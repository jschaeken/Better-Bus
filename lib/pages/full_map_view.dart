import 'dart:io';

import 'package:better_bus_dublin/utils/models.dart';
import 'package:flutter/material.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class FullMapView extends StatefulWidget {
  const FullMapView({required this.stop, super.key});

  final Stop stop;

  @override
  State<FullMapView> createState() => FullMapViewState();
}

class FullMapViewState extends State<FullMapView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stop.stopCode,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
        automaticallyImplyLeading: true,
      ),
      body: (Platform.isIOS || Platform.isAndroid)
          ? PlatformMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.stop.stopLat,
                  widget.stop.stopLon,
                ),
                zoom: 16.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
            )
          : Image.asset(
              'assets/images/appleMap.jpg',
            ),
    );
  }
}
