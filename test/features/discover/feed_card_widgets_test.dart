import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comnecter_mobile/features/discover/models/feed_item.dart';
import 'package:comnecter_mobile/features/discover/widgets/feed_card_widgets.dart';

void main() {
  group('UserFeedCard Widget Tests', () {
    testWidgets('displays user information correctly', (WidgetTester tester) async {
      final user = UserCard(
        id: 'user_1',
        name: 'John Doe',
        avatar: '👨',
        bio: 'Software developer',
        interests: ['Music', 'Travel'],
        mutualFriendsCount: 5,
        isOnline: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserFeedCard(
              user: user,
              distance: 500.0,
              isBoosted: false,
            ),
          ),
        ),
      );

      // Check if user name is displayed
      expect(find.text('John Doe'), findsOneWidget);
      
      // Check if bio is displayed
      expect(find.text('Software developer'), findsOneWidget);
      
      // Check if distance is displayed
      expect(find.text('0.5 km away'), findsOneWidget);
      
      // Check if mutual friends is displayed
      expect(find.text('5 mutual friends'), findsOneWidget);
      
      // Check if interests are displayed
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      
      // Check if Connect button exists
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('displays boosted badge when isBoosted is true', (WidgetTester tester) async {
      final user = UserCard(
        id: 'user_1',
        name: 'Jane Doe',
        avatar: '👩',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserFeedCard(
              user: user,
              distance: 1000.0,
              isBoosted: true,
            ),
          ),
        ),
      );

      // Check if BOOSTED badge is displayed
      expect(find.text('BOOSTED'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });

    testWidgets('Connect button triggers callback', (WidgetTester tester) async {
      bool connectCalled = false;
      final user = UserCard(
        id: 'user_1',
        name: 'Test User',
        avatar: '👨',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserFeedCard(
              user: user,
              distance: 500.0,
              onConnect: () {
                connectCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap Connect button
      await tester.tap(find.text('Connect'));
      await tester.pump();

      expect(connectCalled, true);
    });
  });

  group('CommunityFeedCard Widget Tests', () {
    testWidgets('displays community information correctly', (WidgetTester tester) async {
      final community = CommunityCard(
        id: 'comm_1',
        name: 'Tech Enthusiasts',
        description: 'A community for tech lovers',
        avatar: '💻',
        memberCount: 1500,
        tags: ['Technology', 'Innovation'],
        isVerified: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityFeedCard(
              community: community,
              distance: 2000.0,
              isBoosted: false,
            ),
          ),
        ),
      );

      // Check if community name is displayed
      expect(find.text('Tech Enthusiasts'), findsOneWidget);
      
      // Check if description is displayed
      expect(find.text('A community for tech lovers'), findsOneWidget);
      
      // Check if member count is formatted correctly
      expect(find.text('1.5K members'), findsOneWidget);
      
      // Check if tags are displayed
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Innovation'), findsOneWidget);
      
      // Check if verified badge is shown
      expect(find.byIcon(Icons.verified), findsOneWidget);
      
      // Check if Join button exists
      expect(find.text('Join Community'), findsOneWidget);
    });

    testWidgets('shows "Joined" when community is already joined', (WidgetTester tester) async {
      final community = CommunityCard(
        id: 'comm_1',
        name: 'My Community',
        description: 'Already joined',
        avatar: '💻',
        memberCount: 100,
        isJoined: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityFeedCard(
              community: community,
              distance: 1000.0,
            ),
          ),
        ),
      );

      expect(find.text('Joined'), findsOneWidget);
      expect(find.text('Join Community'), findsNothing);
    });
  });

  group('EventFeedCard Widget Tests', () {
    testWidgets('displays event information correctly', (WidgetTester tester) async {
      final startTime = DateTime(2025, 12, 25, 18, 0);
      final event = EventCard(
        id: 'event_1',
        title: 'Tech Meetup',
        description: 'Join us for tech talks',
        startTime: startTime,
        location: 'Tech Hub',
        attendeeCount: 25,
        maxAttendees: 100,
        tags: ['Technology', 'Networking'],
        organizerId: 'org_1',
        organizerName: 'TechHub',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventFeedCard(
              event: event,
              distance: 1500.0,
              isBoosted: false,
            ),
          ),
        ),
      );

      // Check if event title is displayed
      expect(find.text('Tech Meetup'), findsOneWidget);
      
      // Check if description is displayed
      expect(find.text('Join us for tech talks'), findsOneWidget);
      
      // Check if location is displayed
      expect(find.text('Tech Hub'), findsOneWidget);
      
      // Check if attendee count is displayed
      expect(find.text('25/100 attending'), findsOneWidget);
      
      // Check if organizer is displayed
      expect(find.text('by TechHub'), findsOneWidget);
      
      // Check if tags are displayed
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('Networking'), findsOneWidget);
      
      // Check if RSVP button exists
      expect(find.text('RSVP'), findsOneWidget);
    });

    testWidgets('shows "Event Full" when event is at capacity', (WidgetTester tester) async {
      final event = EventCard(
        id: 'event_1',
        title: 'Full Event',
        description: 'No more space',
        startTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Venue',
        attendeeCount: 50,
        maxAttendees: 50,
        organizerId: 'org_1',
        organizerName: 'Organizer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventFeedCard(
              event: event,
              distance: 1000.0,
            ),
          ),
        ),
      );

      expect(find.text('Event Full'), findsOneWidget);
      
      // Button should be disabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Event Full'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows "Attending" when user is already attending', (WidgetTester tester) async {
      final event = EventCard(
        id: 'event_1',
        title: 'My Event',
        description: 'I am attending',
        startTime: DateTime.now().add(const Duration(days: 1)),
        location: 'Venue',
        attendeeCount: 25,
        isAttending: true,
        organizerId: 'org_1',
        organizerName: 'Organizer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventFeedCard(
              event: event,
              distance: 1000.0,
            ),
          ),
        ),
      );

      expect(find.text('Attending'), findsOneWidget);
      expect(find.text('RSVP'), findsNothing);
    });
  });
}

