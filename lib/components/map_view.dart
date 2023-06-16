import 'package:flutter/material.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class MapView extends StatelessWidget {
  const MapView({
    required this.onMapCreated,
    required this.cameraIdleCallback,
    required this.onCameraMove,
    super.key,
    required this.markers,
  });

  final Function(PlatformMapController mapController) onMapCreated;
  final Function(CameraPosition cameraPosition) onCameraMove;
  final VoidCallback cameraIdleCallback;
  final Set<Marker> markers;

  @override
  Widget build(BuildContext context) {
    return PlatformMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(53.3498, -6.2603),
        zoom: 12.0,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) => onMapCreated(controller),
      onCameraIdle: () => cameraIdleCallback,
      onCameraMove: (position) => onCameraMove(position),
    );
  }
}
