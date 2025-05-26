import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../screens/home_screen.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/community_provider.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';
import '../services/app_refresh_service.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'chat_detail_screen.dart';
import 'user_search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  // Animation controllers
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching ? AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search chats...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.6)),
          ),
          style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
        ],
      ) : null,
      body: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: Icon(
                  _currentTabIndex == 0 ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  color: _currentTabIndex == 0 ? AppTheme.primaryColor : null,
                ),
                text: 'Direct',
              ),
              Tab(
                icon: Icon(
                  _currentTabIndex == 1 ? Icons.group : Icons.group_outlined,
                  color: _currentTabIndex == 1 ? AppTheme.primaryColor : null,
                ),
                text: 'Communities',
              ),
            ],
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[700],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          
          // Search bar (only when not in search mode)
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isSearching = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search, 
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search chats...', 
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // TabBarView fills remaining space
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DirectChatsTab(searchQuery: _searchQuery),
                _CommunityChatsTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _buildFloatingActionButton(),
      ),
    );
  }
  
  Widget _buildFloatingActionButton() {
    // Different fab actions based on current tab
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        key: ValueKey<int>(_currentTabIndex),
        onPressed: () {
          HapticFeedback.mediumImpact();
          if (_currentTabIndex == 0) {
            // New direct chat
            _showNewChatOptions();
          } else {
            // New community chat
            _showJoinCommunityDialog();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        elevation: 8, // Increased elevation for better z-index handling
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: Text(_currentTabIndex == 0 ? 'New Chat' : 'Join', style: const TextStyle(fontWeight: FontWeight.bold)),
        icon: Icon(
          _currentTabIndex == 0 ? Icons.chat : Icons.group_add,
          color: Colors.white,
        ),
      ),
    );
  }
  
  void _showNewChatOptions() {
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
                // Navigate to radar tab (first tab index)
                HomeScreen.navigateToTab(context, 0);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showJoinCommunityDialog() {
    // This would show options to join/create communities
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
                // Navigate to community creation screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Community creation coming soon')),
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
                // Navigate to community browser
                // Switch to communities tab
                HomeScreen.navigateToTab(context, 2);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectChatsTab extends StatelessWidget {
  final String searchQuery;
  
  const _DirectChatsTab({Key? key, this.searchQuery = ''}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, UserProvider>(
      builder: (context, chatProvider, userProvider, _) {
        final userId = userProvider.currentUser?.userId;
        if (userId == null) {
          return const Center(child: Text('User profile not found'));
        }

        final directChats = chatProvider.getDirectChats();
        
        // Filter by search query if needed
        final filteredChats = searchQuery.isEmpty 
            ? directChats 
            : directChats.where((chat) {
                final otherUserId = chat.participantIds.firstWhere((id) => id != userId, orElse: () => '');
                if (otherUserId.isEmpty) return false;
                
                final otherUser = userProvider.nearbyUsers.firstWhere(
                  (user) => user.userId == otherUserId,
                  orElse: () => UserModel(
                    userId: otherUserId,
                    userName: 'User',
                    username: 'unknown',
                    latitude: 0,
                    longitude: 0,
                    interests: [],
                  ),
                );
                
                return otherUser.userName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                       otherUser.username.toLowerCase().contains(searchQuery.toLowerCase()) ||
                       (chat.lastMessageContent?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
              }).toList();
        
        if (filteredChats.isEmpty) {
          return _buildEmptyState(context, searchQuery.isNotEmpty);
        }

        // Add refreshable functionality
        return RefreshIndicator(
          onRefresh: () async {
            // Add haptic feedback
            HapticFeedback.mediumImpact();
            
            // Add sound effect
            final SoundService soundService = SoundService();
            soundService.playTapSound();
            
            // Load chats
            await chatProvider.loadChats(userId);
            
            // Play success sound
            soundService.playSuccessSound();
          },
          color: AppTheme.primaryColor,
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800] 
              : Colors.white,
          child: AnimationLimiter(
            child: ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                final otherUserId = chat.participantIds.firstWhere((id) => id != userId);
                final otherUser = userProvider.nearbyUsers.firstWhere(
                  (user) => user.userId == otherUserId,
                  orElse: () => UserModel(
                    userId: otherUserId,
                    userName: 'User',
                    username: 'unknown',
                    latitude: 0,
                    longitude: 0,
                    interests: [],
                  ),
                );
                
                // Use staggered animations for list items
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildChatTile(
                        context,
                        chat,
                        otherUser.userName,
                        otherUser.username,
                        () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                                opacity: animation,
                                child: ChatDetailScreen(
                                  chatId: chat.chatId,
                                  otherUser: otherUser,
                                ),
                              ),
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    if (isSearching) {
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
              'No chats found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
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
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 72,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Use the radar to find people nearby and start chatting with them!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to radar screen
                HomeScreen.navigateToTab(context, 0);
              },
              icon: const Icon(Icons.radar),
              label: const Text('Go to Radar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    ChatModel chat,
    String title,
    String username,
    VoidCallback onTap,
  ) {
    final lastMessage = chat.lastMessageContent;
    final lastMessageTime = chat.lastMessageTime;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 0,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]?.withOpacity(0.5)
            : Colors.grey[100]?.withOpacity(0.7),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar
                Hero(
                  tag: 'avatar_${chat.participantIds.where((id) => id != Provider.of<UserProvider>(context).currentUser?.userId).first}',
                  child: Container(
                    width: 56,
                    height: 56,
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
                        title.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (lastMessageTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatTimestamp(lastMessageTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      lastMessage != null
                          ? Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            )
                          : Text(
                              'Start a conversation',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

class _CommunityChatsTab extends StatelessWidget {
  final String searchQuery;
  
  const _CommunityChatsTab({Key? key, this.searchQuery = ''}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer3<ChatProvider, UserProvider, CommunityProvider>(
      builder: (context, chatProvider, userProvider, communityProvider, _) {
        final userId = userProvider.currentUser?.userId;
        if (userId == null) {
          return const Center(child: Text('User profile not found'));
        }

        final communityChats = chatProvider.getCommunityChats();
        
        // Filter by search query if needed
        final filteredChats = searchQuery.isEmpty 
            ? communityChats 
            : communityChats.where((chat) {
                if (chat.communityId == null) return false;
                
                try {
                  final community = communityProvider.communities.firstWhere(
                    (c) => c.communityId == chat.communityId,
                  );
                  
                  return community.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                         community.uniqueTag.toLowerCase().contains(searchQuery.toLowerCase()) ||
                         community.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase())) ||
                         (chat.lastMessageContent?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
                } catch (e) {
                  return false;
                }
              }).toList();
        
        if (filteredChats.isEmpty) {
          return _buildEmptyState(context, searchQuery.isNotEmpty);
        }

        // Add refreshable functionality
        return RefreshIndicator(
          onRefresh: () async {
            // Add haptic feedback
            HapticFeedback.mediumImpact();
            
            // Add sound effect
            final SoundService soundService = SoundService();
            soundService.playTapSound();
            
            // Load chats and communities in parallel
            await Future.wait([
              chatProvider.loadChats(userId),
              communityProvider.loadAllCommunities(),
              communityProvider.loadUserCommunities(userId),
            ]);
            
            // Play success sound
            soundService.playSuccessSound();
          },
          color: AppTheme.primaryColor,
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800] 
              : Colors.white,
          child: AnimationLimiter(
            child: ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                
                // Find community info
                CommunityModel? community;
                if (chat.communityId != null) {
                  try {
                    community = communityProvider.communities.firstWhere(
                      (c) => c.communityId == chat.communityId,
                    );
                  } catch (e) {
                    // Community not found
                  }
                }

                final communityName = community?.name ?? 'Unknown Community';
                final communityTag = community?.uniqueTag ?? '';

                // Use staggered animations
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildChatTile(
                        context,
                        chat,
                        communityName,
                        communityTag,
                        community,
                        () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                                opacity: animation,
                                child: ChatDetailScreen(
                                  chatId: chat.chatId,
                                  isCommunityChat: true,
                                  communityName: communityName,
                                ),
                              ),
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    if (isSearching) {
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
              'No community chats found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
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
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 72,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No community chats yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Join a community to start chatting with people who share your interests!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to communities screen
                HomeScreen.navigateToTab(context, 2);
              },
              icon: const Icon(Icons.group_add),
              label: const Text('Browse Communities'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    ChatModel chat,
    String communityName,
    String communityTag,
    CommunityModel? community,
    VoidCallback onTap,
  ) {
    final lastMessage = chat.lastMessageContent;
    final lastMessageTime = chat.lastMessageTime;
    final memberCount = community?.memberIds.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 0,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]?.withOpacity(0.5)
            : Colors.grey[100]?.withOpacity(0.7),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Community avatar
                Hero(
                  tag: 'community_${chat.chatId}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.people_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              communityName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessageTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatTimestamp(lastMessageTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (communityTag.isNotEmpty)
                            Text(
                              '@$communityTag',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          if (communityTag.isNotEmpty && memberCount > 0)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (memberCount > 0)
                            Text(
                              '$memberCount members',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      lastMessage != null
                          ? Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            )
                          : Text(
                              'No messages yet',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                      if (community != null && community.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: community.tags.take(3).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}