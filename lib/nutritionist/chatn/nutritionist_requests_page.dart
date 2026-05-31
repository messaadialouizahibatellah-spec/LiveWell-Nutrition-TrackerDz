import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionistRequestsPage extends StatefulWidget {
  final List<Map<String, String>>? requests;

  const NutritionistRequestsPage({
    super.key,
    this.requests,
  });

  @override
  State<NutritionistRequestsPage> createState() =>
      _NutritionistRequestsPageState();
}

class _NutritionistRequestsPageState extends State<NutritionistRequestsPage> {
  Future<void> _acceptRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection("message_requests")
        .doc(requestId)
        .update({
      "status": "accepted",
      "acceptedAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Request accepted"),
        backgroundColor: Color(0xFF2E7D5A),
      ),
    );
  }

  Future<void> _rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection("message_requests")
        .doc(requestId)
        .update({
      "status": "rejected",
      "rejectedAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Request rejected"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nutritionist = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)),
        title: const Text(
          "Message Requests",
          style: TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: nutritionist == null
          ? const Center(
        child: Text(
          "No nutritionist logged in",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("message_requests")
            .where("nutritionistUid", isEqualTo: nutritionist.uid)
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "No requests for now",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = requests[index];
              final request = doc.data() as Map<String, dynamic>;

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFA8E6CF)
                              .withOpacity(0.35),
                          child: Text(
                            (request["userName"] ?? "U")
                                .toString()
                                .substring(0, 1),
                            style: const TextStyle(
                              color: Color(0xFF2E7D5A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request["userName"] ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D5A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request["message"] ??
                                    "Wants to contact you",
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _acceptRequest(doc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D5A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              "Accept",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _rejectRequest(doc.id),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFFFA94D),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              "Reject",
                              style: TextStyle(
                                color: Color(0xFFFFA94D),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}