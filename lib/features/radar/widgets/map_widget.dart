import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../../../theme/app_theme.dart';
import '../models/user_model.dart';

class MapWidget extends HookWidget {
  final List<NearbyUser> users;
  final bool isScanning;
  final Function(NearbyUser)? onUserTap;
  final Function(String)? onManualDetection;

  const MapWidget({
    super.key,
    required this.users,
    this.isScanning = true,
    this.onUserTap,
    this.onManualDetection,
  });

  @override
  Widget build(BuildContext context) {
    final mapController = useMemoized(() => Completer<GoogleMapController>());
    final currentPosition = useState<LatLng?>(null);
    final markers = useState<Set<Marker>>({});
    final scanAnimation = useAnimationController(duration: const Duration(seconds: 2));

    // Get current position
    useEffect(() {
      _getCurrentLocation().then((position) {
        currentPosition.value = position;
        _updateMarkers();
      });
      return null;
    }, []);

    // Update markers when users change
    useEffect(() {
      _updateMarkers();
      return null;
    }, [users]);

    // Start scan animation
    useEffect(() {
      if (isScanning) {
        scanAnimation.repeat();
      } else {
        scanAnimation.stop();
      }
      return null;
    }, [isScanning]);

    Future<LatLng> _getCurrentLocation() async {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        
        final position = await Geolocator.getCurrentPosition();
        return LatLng(position.latitude, position.longitude);
      } catch (e) {
        // Default to a central location if GPS fails
        return const LatLng(40.7128, -74.0060); // New York
      }
    }

    void _updateMarkers() {
      if (currentPosition.value == null) return;

      final newMarkers = <Marker>{};
      
      // Add current user marker
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: currentPosition.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Your current location',
          ),
        ),
      );

      // Add user markers
      for (final user in users) {
        final userPosition = _calculateUserPosition(user);
        newMarkers.add(
          Marker(
            markerId: MarkerId(user.id),
            position: userPosition,
            icon: _getUserMarkerIcon(user),
            infoWindow: InfoWindow(
              title: user.name,
              snippet: '${(user.distanceKm * 1000).round()}m away',
            ),
            onTap: () => onUserTap?.call(user),
          ),
        );
      }

      markers.value = newMarkers;
    }

    LatLng _calculateUserPosition(NearbyUser user) {
      if (currentPosition.value == null) {
        return const LatLng(40.7128, -74.0060);
      }

      // Convert distance and angle to lat/lng offset
      final distanceInDegrees = user.distanceKm / 111.0; // Approximate km to degrees
      final angleRadians = user.angleDegrees * pi / 180;
      
      final deltaLat = distanceInDegrees * cos(angleRadians);
      final deltaLng = distanceInDegrees * sin(angleRadians);
      
      return LatLng(
        currentPosition.value!.latitude + deltaLat,
        currentPosition.value!.longitude + deltaLng,
      );
    }

    BitmapDescriptor _getUserMarkerIcon(NearbyUser user) {
      // Create custom marker based on signal strength
      if (user.signalStrength > 0.8) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (user.signalStrength > 0.5) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      } else if (user.signalStrength > 0.2) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      } else {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      }
    }

    return Stack(
      children: [
        // Google Map
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            mapController.complete(controller);
          },
          initialCameraPosition: CameraPosition(
            target: currentPosition.value ?? const LatLng(40.7128, -74.0060),
            zoom: 15.0,
          ),
          markers: markers.value,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          onCameraMove: (position) {
            // Update markers if needed
          },
        ),
        
        // Radar detection circle overlay
        if (isScanning)
          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: MapRadarPainter(
                  center: currentPosition.value ?? const LatLng(40.7128, -74.0060),
                  progress: scanAnimation.value,
                ),
                size: Size.infinite,
              );
            },
          ),
        
        // User count indicator
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${users.length} nearby',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Signal strength legend
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signal Strength',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendItem('Strong', Colors.green),
                _buildLegendItem('Medium', Colors.orange),
                _buildLegendItem('Weak', Colors.red),
                _buildLegendItem('Very Weak', Colors.purple),
              ],
            ),
          ),
        ),
        
        // My location button
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () async {
                final controller = await mapController.future;
                if (currentPosition.value != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLng(currentPosition.value!),
                  );
                }
              },
              icon: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MapRadarPainter extends CustomPainter {
  final LatLng center;
  final double progress;

  MapRadarPainter({
    required this.center,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // This would need to be implemented with proper coordinate conversion
    // For now, we'll create a simple radar effect
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppTheme.electricAurora.withOpacity(0.6);

    // Draw radar circles (simplified)
    final centerPoint = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 4;
    
    for (int i = 1; i <= 3; i++) {
      final radius = maxRadius * i / 3;
      canvas.drawCircle(centerPoint, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
