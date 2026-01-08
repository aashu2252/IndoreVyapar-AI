import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart'; // New Package
import 'dart:convert';
import 'firebase_options.dart';
import 'gemini_helper.dart';
import 'transaction_card.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo), 
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToText _speech = SpeechToText(); // Phone's Ears
  final GeminiHelper _gemini = GeminiHelper(); // Phone's Brain
  
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusMessage = "Hold Mic to Speak";

  // Initialize Speech Engine
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
    setState(() {});
  }

  // START LISTENING
  void _startListening() async {
    if (!_isProcessing) {
      await _speech.listen(onResult: (result) {
        // As you speak, this updates live
        setState(() {
          _statusMessage = result.recognizedWords;
        });
      });
      setState(() => _isListening = true);
    }
  }

  // STOP & SEND TO GEMINI
  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    final spokenText = _speech.lastRecognizedWords;
    if (spokenText.isNotEmpty) {
      // Send the TEXT to Gemini
      String? jsonString = await _gemini.processText(spokenText);
      
      if (jsonString != null) {
        try {
          jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
          Map<String, dynamic> data = jsonDecode(jsonString);
          
          await FirebaseFirestore.instance.collection('transactions').add({
            ...data,
            'timestamp': FieldValue.serverTimestamp(),
          });
          setState(() => _statusMessage = "Saved: ${data['summary_hindi']}");
        } catch (e) {
          setState(() => _statusMessage = "Error saving data.");
        }
      } else {
        setState(() => _statusMessage = "Gemini didn't understand.");
      }
    } else {
      setState(() => _statusMessage = "I didn't hear anything.");
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("IndoreVyapar (Hybrid)")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            width: double.infinity,
            color: Colors.indigo.shade50,
            child: Text(
              _statusMessage, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return TransactionCard(data: docs[index].data() as Map<String, dynamic>);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        // HOLD TO SPEAK LOGIC
        onLongPress: _startListening,
        onLongPressUp: _stopListening,
        child: CircleAvatar(
          radius: 35,
          backgroundColor: _isListening ? Colors.red : Colors.indigo,
          child: Icon(_isProcessing ? Icons.hourglass_top : Icons.mic, color: Colors.white),
        ),
      ),
    );
  }
}