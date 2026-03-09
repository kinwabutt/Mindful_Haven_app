import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/background_wrapper.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;

  String _userName = 'Kinza';
  String _userTitle = 'Software Engineer';
  String _profileImageUrl = 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80';
  final int _sessionCount = 12;
  final String _stabilityScore = '85%';
  final String _streakDays = '5D';
  final int _totalMinutes = 480;
  double _profileCompletion = 0.0;
  int profileCompletionPercentage = 0;

  // Achievement data backing the achievements UI (dynamic)
  Map<String, dynamic> _achievementData = {
    'streak': 7,
    'sessions': 10,
    'isPro': true,
    'rating': '5★',
  };

  bool _isNewUser = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    // Load saved profile and achievement data (if any).
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
          // store local path as profile image override
          _profileImageUrl = image.path;
          _isNewUser = false; // mark initialized when user adds a photo
          _recalculateProfileCompletion();
        });
        await _saveProfileData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated!'),
              backgroundColor: AppTheme.primaryTeal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error selecting image. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // Recalculate profile completion based on filled fields.
  void _recalculateProfileCompletion() {
    final int pct = calculateCompletion();
    setState(() {
      profileCompletionPercentage = pct;
      _profileCompletion = (pct / 100.0).clamp(0.0, 1.0);
    });
  }

  // Load saved profile & achievement data from SharedPreferences.
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool('profile_initialized') ?? false;
    if (!initialized) {
      // New user: keep controllers empty and zeroed achievements
      setState(() {
        _isNewUser = true;
        _nameController.text = '';
        _emailController.text = '';
        _bioController.text = '';
        _userName = '';
        _userTitle = '';
        _profileImageUrl = '';
        _achievementData = {
          'streak': 0,
          'sessions': 0,
          'isPro': false,
          'rating': '',
        };
      });
    } else {
      setState(() {
        _isNewUser = false;
        _nameController.text = prefs.getString('profile_name') ?? '';
        _emailController.text = prefs.getString('profile_email') ?? '';
        _bioController.text = prefs.getString('profile_bio') ?? '';
        _userName = prefs.getString('profile_name') ?? _userName;
        _userTitle = prefs.getString('profile_bio') ?? _userTitle;
        _profileImageUrl = prefs.getString('profile_image') ?? _profileImageUrl;
        _achievementData['streak'] = prefs.getInt('ach_streak') ?? (_achievementData['streak'] ?? 0);
        _achievementData['sessions'] = prefs.getInt('ach_sessions') ?? (_achievementData['sessions'] ?? 0);
        _achievementData['isPro'] = prefs.getBool('ach_isPro') ?? (_achievementData['isPro'] ?? false);
        _achievementData['rating'] = prefs.getString('ach_rating') ?? (_achievementData['rating'] ?? '');
      });
    }

    // Recalculate completion after loading
    _recalculateProfileCompletion();
  }

  // Persist profile & achievement data to SharedPreferences.
  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_initialized', true);
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setString('profile_email', _emailController.text.trim());
    await prefs.setString('profile_bio', _bioController.text.trim());
    await prefs.setString('profile_image', _profileImageUrl);
    await prefs.setInt('ach_streak', (_achievementData['streak'] ?? 0) as int);
    await prefs.setInt('ach_sessions', (_achievementData['sessions'] ?? 0) as int);
    await prefs.setBool('ach_isPro', (_achievementData['isPro'] ?? false) as bool);
    await prefs.setString('ach_rating', (_achievementData['rating'] ?? '').toString());
  }

  // Calculate completion percent by checking filled fields.
  // Four fields considered: name, bio, email, photo (25% each).
  int calculateCompletion() {
    int filled = 0;
    if (_nameController.text.trim().isNotEmpty) filled++;
    if (_bioController.text.trim().isNotEmpty) filled++;
    if (_emailController.text.trim().isNotEmpty) filled++;
    if (_selectedImage != null || _profileImageUrl.isNotEmpty) filled++;
    return (filled * 25);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.05;
    final verticalSpacing = screenHeight * 0.02;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: screenHeight * 0.4,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                  background: _buildPremiumProfileHeader(),
                  collapseMode: CollapseMode.pin,
                  expandedTitleScale: 1.0,
                ),
              leading: const SizedBox.shrink(),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildActionButton(
                    Icons.settings_outlined,
                    () => _showSettingsSheet(context),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalSpacing * 1.2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCompletionCard(),
                    SizedBox(height: verticalSpacing * 1.0),
                    _buildAchievementsSection(),
                    SizedBox(height: verticalSpacing * 1.0),
                    _buildGlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('ACCOUNT'),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.person_outline, color: AppTheme.primaryTeal),
                            title: Text('Personal Information', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('Edit your profile details', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showEditProfileSheet(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.notifications_none_rounded, color: AppTheme.primaryTeal),
                            title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('Customize your alerts', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.lock_outline_rounded, color: AppTheme.primaryTeal),
                            title: Text('Security', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('Password & authentication', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 1.0),
                    _buildGlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('JOURNEY'),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.history, color: AppTheme.primaryTeal),
                            title: Text('Progress Insights', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('Track your mindfulness growth', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.emoji_events_outlined, color: Colors.amber),
                            title: Text('Achievements', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('View all badges & rewards', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.emergency_outlined, color: Colors.deepOrangeAccent),
                            title: Text('Emergency Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('Quick access protocols', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _safeNavigate(context, '/emergency'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 1.0),
                    _buildGlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('SUPPORT'),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.help_outline, color: AppTheme.primaryTeal),
                            title: Text('Help Center', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('FAQ & live support', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryTeal),
                            title: Text('Privacy Policy', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('Your data & privacy', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.description_outlined, color: AppTheme.primaryTeal),
                            title: Text('Terms of Service', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                            subtitle: Text('Legal information', style: GoogleFonts.outfit(color: AppTheme.textLight)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 1.0),
                    _buildPremiumBanner(),
                    SizedBox(height: verticalSpacing * 1.0),
                    Center(child: _buildLogoutButton(context)),
                    SizedBox(height: verticalSpacing * 1.2),
                  ],
                ),
              ),
            ),
          ],
          
        ),
    );
  }

  void _safeNavigate(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushNamed(context, route).catchError((e) {
        debugPrint('Navigation error: $e');
      });
    }
  }

  Widget _buildPremiumProfileHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final avatarSize = screenWidth * 0.25;
    final iconSize = avatarSize * 0.5;
    final titleFontSize = screenWidth * 0.04;
    final subtitleFontSize = screenWidth * 0.03;
    
    // White rounded header card to match provided design
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildAvatarWithRing(avatarSize, iconSize),
              const SizedBox(height: 12),
              // Show name only when user has filled it (either saved or typed)
              if ((_nameController.text.isNotEmpty) || (_userName.isNotEmpty))
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _nameController.text.isNotEmpty ? _nameController.text : _userName,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 6),
              // Subtitle/bio: only render when we have content and user isn't fresh
              if ((!_isNewUser) && (_bioController.text.isNotEmpty || _userTitle.isNotEmpty))
                Text(
                  _bioController.text.isNotEmpty ? _bioController.text : _userTitle,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              // Completion chip + small stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 16, color: AppTheme.primaryTeal),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Profile completion',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(_profileCompletion * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryTeal)),
                        ],
                      ),
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

  Widget _buildAvatarWithRing(double avatarSize, double iconSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ringPadding = avatarSize * 0.04;
    final innerPadding = avatarSize * 0.03;
    final cameraIconSize = screenWidth * 0.035;
    
    return GestureDetector(
      onTap: _pickImageFromGallery,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(ringPadding),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.8),
                  AppTheme.primaryTeal.withValues(alpha: 0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(innerPadding),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: _buildProfileImage(avatarSize),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(cameraIconSize * 0.4),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: cameraIconSize,
              ),
            ),
          ),
          Positioned(
            right: screenWidth * 0.02,
            bottom: screenWidth * 0.02,
            child: Container(
              width: screenWidth * 0.045,
              height: screenWidth * 0.045,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildProfileImage(double size) {
  if (_selectedImage != null) {
    return Image.file(
      File(_selectedImage!.path),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  } 
  else if (_profileImageUrl.isNotEmpty) {
    try {
      final file = File(_profileImageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      }
    } catch (_) {}

    return Image.network(
      _profileImageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultAvatar(size);
      },
    );
  } 
  else {
    return _buildDefaultAvatar(size);
  }
}

  Widget _buildDefaultAvatar(double size) {
    // Minimal empty placeholder circle for new users (no inner icon)
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.12), width: 2),
      ),
    );
  }

  Widget _buildStatsRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPad = screenWidth * 0.03;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.035,
          horizontal: screenWidth * 0.01,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(child: _buildStatItem(_sessionCount.toString(), 'Sessions', Icons.spa_rounded)),
              _buildVerticalDivider(),
              Flexible(child: _buildStatItem(_stabilityScore, 'Stability', Icons.auto_awesome_rounded)),
              _buildVerticalDivider(),
              Flexible(child: _buildStatItem(_streakDays, 'Streak', Icons.local_fire_department_rounded)),
              _buildVerticalDivider(),
              Flexible(child: _buildStatItem(_totalMinutes.toString(), 'Min', Icons.timer_outlined)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: screenWidth * 0.005),
            Icon(icon, size: screenWidth * 0.035, color: Colors.white70),
          ],
        ),
        SizedBox(height: screenWidth * 0.01),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: screenWidth * 0.025,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildStartJourneyCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPad = screenWidth * 0.03;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: screenWidth * 0.09,
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              'Start Your Journey',
              style: GoogleFonts.outfit(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              'Begin your mindfulness practice today!',
              style: GoogleFonts.outfit(
                fontSize: screenWidth * 0.03,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Get Started',
                style: GoogleFonts.outfit(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final completionPercent = profileCompletionPercentage;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryTeal.withValues(alpha: 0.15),
            AppTheme.lightTeal.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: GoogleFonts.outfit(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                '$completionPercent%',
                style: GoogleFonts.outfit(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (profileCompletionPercentage / 100.0).clamp(0.0, 1.0),
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
              minHeight: 8,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            'Complete your profile to unlock premium features',
            style: GoogleFonts.outfit(
              fontSize: screenWidth * 0.03,
              color: AppTheme.textLight,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Define display order and metadata for achievements.
    // Define display order and metadata for achievements using _achievementData
    final items = [
      {'key': 'streak', 'label': 'Day Streak', 'icon': Icons.local_fire_department_rounded, 'color': Colors.orange},
      {'key': 'sessions', 'label': 'Sessions', 'icon': Icons.spa_rounded, 'color': AppTheme.primaryTeal},
      {'key': 'member', 'label': 'Member', 'icon': Icons.workspace_premium_rounded, 'color': Colors.amber},
      {'key': 'rating', 'label': 'Rating', 'icon': Icons.star_rounded, 'color': Colors.yellow[700]},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: screenWidth * 0.01,
            bottom: screenHeight * 0.02,
          ),
          child: Text(
            'ACHIEVEMENTS',
            style: GoogleFonts.outfit(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryTeal.withValues(alpha: 0.8),
              letterSpacing: 2.0,
            ),
          ),
        ),
        SizedBox(
          height: screenHeight * 0.15,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: screenWidth * 0.03),
            itemBuilder: (context, index) {
              final meta = items[index];
              final key = meta['key'] as String;
              String valueStr = '';

              switch (key) {
                case 'streak':
                  valueStr = (_achievementData['streak'] ?? 0).toString();
                  break;
                case 'sessions':
                  valueStr = (_achievementData['sessions'] ?? 0).toString();
                  break;
                case 'member':
                  valueStr = (_achievementData['isPro'] == true) ? 'Pro' : 'Free';
                  break;
                case 'rating':
                  valueStr = (_achievementData['rating'] ?? '').toString();
                  break;
                default:
                  valueStr = '';
              }

              return _buildAchievementBadge(
                valueStr,
                meta['label'] as String,
                meta['icon'] as IconData,
                (meta['color'] as Color?) ?? AppTheme.primaryTeal,
              );
            },
          ),
        ),
      ],
    );
  }

  // Update achievement data programmatically
  void updateUserStats(int newStreak, int newSessions, {bool? isPro, String? rating}) {
    setState(() {
      _achievementData['streak'] = newStreak;
      _achievementData['sessions'] = newSessions;
      if (isPro != null) _achievementData['isPro'] = isPro;
      if (rating != null) _achievementData['rating'] = rating;
    });
    // save updated stats
    _saveProfileData();
  }

  Widget _buildAchievementBadge(String value, String label, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final badgeWidth = screenWidth * 0.22;
    
    return Container(
      width: badgeWidth,
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: screenWidth * 0.07),
          SizedBox(height: screenHeight * 0.01),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: screenWidth * 0.022,
              color: AppTheme.textLight,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Update achievements programmatically and refresh UI.
  // Primary API: update streak and sessions. Optional extras can be provided.
  void updateAchievements(int newStreak, int newSessions, {String? newRating, String? newMember}) {
    setState(() {
      _achievementData['streak'] = newStreak;
      _achievementData['sessions'] = newSessions;
      if (newRating != null) _achievementData['rating'] = newRating;
      if (newMember != null) _achievementData['member'] = newMember;
    });
    _saveProfileData();
  }

  Widget _buildPremiumBanner() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: screenWidth * 0.07,
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to Premium',
                  style: GoogleFonts.outfit(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  'Unlock unlimited sessions & more',
                  style: GoogleFonts.outfit(
                    fontSize: screenWidth * 0.03,
                    color: Colors.white70,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.012,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Upgrade',
              style: GoogleFonts.outfit(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF667eea),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(
        bottom: screenWidth * 0.04,
        left: screenWidth * 0.01,
      ),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: screenWidth * 0.032,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryTeal.withValues(alpha: 0.8),
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.black.withValues(alpha: 0.05),
    );
  }

  Widget _buildModernTile(
    IconData icon, 
    String title, 
    String subtitle, {
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final finalIconColor = iconColor ?? AppTheme.primaryTeal;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.025,
          horizontal: screenWidth * 0.01,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: finalIconColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: finalIconColor, size: screenWidth * 0.05),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.005),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: screenWidth * 0.03,
                      color: AppTheme.textLight,
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              color: AppTheme.textLight.withValues(alpha: 0.5), 
              size: screenWidth * 0.035,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, {double size = 22}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  Widget _buildCollapsedAvatar(double size) {
    // Small avatar used in collapsed appbar title
    ImageProvider? provider;
    if (_selectedImage != null) {
      provider = FileImage(File(_selectedImage!.path));
    } else if (_profileImageUrl.isNotEmpty) {
      provider = NetworkImage(_profileImageUrl);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: provider == null ? Colors.white : AppTheme.primaryTeal.withValues(alpha: 0.15),
        image: provider != null ? DecorationImage(image: provider, fit: BoxFit.cover) : null,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
      ),
      // When provider == null leave the circle empty (no inner icon)
      child: provider == null ? const SizedBox.shrink() : null,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          color: Colors.red.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red[400], size: screenWidth * 0.045),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: screenWidth * 0.035,
                color: Colors.red[400],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(screenWidth * 0.06),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: screenWidth * 0.1,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            Text(
              'Settings',
              style: GoogleFonts.outfit(
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            _buildSettingsTile(Icons.dark_mode_outlined, 'Dark Mode', 'Coming soon'),
            _buildSettingsTile(Icons.language_outlined, 'Language', 'English'),
            _buildSettingsTile(Icons.timer_outlined, 'Session Duration', '15 min'),
            _buildSettingsTile(Icons.notifications_outlined, 'Push Notifications', 'Enabled'),
            SizedBox(height: screenWidth * 0.06),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryTeal, size: screenWidth * 0.055),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: screenWidth * 0.037,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: screenWidth * 0.035,
              color: AppTheme.textLight,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Icon(Icons.chevron_right, color: AppTheme.textLight, size: screenWidth * 0.05),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Prefill controllers with current stored values (may be empty for new users)
    _nameController.text = _nameController.text.isNotEmpty ? _nameController.text : _userName;
    _emailController.text = _emailController.text.isNotEmpty ? _emailController.text : '';
    _bioController.text = _bioController.text.isNotEmpty ? _bioController.text : _userTitle;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: screenWidth * 0.06,
          right: screenWidth * 0.06,
          top: screenWidth * 0.06,
          bottom: MediaQuery.of(context).viewInsets.bottom + screenWidth * 0.06,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: screenWidth * 0.1,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            Text(
              'Edit Profile',
              style: GoogleFonts.outfit(
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: _userName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'kinza@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            TextField(
              controller: _bioController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Mindfulness Explorer',
                prefixIcon: Icon(Icons.info_outline),
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveProfileChanges(context),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfileChanges(BuildContext context) async {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newBio = _bioController.text.trim();
    debugPrint('Saving profile: name=$newName, email=$newEmail, bio=$newBio');
    setState(() {
      // Apply values (allow empty strings) and mark initialized
      _userName = newName;
      _userTitle = newBio;
      _isNewUser = false;
    });

    // Recalculate profile completion after saving changes
    _recalculateProfileCompletion();

    // Persist changes locally
    await _saveProfileData();

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: AppTheme.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to Logout?',
          style: GoogleFonts.outfit(color: AppTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () => _handleLogout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.pop(context);
    AuthService().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }
}

