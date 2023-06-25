//import http package
// ignore_for_file: unused_import

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:better_bus_dublin/utils/constants.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:better_bus_dublin/utils/remote_api.dart';
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

  List<ServiceDetails> serviceDetails = [];

  Fluster<MapMarker>? fluster;

  CameraPosition? currentCamPos;

  List<MapMarker> currentClusters = [];

  List<BusRtpi> busRtpiList = [];

  bool _isLoadingInfo = false;
  bool get isLoadingInfo => _isLoadingInfo;
  set isLoadingInfo(bool value) {
    _isLoadingInfo = value;
    notifyListeners();
  }

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

  Future<void> loadStops(
      {Function(String e)? callback,
      Function(String stopId)? stopWindowTapped}) async {
    int i = 0;
    log('loading stops');
    try {
      String longString =
          await rootBundle.loadString('assets/gtfs_data/stops.txt');
      var d = const FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
      const CsvToListConverter()
          .convert(longString, csvSettingsDetector: d)
          .forEach((row) {
        i++;
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
            windowTapped: (stopId) => stopWindowTapped == null
                ? null
                : stopWindowTapped(row[0].toString()),
            icon: BitmapDescriptor.defaultMarker,
            position: LatLng(
              double.parse(row[4].toString()),
              double.parse(row[5].toString()),
            ),
          ),
        );
        if (i % 1000 == 0) {
          log('${mapMarkers[i - 1].latitude}, ${mapMarkers[i - 1].longitude}');
        }
      });

      log('loaded stops: listStopsLength: ${_listStops.length}, mapMarkersLength: ${_mapMarkers.length}');
    } catch (e) {
      if (callback != null) {
        log('error loading stops: $e, i: $i');
        callback(e.toString());
      }
    }
  }

  Future<void> initFluster(
    int minZoom,
    int maxZoom,
    BitmapDescriptor clusterImage,
    Function(String id) stopWindowTapped,
  ) async {
    await checkStopsLoaded();
    log('init fluster: mapMarkersLength: ${_mapMarkers.length}');
    fluster = Fluster<MapMarker>(
      minZoom: minZoom, // The min zoom at clusters will show
      maxZoom: maxZoom, // The max zoom at clusters will show
      radius: 150, // Cluster radius in pixels
      extent: 2048, // Tile extent. Radius is calculated with it.
      nodeSize: 64, // Size of the KD-tree leaf node.
      points: _mapMarkers, // The list of markers created before
      createCluster: (
        // Create cluster marker
        BaseCluster? cluster,
        double? lng,
        double? lat,
      ) =>
          MapMarker(
        id: cluster!.id.toString(),
        position: LatLng(lat!, lng!),
        // icon: clusterImage,
        windowTapped: (id) => stopWindowTapped(id),
        isCluster: cluster.isCluster,
        clusterId: cluster.id,
        pointsSize: cluster.pointsSize,
        childMarkerId: cluster.childMarkerId,
      ),
    );
  }

  Future<bool> checkStopsLoaded() async {
    while (_mapMarkers.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return true;
  }

  void updateClustersForCamPos(LatLngBounds bounds) {
    currentClusters = fluster?.clusters(
          [
            bounds.southwest.longitude,
            bounds.southwest.latitude,
            bounds.northeast.longitude,
            bounds.northeast.latitude,
          ],
          currentCamPos?.zoom.toInt() ?? 0,
        ) ??
        [];
    notifyListeners();
    log('zoom: ${currentCamPos?.zoom.toInt()}, clusters: ${currentClusters.length}');
    log('bounds: ${bounds.southwest.longitude.toStringAsFixed(3)}, ${bounds.southwest.latitude.toStringAsFixed(3)}, ${bounds.northeast.longitude.toStringAsFixed(3)}, ${bounds.northeast.latitude.toStringAsFixed(3)}');
  }

  Future<void> loadServiceAvailability() async {
    try {
      String longString =
          await rootBundle.loadString('assets/gtfs_data/calendar.txt');
      var d = const FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
      serviceDetails = const CsvToListConverter()
          .convert(longString, csvSettingsDetector: d)
          .map((row) {
        return ServiceDetails(
            serviceId: row[0],
            binaryList: row.sublist(1, 8).map((number) => number == 1).toList(),
            monday: row[1] == 1,
            tuesday: row[2] == 1,
            wednesday: row[3] == 1,
            thursday: row[4] == 1,
            friday: row[5] == 1,
            saturday: row[6] == 1,
            sunday: row[7] == 1,
            startDate: DateTime.tryParse(row[8].toString()) ??
                DateTime.now().subtract(const Duration(days: 1)),
            endDate: DateTime.tryParse(row[9].toString()) ??
                DateTime.now().add(const Duration(days: 100)));
      }).toList();
    } catch (e) {
      log(e.toString(), name: 'loadServiceAvailability');
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

  Future<Trip?> getTripInfo(
      String tripId, Function(String e) errorCallback) async {
    try {
      final routeInfoMap = await remoteApi.queryRouteByTripId(tripId);
      if (routeInfoMap['Items'].isEmpty) {
        log('No trip info found for tripId: $tripId, routeInfoMap: $routeInfoMap');

        return null;
      } else {
        final trip = Trip.fromMap(
          tripInfoMap: routeInfoMap['Items'][0],
          routeNameAndAgency: (routeId) => getRouteShortNameAndAgency(routeId),
        );
        return trip;
      }
    } catch (e) {
      log(e.toString(), name: 'getTripInfo');
      // errorCallback(e.toString());
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
      {bool isRefesh = false, bool streamResults = false}) async {
    if (isRefesh) {
      isLoadingInfo = true;
    } else {
      _isLoadingInfo = true;
    }
    busRtpiList = [];
    Map<String, dynamic> jsonMap = await remoteApi.queryBusTimesByStopId(
      stopId,
      (e) {
        throw ('A network error has occured');
      },
    );
    List<BusRtpi> tempRtpiList = [];
    List<dynamic> items = jsonMap['Items'] ?? [];

    await Future.forEach(
      items,
      ((busTime) async {
        Trip? tripInfo = await getTripInfo(busTime['trip_id'], (e) {
          throw ('An error has occured');
        });
        // ignore: unnecessary_null_comparison
        if (tripInfo != null && checkServiceIdValidity(tripInfo.serviceId)) {
          log('adding ${tripInfo.toString()} to list');
          tempRtpiList.add(
            BusRtpi(
              arrivalTime: minsToDateTime(busTime['arrival_time']),
              departureMins:
                  getRelativeMins(minsToDateTime(busTime['arrival_time'])) + 1,
              scheduleType: ScheduleType.scheduled,
              tripInfo: tripInfo,
            ),
          );
          if (!streamResults) {
            isLoadingInfo = false;
            busRtpiList = tempRtpiList;
            notifyListeners();
          }
        }
      }),
    );

    busRtpiList = tempRtpiList;
    notifyListeners();
    isLoadingInfo = false;
    // } catch (e) {
    //   isLoadingInfo = false;
    //   // errorCallback(e.toString());
    //   throw Exception(e);
    // }
  }

  //Helper functions
  bool checkServiceIdValidity(int serviceId) {
    //get current day and check if serviceId is valid

    final now = DateTime.now();
    final day = now.weekday;
    log('Checking serviceId validity for $serviceId');
    log('Day is $day');

    final serviceDetailsTmp = serviceDetails.where((serviceDetail) {
      return serviceDetail.startDate.isBefore(now) &&
          serviceDetail.endDate.isAfter(now);
    }).toList();

    log('ServiceDetailsTmp length is ${serviceDetailsTmp.length}');

    return serviceDetailsTmp
        .singleWhere((serviceDetail) => serviceDetail.serviceId == serviceId,
            orElse: () => ServiceDetails.blank())
        .binaryList[day - 1];
  }

  (String, Agency?) getRouteShortNameAndAgency(String routeId) {
    final matchingRoutes = listRoutes.where((route) {
      return route.routeId == routeId;
    }).toList();
    if (matchingRoutes.isNotEmpty) {
      return (
        matchingRoutes.first.routeShortName,
        getAgencyById(matchingRoutes.first.agencyId)
      );
    }
    log('No route found for routeId: $routeId');
    return ('', null);
  }

  int getRelativeMins(DateTime dateTime) {
    return dateTime.difference(DateTime.now()).inMinutes;
  }

  int getMinutesSinceDayStart(DateTime dateTime) {
    final mins = dateTime
        .difference(DateTime(
            dateTime.year, dateTime.month, dateTime.day, 0, 0, 0, 0, 0))
        .inMinutes;
    return mins;
  }

  DateTime minsToDateTime(int mins) {
    return DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 0, 0, 0, 0, 0)
        .add(Duration(minutes: mins));
  }

  parseTimeString(busTime) {
    //parse a string like 13:38:36 into a DateTime, for today, hours, minutes, seconds
    var parts = busTime.split(':');
    var now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]),
        int.parse(parts[1]), int.parse(parts[2]));
  }

  Agency? getAgencyById(String agencyId) {
    switch (agencyId) {
      case '7778019':
        return Agency.dublinBus;
      case '7778006':
        return Agency.goAhead;
      case '7778021':
        return Agency.goAhead;
    }
    return null;
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
  List<bool> binaryList;
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
    required this.binaryList,
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

  ServiceDetails.blank()
      : serviceId = 0,
        binaryList = [false, false, false, false, false, false, false],
        monday = false,
        tuesday = false,
        wednesday = false,
        thursday = false,
        friday = false,
        saturday = false,
        sunday = false,
        startDate = DateTime.now(),
        endDate = DateTime.now();
}
