// TODO: Voeg visuele animatie toe bij radar-ping (bijv. pulse effect)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user_model.dart';
import '../widgets/enhanced_radar_view.dart';
import '../services/sound_service.dart';
import '../services/app_refresh_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../screens/notifications_screen.dart';
import 'nearby_users_list_screen.dart';
import 'user_search_screen.dart';
import 'chat_detail_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class RadarScreen extends StatefulWidget {
const RadarScreen({Key? key}) : super(key: key);

@override
State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
bool _isLoading = false;
double _maxDistance = 1000.0; // Maximum distance in km
late AnimationController _pulseAnimationController;
late Animation<double> _pulseAnimation;

// Animation variables for improved UX
final _nearbyUserItemAnimationDuration = const Duration(milliseconds: 400);
bool _filterIsActive = false;

// Controller for the search field
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';
List<UserModel> _filteredUsers = [];

// Sound service
final SoundService _soundService = SoundService();

// Flag to track if the radar has been initialized
bool _radarInitialized = false;

@override
bool get wantKeepAlive => true;

@override
void initState() {
super.initState();

// Set up pulse animation for the radar effect
_pulseAnimationController = AnimationController(
vsync: this,
duration: const Duration(seconds: 2),
);

_pulseAnimation = Tween<double>(
begin: 0.95,
end: 1.05,
).animate(CurvedAnimation(
parent: _pulseAnimationController,
curve: Curves.easeInOut,
));

_pulseAnimationController.repeat(reverse: true);

// Wait for the UI to build before refreshing users (looks better with animations)
WidgetsBinding.instance.addPostFrameCallback((_) {
_refreshNearbyUsers();
});
}

@override
void dispose() {
_pulseAnimationController.dispose();
_searchController.dispose();
super.dispose();
}

void _filterUsers(String query) {
setState(() {
_searchQuery = query;
// We'll apply the filter when we rebuild
});
}

Future<void> _refreshNearbyUsers() async {
// Add haptic feedback before loading starts
HapticFeedback.mediumImpact();
setState(() => _isLoading = true);

try {
// Play radar refresh sound sequence
_soundService.playRadarHighPingSound(); // High ping to indicate refresh starting

// Small delay to simulate radar recalibration
await Future.delayed(const Duration(milliseconds: 300));

await Provider.of<UserProvider>(context, listen: false).refreshNearbyUsers();

// Reset search when refreshing
if (_searchQuery.isNotEmpty) {
setState(() {
_searchQuery = '';
_searchController.clear();
});
}

// Set radar as initialized after first load
if (!_radarInitialized) {
setState(() {
_radarInitialized = true;
});
}

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Row(
children: [
Icon(Icons.check_circle_outline, color: Colors.white),
const SizedBox(width: 10),
Text('Radar updated with nearby users'),
],
),
duration: const Duration(seconds: 2),
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
backgroundColor: AppTheme.primaryColor,
)
);

// Play sound based on number of users found
final userProvider = Provider.of<UserProvider>(context, listen: false);
if (userProvider.nearbyUsers.isNotEmpty) {
if (userProvider.nearbyUsers.length > 5) {
_soundService.playMatchFoundSound(); // Many users found - exciting sound
} else {
_soundService.playSuccessSound(); // Some users found - normal success
}

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(1)}k km';
} else if (distance >= 100) {
return '${distance.toStringAsFixed(0)} km';
} else if (distance >= 10) {
return '${distance.toStringAsFixed(1)} km';
} else {
return '${distance.toStringAsFixed(2)} km';
}
}
} else {
_soundService.playRadarLowPingSound(); // No users found - low ping
}

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(1)}k km';
} else if (distance >= 100) {
return '${distance.toStringAsFixed(0)} km';
} else if (distance >= 10) {
return '${distance.toStringAsFixed(1)} km';
} else {
return '${distance.toStringAsFixed(2)} km';
}
}
}
} catch (e) {
if (mounted) {
// Play error sound
_soundService.playErrorSound();

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Row(
children: [
Icon(Icons.error_outline, color: Colors.white),
const SizedBox(width: 10),
Expanded(child: Text('Error refreshing users: $e')),
],
),
backgroundColor: Colors.red,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
)
);
}

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(1)}k km';
} else if (distance >= 100) {
return '${distance.toStringAsFixed(0)} km';
} else if (distance >= 10) {
return '${distance.toStringAsFixed(1)} km';
} else {
return '${distance.toStringAsFixed(2)} km';
}
}
} finally {
if (mounted) {
setState(() => _isLoading = false);
}
}
}

void _showUserDetails(UserModel user) {
// Play tap sound
_soundService.playTapSound();
final userProvider = Provider.of<UserProvider>(context, listen: false);
final currentUser = userProvider.currentUser;

if (currentUser == null) return;

// Calculate distance
final distance = userProvider.getDistanceToUser(user);

// Check friendship status
bool isFriend = currentUser.friendIds.contains(user.userId);
bool isRequestSent = currentUser.sentFriendRequests.contains(user.userId);
bool isRequestReceived = currentUser.receivedFriendRequests.contains(user.userId);

showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (context) => Container(
height: MediaQuery.of(context).size.height * 0.6,
decoration: BoxDecoration(
color: Theme.of(context).scaffoldBackgroundColor,
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(24),
topRight: Radius.circular(24),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 10,
offset: const Offset(0, -2),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Handle
Center(
child: Container(
margin: const EdgeInsets.only(top: 12, bottom: 24),
width: 40,
height: 4,
decoration: BoxDecoration(
color: Colors.grey[400],
borderRadius: BorderRadius.circular(2),
),
),
),

// Profile section
Padding(
padding: const EdgeInsets.symmetric(horizontal: 24),
child: Row(
children: [
// Avatar
Container(
width: 80,
height: 80,
decoration: BoxDecoration(
gradient: AppTheme.accentGradient,
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: AppTheme.accentColor.withOpacity(0.3),
blurRadius: 8,
offset: const Offset(0, 4),
),
],
),
child: Center(
child: Text(
user.userName.substring(0, 1).toUpperCase(),
style: const TextStyle(
color: Colors.white,
fontSize: 32,
fontWeight: FontWeight.bold,
),
),
),
),
const SizedBox(width: 20),

// User info
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
user.userName,
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'@${user.username}',
style: TextStyle(
color: Theme.of(context).textTheme.bodySmall?.color,
),
),
const SizedBox(height: 8),
Row(
children: [
Icon(
Icons.place,
size: 16,
color: AppTheme.primaryColor,
),
const SizedBox(width: 4),
Text(
'${_formatDistance(distance)} away',
style: TextStyle(
color: AppTheme.primaryColor,
fontWeight: FontWeight.w500,
),
),
],
),
],
),
),
],
),
),

const SizedBox(height: 24),

// Interests
Padding(
padding: const EdgeInsets.symmetric(horizontal: 24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Interests',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
user.interests.isEmpty
? Text(
'No interests specified',
style: TextStyle(color: Colors.grey[600]),
)
: Wrap(
spacing: 8,
runSpacing: 8,
children: user.interests.map((interest) => Chip(
label: Text(interest),
backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
labelStyle: TextStyle(color: AppTheme.primaryColor),
)).toList(),
),
],
),
),

const Spacer(),

// Action buttons
Padding(
padding: const EdgeInsets.all(24),
child: Row(
children: [
// Chat button
Expanded(
child: ElevatedButton.icon(
onPressed: isFriend ? () => _startChat(user) : null,
icon: const Icon(Icons.chat_bubble_outline),
label: const Text('Message'),
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primaryColor,
foregroundColor: Colors.white,
elevation: 0,
disabledBackgroundColor: Colors.grey[300],
disabledForegroundColor: Colors.grey[600],
),
),
),
const SizedBox(width: 16),

// Friend request button
Expanded(
child: OutlinedButton.icon(
onPressed: isFriend || isRequestSent ? null : () => _sendFriendRequest(user),
icon: Icon(isFriend ? Icons.check : Icons.person_add_alt),
label: Text(isFriend
? 'Friend'
: (isRequestSent ? 'Requested' : 'Add Friend')),
style: OutlinedButton.styleFrom(
foregroundColor: AppTheme.accentColor,
side: BorderSide(color: AppTheme.accentColor),
disabledForegroundColor: Colors.grey[600],
),
),
),
],
),
),
],
),
),
);
}

Future<void> _sendFriendRequest(UserModel user) async {
// Play friend request sound
_soundService.playFriendRequestSentSound();
try {
final userProvider = Provider.of<UserProvider>(context, listen: false);
await userProvider.sendFriendRequest(user.userId);

if (mounted) {
HapticFeedback.mediumImpact(); // Provide feedback
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Friend request sent to ${user.userName}'))
);
Navigator.pop(context); // Close bottom sheet
}

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(1)}k km';
} else if (distance >= 100) {
return '${distance.toStringAsFixed(0)} km';
} else if (distance >= 10) {
return '${distance.toStringAsFixed(1)} km';
} else {
return '${distance.toStringAsFixed(2)} km';
}
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Error sending friend request: $e'))
);
}

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(1)}k km';
} else if (distance >= 100) {
return '${distance.toStringAsFixed(0)} km';
} else if (distance >= 10) {
return '${distance.toStringAsFixed(1)} km';
} else {
return '${distance.toStringAsFixed(2)} km';
}
}
}
}

Future<void> _startChat(UserModel user) async {
final userProvider = Provider.of<UserProvider>(context, listen: false);
final currentUser = userProvider.currentUser;
if (currentUser == null) return;

try {
// Create a new chat through the ChatProvider
final chatProvider = Provider.of<ChatProvider>(context, listen: false);
final newChat = await chatProvider.createChat([currentUser.userId, user.userId]);

if (!mounted) return;

// Navigate to chat detail
Navigator.pop(context); // Close user details
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => ChatDetailScreen(
chatId: newChat.chatId,
otherUser: user,
),
),
);
} catch (e) {
print('Error starting chat: $e');
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Error starting chat: $e'))
);
}

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(1)}k km';
} else if (distance >= 100) {
return '${distance.toStringAsFixed(0)} km';
} else if (distance >= 10) {
return '${distance.toStringAsFixed(1)} km';
} else {
return '${distance.toStringAsFixed(2)} km';
}
}
}
}

void _viewAllNearbyUsers() {
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const NearbyUsersListScreen()),
);
}

// Show notifications panel
Widget _buildNotificationsPanel(BuildContext context) {
return Container(
height: MediaQuery.of(context).size.height * 0.7,
padding: const EdgeInsets.symmetric(vertical: 20),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(24),
topRight: Radius.circular(24),
),
),
child: Column(
children: [
Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: Colors.grey[400],
borderRadius: BorderRadius.circular(2),
),
),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16.0),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
'Notifications',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
TextButton(
onPressed: () {
// Mark all as read
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('All notifications marked as read')),
);
},
child: const Text('Mark all as read'),
),
],
),
),
const SizedBox(height: 12),
Expanded(
child: ListView(
children: [
// Friend request notification
_buildNotificationItem(
icon: Icons.person_add,
title: 'New Friend Request',
body: 'User_2 sent you a friend request',
time: '2m ago',
color: AppTheme.primaryColor,
onTap: () {
_showNotificationDetail(
context: context,
title: 'Friend Request',
content: _buildFriendRequestDetail(),
);
},
),
// Message notification
_buildNotificationItem(
icon: Icons.chat_bubble_outline,
title: 'New Message',
body: 'User_5: Hey, how are you doing?',
time: '15m ago',
color: Colors.green,
onTap: () {
_showNotificationDetail(
context: context,
title: 'New Message',
content: _buildMessageDetail(),
onNavigate: () {
// Close detail view and notifications panel
Navigator.pop(context); // Close detail view
Navigator.pop(context); // Close notifications panel
// Navigate to chats tab
HomeScreen.navigateToTab(context, 1); // Chat tab index
},
);
},
),
// Nearby user notification
_buildNotificationItem(
icon: Icons.radar_outlined,
title: 'New User Nearby',
body: 'User_8 is now within 1km of your location',
time: '1h ago',
color: AppTheme.accentColor,
onTap: () {
_showNotificationDetail(
context: context,
title: 'Nearby User',
content: _buildNearbyUserDetail(),
);
},
),
// Show all button
Padding(
padding: const EdgeInsets.all(16.0),
child: TextButton(
onPressed: () {
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Full notifications page coming soon')),
);
},
child: const Text('See all notifications'),
),
),
],
),
),
],
),
);
}

// Show notification detail screen with back button
void _showNotificationDetail({
required BuildContext context,
required String title,
required Widget content,
VoidCallback? onNavigate,
}) {
showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
isScrollControlled: true,
builder: (detailContext) => Container(
height: MediaQuery.of(context).size.height * 0.7,
padding: const EdgeInsets.symmetric(vertical: 20),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(24),
topRight: Radius.circular(24),
),
),
child: Column(
children: [
Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: Colors.grey[400],
borderRadius: BorderRadius.circular(2),
),
),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16.0),
child: Row(
children: [
// Back button
IconButton(
icon: const Icon(Icons.arrow_back),
onPressed: () => Navigator.pop(detailContext),
),
const SizedBox(width: 8),
// Title
Text(
title,
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
),
const Divider(),
Expanded(
child: SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: content,
),
),
if (onNavigate != null)
Padding(
padding: const EdgeInsets.all(16.0),
child: SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: onNavigate,
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primaryColor,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 12),
),
child: const Text('Go to Chat'),
),
),
),
],
),
),
);
}

// Build notification item
Widget _buildNotificationItem({
required IconData icon,
required String title,
required String body,
required String time,
required Color color,
required VoidCallback onTap,
}) {
return ListTile(
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: color.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(icon, color: color),
),
title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
subtitle: Text(body, maxLines: 1, overflow: TextOverflow.ellipsis),
trailing: Text(
time,
style: TextStyle(
fontSize: 12,
color: Theme.of(context).textTheme.bodySmall?.color,
),
),
onTap: onTap,
);
}

// Build friend request detail content
Widget _buildFriendRequestDetail() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ListTile(
leading: CircleAvatar(
backgroundColor: AppTheme.accentColor,
child: const Text('U2', style: TextStyle(color: Colors.white)),
),
title: const Text('User_2'),
subtitle: const Text('@user_2'),
),
const SizedBox(height: 16),
const Text('User_2 sent you a friend request'),
const SizedBox(height: 24),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () {
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Friend request declined')),
);
},
style: OutlinedButton.styleFrom(
foregroundColor: Colors.red,
side: const BorderSide(color: Colors.red),
),
child: const Text('Decline'),
),
),
const SizedBox(width: 16),
Expanded(
child: ElevatedButton(
onPressed: () {
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Friend request accepted')),
);
},
style: ElevatedButton.styleFrom(
backgroundColor: Colors.green,
foregroundColor: Colors.white,
),
child: const Text('Accept'),
),
),
],
),
],
);
}

// Build message detail content
Widget _buildMessageDetail() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ListTile(
leading: CircleAvatar(
backgroundColor: Colors.green,
child: const Text('U5', style: TextStyle(color: Colors.white)),
),
title: const Text('User_5'),
subtitle: const Text('15 minutes ago'),
),
const SizedBox(height: 16),
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.green.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: Colors.green.withOpacity(0.3)),
),
child: const Text(
'Hey, how are you doing?',
style: TextStyle(fontSize: 16),
),
),
],
);
}

// Build nearby user detail content
Widget _buildNearbyUserDetail() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ListTile(
leading: CircleAvatar(
backgroundColor: AppTheme.accentColor,
child: const Text('U8', style: TextStyle(color: Colors.white)),
),
title: const Text('User_8'),
subtitle: const Text('1 km away'),
),
const SizedBox(height: 16),
const Text(
'A new user has been detected within 1km of your location. You might have common interests!',
style: TextStyle(fontSize: 16),
),
const SizedBox(height: 16),
const Text('Interests:', style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
Wrap(
spacing: 8,
runSpacing: 8,
children: [
Chip(label: const Text('Music')),
Chip(label: const Text('Technology')),
Chip(label: const Text('Travel')),
],
),
],
);
}

// Build search bottom sheet
Widget _buildSearchSheet(BuildContext context) {
return Container(
padding: EdgeInsets.only(
bottom: MediaQuery.of(context).viewInsets.bottom,
top: 20,
left: 20,
right: 20,
),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(24),
topRight: Radius.circular(24),
),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
// Handle
Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: Colors.grey[400],
borderRadius: BorderRadius.circular(2),
),
),

// Title
Row(
children: [
Icon(Icons.search, color: AppTheme.primaryColor),
const SizedBox(width: 10),
Text(
'Search nearby users',
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
const SizedBox(height: 20),

// Search field
TextField(
controller: _searchController,
decoration: InputDecoration(
hintText: 'Search by name, username or interests...',
prefixIcon: const Icon(Icons.search),
suffixIcon: IconButton(
icon: const Icon(Icons.clear),
onPressed: () {
_searchController.clear();
_filterUsers('');
},
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
contentPadding: const EdgeInsets.symmetric(vertical: 16),
),
onChanged: _filterUsers,
textInputAction: TextInputAction.search,
onSubmitted: (value) {
_filterUsers(value);
Navigator.pop(context);
},
autofocus: true,
),

const SizedBox(height: 16),

// Buttons
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () {
_filterUsers('');
_searchController.clear();
Navigator.pop(context);
},
style: OutlinedButton.styleFrom(
side: BorderSide(color: AppTheme.primaryColor),
padding: const EdgeInsets.symmetric(vertical: 12),
),
child: const Text('Cancel'),
),
),
const SizedBox(width: 16),
Expanded(
child: ElevatedButton(
onPressed: () {
_filterUsers(_searchController.text);
Navigator.pop(context);
},
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primaryColor,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 12),
),
child: const Text('Search'),
),
),
],
),
const SizedBox(height: 20),
],
),
);
}

@override
Widget build(BuildContext context) {
  // TODO: Dynamische radarafstand op basis van premium status
final user = ref.watch(userProvider);
// TIP: Speel geluid bij radar actie
  // SoundService.playRadarPing();
  final int maxDistanceKm = user?.radarRangeKm ?? 5;
// Gebruik maxDistanceKm in filtering/logica voor nabijheid


return Scaffold(
extendBodyBehindAppBar: true,
appBar: AppBar(
title: const Text('Nearby Radar'),
backgroundColor: Colors.transparent,
elevation: 0,
leading: IconButton(
icon: const Icon(Icons.settings),
onPressed: () {
// Navigate to settings screen
Navigator.push(
context,
PageRouteBuilder(
pageBuilder: (context, animation, secondaryAnimation) {
return FadeTransition(
opacity: animation,
child: const SettingsScreen(),
);
},
transitionDuration: const Duration(milliseconds: 300),
),
);
},
),
actions: [
IconButton(
icon: const Icon(Icons.notifications_outlined),
tooltip: 'Notifications',
onPressed: () {
HapticFeedback.selectionClick();
// Navigate to notifications screen
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const NotificationsScreen()),
);
},
),
IconButton(
icon: const Icon(Icons.search),
onPressed: () {
HapticFeedback.selectionClick();
showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (context) => _buildSearchSheet(context),
);
},
),
IconButton(
icon: const Icon(Icons.list),
onPressed: () {
HapticFeedback.selectionClick();
_viewAllNearbyUsers();
},
),
],
),
body: Consumer<UserProvider>(
builder: (context, userProvider, child) {
final currentUser = userProvider.currentUser;
if (currentUser == null) {
return const Center(child: Text('User profile not found'));
}

final nearbyUsers = userProvider.getNearbyUsersWithinDistance(_maxDistance);

// Filter users if search is active
if (_searchQuery.isNotEmpty) {
_filteredUsers = nearbyUsers.where((user) {
return user.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
user.interests.any((interest) =>
interest.toLowerCase().contains(_searchQuery.toLowerCase()));
}).toList();
} else {
_filteredUsers = nearbyUsers;
}

return Stack(
children: [
// Decorative background
Positioned.fill(
child: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
AppTheme.primaryColor.withOpacity(0.05),
Theme.of(context).scaffoldBackgroundColor,
Theme.of(context).scaffoldBackgroundColor,
],
),
),
),
),

// Main content
SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 16.0),
child: Column(
children: [
// Radar visualization with animated container
Expanded(
flex: 3,
child: Hero(
tag: 'radar_view',
child: Container(
margin: const EdgeInsets.only(top: 16),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(24),
boxShadow: [
BoxShadow(
color: AppTheme.primaryColor.withOpacity(0.15),
blurRadius: 20,
spreadRadius: 2,
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(24),
child: AnimatedBuilder(
animation: _pulseAnimation,
builder: (context, child) {
return Transform.scale(
scale: _pulseAnimation.value,
child: EnhancedRadarView(
nearbyUsers: _searchQuery.isEmpty ? nearbyUsers : _filteredUsers,
currentUser: currentUser,
onUserTap: _showUserDetails,
maxDistance: _maxDistance,
playSounds: true,
),
);
},
),
),
),
),
),

const SizedBox(height: 16),

// Distance slider with improved visuals
Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: Column(
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(
children: [
Icon(
Icons.radar,
size: 18,
color: AppTheme.primaryColor,
),
const SizedBox(width: 8),
Text(
'Range: ${_formatDistance(_maxDistance)}',
style: TextStyle(
fontWeight: FontWeight.bold,
color: AppTheme.primaryColor,
),
),
],
),
Container(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Text(
'${_searchQuery.isEmpty ? nearbyUsers.length : _filteredUsers.length} users',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 12,
color: AppTheme.primaryColor,
),
),
),
],
),
SliderTheme(
data: SliderTheme.of(context).copyWith(
trackHeight: 6,
thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
activeTrackColor: AppTheme.primaryColor,
inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
thumbColor: AppTheme.primaryColor,
overlayColor: AppTheme.primaryColor.withOpacity(0.2),
),
child: Slider(
value: _maxDistance,
min: 1.0,
max: 1000.0,
divisions: 100,
label: _formatDistance(_maxDistance),
onChanged: (value) {
HapticFeedback.selectionClick();
setState(() {
_maxDistance = value;
});

// Play distance change sound
if (value == 1.0) {
_soundService.playDistanceMinSound();
} else if (value == 1000.0) {
_soundService.playDistanceMaxSound();
} else {
_soundService.playDistanceChangeSound();
}

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(1)}k km';
} else if (distance >= 100) {
return '${distance.toStringAsFixed(0)} km';
} else if (distance >= 10) {
return '${distance.toStringAsFixed(1)} km';
} else {
return '${distance.toStringAsFixed(2)} km';
}
}
},
),
),
],
),
),

// Nearby users list with improved design
const SizedBox(height: 16),
Expanded(
flex: 2,
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Row(
children: [
Icon(
Icons.people_alt_outlined,
size: 18,
color: AppTheme.primaryColor,
),
const SizedBox(width: 8),
Text(
'Nearby Users',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
TextButton.icon(
onPressed: () {
HapticFeedback.selectionClick();
_viewAllNearbyUsers();
},
icon: const Icon(Icons.arrow_forward, size: 16),
label: const Text('View All'),
style: TextButton.styleFrom(
foregroundColor: AppTheme.primaryColor,
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
minimumSize: Size.zero,
tapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
),
],
),
const SizedBox(height: 8),

Expanded(
child: _filteredUsers.isEmpty
? Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(
Icons.person_off_outlined,
size: 48,
color: AppTheme.primaryColor,
),
),
const SizedBox(height: 16),
Text(
'No users found nearby',
style: Theme.of(context).textTheme.titleMedium,
),
const SizedBox(height: 8),
ElevatedButton.icon(
onPressed: () {
HapticFeedback.mediumImpact();
setState(() {
_maxDistance = 10.0; // Increase range
});
_refreshNearbyUsers();
},
icon: const Icon(Icons.expand_more),
label: const Text('Increase Range'),
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primaryColor,
foregroundColor: Colors.white,
),
),
],
),
)
: ListView.builder(
itemCount: _filteredUsers.length > 5 ? 5 : _filteredUsers.length,
itemBuilder: (context, index) {
final user = _filteredUsers[index];
final distance = userProvider.getDistanceToUser(user);

// Check if users share any interests
final commonInterests = user.interests
.where((interest) => currentUser.interests.contains(interest))
.toList();

return Card(
elevation: 0,
color: Theme.of(context).brightness == Brightness.dark
? AppTheme.primaryColor.withOpacity(0.05)
: Colors.white,
margin: const EdgeInsets.symmetric(vertical: 4),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: InkWell(
borderRadius: BorderRadius.circular(12),
onTap: () {
HapticFeedback.mediumImpact();
_showUserDetails(user);
},
child: Padding(
padding: const EdgeInsets.all(12.0),
child: Row(
children: [
Hero(
tag: 'avatar_${user.userId}',
child: Container(
width: 50,
height: 50,
decoration: BoxDecoration(
gradient: AppTheme.accentGradient,
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: AppTheme.accentColor.withOpacity(0.3),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: Center(
child: Text(
user.userName.substring(0, 1).toUpperCase(),
style: const TextStyle(
color: Colors.white,
fontSize: 20,
fontWeight: FontWeight.bold,
),
),
),
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
user.userName,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
if (commonInterests.isNotEmpty) ...
[
const SizedBox(height: 4),
Row(
children: [
Icon(
Icons.favorite,
size: 12,
color: AppTheme.primaryColor,
),
const SizedBox(width: 4),
Text(
'${commonInterests.length} common interests',
style: TextStyle(
fontSize: 12,
color: AppTheme.primaryColor,
),
),
],
),
],
],
),
),
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
borderRadius: BorderRadius.circular(16),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.place_outlined,
size: 12,
color: AppTheme.primaryColor,
),
const SizedBox(width: 4),
Text(
'${distance.toStringAsFixed(1)} km',
style: TextStyle(
color: AppTheme.primaryColor,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
],
),
),
],
),
),
),
);
},
),
),
],
),
),
),
],
),
),
),

// Loading overlay
if (_isLoading)
Positioned.fill(
child: Container(
color: Colors.black.withOpacity(0.3),
child: Center(
child: Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 10,
spreadRadius: 1,
),
],
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
CircularProgressIndicator(
valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
),
const SizedBox(height: 16),
const Text('Scanning for nearby users...'),
],
),
),
),
),
),
],
);
},
),
floatingActionButton: FloatingActionButton(
onPressed: _isLoading ? null : _refreshNearbyUsers,
backgroundColor: AppTheme.primaryColor,
tooltip: 'Refresh nearby users',
child: _isLoading
? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
: const Icon(Icons.refresh, color: Colors.white),
),
);
}

String _formatDistance(double distance) {
if (distance >= 1000) {
return '${(distance / 1000).toStringAsFixed(1)}k km';
} else if (distance >= 100) {
return '${distance.toStringAsFixed(0)} km';
} else if (distance >= 10) {
return '${distance.toStringAsFixed(1)} km';
} else {
return '${distance.toStringAsFixed(2)} km';
}
}
}