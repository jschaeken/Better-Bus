import 'package:flutter/material.dart';
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
            print("Marker tapped");
          },
        ),
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onTap: (location) => print('onTap: $location'),
      onCameraMove: (cameraUpdate) => print('onCameraMove: $cameraUpdate'),
      compassEnabled: true,
      onMapCreated: (controller) {
        Future.delayed(const Duration(seconds: 2)).then(
          (_) {
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                const CameraPosition(
                  bearing: 270.0,
                  target: LatLng(51.5160895, -0.1294527),
                  tilt: 30.0,
                  zoom: 18,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
