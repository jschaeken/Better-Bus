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

class ApiInterface extends ChangeNotifier {
  String baseUrl = 'https://api.nationaltransport.ie/gtfsr/v2/';

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

  Future<List<BusRoute>> loadRoutes() async {
    final longString =
        await rootBundle.loadString('assets/gtfs_data/routes.txt');
    return const CsvToListConverter()
        .convert(longString)
        .map((row) => BusRoute(
              routeId: row[0].toString(),
              agencyId: row[1].toString(),
              routeShortName: row[2].toString(),
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
    //start a timeout timer
    // final timer = Timer(const Duration(seconds: 10), () {
    //   //if the timer is not cancelled, then the request has timed out
    //   if (isLoadingInfo) {
    //     errorCallback('Request timed out');
    //     isLoadingInfo = false;
    //     notifyListeners();
    //   }
    // });
    // try {
    //   final response = await http.get(
    //     Uri.parse(
    //       '${Constants.baseUrl}getStopTimes?route=$route&stop_id=$stopId',
    //     ),
    //   );
    //   if (response.statusCode != 200) {
    //     timer.cancel();
    //     errorCallback(jsonDecode(response.body)['error']);
    //     isLoadingInfo = false;
    //     notifyListeners();
    //     busRtpiList = [
    //       BusRtpi(
    //         departureMins: 5,
    //         scheduleType: ScheduleType.scheduled,
    //         vehicleInfo: VehicleInfo(
    //           routeShortName: route,
    //           tripHeadsign: 'Dummy Response',
    //           tripId: 'trip_id',
    //         ),
    //       ),
    //     ];
    //   } else if (response.statusCode == 200) {
    //     timer.cancel();
    //     isLoadingInfo = false;
    //     notifyListeners();
    //     final json = jsonDecode(response.body)['times'];
    //     busRtpiList = json
    //         .map<BusRtpi>((busRtpi) => BusRtpi(
    //             departureMins: busRtpi['departure_mins'],
    //             scheduleType: ScheduleType.scheduled,
    //             vehicleInfo: VehicleInfo(
    //               routeShortName: route,
    //               tripHeadsign: busRtpi['destination'],
    //               tripId: busRtpi['trip_id'],
    //             )))
    //         .toList();
    //     log('data updated successfully');
    //   }
    // } catch (e) {
    //   timer.cancel();
    //   errorCallback(e.toString());
    // }
  }

  Future<int> getTripUpdates(
      {required Null Function(String error) errorCallback}) async {
    final url = Uri.parse('${baseUrl}TripUpdates?format=js');
    try {
      final response = await http.get(
        url,
        headers: {
          'Cache-Control': 'no-cache',
          'x-api-key': dotenv.env['NTA_API_KEY']!,
        },
      );

      if (response.statusCode == 200) {
        final feedMessage = gtfs.FeedMessage.fromBuffer(response.bodyBytes);
        _listTripUpdates = feedMessage.entity
            .map((entity) => TripUpdate(
                  arrivalTime: entity.tripUpdate.timestamp.toString(),
                  departureTime: entity.tripUpdate.timestamp.toString(),
                  stopHeadsign: 'unknown',
                  stopId: 'unknown',
                  tripId: entity.tripUpdate.trip.tripId,
                ))
            .toList();
        return _listTripUpdates.length;
      } else {
        debugPrint(
            'Request failed with status: ${response.statusCode}, ${response.body}.');
        errorCallback(response.body);
        return -1;
      }
    } catch (e) {
      debugPrint('an error has occured: $e');
      errorCallback(e.toString());
      return -1;
    }
  }
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
