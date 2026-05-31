import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'nutritionist_conversation_page.dart';

class NutritionistChatPage extends StatelessWidget {
  final List<Map<String, String>>? users;

  const NutritionistChatPage({
    super.key,
    this.users,
  });

  @override
  Widget build(BuildContext context) {
    final nutritionist = FirebaseAuth.instance.currentUser;

    if (nutritionist == null) {
      return const Center(
        child: Text(
          "No nutritionist logged in",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("message_requests")
          .where("nutritionistUid", isEqualTo: nutritionist.uid)
          .where("status", isEqualTo: "accepted")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final acceptedUsers = snapshot.data!.docs;

        if (acceptedUsers.isEmpty) {
          return const Center(
            child: Text(
              "No active conversations yet",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: acceptedUsers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request =
            acceptedUsers[index].data() as Map<String, dynamic>;

            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NutritionistConversationPage(
                      userName: request["userName"] ?? "",
                      roomName: request["message"] ?? "Accepted request",
                      userUid: request["userUid"] ?? "",
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                      const Color(0xFFA8E6CF).withOpacity(0.4),
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
                            request["message"] ?? "Accepted request",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("specialist_chats")
                          .doc("${request["userUid"]}_${nutritionist.uid}")
                          .collection("messages")
                          .where("senderType", isEqualTo: "user")
                          .where("seenByNutritionist", isEqualTo: false)
                          .snapshots(),
                      builder: (context, unreadSnapshot) {
                        final unreadCount =
                            unreadSnapshot.data?.docs.length ?? 0;

                        if (unreadCount > 0) {
                          return Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        return const SizedBox(width: 24);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}