import 'dart:developer';

import 'package:fluster/fluster.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class BusRoute {
  // route_id,agency_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color
  String routeId;
  String agencyId;
  String routeShortName;
  String? routeLongName;
  String? routeDesc;
  String? routeType;
  String? routeUrl;
  String? routeColor;
  String? routeTextColor;
  List<Stop> routeStops;

  BusRoute({
    required this.routeId,
    required this.agencyId,
    required this.routeShortName,
    this.routeLongName,
    this.routeDesc,
    this.routeType,
    this.routeUrl,
    this.routeColor,
    this.routeTextColor,
    this.routeStops = const [],
  });
}

class Trip {
  Trip({
    required this.tripId,
    required this.routeShortName,
    this.agency,
    required this.routeId,
    required this.serviceId,
    required this.tripHeadsign,
  });

  String tripId;
  String routeShortName;
  String routeId;
  int serviceId;
  String tripHeadsign;
  Agency? agency;

  static Trip fromMap({
    required Map<String, dynamic> tripInfoMap,
    required (String, Agency?) Function(dynamic routeId) routeNameAndAgency,
  }) {
    final nameAndAgency = routeNameAndAgency(tripInfoMap['route_id']);
    return Trip(
      tripId: tripInfoMap['trip_id'],
      routeId: tripInfoMap['route_id'],
      routeShortName: nameAndAgency.$1,
      agency: nameAndAgency.$2,
      serviceId: int.parse(tripInfoMap['service_id']),
      tripHeadsign: tripInfoMap['trip_headsign'],
    );
  }

  @override
  String toString() {
    return 'Trip{routeShortname: $routeShortName tripId: $tripId, routeId: $routeId, serviceId: $serviceId, tripHeadsign: $tripHeadsign, agency: $agency}';
  }
}

class VehicleInfo {
  List<double>? position;
  String? routeId;
  String tripId;
  String? vehicleId;
  String routeShortName;
  String tripHeadsign;
  Agency? agencyId;

  VehicleInfo({
    this.position,
    this.routeId,
    required this.tripId,
    this.vehicleId,
    required this.routeShortName,
    required this.tripHeadsign,
    this.agencyId,
  });
}

@HiveType(typeId: 0)
class Stop {
  // stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station

  @HiveField(0)
  String stopId;

  @HiveField(1)
  String stopCode;

  @HiveField(2)
  String stopName;

  @HiveField(3)
  String? stopDesc;

  @HiveField(4)
  double stopLat;

  @HiveField(5)
  double stopLon;

  @HiveField(6)
  String? zoneId;

  @HiveField(7)
  String? stopUrl;

  @HiveField(8)
  String? locationType;

  @HiveField(9)
  String? parentStation;

  @HiveField(10)
  String? notice;

  Stop({
    required this.stopId,
    required this.stopCode,
    required this.stopName,
    this.stopDesc,
    required this.stopLat,
    required this.stopLon,
    this.zoneId,
    this.stopUrl,
    this.locationType,
    this.parentStation,
    this.notice,
  });
}

class TripUpdate {
  // trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,pickup_type,drop_off_type,shape_dist_traveled,stop_note
  String tripId;
  String arrivalTime;
  String departureTime;
  String stopId;
  String? stopSequence;
  String? stopHeadsign;
  String? pickupType;
  String? dropOffType;

  TripUpdate({
    required this.tripId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopId,
    this.stopSequence,
    this.stopHeadsign,
    this.pickupType,
    this.dropOffType,
  });
}

class BusRtpi {
  Trip? tripInfo;
  ScheduleType scheduleType;
  DateTime arrivalTime;
  DateTime? departureTime;
  int? departureMins;

  BusRtpi({
    required this.tripInfo,
    required this.scheduleType,
    required this.arrivalTime,
    this.departureTime,
    this.departureMins,
  });
}

enum ApiType {
  tripUpdates,
  vehiclePositions,
  gtfsr,
}

enum ScheduleType {
  scheduled,
  live,
  skipped,
}

enum Agency {
  dublinBus,
  goAhead,
  busEireann,
}

class MapMarker extends Clusterable {
  final String id;
  final LatLng position;
  final BitmapDescriptor? icon;
  final String? infoWindowText;
  final Function(String stopId) windowTapped;
  MapMarker({
    required this.id,
    required this.position,
    required this.windowTapped,
    this.icon,
    this.infoWindowText,
    isCluster = false,
    clusterId,
    pointsSize,
    childMarkerId,
  }) : super(
          markerId: id,
          latitude: position.latitude,
          longitude: position.longitude,
          isCluster: isCluster,
          clusterId: clusterId,
          pointsSize: pointsSize,
          childMarkerId: childMarkerId,
        );
  Marker toMarker() {
    return Marker(
      markerId: MarkerId(id),
      position: LatLng(
        position.latitude,
        position.longitude,
      ),
      infoWindow: InfoWindow(
          title: isCluster ?? false ? '$pointsSize Stops' : '$infoWindowText',
          onTap: windowTapped(id)),
      icon: icon,
    );
  }

  onTap() {
    log('marker $id tapped');
  }
}
