import 'dart:io';

import 'package:better_bus_dublin/utils/components.dart';
import 'package:better_bus_dublin/utils/models.dart';
import 'package:flutter/material.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

import '../utils/constants.dart';

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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: BoldTileText('Stop ${widget.stop.stopCode}'),
        elevation: 6,
        automaticallyImplyLeading: true,
      ),
      extendBodyBehindAppBar: true,
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
              markers: {
                Marker(
                  markerId: MarkerId(widget.stop.stopId),
                  position: LatLng(
                    widget.stop.stopLat,
                    widget.stop.stopLon,
                  ),
                  consumeTapEvents: true,
                  infoWindow: InfoWindow(
                    title: widget.stop.stopCode,
                    snippet: widget.stop.stopName,
                  ),
                ),
              },
            )
          : Image.asset(
              Constants.assetRoutesMap[AssetImages.appleMap]!,
            ),
    );
  }
}
