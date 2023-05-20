//import http package
import 'dart:convert';
import 'dart:io';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart' as gtfs;
import 'package:http/http.dart' as http;

class ApiInterface extends ChangeNotifier {
  String baseUrl = 'https://api.nationaltransport.ie/gtfsr/v2/';

  List<VehicleInfo> _listActiveVehicleInfo = [];
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

  getLiveData(ApiType apiType) async {
    //a switch statement to assign a string to the url variable based on the apiType
    String apiSuffix = '';
    switch (apiType) {
      case ApiType.tripUpdates:
        apiSuffix = 'TripUpdates?format=js';
        break;
      case ApiType.vehiclePositions:
        apiSuffix = 'Vehicles?format=js';
        break;
      case ApiType.gtfsr:
        break;
    }

    final url = Uri.parse(baseUrl + apiSuffix);
    final response = await http.get(
      url,
      headers: {
        'Cache-Control': 'no-cache',
        'x-api-key': dotenv.env['NTA_API_KEY']!,
      },
    );

    if (response.statusCode == 200) {
      final feedMessage = gtfs.FeedMessage.fromBuffer(response.bodyBytes);

      print('Number of entities: ${feedMessage.entity.length}.');
      switch (apiType) {
        case ApiType.tripUpdates:
          break;
        case ApiType.vehiclePositions:
          List<VehicleInfo> tempList = [];
          for (var entity in feedMessage.entity) {
            final vehiclePosition = entity.vehicle;
            final vehicleInfo = VehicleInfo(
              position: [
                vehiclePosition.position.latitude,
                vehiclePosition.position.longitude,
              ],
              routeId: vehiclePosition.trip.routeId,
              tripId: vehiclePosition.trip.tripId,
              vehicleId: vehiclePosition.vehicle.id,
              agencyId: Agency.dublinBus,
              routeShortName:
                  'Unknown', //TODO: get route short name from route id
              tripHeadsign: 'Unknown', //TODO: get trip headsign from trip id
            );
            tempList.add(vehicleInfo);
          }
          return tempList;
        case ApiType.gtfsr:
          break;
      }
    } else {
      print(
          'Request failed with status: ${response.statusCode}, ${response.body}.');
    }
  }

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

  Future<void> loadStops() async {
    final longString =
        await rootBundle.loadString('assets/gtfs_data/stops.txt');
    _listStops = const CsvToListConverter().convert(longString).map((row) {
      return Stop(
        stopId: row[0].toString(),
        stopCode: row[1].toString(),
        stopName: row[2].toString(),
        stopLat: double.parse(row[4].toString()),
        stopLon: double.parse(row[5].toString()),
      );
    }).toList();
  }

  Future<List<Stop>> searchByStopCode(String trim) async {
    if (listStops.isEmpty) {
      await loadStops();
    }
    if (trim.isEmpty) {
      return [];
    }
    return listStops.where((stop) => stop.stopCode.contains(trim)).toList();
  }

  Future<List<dynamic>> getStopTimesById(String stopId) async {
    //asyncronously load and read the file until the line with the stopId is found

    //then read the next 2 lines and return them as a list of StopTimes

    File file = File('assets/gtfs_data/stop_times.txt');
    await file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((l) {
      if (l.contains(stopId)) {
        print(l);
      }
    });
    return [''];
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

  Future<List<BusRtpi>> getTripUpdateByStopId(String stopId) async {
    // return _listTripUpdates
    //     .where((tripUpdate) => tripUpdate.stopId == stopId)
    //     .toList();

    //DEMO DATA
    return [
      BusRtpi(
        arrivalTime: DateTime.now().add(const Duration(minutes: 6)),
        departureTime: DateTime.now(),
        scheduleType: ScheduleType.scheduled,
        vehicleInfo: VehicleInfo(
          position: [
            53.38383333,
            -6.474637809,
          ],
          routeId: '123456789',
          routeShortName: '47',
          tripHeadsign: 'Poolbeg Street',
          tripId: '234543',
          vehicleId: '3454326',
          agencyId: Agency.dublinBus,
        ),
      ),
      BusRtpi(
        arrivalTime: DateTime.now().add(const Duration(minutes: 2)),
        departureTime: DateTime.now(),
        scheduleType: ScheduleType.scheduled,
        vehicleInfo: VehicleInfo(
          position: [
            53.38383333,
            -6.474637809,
          ],
          routeId: '123456789',
          routeShortName: '47',
          tripHeadsign: 'Poolbeg Street',
          tripId: '234543',
          vehicleId: '3454326',
          agencyId: Agency.dublinBus,
        ),
      ),
      BusRtpi(
        arrivalTime: DateTime.now().add(const Duration(minutes: 17)),
        departureTime: DateTime.now(),
        scheduleType: ScheduleType.scheduled,
        vehicleInfo: VehicleInfo(
          position: [
            53.38383333,
            -6.474637809,
          ],
          routeId: '123456789',
          routeShortName: '46a',
          tripHeadsign: 'Dun Laoirghaire',
          tripId: '234543',
          vehicleId: '3454326',
          agencyId: Agency.dublinBus,
        ),
      ),
    ];
  }
}
