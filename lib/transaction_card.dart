import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- I ADDED THIS LINE
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const TransactionCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 1. Determine Color: Red for Credit (Udhaar), Green for Payment
    final type = data['transaction_type'];
    final bool isCredit = type == 'CREDIT_SALE';
    final color = isCredit ? Colors.red : Colors.green;
    
    // 2. Format Date (Safely handle nulls)
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final dateStr = ts != null 
        ? DateFormat('dd MMM, hh:mm a').format(ts.toDate()) 
        : 'Just now';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isCredit ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        // 3. Customer Name & Summary
        title: Text(
          data['customer_name'] ?? 'Unknown Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['summary_hindi'] ?? '...', maxLines: 1),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        // 4. Amount
        trailing: Text(
          "₹${data['amount'] ?? 0}",
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.bold, 
            fontSize: 16
          ),
        ),
      ),
    );
  }
}