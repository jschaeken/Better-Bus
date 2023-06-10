import 'dart:developer';
import 'dart:io';
import 'package:better_bus_dublin/pages/stop_details.dart';
import 'package:better_bus_dublin/utils/components.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class RouteDetail extends StatelessWidget {
  RouteDetail({super.key, required this.route});

  final BusRoute route;
  final isMobile = Platform.isIOS || Platform.isAndroid;

  @override
  Widget build(BuildContext context) {
    getLatLngBoundsCenter(route.routeStops);
    return Scaffold(
      appBar: AppBar(
        title: Text('Route ${route.routeShortName}'),
      ),
      body: Column(
        children: [
          isMobile
              ? PlatformMap(
                  initialCameraPosition: CameraPosition(
                    target: getLatLngBoundsCenter(route.routeStops),
                    zoom: 12,
                  ),
                  markers: placeMarkers(route.routeStops),
                )
              : SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/appleMap.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
          Flexible(
            child: ListView.builder(
              itemCount: route.routeStops.length,
              itemBuilder: (context, index) {
                return InformationTile(
                  onTileTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => StopDetailsPage(
                          stop: route.routeStops[index],
                        ),
                      ),
                    );
                  },
                  titleText: route.routeStops[index].stopName,
                  subtitleText: 'Stop ${route.routeStops[index].stopCode}',
                  isLoadingRoute: false,
                  index: index,
                );
              },
            ),
          )
        ],
      ),
    );
  }

  getLatLngBoundsCenter(List<Stop> routeStops) {
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;
    for (var stop in routeStops) {
      if (stop.stopLat < minLat) {
        minLat = stop.stopLat;
      }
      if (stop.stopLat > maxLat) {
        maxLat = stop.stopLat;
      }
      if (stop.stopLon < minLng) {
        minLng = stop.stopLon;
      }
      if (stop.stopLon > maxLng) {
        maxLng = stop.stopLon;
      }
    }
    log('center is ${LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2)}');
    return LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );
  }

  Set<Marker> placeMarkers(List<Stop> routeStops) {
    Set<Marker> markers = {};
    for (var stop in routeStops) {
      markers.add(
        Marker(
          markerId: MarkerId(stop.stopId),
          position: LatLng(stop.stopLat, stop.stopLon),
          consumeTapEvents: true,
          onTap: () {
            log('tapped marker ${stop.stopId}');
          },
        ),
      );
    }
    return markers;
  }
}
