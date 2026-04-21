import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'theme_provider.dart';
import 'breathing_screen.dart'; 
import 'chat_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class EncryptionHelper {
  static final key = encrypt.Key.fromUtf8('my_super_secret_key_123456789012'); 
  static final iv = encrypt.IV.fromLength(16);
  static final encrypter = encrypt.Encrypter(encrypt.AES(key));

  static String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    try { return encrypter.decrypt64(encryptedText, iv: iv); } catch (e) { return encryptedText; }
  }
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedTab = 'Daily';
  final DateTime _selectedDate = DateTime.now();
  bool _isUpdating = false;

  static const Color myPrimaryColor = Color(0xFF26C6DA);
  // Purani line ko delete karke ye likhein
final String predictUrl = dotenv.env['BERT_PREDICT_URL'] ?? "";

  final Map<String, List<String>> moodTips = {
    'joy': ["Your positive energy is amazing! Channel it into something creative.", "Happiness grows by sharing. Spread your joy today.", "Keep this beautiful smile! You're doing great."],
    'sadness': ["It's okay to feel low. Taking a break is a form of strength.", "Every cloud has a silver lining. Stay hopeful.", "You are not alone. Small steps lead to big changes."],
    'stress': ["Take a deep breath (4-7-8 technique). Center yourself.", "Focus on one thing at a time. You've got this.", "Hydrate and step away from the screen for 5 minutes."],
    'neutral': ["Stay hydrated! Drink at least 8 glasses of water today.", "A perfect time for a quick 5-minute mindfulness walk.", "Reflect on one thing you are grateful for today."]
  };

  TextStyle headingStyle(bool isDark) => TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87,
  );

  bool _isTabLocked(Map<String, dynamic> userData) {
    if (_selectedTab == 'Daily') return false;
    DateTime? creationTime = _user?.metadata.creationTime;
    if (creationTime == null) return true;
    int daysSinceJoined = DateTime.now().difference(creationTime).inDays;
    if (_selectedTab == 'Weekly' && daysSinceJoined < 7) return true;
    if (_selectedTab == 'Monthly' && daysSinceJoined < 30) return true;
    return false;
  }

  String _getLockMessage() {
    if (_selectedTab == 'Weekly') return "Weekly insights unlock after 7 days of activity.";
    if (_selectedTab == 'Monthly') return "Monthly reports require 30 days of consistent data.";
    return "";
  }

  Future<void> _refreshAIAnalysis() async {
    if (_user == null || _isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final historySnap = await _firestore.collection('chats').doc(_user!.uid).collection('history').orderBy('timestamp', descending: true).limit(1).get();
      if (historySnap.docs.isEmpty) {
        if (mounted) setState(() => _isUpdating = false);
        return;
      }
      String latestChatId = historySnap.docs.first.id;
      final messagesSnap = await _firestore.collection('chats').doc(_user!.uid).collection('history').doc(latestChatId).collection('messages').orderBy('timestamp', descending: true).limit(5).get();
      String chatText = messagesSnap.docs.map((m) => EncryptionHelper.decryptText(m['text'] ?? "")).join(" ");
      final res = await http.post(Uri.parse(predictUrl), headers: {"Content-Type": "application/json"}, body: jsonEncode({"text": chatText}));
      if (res.statusCode == 200) {
        String moodLabel = jsonDecode(res.body)['emotion'] ?? "Neutral";
        String moodKey = moodLabel.toLowerCase().trim();
        String randomTip = (moodTips[moodKey] ?? moodTips['neutral']!).first;
        await _firestore.collection('users').doc(_user!.uid).update({
          'latest_tip': randomTip,
          'last_mood_detected': moodLabel,
          'last_mood_update': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) { debugPrint(e.toString()); } finally { if (mounted) setState(() => _isUpdating = false); }
  }

 Future<Map<String, double>> _calculateSmartScores() async {
    if (_user == null) return {'happy': 0.0, 'stress': 0.0, 'sad': 0.0};
    
    DateTime now = DateTime.now();
    DateTime startTime;

    // Daily logic: Aaj raat 12:00 AM se ab tak ka data
    if (_selectedTab == 'Daily') {
      startTime = DateTime(now.year, now.month, now.day);
    } 
    // Weekly logic: Pichle 7 din
    else if (_selectedTab == 'Weekly') {
      startTime = now.subtract(const Duration(days: 7));
    } 
    // Monthly logic: Pichle 30 din
    else {
      startTime = now.subtract(const Duration(days: 30));
    }

    var snapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('mood_history')
        .where('timestamp', isGreaterThanOrEqualTo: startTime)
        .get();

    double happy = 0, sad = 0, stress = 0;
    for (var doc in snapshot.docs) {
      String m = doc['mood']?.toString().toLowerCase() ?? "";
      if (['joy', 'happy', 'surprise'].contains(m)) happy++;
      else if (['sadness', 'sad'].contains(m)) sad++;
      else stress++;
    }

    double total = happy + sad + stress;
    if (total == 0) return {'happy': 0.0, 'stress': 0.0, 'sad': 0.0};
    return {'happy': happy / total, 'stress': stress / total, 'sad': sad / total};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FBFF),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(_user?.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return _buildGlobalShimmer();
            final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            bool isLocked = _isTabLocked(userData);

            return RefreshIndicator(
              onRefresh: _refreshAIAnalysis,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(textColor),
                    const SizedBox(height: 20),
                    _buildCalendarStrip(cardColor, textColor),
                    const SizedBox(height: 20),
                    _buildTimeToggle(isDark),
                    const SizedBox(height: 25),
                    if (isLocked) 
                      _buildLockedView(cardColor, isDark) 
                    else ...[
                      _buildStatsRow(_getDisplayTime(userData), (userData['sessions_count'] ?? 0).toString(), cardColor, isDark),
                      const SizedBox(height: 25),
                      FutureBuilder<Map<String, double>>(
                        future: _calculateSmartScores(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                          final s = snap.data ?? {'happy': 0.0, 'stress': 0.0, 'sad': 0.0};
                          return _buildEmotionBreakdown(s['happy']!, s['stress']!, s['sad']!, cardColor, isDark);
                        }
                      ),
                      const SizedBox(height: 25),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('users').doc(_user!.uid).collection('breathing_history').orderBy('timestamp', descending: true).snapshots(),
                        builder: (context, bSnap) {
                          return _buildMoodTrendSection(_processHistoryToBars(bSnap.data?.docs ?? []), cardColor, isDark);
                        }
                      ),
                      const SizedBox(height: 25),
                      _buildAIInsightsCard(userData, isDark),
                      const SizedBox(height: 16),
                      _buildSmartActionButton(userData['last_mood_detected'] ?? "Neutral"),
                    ],
                    const SizedBox(height: 40),
                  ],
                ).animate().fadeIn(duration: 500.ms),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmartActionButton(String mood) {
    String label = "Start Quick Session";
    IconData icon = Icons.play_arrow_rounded;
    Widget targetScreen = const BreathingScreen(); 
    
    if (mood.toLowerCase().contains("stress")) { 
      label = "Start Breathing Exercise"; 
      icon = Icons.air_rounded;
      targetScreen = const BreathingScreen();
    }
    else if (mood.toLowerCase().contains("sad")) { 
      label = "Chat with Mindful AI"; 
      icon = Icons.chat_bubble_outline_rounded;
      targetScreen = const ChatScreen();
    }
    else if (mood.toLowerCase().contains("happy")) { 
      label = "Reflect & Connect"; 
      icon = Icons.favorite_border_rounded;
      targetScreen = const ChatScreen();
    }

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen)),
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: myPrimaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

Widget _buildTopHeader(Color textColor) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(
          color: myPrimaryColor.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(10)
        ), 
        child: const Icon(Icons.insights_rounded, color: myPrimaryColor, size: 20)
      ),
      const SizedBox(width: 12), 
      Text(
        "Your Insights", 
        style: headingStyle(true).copyWith(color: textColor, fontSize: 18)
      ),
      // Spacer sab kuch left side pe rakhe ga aur right side khali rahay gi
      const Spacer(), 
    ],
  );

  Widget _buildCalendarStrip(Color cardColor, Color textColor) => InkWell(
    onTap: () async {
      // Is se real calendar khule ga
      await showDatePicker(
        context: context, 
        initialDate: _selectedDate, 
        firstDate: DateTime(2024), 
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: myPrimaryColor),
          ),
          child: child!,
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: myPrimaryColor.withOpacity(0.1))
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, color: myPrimaryColor, size: 18), 
        const SizedBox(width: 12), 
        Text(
          DateFormat('MMMM d, yyyy').format(_selectedDate), 
          style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500)
        ),
        const Spacer(),
        const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20), // Dropdown icon tells user it's clickable
      ]),
    ),
  );

  Widget _buildTimeToggle(bool isDark) => Container(
    padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(16)),
    child: Row(children: ['Daily', 'Weekly', 'Monthly'].map((tab) {
      bool isSelected = _selectedTab == tab;
      return Expanded(child: GestureDetector(onTap: () => setState(() => _selectedTab = tab), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isSelected ? myPrimaryColor : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(tab, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))))));
    }).toList()),
  );

  Widget _buildLockedView(Color cardColor, bool isDark) => Container(
    width: double.infinity, padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
    child: Column(children: [Icon(Icons.lock_clock_rounded, size: 60, color: myPrimaryColor.withOpacity(0.5)), const SizedBox(height: 20), Text("Module Locked", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark?Colors.white:Colors.black87)), const SizedBox(height: 10), Text(_getLockMessage(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey))]),
  ).animate().scale();

  Widget _buildStatsRow(String time, String sessions, Color cardColor, bool isDark) => Row(children: [
    _statCard(Icons.access_time_filled_rounded, time, "Focus Time", myPrimaryColor, cardColor, isDark),
    const SizedBox(width: 16),
    _statCard(Icons.local_fire_department_rounded, sessions, "Sessions", Colors.orangeAccent, cardColor, isDark),
  ]);

  Widget _statCard(IconData icon, String val, String label, Color color, Color cardColor, bool isDark) => Expanded(child: Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 24), const SizedBox(height: 12), Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark?Colors.white:Colors.black87)), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
  ));

  Widget _buildEmotionBreakdown(double happy, double stress, double sad, Color cardColor, bool isDark) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("Mood Distribution", style: headingStyle(isDark)), const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)), child: Column(children: [_buildEmotionBar("Happiness", happy, Colors.teal, isDark), const SizedBox(height: 16), _buildEmotionBar("Stress Level", stress, Colors.orangeAccent, isDark), const SizedBox(height: 16), _buildEmotionBar("Sadness", sad, Colors.blueAccent, isDark)]))
  ]);

  Widget _buildEmotionBar(String label, double val, Color color, bool isDark) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: 13, color: isDark?Colors.white70:Colors.black54)), Text("${(val*100).toInt()}%", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]),
    const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: val, backgroundColor: color.withOpacity(0.1), color: color, minHeight: 10))
  ]);

 Widget _buildMoodTrendSection(List<BarChartGroupData> barGroups, Color cardColor, bool isDark) {
    // Check if there is any data to show
    bool hasData = barGroups.any((group) => group.barRods.any((rod) => rod.toY > 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Text(
          _selectedTab == 'Monthly' ? "Monthly Session Analytics" : "Activity Tracker", 
          style: headingStyle(isDark)
        ), 
        const SizedBox(height: 4),
        const Text(
          "Total mindfulness sessions per day", 
          style: TextStyle(fontSize: 11, color: Colors.grey)
        ),
        const SizedBox(height: 20),
        Container(
          height: 220, 
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: cardColor, 
            borderRadius: BorderRadius.circular(24),
            // Light border for premium feel
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: !hasData 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_rounded, color: Colors.grey.withOpacity(0.3), size: 40),
                    const SizedBox(height: 8),
                    Text(
                      "No sessions recorded yet", 
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)
                    ),
                  ],
                ),
              )
            : BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false, 
                    getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1)
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, 
                        reservedSize: 30, 
                        getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10))
                      )
                    ),
                  bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    getTitlesWidget: (double value, TitleMeta meta) {
      // 1. Daily Tab: S1, S2, S3... dikhane ke liye
      if (_selectedTab == 'Daily') {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text("S${value.toInt() + 1}", 
            style: const TextStyle(color: Colors.grey, fontSize: 10)),
        );
      } 
      
      // 2. Weekly Tab: Mon, Tue... dikhane ke liye
      else if (_selectedTab == 'Weekly') {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        if (value.toInt() >= 0 && value.toInt() < 7) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(days[value.toInt()], 
              style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          );
        }
      } 
      
      // 3. Monthly Tab: Sirf dates dikhane ke liye (1st, 10th, 20th etc.) taake messy na ho
      else if (_selectedTab == 'Monthly') {
        if (value.toInt() % 5 == 0) { // Har 5 din baad label dikhao
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text("${value.toInt() + 1}", 
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
          );
        }
      }
      
      return const Text("");
    }
  )
),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                  // Smooth animation when data changes
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
        ),
      ]
    );
  }

  // --- OVERFLOW FIXED AI INSIGHTS CARD ---
  Widget _buildAIInsightsCard(Map<String, dynamic> data, bool isDark) => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(20), 
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [myPrimaryColor.withOpacity(0.2), myPrimaryColor.withOpacity(0.05)]), 
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: myPrimaryColor.withOpacity(0.1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 18), 
            const SizedBox(width: 8), 
            const Expanded( // FIXED: Added Expanded to prevent overflow
              child: Text("AI WELLNESS INSIGHT", 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: myPrimaryColor),
                overflow: TextOverflow.ellipsis,
              ),
            ), 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
              decoration: BoxDecoration(color: myPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), 
              child: Text("Status: ${data['last_mood_detected'] ?? "Analyzing"}", 
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: myPrimaryColor)
              )
            )
          ]
        ),
        const SizedBox(height: 12), 
        Text(
          data['latest_tip'] ?? "Engage in more conversations to unlock deeper insights.", 
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87, height: 1.5)
        )
      ]
    )
  );

  String _getDisplayTime(Map<String, dynamic> userData) { int s = userData['total_breathing_seconds'] ?? 0; return s < 60 ? "${s}s" : "${(s/60).toStringAsFixed(1)}m"; }

 List<BarChartGroupData> _processHistoryToBars(List<QueryDocumentSnapshot> docs) {
  DateTime now = DateTime.now();
  DateTime todayStart = DateTime(now.year, now.month, now.day);
  
  // 1. Determine Range
  int range = (_selectedTab == 'Monthly') ? 30 : 7;
  if (_selectedTab == 'Daily') range = 5; // Daily mein hum bas 5 slots dikha dete hain (Session 1, 2, 3..)

  Map<int, double> barValues = {for (var i = 0; i < range; i++) i: 0};

  // 2. Filter Data
  int dailySessionIndex = 0;
  for (var doc in docs) {
    if (doc['timestamp'] == null) continue;
    DateTime d = (doc['timestamp'] as Timestamp).toDate();

    if (_selectedTab == 'Daily') {
      // Logic: Agar message aaj ka hai, toh usay slots mein barabar daal do
      if (d.isAfter(todayStart) && dailySessionIndex < range) {
        barValues[dailySessionIndex] = (barValues[dailySessionIndex] ?? 0) + 1;
        dailySessionIndex++;
      }
    } else {
      // Weekly/Monthly: Purani logic (Days diff)
      int diff = todayStart.difference(DateTime(d.year, d.month, d.day)).inDays;
      if (diff >= 0 && diff < range) {
        int idx = (range - 1) - diff;
        barValues[idx] = (barValues[idx] ?? 0) + 1;
      }
    }
  }

  // 3. Create Bars
  return barValues.entries.map((e) => BarChartGroupData(
    x: e.key,
    barRods: [
      BarChartRodData(
        toY: e.value,
        color: myPrimaryColor,
        width: _selectedTab == 'Monthly' ? 6 : 14,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        backDrawRodData: BackgroundBarChartRodData(
          show: true, 
          toY: 5, 
          color: myPrimaryColor.withOpacity(0.05)
        ),
      )
    ],
  )).toList();
}

  Widget _buildGlobalShimmer() => Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: const Padding(padding: EdgeInsets.all(20), child: Column(children: [SizedBox(height: 40), SizedBox(height: 100)])));
}