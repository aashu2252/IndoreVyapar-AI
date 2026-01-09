import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const TransactionCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 1. Determine Color: Red for Credit (Udhaar), Green for Payment
    final type = data['transaction_type'];
    final bool isCredit = type == 'CREDIT_SALE';
    final color = isCredit ? Colors.redAccent.shade100 : Colors.greenAccent.shade400; // Softer/Precise colors for Dark Mode
    
    // 2. Format Date (Safely handle nulls)
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final dateStr = ts != null 
        ? DateFormat('hh:mm a').format(ts.toDate()) // Time only, as date headers will handle the day
        : 'Just now';

    // 3. Customer Name & Summary
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Subtle off-white for dark mode
        borderRadius: BorderRadius.circular(8), // Standard/Corporate 8px
        border: Border.all(color: Colors.white10, width: 0.5), // Thinner borders
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon (Subtle)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isCredit ? Icons.arrow_outward : Icons.arrow_downward,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Name & Summary (Hero Name)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['customer_name'] ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, 
                    color: Colors.white,
                    fontSize: 16
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data['summary_hindi'] ?? '...', 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)
                ),
              ],
            ),
          ),

          // Amount & Time (Hero Amount)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${data['amount'] ?? 0}",
                style: GoogleFonts.inter(
                  color: color, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 16
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr, 
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white30)
              ),
            ],
          ),
        ],
      ),
    );
  }
}