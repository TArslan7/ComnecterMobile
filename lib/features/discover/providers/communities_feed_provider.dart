import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import '../repositories/communities_feed_repository.dart';

/// Communities feed state
class CommunitiesFeedState {
  final List<FeedItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? cursor;
  final String? error;
  final bool hideBoosted;

  const CommunitiesFeedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.cursor,
    this.error,
    this.hideBoosted = false,
  });

  CommunitiesFeedState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? cursor,
    String? error,
    bool? hideBoosted,
  }) {
    return CommunitiesFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: error,
      hideBoosted: hideBoosted ?? this.hideBoosted,
    );
  }

  /// Get filtered items based on hideBoosted setting
  List<FeedItem> get filteredItems {
    if (hideBoosted) {
      return items.where((item) => !item.isBoosted).toList();
    }
    return items;
  }

  /// Check if feed is empty
  bool get isEmpty => items.isEmpty && !isLoading;

  /// Check if there was an error
  bool get hasError => error != null;
}

/// Controller for managing the communities feed
class CommunitiesFeedController extends StateNotifier<CommunitiesFeedState> {
  CommunitiesFeedController({
    required this.repository,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  }) : super(const CommunitiesFeedState());

  final CommunitiesFeedRepository repository;
  final double lat;
  final double lng;
  final double radiusMeters;

  /// Load initial feed items
  Future<void> loadInitial({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      if (forceRefresh) {
        repository.reset();
      }

      final response = await repository.fetchInitial(
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
        hideBoosted: state.hideBoosted,
      );

      state = state.copyWith(
        items: response.items,
        isLoading: false,
        hasMore: response.hasMore,
        cursor: response.cursor,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load next page of feed items
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.cursor == null) return;

    state = state.copyWith(
      isLoadingMore: true,
      error: null,
    );

    try {
      final response = await repository.fetchNext(
        cursor: state.cursor!,
        lat: lat,
        lng: lng,
        radiusMeters: radiusMeters,
        hideBoosted: state.hideBoosted,
      );

      state = state.copyWith(
        items: [...state.items, ...response.items],
        isLoadingMore: false,
        hasMore: response.hasMore,
        cursor: response.cursor,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh feed (pull-to-refresh)
  Future<void> refresh() async {
    await loadInitial(forceRefresh: true);
  }

  /// Toggle hide boosted items (premium feature)
  Future<void> toggleHideBoosted(bool value) async {
    if (state.hideBoosted == value) return;

    state = state.copyWith(
      hideBoosted: value,
    );

    // Reload feed with new filter
    await loadInitial(forceRefresh: true);
  }

  /// Remove a specific item from the feed
  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != itemId).toList(),
    );
  }

  /// Update a specific item in the feed
  void updateItem(String itemId, FeedItem updatedItem) {
    final items = state.items.map((item) {
      if (item.id == itemId) {
        return updatedItem;
      }
      return item;
    }).toList();

    state = state.copyWith(items: items);
  }
}

/// Provider for the communities feed repository
final communitiesFeedRepositoryProvider = Provider<CommunitiesFeedRepository>((ref) {
  return CommunitiesFeedRepository();
});

/// Provider factory for creating communities feed controllers
final communitiesFeedControllerProvider = StateNotifierProvider.family
    .autoDispose<CommunitiesFeedController, CommunitiesFeedState, CommunitiesFeedParams>(
  (ref, params) {
    final repository = ref.watch(communitiesFeedRepositoryProvider);
    final controller = CommunitiesFeedController(
      repository: repository,
      lat: params.lat,
      lng: params.lng,
      radiusMeters: params.radiusMeters,
    );
    
    // Auto-load initial data
    Future.microtask(() => controller.loadInitial());
    
    return controller;
  },
);

/// Parameters for communities feed controller
class CommunitiesFeedParams {
  final double lat;
  final double lng;
  final double radiusMeters;

  const CommunitiesFeedParams({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunitiesFeedParams &&
        other.lat == lat &&
        other.lng == lng &&
        other.radiusMeters == radiusMeters;
  }

  @override
  int get hashCode => Object.hash(lat, lng, radiusMeters);
}

