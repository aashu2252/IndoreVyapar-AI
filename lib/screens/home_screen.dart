import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../gemini_helper.dart';

import 'package:flutter_tts/flutter_tts.dart';
import '../transaction_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final GeminiHelper _gemini = GeminiHelper();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();

  // Animation Controller for "Breathing" Mic
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  bool _isListening = false;
  bool _isProcessing = false;
  String _statusMessage = "Tap mic to speak...";

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    // Initialize Animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    await _speech.initialize();
    setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage("hi-IN"); // Hindi India
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _startListening() async {
    if (!_isProcessing) {
      await _speech.listen(onResult: (result) {
        setState(() {
          _statusMessage = result.recognizedWords;
        });
      });
      setState(() {
        _isListening = true;
        _animController.repeat(reverse: true); // Start Breathing
      });
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _animController.stop(); // Stop Breathing
      _animController.value = 1.0; // Reset
    });

    final spokenText = _speech.lastRecognizedWords;
    if (spokenText.isNotEmpty) {
      await _processTransaction(spokenText, null);
    } else {
      setState(() => _statusMessage = "No speech detected.");
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _isProcessing = true;
        _statusMessage = "Analyzing Bill...";
      });
      final bytes = await photo.readAsBytes();
      await _processTransaction("Analyze this bill image", bytes);
    }
  }

  Future<void> _processTransaction(String text, Uint8List? imageBytes) async {
    String? jsonString = await _gemini.processInput(text, imageBytes);

    if (jsonString != null) {
      try {
        jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
        Map<String, dynamic> data = jsonDecode(jsonString);

        // Normalize Customer Name (Simple Title Case)
        String custName = data['customer_name'] ?? 'Unknown';
        if (custName.isNotEmpty && custName.length > 1) {
          custName = "${custName[0].toUpperCase()}${custName.substring(1)}";
        }

        DocumentReference docRef = await FirebaseFirestore.instance.collection('transactions').add({
          ...data,
          'customer_name': custName,
          'timestamp': FieldValue.serverTimestamp(),
        });

        String summary = data['summary_hindi'];
        setState(() => _statusMessage = "Saved: $summary");
        _speak(summary); // Audio Feedback

        // Show Snackbar with EDIT button
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.indigo.shade900,
            content: Text(summary, style: const TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'EDIT',
              textColor: Colors.orangeAccent,
              onPressed: () => _showEditDialog(docRef, data),
            ),
          ));
        }
      } catch (e) {
        setState(() => _statusMessage = "Error saving: ${e.toString()}");
      }
    } else {
      setState(() => _statusMessage = "Gemini didn't understand.");
    }
    setState(() => _isProcessing = false);
  }

  void _showEditDialog(DocumentReference docRef, Map<String, dynamic> data) {
    TextEditingController amountCtrl = TextEditingController(text: data['amount'].toString());
    TextEditingController nameCtrl = TextEditingController(text: data['customer_name']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.indigo.shade50,
        title: const Text("Edit Transaction"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Customer Name")),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () async {
              await docRef.update({
                'customer_name': nameCtrl.text,
                'amount': double.tryParse(amountCtrl.text) ?? 0,
              });
              Navigator.pop(context);
              setState(() => _statusMessage = "Transaction Updated.");
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("IndoreVyapar AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Uses global scaffold color
        elevation: 0,
      ),
      body: Container(
        // Background controlled by main.dart theme (Color 0xFF101010)
        child: Column(
          children: [
            const SizedBox(height: 100), // Spacing for AppBar

            // 📝 LIVE TRANSCRIPTION AREA
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), // Glassmorphism
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Stack(
                children: [
                   if (_isProcessing)
                     const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
                   else
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),

            // 📜 RECENT TRANSACTIONS (Glass Cards)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('transactions').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white30));
                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100), // Space for Floating Button
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      // Custom Glass Card
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TransactionCard(data: data), // We'll need to update TransactionCard to look good on dark mode too, or it might just work if text is black.
                        // Note: TransactionCard handles its own text styles. If it uses default black text, we might need to change it later.
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 🎤 THE HERO INTERFACE (Bottom)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        width: double.infinity, 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 📷 CAMERA BUTTON (Left Side)
            FloatingActionButton(
              heroTag: "cam_btn",
              backgroundColor: Colors.white24,
              elevation: 0,
              onPressed: _pickImage,
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),

            // 🎙️ BREATHING MIC CORE (Center)
            GestureDetector(
              onLongPress: _startListening,
              onLongPressUp: _stopListening,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                        ? [Colors.orangeAccent, Colors.deepOrange]
                        : [Colors.indigoAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isListening ? Colors.orangeAccent.withOpacity(0.6) : Colors.indigoAccent.withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ]
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 35
                  ),
                ),
              ),
            ),

            // 👻 EMPTY DUMMY BOX (Right Side Balance)
            const SizedBox(width: 56, height: 56), // Matches FAB size
          ],
        ),
      ),
    );
  }
}
