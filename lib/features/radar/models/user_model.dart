import 'dart:math';

class NearbyUser {
  final String id;
  final String name;
  final String avatar;
  final double distanceKm;
  final String status;
  final List<String> interests;

  NearbyUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.distanceKm,
    required this.status,
    required this.interests,
  });

  static List<NearbyUser> generateMockUsers(int count) {
    final random = Random();
    final names = [
      'Alex',
      'Sarah',
      'Mike',
      'Emma',
      'David',
      'Lisa',
      'Tom',
      'Anna',
      'John',
      'Maria',
      'Chris',
      'Sophie',
      'Mark',
      'Julia',
      'Paul',
      'Nina',
    ];

    final statuses = [
      'Online',
      'Away',
      'Busy',
      'Available',
    ];

    final interests = [
      'Music',
      'Sports',
      'Travel',
      'Cooking',
      'Gaming',
      'Reading',
      'Photography',
      'Art',
      'Technology',
      'Fitness',
      'Movies',
      'Dancing',
    ];

    final avatars = [
      '👤',
      '👨',
      '👩',
      '🧑',
      '👨‍💼',
      '👩‍💼',
      '👨‍🎨',
      '👩‍🎨',
      '👨‍⚕️',
      '👩‍⚕️',
      '👨‍🏫',
      '👩‍🏫',
    ];

    return List.generate(count, (index) {
      final name = names[random.nextInt(names.length)];
      final status = statuses[random.nextInt(statuses.length)];
      final avatar = avatars[random.nextInt(avatars.length)];
      final distance = 0.1 + random.nextDouble() * 4.9; // 0.1 to 5.0 km
      
      // Generate 2-4 random interests
      final userInterests = <String>[];
      final interestCount = 2 + random.nextInt(3);
      final shuffledInterests = List<String>.from(interests)..shuffle(random);
      for (int i = 0; i < interestCount && i < shuffledInterests.length; i++) {
        userInterests.add(shuffledInterests[i]);
      }

      return NearbyUser(
        id: 'user_${index + 1}',
        name: name,
        avatar: avatar,
        distanceKm: distance,
        status: status,
        interests: userInterests,
      );
    });
  }
} 