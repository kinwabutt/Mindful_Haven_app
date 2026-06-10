import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; 
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
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Record?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to remove this session from your history?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
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
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return "${totalSeconds}s";
    int mins = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;
    return secs == 0 ? "${mins}m" : "${mins}m ${secs}s";
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
        automaticallyImplyLeading: false, 
        title: Text(
          'History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
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

          // --- LOGIC: Grouping by Date ---
          Map<String, List<QueryDocumentSnapshot>> groupedDocs = {};
          for (var doc in snapshot.data!.docs) {
            DateTime date = (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            String dateKey = DateFormat('yyyy-MM-dd').format(date);
            if (groupedDocs[dateKey] == null) groupedDocs[dateKey] = [];
            groupedDocs[dateKey]!.add(doc);
          }

          var sortedDateKeys = groupedDocs.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: sortedDateKeys.length,
            itemBuilder: (context, index) {
              String dateKey = sortedDateKeys[index];
              List<QueryDocumentSnapshot> sessions = groupedDocs[dateKey]!;

              // Header Logic (Today, Yesterday, Date)
              DateTime now = DateTime.now();
              String today = DateFormat('yyyy-MM-dd').format(now);
              String yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

              String headerLabel;
              if (dateKey == today) {
                headerLabel = "Today";
              } else if (dateKey == yesterday) {
                headerLabel = "Yesterday";
              } else {
                headerLabel = DateFormat('dd MMM, yyyy').format(DateTime.parse(dateKey));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 12, left: 8),
                    child: Text(
                      headerLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, color: brandTeal, fontSize: 14),
                    ),
                  ),
                  ...sessions.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    DateTime sessionTime = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                                ),
                                Text(
                                  DateFormat('hh:mm a').format(sessionTime),
                                  style: TextStyle(fontSize: 12, color: subTextColor),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDuration(data['duration'] ?? 0),
                                style: TextStyle(fontWeight: FontWeight.bold, color: brandTeal, fontSize: 14),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22),
                                onPressed: () => _deleteHistoryItem(doc.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor, bool isDark) {
    return Center(
      // SingleChildScrollView lagane se landscape mein vertical overflow khatam ho jaye ga
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Vertical padding bhi de di
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
                        color: brandTeal.withOpacity(isDark ? 0.05 : 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Positioned(top: 40, left: 50, child: Icon(Icons.eco_rounded, color: brandTeal.withOpacity(0.2), size: 35)),
                    Positioned(top: 60, right: 40, child: Icon(Icons.favorite_rounded, color: brandTeal.withOpacity(0.2), size: 40)),
                    Positioned(bottom: 50, left: 60, child: Icon(Icons.local_florist_rounded, color: brandTeal.withOpacity(0.2), size: 35)),
                    Positioned(
                      top: 30,
                      right: 30,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white, 
                          shape: BoxShape.circle, 
                          boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black12, blurRadius: 10)]
                        ),
                        child: Icon(Icons.chat_bubble_rounded, color: brandTeal, size: 24),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white, 
                          shape: BoxShape.circle, 
                          boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black12, blurRadius: 10)]
                        ),
                        child: Icon(Icons.psychology_rounded, color: brandTeal, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text("No sessions recorded", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text("Complete a breathing exercise to see your history here.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: subTextColor)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingScreen())),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text("Start Session", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  }