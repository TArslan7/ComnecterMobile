import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/detection_model.dart';
import 'detection_profile_card.dart';

/// A widget for displaying saved favorite users
class FavoritesSectionWidget extends HookWidget {
  final List<FavoriteUser> favorites;
  final Function(FavoriteUser)? onFavoriteTap;
  final Function(String)? onRemoveFromFavorites;
  final DetectionSort? sort;
  final bool isLoading;

  const FavoritesSectionWidget({
    super.key,
    required this.favorites,
    this.onFavoriteTap,
    this.onRemoveFromFavorites,
    this.sort,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final isExpanded = useState(true);

    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (favorites.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Header with expand/collapse functionality
        _buildHeader(context, isExpanded),
        
        // Favorites list
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded.value
              ? _buildFavoritesList(context, scrollController)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ValueNotifier<bool> isExpanded) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            isExpanded.value = !isExpanded.value;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
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
                        'Saved Favorites',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${favorites.length} saved users',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Expand/collapse icon
                AnimatedRotation(
                  turns: isExpanded.value ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, ScrollController scrollController) {
    return Container(
      height: 300, // Fixed height for the favorites section
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final favorite = favorites[index];
          
          // Convert FavoriteUser to UserDetection for the card
          final detection = UserDetection(
            id: 'favorite_${favorite.id}',
            userId: favorite.userId,
            name: favorite.name,
            avatar: favorite.avatar,
            distanceKm: 0, // Not relevant for favorites
            signalStrength: 1.0, // Not relevant for favorites
            detectedAt: favorite.savedAt,
            isOnline: false, // Not relevant for favorites
            interests: favorite.interests,
            metadata: favorite.metadata,
          );
          
          return DetectionProfileCard(
            detection: detection,
            isFavorite: true,
            onTap: () => onFavoriteTap?.call(favorite),
            onRemoveFromFavorites: () => onRemoveFromFavorites?.call(favorite.userId),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            strokeWidth: 2,
          ),
          const SizedBox(width: 16),
          Text(
            'Loading favorites...',
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 40,
              color: Colors.red.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe right on detections to save them as favorites',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe_right,
                  size: 16,
                  color: Colors.red.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Swipe to save',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact favorite card for use in smaller spaces
class CompactFavoriteCard extends StatelessWidget {
  final FavoriteUser favorite;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const CompactFavoriteCard({
    super.key,
    required this.favorite,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      favorite.name.isNotEmpty ? favorite.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Name
                Expanded(
                  child: Text(
                    favorite.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                // Remove button
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
