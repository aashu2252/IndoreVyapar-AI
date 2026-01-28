import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../transaction_card.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerName;

  const CustomerDetailScreen({super.key, required this.customerName});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = "All"; // All, Udhaar, Jama

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsAppReminder(double balance) async {
    final message = "Namaste ${widget.customerName}, aapka purana hisaab ₹${balance.abs()} baaki hai. Kripya payment karein. - IndoreVyapar Shop";
    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _confirmDelete(String docId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Delete Transaction?", style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          "Are you sure you want to delete this history item? This action cannot be undone.",
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              try {
                await FirebaseFirestore.instance.collection('transactions').doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Transaction deleted successfully"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting: $e")),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Use Theme
      appBar: AppBar(
        title: Text(widget.customerName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // 🔍 SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.inter(color: Colors.white),
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search transactions...",
                    hintStyle: GoogleFonts.inter(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0), // Slim height
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 🏷️ FILTER CHIPS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ["All", "Udhaar", "Jama"].map((filter) {
                    final isSelected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _filter = filter),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        selectedColor: Colors.indigoAccent.withOpacity(0.2),
                        checkmarkColor: Colors.indigoAccent,
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? Colors.indigoAccent : Colors.white60,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.indigoAccent.withOpacity(0.5) : Colors.transparent
                          )
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('customer_name', isEqualTo: widget.customerName)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          
          // 1. CLIENT-SIDE FILTERING & SEARCH
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['transaction_type'];
            final summary = (data['summary_hindi'] ?? '').toString().toLowerCase();
            final search = _searchCtrl.text.toLowerCase();

            // Filter Logic
            if (_filter == "Udhaar" && type != "CREDIT_SALE") return false;
            if (_filter == "Jama" && type != "PAYMENT") return false;

            // Search Logic
            if (search.isNotEmpty && !summary.contains(search)) return false;

            return true;
          }).toList();

          if (docs.isEmpty) {
            return Center(child: Text("No transactions match.", style: GoogleFonts.inter(color: Colors.white38)));
          }

          // 2. CALCULATE BALANCE & GROUP BY DATE
          double balance = 0;
          Map<String, List<QueryDocumentSnapshot>> grouped = {};
          
          for (var doc in snapshot.data!.docs) { // Calculate balance on ALL docs, not filtered
             final data = doc.data() as Map<String, dynamic>;
             final dynamic rawAmount = data['amount'];
             double amount = (rawAmount is int) ? rawAmount.toDouble() : (rawAmount as double? ?? 0.0);
             if (data['transaction_type'] == 'CREDIT_SALE') balance += amount;
             else if (data['transaction_type'] == 'PAYMENT') balance -= amount;
          }

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp? ts = data['timestamp'];
            String dateKey = "Unknown Date";
            if (ts != null) {
              final date = ts.toDate();
              final now = DateTime.now();
              if (date.year == now.year && date.month == now.month && date.day == now.day) {
                dateKey = "Today";
              } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
                dateKey = "Yesterday";
              } else {
                dateKey = DateFormat('dd MMM yyyy').format(date);
              }
            }
            if (grouped[dateKey] == null) grouped[dateKey] = [];
            grouped[dateKey]!.add(doc);
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  String dateKey = grouped.keys.elementAt(index);
                  List<QueryDocumentSnapshot> dayDocs = grouped[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DATE HEADER
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          dateKey.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white38, 
                            fontSize: 12, 
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0
                          ),
                        ),
                      ),
                      // LIST ITEMS
                      ...dayDocs.map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onLongPress: () => _confirmDelete(doc.id),
                          child: TransactionCard(data: doc.data() as Map<String, dynamic>),
                        ),
                      )).toList(),
                    ],
                  );
                },
              ),

              // 🟢 PENDING BADGE / FAB
              if (balance > 0)
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: () => _sendWhatsAppReminder(balance),
                    backgroundColor: Colors.green.shade700,
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: Row(
                      children: [
                         Text("PAYMENT PENDING  ", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                         Text("₹${balance.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
