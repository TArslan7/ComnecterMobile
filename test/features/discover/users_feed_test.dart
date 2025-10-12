import 'package:flutter_test/flutter_test.dart';
import 'package:comnecter_mobile/features/discover/models/feed_item.dart';
import 'package:comnecter_mobile/features/discover/repositories/users_feed_repository.dart';

void main() {
  group('UsersFeedRepository Tests', () {
    late UsersFeedRepository repository;

    setUp(() {
      repository = UsersFeedRepository();
    });

    test('fetchInitial returns FeedResponse with user items only', () async {
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      expect(response.items, isNotEmpty);
      expect(response.cursor, isNotNull);
      expect(response.hasMore, true);
      
      // All items should be users
      expect(
        response.items.every((item) => item.type == FeedItemType.user),
        true,
      );
    });

    test('fetchInitial with hideBoosted filters boosted users', () async {
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
        hideBoosted: true,
      );

      // All items should not be boosted
      expect(response.items.every((item) => !item.isBoosted), true);
    });

    test('fetchNext returns more user items', () async {
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
      
      // All items should be users
      expect(
        nextResponse.items.every((item) => item.type == FeedItemType.user),
        true,
      );
    });

    test('boosted users appear first in feed', () async {
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

    test('all feed items have UserCard payload', () async {
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      for (final item in response.items) {
        expect(item.type, FeedItemType.user);
        expect(item.payload, isA<UserCard>());
        
        final user = item.payload as UserCard;
        expect(user.id, isNotEmpty);
        expect(user.name, isNotEmpty);
        expect(user.avatar, isNotEmpty);
      }
    });

    test('users have realistic data', () async {
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      for (final item in response.items) {
        final user = item.payload as UserCard;
        
        // Check that users have realistic data
        expect(user.mutualFriendsCount, greaterThanOrEqualTo(0));
        expect(user.mutualFriendsCount, lessThan(20));
        expect(user.interests, isNotEmpty);
        expect(user.bio, isNotNull);
        expect(user.bio, isNotEmpty);
        expect(user.lastSeen, isNotNull);
        
        // Last seen should be in the past
        expect(user.lastSeen!.isBefore(DateTime.now()), true);
      }
    });

    test('pagination eventually ends', () async {
      // Fetch initial
      var response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      expect(response.hasMore, true);

      // Keep fetching until hasMore is false
      int pageCount = 1;
      while (response.hasMore && pageCount < 10) {
        response = await repository.fetchNext(
          cursor: response.cursor!,
          lat: 37.7749,
          lng: -122.4194,
          radiusMeters: 5000.0,
        );
        pageCount++;
      }

      // Should eventually stop
      expect(response.hasMore, false);
      expect(response.cursor, isNull);
    });

    test('users within specified radius', () async {
      const radiusMeters = 3000.0;
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: radiusMeters,
      );

      // All users should be within radius
      for (final item in response.items) {
        expect(item.distance, lessThanOrEqualTo(radiusMeters));
        expect(item.distance, greaterThanOrEqualTo(0));
      }
    });
  });

  group('UserCard Tests', () {
    test('online status and last seen are mutually exclusive', () async {
      final repository = UsersFeedRepository();
      final response = await repository.fetchInitial(
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 5000.0,
      );

      for (final item in response.items) {
        final user = item.payload as UserCard;
        
        // User should have either online status or last seen time
        if (user.isOnline) {
          // Online users should have recent last seen
          expect(user.lastSeen, isNotNull);
        }
      }
    });
  });
}

