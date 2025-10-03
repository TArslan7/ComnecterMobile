import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../radar/models/user_model.dart';

class MapView extends HookWidget {
  final List<NearbyUser> detectedUsers;
  final List<Map<String, dynamic>> communities;
  final List<Map<String, dynamic>> events;

  const MapView({
    super.key,
    required this.detectedUsers,
    required this.communities,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final mapController = useState<GoogleMapController?>(null);
    final currentPosition = useState<LatLng?>(null);
    final isLoading = useState(true);
    final selectedMarker = useState<String?>(null);
    final hasError = useState(false);

    // Initialize map
    useEffect(() {
      _initializeMap(currentPosition, isLoading, hasError);
      return null;
    }, []);

    // Create markers
    final markers = useMemoized(() {
      final markerList = <Marker>[];
      
      // Add user's current position
      if (currentPosition.value != null) {
        markerList.add(
          Marker(
            markerId: const MarkerId('current_position'),
            position: currentPosition.value!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'You are here',
              snippet: 'Your current location',
            ),
          ),
        );
      }

      // Add detected users
      for (int i = 0; i < detectedUsers.length; i++) {
        final user = detectedUsers[i];
        final position = _generateRandomPosition(currentPosition.value);
        
        markerList.add(
          Marker(
            markerId: MarkerId('user_${user.id}'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: user.name,
              snippet: '${user.distanceKm.toStringAsFixed(1)} km away',
            ),
            onTap: () => selectedMarker.value = user.id,
          ),
        );
      }

      // Add communities
      for (int i = 0; i < communities.length; i++) {
        final community = communities[i];
        final position = _generateRandomPosition(currentPosition.value);
        
        markerList.add(
          Marker(
            markerId: MarkerId('community_${community['id']}'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: community['name'],
              snippet: '${community['memberCount']} members',
            ),
            onTap: () => selectedMarker.value = 'community_${community['id']}',
          ),
        );
      }

      // Add events
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final position = _generateRandomPosition(currentPosition.value);
        
        markerList.add(
          Marker(
            markerId: MarkerId('event_${event['id']}'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: event['title'],
              snippet: event['location'],
            ),
            onTap: () => selectedMarker.value = 'event_${event['id']}',
          ),
        );
      }

      return markerList;
    }, [detectedUsers, communities, events, currentPosition.value]);

    if (isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError.value) {
      return _buildErrorState(context);
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: currentPosition.value ?? const LatLng(37.7749, -122.4194),
            zoom: 15,
          ),
          markers: markers.toSet(),
          onMapCreated: (GoogleMapController controller) {
            mapController.value = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          onTap: (LatLng position) {
            selectedMarker.value = null;
          },
        ),
        
        // Legend
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem('You', BitmapDescriptor.hueBlue),
                const SizedBox(height: 4),
                _buildLegendItem('Users', BitmapDescriptor.hueGreen),
                const SizedBox(height: 4),
                _buildLegendItem('Communities', BitmapDescriptor.hueOrange),
                const SizedBox(height: 4),
                _buildLegendItem('Events', BitmapDescriptor.hueRed),
              ],
            ),
          ),
        ),

        // Selected item details
        if (selectedMarker.value != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildSelectedItemDetails(context, selectedMarker.value!),
          ),
      ],
    );
  }

  Widget _buildLegendItem(String label, double hue) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 
              (hue * 255 / 360).round(), 
              ((hue + 120) * 255 / 360).round(), 
              ((hue + 240) * 255 / 360).round()),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSelectedItemDetails(BuildContext context, String markerId) {
    if (markerId.startsWith('user_')) {
      final user = detectedUsers.firstWhere((u) => u.id == markerId.substring(5));
      return _buildUserDetails(context, user);
    } else if (markerId.startsWith('community_')) {
      final communityId = markerId.substring(10);
      final community = communities.firstWhere((c) => c['id'] == communityId);
      return _buildCommunityDetails(context, community);
    } else if (markerId.startsWith('event_')) {
      final eventId = markerId.substring(6);
      final event = events.firstWhere((e) => e['id'] == eventId);
      return _buildEventDetails(context, event);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildUserDetails(BuildContext context, NearbyUser user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              user.avatar,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${user.distanceKm.toStringAsFixed(1)} km away',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Handle connect action
            },
            icon: const Icon(Icons.person_add),
            tooltip: 'Connect',
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityDetails(BuildContext context, Map<String, dynamic> community) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(
              community['image'] ?? '👥',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  community['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${community['memberCount']} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Handle join action
            },
            icon: const Icon(Icons.group_add),
            tooltip: 'Join',
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context, Map<String, dynamic> event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.error,
            child: Text(
              event['image'] ?? '🎉',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event['title'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  event['location'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Handle attend action
            },
            icon: const Icon(Icons.event_available),
            tooltip: 'Attend',
          ),
        ],
      ),
    );
  }

  Future<void> _initializeMap(
    ValueNotifier<LatLng?> currentPosition,
    ValueNotifier<bool> isLoading,
    ValueNotifier<bool> hasError,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      currentPosition.value = LatLng(position.latitude, position.longitude);
      isLoading.value = false;
    } catch (e) {
      // Use default position if location access fails
      currentPosition.value = const LatLng(37.7749, -122.4194);
      isLoading.value = false;
      hasError.value = true;
    }
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Map View Coming Soon',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Google Maps integration is being configured.\nFor now, use Radar or Scroll view to discover people.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // This would switch to radar view
            },
            icon: const Icon(Icons.radar),
            label: const Text('Use Radar View'),
          ),
        ],
      ),
    );
  }

  LatLng _generateRandomPosition(LatLng? center) {
    if (center == null) {
      return const LatLng(37.7749, -122.4194);
    }
    
    // Generate random position within ~1km radius
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    final latOffset = (random - 500) / 100000.0; // ~1km
    final lngOffset = ((random * 2) % 1000 - 500) / 100000.0;
    
    return LatLng(
      center.latitude + latOffset,
      center.longitude + lngOffset,
    );
  }
}
