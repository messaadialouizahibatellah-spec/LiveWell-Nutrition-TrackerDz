import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalCardScannerPage extends StatefulWidget {
  const ProfessionalCardScannerPage({super.key});

  @override
  State<ProfessionalCardScannerPage> createState() =>
      _ProfessionalCardScannerPageState();
}

class _ProfessionalCardScannerPageState
    extends State<ProfessionalCardScannerPage> {
  bool scanned = false;

  Future<void> _checkCard(String code) async {
    if (scanned) return;

    scanned = true;

    final cleanCode = code.trim();

    final cardDoc = await FirebaseFirestore.instance
        .collection("professional_cards")
        .doc(cleanCode)
        .get();

    if (!cardDoc.exists) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Professional card not found"),
          backgroundColor: Colors.red,
        ),
      );

      scanned = false;
      return;
    }

    final data = cardDoc.data()!;

    if (data["isActive"] != true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This card is not active"),
          backgroundColor: Colors.red,
        ),
      );

      scanned = false;
      return;
    }

    if (!mounted) return;

    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D5A),
        title: const Text(
          "Scan Professional Card",
        ),
      ),

      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.first;

              final code = barcode.rawValue;

              if (code != null && code.isNotEmpty) {
                _checkCard(code);
              }
            },
          ),

          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFFFB74D),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          const Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Text(
              "Place the QR code inside the square",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}