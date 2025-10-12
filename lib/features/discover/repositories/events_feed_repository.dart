import 'dart:async';
import 'dart:math';
import '../models/feed_item.dart';

/// Repository for fetching events-only feed data
class EventsFeedRepository {
  static final EventsFeedRepository _instance = EventsFeedRepository._internal();
  factory EventsFeedRepository() => _instance;
  EventsFeedRepository._internal();

  final Random _random = Random();
  int _currentPage = 0;
  
  /// Fetch initial events
  Future<FeedResponse> fetchInitial({
    required double lat,
    required double lng,
    required double radiusMeters,
    bool hideBoosted = false,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    _currentPage = 0;
    final items = _generateMockEvents(
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

  /// Fetch next page of events
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
    
    final items = _generateMockEvents(
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

  /// Generate mock events for development
  List<FeedItem> _generateMockEvents({
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
      
      final event = _generateMockEvent();
      
      items.add(FeedItem(
        id: 'event_${_currentPage}_$i',
        type: FeedItemType.event,
        isBoosted: isBoosted,
        distance: distance,
        payload: event,
        detectedAt: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      ));
    }
    
    // Sort: boosted items first, then by date (upcoming first)
    items.sort((a, b) {
      if (a.isBoosted && !b.isBoosted) return -1;
      if (!a.isBoosted && b.isBoosted) return 1;
      // Sort by start time for events
      final eventA = a.payload as EventCard;
      final eventB = b.payload as EventCard;
      return eventA.startTime.compareTo(eventB.startTime);
    });
    
    return items;
  }

  EventCard _generateMockEvent() {
    final titles = [
      'Tech Meetup 2025',
      'Summer Music Festival',
      'Fitness Bootcamp',
      'Art Exhibition Opening',
      'Food Tasting Experience',
      'Networking Night',
      'Yoga Workshop',
      'Book Club Gathering',
      'Film Screening',
      'Startup Pitch Night',
      'Photography Walk',
      'Cooking Class',
      'Live Jazz Concert',
      'Community Cleanup Day',
      'Game Night',
      'Wine Tasting Event',
    ];
    
    final descriptions = [
      'Join us for an amazing experience you won\'t forget!',
      'Connect with fellow enthusiasts and have a great time',
      'Limited spots available - register now!',
      'An evening of fun, learning, and networking',
      'Bring your friends and make new connections',
      'Expert-led session with hands-on activities',
      'Discover new skills and meet like-minded people',
      'A unique opportunity to learn and grow',
    ];
    
    final locations = [
      'Downtown Convention Center',
      'City Park Pavilion',
      'Community Center Hall',
      'Tech Hub Co-working Space',
      'Riverside Amphitheater',
      'Local Coffee Shop',
      'Art Gallery District',
      'Sports Complex Arena',
      'Beachside Venue',
      'Historic Theater',
    ];
    
    final organizerNames = [
      'TechHub Organizers',
      'Community Leaders Network',
      'Event Masters Inc',
      'Local Organizers Collective',
      'Meetup Group Squad',
      'Event Planning Co',
    ];
    
    final tags = [
      ['Technology', 'Networking', 'Innovation'],
      ['Music', 'Entertainment', 'Live'],
      ['Health', 'Fitness', 'Wellness'],
      ['Food', 'Social', 'Tasting'],
      ['Arts', 'Culture', 'Exhibition'],
      ['Business', 'Professional', 'Career'],
    ];
    
    // Generate random date within next 60 days
    final startTime = DateTime.now().add(
      Duration(
        days: _random.nextInt(60),
        hours: _random.nextInt(24),
      ),
    );
    
    final maxAttendees = _random.nextBool() ? _random.nextInt(150) + 50 : 0;
    final attendeeCount = maxAttendees > 0 
        ? _random.nextInt(maxAttendees) 
        : _random.nextInt(100);
    
    return EventCard(
      id: 'event_${_random.nextInt(10000)}',
      title: titles[_random.nextInt(titles.length)],
      description: descriptions[_random.nextInt(descriptions.length)],
      startTime: startTime,
      endTime: startTime.add(Duration(hours: _random.nextInt(4) + 1)),
      location: locations[_random.nextInt(locations.length)],
      venue: _random.nextBool() ? 'Room ${_random.nextInt(10) + 1}' : null,
      attendeeCount: attendeeCount,
      maxAttendees: maxAttendees,
      isAttending: _random.nextDouble() < 0.15, // 15% already attending
      tags: tags[_random.nextInt(tags.length)],
      organizerId: 'org_${_random.nextInt(1000)}',
      organizerName: organizerNames[_random.nextInt(organizerNames.length)],
    );
  }

  /// Reset pagination
  void reset() {
    _currentPage = 0;
  }
}

