import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:kaquiz/app/theme/app_colors.dart';
import 'package:kaquiz/models/friend.dart';
import 'package:kaquiz/services/friends_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _initialLocation = LatLng(34.0209, -6.8416);

  final FriendsService _friendsService = FriendsService();

  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  // DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final friends = await _friendsService.getFriends();

      final markers = await _buildMarkers(friends);

      if (!mounted) return;

      setState(() {
        _markers = markers;
        // _lastUpdated = DateTime.now();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError(error);
    }
  }

  Future<void> _refreshFriends() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Explicitly bypass the cache.
      final friends = await _friendsService.refreshFriends();

      final markers = await _buildMarkers(friends);

      if (!mounted) return;

      setState(() {
        _markers = markers;
        // _lastUpdated = DateTime.now();
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isRefreshing = false;
      });

      _showError(error);
    }
  }

  Future<Set<Marker>> _buildMarkers(List<Friend> friends) async {
    final markers = <Marker>{};

    for (final friend in friends) {
      final location = friend.location;

      // Friend has no known location.
      if (location == null) {
        continue;
      }

      final icon = await _createAvatarMarker(friend.avatar);

      markers.add(
        Marker(
          markerId: MarkerId('friend_${friend.id}'),
          position: LatLng(location.latitude, location.longitude),
          icon: icon,
          infoWindow: InfoWindow(title: friend.name),
        ),
      );
    }

    return markers;
  }

  Future<BitmapDescriptor> _createAvatarMarker(String avatarUrl) async {
    try {
      final response = await http.get(Uri.parse(avatarUrl));

      if (response.statusCode != 200) {
        return BitmapDescriptor.defaultMarker;
      }

      return await _imageToMarker(response.bodyBytes);
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<BitmapDescriptor> _imageToMarker(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 100,
      targetHeight: 100,
    );

    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const size = 100.0;
    const center = size / 2;
    const radius = 38.0;

    // Outer translucent ring.
    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(center, center), 49, outerPaint);

    // White border.
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(center, center), 43, borderPaint);

    // Clip avatar into a circle.
    canvas.save();

    canvas.clipPath(
      Path()..addOval(
        Rect.fromCircle(center: Offset(center, center), radius: radius),
      ),
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCircle(center: Offset(center, center), radius: radius),
      Paint(),
    );

    canvas.restore();

    // Teal bottom accent inspired by your logo.
    final accentPaint = Paint()
      ..color = AppColors.accentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final accentPath = Path()
      ..moveTo(26, 79)
      ..quadraticBezierTo(50, 67, 74, 79);

    canvas.drawPath(accentPath, accentPaint);

    final picture = recorder.endRecording();

    final markerImage = await picture.toImage(size.toInt(), size.toInt());

    final markerBytes = await markerImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.bytes(markerBytes!.buffer.asUint8List());
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update friend locations.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _initialLocation,
            zoom: 12,
          ),
          markers: _markers,

          // We don't need +/- buttons.
          zoomControlsEnabled: false,

          // Native "my location" button.
          myLocationEnabled: true,
          myLocationButtonEnabled: true,

          compassEnabled: false,
          mapToolbarEnabled: false,

          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),

        // Refresh button.
        Positioned(right: 16, bottom: 24, child: _buildRefreshButton()),

        if (_isLoading)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentDark),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: AppColors.accentDark,
      child: InkWell(
        onTap: _isRefreshing ? null : _refreshFriends,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 54,
          height: 54,
          child: Center(
            child: _isRefreshing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
