import 'package:flutter_test/flutter_test.dart';
import 'package:comnecter_mobile/features/discover/models/feed_item.dart';
import 'package:comnecter_mobile/features/discover/repositories/all_feed_repository.dart';

void main() {
  group('FeedItem Tests', () {
    test('FeedItem.fromJson creates valid UserCard', () {
      final json = {
        'id': 'user_1',
        'type': 'user',
        'isBoosted': true,
        'distance': 500.0,
        'detectedAt': DateTime.now().toIso8601String(),
        'payload': {
          'id': 'user_1',
          'name': 'John Doe',
          'avatar': '👨',
          'bio': 'Test bio',
          'interests': ['Music', 'Travel'],
          'mutualFriendsCount': 5,
          'isOnline': true,
        },
      };

      final item = FeedItem.fromJson(json);

      expect(item.id, 'user_1');
      expect(item.type, FeedItemType.user);
      expect(item.isBoosted, true);
      expect(item.distance, 500.0);
      expect(item.payload, isA<UserCard>());
      
      final user = item.payload as UserCard;
      expect(user.name, 'John Doe');
      expect(user.interests, ['Music', 'Travel']);
    });

    test('FeedItem.fromJson creates valid CommunityCard', () {
      final json = {
        'id': 'community_1',
        'type': 'community',
        'isBoosted': false,
        'distance': 1000.0,
        'detectedAt': DateTime.now().toIso8601String(),
        'payload': {
          'id': 'community_1',
          'name': 'Tech Enthusiasts',
          'description': 'A community for tech lovers',
          'avatar': '💻',
          'memberCount': 150,
          'tags': ['Technology', 'Innovation'],
          'isJoined': false,
          'isVerified': true,
        },
      };

      final item = FeedItem.fromJson(json);

      expect(item.type, FeedItemType.community);
      expect(item.payload, isA<CommunityCard>());
      
      final community = item.payload as CommunityCard;
      expect(community.name, 'Tech Enthusiasts');
      expect(community.memberCount, 150);
      expect(community.isVerified, true);
    });

    test('FeedItem.formattedDistance returns correct string', () {
      final item = FeedItem(
        id: 'test',
        type: FeedItemType.user,
        isBoosted: false,
        distance: 500.0,
        payload: UserCard(
          id: 'user_1',
          name: 'Test User',
          avatar: '👨',
        ),
        detectedAt: DateTime.now(),
      );

      expect(item.formattedDistance, '500m away');

      final item2 = item.copyWith(distance: 1500.0);
      expect(item2.formattedDistance, '1.5km away');
    });
  });

  group('AllFeedRepository Tests', () {
    late AllFeedRepository repository;

    setUp(() {
      repository = AllFeedRepository();
    });

    test('fetchInitial returns FeedResponse with items', () async {
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      expect(response.items, isNotEmpty);
      expect(response.cursor, isNotNull);
      expect(response.hasMore, true);
    });

    test('fetchInitial with hideBoosted filters boosted items', () async {
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
        hideBoosted: true,
      );

      // All items should not be boosted
      expect(response.items.every((item) => !item.isBoosted), true);
    });

    test('fetchNext returns more items', () async {
      // First fetch
      final initialResponse = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      // Next fetch
      final nextResponse = await repository.fetchNext(
        cursor: initialResponse.cursor!,
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      expect(nextResponse.items, isNotEmpty);
      expect(nextResponse.cursor, isNotNull);
    });

    test('boosted items appear first in feed', () async {
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      // Find first boosted and first non-boosted item indices
      int? firstBoostedIndex;
      int? firstNonBoostedIndex;

      for (int i = 0; i < response.items.length; i++) {
        if (response.items[i].isBoosted && firstBoostedIndex == null) {
          firstBoostedIndex = i;
        }
        if (!response.items[i].isBoosted && firstNonBoostedIndex == null) {
          firstNonBoostedIndex = i;
        }
      }

      // If both exist, boosted should come before non-boosted
      if (firstBoostedIndex != null && firstNonBoostedIndex != null) {
        expect(firstBoostedIndex < firstNonBoostedIndex, true);
      }
    });

    test('reset clears pagination state', () async {
      // Fetch some pages
      await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      // Reset
      repository.reset();

      // Fetch again should start from page 0
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      expect(response.cursor, 'page_1');
    });
  });

  group('UserCard Tests', () {
    test('UserCard.fromJson creates valid object', () {
      final json = {
        'id': 'user_1',
        'name': 'Jane Doe',
        'avatar': '👩',
        'bio': 'Software developer',
        'interests': ['Coding', 'Coffee'],
        'mutualFriendsCount': 3,
        'isOnline': true,
      };

      final user = UserCard.fromJson(json);

      expect(user.id, 'user_1');
      expect(user.name, 'Jane Doe');
      expect(user.bio, 'Software developer');
      expect(user.interests, ['Coding', 'Coffee']);
      expect(user.mutualFriendsCount, 3);
      expect(user.isOnline, true);
    });
  });

  group('CommunityCard Tests', () {
    test('formattedMemberCount formats correctly', () {
      final community = CommunityCard(
        id: 'com_1',
        name: 'Test Community',
        description: 'Test description',
        avatar: '💻',
        memberCount: 500,
      );

      expect(community.formattedMemberCount, '500 members');

      final community2 = CommunityCard(
        id: 'com_2',
        name: 'Test Community 2',
        description: 'Test description',
        avatar: '💻',
        memberCount: 1500,
      );
      expect(community2.formattedMemberCount, '1.5K members');

      final community3 = CommunityCard(
        id: 'com_3',
        name: 'Test Community 3',
        description: 'Test description',
        avatar: '💻',
        memberCount: 1500000,
      );
      expect(community3.formattedMemberCount, '1.5M members');
    });
  });

  group('EventCard Tests', () {
    test('isHappeningSoon returns true for events within 24 hours', () {
      final event = EventCard(
        id: 'event_1',
        title: 'Tech Meetup',
        description: 'Join us for tech talks',
        startTime: DateTime.now().add(const Duration(hours: 12)),
        location: 'Tech Hub',
        attendeeCount: 25,
        organizerId: 'org_1',
        organizerName: 'TechHub',
      );

      expect(event.isHappeningSoon, true);

      final event2 = EventCard(
        id: 'event_2',
        title: 'Future Event',
        description: 'Far away event',
        startTime: DateTime.now().add(const Duration(days: 7)),
        location: 'Venue',
        attendeeCount: 50,
        organizerId: 'org_1',
        organizerName: 'Organizer',
      );

      expect(event2.isHappeningSoon, false);
    });

    test('isFull returns true when event reaches capacity', () {
      final event = EventCard(
        id: 'event_1',
        title: 'Limited Event',
        description: 'Small capacity',
        startTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Small Venue',
        attendeeCount: 50,
        maxAttendees: 50,
        organizerId: 'org_1',
        organizerName: 'Organizer',
      );

      expect(event.isFull, true);

      final event2 = EventCard(
        id: 'event_2',
        title: 'Open Event',
        description: 'Room for more',
        startTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Large Venue',
        attendeeCount: 25,
        maxAttendees: 100,
        organizerId: 'org_1',
        organizerName: 'Organizer',
      );

      expect(event2.isFull, false);
    });

    test('formattedAttendeeCount includes max when set', () {
      final event = EventCard(
        id: 'event_1',
        title: 'Event',
        description: 'Description',
        startTime: DateTime.now(),
        location: 'Venue',
        attendeeCount: 25,
        maxAttendees: 100,
        organizerId: 'org_1',
        organizerName: 'Organizer',
      );

      expect(event.formattedAttendeeCount, '25/100 attending');

      final event2 = EventCard(
        id: 'event_2',
        title: 'Unlimited Event',
        description: 'No capacity',
        startTime: DateTime.now(),
        location: 'Venue',
        attendeeCount: 50,
        maxAttendees: 0,
        organizerId: 'org_1',
        organizerName: 'Organizer',
      );

      expect(event2.formattedAttendeeCount, '50 attending');
    });
  });
}

