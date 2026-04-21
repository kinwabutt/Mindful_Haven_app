import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; 
// Make sure this import matches your breathing screen file path
import 'breathing_screen.dart'; 

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Color brandTeal = const Color(0xFF26C6DA);
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _deleteHistoryItem(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('breathing_history')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting record: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final themeProvider = context.watch<ThemeProvider>();
    final bool isDark = themeProvider.isDarkMode;

    final Color bgColor = isDark ? Colors.black : const Color(0xFFF8FAFC);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color cardColor = isDark ? const Color(0xFF121212) : Colors.white;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Back button remove kar diya
        title: Text(
          'History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('breathing_history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: brandTeal));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(textColor, subTextColor, isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: brandTeal.withOpacity(0.1),
                      child: Icon(Icons.air_rounded, color: brandTeal),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Box Breathing',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM, hh:mm a').format(date),
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(data['duration'] ?? 0) ~/ 60}m',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: brandTeal,
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _deleteHistoryItem(doc.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: brandTeal.withOpacity(isDark ? 0.1 : 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Positioned(top: 40, left: 50, child: Icon(Icons.eco_rounded, color: brandTeal.withOpacity(0.3), size: 35)),
                  Positioned(top: 60, right: 40, child: Icon(Icons.favorite_rounded, color: brandTeal.withOpacity(0.3), size: 40)),
                  // Error wala icon local_florist se replace kar diya jo professional lag raha hai
                  Positioned(bottom: 50, left: 60, child: Icon(Icons.local_florist_rounded, color: brandTeal.withOpacity(0.3), size: 35)),
                  Positioned(bottom: 60, right: 50, child: Icon(Icons.cloud_rounded, color: brandTeal.withOpacity(0.3), size: 30)),
                  
                  Positioned(
                    top: 30,
                    right: 30,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: Icon(Icons.chat_bubble_rounded, color: brandTeal, size: 24),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                      child: Icon(Icons.psychology_rounded, color: brandTeal, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            Text(
              "No sessions yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start your first breathing session",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BreathingScreen()),
                  );
                },
                icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
                label: const Text(
                  "Start Session",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}