import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../transaction_card.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerName;

  const CustomerDetailScreen({super.key, required this.customerName});

  Future<void> _sendWhatsAppReminder(double balance) async {
    final message = "Namaste $customerName, aapka purana hisaab ₹${balance.abs()} baaki hai. Kripya payment karein. - IndoreVyapar Shop";
    final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customerName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('customer_name', isEqualTo: customerName)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No transactions found."));
          }

          // Calculate Total Balance
          double balance = 0;
          for (var doc in docs) {
             final data = doc.data() as Map<String, dynamic>;
             final dynamic rawAmount = data['amount'];
             double amount = 0.0;
             if (rawAmount is int) amount = rawAmount.toDouble();
             else if (rawAmount is double) amount = rawAmount;
             else if (rawAmount is String) amount = double.tryParse(rawAmount) ?? 0.0;

             if (data['transaction_type'] == 'CREDIT_SALE') {
               balance += amount;
             } else if (data['transaction_type'] == 'PAYMENT') {
               balance -= amount;
             }
          }

          return Scaffold( // Nested Scaffold for FAB
            body: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return TransactionCard(
                    data: docs[index].data() as Map<String, dynamic>);
              },
            ),
            floatingActionButton: balance > 0 // Only show if they owe money
                ? FloatingActionButton.extended(
                    onPressed: () => _sendWhatsAppReminder(balance),
                    backgroundColor: Colors.green,
                    icon: const Icon(Icons.message, color: Colors.white),
                    label: Text("Remind ₹${balance.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white)),
                  )
                : null,
          );
        },
      ),
    );
  }
}
