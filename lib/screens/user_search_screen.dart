import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../models/user_model.dart';
import '../theme.dart';
import 'chat_detail_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<UserModel> _searchResults = [];
  String _searchQuery = '';

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
    
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final results = await userProvider.searchUsers(_searchQuery);
      
      // Filter out current user
      final currentUser = userProvider.currentUser;
      final filteredResults = results.where((user) => 
        currentUser == null || user.userId != currentUser.userId
      ).toList();
      
      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e'))
        );
      }
    }
  }

  Future<void> _sendFriendRequest(UserModel user) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to send friend requests'))
      );
      return;
    }
    
    try {
      await userProvider.sendFriendRequest(user.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friend request sent to ${user.userName}'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending friend request: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username or name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
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
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          
          if (!_isSearching)
            Expanded(
              child: _searchResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return _buildUserTile(user);
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Find friends by their username or name',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildUserTile(UserModel user) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    bool isFriend = currentUser != null && currentUser.friendIds.contains(user.userId);
    bool isRequestSent = currentUser != null && currentUser.sentFriendRequests.contains(user.userId);
    bool isRequestReceived = currentUser != null && currentUser.receivedFriendRequests.contains(user.userId);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.accentColor,
        child: Text(
          user.userName.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(user.userName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${user.username}'),
          if (user.interests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Interests: ${user.interests.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: _buildUserActions(user, isFriend, isRequestSent, isRequestReceived),
      onTap: () => _showUserProfileDialog(user),
    );
  }

  Widget _buildUserActions(UserModel user, bool isFriend, bool isRequestSent, bool isRequestReceived) {
    if (isFriend) {
      return ElevatedButton(
        onPressed: () => _startChat(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text('Message'),
      );
    } else if (isRequestSent) {
      return OutlinedButton(
        onPressed: null, // Disabled
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text('Request Sent'),
      );
    } else if (isRequestReceived) {
      return ElevatedButton(
        onPressed: () => _acceptFriendRequest(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text('Accept'),
      );
    } else {
      return OutlinedButton(
        onPressed: () => _sendFriendRequest(user),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text('Add Friend'),
      );
    }
  }

  Future<void> _acceptFriendRequest(UserModel user) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      await userProvider.acceptFriendRequest(user.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accepted friend request from ${user.userName}'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting friend request: $e'))
        );
      }
    }
  }

  Future<void> _startChat(UserModel user) async {
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
      // Create a new chat through the ChatProvider
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final newChat = await chatProvider.createChat([currentUser.userId, user.userId]);
      
      if (!mounted) return;
      
      // Navigate to chat detail
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
    }
  }

  void _showUserProfileDialog(UserModel user) {
    // Implement user profile dialog
    // This can be similar to the one in the RadarScreen, but you may want to customize it for the search context
  }
}