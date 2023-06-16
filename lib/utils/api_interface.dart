//import http package
// ignore_for_file: unused_import

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:better_bus_dublin/utils/constants.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:fluster/fluster.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart' as gtfs;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class ApiInterface extends ChangeNotifier {
  RemoteApi remoteApi = RemoteApi();

  List<VehicleInfo> _listActiveVehicleInfo = [];

  List<Agency> _servingAgencies = [];
  List<Agency> get servingAgencies => _servingAgencies;
  set servingAgencies(List<Agency> value) {
    _servingAgencies = value;
    notifyListeners();
  }

  List<VehicleInfo> get listActiveVehicleInfo => _listActiveVehicleInfo;

  bool _isTripUpdatesLoading = false;
  bool get isTripUpdatesLoading => _isTripUpdatesLoading;

  startTripUpdatesLoading() {
    _isTripUpdatesLoading = true;
    notifyListeners();
  }

  stopTripUpdatesLoading() {
    _isTripUpdatesLoading = false;
    notifyListeners();
  }

  set listActiveVehicleInfo(List<VehicleInfo> value) {
    _listActiveVehicleInfo = value;
    notifyListeners();
  }

  List<BusRoute> _listRoutes = [];
  List<BusRoute> get listRoutes => _listRoutes;
  set listRoutes(List<BusRoute> value) {
    _listRoutes = value;
    notifyListeners();
  }

  List<Stop> _listStops = [];
  List<Stop> get listStops => _listStops;
  set listStops(List<Stop> value) {
    _listStops = value;
    notifyListeners();
  }

  List<MapMarker> _mapMarkers = [];
  List<MapMarker> get mapMarkers => _mapMarkers;
  set mapMarkers(List<MapMarker> value) {
    _mapMarkers = value;
    notifyListeners();
  }

  List<TripUpdate> _listTripUpdates = [];
  List<TripUpdate> get listTripUpdates => _listTripUpdates;
  set listTripUpdates(List<TripUpdate> value) {
    _listTripUpdates = value;
    notifyListeners();
  }

  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  set errorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }

  List<ServiceDetails> _serviceDetails = [];
  List<ServiceDetails> get serviceDetails => _serviceDetails;
  set serviceDetails(List<ServiceDetails> value) {
    _serviceDetails = value;
    notifyListeners();
  }

  Fluster<MapMarker>? fluster;

  CameraPosition? currentCamPos;

  List<MapMarker> currentClusters = [];

  List<BusRtpi> busRtpiList = [];

  Future<void> loadRoutes({Function(String e)? callback}) async {
    final longString =
        await rootBundle.loadString('assets/gtfs_data/routes.txt');
    var d = const FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
    _listRoutes = const CsvToListConverter()
        .convert(longString, csvSettingsDetector: d)
        .map((row) => BusRoute(
              routeId: row[0].toString(),
              agencyId: row[1].toString(),
              routeShortName: row[2].toString(),
              routeLongName: row[3].toString(),
            ))
        .toList();
  }

  Future<void> loadStops({Function(String e)? callback}) async {
    log('loading stops');
    try {
      String longString =
          await rootBundle.loadString('assets/gtfs_data/stops.txt');
      var d = const FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
      const CsvToListConverter()
          .convert(longString, csvSettingsDetector: d)
          .forEach((row) {
        _listStops.add(
          Stop(
            stopId: row[0].toString(),
            stopCode: row[1].toString(),
            stopName: row[2].toString(),
            stopLat: double.parse(row[4].toString()),
            stopLon: double.parse(row[5].toString()),
          ),
        );
        _mapMarkers.add(
          MapMarker(
            id: row[0].toString(),
            infoWindowText: row[1].toString(),
            icon: BitmapDescriptor.defaultMarker,
            position: LatLng(
              double.parse(row[4].toString()),
              double.parse(row[5].toString()),
            ),
          ),
        );
      });
      log('loaded stops: listStopsLength: ${_listStops.length}, mapMarkersLength: ${_mapMarkers.length}');
    } catch (e) {
      if (callback != null) {
        callback(e.toString());
      }
    }
  }

  Future<void> initFluster(
    int minZoom,
    int maxZoom,
    BitmapDescriptor clusterImage,
  ) async {
    fluster = Fluster<MapMarker>(
      minZoom: minZoom, // The min zoom at clusters will show
      maxZoom: maxZoom, // The max zoom at clusters will show
      radius: 150, // Cluster radius in pixels
      extent: 2048, // Tile extent. Radius is calculated with it.
      nodeSize: 64, // Size of the KD-tree leaf node.
      points: _mapMarkers, // The list of markers created before
      createCluster: (
        // Create cluster marker
        BaseCluster cluster,
        double lng,
        double lat,
      ) =>
          MapMarker(
        id: cluster.id.toString(),
        position: LatLng(lat, lng),
        icon: clusterImage,
        isCluster: cluster.isCluster,
        clusterId: cluster.id,
        pointsSize: cluster.pointsSize,
        childMarkerId: cluster.childMarkerId,
      ),
    );
  }

  updateClustersForCamPos(LatLngBounds bounds) {
    currentClusters = fluster?.clusters(
          [
            bounds.northeast.longitude,
            bounds.northeast.latitude,
            bounds.southwest.longitude,
            bounds.southwest.latitude,
          ],
          currentCamPos?.zoom.toInt() ?? 10,
        ) ??
        [];
  }

  Future<void> loadServiceAvailability() async {
    try {
      String longString =
          await rootBundle.loadString('assets/gtfs_data/calendar.txt');
      var d = const FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
      _serviceDetails = const CsvToListConverter()
          .convert(longString, csvSettingsDetector: d)
          .map((row) {
        return ServiceDetails(
            serviceId: row[0],
            monday: row[1].map((number) => number == 1),
            tuesday: row[2].map((number) => number == 1),
            wednesday: row[3].map((number) => number == 1),
            thursday: row[4].map((number) => number == 1),
            friday: row[5].map((number) => number == 1),
            saturday: row[6].map((number) => number == 1),
            sunday: row[7].map((number) => number == 1),
            startDate: DateTime.tryParse(row[8]) ??
                DateTime.now().subtract(const Duration(days: 1)),
            endDate: DateTime.tryParse(row[8]) ??
                DateTime.now().add(const Duration(days: 100)));
      }).toList();
    } catch (e) {
      log(e.toString());
    }
  }

  Future<List<Stop>> searchByStopCode(
      String trim, Function(String e) errorCallback) async {
    try {
      if (listStops.isEmpty) {
        await loadStops(
          callback: (e) {
            errorCallback(e);
          },
        );
      }
      if (trim.isEmpty) {
        return [];
      }
      return listStops.where((stop) => stop.stopCode.contains(trim)).toList();
    } catch (e) {
      errorCallback(e.toString());
      return [];
    }
  }

  bool _isLoadingInfo = false;
  bool get isLoadingInfo => _isLoadingInfo;
  set isLoadingInfo(bool value) {
    _isLoadingInfo = value;
    notifyListeners();
  }

  Stop? searchByStopId(String stopId, Function(String e) errorCallback) {
    try {
      if (listStops.isEmpty) {
        loadStops(
          callback: (e) {
            errorCallback(e);
          },
        );
      }
      if (stopId.isEmpty) {
        return null;
      }
      final matchingStops = listStops.where((stop) {
        return stop.stopId == stopId;
      }).toList();
      if (matchingStops.isNotEmpty) {
        return matchingStops.first;
      }
    } catch (e) {
      errorCallback(e.toString());
      return null;
    }
    return null;
  }

  Future<BusRoute?> searchRouteId(
      String routeId, Function(String e) errorCallback) async {
    try {
      if (listRoutes.isEmpty) {
        loadRoutes(
          callback: (e) {
            errorCallback(e);
          },
        );
      }
      if (routeId.isEmpty) {
        return null;
      }
      final matchingRoutes = listRoutes.where((route) {
        return route.routeId == routeId;
      }).toList();
      if (matchingRoutes.isNotEmpty) {
        return matchingRoutes.first;
      }
    } catch (e) {
      errorCallback(e.toString());
      return null;
    }
    return null;
  }

  List<BusRoute> searchByRouteName(
      String trim, Function(String e) errorCallback) {
    try {
      if (trim.isEmpty) {
        return [];
      }
      trim = trim.toUpperCase();
      log(trim);
      if (listRoutes.isEmpty) {
        loadRoutes(
          callback: (e) {
            errorCallback(e);
          },
        );
      }
      return listRoutes
          .where((route) => route.routeShortName.contains(trim))
          .toList();
    } catch (e) {
      errorCallback(e.toString());
      return [];
    }
  }

  Future<(BusRoute, BusRoute)> getRouteDetail(
      BusRoute route, Function(String error) errorCallback) async {
    RemoteApi remoteApi = RemoteApi();
    try {
      List<String> stopIds1 =
          await remoteApi.queryStopsByRouteIdAndDirection(route.routeId, 0);
      List<Stop> stops1 = [];
      for (String stopId in stopIds1) {
        Stop? stop = (searchByStopId(stopId, (e) {
          throw Exception(e);
        }));
        if (stop != null) {
          stops1.add(stop);
        }
      }

      List<String> stopIds2 =
          await remoteApi.queryStopsByRouteIdAndDirection(route.routeId, 1);
      List<Stop> stops2 = [];
      for (String stopId in stopIds2) {
        Stop? stop = (searchByStopId(stopId, (e) {
          throw Exception(e);
        }));
        if (stop != null) {
          stops2.add(stop);
        }
      }

      return (
        BusRoute(
          routeId: route.routeId,
          routeShortName: route.routeShortName,
          routeLongName: route.routeLongName,
          agencyId: route.agencyId,
          routeStops: stops1,
        ),
        BusRoute(
          routeId: route.routeId,
          routeShortName: route.routeShortName,
          routeLongName: flipRouteLongName(route.routeLongName),
          agencyId: route.agencyId,
          routeStops: stops2,
        )
      );
    } catch (e) {
      debugPrint(
        '${e.toString()} 362',
      );
      throw Exception(e);
    }
  }

  void getStopTimesByStopId(String stopId, Function(String error) errorCallback,
      {bool isRefesh = false}) async {
    if (isRefesh) {
      isLoadingInfo = true;
    } else {
      _isLoadingInfo = true;
    }
    busRtpiList = [];
    try {
      Map<String, dynamic> jsonMap = await remoteApi.queryBusTimesByStopId(
        stopId,
        (e) {
          errorCallback('A network error has occured');
        },
        minutesIntoFuture: 240,
      );
      List<BusRtpi> tempRtpiList = [];
      jsonMap['Items'].forEach((busTime) {
        tempRtpiList.add(BusRtpi(
          arrivalTime: parseTimeString(busTime['arrival_time']),
          departureMins:
              getRelativeMins((parseTimeString(busTime['arrival_time']))),
          scheduleType: ScheduleType.scheduled,
          vehicleInfo: VehicleInfo(
            routeShortName: 'Route',
            tripHeadsign: busTime['trip_id'],
            tripId: busTime['trip_id'],
          ),
        ));
      });
      // tempRtpiList.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
      busRtpiList = tempRtpiList;
      isLoadingInfo = false;
    } catch (e) {
      isLoadingInfo = false;
      debugPrint(
        '${e.toString()} 362',
      );
      errorCallback('An unkonwn error has occured');
    }
  }

  int getRelativeMins(DateTime dateTime) {
    return dateTime.difference(DateTime.now()).inMinutes;
  }

  parseTimeString(busTime) {
    //parse a string like 13:38:36 into a DateTime, for today, hours, minutes, seconds
    var parts = busTime.split(':');
    var now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]),
        int.parse(parts[1]), int.parse(parts[2]));
  }

  String flipRouteLongName(String? routeLongName) {
    if (routeLongName == null) {
      return '';
    }
    log('initial routeLongName: $routeLongName');
    List<String> split = routeLongName.split(' – ');
    if (split.length == 2) {
      log('flipped routeLongName: ${split[1]} – ${split[0]}');
      return '${split[1]} - ${split[0]}';
    } else {
      log('split.length != 2, split: $split, split.length: ${split.length}');
      return routeLongName;
    }
  }
}

class RemoteApi {
  static String baseUrl =
      'https://83gxay2ofa.execute-api.eu-west-1.amazonaws.com/';

  static Map<String, String> authHeaders = {
    "x-api-key": "${dotenv.env['AWS_LAMBDA_KEY']}",
  };

  static ApiInterface apiInterface = ApiInterface();

  Future<List<String>> queryStopIdsByTripId(
      String tripId, Stage stage, Function(String e) errorCallback) async {
    Uri uri = Uri.parse('$baseUrl$stage/get-stops?tripId=$tripId');
    try {
      Response response = await http.get(
        uri,
        headers: authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Request failed with status: ${response.statusCode}, ${response.body}');
      }
      List json = jsonDecode(response.body) as List;
      return json.map((e) {
        return e['stop_id'] as String;
      }).toList();
    } catch (e) {
      log(e.toString());
      errorCallback(e.toString());
      return [];
    }
  }

  Future<List<String>> queryStopsByRouteIdAndDirection(
      String routeId, int direction) async {
    assert(direction == 0 || direction == 1);
    String stage = dotenv.env['STAGE'] ?? 'dev';
    Uri uri = Uri.parse(
        '$baseUrl$stage/stop-routes?route_id=$routeId&direction_id=$direction');
    try {
      Response response = await http.get(
        uri,
        headers: authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Request failed with status: ${response.statusCode}, ${response.body}');
      }

      List<dynamic> stopIds = jsonDecode(response.body);
      List<String> stopIdsStrings = [];
      for (dynamic stopId in stopIds) {
        stopIdsStrings.add(stopId.toString());
      }
      return stopIdsStrings;
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  Future<Map<String, dynamic>> queryBusTimesByStopId(
      String stopId, Function(String e) errorCallback,
      {int minutesIntoFuture = 60}) async {
    String timeNow = formatDateTime(DateTime.now());
    String maxArrivalTime = formatDateTime(
        DateTime.now().add(Duration(minutes: minutesIntoFuture)));
    String stage = dotenv.env['STAGE'] ?? 'dev';

    Uri uri = Uri.parse(
        '$baseUrl$stage/bus-times-at-stop?stop_id=$stopId&time_now=$timeNow&max_arrival_time=$maxArrivalTime');
    try {
      Response response = await http.get(
        uri,
        headers: authHeaders,
      );

      if (response.statusCode != 200) {
        log(response.body);
        throw Exception(
            'Request failed with status: ${response.statusCode}, ${response.body}');
      }

      Map<String, dynamic> busRtpiJson = jsonDecode(response.body);
      log('busRtpiJson: $busRtpiJson');
      return busRtpiJson;
    } catch (e) {
      log(e.toString());
      errorCallback(e.toString());
      throw Exception(e);
    }
  }

  String formatDateTime(DateTime dateTime) {
    String formatted = DateFormat.Hms().format(dateTime);
    return formatted;
  }
}

enum Stage {
  dev,
  stg,
  prod;

  @override
  String toString() => name;
}

class ServiceDetails {
  int serviceId;
  bool monday;
  bool tuesday;
  bool wednesday;
  bool thursday;
  bool friday;
  bool saturday;
  bool sunday;
  DateTime startDate;
  DateTime endDate;

  ServiceDetails({
    required this.serviceId,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.startDate,
    required this.endDate,
  });
}
