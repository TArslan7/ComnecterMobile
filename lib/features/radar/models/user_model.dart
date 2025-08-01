import 'dart:math';

class NearbyUser {
  final String id;
  final String name;
  final String avatarUrl;
  final double distanceKm;
  final double angleDegrees; // Position angle on radar (0-360)
  final bool isOnline;
  final DateTime lastSeen;

  const NearbyUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.distanceKm,
    required this.angleDegrees,
    required this.isOnline,
    required this.lastSeen,
  });

  // Create mock users for testing
  static List<NearbyUser> generateMockUsers(int count) {
    final random = Random();
    final names = [
      'Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Henry',
      'Ivy', 'Jack', 'Kate', 'Liam', 'Maya', 'Noah', 'Olivia', 'Paul'
    ];
    
    return List.generate(count, (index) {
      final name = names[random.nextInt(names.length)];
      return NearbyUser(
        id: 'user_$index',
        name: name,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$name',
        distanceKm: random.nextDouble() * 5.0, // 0-5 km
        angleDegrees: random.nextDouble() * 360, // 0-360 degrees
        isOnline: random.nextBool(),
        lastSeen: DateTime.now().subtract(
          Duration(minutes: random.nextInt(60)),
        ),
      );
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}