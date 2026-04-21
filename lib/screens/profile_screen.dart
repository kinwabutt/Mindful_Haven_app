import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'theme_provider.dart';
// Nayi screens ke imports
import 'emergency_support_screen.dart'; 
import 'emergency_settings_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _imagePath = prefs.getString('img_${_user?.uid}'));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('img_${_user?.uid}', pickedFile.path);
      setState(() => _imagePath = pickedFile.path);
    }
  }

  // --- DELETE ACCOUNT LOGIC START ---
  Future<void> _deleteUserAccount() async {
    if (_user == null) return;

    try {
      String uid = _user!.uid;

      // 1. Delete Chat History
      var chatDocs = await _firestore.collection('chats').doc(uid).collection('history').get();
      for (var doc in chatDocs.docs) {
        var messages = await doc.reference.collection('messages').get();
        for (var msg in messages.docs) {
          await msg.reference.delete();
        }
        await doc.reference.delete();
      }
      await _firestore.collection('chats').doc(uid).delete();

      // 2. Delete User Profile Document
      await _firestore.collection('users').doc(uid).delete();

      // 3. Delete Auth Account
      await _user!.delete();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account and data deleted permanently.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Security check: Please re-login before deleting account.")),
        );
      }
    }
  }

  void _confirmDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Account?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text("This will permanently erase your encrypted chat history and profile. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUserAccount();
            },
            child: const Text("Delete Everything", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  // --- DELETE ACCOUNT LOGIC END ---

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    const Color primaryTeal = Color(0xFF26C6DA);

    final bgColor = isDark ? Colors.black : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () {
            // Logic updated to navigate to chat screen
            Navigator.pushReplacementNamed(context, '/chat');
          },
        ),
        title: Text(
          "Profile Settings",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _user == null
          ? const Center(child: Text("User not found"))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryTeal),
                  );
                }

                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                String name = data['name'] ?? 'User Name';
                String bio = data['bio'] ?? 'Mindful Haven User';
                String level = data['semester'] ?? '';
                String institute = data['institute'] ?? '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: primaryTeal.withOpacity(0.2),
                            backgroundImage: _imagePath != null
                                ? FileImage(File(_imagePath!))
                                : null,
                            child: _imagePath == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: primaryTeal,
                                  )
                                : null,
                          ),
                          GestureDetector(
                            onTap: _pickImage,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: primaryTeal,
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        bio,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (level.isNotEmpty || institute.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (level.isNotEmpty)
                                _infoRow(
                                  Icons.school_outlined,
                                  "Grade / Level",
                                  level,
                                  isDark,
                                ),
                              if (level.isNotEmpty && institute.isNotEmpty)
                                const Divider(height: 30),
                              if (institute.isNotEmpty)
                                _infoRow(
                                  Icons.account_balance_outlined,
                                  "Institute",
                                  institute,
                                  isDark,
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 25),
                      _menuItem(
                        Icons.edit_note_rounded,
                        "Edit Profile",
                        () => _showEditSheet(data, isDark),
                        isDark,
                      ),
                      _menuItem(
                        Icons.settings_suggest_rounded,
                        "App Settings",
                        _showSettingsDialog,
                        isDark,
                      ),
                      
                      _menuItem(
                        Icons.shield_moon_outlined,
                        "Emergency Support",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EmergencySupportScreen()),
                        ),
                        isDark,
                      ),

                      _menuItem(
                        Icons.emergency_share_outlined,
                        "Emergency Settings",
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EmergencySettingsScreen()),
                        ),
                        isDark,
                      ),

                      const SizedBox(height: 40),

                      // DELETE ACCOUNT BUTTON
                      TextButton.icon(
                        onPressed: _confirmDeletion,
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                        label: const Text(
                          "Delete Account & Data",
                          style: TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // LOGOUT BUTTON
                      TextButton.icon(
                        onPressed: () async {
                          await AuthService().logout();
                          if (mounted)
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) =>
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF26C6DA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF26C6DA)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    bool isDark,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF26C6DA)),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDark ? Colors.white38 : Colors.grey,
          ),
        ],
      ),
    ),
  );

  void _showEditSheet(Map<String, dynamic> data, bool isDark) {
    final nameC = TextEditingController(text: data['name']);
    final bioC = TextEditingController(text: data['bio']);
    final semC = TextEditingController(text: data['semester']);
    final instC = TextEditingController(text: data['institute']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            _textField(nameC, "Name", isDark, Icons.person_outline),
            _textField(bioC, "Bio", isDark, Icons.info_outline),
            _textField(semC, "Grade / Semester", isDark, Icons.school_outlined),
            _textField(
              instC,
              "Institute",
              isDark,
              Icons.account_balance_outlined,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26C6DA),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                if (_user != null) {
                  await _firestore.collection('users').doc(_user!.uid).set({
                    'name': nameC.text.trim(),
                    'bio': bioC.text.trim(),
                    'semester': semC.text.trim(),
                    'institute': instC.text.trim(),
                  }, SetOptions(merge: true));
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "Save Changes",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    bool isDark,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF26C6DA), size: 20),
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF26C6DA)),
        ),
      ),
    ),
  );

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final themeProvider = context.watch<ThemeProvider>();
          final currentIsDark = themeProvider.isDarkMode;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: currentIsDark ? Colors.grey[900] : Colors.white,
            title: Text(
              "App Settings",
              style: TextStyle(
                color: currentIsDark ? Colors.white : Colors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(
                    "Dark Mode",
                    style: TextStyle(
                      color: currentIsDark ? Colors.white : Colors.black,
                    ),
                  ),
                  value: currentIsDark,
                  activeColor: const Color(0xFF26C6DA),
                  onChanged: (val) async {
                    themeProvider.toggleTheme(val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isDarkMode', val);
                    setDialogState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}