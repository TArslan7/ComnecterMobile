import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'models/detection_model.dart';
import 'services/detection_history_service.dart';
import '../../theme/app_theme.dart';

/// Main screen for displaying detection history and favorites
class DetectionHistoryScreen extends HookWidget {
  const DetectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final detectionService = useMemoized(() => DetectionHistoryService(), []);
    final detections = useState<List<UserDetection>>([]);
    final favorites = useState<List<FavoriteUser>>([]);
    final isLoading = useState(true);
    final currentFilter = useState(DetectionFilter.recent);
    final currentSort = useState(DetectionSort.newest);
    final showSwipeHints = useState(true);
    final selectedTab = useState(0); // 0 = Recent Detections, 1 = Saved Favorites

    // Initialize service and load data
    useEffect(() {
      Future.microtask(() async {
        try {
          await detectionService.initialize();
          // Load initial data after initialization
          detections.value = detectionService.getDetections(
            filter: currentFilter.value,
            sort: currentSort.value,
          );
          favorites.value = detectionService.getFavorites(sort: currentSort.value);
          
          // Debug: Print current detections count
          print('Detection History Screen - Loaded ${detections.value.length} detections');
          print('Detection History Screen - Loaded ${favorites.value.length} favorites');
          
          isLoading.value = false;
        } catch (e) {
          print('Error initializing detection history service: $e');
          isLoading.value = false;
        }
      });
      return null;
    }, []);

    // Listen to detection updates
    useEffect(() {
      final subscription = detectionService.detectionsStream.listen((newDetections) {
        detections.value = detectionService.getDetections(
          filter: currentFilter.value,
          sort: currentSort.value,
        );
      });
      return subscription.cancel;
    }, [currentFilter.value, currentSort.value]);

    // Listen to favorites updates
    useEffect(() {
      final subscription = detectionService.favoritesStream.listen((newFavorites) {
        favorites.value = detectionService.getFavorites(sort: currentSort.value);
      });
      return subscription.cancel;
    }, [currentSort.value]);

    // Load initial data
    useEffect(() {
      if (!isLoading.value) {
        detections.value = detectionService.getDetections(
          filter: currentFilter.value,
          sort: currentSort.value,
        );
        favorites.value = detectionService.getFavorites(sort: currentSort.value);
      }
      return null;
    }, [isLoading.value, currentFilter.value, currentSort.value]);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          'Detection History',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSettingsDialog(context, detectionService),
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    context,
                    'Recent Detections',
                    Icons.radar,
                    selectedTab.value == 0,
                    () {
                      selectedTab.value = 0;
                    },
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    context,
                    'Saved Favorites',
                    Icons.favorite,
                    selectedTab.value == 1,
                    () {
                      selectedTab.value = 1;
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Content area - show selected tab
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: selectedTab.value == 0
                  ? Container(
                      key: const ValueKey('detections'),
                      child: _buildDetectionsSection(
                        context,
                        detections.value,
                        favorites.value,
                        currentFilter.value,
                        currentSort.value,
                        showSwipeHints.value,
                        isLoading.value,
                        detectionService,
                      ),
                    )
                  : Container(
                      key: const ValueKey('favorites'),
                      child: _buildFavoritesSection(
                        context,
                        favorites.value,
                        currentSort.value,
                        isLoading.value,
                        detectionService,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetectionTap(BuildContext context, UserDetection detection) {
    // Navigate to user profile or show details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetectionDetailsSheet(detection: detection),
    );
  }

  void _onFavoriteTap(BuildContext context, FavoriteUser favorite) {
    // Navigate to user profile or show details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FavoriteDetailsSheet(favorite: favorite),
    );
  }

  void _onSaveToFavorites(DetectionHistoryService service, UserDetection detection) {
    service.addToFavorites(detection);
  }

  void _onRemoveFromFavorites(DetectionHistoryService service, String userId) {
    service.removeFromFavorites(userId);
  }

  void _showSettingsDialog(BuildContext context, DetectionHistoryService service) {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(service: service),
    );
  }

  void _showClearHistoryDialog(BuildContext context, DetectionHistoryService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.clear_all,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Clear Detection History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to clear your detection history?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action will remove all recent detections from your history.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Warning section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This action cannot be undone. Your saved favorites will remain safe.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearDetectionHistoryWithAnimation(context, service);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Clear History',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      ),
    );
  }

  Future<void> _clearDetectionHistoryWithAnimation(BuildContext context, DetectionHistoryService service) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Clear the detection history
      await service.clearDetections();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Detection history cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing history: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildTabButton(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionsSection(
    BuildContext context,
    List<UserDetection> detections,
    List<FavoriteUser> favorites,
    DetectionFilter filter,
    DetectionSort sort,
    bool showSwipeHints,
    bool isLoading,
    DetectionHistoryService detectionService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.radar,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Detections',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              if (detections.isNotEmpty) ...[
                Text(
                  '${detections.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showClearHistoryDialog(context, detectionService),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.clear_all,
                            color: Colors.red.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else
                Text(
                  '${detections.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Detections list
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading detections...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : detections.isEmpty
                    ? _buildEmptyDetectionsState(context)
                    : ListView.separated(
                        itemCount: detections.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (context, index) {
                          final detection = detections[index];
                          final isFavorite = favorites.any((f) => f.userId == detection.userId);
                          
                          return _buildDetectionCard(
                            context,
                            detection,
                            isFavorite,
                            () => _onDetectionTap(context, detection),
                            () => _onSaveToFavorites(detectionService, detection),
                            () => _onRemoveFromFavorites(detectionService, detection.userId),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(
    BuildContext context,
    List<FavoriteUser> favorites,
    DetectionSort sort,
    bool isLoading,
    DetectionHistoryService detectionService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Saved Favorites',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const Spacer(),
              Text(
                '${favorites.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Favorites list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : favorites.isEmpty
                    ? _buildEmptyFavoritesState(context)
                    : ListView.builder(
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final favorite = favorites[index];
                          
                          return _buildFavoriteCard(
                            context,
                            favorite,
                            () => _onFavoriteTap(context, favorite),
                            () => _onRemoveFromFavorites(detectionService, favorite.userId),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard(
    BuildContext context,
    UserDetection detection,
    bool isFavorite,
    VoidCallback onTap,
    VoidCallback onSaveToFavorites,
    VoidCallback onRemoveFromFavorites,
  ) {
    return _SwipeableDetectionCard(
      detection: detection,
      isFavorite: isFavorite,
      onTap: onTap,
      onSaveToFavorites: onSaveToFavorites,
      onRemoveFromFavorites: onRemoveFromFavorites,
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context,
    FavoriteUser favorite,
    VoidCallback onTap,
    VoidCallback onRemove,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      favorite.name.isNotEmpty ? favorite.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saved ${_formatTimestamp(favorite.savedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Remove button
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  tooltip: 'Remove from favorites',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDetectionsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Motivational icon with animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.radar_outlined,
                size: 64,
                color: AppTheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // Motivational message
            Text(
              'Ready to Connect?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your radar is waiting to discover amazing people around you. Every connection starts with a single scan!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Call to action button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => context.push('/'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.radar,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Start Scanning Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Additional motivational text
            Text(
              '✨ Discover • Connect • Grow',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavoritesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Motivational icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withValues(alpha: 0.1),
                    Colors.red.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.favorite_border,
                size: 64,
                color: Colors.red.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // Motivational message
            Text(
              'Build Your Circle',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start swiping right on people you\'d like to connect with. Your favorites will appear here!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Helpful tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Swipe right on any detection to save it as a favorite',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Additional motivational text
            Text(
              '💝 Every connection matters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// A swipeable detection card with glow animations
class _SwipeableDetectionCard extends HookWidget {
  final UserDetection detection;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onSaveToFavorites;
  final VoidCallback? onRemoveFromFavorites;
  final bool isClearing;

  const _SwipeableDetectionCard({
    required this.detection,
    this.isFavorite = false,
    this.onTap,
    this.onSaveToFavorites,
    this.onRemoveFromFavorites,
    this.isClearing = false,
  });

  @override
  Widget build(BuildContext context) {
    final swipeOffset = useState(0.0);
    final isSwipeActive = useState(false);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );
    final glowController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );
    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );

    // Trigger fade-out animation when clearing
    useEffect(() {
      if (isClearing) {
        fadeController.forward();
      }
      return null;
    }, [isClearing]);

    // Handle swipe gestures
    void handlePanUpdate(DragUpdateDetails details) {
      if (isFavorite) return; // Don't allow swiping for favorites
      
      final delta = details.delta.dx;
      final newOffset = (swipeOffset.value + delta).clamp(-200.0, 200.0);
      swipeOffset.value = newOffset;
      
      if (newOffset.abs() > 50) {
        isSwipeActive.value = true;
        animationController.forward();
      } else {
        isSwipeActive.value = false;
        animationController.reverse();
      }
    }

    void handlePanEnd(DragEndDetails details) {
      if (isFavorite) return;
      
      if (swipeOffset.value > 100) {
        // Swipe right - save to favorites with glow animation
        glowController.forward().then((_) {
          glowController.reverse();
        });
        onSaveToFavorites?.call();
        HapticFeedback.mediumImpact();
      } else {
        // Reset position
        animationController.reverse();
      }
      
      swipeOffset.value = 0.0;
      isSwipeActive.value = false;
    }

    return GestureDetector(
      onPanUpdate: handlePanUpdate,
      onPanEnd: handlePanEnd,
      onTap: onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([animationController, glowController, fadeController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: fadeController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-1.0, 0.0),
              ).animate(CurvedAnimation(
                parent: fadeController,
                curve: Curves.easeInOut,
              )),
              child: Transform.translate(
                offset: Offset(swipeOffset.value, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                      // Glow effect when swiping
                      if (isSwipeActive.value)
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4 + (glowController.value * 0.3)),
                          blurRadius: 25 + (glowController.value * 35),
                          spreadRadius: 8 + (glowController.value * 20),
                        ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Main card content
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFavorite 
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                    child: Row(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  detection.name.isNotEmpty ? detection.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            if (isFavorite)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                detection.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: AppTheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${detection.distanceKm.toStringAsFixed(1)} km',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTimestamp(detection.detectedAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Action button
                        if (isFavorite)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: onRemoveFromFavorites,
                              icon: Icon(
                                Icons.favorite,
                                color: Colors.red.shade600,
                                size: 22,
                              ),
                              tooltip: 'Remove from favorites',
                              padding: const EdgeInsets.all(12),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: onSaveToFavorites,
                              icon: Icon(
                                Icons.favorite_border,
                                color: Colors.grey.shade600,
                                size: 22,
                              ),
                              tooltip: 'Add to favorites',
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Swipe action indicators
                  if (!isFavorite) _buildSwipeActions(context, animationController, swipeOffset.value),
                ],
              ),
            ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeActions(BuildContext context, AnimationController animationController, double swipeOffset) {
    return Positioned.fill(
      child: Row(
        children: [
          // Right side - save action
          if (swipeOffset > 50)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.green.withValues(alpha: 0.1),
                      Colors.green.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (animationController.value * 0.2),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.green.shade600,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Bottom sheet for showing detection details
class _DetectionDetailsSheet extends StatelessWidget {
  final UserDetection detection;

  const _DetectionDetailsSheet({required this.detection});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    detection.name.isNotEmpty ? detection.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detection.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detected ${_formatTimestamp(detection.detectedAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Details
            _buildDetailRow('Distance', '${detection.distanceKm.toStringAsFixed(1)} km'),
            _buildDetailRow('Signal Strength', '${(detection.signalStrength * 100).round()}%'),
            _buildDetailRow('Status', detection.isOnline ? 'Online' : 'Offline'),
            
            if (detection.interests.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Interests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: detection.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: AppTheme.primary),
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to chat or send friend request
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Add to favorites
                    },
                    icon: const Icon(Icons.favorite),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Bottom sheet for showing favorite details
class _FavoriteDetailsSheet extends StatelessWidget {
  final FavoriteUser favorite;

  const _FavoriteDetailsSheet({required this.favorite});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  child: Text(
                    favorite.name.isNotEmpty ? favorite.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saved ${_formatTimestamp(favorite.savedAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Notes section
            if (favorite.notes != null && favorite.notes!.isNotEmpty) ...[
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  favorite.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (favorite.interests.isNotEmpty) ...[
              Text(
                'Interests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: favorite.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: Colors.red.shade700),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to chat or send friend request
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Remove from favorites
                    },
                    icon: const Icon(Icons.favorite),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Settings dialog for detection history
class _SettingsDialog extends HookWidget {
  final DetectionHistoryService service;

  const _SettingsDialog({required this.service});

  @override
  Widget build(BuildContext context) {
    final settings = useState(service.settings);

    return AlertDialog(
      title: const Text('Detection History Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Auto-save detections'),
            subtitle: const Text('Automatically save new detections'),
            value: settings.value.enableAutoSave,
            onChanged: (value) {
              settings.value = settings.value.copyWith(enableAutoSave: value);
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Show notifications for new detections'),
            value: settings.value.enableNotifications,
            onChanged: (value) {
              settings.value = settings.value.copyWith(enableNotifications: value);
            },
          ),
          ListTile(
            title: const Text('Max detections'),
            subtitle: Text('${settings.value.maxDetections}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    if (settings.value.maxDetections > 100) {
                      settings.value = settings.value.copyWith(
                        maxDetections: settings.value.maxDetections - 100,
                      );
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () {
                    if (settings.value.maxDetections < 5000) {
                      settings.value = settings.value.copyWith(
                        maxDetections: settings.value.maxDetections + 100,
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            service.updateSettings(settings.value);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
