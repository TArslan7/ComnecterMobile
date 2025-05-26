import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user_model.dart';
import '../theme.dart';
import '../services/sound_service.dart';
import 'chat_detail_screen.dart';

class NearbyUsersListScreen extends StatefulWidget {
  const NearbyUsersListScreen({Key? key}) : super(key: key);

  @override
  State<NearbyUsersListScreen> createState() => _NearbyUsersListScreenState();
}

class _NearbyUsersListScreenState extends State<NearbyUsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SoundService _soundService = SoundService(); // Sound service for auditory feedback
  String _searchQuery = '';
  bool _isSearching = false;
  
  // Sort options
  String _sortOption = 'distance';
  bool _sortAscending = true;
  
  // Distance filter
  double _maxDistance = 10.0; // km
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _refreshNearbyUsers() async {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    setState(() => _isSearching = true);
    
    try {
      await Provider.of<UserProvider>(context, listen: false).refreshNearbyUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nearby users updated'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating nearby users: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _showUserProfileDialog(UserModel user, double distance) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) return;
    
    // Check friendship status
    bool isFriend = currentUser.friendIds.contains(user.userId);
    bool isRequestSent = currentUser.sentFriendRequests.contains(user.userId);
    bool isBlocked = currentUser.blockedUserIds.contains(user.userId);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // User info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name and friend status
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.userName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isFriend)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Friend',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Username
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      
                      // Distance
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km away',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Primary action button based on relationship
                  isFriend
                    ? ElevatedButton.icon(
                        onPressed: isBlocked ? null : () => _startChat(user),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 0),
                          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.4),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: isRequestSent || isBlocked ? null : () => _sendFriendRequest(user),
                        icon: Icon(isRequestSent ? Icons.hourglass_top : Icons.person_add_outlined),
                        label: Text(isRequestSent ? 'Request Sent' : 'Add Friend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 0),
                          disabledBackgroundColor: AppTheme.accentColor.withOpacity(0.4),
                        ),
                      ),
                  
                  const SizedBox(height: 8),
                  
                  // No secondary action button - users must be friends to message each other
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest(UserModel user) async {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.sendFriendRequest(user.userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${user.userName}'),
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context); // Close the bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending friend request: $e'))
        );
      }
    }
  }

  Future<void> _startChat(UserModel user) async {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;
    
    // Check if they are friends
    bool isFriend = currentUser.friendIds.contains(user.userId);
    bool isBlocked = currentUser.blockedUserIds.contains(user.userId);
    
    // Cannot message blocked users
    if (isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message a blocked user'))
      );
      return;
    }
    
    // Cannot message users who haven't accepted your friend request
    if (!isFriend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message a user directly if they have not accepted your friend request'))
      );
      return;
    }
    
    try {
      // Create a new chat
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final newChat = await chatProvider.createChat([currentUser.userId, user.userId]);
      
      if (!mounted) return;
      
      // Close bottom sheet
      Navigator.pop(context);
      
      // Navigate to chat detail
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: ChatDetailScreen(
              chatId: newChat.chatId,
              otherUser: user,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      print('Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e'))
        );
      }
    }
  }
  
  void _showFilterDialog() {
    // Play filter sound
    _soundService.playFilterChangeSound();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Wrap(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Row(
                children: [
                  Icon(Icons.filter_alt, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Filter & Sort',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Distance filter
              Text(
                'Maximum Distance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _maxDistance,
                      min: 1.0,
                      max: 20.0,
                      divisions: 19,
                      label: '${_maxDistance.toStringAsFixed(1)} km',
                      activeColor: AppTheme.primaryColor,
                      onChanged: (value) {
                        setState(() => _maxDistance = value);
                        
                        // Play distance change sound
                        if (value == 1.0) {
                          _soundService.playDistanceMinSound();
                        } else if (value == 20.0) {
                          _soundService.playDistanceMaxSound();
                        } else {
                          _soundService.playDistanceChangeSound();
                        }
                      },
                    ),
                  ),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${_maxDistance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Sort options
              Text(
                'Sort By',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Sort radio buttons
              RadioListTile<String>(
                title: const Text('Distance'),
                value: 'distance',
                groupValue: _sortOption,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                },
              ),
              
              RadioListTile<String>(
                title: const Text('Name'),
                value: 'name',
                groupValue: _sortOption,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                },
              ),
              
              RadioListTile<String>(
                title: const Text('Common Interests'),
                value: 'interests',
                groupValue: _sortOption,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                },
              ),
              
              // Sort direction
              SwitchListTile(
                title: Row(
                  children: [
                    Icon(
                      _sortAscending 
                          ? Icons.arrow_upward 
                          : Icons.arrow_downward,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(_sortAscending ? 'Ascending' : 'Descending'),
                  ],
                ),
                value: _sortAscending,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() => _sortAscending = value);
                },
              ),
              
              const SizedBox(height: 16),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply the filter and sort options
                        Navigator.pop(context);
                        this.setState(() {
                          // The filter and sort variables are already updated
                          // in the StatefulBuilder, they will be applied in the
                          // build method automatically
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or interests...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
            ),
          ),
          
          // User list
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (userProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final currentUser = userProvider.currentUser;
                if (currentUser == null) {
                  return const Center(child: Text('User not found'));
                }
                
                // Get nearby users and filter by distance
                var nearbyUsers = userProvider.nearbyUsers.where((user) {
                  final distance = userProvider.getDistanceToUser(user);
                  return distance <= _maxDistance;
                }).toList();
                
                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  nearbyUsers = nearbyUsers.where((user) {
                    return user.userName.toLowerCase().contains(query) ||
                           user.username.toLowerCase().contains(query) ||
                           user.interests.any((interest) => interest.toLowerCase().contains(query));
                  }).toList();
                }
                
                // Sort based on selected option
                nearbyUsers.sort((a, b) {
                  if (_sortOption == 'distance') {
                    final distanceA = userProvider.getDistanceToUser(a);
                    final distanceB = userProvider.getDistanceToUser(b);
                    return _sortAscending 
                        ? distanceA.compareTo(distanceB)
                        : distanceB.compareTo(distanceA);
                  } else if (_sortOption == 'name') {
                    return _sortAscending
                        ? a.userName.compareTo(b.userName)
                        : b.userName.compareTo(a.userName);
                  } else if (_sortOption == 'interests') {
                    // Sort by number of common interests
                    final commonInterestsA = a.interests
                        .where((interest) => currentUser.interests.contains(interest))
                        .length;
                    final commonInterestsB = b.interests
                        .where((interest) => currentUser.interests.contains(interest))
                        .length;
                    return _sortAscending
                        ? commonInterestsA.compareTo(commonInterestsB)
                        : commonInterestsB.compareTo(commonInterestsA);
                  }
                  return 0;
                });
                
                if (nearbyUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No nearby users found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term or filter'
                              : 'Try increasing the distance range',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _refreshNearbyUsers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshNearbyUsers,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: nearbyUsers.length,
                    itemBuilder: (context, index) {
                      final user = nearbyUsers[index];
                      final distance = userProvider.getDistanceToUser(user);
                      
                      // Get common interests
                      final commonInterests = user.interests
                          .where((interest) => currentUser.interests.contains(interest))
                          .toList();
                      
                      // Check friendship status
                      final isFriend = currentUser.friendIds.contains(user.userId);
                      final isRequestSent = currentUser.sentFriendRequests.contains(user.userId);
                      
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () => _showUserProfileDialog(user, distance),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Avatar
                                Hero(
                                  tag: 'avatar_${user.userId}',
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.accentGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        user.userName.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // User details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user.userName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(width: 4),
                                          if (isFriend)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Friend',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          else if (isRequestSent)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Requested',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        '@${user.username}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      
                                      // Interests
                                      if (user.interests.isNotEmpty) ...[  
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.interests,
                                              size: 12,
                                              color: AppTheme.primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                user.interests.join(', '),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      
                                      // Common interests
                                      if (commonInterests.isNotEmpty) ...[  
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.favorite,
                                                    size: 10,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${commonInterests.length} in common',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme.primaryColor,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // Distance and action button
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${distance.toStringAsFixed(1)} km',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (isFriend)
                                      TextButton.icon(
                                        onPressed: () => _startChat(user),
                                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                        label: const Text('Chat'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.primaryColor,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      )
                                    else
                                      TextButton.icon(
                                        onPressed: isRequestSent ? null : () => _sendFriendRequest(user),
                                        icon: Icon(
                                          isRequestSent ? Icons.hourglass_top : Icons.person_add_outlined, 
                                          size: 16,
                                        ),
                                        label: Text(isRequestSent ? 'Sent' : 'Add'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.accentColor,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          disabledForegroundColor: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshNearbyUsers,
        backgroundColor: AppTheme.primaryColor,
        child: _isSearching 
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}