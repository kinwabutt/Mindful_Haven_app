import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencySettingsScreen extends StatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  State<EmergencySettingsScreen> createState() =>
      _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends State<EmergencySettingsScreen> {
  bool _autoSMS = true;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  static const Color myPrimaryColor = Color(0xFF26C6DA);
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSMS = prefs.getBool('auto_sms') ?? true;
      _nameController.text = prefs.getString('emergency_name') ?? '';
      _phoneController.text = prefs.getString('emergency_phone') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String uid = _auth.currentUser?.uid ?? 'unknown_user';

      await _firestore.collection('users').doc(uid).set({
        'emergency_contact': {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'auto_sms': _autoSMS,
          'is_monitoring_active': true,
          'last_updated': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_sms', _autoSMS);
      await prefs.setString('emergency_name', _nameController.text.trim());
      await prefs.setString('emergency_phone', _phoneController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings synced with Cloud Successfully'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving to database: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect if dark mode is active from the Theme
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
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
                      'Emergency Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALERT PREFERENCES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassSettingsCard(
                      isDarkMode: isDarkMode,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automatic SMS Alerts',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Sends location and status to contacts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _autoSMS,
                            activeColor: myPrimaryColor,
                            onChanged: (val) => setState(() => _autoSMS = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'EMERGENCY CONTACT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGlassTextField(
                      'Contact Name',
                      _nameController,
                      Icons.person_outline_rounded,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 20),
                    _buildGlassTextField(
                      'Phone Number',
                      _phoneController,
                      Icons.phone_android_rounded,
                      isPhone: true,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 30),
                    _buildInfoCard(isDarkMode),
                  ],
                ),
              ),
            ),

            // Save Button Section
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: GestureDetector(
                onTap: _isLoading ? null : _saveSettings,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: myPrimaryColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: myPrimaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Settings',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return _buildGlassSettingsCard(
      isDarkMode: isDarkMode,
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: myPrimaryColor,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Mindful Haven will analyze your chats to detect extreme stress and can notify this contact.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white : Colors.black,
                fontStyle: FontStyle.italic,
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          shape: BoxShape.circle,
          boxShadow: isDarkMode
              ? null
              : [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildGlassSettingsCard({
    required Widget child,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }

  Widget _buildGlassTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPhone = false,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isDarkMode
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.name,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: myPrimaryColor, size: 20),
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}
