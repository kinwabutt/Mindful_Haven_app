import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import 'emergency_settings_screen.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rippleController;
  late AnimationController _callingController;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the button itself
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Radiating ripple animation for the background
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Small calling icon animation
    _callingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _callingController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final Uri url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  Future<void> _sendEmergencyAlert() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      final prefs = await SharedPreferences.getInstance();
      final contactPhone = prefs.getString('emergency_phone') ?? '+12345678901';
      final autoSMS = prefs.getBool('auto_sms') ?? true;

      if (autoSMS) {
        final String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
        final String message = 'HELP! I am in an emergency. My current location: $mapsUrl';
        final Uri smsUrl = Uri.parse('sms:$contactPhone?body=${Uri.encodeComponent(message)}');

        if (await canLaunchUrl(smsUrl)) {
          await launchUrl(smsUrl);
        } else {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not prepare SMS')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location fetched, but SMS alerts are disabled in settings')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2F1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Premium Glass Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                child: Row(
                  children: [
                    _buildGlassCircle(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Emergency Support',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    _buildGlassCircle(
                      icon: Icons.settings_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmergencySettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Premium Safety Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE0F2F1).withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.4),
                                    Colors.white.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.redAccent.withValues(alpha: 0.15),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.security_rounded, 
                                      color: Colors.redAccent, 
                                      size: 40
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Quick Safety Hub',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your location and emergency contacts are synced.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textLight.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Call 911 Banner Refined
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50]?.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Immediate danger? Call 911',
                                          style: GoogleFonts.outfit(
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.w600,
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
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      Text(
                        'DIRECT HELP LINKS',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textLight,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildNeumorphicCrisisLink(
                        title: 'National Suicide Prevention',
                        subtitle: 'Tap to call 988 for immediate help',
                        iconData: Icons.phone_in_talk_rounded,
                        color: Colors.blueAccent,
                        onTap: () => _makeCall('988'),
                        showCallingAnim: true,
                      ),
                      const SizedBox(height: 20),
                      _buildNeumorphicCrisisLink(
                        title: 'Crisis Text Line',
                        subtitle: 'Text HOME to 741741',
                        iconData: Icons.chat_bubble_rounded,
                        color: AppTheme.primaryTeal,
                        onTap: () => _makeCall('741741'),
                      ),

                      const SizedBox(height: 20),
                      
                      Center(
                        child: Text(
                          'Your safety is our priority.\nStay on the line if you call.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppTheme.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50),

                      // Safety Disclaimer Footer
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Mindful Haven is an AI support tool and not a replacement for professional emergency services.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textLight.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Radiating Emergency Alert Button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Radiating Ripples
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: RipplePainter(_rippleController.value),
                          child: const SizedBox(width: 250, height: 100),
                        );
                      }
                    ),
                    
                    // Floating Pill Button
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: GestureDetector(
                        onTap: _sendEmergencyAlert,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'SEND ALERT',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildGlassCircle({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppTheme.textDark),
      ),
    );
  }

  Widget _buildNeumorphicCrisisLink({
    required String title, 
    required String subtitle, 
    required IconData iconData, 
    required Color color,
    required VoidCallback onTap,
    bool showCallingAnim = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9F9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              blurRadius: 15,
              offset: const Offset(-8, -8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(8, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10),
                    ],
                  ),
                  child: Icon(iconData, color: color, size: 22),
                ),
                if (showCallingAnim)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: FadeTransition(
                      opacity: _callingController,
                      child: Icon(Icons.settings_input_antenna_rounded, color: color, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: AppTheme.textDark,
                    highlightColor: color.withValues(alpha: 0.3),
                    period: const Duration(seconds: 3),
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textLight.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double progress;
  RipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.redAccent.withValues(alpha: (1 - progress) * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final double maxRadius = size.width / 1.5;
    final double radius = maxRadius * progress;
    
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
    
    // Draw secondary ripple
    final double secondProgress = (progress + 0.5) % 1.0;
    final Paint secondPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: (1 - secondProgress) * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), maxRadius * secondProgress, secondPaint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}
