import 'dart:convert';
import 'dart:developer';
import 'package:better_bus_dublin/utils/api_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:intl/intl.dart';

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
      log(e.toString(), name: 'queryStopsByRouteIdAndDirection');
      return [];
    }
  }

  Future<Map<String, dynamic>> queryRouteByTripId(String tripId) async {
    String stage = dotenv.env['STAGE'] ?? 'dev';
    Uri uri = Uri.parse('$baseUrl$stage/trip-id-info?trip_id=$tripId');
    try {
      Response response = await http.get(
        uri,
        headers: authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Request failed with status: ${response.statusCode}, ${response.body}');
      }

      Map<String, dynamic> routeInfo = jsonDecode(response.body);
      return routeInfo;
    } catch (e) {
      log(e.toString(), name: 'queryRouteIdByTripId');
      return {};
    }
  }

  Future<Map<String, dynamic>> queryBusTimesByStopId(
      String stopId, Function(String e) errorCallback,
      {required int minutesIntoFuture}) async {
    int timeNow = apiInterface.getMinutesSinceDayStart(DateTime.now());
    int maxArrivalTime = timeNow + minutesIntoFuture;
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
      log('response: ${response.statusCode}, ${response.body}');

      Map<String, dynamic> busRtpiJson = jsonDecode(response.body);
      log('items returned: ${busRtpiJson.length}');
      return busRtpiJson;
    } catch (e) {
      log(e.toString(), name: 'queryBusTimesByStopId');
      errorCallback(e.toString());
      throw Exception(e);
    }
  }

  String formatDateTime(DateTime dateTime) {
    String formatted = DateFormat.Hms().format(dateTime);
    return formatted;
  }

  Future<Map<String, dynamic>> queryVehicleLocationByTripId(
      String tripId) async {
    String stage = dotenv.env['STAGE'] ?? 'dev';
    Uri uri = Uri.parse('$baseUrl$stage/bus-loc?tripId=$tripId');

    try {
      Response response = await http.get(
        uri,
        headers: authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Request failed with status: ${response.statusCode}, ${response.body}');
      }

      Map<String, dynamic> busLocList = jsonDecode(response.body);
      return busLocList;
    } catch (e) {
      log(e.toString(), name: 'queryVehicleLocationByTripId');
      return Future.value({});
    }
  }

  Future<Map<String, dynamic>> queryAllActiveBuses() {
    String stage = dotenv.env['STAGE'] ?? 'dev';
    Uri uri = Uri.parse('$baseUrl$stage/bus-loc?getAll=1');

    try {
      return http
          .get(
        uri,
        headers: authHeaders,
      )
          .then((response) {
        if (response.statusCode != 200) {
          throw Exception(
              'Request failed with status: ${response.statusCode}, ${response.body}');
        }

        Map<String, dynamic> busLocList = jsonDecode(response.body);
        return busLocList;
      });
    } catch (e) {
      log(e.toString(), name: 'queryAllActiveBuses');
      return Future.value({});
    }
  }
}
