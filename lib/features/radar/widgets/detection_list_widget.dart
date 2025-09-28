import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/detection_model.dart';
import 'detection_profile_card.dart';
import '../../../theme/app_theme.dart';

/// A scrollable list widget for displaying recent detections
class DetectionListWidget extends HookWidget {
  final List<UserDetection> detections;
  final List<FavoriteUser> favorites;
  final Function(UserDetection)? onDetectionTap;
  final Function(UserDetection)? onSaveToFavorites;
  final Function(String)? onRemoveFromFavorites;
  final DetectionFilter? filter;
  final DetectionSort? sort;
  final bool showSwipeHints;
  final bool isLoading;

  const DetectionListWidget({
    super.key,
    required this.detections,
    required this.favorites,
    this.onDetectionTap,
    this.onSaveToFavorites,
    this.onRemoveFromFavorites,
    this.filter,
    this.sort,
    this.showSwipeHints = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final showHint = useState(showSwipeHints);

    // Hide swipe hints after a delay
    useEffect(() {
      if (showSwipeHints) {
        Future.delayed(const Duration(seconds: 3), () {
          showHint.value = false;
        });
      }
      return null;
    }, [showSwipeHints]);

    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (detections.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Header with filter and sort options
        _buildHeader(context),
        
        // Detections list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Trigger refresh - this would be handled by the parent
            },
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: detections.length,
              itemBuilder: (context, index) {
                final detection = detections[index];
                final isFavorite = favorites.any((f) => f.userId == detection.userId);
                
                return DetectionProfileCard(
                  detection: detection,
                  isFavorite: isFavorite,
                  onTap: () => onDetectionTap?.call(detection),
                  onSaveToFavorites: isFavorite 
                      ? null 
                      : () => onSaveToFavorites?.call(detection),
                  onRemoveFromFavorites: isFavorite 
                      ? () => onRemoveFromFavorites?.call(detection.userId)
                      : null,
                  showSwipeHint: showHint.value && index == 0,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.radar,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Title and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Detections',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${detections.length} users detected',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Filter/Sort button
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: Icon(
              Icons.tune,
              color: AppTheme.primary,
              size: 20,
            ),
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
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
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.radar_outlined,
              size: 60,
              color: AppTheme.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Detections Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning to discover people nearby',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to radar screen
            },
            icon: const Icon(Icons.radar),
            label: const Text('Start Scanning'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        currentFilter: filter ?? DetectionFilter.recent,
        currentSort: sort ?? DetectionSort.newest,
        onFilterChanged: (newFilter) {
          // Handle filter change
        },
        onSortChanged: (newSort) {
          // Handle sort change
        },
      ),
    );
  }
}

/// Bottom sheet for filter and sort options
class _FilterBottomSheet extends HookWidget {
  final DetectionFilter currentFilter;
  final DetectionSort currentSort;
  final Function(DetectionFilter) onFilterChanged;
  final Function(DetectionSort) onSortChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.currentSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedFilter = useState(currentFilter);
    final selectedSort = useState(currentSort);

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
            
            // Title
            Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Filter section
            Text(
              'Time Filter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              children: DetectionFilter.values.map((filter) {
                final isSelected = selectedFilter.value == filter;
                return FilterChip(
                  label: Text(_getFilterLabel(filter)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      selectedFilter.value = filter;
                    }
                  },
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primary,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Sort section
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              children: DetectionSort.values.map((sort) {
                final isSelected = selectedSort.value == sort;
                return FilterChip(
                  label: Text(_getSortLabel(sort)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      selectedSort.value = sort;
                    }
                  },
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primary,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onFilterChanged(selectedFilter.value);
                  onSortChanged(selectedSort.value);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(DetectionFilter filter) {
    switch (filter) {
      case DetectionFilter.all:
        return 'All Time';
      case DetectionFilter.recent:
        return 'Last 24h';
      case DetectionFilter.today:
        return 'Today';
      case DetectionFilter.thisWeek:
        return 'This Week';
      case DetectionFilter.thisMonth:
        return 'This Month';
    }
  }

  String _getSortLabel(DetectionSort sort) {
    switch (sort) {
      case DetectionSort.newest:
        return 'Newest';
      case DetectionSort.oldest:
        return 'Oldest';
      case DetectionSort.distance:
        return 'Distance';
      case DetectionSort.name:
        return 'Name';
      case DetectionSort.signalStrength:
        return 'Signal';
    }
  }
}
