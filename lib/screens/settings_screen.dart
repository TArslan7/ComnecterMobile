// FUTURE: Voeg premium instellingen toggle toe (radar upgrade, ads verwijderen)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme.dart';
import 'onboarding_screen.dart';
import 'friends_insight_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;
  double _maxSearchDistance = 5.0;
  bool _friendsInsightEnabled = false;
  bool _isDetectable = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // In a real app, these would be loaded from SharedPreferences
    // For this demo, we'll just use default values
    setState(() {
      _darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
      
      // Load Friends Insight setting from user profile
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        _friendsInsightEnabled = userProvider.currentUser!.friendsInsightEnabled;
        _isDetectable = userProvider.currentUser!.isDetectable;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme settings
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              // In a full implementation, this would change the theme
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme settings would be saved in a real app'))
              );
            },
            secondary: Icon(
              Icons.brightness_4,
              color: AppTheme.primaryColor,
            ),
          ),
          const Divider(),
          
          // Notification settings
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get alerts about new messages and nearby users'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings would be saved in a real app'))
              );
            },
            secondary: Icon(
              Icons.notifications_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          ListTile(
            title: const Text('Notification Types'),
            subtitle: const Text('Choose which notifications to receive'),
            leading: Icon(
              Icons.list_alt_outlined,
              color: AppTheme.primaryColor,
            ),
            enabled: _notificationsEnabled,
            onTap: _notificationsEnabled ? () {
              // Would show notification type settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Would show notification type settings'))
              );
            } : null,
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          
          // Privacy settings
          _buildSectionHeader('Privacy'),
          SwitchListTile(
            title: const Text('Location Services'),
            subtitle: const Text('Allow the app to access your location'),
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location settings would be saved in a real app'))
              );
            },
            secondary: Icon(
              Icons.location_on_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          SwitchListTile(
            title: const Text('Radar Visibility'),
            subtitle: const Text('Allow others to see you on their radar'),
            value: _isDetectable,
            onChanged: (value) {
              _toggleDetectability(value);
            },
            secondary: Icon(
              Icons.visibility_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          ListTile(
            title: Text('Maximum Search Distance'),
            subtitle: Text('${_maxSearchDistance.toStringAsFixed(1)} km'),
            leading: Icon(
              Icons.radar_outlined,
              color: AppTheme.primaryColor,
            ),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: _maxSearchDistance,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: _maxSearchDistance.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _maxSearchDistance = value;
                  });
                },
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Friends Insight'),
            subtitle: const Text('Share and see detailed friendship activity'),
            value: _friendsInsightEnabled,
            onChanged: (value) {
              // Show explanation dialog before toggling
              if (value != _friendsInsightEnabled) {
                _showFriendsInsightDialog(value);
              }
            },
            secondary: Icon(
              Icons.visibility_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
          ListTile(
            title: const Text('Friends Insight Activity'),
            subtitle: const Text('See detailed friendship statistics and history'),
            leading: Icon(
              Icons.analytics_outlined,
              color: AppTheme.primaryColor,
            ),
            enabled: _friendsInsightEnabled,
            onTap: _friendsInsightEnabled ? () {
              _showFriendsInsightActivity();
            } : null,
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          
          // Account settings
          _buildSectionHeader('Account'),
          ListTile(
            title: const Text('Edit Profile'),
            subtitle: const Text('Change your name, interests, and other details'),
            leading: Icon(
              Icons.person_outline,
              color: AppTheme.primaryColor,
            ),
            onTap: () {
              // Navigate back to profile and trigger edit mode
              Navigator.pop(context);
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Data & Storage'),
            subtitle: const Text('Manage your data usage and storage'),
            leading: Icon(
              Icons.storage_outlined,
              color: AppTheme.primaryColor,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Would show data and storage settings'))
              );
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Clear Chat History'),
            subtitle: const Text('Delete all messages and conversations'),
            leading: Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            onTap: () {
              _showClearChatDialog();
            },
          ),
          ListTile(
            title: const Text('Log Out'),
            subtitle: const Text('Sign out of your account'),
            leading: Icon(
              Icons.logout,
              color: Colors.red,
            ),
            onTap: () {
              _showLogoutDialog();
            },
          ),
          const Divider(),
          
          // Help & About
          _buildSectionHeader('Help & About'),
          ListTile(
            title: const Text('Help Center'),
            leading: Icon(
              Icons.help_outline,
              color: AppTheme.primaryColor,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Would show help center'))
              );
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('About'),
            leading: Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
            ),
            onTap: () {
              _showAboutDialog();
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: AppTheme.primaryColor,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Would show privacy policy'))
              );
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            leading: Icon(
              Icons.description_outlined,
              color: AppTheme.primaryColor,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Would show terms of service'))
              );
            },
            trailing: const Icon(Icons.chevron_right),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
  
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('This will delete all your messages and conversations. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared'))
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // In a real app, this would clear user data and token
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Comnecter',
        applicationVersion: '1.0.0',
        applicationIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.radar,
            color: Colors.white,
            size: 30,
          ),
        ),
        children: [
          const SizedBox(height: 16),
          const Text('Let Us Connect - A chat app to help you connect with people around you who share your interests.'),
          const SizedBox(height: 16),
          const Text('© 2023 Comnecter'),
        ],
      ),
    );
  }
  
  // Show explanatory dialog when enabling/disabling Friends Insight
  void _showFriendsInsightDialog(bool newValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newValue ? 'Enable Friends Insight?' : 'Disable Friends Insight?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newValue 
                ? 'When you enable Friends Insight:'
                : 'When you disable Friends Insight:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...newValue 
              ? _buildEnablingBulletPoints()
              : _buildDisablingBulletPoints(),
            const SizedBox(height: 16),
            const Text(
              'Friends Insight operates on a mutual transparency principle - you can only see these changes from users who have also enabled Friends Insight.', 
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleFriendsInsight(newValue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newValue ? AppTheme.primaryColor : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(newValue ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );
  }
  
  // Build bullet points for enabling Friends Insight
  List<Widget> _buildEnablingBulletPoints() {
    return [
      _buildBulletPoint('You will be able to see when someone blocks you'),
      _buildBulletPoint('You will be able to see when someone removes you as a friend'),
      _buildBulletPoint('You will be able to see when someone mutes or restricts you'),
      _buildBulletPoint('You will be able to see when someone reads but ignores your messages'),
      _buildBulletPoint('You will be able to see when someone removes you from a group chat'),
      const SizedBox(height: 8),
      _buildBulletPoint('Others with Friends Insight will see the same information about you', isWarning: true),
    ];
  }
  
  // Build bullet points for disabling Friends Insight
  List<Widget> _buildDisablingBulletPoints() {
    return [
      _buildBulletPoint('You will no longer see when someone blocks, removes, mutes, or restricts you'),
      _buildBulletPoint('You will no longer see when your messages are read but ignored'),
      _buildBulletPoint('You will no longer see when you are removed from group chats'),
      const SizedBox(height: 8),
      _buildBulletPoint('Others will no longer see this information about you either', isPositive: true),
      _buildBulletPoint('Friend request acceptance/decline notifications will still be visible to all users'),
    ];
  }
  
  // Helper to build a bullet point
  Widget _buildBulletPoint(String text, {bool isWarning = false, bool isPositive = false}) {
    Color textColor = isWarning ? Colors.red : (isPositive ? Colors.green : Colors.black87);
    if (Theme.of(context).brightness == Brightness.dark) {
      textColor = isWarning ? Colors.red : (isPositive ? Colors.green : Colors.white70);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }
  
  // Toggle the Friends Insight setting
  void _toggleFriendsInsight(bool newValue) async {
    setState(() {
      _friendsInsightEnabled = newValue;
    });
    
    // Update the user profile
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.toggleFriendsInsight(newValue);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Friends Insight ${newValue ? 'enabled' : 'disabled'} successfully'))
        );
      }
    } catch (e) {
      // Restore previous state if failed
      if (mounted) {
        setState(() {
          _friendsInsightEnabled = !newValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating Friends Insight: $e'))
        );
      }
    }
  }
  
  // Show Friends Insight Activity screen
  void _showFriendsInsightActivity() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const FriendsInsightScreen()),
    );
  }
  
  // Toggle user detectability on radar
  Future<void> _toggleDetectability(bool value) async {
    setState(() => _isDetectable = value);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      
      if (currentUser != null) {
        // Update the user model with the new detectability setting
        final updatedUser = currentUser.copyWith(isDetectable: value);
        await userProvider.updateUser(updatedUser);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Radar visibility ${value ? "enabled" : "disabled"}'))
        );
      }
    } catch (e) {
      // Restore previous state if failed
      if (mounted) {
        setState(() => _isDetectable = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating radar visibility: $e'))
        );
      }
    }
  }
}