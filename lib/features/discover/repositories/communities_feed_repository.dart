import 'dart:async';
import 'dart:math';
import '../models/feed_item.dart';

/// Repository for fetching communities-only feed data
class CommunitiesFeedRepository {
  static final CommunitiesFeedRepository _instance = CommunitiesFeedRepository._internal();
  factory CommunitiesFeedRepository() => _instance;
  CommunitiesFeedRepository._internal();

  final Random _random = Random();
  int _currentPage = 0;
  
  /// Fetch initial communities
  Future<FeedResponse> fetchInitial({
    required double lat,
    required double lng,
    required double radiusMeters,
    bool hideBoosted = false,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    _currentPage = 0;
    final items = _generateMockCommunities(
      lat: lat,
      lng: lng,
      radiusMeters: radiusMeters,
      count: 10,
      hideBoosted: hideBoosted,
    );
    
    return FeedResponse(
      items: items,
      cursor: 'page_1',
      hasMore: true,
    );
  }

  /// Fetch next page of communities
  Future<FeedResponse> fetchNext({
    required String cursor,
    required double lat,
    required double lng,
    required double radiusMeters,
    bool hideBoosted = false,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    _currentPage++;
    
    // Simulate running out of content after a few pages
    if (_currentPage >= 5) {
      return const FeedResponse(
        items: [],
        cursor: null,
        hasMore: false,
      );
    }
    
    final items = _generateMockCommunities(
      lat: lat,
      lng: lng,
      radiusMeters: radiusMeters,
      count: 8,
      hideBoosted: hideBoosted,
    );
    
    final hasMore = _currentPage < 4;
    
    return FeedResponse(
      items: items,
      cursor: hasMore ? 'page_${_currentPage + 1}' : null,
      hasMore: hasMore,
    );
  }

  /// Generate mock communities for development
  List<FeedItem> _generateMockCommunities({
    required double lat,
    required double lng,
    required double radiusMeters,
    required int count,
    bool hideBoosted = false,
  }) {
    final items = <FeedItem>[];
    
    for (int i = 0; i < count; i++) {
      final isBoosted = !hideBoosted && _random.nextDouble() < 0.3; // 30% boosted
      final distance = _random.nextDouble() * radiusMeters;
      
      final community = _generateMockCommunity();
      
      items.add(FeedItem(
        id: 'community_${_currentPage}_$i',
        type: FeedItemType.community,
        isBoosted: isBoosted,
        distance: distance,
        payload: community,
        detectedAt: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      ));
    }
    
    // Sort: boosted items first, then by distance
    items.sort((a, b) {
      if (a.isBoosted && !b.isBoosted) return -1;
      if (!a.isBoosted && b.isBoosted) return 1;
      return a.distance.compareTo(b.distance);
    });
    
    return items;
  }

  CommunityCard _generateMockCommunity() {
    final names = [
      'Tech Innovators Hub',
      'Fitness Warriors',
      'Book Lovers Society',
      'Photography Enthusiasts',
      'Foodie Paradise',
      'Travel Buddies Network',
      'Music Makers Collective',
      'Art & Design Studio',
      'Gaming Squad',
      'Startup Founders Circle',
      'Yoga & Wellness Community',
      'Coffee Connoisseurs',
      'Film Buffs United',
      'Nature Lovers Club',
      'Crypto Enthusiasts',
      'Language Exchange',
      'Pet Parents Group',
      'Sustainable Living',
    ];
    
    final avatars = ['💻', '🏃‍♂️', '📚', '📸', '🍕', '✈️', '🎵', '🎨', '🎮', '🚀', '🧘', '☕', '🎬', '🌿', '💰', '🗣️', '🐕', '🌱'];
    
    final descriptions = [
      'A vibrant community of like-minded individuals passionate about innovation and growth',
      'Join us for weekly meetups, exciting activities, and meaningful connections',
      'Connect, share, and grow together in this amazing community of enthusiasts',
      'Where passion meets friendship and ideas come to life',
      'Building meaningful connections one event at a time',
      'Your local community for all things awesome and inspiring',
      'Discover, learn, and share with people who care about the same things',
      'Creating a supportive environment for everyone to thrive',
    ];
    
    final tagsList = [
      ['Technology', 'Innovation', 'Networking'],
      ['Health', 'Wellness', 'Fitness'],
      ['Arts', 'Culture', 'Creativity'],
      ['Food', 'Drinks', 'Culinary'],
      ['Travel', 'Adventure', 'Exploration'],
      ['Music', 'Entertainment', 'Concerts'],
      ['Business', 'Entrepreneurship', 'Growth'],
      ['Education', 'Learning', 'Development'],
    ];
    
    return CommunityCard(
      id: 'community_${_random.nextInt(10000)}',
      name: names[_random.nextInt(names.length)],
      description: descriptions[_random.nextInt(descriptions.length)],
      avatar: avatars[_random.nextInt(avatars.length)],
      memberCount: _random.nextInt(5000) + 10,
      tags: tagsList[_random.nextInt(tagsList.length)],
      isJoined: _random.nextDouble() < 0.2, // 20% already joined
      isVerified: _random.nextDouble() < 0.3, // 30% verified
    );
  }

  /// Reset pagination
  void reset() {
    _currentPage = 0;
  }
}

