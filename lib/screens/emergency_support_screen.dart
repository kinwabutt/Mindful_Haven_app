import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telephony/telephony.dart'; 
import 'emergency_settings_screen.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rippleController;

  final Telephony telephony = Telephony.instance; 
  static const Color myPrimaryColor = Color(0xFF26C6DA);

  String savedContactName = "Loading...";
  String savedContactPhone = "";
  bool isAutoSMSEnabled = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchContactData();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  Future<void> _fetchContactData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('emergency_contact')) {
            setState(() {
              savedContactName =
                  data['emergency_contact']['name'] ?? "Personal Contact";
              savedContactPhone = data['emergency_contact']['phone'] ?? "";
              isAutoSMSEnabled = data['emergency_contact']['auto_sms'] ?? true;
            });
          }
        }
      }
    } catch (e) {
      setState(() => savedContactName = "Set Contact in Settings");
    }
  }

  // --- NEW: WHATSAPP LOGIC ---
  Future<void> _sendWhatsAppAlert(String message) async {
    if (savedContactPhone.isEmpty) return;

    // Formatting number for WhatsApp (removing 0 and adding 92)
    String formattedNumber = savedContactPhone;
    if (formattedNumber.startsWith('0')) {
      formattedNumber = '92${formattedNumber.substring(1)}';
    } else if (!formattedNumber.startsWith('92')) {
      formattedNumber = '92$formattedNumber';
    }

    final Uri whatsappUrl = Uri.parse(
      "whatsapp://send?phone=$formattedNumber&text=${Uri.encodeComponent(message)}"
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      debugPrint("WhatsApp not installed");
    }
  }

  Future<void> _sendEmergencyAlert() async {
    if (savedContactPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please set an emergency contact in Settings first!"),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isSending = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final String mapsUrl = 'http://maps.google.com/?q=${position.latitude},${position.longitude}';
      final String message = 'EMERGENCY! I am using Mindful Haven and I am in distress. My current location: $mapsUrl';

      // 1. Send SMS Automatically (Direct)
      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

      if (permissionsGranted != null && permissionsGranted) {
        await telephony.sendSms(
          to: savedContactPhone,
          message: message,
          statusListener: (SendStatus status) {
            if (status == SendStatus.SENT) {
              debugPrint("SMS Sent Successfully");
            }
          },
        );
        
        // 2. Open WhatsApp for secondary alert
        await _sendWhatsAppAlert(message);

      } else {
        throw 'SMS Permission Denied';
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _makeCall(String number) async {
    if (number.isEmpty) return;
    final Uri url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(isDarkMode),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSafetyHubCard(isDarkMode),
                    const SizedBox(height: 30),
                    Text(
                      'HELP & SUPPORT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNeumorphicCrisisLink(
                      title: savedContactName,
                      subtitle: savedContactPhone.isEmpty
                          ? 'Tap settings to add'
                          : 'Tap to call $savedContactPhone',
                      iconData: Icons.person_pin_rounded,
                      color: myPrimaryColor,
                      onTap: () => _makeCall(savedContactPhone),
                      titleSize: 14,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildNeumorphicCrisisLink(
                      title: ' Prevention Help',
                      subtitle: 'Tap to call 15(Police)',
                      iconData: Icons.health_and_safety_rounded,
                      color: Colors.redAccent,
                      onTap: () => _makeCall('15'),
                      titleSize: 14,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 30),
                    _buildFooterDisclaimer(isDarkMode),
                  ],
                ),
              ),
            ),
            _buildEmergencyButtonArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          _buildGlassCircle(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Emergency Support',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildGlassCircle(
            icon: Icons.settings_outlined,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencySettingsScreen(),
                ),
              );
              _fetchContactData();
            },
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicCrisisLink({
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color color,
    required VoidCallback onTap,
    required double titleSize,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(iconData, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleSize,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.call_rounded, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButtonArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) => CustomPaint(
              painter: RipplePainter(_rippleController.value),
              child: const SizedBox(width: 250, height: 120),
            ),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: _isSending ? null : _sendEmergencyAlert,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.emergency_share_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                    const SizedBox(width: 12),
                    Text(
                      _isSending ? 'SENDING...' : 'SEND ALERT',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircle({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          shape: BoxShape.circle,
          boxShadow: isDarkMode
              ? null
              : [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildSafetyHubCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
      ),
      child: Column(
        children: [
          const Icon(Icons.security_rounded, color: Colors.redAccent, size: 45),
          const SizedBox(height: 16),
          Text(
            'Quick Safety Hub',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'In case of danger, alert your circle immediately.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterDisclaimer(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          'Mindful Haven is an AI tool and not a replacement for professional emergency services.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: isDarkMode ? Colors.white60 : Colors.black45,
          ),
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
    for (int i = 3; i >= 1; i--) {
      final double opacity = (1 - ((progress + (i / 3)) % 1)).clamp(0, 1);
      final double radius = (size.width / 2) * ((progress + (i / 3)) % 1);
      final Paint paint = Paint()
        ..color = Colors.redAccent.withOpacity(opacity * 0.15);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}