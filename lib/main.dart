import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';

// --- THEME CONSTANTS ---
const Color kBgDark = Color(0xFF0F172A); // Midnight Blue/Black
const Color kCardDark = Color(0xFF1E293B); // Lighter Card Color
const Color kPrimary = Color(0xFF6366F1); // Indigo Neon
const Color kAccent = Color(0xFFF43F5E); // Rose Neon for "Udhaar"
const Color kSuccess = Color(0xFF10B981); // Emerald Neon for "Jama"

class UltimateHomeScreen extends StatefulWidget {
  const UltimateHomeScreen({super.key});

  @override
  State<UltimateHomeScreen> createState() => _UltimateHomeScreenState();
}

class _UltimateHomeScreenState extends State<UltimateHomeScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  late AnimationController _micController;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  void toggleListening() async {
    if (isListening) {
      // STOP LISTENING (Click to Stop)
      await _speechToText.stop();
      setState(() => isListening = false);
    } else {
      // START LISTENING (Click to Start)
      setState(() => isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          // The "finalResult" check handles the auto-stop when you finish speaking
          if (result.finalResult) {
            setState(() => isListening = false);
            print("AI Heard: ${result.recognizedWords}"); 
            // TODO: Call your Parser logic here
          }
        },
        listenFor: const Duration(seconds: 30), // Keeps listening for up to 30 seconds
        pauseFor: const Duration(seconds: 3),   // Waits for 3 seconds of silence before stopping automatically
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      );
    }
  }

  @override
  void dispose() {
    _micController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [
          // 1. Ambient Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimary.withOpacity(0.2),
                blurRadius: 120,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccent.withOpacity(0.15),
                blurRadius: 100,
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 25),
                _buildDashboardCard(),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Recent Transactions", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Text("View All", style: GoogleFonts.outfit(color: kPrimary, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(child: _buildGlassList()),
              ],
            ),
          ),

          // 3. The Ultimate Floating Mic Interface
          _buildFloatingMicDock(),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Good Evening,", style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14)),
              Text("Gupta General Store", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kCardDark, kCardDark.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Udhaar (Market)", style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text("₹ 42,500", style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: kAccent, size: 14),
                    const SizedBox(width: 4),
                    Text("12%", style: GoogleFonts.outfit(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(child: _buildStatButton("To Collect", "₹ 12.5k", kAccent, Icons.download)),
              const SizedBox(width: 15),
              Expanded(child: _buildStatButton("Today's Sale", "₹ 8.4k", kSuccess, Icons.trending_up)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatButton(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: kBgDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text(label, style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGlassList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      itemCount: 8,
      itemBuilder: (context, index) {
        bool isCredit = index % 2 == 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isCredit ? kAccent.withOpacity(0.1) : kSuccess.withOpacity(0.1),
                radius: 22,
                child: Icon(isCredit ? Icons.person_remove : Icons.person_add, color: isCredit ? kAccent : kSuccess, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isCredit ? "Sharma Ji" : "Rahul Verma", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    Text(isCredit ? "2kg Sugar, 5L Oil" : "Cash Received", style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹${isCredit ? '540' : '200'}", style: GoogleFonts.outfit(color: isCredit ? kAccent : kSuccess, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("10:4${index} AM", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 10)),
                ],
              )
            ],
          ),
        ).animate().slideX(begin: 0.2, duration: 400.ms, delay: (index * 50).ms).fadeIn();
      },
    );
  }

  // ... inside class _UltimateHomeScreenState ...

  Widget _buildFloatingDock() {
    return Positioned(
      bottom: 30, left: 24, right: 24,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isListening ? 140 : 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: kCardGlass,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: kNeonPrimary.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: kNeonPrimary.withOpacity(isListening ? 0.4 : 0.1), 
              blurRadius: isListening ? 30 : 10,
              spreadRadius: 2
            ),
          ],
        ),
        child: isListening 
          ? Column(
              // ... (Keep your existing listening column code here) ...
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Listening...", style: GoogleFonts.outfit(color: Colors.white)).animate().fadeIn(),
                const SizedBox(height: 10),
                // Fake Waveform Animation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => 
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 5, height: 20,
                      decoration: BoxDecoration(color: kNeonPrimary, borderRadius: BorderRadius.circular(10)),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleY(begin: 0.5, end: 1.5, duration: (300 + i*100).ms)
                  ),
                ),
                // OPTIONAL: Add a text button to stop manually if preferred
                TextButton(onPressed: toggleListening, child: const Text("Stop", style: TextStyle(color: Colors.grey)))
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: (){}, icon: const Icon(Icons.qr_code_scanner, color: Colors.white)),
                
                // --- PASTE YOUR NEW CODE HERE (REPLACING THE OLD MIC BUTTON) ---
                GestureDetector(
                  onTap: toggleListening, 
                  child: Container(
                    height: 60, width: 60, 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isListening 
                          ? [Colors.redAccent, Colors.red] 
                          : [kNeonPrimary, const Color(0xFF818CF8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isListening ? Colors.redAccent.withOpacity(0.5) : kNeonPrimary.withOpacity(0.4), 
                          blurRadius: 15, 
                          spreadRadius: 2
                        )
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.stop : Icons.mic, 
                      color: Colors.white, 
                      size: 30
                    ),
                  ),
                ),
                // -------------------------------------------------------------
                
                IconButton(onPressed: (){}, icon: const Icon(Icons.history, color: Colors.white)),
              ],
            ),
      ),
    );
  }