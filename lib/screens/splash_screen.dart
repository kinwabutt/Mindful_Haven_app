import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'dart:ui';
import 'dart:math' as math; // Import math for animation

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _blobController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Slow moving
    )..repeat(); // Loop indefinitely

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutExpo),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    // Wait for the animation to finish + a small pause for premium feel
    await Future.delayed(const Duration(milliseconds: 3200));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Lava Lamp Background Blobs
          Positioned.fill(
             child: AnimatedBuilder(
              animation: _blobController,
              builder: (context, child) {
                final height = MediaQuery.of(context).size.height;
                final width = MediaQuery.of(context).size.width;

                 // Calculate dynamic positions using sine/cosine for smooth crossing
                final tealY = height * 0.5 + math.sin(_blobController.value * 2 * math.pi) * height * 0.3;
                final tealX = width * 0.5 + math.cos(_blobController.value * 2 * math.pi) * width * 0.3;

                // Blue blob moves in the opposite direction
                final blueY = height * 0.5 + math.sin((_blobController.value + 0.5) * 2 * math.pi) * height * 0.3;
                final blueX = width * 0.5 + math.cos((_blobController.value + 0.5) * 2 * math.pi) * width * 0.3;

                // Pulsing sizes
                final tealSize = 350 + math.sin(_blobController.value * 4 * math.pi) * 50;
                final blueSize = 350 + math.cos(_blobController.value * 4 * math.pi) * 50;

                return Stack(
                    children: [
                      // Teal Blob
                      Positioned(
                        left: tealX - tealSize / 2,
                        top: tealY - tealSize / 2,
                        child: Container(
                          width: tealSize,
                          height: tealSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      // Blue Blob
                      Positioned(
                        left: blueX - blueSize / 2,
                        top: blueY - blueSize / 2,
                        child: Container(
                          width: blueSize,
                          height: blueSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      // Universal Blur (Deep Glassmorphism)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), // High blur for lava lamp effect
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ],
                );
              },
            ),
          ),
          
          // Foreground Content (Logo and Text)
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Logo
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                            blurRadius: 40,
                            spreadRadius: 1,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                        child: const Icon(
                          Icons.spa_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Minimized Professional Typography
                    Text(
                      'Mindful Haven',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5, // The editorial spacing you want
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Finding peace in the present',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.2, // Keeps consistency
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ultra-thin loading indicator at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'INITIALIZING CLARITY',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textLight.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 110),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: const Color(0xFFF8F8F8),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                              minHeight: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
