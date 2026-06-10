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
import 'dart:math'; // Random tips ke liye zaroori hai
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
  String? _syncedMood; // Ye variable dono ko saath rakhe ga
String? _localTip; // Ye foran UI update karne ke liye hai
  String _selectedTab = 'Daily';
  bool _isSessionActive = false; // Yeh track karega ke abhi chat hui hai ya nahi
 //  Purana Code:
// final DateTime _selectedDate = DateTime.now();
//  Naya Fixed Code:
DateTime _selectedDate = DateTime.now();
  bool _isUpdating = false;
  

  static const Color myPrimaryColor = Color(0xFF26C6DA);
@override
void initState() {
  super.initState();
  // _firestore.collection('users').doc(_user?.uid).update({'latest_tip_daily': null});

}
final String predictUrl = dotenv.env['BERT_PREDICT_URL'] ?? "";

final Map<String, List<String>> moodTips = {

    'joy': [
      "Oho! Aaj toh bari chamak aa rahi hai face par, party kab hai? 🎉",
      "Nazar na lag jaye kisi ki, itni khushi? Sadqa nikaal dena thora sa!",
      "Lagta hai aaj nashtay mein halwa puri khayi hai! Keep it up buddy.",
      "Itna khush? Pakka koi achi news mili hai, mujhe bhi toh batao!",
      "Aapki vibes 100/100 hain aaj. Isay kisi boring kaam mein mat zaya karna.",
      "Aaj toh status lagana banta hai! Spread this smile.",
      "MashaAllah! Bas aise hi haste raho, dushmanon ko jalana bhi toh hai. 😉"
    ],
    'sadness': [
      "Yar itna mun kyun latkaya hua hai? Chalo utho, ek karak chai paitay hain. ☕",
      "Zindagi hai yar, up-down chalta rehta hai. Itna dil par mat lo.",
      "Acha bas ab rona band! Chalo koi purani funny video dekhte hain.",
      "Sunn, tu akela nahi hai. Main hoon na, jo bhi hai nikaal dil se.",
      "Lagta hai kisi ne dil dukhaya hai? Usay choro, apni value samjho!",
      "Thora bahar nikal, taaza hawa kha, ye kamray mein beth kar overthinking mat kar.",
      "Ek chocolate khao aur thori dair so jao, sab theek ho jayega InshaAllah."
    ],
    'stress': [
      "O bhai! Dimag ka dahi mat karo, ek waqt mein ek kaam pakro.",
      "Gehri saans le... lambi wali! Itni tension legi toh jaldi budhi ho jayegi. 😂",
      "Laptop/Mobile side par rakho 5 minute, aankhein band kar ke sukoon karo.",
      "Dunya khatam nahi ho rahi, relax! Sab ho jayega apne time par.",
      "Suno, paani piyo aur thori dair kisi se gappe maro, stress bhag jayega.",
      "Zyada load mat lo, jitna ho sakta hai bas utna hi karo. Machine nahi ho tum!",
      "Thora stretch karo, body bohot tight ho rahi hai tumhari tension se."
    ],
    'fear': [
      "Darr ke agay jeet hai (aur peechay danda)! Darne ki koi baat nahi hai.",
      "Itni bahadur ho kar darr rahi ho? Chal shabaash, face kar isay!",
      "Jo hoga dekha jayega, abhi se kyun darr rahi ho? Main saath hoon.",
      "Ayat-ul-Kursi parh lo aur thora sukoon karo, sab khair hai.",
      "Darr sirf dimag mein hota hai, haqeeqat mein kuch nahi hai. Chill karo!",
      "Arey kuch nahi hota, itni si baat se darr gayi? Sher bano sher!"
    ],
    'anger': [
      "Thanda paani piyo yar! Gussay mein faislay nahi karte.",
      "10 tak ginti gino... 1, 2, 3... gussa thora thanda hua ya bhejoon thanda juice?",
      "Gussa karke apna hi khoon jala rahi ho, choro na mitti pao!",
      "Abhi reply mat karna kisi ko, pehle gussa thanda hone do phir baat karna.",
      "Chill maro yar, logon ka kaam hai bolna. Unki wajah se apna mood kyun khrab karna?",
      "Wuzu kar lo, gussa shaytan ka hota hai, foran sukoon mil jayega."
    ],
    'neutral': [
      "Aur sunao? Sab khairiyat? Aaj toh bare khamosh ho.",
      "Kuch boring feel ho raha hai? Chalo koi naya gaana sunte hain.",
      "Free ho toh thora ghar walon ke paas beth jao, acha lagega.",
      "Aaj ka plan kya hai? Kuch productive karte hain chalo!",
      "Zindagi thori slow chal rahi hai aaj? Koi baat nahi, kabhi kabhi sukoon bhi chahiye.",
      "Suno! Aaj khud ko ek choti si treat do, tum deserve karti ho."
    ]
  };
  TextStyle headingStyle(bool isDark) => TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87,
  );

 bool _isTabLocked(Map<String, dynamic> userData) {
  //  return false;
 if (_selectedTab == 'Daily') return false;
  
  DateTime? creationTime = _user?.metadata.creationTime;
  if (creationTime == null) return true;

  // --- FIX: Dono dates ka "Time" zero kar dein (Normalize) ---
  DateTime today = DateTime.now();
  DateTime pureToday = DateTime(today.year, today.month, today.day);
  DateTime pureJoinDate = DateTime(creationTime.year, creationTime.month, creationTime.day);

  // Ab ye pure dino ka farq nikalay ga
  int daysSinceJoined = pureToday.difference(pureJoinDate).inDays;

  if (_selectedTab == 'Weekly') {
    return daysSinceJoined < 7; 
  }
  if (_selectedTab == 'Monthly') {
    return daysSinceJoined < 30;
  }
  return false;
 
 }

  String _getLockMessage() {
    if (_selectedTab == 'Weekly') return "Weekly insights unlock after 7 days of activity.";
    if (_selectedTab == 'Monthly') return "Monthly reports require 30 days of consistent data.";
    return "";
  }
Future<void> _refreshAIAnalysis() async {
  if (_user == null) return;

  try {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
    
    String finalMoodToUse = "neutral";

    if (_selectedTab == 'Daily') {
      String userMessage = (userData['last_message_text'] ?? "").toString().toLowerCase(); 
      String rawBert = (userData['last_mood_detected'] ?? "neutral").toString().toLowerCase();

      if (userMessage.contains("stress") || userMessage.contains("tension") || userMessage.contains("burden")) {
        finalMoodToUse = 'stress';
      } 
      else if (userMessage.contains("happy") || userMessage.contains("joy") || userMessage.contains("mazay")) {
        finalMoodToUse = 'joy';
      }
      else if (userMessage.contains("sad") || userMessage.contains("roney") || userMessage.contains("dukh")) {
        finalMoodToUse = 'sadness';
      }
      else {
        if (['joy', 'happy', 'surprise', 'love'].contains(rawBert)) finalMoodToUse = 'joy';
        else if (['sadness', 'sad', 'disappointed'].contains(rawBert)) finalMoodToUse = 'sadness';
        else if (['stress', 'anger', 'fear', 'annoyed'].contains(rawBert)) finalMoodToUse = 'stress';
        else finalMoodToUse = "neutral";
      }
    } 
    else {
      DateTime now = DateTime.now();
      DateTime startTime = (_selectedTab == 'Weekly') 
          ? now.subtract(const Duration(days: 7)) 
          : now.subtract(const Duration(days: 30));

      final moodSnap = await _firestore.collection('users').doc(_user!.uid)
          .collection('mood_history')
          .where('timestamp', isGreaterThanOrEqualTo: startTime)
          .get();

      if (moodSnap.docs.isNotEmpty) {
        Map<String, int> counts = {'joy': 0, 'sadness': 0, 'stress': 0, 'neutral': 0};
        for (var doc in moodSnap.docs) {
          String m = doc['mood']?.toString().toLowerCase() ?? "neutral";
          if (['joy', 'happy', 'surprise'].contains(m)) counts['joy'] = counts['joy']! + 1;
          else if (['sadness', 'sad'].contains(m)) counts['sadness'] = counts['sadness']! + 1;
          else if (['stress', 'anger', 'fear'].contains(m)) counts['stress'] = counts['stress']! + 1;
          else counts['neutral'] = counts['neutral']! + 1;
        }
        var dominantEntry = counts.entries.reduce((a, b) => a.value > b.value ? a : b);
        if (dominantEntry.value > 0) finalMoodToUse = dominantEntry.key;
      }
    }
String fieldName = 'latest_tip_${_selectedTab.toLowerCase()}'; 
    List<String> selectedTipsList = moodTips[finalMoodToUse] ?? moodTips['neutral']!;
    String dynamicTip = "$_selectedTab Summary: ${selectedTipsList[Random().nextInt(selectedTipsList.length)]}";

    Map<String, dynamic> updateMap = {
      fieldName: dynamicTip,
    };

    // SIRF Daily tab par 'last_mood_detected' update hoga
    if (_selectedTab == 'Daily') {
      updateMap['last_mood_detected'] = finalMoodToUse.toUpperCase();
      updateMap['last_mood_update'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('users').doc(_user!.uid).update(updateMap);

    if (mounted) {
      setState(() {
        // Local variables ko clear kar do taake wo Firestore se fresh data uthaye
        _localTip = null; 
        _syncedMood = null;
      });
    }
  } catch (e) {
    debugPrint("AI Refresh Error: $e");
  }
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

          // Session Active check
          Timestamp? lastUpdate = userData['last_mood_update'] as Timestamp?;
          if (lastUpdate != null) {
            DateTime updateTime = lastUpdate.toDate();
            DateTime now = DateTime.now();
            _isSessionActive = (updateTime.day == now.day && 
                               updateTime.month == now.month && 
                               updateTime.year == now.year);
          }
          bool isLocked = _isTabLocked(userData);

          return SingleChildScrollView(
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
                  // --- SECTION 1: STATS CARDS ---
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').doc(_user!.uid).collection('breathing_history').snapshots(),
                    builder: (context, sessionSnap) {
                      DateTime now = _selectedDate;
                      DateTime startTime = _selectedTab == 'Daily' 
                          ? DateTime(now.year, now.month, now.day) 
                          : (_selectedTab == 'Weekly' ? now.subtract(const Duration(days: 7)) : now.subtract(const Duration(days: 30)));

                      int totalSessions = 0;
                      int totalSeconds = 0;

                      if (sessionSnap.hasData) {
                        final filteredDocs = sessionSnap.data!.docs.where((doc) {
                          Timestamp? t = doc['timestamp'] as Timestamp?;
                          return t != null && t.toDate().isAfter(startTime);
                        }).toList();
                        totalSessions = filteredDocs.length;
                        for (var doc in filteredDocs) {
                          totalSeconds += (doc.data() as Map<String, dynamic>)['duration'] as int? ?? 0; 
                        }
                      }
                      String displayTime = totalSeconds < 60 ? "${totalSeconds}s" : "${(totalSeconds / 60).toStringAsFixed(1)}m";
                      return _buildStatsRow(displayTime, totalSessions.toString(), cardColor, isDark);
                    }
                  ),

                  const SizedBox(height: 25),

                 // --- SECTION 2: MOOD BARS (FIXED FOR NEUTRAL) ---
StreamBuilder<QuerySnapshot>(
  stream: _firestore.collection('users').doc(_user!.uid).collection('mood_history').snapshots(),
  builder: (context, moodSnap) {
    if (moodSnap.connectionState == ConnectionState.waiting) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }
    
    DateTime now = _selectedDate;
    DateTime startTime = _selectedTab == 'Daily' 
        ? DateTime(now.year, now.month, now.day) 
        : (_selectedTab == 'Weekly' ? now.subtract(const Duration(days: 7)) : now.subtract(const Duration(days: 30)));

    double happy = 0, sad = 0, stress = 0;
    
    final docs = moodSnap.data?.docs.where((doc) {
      Timestamp? t = doc['timestamp'] as Timestamp?;
      return t != null && t.toDate().isAfter(startTime);
    }).toList() ?? [];

    for (var doc in docs) {
      String m = doc['mood']?.toString().toLowerCase() ?? "";
      
      if (['joy', 'happy', 'surprise', 'love'].contains(m)) {
        happy++;
      } else if (['sadness', 'sad', 'disappointed'].contains(m)) {
        sad++;
      } else if (['stress', 'anger', 'fear', 'annoyed'].contains(m)) {
        stress++;
      }
      // 📝 Note: Agar 'neutral' hoga, toh wo kisi mein plus nahi hoga aur baqi bars bilkul freeze rahein ge!
    }

    // Formula total mein ab sirf active moods plus honge, neutral isay disturb nahi karega
    double total = happy + sad + stress;
    
    return _buildEmotionBreakdown(
      total == 0 ? 0 : happy / total, 
      total == 0 ? 0 : stress / total, 
      total == 0 ? 0 : sad / total, 
      cardColor, 
      isDark,
    );
  },
),

                  const SizedBox(height: 25),

                  // --- SECTION 3: ACTIVITY TRACKER ---
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').doc(_user!.uid).collection('breathing_history').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, bSnap) {
                      return _buildMoodTrendSection(_processHistoryToBars(bSnap.data?.docs ?? []), cardColor, isDark);
                    }
                  ),

                  const SizedBox(height: 25),
Builder(
  builder: (context) {
    String tipKey = 'latest_tip_${_selectedTab.toLowerCase()}';
    String? currentTip = _localTip ?? userData[tipKey];
    
    // Status ki tension khatam, bas placeholder ke liye neutral mood rakho
    String currentMood = userData['last_mood_detected'] ?? "NEUTRAL";

    if (currentTip == null || currentTip.isEmpty) return _buildInitialEngageCard(isDark);

    return Column(
      key: ValueKey("$_selectedTab-$currentTip"), 
      children: [
        _buildAIInsightsCard(userData, isDark, currentTip), // Ab sirf 3 parameters hain
        const SizedBox(height: 16),
        _buildSmartActionButton(currentMood), 
      ],
    );
  },
),
                  const SizedBox(height: 40),
                ],
              ],
            ).animate().fadeIn(duration: 500.ms),
          );
        },
      ),
    ),
  );
}

Widget _buildInitialEngageCard(bool isDark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark ? Colors.white10 : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: myPrimaryColor.withOpacity(0.1)),
    ),
    child: Column(
      children: [
        const Icon(Icons.auto_awesome_outlined, color: myPrimaryColor, size: 32),
        const SizedBox(height: 12),
        Text("Ready for a check-in?", 
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        const Text(
          "Chat with Mindful AI to analyze your mood and get new tips!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
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
  // Apne _buildSmartActionButton mein Navigator wala hissa check karo:
onPressed: () async {
  // 1. Chat screen par jao aur wapis aane ka intezar (await) karo
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => targetScreen),
  );

  // --- YE CODE TAB CHALAY GA JAB USER WAPIS AA JAYE GA ---
  
  // 2. UI ko active karo
  setState(() {
    _isSessionActive = true; 
  });

  // 3. Analysis chalao aur iska bhi intezar karo taake data save ho jaye
  await _refreshAIAnalysis(); 
  
  // Ab shuffle ki zaroorat nahi paregi kyunke screen analysis ke BAAD rebuild hogi!
},
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
      // 1. User ki select ki hui date ko variable mein pakro
      final DateTime? picked = await showDatePicker(
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

      // 2. Agar user ne date select ki hai (Cancel nahi dabaya)
      if (picked != null && picked != _selectedDate) {
        setState(() {
          // Yahan date update hogi aur UI refresh hoga
          _selectedDate = picked; 
        });
        
        // 3. Nayi date ke mutabiq analysis refresh karo
        _refreshAIAnalysis(); 
      }
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
        const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
      ]),
    ),
  );

  Widget _buildTimeToggle(bool isDark) => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['Daily', 'Weekly', 'Monthly'].map((tab) {
          bool isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
            onTap: () {
  setState(() {
    _selectedTab = tab;
    _localTip = null; // Purani local tip clear karo taake naya data fetch ho
  });
  _refreshAIAnalysis();
},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? myPrimaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
      if (_selectedTab == 'Daily') {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text("S${value.toInt() + 1}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
        );
      } 
      else if (_selectedTab == 'Weekly') {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        if (value.toInt() >= 0 && value.toInt() < 7) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          );
        }
      } 
      else if (_selectedTab == 'Monthly') {
        // --- MONTHLY LABELS FIX ---
        const weeks = ['W1', 'W2', 'W3', 'W4']; // Weeks ke labels
        if (value.toInt() >= 0 && value.toInt() < 4) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(weeks[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
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
Widget _buildAIInsightsCard(Map<String, dynamic> data, bool isDark, String currentTip) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [myPrimaryColor.withOpacity(0.2), myPrimaryColor.withOpacity(0.05)]
      ),
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
            Text(
              "AI ${_selectedTab.toUpperCase()} INSIGHT",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: myPrimaryColor),
            ),
            // STATUS WALA CONTAINER YAHAN SE DELETE KAR DIYA
          ],
        ),
        const SizedBox(height: 12),
        Text(
          currentTip,
          style: TextStyle(
            fontSize: 15, 
            color: isDark ? Colors.white : Colors.black87, 
            height: 1.5
          ),
        ),
      ],
    ),
  );
}
  String _getDisplayTime(Map<String, dynamic> userData) { int s = userData['total_breathing_seconds'] ?? 0; return s < 60 ? "${s}s" : "${(s/60).toStringAsFixed(1)}m"; }

List<BarChartGroupData> _processHistoryToBars(List<QueryDocumentSnapshot> docs) {
  DateTime now = _selectedDate;
  DateTime todayStart = DateTime(now.year, now.month, now.day);
  
  // 1. Range set karein (Monthly ke liye 4 bars, Weekly ke liye 7)
  int range = (_selectedTab == 'Monthly') ? 4 : 7;
  
  if (_selectedTab == 'Daily') {
    int todayCount = docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['timestamp'] == null) return false; 
      DateTime d = (data['timestamp'] as Timestamp).toDate();
      return d.isAfter(todayStart);
    }).length;
    range = todayCount > 0 ? todayCount : 5; 
  }

  // Bar values initialize karein
  Map<int, double> barValues = {for (var i = 0; i < range; i++) i: 0};

  // 2. Data process karein
  int dailySessionIndex = 0;
  for (var doc in docs) {
    var data = doc.data() as Map<String, dynamic>;
    if (data['timestamp'] == null) continue;

    DateTime d = (data['timestamp'] as Timestamp).toDate();

    if (_selectedTab == 'Daily') {
      if (d.isAfter(todayStart) && dailySessionIndex < range) {
        barValues[dailySessionIndex] = (barValues[dailySessionIndex] ?? 0) + 1;
        dailySessionIndex++;
      }
    } else if (_selectedTab == 'Weekly') {
      int diff = todayStart.difference(DateTime(d.year, d.month, d.day)).inDays;
      if (diff >= 0 && diff < 7) {
        // Mon=1, Sun=7. Indexing 0-6 ke liye -1
        int idx = d.weekday - 1; 
        barValues[idx] = (barValues[idx] ?? 0) + 1;
      }
    } else if (_selectedTab == 'Monthly') {
  int diff = todayStart.difference(DateTime(d.year, d.month, d.day)).inDays;
  
  if (diff >= 0 && diff < 30) {
    // Pehle hum (3 - weekIdx) kar rahe thay, ab direct index use karein ge
    // weekIdx 0 = Aaj se 0-7 din pehle
    // weekIdx 1 = 8-14 din pehle...
    
    int weekIdx = diff ~/ 7; 
    
    // Yahan logic ulta kar dein:
    // Index 0: 22-30 din pehle (Puraana data) -> W1
    // Index 3: 0-7 din pehle (Fresh data) -> W4
    
    // Lekin tum chah rahi ho ke 0-7 din pehle wala W1 ho? 
    // Toh phir simple 'weekIdx' use karo:
    int idx = weekIdx.clamp(0, 3); 
    
    barValues[idx] = (barValues[idx] ?? 0) + 1;
  }
}
  }

  // 3. Bars Create karein
  return barValues.entries.map((e) => BarChartGroupData(
    x: e.key,
    barRods: [
      BarChartRodData(
        toY: e.value,
        color: myPrimaryColor,
        width: _selectedTab == 'Monthly' ? 25 : 14, // Monthly bar thori wide rakhein
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