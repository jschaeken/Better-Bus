import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(47.6, 8.8796),
        zoom: 16.0,
      ),
      markers: <Marker>{
        Marker(
          markerId: MarkerId('marker_1'),
          position: const LatLng(47.6, 8.8796),
          consumeTapEvents: true,
          infoWindow: const InfoWindow(
            title: 'PlatformMarker',
            snippet: "Hi I'm a Platform Marker",
          ),
          onTap: () {
            handleMarkerTap();
          },
        ),
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
    );
  }
}

void handleMarkerTap() {
  print('Marker tapped');
  HapticFeedback.lightImpact();
}
