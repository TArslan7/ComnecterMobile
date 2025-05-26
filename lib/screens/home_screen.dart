import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/sound_service.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/community_provider.dart';
import '../services/notification_service.dart';
import '../services/app_refresh_service.dart';
import '../screens/radar_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/communities_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/events_screen.dart';
import '../screens/user_search_screen.dart';
import '../screens/create_community_screen.dart';
import '../screens/notifications_screen.dart';
import '../services/sample_data_service.dart';
import '../theme.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class HomeScreen extends StatefulWidget {
const HomeScreen({Key? key}) : super(key: key);

// Static method to navigate to a specific tab
static void navigateToTab(BuildContext context, int tabIndex) {
final _HomeScreenState? state = context.findAncestorStateOfType<_HomeScreenState>();
state?._pageController.jumpToPage(tabIndex);
}

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
// Refresh controller
bool _isRefreshing = false;

// Perform app-wide refresh
Future<void> _refreshApp() async {
if (_isRefreshing) return;

setState(() {
_isRefreshing = true;
});

try {
// Play refresh sound
_soundService.playTapSound();

// Add haptic feedback
HapticFeedback.mediumImpact();

// Perform the refresh
final success = await AppRefreshService.refreshAll(context);

if (mounted) {
if (success) {
// Play success sound
_soundService.playSuccessSound();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('App refreshed successfully'),
duration: Duration(seconds: 1),
behavior: SnackBarBehavior.floating,
)
);
} else {
// Play error sound
_soundService.playErrorSound();

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Some updates couldn\'t be refreshed'),
duration: Duration(seconds: 2),
behavior: SnackBarBehavior.floating,
)
);
}
}
} catch (e) {
// Play error sound
_soundService.playErrorSound();

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Error refreshing: $e'),
behavior: SnackBarBehavior.floating,
)
);
}
} finally {
if (mounted) {
setState(() {
_isRefreshing = false;
});
}
}
}

// Build the refreshable body
Widget _buildRefreshableBody() {
// Add pull-to-refresh functionality
return RefreshIndicator(
onRefresh: _refreshApp,
color: AppTheme.primaryColor,
backgroundColor: Theme.of(context).brightness == Brightness.dark
? Colors.grey[800]
: Colors.white,
strokeWidth: 3.0,
displacement: 40.0,
child: PageView(
controller: _pageController,
onPageChanged: _onPageChanged,
physics: const BouncingScrollPhysics(),
children: const [
RadarScreen(),
ChatListScreen(),
CommunitiesScreen(),
ProfileScreen(),
EventsScreen(),
],
),
);
}
// Sound service
final SoundService _soundService = SoundService();
int _currentIndex = 0;
late PageController _pageController;
bool _isLoading = true;
late AnimationController _fabAnimationController;
late Animation<double> _fabScaleAnimation;
late Animation<double> _fabRotationAnimation;
late AnimationController _loadingAnimationController;

// Animation for icon bouncing effect
late List<AnimationController> _iconAnimationControllers;
late List<Animation<double>> _iconScaleAnimations;

@override
void initState() {
super.initState();
_pageController = PageController(initialPage: _currentIndex);

// Setup FAB animations
_fabAnimationController = AnimationController(
duration: const Duration(milliseconds: 300),
vsync: this,
);

_fabScaleAnimation = Tween<double>(
begin: 0.0,
end: 1.0,
).animate(CurvedAnimation(
parent: _fabAnimationController,
curve: Curves.easeInOut,
));

_fabRotationAnimation = Tween<double>(
begin: 0.0,
end: 1.0,
).animate(CurvedAnimation(
parent: _fabAnimationController,
curve: Curves.easeInOut,
));

// Setup loading animation
_loadingAnimationController = AnimationController(
duration: const Duration(seconds: 2),
vsync: this,
)..repeat(reverse: true);

// Setup bottom navigation icon animations
_setupIconAnimations();

_loadInitialData();
}

void _setupIconAnimations() {
_iconAnimationControllers = List.generate(
5,
(index) => AnimationController(
duration: const Duration(milliseconds: 300),
vsync: this,
),
);

_iconScaleAnimations = _iconAnimationControllers.map((controller) {
return Tween<double>(begin: 1.0, end: 1.3).animate(
CurvedAnimation(parent: controller, curve: Curves.easeInOut),
);
}).toList();

// Start the animation for the initial tab
_iconAnimationControllers[_currentIndex].forward();
}

Future<void> _loadInitialData() async {
setState(() => _isLoading = true);
try {
final userProvider = Provider.of<UserProvider>(context, listen: false);
await Future.delayed(const Duration(milliseconds: 1500)); // Simulate loading

// Wait for user to be loaded
if (userProvider.currentUser != null) {
final userId = userProvider.currentUser!.userId;

// Load sample data if this is the first launch
final sampleDataService = SampleDataService();
await sampleDataService.loadAllSampleData(userProvider.currentUser!, context: context);

// Load chats and communities in parallel
await Future.wait([
Provider.of<ChatProvider>(context, listen: false).loadChats(userId),
Provider.of<CommunityProvider>(context, listen: false).loadAllCommunities(),
Provider.of<CommunityProvider>(context, listen: false).loadUserCommunities(userId),
]);
}
} catch (e) {
print('Error loading initial data: $e');
} finally {
if (mounted) {
setState(() => _isLoading = false);

// Play success sound when loading completes
_soundService.playSuccessSound();

// Animate FAB after loading
_fabAnimationController.forward();
}
}
}

@override
void dispose() {
_pageController.dispose();
_fabAnimationController.dispose();
_loadingAnimationController.dispose();
for (final controller in _iconAnimationControllers) {
controller.dispose();
}
super.dispose();
}

void _onPageChanged(int index) {
// Reset all animations first
for (final controller in _iconAnimationControllers) {
controller.reverse();
}

setState(() {
_currentIndex = index;
});

// Animate the new selected tab
_iconAnimationControllers[index].forward();
}

void _onItemTapped(int index) {
if (index == _currentIndex) return;

// Add haptic feedback
HapticFeedback.lightImpact();

// Play tap sound
_soundService.playTapSound();

// Animate to the new page
_pageController.animateToPage(
index,
duration: const Duration(milliseconds: 400),
curve: Curves.easeInOut,
);
}

// Get FAB icon based on current tab
IconData _getFabIcon() {
switch (_currentIndex) {
case 0: return Icons.refresh;
case 1: return Icons.chat;
case 2: return Icons.group_add;
case 3: return Icons.add_photo_alternate; // Changed from edit to add photo for profile
case 4: return Icons.add_circle_outline; // Events tab - create event
default: return Icons.add;
}
}

// FAB action based on current tab
void _onFabPressed() {
// Add haptic feedback
HapticFeedback.mediumImpact();

switch (_currentIndex) {
case 0: // Radar screen - refresh
// Play specific radar sound for refresh
_soundService.playRadarHighPingSound();

// Refresh the radar
final radarScreen = _pageController.page == 0 ?
Provider.of<UserProvider>(context, listen: false).refreshNearbyUsers() : null;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Refreshing nearby users...'),
duration: Duration(seconds: 1),
)
);
break;
case 1: // Chat screen - new chat
// Show new chat dialog
_showNewChatDialog();
break;
case 2: // Communities screen - create community
// Show create community dialog
_showCreateCommunityDialog();
break;
case 3: // Profile screen - add content to profile
// Show dialog to add content to profile
_showAddProfileContentDialog();
break;
case 4: // Events screen - create event
// This action will be handled directly in the EventsScreen
break;
}
}

void _showNewChatDialog() {
showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
builder: (context) => Container(
padding: const EdgeInsets.symmetric(vertical: 20),
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
Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: Colors.grey[400],
borderRadius: BorderRadius.circular(2),
),
),
ListTile(
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(Icons.person_search, color: AppTheme.primaryColor),
),
title: const Text('Find Users'),
subtitle: const Text('Search for people to chat with'),
onTap: () {
Navigator.pop(context);
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const UserSearchScreen()),
);
},
),
ListTile(
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(Icons.radar, color: AppTheme.primaryColor),
),
title: const Text('Browse Nearby'),
subtitle: const Text('Find users near your location'),
onTap: () {
Navigator.pop(context);
// Switch to radar tab
_pageController.animateToPage(
0,
duration: const Duration(milliseconds: 300),
curve: Curves.easeInOut,
);
},
),
],
),
),
);
}

void _showAddProfileContentDialog() {
showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
isScrollControlled: true,
builder: (context) => Container(
padding: const EdgeInsets.all(20),
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
Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: Colors.grey[400],
borderRadius: BorderRadius.circular(2),
),
),
ListTile(
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(Icons.photo, color: AppTheme.primaryColor),
),
title: const Text('Add Photo'),
subtitle: const Text('Share a photo on your profile'),
onTap: () {
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Photo upload coming soon'))
);
},
),
ListTile(
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(Icons.text_fields, color: AppTheme.primaryColor),
),
title: const Text('Add Text Post'),
subtitle: const Text('Share your thoughts'),
onTap: () {
Navigator.pop(context);
_showAddTextPostDialog();
},
),
],
),
),
);
}

void _showAddTextPostDialog() {
final textController = TextEditingController();
showDialog(
context: context,
builder: (context) => AlertDialog(
title: const Text('New Post'),
content: TextField(
controller: textController,
decoration: const InputDecoration(
hintText: 'What\'s on your mind?',
border: OutlineInputBorder(),
),
maxLines: 5,
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('Cancel'),
),
ElevatedButton(
onPressed: () {
Navigator.pop(context);
if (textController.text.trim().isNotEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Post added to your profile'))
);
}
},
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primaryColor,
),
child: const Text('Post'),
),
],
),
);
}

void _showCreateCommunityDialog() {
showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
builder: (context) => Container(
padding: const EdgeInsets.symmetric(vertical: 20),
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
Container(
width: 40,
height: 4,
margin: const EdgeInsets.only(bottom: 20),
decoration: BoxDecoration(
color: Colors.grey[400],
borderRadius: BorderRadius.circular(2),
),
),
ListTile(
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(Icons.add, color: AppTheme.primaryColor),
),
title: const Text('Create Community'),
subtitle: const Text('Start a new community'),
onTap: () {
Navigator.pop(context);
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const CreateCommunityScreen()),
);
},
),
ListTile(
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: AppTheme.primaryColor.withOpacity(0.1),
shape: BoxShape.circle,
),
child: Icon(Icons.search, color: AppTheme.primaryColor),
),
title: const Text('Browse Communities'),
subtitle: const Text('Discover communities to join'),
onTap: () {
Navigator.pop(context);
// Navigate to communities tab
_pageController.animateToPage(
2,
duration: const Duration(milliseconds: 300),
curve: Curves.easeInOut,
);
},
),
],
),
),
);
}

@override
Widget build(BuildContext context) {
if (_isLoading) {
return _buildLoadingScreen();
}

return Scaffold(
appBar: _currentIndex != 0 ? AppBar(
title: _getAppBarTitle(),
leading: Row(
mainAxisSize: MainAxisSize.min,
children: [
IconButton(
icon: const Icon(Icons.settings),
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const SettingsScreen()),
);
},
),
],
),
leadingWidth: 40, // Fixed width
actions: [
Consumer<NotificationService>(
builder: (context, notificationService, child) {
final unreadCount = notificationService.unreadCount;

return Stack(
children: [
IconButton(
icon: const Icon(Icons.notifications_outlined),
tooltip: 'Notifications',
onPressed: () {
HapticFeedback.lightImpact();

// Navigate to notifications screen
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const NotificationsScreen()),
);
},
),
if (unreadCount > 0)
Positioned(
right: 8,
top: 8,
child: Container(
padding: const EdgeInsets.all(4),
decoration: BoxDecoration(
color: Colors.red,
shape: BoxShape.circle,
),
constraints: const BoxConstraints(
minWidth: 16,
minHeight: 16,
),
child: Text(
unreadCount > 9 ? '9+' : '$unreadCount',
style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
textAlign: TextAlign.center,
),
),
),
],
);
},
),
..._getAppBarActions() ?? [],
],
elevation: 0,
) : null,
body: _buildRefreshableBody(),
bottomNavigationBar: AnimatedContainer(
duration: const Duration(milliseconds: 300),
decoration: BoxDecoration(
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 10,
offset: const Offset(0, -1),
),
],
),
child: ClipRRect(
borderRadius: const BorderRadius.only(
topLeft: Radius.circular(20),
topRight: Radius.circular(20),
),
child: BottomNavigationBar(
currentIndex: _currentIndex,
onTap: _onItemTapped,
elevation: 0,
type: BottomNavigationBarType.fixed,
showSelectedLabels: true,
showUnselectedLabels: true,
selectedItemColor: AppTheme.primaryColor,
unselectedItemColor: Theme.of(context).brightness == Brightness.dark
? Colors.grey[600]
: Colors.grey[400],
selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
unselectedLabelStyle: const TextStyle(fontSize: 12),
items: [
_buildNavItem(0, 'Explore', Icons.explore_outlined, Icons.explore),
_buildNavItem(1, 'Chats', Icons.chat_bubble_outline, Icons.chat_bubble),
_buildNavItem(2, 'Communities', Icons.people_outline, Icons.people),
_buildNavItem(3, 'Profile', Icons.person_outline, Icons.person),
_buildNavItem(4, 'Events', Icons.event_outlined, Icons.event),
],
),
),
),

// Add sliding animation for the FAB
floatingActionButton: _currentIndex == 0
? null // Don't show FAB on radar screen (it has its own)
: AnimatedBuilder(
animation: _fabAnimationController,
builder: (context, child) {
return Transform.scale(
scale: _fabScaleAnimation.value,
child: Transform.rotate(
angle: _fabRotationAnimation.value * 0.5 * math.pi,
child: child,
),
);
},
child: FloatingActionButton(
onPressed: _onFabPressed,
backgroundColor: AppTheme.accentColor,
elevation: 8, // Increased elevation for better visibility
materialTapTargetSize: MaterialTapTargetSize.padded,
child: Icon(_getFabIcon(), color: Colors.white),
),
)
);
}

// Get app bar title based on current tab
Widget _getAppBarTitle() {
switch (_currentIndex) {
case 1:
return const Text('My Chats');
case 2:
return const Text('Communities');
case 3:
return const Text('My Profile');
case 4:
return const Text('Events');
default:
return const Text('Comnecter');
}
}

// Show notifications panel
void _showNotificationsPanel() {
showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
isScrollControlled: true,
builder: (context) => _buildNotificationsPanel(context),
);
}

// Build notifications panel content
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
_pageController.animateToPage(
1, // Chat tab
duration: const Duration(milliseconds: 300),
curve: Curves.easeInOut,
);
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
onNavigate: () {
// Close detail view and notifications panel
Navigator.pop(context); // Close detail view
Navigator.pop(context); // Close notifications panel
// Navigate to radar tab
_pageController.animateToPage(
0, // Radar tab
duration: const Duration(milliseconds: 300),
curve: Curves.easeInOut,
);
},
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

// Get app bar actions based on current tab
List<Widget>? _getAppBarActions() {
switch (_currentIndex) {
case 1: // Chats tab
return [
IconButton(
icon: const Icon(Icons.search),
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(builder: (context) => const UserSearchScreen()),
);
},
),
];
case 3: // Profile tab
return null;
case 4: // Events tab
return [
IconButton(
icon: const Icon(Icons.tune),
onPressed: () {
// Show filter options
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Filtering options coming soon')),
);
},
),
];
default:
return null;
}
}

BottomNavigationBarItem _buildNavItem(int index, String label, IconData unselectedIcon, IconData selectedIcon) {
return BottomNavigationBarItem(
icon: AnimatedBuilder(
animation: _iconScaleAnimations[index],
builder: (context, child) {
return Stack(
alignment: Alignment.center,
children: [
// Background glow effect (only for selected item)
if (_currentIndex == index)
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: AppTheme.primaryColor.withOpacity(0.1),
),
)
.animate(onPlay: (controller) => controller.repeat(reverse: true))
.scale(begin: const Offset(0.9, 0.9), end: const Offset(1.2, 1.2), duration: 1.5.seconds, curve: Curves.easeInOut),

// Icon with scale animation
Transform.scale(
scale: _iconScaleAnimations[index].value,
child: Padding(
padding: const EdgeInsets.only(bottom: 4.0),
child: Icon(
_currentIndex == index ? selectedIcon : unselectedIcon,
color: _currentIndex == index ? AppTheme.primaryColor : null,
),
),
),
],
);
},
),
label: label,
);
}

Widget _buildLoadingScreen() {
return Scaffold(
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Stack(
alignment: Alignment.center,
children: [
// Pulsating effect
AnimatedBuilder(
animation: _loadingAnimationController,
builder: (context, child) {
return Container(
width: 120 + (_loadingAnimationController.value * 30),
height: 120 + (_loadingAnimationController.value * 30),
decoration: BoxDecoration(
gradient: AppTheme.primaryGradient,
borderRadius: BorderRadius.circular(30),
boxShadow: [
BoxShadow(
color: AppTheme.primaryColor.withOpacity(0.3 + _loadingAnimationController.value * 0.2),
blurRadius: 20 + (_loadingAnimationController.value * 15),
spreadRadius: 5 + (_loadingAnimationController.value * 5),
offset: const Offset(0, 8),
),
],
),
);
},
),

// App logo/icon
Container(
width: 120,
height: 120,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
gradient: AppTheme.primaryGradient,
borderRadius: BorderRadius.circular(30),
),
child: const Icon(
Icons.radar,
size: 60,
color: Colors.white,
),
),
],
),
const SizedBox(height: 32),
AnimatedTextKit(
animatedTexts: [
FadeAnimatedText(
'Comnecter',
textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
fontWeight: FontWeight.bold,
color: AppTheme.primaryColor,
),
duration: const Duration(milliseconds: 1500),
),
],
totalRepeatCount: 1,
),
const SizedBox(height: 16),
Text(
'Connecting nearby communities',
style: Theme.of(context).textTheme.bodyMedium,
),
const SizedBox(height: 40),
SizedBox(
width: 40,
height: 40,
child: CircularProgressIndicator(
valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
strokeWidth: 3,
),
),
],
),
),
);
}
}