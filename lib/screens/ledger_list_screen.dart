import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_detail_screen.dart';

class LedgerListScreen extends StatelessWidget {
  const LedgerListScreen({super.key});

  @override
  Future<void> _addMockData() async {
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('transactions');

    final mockData = [
      {'customer_name': 'Ramesh Bhai', 'amount': 500, 'transaction_type': 'CREDIT_SALE', 'items': 'Shakar', 'summary_hindi': 'Ramesh Bhai - 500 ki Shakar (Udhaar)', 'timestamp': FieldValue.serverTimestamp()},
      {'customer_name': 'Suresh', 'amount': 200, 'transaction_type': 'PAYMENT', 'items': 'Cash', 'summary_hindi': 'Suresh ne 200 diye', 'timestamp': FieldValue.serverTimestamp()},
      {'customer_name': 'Mahesh', 'amount': 1000, 'transaction_type': 'CREDIT_SALE', 'items': 'Unknown', 'summary_hindi': 'Mahesh - 1000 baaki', 'timestamp': FieldValue.serverTimestamp()},
      {'customer_name': 'Ramesh Bhai', 'amount': 100, 'transaction_type': 'PAYMENT', 'items': 'Cash', 'summary_hindi': 'Ramesh ne 100 jama kiye', 'timestamp': FieldValue.serverTimestamp()},
    ];

    for (var data in mockData) {
      batch.set(collection.doc(), data);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text("Customer Ledger", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.orangeAccent),
            tooltip: 'Add Mock Data',
            onPressed: _addMockData,
          )
        ],
      ),
      body: Container(
        // Background controlled by main.dart theme
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snapshot.data!.docs;
            final Map<String, double> balances = {};

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['customer_name'] ?? 'Unknown';
              final dynamic rawAmount = data['amount'];
              double amount = 0.0;
              if (rawAmount is int) amount = rawAmount.toDouble();
              else if (rawAmount is double) amount = rawAmount;
              else if (rawAmount is String) amount = double.tryParse(rawAmount) ?? 0.0;

              final type = data['transaction_type'];
              if (type == 'CREDIT_SALE') balances[name] = (balances[name] ?? 0) + amount;
              else if (type == 'PAYMENT') balances[name] = (balances[name] ?? 0) - amount;
            }

            final customerList = balances.keys.toList();

            if (customerList.isEmpty) {
               return const Center(child: Text("No records found.", style: TextStyle(color: Colors.white54)));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 100, 0, 20), // Top padding for AppBar
              itemCount: customerList.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final name = customerList[index];
                final balance = balances[name] ?? 0;
                final bool isCredit = balance > 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCredit ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: TextStyle(color: isCredit ? Colors.redAccent : Colors.greenAccent)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  trailing: Text(
                    "₹${balance.abs().toStringAsFixed(2)}",
                    style: TextStyle(
                        color: isCredit ? Colors.redAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  subtitle: Text(
                      isCredit ? "Takes (Owes You)" : "Gives (Advance)",
                      style: const TextStyle(color: Colors.white54)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerName: name)),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
