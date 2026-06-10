import 'dart:convert';
import 'dart:async';
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:encrypt/encrypt.dart' as encrypt; 
// import 'package:telephony/telephony.dart'; 
import 'emergency_support_screen.dart';
import 'breathing_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'; // Ye line add karein
const Color myPrimaryColor = Color(0xFF26C6DA); 

final String GEMINI_API_KEY = dotenv.env['GEMINI_API_KEY'] ?? "";
final String GEMINI_MODEL = dotenv.env['GEMINI_MODEL'] ?? "default-model"; 

class EncryptionHelper {
  static final key = encrypt.Key.fromUtf8('my_super_secret_key_123456789012'); 
  static final iv = encrypt.IV.fromUtf8('8888888888888888'); 
  static final encrypter = encrypt.Encrypter(encrypt.AES(key));

  static String encryptText(String text) {
    if (text.isEmpty) return text;
    try {
      return encrypter.encrypt(text, iv: iv).base64;
    } catch (e) {
      return text;
    }
  }

  static String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    try {
      return encrypter.decrypt64(encryptedText, iv: iv);
    } catch (e) {
      debugPrint("Decryption Error: $e");
      return encryptedText; 
    }
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? _user = FirebaseAuth.instance.currentUser;
  static const platform = MethodChannel('send_sms_channel');
  // final Telephony telephony = Telephony.instance;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isTyping = false;
  bool _showEmoji = false;
  late String _currentChatId;
  Timer? _inactivityTimer;
  String _detectedMood = "Mood Detection";
  String? _editingMessageId;
 final String bertBackendUrl = dotenv.env['BERT_PREDICT_URL'] ?? "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // --- REST OF THE METHODS (Mood Tips, Stats, etc.) ---
  String _mapMoodToField(String mood) {
    String m = mood.toLowerCase().trim();
    if (['joy', 'happy', 'surprise', 'love'].contains(m)) return "happy_count";
    if (['stress', 'fear', 'anger', 'disgust', 'anxiety', 'tense'].contains(m)) return "stress_count";
    if (['sadness', 'sad', 'low', 'grief'].contains(m)) return "sad_count";
    if (['neutral'].contains(m)) return "neutral_count";
    return "";
  }

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

 Future<void> _updateEmotionStats(String mood) async {
  if (_user == null) return;
  String moodKey = mood.toLowerCase().trim();
  
  // 1. Tip pick karo
  List<String> selectedTips = moodTips[moodKey] ?? moodTips['neutral']!;
  selectedTips.shuffle(); 
  String randomTip = "Daily Summary: ${selectedTips.first}"; // Format matching

  String fieldName = _mapMoodToField(mood);
  
  try {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
    
    // 2. Map mein sahi field name dalo
    Map<String, dynamic> updateData = {
      'last_mood_update': FieldValue.serverTimestamp(),
      'last_mood_detected': mood.toUpperCase(), // Status update
      'latest_tip_daily': randomTip,            // <--- YEH HAI VO MAIN CHANGE
    };
    
    if (fieldName.isNotEmpty) updateData[fieldName] = FieldValue.increment(1);
    
    // Ek hi update call mein status aur tip dono chale gaye
    await userRef.update(updateData);
    
    await userRef.collection('mood_history').add({
      'mood': mood, 
      'timestamp': FieldValue.serverTimestamp()
    });
  } catch (e) { 
    debugPrint("Stats Update Error: $e"); 
  }
}

  Future<String> _analyzeWithBERT(String text) async {
    setState(() => _detectedMood = "Analyzing Mood...");
   try {
  final response = await http.post(
      // Yahan ab bertBackendUrl use hoga
      Uri.parse(bertBackendUrl), 
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    ).timeout(const Duration(seconds: 12));

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseBody = jsonDecode(response.body);
    // Note: Confirm kar lein ke Hugging Face se 'emotion' hi wapas aa raha hai
    String mood = responseBody['label'] ?? responseBody['emotion'] ?? "Neutral"; 
    
    setState(() => _detectedMood = "Current Mood: $mood");
    await _updateEmotionStats(mood);
    return mood;
  } else {
    print("Backend Error: ${response.statusCode}");
  }
} catch (e) {
  print("Connection Error: $e");
}
    setState(() => _detectedMood = "Mood: Neutral");
    return "Neutral";
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && !_isTyping) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Main yahan hoon, agar aap kuch kehna chahein...")));
      }
    });
  }
Future<void> sendBackgroundSMS(String phoneNumber, String messageContent) async {
  try {
    await platform.invokeMethod('sendSMS', {
      'phone': phoneNumber,
      'message': messageContent,
    });
    print("SMS successfully sent via Native Android Bridge!");
  } on PlatformException catch (e) {
    print("Failed to send SMS: '${e.message}'.");
  }
}
  // --- UPDATED CORE LOGIC ---
  Future<void> _sendMessage() async {
  final text = _controller.text.trim();
  if (text.isEmpty || _user == null || _isTyping) return;

  // 1. Internet check
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    _showErrorSnackBar("Internet not found! Please check your connection.");
    return;
  }

  final messagesRef = FirebaseFirestore.instance.collection('chats').doc(_user!.uid).collection('history').doc(_currentChatId).collection('messages');
  String encryptedText = EncryptionHelper.encryptText(text);

  if (_editingMessageId != null) {
    String msgIdToUpdate = _editingMessageId!;
    setState(() { _editingMessageId = null; _isTyping = true; });
    _controller.clear();
    await messagesRef.doc(msgIdToUpdate).update({'text': encryptedText, 'edited': true});
    await _getAIResponse(text, messagesRef);
  } else {
    _controller.clear();
    setState(() { _isTyping = true; _showEmoji = false; });
    
    // 2. Chat history title set karna
    await FirebaseFirestore.instance.collection('chats').doc(_user!.uid).collection('history').doc(_currentChatId).set({
      'title': EncryptionHelper.encryptText(text.length > 30 ? "${text.substring(0, 27)}..." : text),
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

   // 3. User message add karna
    await messagesRef.add({'text': encryptedText, 'isUser': true, 'timestamp': FieldValue.serverTimestamp()});

    // 4. Emergency check
    if (["emergency", "help", "suicide", "marne", "kill", "jaan khatam"].any((w) => text.toLowerCase().contains(w))) {
      
      // Firestore se current user ka emergency number fetch karna
      final currentUser = FirebaseAuth.instance.currentUser;
      String emergencyNumber = ""; // Default empty

      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        // फर्ज़ करो tumne field ka naam 'emergencyContact' ya 'trustedNumber' rakkha hai
        emergencyNumber = userDoc.data()?['emergencyContact'] ?? ""; 
      }

      // Agar number mil jaye toh hi SMS bhejo
      if (emergencyNumber.isNotEmpty) {
        String messageContent = "Emergency Alert from Mindful Haven! User sent a critical message: '$text'";
        
        try {
          await platform.invokeMethod('sendSMS', {
            'phone': emergencyNumber,
            'message': messageContent,
          });
          print("Dynamic Emergency SMS Sent to: $emergencyNumber");
        } on PlatformException catch (e) {
          print("Failed to send automatic SMS: '${e.message}'.");
        }
      } else {
        print("No emergency number found in Firestore for this user!");
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencySupportScreen()));
      setState(() => _isTyping = false);
    } else {
// --- NAYI LOGIC START: SMART OVERRIDE + BERT SYNC ---
      String lowerText = text.toLowerCase();
      String moodResult = "";

      // 1. Pehle Keywords check karo (Manual Override)
      if (lowerText.contains("stress") || lowerText.contains("tension") || lowerText.contains("burden") || lowerText.contains("load") || lowerText.contains("exam") || lowerText.contains("crash") || lowerText.contains("hurt")) {
        moodResult = "Stress";
        // Manual override par bhi top bar aur stats update honge
        setState(() => _detectedMood = "Current Mood: Stress");
        await _updateEmotionStats("stress"); 
      } else if (lowerText.contains("happy") || lowerText.contains("joy") || lowerText.contains("mazay") || lowerText.contains("love")) {
        moodResult = "Joy";
        setState(() => _detectedMood = "Current Mood: Joy");
        await _updateEmotionStats("joy");
      } else if (lowerText.contains("sad") || lowerText.contains("roney") || lowerText.contains("dukh") || lowerText.contains("wasted")) {
        moodResult = "Sadness";
        setState(() => _detectedMood = "Current Mood: Sadness");
        await _updateEmotionStats("sadness");
      } else {
        // 2. Agar koi keyword match nahi hua, tab BERT model ko call karo
        moodResult = await _analyzeWithBERT(text);
      }

      // 5. Insights Screen ke liye text aur final mood sync karna
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
        'last_message_text': text, 
        'last_mood_detected': moodResult.toUpperCase(),
        'last_mood_update': FieldValue.serverTimestamp(),
      });

      // 6. Gemini (AI) ko final mood ke saath call karna
      await _getAIResponse(text, messagesRef, mood: moodResult);
      
      // --- NAYI LOGIC END ---
    }
  }
  _startInactivityTimer();
}
Future<void> _getAIResponse(String text, CollectionReference messagesRef, {String mood = "Neutral"}) async {
  try {
    // Current Logged-in User ki ID lena
    final currentUser = FirebaseAuth.instance.currentUser;
    int userAge = 20; // Default age agar database se na mile

    if (currentUser != null) {
      // Firestore se user ka document nikalna taake hum uski age parh sakein
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data()?['age'] != null) {
        userAge = userDoc.data()?['age'];
      }
    }

    //  Age ke mutabik specific tone set karna (Yeh hum system instruction mein bhejenge)
    String ageToneInstruction = "";
    if (userAge < 15) {
      // 12-14 saal ke bachon ke liye dosti wali aur soft tone
      ageToneInstruction = "The user is a child (Age: $userAge). Act like a friendly elder sibling or school friend. Use very simple words, be extremely playful, gentle, and avoid complex psychological advice.";
    } else {
      // Adults ke liye mature tone
      ageToneInstruction = "The user is an adult (Age: $userAge). Act like a mature mental health companion. Provide sensible empathy and practical cognitive reframing.";
    }

    // Sirf aakhri 5-6 messages kaafi hain history ke liye
    final prevMessages = await messagesRef.orderBy('timestamp', descending: true).limit(6).get();
    
    //  Aap ki system instruction ke andar humne ageToneInstruction ko fit kar diya
    String systemInstruction = """
System: You are 'Mindful Friend', a friendly emotional support companion. 
The user's current detected mood is: $mood.
$ageToneInstruction

RULES:
1. Speak in a friendly mix of Roman Urdu and English (Hinglish).
2. Give a natural, short response (around 2 to 3 lines max). Don't make it just 1 short sentence, talk nicely.
3. Be supportive, use cute emojis, and give a small playful advice or joke to lighten up their mood.
""";
    
    List<Map<String, dynamic>> contents = [];

    // Sab se pehle System Instruction ko top standard structure mein add karein taake model ignore na kare
    contents.add({
      "role": "user",
      "parts": [{"text": systemInstruction}]
    });
    // History ko "User -> Model" sequence mein dalna
    for (var m in prevMessages.docs.reversed) {
      String msgText = EncryptionHelper.decryptText(m['text'] ?? "");
      if (msgText.isNotEmpty) {
        contents.add({
          "role": m['isUser'] ? "user" : "model",
          "parts": [{"text": msgText}]
        });
      }
    }

    // Naya user message payload sequence update check
    if (contents.isEmpty || contents.last['role'] == 'model') {
      contents.add({
        "role": "user",
        "parts": [{"text": text}]
      });
    } else {
      contents.last['parts'][0]['text'] += "\n\nUser: $text";
    }

    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$GEMINI_MODEL:generateContent?key=$GEMINI_API_KEY"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"contents": contents}),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        String reply = data['candidates'][0]['content']['parts'][0]['text'];
        await messagesRef.add({
          'text': EncryptionHelper.encryptText(reply),
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp()
        });
      }
    } else {
      debugPrint("Gemini Error: ${response.body}");
      _showErrorSnackBar("Server busy! Please try again in a moment.");
    }
  } catch (e) {
    debugPrint("Chat Error: $e");
    _showErrorSnackBar("Connection issues. Please check your internet.");
  } finally {
    if (mounted) setState(() => _isTyping = false);
    _scrollToBottom();
  }
}
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _deleteChat(String chatId) async {
    if (_user == null) return;
    try {
      var messages = await FirebaseFirestore.instance.collection('chats').doc(_user!.uid).collection('history').doc(chatId).collection('messages').get();
      for (var doc in messages.docs) { await doc.reference.delete(); }
      await FirebaseFirestore.instance.collection('chats').doc(_user!.uid).collection('history').doc(chatId).delete();
      if (_currentChatId == chatId) {
        setState(() { _currentChatId = DateTime.now().millisecondsSinceEpoch.toString(); _detectedMood = "Mood Detection"; });
      }
    } catch (e) { debugPrint("Delete Error: $e"); }
  }

// Feedback save karne ka function
Future<void> _submitFeedback(bool isPositive, String userComment, String aiMessage) async {
  if (_user == null) return;
  try {
    await FirebaseFirestore.instance.collection('feedback').add({
      'uid': _user!.uid,
      'isPositive': isPositive,
      'comment': userComment,
      'ai_response': EncryptionHelper.encryptText(aiMessage),
      'timestamp': FieldValue.serverTimestamp(),
      'model': GEMINI_MODEL,
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("JazakAllah! Aapka feedback save ho gaya.")),
    );
  } catch (e) {
    debugPrint("Feedback Error: $e");
  }
}

// Popup dikhanay ka function
void _showFeedbackDialog(bool isPositive, String aiMessage) {
  final TextEditingController _feedbackController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isPositive ? "Thanks for good feedback! 😍" : "Sorry! What went wrong? 😔",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: myPrimaryColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isPositive 
              ? "Glad you found this helpful! Want to say more?"
              : "Sorry for the disappointment. What was missing?",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write your feedback here...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: myPrimaryColor),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: myPrimaryColor, shape: const StadiumBorder()),
          onPressed: () {
            _submitFeedback(isPositive, _feedbackController.text, aiMessage);
            Navigator.pop(context);
          },
          child: const Text("Submit", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      drawer: _buildDrawer(isDarkMode),
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: Column(children: [const Text('Mindful Haven', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(_detectedMood, style: const TextStyle(fontSize: 11, color: myPrimaryColor))]),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.shield_moon_outlined, color: myPrimaryColor), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencySupportScreen())))],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(_user?.uid).collection('history').doc(_currentChatId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: myPrimaryColor));
                
                final docs = snapshot.data!.docs;

                // ➕ 👇 YEH NAYA CODE HAI: Empty State Setup 👇 ➕
                if (docs.isEmpty) {
                  return Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "Welcome to "),
              TextSpan(
                text: "Mindful Haven",
                style: TextStyle(
                  color: myPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const TextSpan(text: " \n\n"),
              const TextSpan(
                text: "Take a deep breath. What's heavy on your heart or mind today? I am here to listen, always.",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
                }

                // 🔄 BAKI AAPKA LISTVIEW WAISE HI CHALAY GA
                return ListView.builder(
                  controller: _scrollController, reverse: true, padding: const EdgeInsets.all(16), itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    String decryptedText = EncryptionHelper.decryptText(data['text'] ?? '');
                    return _ChatBubble(
                      text: decryptedText, isUser: data['isUser'] ?? false, isDarkMode: isDarkMode, 
                      onEdit: () { _controller.text = decryptedText; setState(() => _editingMessageId = docs[index].id); },
                      onFeedback: (isPositive) => _showFeedbackDialog(isPositive, decryptedText), 
                    );
                  },
                );
              },
            ),
          ),
          if (_isTyping) const Padding(padding: EdgeInsets.only(left: 20, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text("Mindful Friend is thinking...", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)))),
          _buildInputArea(isDarkMode),
          if (_showEmoji) _buildEmojiPicker(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Row(
        children: [
          IconButton(icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.grey), onPressed: () { FocusScope.of(context).unfocus(); setState(() => _showEmoji = !_showEmoji); }),
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(25)), child: TextField(controller: _controller, onTap: () => setState(() => _showEmoji = false), style: TextStyle(color: isDarkMode ? Colors.white : Colors.black), decoration: InputDecoration(hintText: _editingMessageId != null ? 'Edit message...' : 'Talk to friend...', border: InputBorder.none)))),
          IconButton(icon: Icon(_editingMessageId != null ? Icons.check_circle : Icons.send_rounded, color: _isTyping ? Colors.grey : myPrimaryColor), onPressed: _isTyping ? null : _sendMessage),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker(bool isDarkMode) {
    return SizedBox(height: 250, child: EmojiPicker(onEmojiSelected: (category, emoji) => _controller.text += emoji.emoji, config: Config(emojiViewConfig: EmojiViewConfig(backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF2F2F2)))));
  }

  Widget _buildDrawer(bool isDarkMode) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 10, right: 10, bottom: 10),
            color: isDarkMode ? Colors.grey[900] : const Color(0xFFF8FAFD),
            child: _isSearching
                ? TextField(
                    controller: _searchController, autofocus: true, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(hintText: "Search conversations...", prefixIcon: const Icon(Icons.search, color: myPrimaryColor), suffixIcon: IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () { setState(() { _isSearching = false; _searchQuery = ""; _searchController.clear(); }); })),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  )
                : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(icon: const Icon(Icons.menu_open_rounded, color: myPrimaryColor), onPressed: () => Navigator.pop(context)), IconButton(icon: const Icon(Icons.search_rounded, color: myPrimaryColor), onPressed: () => setState(() => _isSearching = true))]),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: InkWell(
              onTap: () { setState(() { _currentChatId = DateTime.now().millisecondsSinceEpoch.toString(); _detectedMood = "Mood Detection"; }); Navigator.pop(context); },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15), decoration: BoxDecoration(color: myPrimaryColor, borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add, color: Colors.white), SizedBox(width: 10), Text("New Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Text("Recent Chats", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(_user?.uid).collection('history').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                var filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String decryptedTitle = EncryptionHelper.decryptText(data['title'] ?? "");
                  return decryptedTitle.toLowerCase().contains(_searchQuery);
                }).toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    bool isSelected = _currentChatId == filteredDocs[index].id;
                    String chatId = filteredDocs[index].id;
                    String displayTitle = EncryptionHelper.decryptText(data['title'] ?? "");
                    if (displayTitle.isEmpty) displayTitle = "Untitled Chat";
                    
                    return ListTile(
                      tileColor: isSelected ? myPrimaryColor.withOpacity(0.1) : Colors.transparent,
                      title: Text(displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      onTap: () { setState(() => _currentChatId = chatId); Navigator.pop(context); },
                      onLongPress: () {
                        showDialog(context: context, builder: (context) => AlertDialog(
                          title: const Text("Delete Chat?"), content: const Text("Do you want to delete this chat permanently?"),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")), TextButton(onPressed: () { _deleteChat(chatId); Navigator.pop(context); }, child: const Text("Yes", style: TextStyle(color: Colors.red)))],
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser, isDarkMode;
  final VoidCallback onEdit;
  final Function(bool isPositive) onFeedback;
const _ChatBubble({
    required this.text, 
    required this.isUser, 
    required this.isDarkMode, 
    required this.onEdit,
    required this.onFeedback, // Require karein
  });

  @override
  Widget build(BuildContext context) {
    String lowerText = text.toLowerCase();
    bool showBreathingButton = !isUser && (lowerText.contains("breathing") || lowerText.contains("saans") || lowerText.contains("exercise"));
    bool showYoutubeButton = !isUser && (lowerText.contains("audio") || lowerText.contains("naat") || lowerText.contains("relax") || lowerText.contains("sukoon"));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isUser) ...[
                IconButton(icon: const Icon(Icons.copy, size: 14, color: Colors.grey), onPressed: () { Clipboard.setData(ClipboardData(text: text)); }),
                IconButton(icon: const Icon(Icons.edit, size: 14, color: Colors.grey), onPressed: onEdit),
              ],
           Flexible(
  child: Container(
    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: isUser ? myPrimaryColor : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200]), 
      borderRadius: BorderRadius.circular(15)
    ),
    // Yahan Text ko replace kar diya:
    child: MarkdownBody(
  data: text,
  styleSheet: MarkdownStyleSheet(
    p: TextStyle(
      color: isUser || isDarkMode ? Colors.white : Colors.black87,
      fontSize: 15,
    ),
    strong: TextStyle(
      fontWeight: FontWeight.bold,
      color: isUser || isDarkMode ? Colors.white : Colors.black, 
    ),
    listBullet: TextStyle(
      // Make sure 'myPrimaryColor' is defined in your variables
      color: isUser ? Colors.white : (myPrimaryColor ?? Colors.blue),
    ),
  ),
),
  ),
),
            ],
          ),
        if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbs Up
                  IconButton(
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey), 
                    onPressed: () => onFeedback(true), // Callback call karein
                  ),
                  // Thumbs Down
                  IconButton(
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 16, color: Colors.grey), 
                    onPressed: () => onFeedback(false), // Callback call karein
                  ),
                  IconButton(icon: const Icon(Icons.copy, size: 16, color: Colors.grey), onPressed: () { Clipboard.setData(ClipboardData(text: text)); }),
                ],
              ),
            ),
          ],
          if (showBreathingButton) Padding(padding: const EdgeInsets.only(left: 5, bottom: 8), child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingScreen())), icon: const Icon(Icons.air, size: 18), label: const Text("Go to Breathing Area"), style: ElevatedButton.styleFrom(backgroundColor: myPrimaryColor, foregroundColor: Colors.white, shape: const StadiumBorder()))),
          if (showYoutubeButton) 
            Padding(
              padding: const EdgeInsets.only(left: 5, bottom: 8), 
              child: ElevatedButton.icon(
                onPressed: () async { 
                  final String youtubeUrl = dotenv.env['RELAXATION_VIDEO_URL'] ?? "https://www.youtube.com";
                  final Uri url = Uri.parse(youtubeUrl); 
                  if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
                }, 
                icon: const Icon(Icons.play_circle_fill, size: 18), label: const Text("Listen to Peaceful Audio"), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: const StadiumBorder()),
              ),
            ),
        ],
      ),
    );
  }
}