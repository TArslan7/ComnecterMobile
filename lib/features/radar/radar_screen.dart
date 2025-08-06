import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'dart:async';
import 'dart:math';
import 'models/user_model.dart';
import 'widgets/radar_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/loading_widget.dart';
import 'widgets/user_list_widget.dart';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nearbyUsers = useState<List<NearbyUser>>([]);
    final isLoading = useState<bool>(false);
    final refreshController = useMemoized(() => RefreshController());
    final isMounted = useRef(true);

    // Function to fetch nearby users (simulated)
    Future<void> fetchNearbyUsers() async {
      isLoading.value = true;
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Generate random number of users (0-8)
      final random = Random();
      final userCount = random.nextInt(9);
      
      nearbyUsers.value = NearbyUser.generateMockUsers(userCount);
      isLoading.value = false;
    }

    // Auto-refresh timer every 3 seconds
    useEffect(() {
      // Initial load
      fetchNearbyUsers();
      
      // Set up periodic refresh
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        // Check if the widget is still mounted before updating state
        if (!isLoading.value && isMounted.value) {
          fetchNearbyUsers();
        }
      });
      
      return () {
        isMounted.value = false;
        timer.cancel();
      };
    }, []);

    // Manual refresh handler
    Future<void> handleRefresh() async {
      await fetchNearbyUsers();
      refreshController.refreshCompleted();
    }

    // Handle user tap
    void handleUserTap(NearbyUser user) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tapped on ${user.name} (${user.distanceKm.toStringAsFixed(1)} km away)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading.value ? null : fetchNearbyUsers,
            tooltip: 'Vernieuwen',
          ),
        ],
      ),
      body: SmartRefresher(
        controller: refreshController,
        enablePullDown: true,
        onRefresh: handleRefresh,
        header: const WaterDropMaterialHeader(
          backgroundColor: Colors.blueAccent,
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Loading state
              if (isLoading.value && nearbyUsers.value.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: LoadingWidget(),
                ),
              
              // Empty state
              if (!isLoading.value && nearbyUsers.value.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: EmptyStateWidget(),
                ),
              
              // Radar display with users
              if (nearbyUsers.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: RadarWidget(
                    users: nearbyUsers.value,
                    isLoading: isLoading.value,
                    size: 320,
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // User list
              if (nearbyUsers.value.isNotEmpty)
                UserListWidget(
                  users: nearbyUsers.value,
                  onUserTap: handleUserTap,
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
