import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mindful_haven/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class BreathingScreen extends StatefulWidget {
  final int sessionSeconds;
  const BreathingScreen({super.key, this.sessionSeconds = 300});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

enum BoxBreathingPhase { inhale, holdAfterInhale, exhale, holdAfterExhale }

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _holdController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  BoxBreathingPhase _phase = BoxBreathingPhase.inhale;
  late int _secondsRemaining;
  int _secondsPracticed = 0;
  Timer? _sessionTimer;
  Timer? _phaseTimer;
  bool _isPaused = true;
  bool _timeSelected = false;

  static const Color myPrimaryColor = Color(0xFF26C6DA);

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.sessionSeconds;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(
      begin: 0.1,
      end: 0.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener(_handleStatus);
  }

  void _startSession(int seconds) {
    setState(() {
      _secondsRemaining = seconds;
      _secondsPracticed = 0; 
      _timeSelected = true;
      _isPaused = true; 
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _stopAnimations();
      } else {
        _startTimer();
        if (_phase == BoxBreathingPhase.inhale) {
          _controller.forward();
        } else if (_phase == BoxBreathingPhase.exhale) {
          _controller.reverse();
        } else {
          _runHoldPhase(_continueToNextPhase);
        }
      }
    });
  }

  void _stopAnimations() {
    _controller.stop();
    _holdController.stop();
    _sessionTimer?.cancel();
    _phaseTimer?.cancel();
  }

  void _handleStatus(AnimationStatus status) {
    if (!mounted || _isPaused) return;
    if (status == AnimationStatus.completed) {
      setState(() => _phase = BoxBreathingPhase.holdAfterInhale);
      _runHoldPhase(_continueToNextPhase);
    } else if (status == AnimationStatus.dismissed) {
      setState(() => _phase = BoxBreathingPhase.holdAfterExhale);
      _runHoldPhase(_continueToNextPhase);
    }
  }

  void _runHoldPhase(VoidCallback onComplete) {
    _holdController.repeat(reverse: true);
    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _isPaused) return;
      _holdController.stop();
      onComplete();
    });
  }

  void _continueToNextPhase() {
    if (_phase == BoxBreathingPhase.holdAfterInhale) {
      setState(() => _phase = BoxBreathingPhase.exhale);
      _controller.reverse();
    } else {
      setState(() => _phase = BoxBreathingPhase.inhale);
      _controller.forward();
    }
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _secondsPracticed++;
        } else {
          timer.cancel();
          _stopAnimations();
          _showSummary();
        }
      });
    });
  }

  Future<void> _showSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('breathing_history')
            .add({
              'duration': _secondsPracticed,
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'Box Breathing',
            });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'total_breathing_seconds': FieldValue.increment(
                _secondsPracticed,
              ),
              'sessions_count': FieldValue.increment(1),
            });
      } catch (e) {
        debugPrint("Error saving session: $e");
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Session Complete",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Great job! You practiced for ${_secondsPracticed ~/ 60}m ${(_secondsPracticed % 60)}s.",
          style: const TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              setState(() {
                _timeSelected = false; 
              });
            },
            child: const Text(
              "FINISH",
              style: TextStyle(
                color: myPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _phaseTimer?.cancel();
    _controller.dispose();
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final bgColor = isDark ? Colors.black : const Color(0xFFF8FBFF);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(isDark, textColor),
              if (!_timeSelected)
                _buildTimeSelection(isDark, textColor)
              else
                _buildBreathingUI(isDark, textColor),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED HEADER: Logo removed, Cross removed, Back icon added with logic
  Widget _buildHeader(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
  icon: const Icon(Icons.arrow_back_ios_new),
  onPressed: () {
    // Ye line check karegi ke agar peeche kuch hai toh pop kare, 
    // warna seedha Chat Screen par le jaye.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()), 
      (route) => false, // Is se purani sari screens (Splash etc.) khatam ho jayengi
    );
  },
),
          const SizedBox(width: 8),
         const Text(
          "Breathe and Relax",
           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          // Spacer will push everything to the left and leave the right side empty
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTimeSelection(bool isDark, Color textColor) {
    return Column(
      children: [
        const SizedBox(height: 45),
        Text(
          "How long to practice?",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),
        _timeButton("1 Minute", 60, isDark),
        _timeButton("2 Minutes", 120, isDark),
        _timeButton("3 Minutes", 180, isDark),
        _timeButton("4 Minutes", 240, isDark),
        _timeButton("5 Minutes", 300, isDark),
      ],
    );
  }

  Widget _timeButton(String label, int seconds, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          foregroundColor: myPrimaryColor,
          side: BorderSide(color: myPrimaryColor.withOpacity(0.5)),
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: isDark ? 0 : 2,
        ),
        onPressed: () => _startSession(seconds),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildBreathingUI(bool isDark, Color textColor) {
    return Column(
      children: [
        const SizedBox(height: 40),
        GestureDetector(
          onTap: _togglePause,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Container(
                    width: 220 * _pulseAnimation.value,
                    height: 220 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: myPrimaryColor.withOpacity(
                            _glowAnimation.value,
                          ),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                      border: Border.all(
                        color: myPrimaryColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.air_rounded,
                        color: myPrimaryColor,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPaused ? "Start" : _getPhaseText(),
                        style: TextStyle(
                          color: myPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 80),
        Text(
          '${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: myPrimaryColor,
          ),
        ),
      ],
    );
  }

  String _getPhaseText() {
    switch (_phase) {
      case BoxBreathingPhase.inhale:
        return "INHALE";
      case BoxBreathingPhase.exhale:
        return "EXHALE";
      default:
        return "HOLD";
    }
  }
}