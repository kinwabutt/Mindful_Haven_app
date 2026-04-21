import 'dart:convert';
import 'dart:async';
import 'dart:math'; // Added for Random tips
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:encrypt/encrypt.dart' as encrypt; // For AES-256
import 'package:telephony/telephony.dart'; // <--- AUTOMATED SMS PACKAGE
import 'emergency_support_screen.dart';
import 'breathing_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
const Color myPrimaryColor = Color(0xFF26C6DA); // Teal Color
// Ab code mein sirf ye nazar aayega:
final String GEMINI_API_KEY = dotenv.env['GEMINI_API_KEY'] ?? "";
final String GEMINI_MODEL = dotenv.env['GEMINI_MODEL_NAME'] ?? "default-model";
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
  final Telephony telephony = Telephony.instance;
  void _sendAutomatedSMS(String message) async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted && _user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          var contact = data['emergency_contact'];  
          if (contact != null) {
            String emergencyNumber = contact['phone'] ?? "";
            bool isAutoSMSOn = contact['auto_sms'] ?? true;
            if (emergencyNumber.isNotEmpty && isAutoSMSOn) {
              telephony.sendSms(
                to: emergencyNumber,
                message: "Mindful Haven Alert: Emergency detected. User message: '$message'",
                statusListener: (SendStatus status) {
                  debugPrint("SMS Status: ${status.name}");
                }
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching emergency number: $e");
      }
    }
  }
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isTyping = false;
  bool _showEmoji = false;
  late String _currentChatId;
  Timer? _inactivityTimer;
  String _detectedMood = "Mood Detection";
  String? _editingMessageId;
 // Ab ye value seedha .env file se aaye gi
final String gemmaBackendUrl = dotenv.env['GEMMA_BACKEND_URL'] ?? "";
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
    _startInactivityTimer();
    _requestPermissionsAtStart();
  }
  void _requestPermissionsAtStart() async {
    try {
      await telephony.requestPhoneAndSmsPermissions;
    } catch (e) {
      debugPrint("Permission request error: $e");
    }
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
  String _mapMoodToField(String mood) {
    String m = mood.toLowerCase().trim();
    if (['joy', 'happy', 'surprise', 'love'].contains(m)) return "happy_count";
    if (['stress', 'fear', 'anger', 'disgust', 'anxiety', 'tense'].contains(m)) return "stress_count";
    if (['sadness', 'sad', 'low', 'grief'].contains(m)) return "sad_count";
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
    List<String> selectedTips = moodTips[moodKey] ?? moodTips['neutral']!;
    selectedTips.shuffle(); 
    String randomTip = selectedTips.first;
    String fieldName = _mapMoodToField(mood);
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
      Map<String, dynamic> updateData = {
        'last_mood_update': FieldValue.serverTimestamp(),
        'last_mood_detected': mood,
        'latest_tip': randomTip,
      };
      if (fieldName.isNotEmpty) updateData[fieldName] = FieldValue.increment(1);
      await userRef.update(updateData);
      await userRef.collection('mood_history').add({
        'mood': mood,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Tip and History Updated: $randomTip");
    } catch (e) {
      debugPrint("❌ Stats Update Error: $e");
    }
  }
  Future<String> _analyzeWithBERT(String text) async {
    setState(() => _detectedMood = "Analyzing Mood...");
    try {
      final response = await http.post(
            Uri.parse(gemmaBackendUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"text": text}),
          ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        String mood = responseBody['emotion'] ?? "Neutral";
        setState(() => _detectedMood = "Current Mood: $mood");
        await _updateEmotionStats(mood);
        return mood;
      }
    } catch (e) {
      debugPrint("BERT Backend Error: $e");
    }
    setState(() => _detectedMood = "Mood: Neutral");
    return "Neutral";
  }
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && !_isTyping) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Main yahan hoon, agar aap kuch kehna chahein...")),
        );
      }
    });
  }
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _user == null || _isTyping) return;
    final messagesRef = FirebaseFirestore.instance
        .collection('chats').doc(_user!.uid).collection('history').doc(_currentChatId).collection('messages');
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
      await FirebaseFirestore.instance.collection('chats').doc(_user!.uid).collection('history').doc(_currentChatId).set({
            'title': EncryptionHelper.encryptText(text.length > 30 ? "${text.substring(0, 27)}..." : text),
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      String moodResult = await _analyzeWithBERT(text);
      await messagesRef.add({
        'text': encryptedText,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!["emergency", "help", "suicide", "marne", "kill", "jaan khatam"].any((w) => text.toLowerCase().contains(w))) {
        await _getAIResponse(text, messagesRef, mood: moodResult);
      } else {
        _sendAutomatedSMS(text); 
        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencySupportScreen()));
        setState(() => _isTyping = false);
      }
    }
    _startInactivityTimer();
  }
  Future<void> _getAIResponse(String text, CollectionReference messagesRef, {String mood = "Neutral"}) async {
    try {
      final prevMessages = await messagesRef.orderBy('timestamp', descending: true).limit(8).get();
      String systemPrompt = """
You are 'Mindful Friend', a kind emotional support AI. 
User current mood: $mood. 
STRICT RULES:
1. Mix Roman Urdu and English (Hinglish/Urdu-ish style).
2. Use deep empathy and keep responses short, like a close friend.
3. MEDICAL SAFETY: You are NOT a doctor or therapist. 
4. NEVER prescribe any medicine, pills, or clinical treatments (e.g., antidepressants, Panadol, etc.).
5. NEVER provide a medical diagnosis (e.g., 'You have Depression').
6. If the user asks for medicine or a diagnosis, politely refuse: 'Main ek AI companion hoon, doctor nahi. Behtar hai aap kisi expert se consult karein.'
""";
      List<Map<String, dynamic>> chatHistory = [{"role": "user", "parts": [{"text": systemPrompt}]}];
      for (var m in prevMessages.docs.reversed) {
        chatHistory.add({
          "role": m['isUser'] ? "user" : "model", 
          "parts": [{"text": EncryptionHelper.decryptText(m['text'] ?? "")}]
        });
      }
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$GEMINI_MODEL:generateContent?key=$GEMINI_API_KEY"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"contents": chatHistory}),
      ).timeout(const Duration(seconds: 25));
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
      }
    } catch (e) { 
      debugPrint("Gemini Catch Error: $e"); 
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
        setState(() {
          _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
          _detectedMood = "Mood Detection";
        });
      }
    } catch (e) { debugPrint("Delete Error: $e"); }
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
                return ListView.builder(
                  controller: _scrollController, reverse: true, padding: const EdgeInsets.all(16), itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    String decryptedText = EncryptionHelper.decryptText(data['text'] ?? '');
                    return _ChatBubble(
                      text: decryptedText, 
                      isUser: data['isUser'] ?? false, 
                      isDarkMode: isDarkMode, 
                      onEdit: () { 
                        _controller.text = decryptedText; 
                        setState(() => _editingMessageId = docs[index].id); 
                      }
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text("Recent Chats", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    bool isSelected = _currentChatId == filteredDocs[index].id;
                    String chatId = filteredDocs[index].id;
                    
                    String encryptedTitle = data['title'] ?? "";
                    String displayTitle;
                    
                    try {
                      displayTitle = EncryptionHelper.decryptText(encryptedTitle);
                      if (displayTitle.isEmpty) displayTitle = "Untitled Chat";
                    } catch (e) {
                      displayTitle = "Chat History"; 
                    }
                    
                    return ListTile(
                      tileColor: isSelected ? myPrimaryColor.withOpacity(0.1) : Colors.transparent,
                      title: Text(
                        displayTitle, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        )
                      ),
                      onTap: () { 
                        setState(() => _currentChatId = chatId); 
                        Navigator.pop(context); 
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Delete Chat?"),
                            content: const Text("Do you want to delete this chat permanently?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("No", style: TextStyle(color: Colors.grey))),
                              TextButton(onPressed: () { _deleteChat(chatId); Navigator.pop(context); }, child: const Text("Yes", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
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
  const _ChatBubble({required this.text, required this.isUser, required this.isDarkMode, required this.onEdit});
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
                IconButton(
                  icon: const Icon(Icons.copy, size: 14, color: Colors.grey), 
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Text Copied!"), duration: Duration(seconds: 1)));
                  }
                ),
                IconButton(icon: const Icon(Icons.edit, size: 14, color: Colors.grey), onPressed: onEdit),
              ],
              Flexible( // Added Flexible to prevent right-side overflow
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: isUser ? myPrimaryColor : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200]), borderRadius: BorderRadius.circular(15)),
                  child: Text(text, style: TextStyle(color: isUser || isDarkMode ? Colors.white : Colors.black87)),
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
                  IconButton(
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Glad you liked it!"), duration: Duration(seconds: 1))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 16, color: Colors.grey),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanks for feedback, I'll improve."), duration: Duration(seconds: 1))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Response Copied!"), duration: Duration(seconds: 1)));
                    },
                  ),
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
        // .env se URL uthao, agar na mile toh fallback as a default link
        final String youtubeUrl = dotenv.env['RELAXATION_VIDEO_URL'] ?? "https://www.youtube.com";
        final Uri url = Uri.parse(youtubeUrl); 
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication); 
        } else {
          // Agar link na khule toh error show kar do
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch YouTube"))
          );
        }
      }, 
      icon: const Icon(Icons.play_circle_fill, size: 18), 
      label: const Text("Listen to Peaceful Audio"), 
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent, 
        foregroundColor: Colors.white, 
        shape: const StadiumBorder()
      ),
    ),
  ),
        ],
      ),
    );
  }
}