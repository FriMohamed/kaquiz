import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const LatLng _initialLocation = LatLng(
    34.0209,
    -6.8416,
  );

  @override
  Widget build(BuildContext context) {
    return const GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialLocation,
        zoom: 12,
      ),
    );
  }
}