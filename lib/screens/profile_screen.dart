import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../theme.dart';
import '../widgets/profile_stats_animation.dart';
import '../services/sound_service.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final SoundService _soundService = SoundService();
  late AnimationController _confettiController;
  
  bool _isUsernameValid = true;
  String? _usernameErrorMessage;
  bool _isCheckingUsername = false;
  bool _isSaving = false;
  bool _isEditingUsername = false;
  bool _isEditingDisplayName = false;
  bool _isEditingBio = false;
  bool _showStats = false;

  String? _currentBackgroundImage;
  bool _useAnimation = true;
  String? _profileImageUrl;
  List<Color> _gradientColors = [
    AppTheme.primaryColor,
    AppTheme.accentColor,
    Colors.purple,
  ];
  
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      _usernameController.text = userProvider.currentUser!.username;
      _displayNameController.text = userProvider.currentUser!.userName;
      _bioController.text = userProvider.currentUser!.bio ?? '';
      
      // Initialize profile customization options
      final user = userProvider.currentUser!;
      if (user.data != null) {
        _currentBackgroundImage = user.data!['backgroundImage'];
        _useAnimation = user.data!['useAnimation'] ?? true;
        _profileImageUrl = user.data!['profileImageUrl'];
        
        if (user.data!['gradientColors'] != null) {
          try {
            _gradientColors = List<Color>.from(
              user.data!['gradientColors'].map((c) => Color(c))
            );
          } catch (e) {
            // Use default gradient colors if there's an error
          }
        }
      }
    }
    
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showStats = true);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Check username validity
  Future<void> _checkUsername(String username) async {
    if (username.isEmpty) {
      setState(() {
        _isUsernameValid = true;
        _usernameErrorMessage = null;
      });
      return;
    }
    
    // Basic validation
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _isUsernameValid = false;
        _usernameErrorMessage = 'Username can only contain letters, numbers, and underscores';
      });
      return;
    }
    
    setState(() {
      _isCheckingUsername = true;
      _usernameErrorMessage = null;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isUnique = await userProvider.checkUsernameUnique(username);
      
      if (mounted) {
        setState(() {
          _isUsernameValid = isUnique;
          _usernameErrorMessage = isUnique ? null : 'Username is already taken';
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUsername = false;
        });
      }
    }
  }

  // Change background image
  void _changeBackgroundImage() {
    _soundService.playTapSound();
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.wallpaper, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Choose Background',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Options grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  // Gradient animation option
                  _buildBackgroundOption(
                    title: 'Gradient Animation',
                    icon: Icons.animation,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.animation, color: Colors.white, size: 40)),
                    ),
                    onTap: () {
                      setState(() {
                        _currentBackgroundImage = null;
                        _useAnimation = true;
                      });
                      _saveProfileChanges(backgroundImage: null, useAnimation: true);
                      Navigator.pop(context);
                    },
                    isSelected: _currentBackgroundImage == null && _useAnimation,
                  ),
                  
                  // Nature background
                  _buildBackgroundOption(
                    title: 'Nature',
                    icon: Icons.nature,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "https://pixabay.com/get/gcbee6789f604756447d8b0ba6211a4ac6d5e01c08a5fb4f294feeef83d3b408e61aa266e27008de7c5507cc3f4ea33a128964751f172875020bb18575e867ef2_1280.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                    onTap: () {
                      final imageUrl = "https://pixabay.com/get/gd3eca73fcbe624dc08454f0202d5d2101a9d2a7e137f2b8b9e1069dee56075b48150ff6da36e0576978f18eee56f956e63971cd156584dc19fa95bab9ea70f95_1280.jpg";
                      setState(() {
                        _currentBackgroundImage = imageUrl;
                        _useAnimation = false;
                      });
                      _saveProfileChanges(backgroundImage: imageUrl, useAnimation: false);
                      Navigator.pop(context);
                    },
                    isSelected: _currentBackgroundImage != null && !_useAnimation,
                  ),
                  
                  // Abstract art background
                  _buildBackgroundOption(
                    title: 'Abstract Art',
                    icon: Icons.palette,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "https://pixabay.com/get/ga651e4f68a7cc755099e0d1d0d493bc3b6ea3639e7bff3f272b314886e42cd552904ff2901ceaa8c4339fc37394192dbc5d234ee4950eabe3b4c61a3d4b16db1_1280.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                    onTap: () {
                      final imageUrl = "https://pixabay.com/get/gbe8079949121e964e8e359a360eb757409a792f761680ea7d71598468f86ff90370a436dee691cab2c995443e614eff0901d4d058553171f60d67e59a5f4a36e_1280.jpg";
                      setState(() {
                        _currentBackgroundImage = imageUrl;
                        _useAnimation = false;
                      });
                      _saveProfileChanges(backgroundImage: imageUrl, useAnimation: false);
                      Navigator.pop(context);
                    },
                    isSelected: _currentBackgroundImage != null && !_useAnimation,
                  ),
                  
                  // City background
                  _buildBackgroundOption(
                    title: 'City',
                    icon: Icons.location_city,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        "https://pixabay.com/get/gf8c1ee09150c4ff276199b45c4f6fab2edc0c13a05c25692e1395099fe84c235dcda69d6128fedb09c7fa3d6d7461df27f8a887d277636c79ec875e3d3d89e1c_1280.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                    onTap: () {
                      final imageUrl = "https://pixabay.com/get/g0ed97b47066f79255b3915b008a84a899d06146dc33f3ba04c87d4168659028a016a3c785ef471b1a620fa08f3e90bb5bdb7d377ec20d8f9b66612ecd4e3d7f5_1280.jpg";
                      setState(() {
                        _currentBackgroundImage = imageUrl;
                        _useAnimation = false;
                      });
                      _saveProfileChanges(backgroundImage: imageUrl, useAnimation: false);
                      Navigator.pop(context);
                    },
                    isSelected: _currentBackgroundImage != null && !_useAnimation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Change profile picture or animation
  void _changeProfilePicture() {
    _soundService.playTapSound();
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.person, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Choose Profile Picture',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Profile image options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pulsing animation (default)
                  ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentColor.withOpacity(0.1),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: PulsingCircle(),
                        ),
                      ),
                    ),
                    title: const Text('Pulsing Animation'),
                    subtitle: const Text('Animated display with your initial'),
                    trailing: _profileImageUrl == null 
                      ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : null,
                    onTap: () {
                      setState(() {
                        _profileImageUrl = null;
                      });
                      _saveProfileChanges(profileImageUrl: null);
                      Navigator.pop(context);
                    },
                  ),
                  
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text('Or choose a profile picture:'),
                  ),
                  
                  // Profile picture options in a grid
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildProfileImageOption(
                        "https://pixabay.com/get/gb5a6193c81ae143e81f0724ed385fb33cec4e64e93e50f8af76fa8fcd8b43c60f65e38e1f251e3094a523518edcfc61ffbb144778dd5d02126ef12449fc91cd1_1280.jpg",
                      ),
                      _buildProfileImageOption(
                        "https://pixabay.com/get/gc02f23af273a00d3a59680ce06bd1b4bf677d44d194a111e26d6c534a79bbbfbc3ab3be225c7cae156ba8e566240a047ee5564160e8321528c575e13ace614e7_1280.jpg",
                      ),
                      _buildProfileImageOption(
                        "https://pixabay.com/get/g9848838c262e374085f5b18e44b91058e2108753eb6d8a49c27218f109227101462f859db9219ab958ea4034596e5637d59bc839db017dc9666c4576af8e38a9_1280.jpg",
                      ),
                      _buildProfileImageOption(
                        "https://pixabay.com/get/g5d760a6b1ed93c85ed888684fcdc8a070b41742ce203119a673e4b9c0792dac6ef9af1fede5e9a88324e52f182599e09c5c93fc12a637cb37abcfa47e3764896_1280.jpg",
                      ),
                      _buildProfileImageOption(
                        "https://pixabay.com/get/gf31cb173b81becc149a3faf8de3d788ae08cb6b5ffe1271c5fc33d03e02962bf246bc9094bc38de4c87e70746e137b09e27880bfd4c75832186d5088de26d426_1280.jpg",
                      ),
                      _buildProfileImageOption(
                        "https://pixabay.com/get/g12af5cf054709951b6a01ec589844b5c0a634ca28ee243fc5c072093e9034491d67ce47755a279134577e9beec9616a0f4753beb0b19240137bc954e9d646d17_1280.jpg",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Change gradient colors
  void _changeGradientColors() {
    _soundService.playTapSound();
    HapticFeedback.mediumImpact();
    
    // Define some predefined color schemes
    final colorSchemes = [
      // Purple to blue (default)
      [
        AppTheme.primaryColor,
        AppTheme.accentColor,
        Colors.purple,
      ],
      // Sunset (orange to pink)
      [
        Colors.orange,
        Colors.deepOrange,
        Colors.pink,
      ],
      // Ocean (blue to teal)
      [
        Colors.blue,
        Colors.lightBlue,
        Colors.teal,
      ],
      // Forest (green shades)
      [
        Colors.green,
        Colors.lightGreen,
        Colors.teal,
      ],
      // Twilight (deep blue to purple)
      [
        Colors.indigo,
        Colors.deepPurple,
        Colors.purple,
      ],
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Gradient Colors'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: colorSchemes.length,
            itemBuilder: (context, index) {
              final colors = colorSchemes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _gradientColors = colors;
                    });
                    _saveProfileChanges(
                      gradientColors: colors.map((c) => c.value).toList(),
                    );
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _gradientColors.toString() == colors.toString()
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white),
                          )
                        : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  // Save profile changes
  Future<void> _saveProfileChanges({
    String? backgroundImage,
    bool? useAnimation,
    String? profileImageUrl,
    List<int>? gradientColors,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) return;
    
    // Update data
    Map<String, dynamic> data = currentUser.data ?? {};
    
    if (backgroundImage != null || useAnimation != null) {
      data['backgroundImage'] = backgroundImage;
      data['useAnimation'] = useAnimation ?? true;
    }
    
    if (profileImageUrl != null) {
      data['profileImageUrl'] = profileImageUrl;
    }
    
    if (gradientColors != null) {
      data['gradientColors'] = gradientColors;
    }
    
    // Create updated user
    final updatedUser = currentUser.copyWith(data: data);
    
    try {
      await userProvider.updateUser(updatedUser);
      
      // Play success sound
      _soundService.playSuccessSound();
      
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'))
        );
      }
    }
  }
  
  // Save profile text information
  Future<void> _saveProfile() async {
    if (_isCheckingUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait while we check your username'))
      );
      return;
    }
    
    if (!_isUsernameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_usernameErrorMessage ?? 'Username is not valid'))
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not found');
      }
      
      // Create updated user
      final updatedUser = currentUser.copyWith(
        username: _usernameController.text.trim(),
        userName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      );
      
      await userProvider.updateUser(updatedUser);
      
      if (mounted) {
        // Close editing mode
        setState(() {
          _isEditingUsername = false;
          _isEditingDisplayName = false;
          _isEditingBio = false;
          _isSaving = false;
        });
        
        // Play success sound
        _soundService.playSuccessSound();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'))
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) {
          return const Center(child: Text('User profile not found'));
        }

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Flexible Header with background options
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileBackground(),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.userName),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () {
                          setState(() {
                            _isEditingDisplayName = true;
                          });
                        },
                      ),
                    ],
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.wallpaper_outlined),
                    tooltip: 'Change background',
                    onPressed: _changeBackgroundImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.color_lens_outlined),
                    tooltip: 'Change colors',
                    onPressed: _changeGradientColors,
                  ),
                ],
              ),
              
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Picture with edit button
                    Stack(
                      children: [
                        // Profile picture or animation
                        GestureDetector(
                          onTap: _changeProfilePicture,
                          child: _profileImageUrl != null
                            ? Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: NetworkImage(_profileImageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : PulsingAvatar(
                                text: user.userName.substring(0, 1).toUpperCase(),
                                size: 120,
                                color: AppTheme.accentColor,
                              ),
                        ),
                        
                        // Edit button
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: _changeProfilePicture,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              iconSize: 16,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Display Name (Edit Dialog)
                    if (_isEditingDisplayName)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            TextField(
                              controller: _displayNameController,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                hintText: 'Enter your display name',
                                prefixIcon: Icon(Icons.person),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Reset to original value
                                    _displayNameController.text = user.userName;
                                    setState(() {
                                      _isEditingDisplayName = false;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        user.userName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    const SizedBox(height: 8),
                    
                    // Username section
                    _isEditingUsername
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Enter unique username',
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  prefixText: '@',
                                  errorText: _usernameErrorMessage,
                                  suffixIcon: _isCheckingUsername
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : _usernameController.text.isNotEmpty
                                      ? Icon(
                                          _isUsernameValid
                                            ? Icons.check_circle
                                            : Icons.error,
                                          color: _isUsernameValid
                                            ? Colors.green
                                            : Colors.red,
                                        )
                                      : null,
                                ),
                                onChanged: (value) {
                                  if (value != user.username) {
                                    _checkUsername(value);
                                  } else {
                                    setState(() {
                                      _isUsernameValid = true;
                                      _usernameErrorMessage = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      // Reset to original value
                                      _usernameController.text = user.username;
                                      setState(() {
                                        _isEditingUsername = false;
                                        _isUsernameValid = true;
                                        _usernameErrorMessage = null;
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _isUsernameValid ? _saveProfile : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Save'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '@${user.username}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _isEditingUsername = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 24),
                    
                    // Bio section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _isEditingBio
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bio',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _bioController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a bio to tell the world about yourself',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                maxLength: 150,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      // Reset to original value
                                      _bioController.text = user.bio ?? '';
                                      setState(() {
                                        _isEditingBio = false;
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Save'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Card(
                                elevation: 0,
                                color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]?.withOpacity(0.5)
                                  : Colors.grey[100]?.withOpacity(0.7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Bio',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 16),
                                            onPressed: () {
                                              setState(() {
                                                _isEditingBio = true;
                                              });
                                            },
                                            color: AppTheme.primaryColor,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        user.bio ?? 'Add a bio to tell the world about yourself',
                                        style: TextStyle(
                                          fontStyle: user.bio == null ? FontStyle.italic : FontStyle.normal,
                                          color: user.bio == null ? Colors.grey[600] : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Interests section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Interests',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: user.interests.asMap().entries.map((entry) {
                              final index = entry.key;
                              final interest = entry.value;
                              return ShimmeringInterestChip(
                                label: interest,
                                delay: Duration(milliseconds: index * 100),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Stats section
                    if (_showStats) 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              'Your Profile Stats',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                AnimatedStatsCard(
                                  title: 'Friends',
                                  value: user.friendIds.length.toString(),
                                  icon: Icons.people,
                                  delay: const Duration(milliseconds: 200),
                                ),
                                AnimatedStatsCard(
                                  title: 'Communities',
                                  value: '5', // This would be dynamic in a full implementation
                                  icon: Icons.groups,
                                  delay: const Duration(milliseconds: 400),
                                ),
                                AnimatedStatsCard(
                                  title: 'Posts',
                                  value: '12', // This would be dynamic in a full implementation
                                  icon: Icons.post_add,
                                  delay: const Duration(milliseconds: 600),
                                  onTap: () {
                                    // Navigate to posts or show a dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Your posts will appear here'))
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Build the profile background based on settings
  Widget _buildProfileBackground() {
    if (_currentBackgroundImage != null && !_useAnimation) {
      // Use static background image
      return Image.network(
        _currentBackgroundImage!,
        fit: BoxFit.cover,
      );
    } else {
      // Use animated gradient
      return AnimatedBackgroundGradient(
        height: 200,
        colors: _gradientColors,
      );
    }
  }
  
  // Widget to build a background option for selection
  Widget _buildBackgroundOption({
    required String title,
    required IconData icon,
    required Widget child,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            // Background image or gradient
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: child,
            ),
            
            // Title at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(9),
                    bottomRight: Radius.circular(9),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Build a profile image option for selection
  Widget _buildProfileImageOption(String imageUrl) {
    final isSelected = _profileImageUrl == imageUrl;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _profileImageUrl = imageUrl;
        });
        _saveProfileChanges(profileImageUrl: imageUrl);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(imageUrl),
          child: isSelected
            ? Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white),
              )
            : null,
        ),
      ),
    );
  }
}

class PulsingCircle extends StatefulWidget {
  const PulsingCircle({Key? key}) : super(key: key);

  @override
  State<PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<PulsingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 40 * _animation.value,
          height: 40 * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentColor.withOpacity(0.7 * (2 - _animation.value)),
          ),
        );
      },
    );
  }
}