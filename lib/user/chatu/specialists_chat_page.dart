import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'specialist_conversation_page.dart';

class SpecialistsChatPage extends StatelessWidget {
  const SpecialistsChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "No user logged in",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Color(0xFF2E7D5A),
        ),
        title: const Text(
          "Nutrition Specialists",
          style: TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("message_requests")
            .where("userUid", isEqualTo: user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final conversations = snapshot.data!.docs;

          if (conversations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No conversations yet.\nGo to Discover and send a message.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: conversations.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 12),

            itemBuilder: (context, index) {
              final item =
              conversations[index].data()
              as Map<String, dynamic>;

              final status =
                  item["status"] ?? "pending";
              final nutritionistUid =
                  item["nutritionistUid"] ?? "";

              final chatId =
                  "${user.uid}_$nutritionistUid";

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("specialist_chats")
                    .doc(chatId)
                    .collection("messages")
                    .where("senderType", isEqualTo: "nutritionist")
                    .where("seenByUser", isEqualTo: false)
                    .snapshots(),

                builder: (context, messageSnapshot) {

                  int unreadCount = 0;

                  if (messageSnapshot.hasData) {
                    unreadCount =
                        messageSnapshot.data!.docs.length;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(22),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SpecialistConversationPage(
                                specialistName:
                                item["nutritionistName"] ?? "",

                                specialty:
                                status == "accepted"
                                    ? "Conversation active"
                                    : "Waiting for acceptance",

                                nutritionistUid:
                                nutritionistUid,
                              ),
                        ),
                      );
                    },

                    child: Container(
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(22),

                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                            const Color(0xFFA8E6CF)
                                .withOpacity(0.35),

                            child: Text(
                              (item["nutritionistName"] ?? "N")
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),

                              style: const TextStyle(
                                color: Color(0xFF2E7D5A),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [
                                Text(
                                  item["nutritionistName"] ?? "",

                                  style: const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 16,
                                    color:
                                    Color(0xFF2E7D5A),
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  status == "accepted"
                                      ? "Conversation active"
                                      : "Waiting for acceptance",

                                  style: TextStyle(
                                    color:
                                    status == "accepted"
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (unreadCount > 0)
                            Container(
                              padding:
                              const EdgeInsets.all(8),

                              decoration:
                              const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),

                              child: Text(
                                unreadCount.toString(),

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            )
                          else if (status != "accepted")
                            const Icon(
                              Icons.access_time_rounded,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}