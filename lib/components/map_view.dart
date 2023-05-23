import 'package:flutter/material.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(53.3498, -6.2603),
        zoom: 12.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
    );
  }
}
