
  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../theme/app_theme.dart';
  import 'package:flutter/services.dart';
  import 'dart:async';
  import 'package:shared_preferences/shared_preferences.dart';

  class BreathingScreen extends StatefulWidget {
    const BreathingScreen({super.key});

    @override
    State<BreathingScreen> createState() => _BreathingScreenState();
  }

  enum BoxBreathingPhase { inhale, holdAfterInhale, exhale, holdAfterExhale }

  class _BreathingScreenState extends State<BreathingScreen> with TickerProviderStateMixin {
    late AnimationController _controller;
    late AnimationController _holdController;
    late Animation<double> _pulseAnimation;
    late Animation<double> _glowAnimation;
    late Animation<double> _progressAnimation;
    late Animation<double> _holdPulse;
    late Animation<double> _holdGlow;
  
    BoxBreathingPhase _phase = BoxBreathingPhase.inhale;
    int _secondsRemaining = 300;
    late final int _sessionInitial;
    Timer? _sessionTimer;
    Timer? _phaseTimer;

    @override
    void initState() {
      super.initState();
      _sessionInitial = _secondsRemaining;

      _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
      _holdController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

      _progressAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(_progressAnimation);
      _glowAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(_progressAnimation);
    
      _holdPulse = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _holdController, curve: Curves.easeInOut));
      _holdGlow = Tween<double>(begin: 0.02, end: 0.08).animate(CurvedAnimation(parent: _holdController, curve: Curves.easeInOut));

      _controller.addStatusListener(_handleStatus);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.forward();
        _startTimer();
      });
    }

    void _startTimer() {
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          timer.cancel();
          _saveAndExit();
        }
      });
    }

    Future<void> _saveAndExit() async {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getInt('breathing_total_seconds') ?? 0;
      await prefs.setInt('breathing_total_seconds', existing + _sessionInitial);
      if (mounted) Navigator.pop(context);
    }

    void _handleStatus(AnimationStatus status) {
      if (!mounted) return;
      if (status == AnimationStatus.completed) {
        setState(() => _phase = BoxBreathingPhase.holdAfterInhale);
        HapticFeedback.lightImpact();
        _runHoldPhase(() {
          if (!mounted) return;
          setState(() => _phase = BoxBreathingPhase.exhale);
          _controller.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _phase = BoxBreathingPhase.holdAfterExhale);
        HapticFeedback.lightImpact();
        _runHoldPhase(() {
          if (!mounted) return;
          setState(() => _phase = BoxBreathingPhase.inhale);
          _controller.forward();
        });
      }
    }

    void _runHoldPhase(VoidCallback onComplete) {
      _holdController.repeat(reverse: true);
      _phaseTimer?.cancel();
      _phaseTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        _holdController.stop();
        _holdController.reset();
        onComplete();
      });
    }

    @override
    void dispose() {
      _sessionTimer?.cancel();
      _phaseTimer?.cancel();
      _controller.dispose();
      _holdController.dispose();
      super.dispose();
    }

    String _formatTime(int seconds) {
      int mins = seconds ~/ 60;
      int secs = seconds % 60;
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }

    String _getInstruction() {
      switch (_phase) {
        case BoxBreathingPhase.inhale:
          return 'Inhale';
        case BoxBreathingPhase.holdAfterInhale:
          return 'Hold';
        case BoxBreathingPhase.exhale:
          return 'Exhale';
        case BoxBreathingPhase.holdAfterExhale:
          return 'Hold';
      }
    }

    String _getGuidance() {
      switch (_phase) {
        case BoxBreathingPhase.inhale:
          return 'Slowly fill your lungs with peaceful energy';
        case BoxBreathingPhase.holdAfterInhale:
          return 'Hold gently and feel the stillness';
        case BoxBreathingPhase.exhale:
          return 'Release all tension and let go of stress';
        case BoxBreathingPhase.holdAfterExhale:
          return 'Hold briefly and notice the calm';
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient Oscillating Glow
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryTeal.withValues(alpha: _glowAnimation.value),
                            AppTheme.primaryTeal.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              Column(
                children: [
                  // Professional Header (Matching Chat Screen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                    child: Row(
                      children: [
                         Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mindful Haven',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16, 
                                  color: AppTheme.textDark
                                ),
                              ),
                              Text(
                                'BREATHING GUIDE',
                                style: GoogleFonts.outfit(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w800, 
                                  color: AppTheme.textLight, 
                                  letterSpacing: 0.5
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 24, color: AppTheme.textLight),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Main Breathing Guide
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Pulsating Ring (uses base breathing pulse, plus a subtle hold micro-pulse)
                              AnimatedBuilder(
                                animation: Listenable.merge([_controller, _holdController]),
                                builder: (context, child) {
                                  final pulseVal = _pulseAnimation.value;
                                  final holdFactor = (_phase == BoxBreathingPhase.holdAfterInhale || _phase == BoxBreathingPhase.holdAfterExhale)
                                      ? _holdPulse.value
                                      : 1.0;
                                  final base = 240 * pulseVal;
                                  final alphaAdd = (_phase == BoxBreathingPhase.holdAfterInhale || _phase == BoxBreathingPhase.holdAfterExhale)
                                      ? _holdGlow.value
                                      : 0.0;
                                  return Container(
                                    width: base * holdFactor,
                                    height: base * holdFactor,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryTeal.withValues(alpha: 0.08 + alphaAdd),
                                        width: 1.5,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Second Layer Pulse (also respects hold micro-pulse)
                              AnimatedBuilder(
                                animation: Listenable.merge([_controller, _holdController]),
                                builder: (context, child) {
                                  final pulseVal = _pulseAnimation.value;
                                  final base = 180 * (0.9 + 0.1 * pulseVal);
                                  final holdFactor = (_phase == BoxBreathingPhase.holdAfterInhale || _phase == BoxBreathingPhase.holdAfterExhale)
                                      ? _holdPulse.value
                                      : 1.0;
                                  final glowAlpha = _glowAnimation.value + ((_phase == BoxBreathingPhase.holdAfterInhale || _phase == BoxBreathingPhase.holdAfterExhale) ? _holdGlow.value : 0);
                                  return Container(
                                    width: base * holdFactor,
                                    height: base * holdFactor,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryTeal.withValues(alpha: 0.04 + (glowAlpha * 0.12)),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                              // Inner Interactive Circle
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.spa_rounded, color: AppTheme.primaryTeal.withValues(alpha: 0.3), size: 32),
                                      const SizedBox(height: 8),
                                            Text(
                                              _getInstruction().toUpperCase(),
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.5,
                                                color: AppTheme.primaryTeal,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                              // Circular Progress Border (driven by eased progress)
                              SizedBox(
                                width: 180,
                                height: 180,
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([_controller, _holdController]),
                                  builder: (context, child) {
                                    return CircularProgressIndicator(
                                      value: _progressAnimation.value,
                                      strokeWidth: 3,
                                      strokeCap: StrokeCap.round,
                                      backgroundColor: Colors.transparent,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Dynamic Instruction (phase-aware)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              _getGuidance(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: AppTheme.textLight,
                                fontSize: 12,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        
                          const SizedBox(height: 20),

                          // Session Timer Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_rounded, size: 20, color: AppTheme.primaryTeal),
                                const SizedBox(width: 12),
                                Text(
                                  _formatTime(_secondsRemaining),
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
