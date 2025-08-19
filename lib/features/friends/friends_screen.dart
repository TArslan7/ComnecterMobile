import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import 'models/friend_model.dart';
import 'services/friend_service.dart';
import 'package:go_router/go_router.dart';

class FriendsScreen extends HookWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final friendService = useMemoized(() => FriendService());
    final friends = useState<List<Friend>>([]);
    final requests = useState<List<FriendRequest>>([]);
    final stats = useState<FriendStats>(const FriendStats(totalFriends: 0, onlineFriends: 0, pendingRequests: 0, sentRequests: 0));
    final isLoading = useState(true);
    final searchQuery = useState('');
    final currentTab = useState(0);
    final showAddFriend = useState(false);
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 3)));
    final soundService = useMemoized(() => SoundService());
    final selectedFriend = useState<Friend?>(null);
    final showFriendDetails = useState(false);

    // Initialize friend service
    useEffect(() {
      friendService.initialize().then((_) {
        isLoading.value = false;
      });
      return null;
    }, []);

    // Listen to friend service updates
    useEffect(() {
      final friendsSubscription = friendService.friendsStream.listen((friendsList) {
        friends.value = friendsList;
      });
      
      final requestsSubscription = friendService.requestsStream.listen((requestsList) {
        requests.value = requestsList;
      });
      
      final statsSubscription = friendService.statsStream.listen((statsData) {
        stats.value = statsData;
      });

      return () {
        friendsSubscription.cancel();
        requestsSubscription.cancel();
        statsSubscription.cancel();
      };
    }, []);

    // Start status simulation
    useEffect(() {
      friendService.simulateStatusChanges();
      return null;
    }, []);

    void handleAcceptRequest(String requestId) async {
      await friendService.acceptFriendRequest(requestId);
      confettiController.play();
      soundService.playSuccessSound();
    }

    void handleRejectRequest(String requestId) async {
      await friendService.rejectFriendRequest(requestId);
      soundService.playErrorSound();
    }

    void handleRemoveFriend(String friendId) async {
      await friendService.removeFriend(friendId);
      soundService.playButtonClickSound();
    }

    void handleBlockFriend(String friendId) async {
      await friendService.blockFriend(friendId);
      soundService.playErrorSound();
    }



    void handleFriendTap(Friend friend) {
      soundService.playTapSound();
      selectedFriend.value = friend;
      showFriendDetails.value = true;
    }

    void handleSearch(String query) {
      searchQuery.value = query;
      if (query.isEmpty) {
        // Show all friends
        friends.value = friendService.getFriends();
      } else {
        // Show filtered friends
        friends.value = friendService.searchFriends(query);
      }
    }

    List<Friend> getFilteredFriends() {
      if (searchQuery.value.isEmpty) {
        return friends.value.where((f) => f.status == FriendStatus.accepted).toList();
      }
      return friends.value;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        centerTitle: true,
        leading: Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                  onPressed: () => context.pop(),
                  tooltip: 'Go Back',
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: IconButton(
                  icon: const Icon(Icons.settings, color: AppTheme.primary),
                  onPressed: () => context.push('/settings'),
                  tooltip: 'Settings',
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: IconButton(
                  icon: const Icon(Icons.people, color: AppTheme.primary),
                  onPressed: () => context.push('/friends'),
                  tooltip: 'Friends',
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'Friends',
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.backgroundLight.withValues(alpha: 0.95),
              AppTheme.backgroundLight.withValues(alpha: 0.9),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header with stats
                _buildHeader(context, stats.value),
                
                // Search bar
                _buildSearchBar(context, searchQuery.value, handleSearch),
                
                // Tab bar
                _buildTabBar(context, currentTab.value, (index) {
                  soundService.playButtonClickSound();
                  currentTab.value = index;
                }),
                
                // Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isLoading.value
                        ? _buildLoadingState(context)
                        : currentTab.value == 0
                            ? _buildFriendsList(context, getFilteredFriends(), handleFriendTap, handleRemoveFriend, handleBlockFriend)
                            : _buildRequestsList(context, requests.value, handleAcceptRequest, handleRejectRequest),
                  ),
                ),
              ],
            ),
            
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 10,
                minBlastForce: 4,
                emissionFrequency: 0.02,
                numberOfParticles: 100,
                gravity: 0.06,
                colors: [
                  AppTheme.primary,
                  AppTheme.secondary,
                  AppTheme.success,
                  AppTheme.warning,
                  AppTheme.error,
                ],
              ),
            ),

            // Friend details modal
            if (showFriendDetails.value && selectedFriend.value != null)
              _buildFriendDetailsModal(context, selectedFriend.value!, handleRemoveFriend, handleBlockFriend, () {
                showFriendDetails.value = false;
                selectedFriend.value = null;
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          soundService.playButtonClickSound();
          showAddFriend.value = true;
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FriendStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child:               Text(
                'Friends',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Use Wrap for better responsiveness on small screens
              if (constraints.maxWidth < 300) {
                return Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatItem('Total', stats.totalFriends.toString(), Icons.people),
                    _buildStatItem('Online', stats.onlineFriends.toString(), Icons.circle, color: AppTheme.success),
                    _buildStatItem('Requests', stats.pendingRequests.toString(), Icons.notifications),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(child: _buildStatItem('Total', stats.totalFriends.toString(), Icons.people)),
                    Expanded(child: _buildStatItem('Online', stats.onlineFriends.toString(), Icons.circle, color: AppTheme.success)),
                    Expanded(child: _buildStatItem('Requests', stats.pendingRequests.toString(), Icons.notifications)),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 60,
        maxWidth: 120,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ?? Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, String query, Function(String) onSearch) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: TextStyle(color: AppTheme.textMedium),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (query.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: AppTheme.textMedium),
              onPressed: () => onSearch(''),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, int currentTab, Function(int) onTabChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Friends',
              Icons.people,
              currentTab == 0,
              () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Requests',
              Icons.notifications,
              currentTab == 1,
              () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textMedium,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMedium,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    List<Friend> friends,
    Function(Friend) onFriendTap,
    Function(String) onRemoveFriend,
    Function(String) onBlockFriend,
  ) {
    if (friends.isEmpty) {
      return _buildEmptyState(context, 'No friends found', 'Start adding friends to see them here');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildFriendCard(context, friend, onFriendTap, onRemoveFriend, onBlockFriend),
        ).animate().fadeIn(
          delay: Duration(milliseconds: index * 100),
          duration: const Duration(milliseconds: 500),
        ).slideY(
          begin: 0.3,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  Widget _buildFriendCard(
    BuildContext context,
    Friend friend,
    Function(Friend) onFriendTap,
    Function(String) onRemoveFriend,
    Function(String) onBlockFriend,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceLight,
              AppTheme.surfaceLight.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => onFriendTap(friend),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          friend.avatar,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    if (friend.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.success.withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (friend.bio != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          friend.bio!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (friend.interests.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: friend.interests.take(3).map((interest) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              interest,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppTheme.textMedium),
                  onSelected: (value) {
                    switch (value) {
                      case 'remove':
                        onRemoveFriend(friend.friendId);
                        break;
                      case 'block':
                        onBlockFriend(friend.friendId);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove Friend'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Block Friend'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    List<FriendRequest> requests,
    Function(String) onAcceptRequest,
    Function(String) onRejectRequest,
  ) {
    final pendingRequests = requests.where((r) => r.response == null).toList();
    
    if (pendingRequests.isEmpty) {
      return _buildEmptyState(context, 'No pending requests', 'You\'re all caught up!');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRequests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildRequestCard(context, request, onAcceptRequest, onRejectRequest),
        ).animate().fadeIn(
          delay: Duration(milliseconds: index * 100),
          duration: const Duration(milliseconds: 500),
        ).slideY(
          begin: 0.3,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    FriendRequest request,
    Function(String) onAcceptRequest,
    Function(String) onRejectRequest,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceLight,
              AppTheme.surfaceLight.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        request.fromUserAvatar,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.fromUserName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          request.type == FriendRequestType.received ? 'Wants to be your friend' : 'Friend request sent',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        if (request.message != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            request.message!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMedium,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (request.type == FriendRequestType.received) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onAcceptRequest(request.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onRejectRequest(request.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading friends...',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.people_outline,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendDetailsModal(
    BuildContext context,
    Friend friend,
    Function(String) onRemoveFriend,
    Function(String) onBlockFriend,
    VoidCallback onClose,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.7),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          friend.avatar,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: friend.isOnline ? AppTheme.success : AppTheme.textMedium,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: friend.isOnline ? [
                                    BoxShadow(
                                      color: AppTheme.success.withOpacity(0.7),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ] : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                friend.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: friend.isOnline ? AppTheme.success : AppTheme.textMedium,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (friend.bio != null) ...[
                      const Text(
                        'Bio:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        friend.bio!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Text(
                      'Interests:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: friend.interests.map((interest) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClose,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onClose();
                          // TODO: Navigate to chat
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Message',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
  }
}
