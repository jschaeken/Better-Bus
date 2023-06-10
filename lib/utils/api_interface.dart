//import http package
// ignore_for_file: unused_import

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:better_bus_dublin/utils/constants.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart' as gtfs;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class ApiInterface extends ChangeNotifier {
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
      _listStops = const CsvToListConverter()
          .convert(longString, csvSettingsDetector: d)
          .map((row) {
        return Stop(
          stopId: row[0].toString(),
          stopCode: row[1].toString(),
          stopName: row[2].toString(),
          stopLat: double.parse(row[4].toString()),
          stopLon: double.parse(row[5].toString()),
        );
      }).toList();
    } catch (e) {
      if (callback != null) {
        callback(e.toString());
      }
    }
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

  Future<void> getStopBusTimes(String stopId, Function(String e) errorCallback,
      {String route = '47', bool isRefresh = false}) async {
    if (isRefresh) {
      isLoadingInfo = true;
    } else {
      _isLoadingInfo = true;
    }
    await Future.delayed(const Duration(seconds: 1));
    servingAgencies = [
      Agency.dublinBus,
      Agency.goAhead,
      Agency.busEireann,
    ];
    isLoadingInfo = false;
    // timer.cancel();
    busRtpiList = [
      for (int i = 0; i < 20; i++)
        BusRtpi(
          departureMins: i + 1,
          scheduleType: ScheduleType.scheduled,
          vehicleInfo: VehicleInfo(
            routeShortName: '${20 + (2 * i)}',
            tripHeadsign: 'Dummy Response',
            tripId: 'trip_id',
          ),
        ),
    ];
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

  Future<BusRoute> getRouteDetail(
      BusRoute route, Function(String error) errorCallback) async {
    RemoteApi remoteApi = RemoteApi();
    try {
      List<String> stopIds = await remoteApi.getStopIdsByTripId(
        // route.routeId,
        '3305_11476',
        Stage.dev,
        (e) => errorCallback(e),
      );
      List<Stop> stops = [];

      for (String stopId in stopIds) {
        Stop? stop = (searchByStopId(stopId, (e) {
          throw Exception(e);
        }));
        if (stop != null) {
          stops.add(stop);
        }
      }

      return BusRoute(
        routeId: route.routeId,
        routeShortName: route.routeShortName,
        routeLongName: route.routeLongName,
        agencyId: route.agencyId,
        routeStops: stops,
      );
    } catch (e) {
      debugPrint(
        '${e.toString()} 362',
      );
      throw Exception(e);
    }
  }
}

class RemoteApi {
  static String baseUrl =
      'https://lxqlo2hbvb.execute-api.eu-west-1.amazonaws.com/';

  Future<List<String>> getStopIdsByTripId(
      String tripId, Stage stage, Function(String e) errorCallback) async {
    Uri uri = Uri.parse('$baseUrl$stage/get-stops?tripId=$tripId');
    final headers = {
      "x-api-key": "${dotenv.env['AWS_LAMBDA_KEY']}",
    };
    try {
      Response response = await http.get(
        uri,
        headers: headers,
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

//   Future<List<String>> getTripIdByRouteAndDay(
//       String routeId, int validServiceId) async {}
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
