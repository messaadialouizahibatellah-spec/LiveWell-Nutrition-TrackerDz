import 'package:flutter/material.dart';
import 'specialists_chat_page.dart';
import 'community_chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../auth/loginpage.dart';

class UserChatPage extends StatefulWidget {
  const UserChatPage({super.key});

  @override
  State<UserChatPage> createState() => _UserChatPageState();

}

class _UserChatPageState extends State<UserChatPage> {
  void _showLoginRequired() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Login Required",
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 26),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8E6CF).withOpacity(0.28),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Color(0xFF2E7D5A),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Login Required",
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D5A),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Log in to unlock this feature",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D5A),
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text(
                          "Login Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Color(0xFF2E7D5A),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  int _countUnreadNutritionists(QuerySnapshot snapshot) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ids = <String>{};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data["userUid"] == currentUser?.uid &&
          data["senderType"] == "nutritionist" &&
          data["seenByUser"] == false) {
        ids.add(data["nutritionistUid"] ?? "");
      }
    }

    ids.remove("");
    return ids.length;
  }
  int _countUnreadCommunity(
      QuerySnapshot snapshot,
      Timestamp? lastSeen,
      ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || lastSeen == null) return 0;

    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final time = data["time"];

      if (data["senderId"] != currentUser.uid &&
          time is Timestamp &&
          time.compareTo(lastSeen) > 0) {
        count++;
      }
    }

    return count;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF8F7F3),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                const Text(
                  "Messages",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D5A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Choose where you want to chat",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 22),

                Expanded(
                  child: Column(
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("message_requests")
                            .where(
                          "userUid",
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? "",
                        )
                            .where("hasUnreadForUser", isEqualTo: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

                          return _chatCard(
                            context,
                            title: "Nutrition Specialists",
                            subtitle: "Chat with nutrition experts and follow your program.",
                            icon: Icons.support_agent_rounded,
                            topColor: const Color(0xFFA8E6CF),
                            bottomColor: const Color(0xFFEAF8F1),
                            notificationCount: count,
                            onTap: () {
                              final isGuest = FirebaseAuth.instance.currentUser == null;

                              if (isGuest) {
                                _showLoginRequired();
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SpecialistsChatPage(),
                                ),
                              );
                            },
                          );
                        },
                      ),

              const SizedBox(height: 18),

                      Builder(
                        builder: (context) {
                          final currentUser = FirebaseAuth.instance.currentUser;

                          if (currentUser == null) {
                            return _chatCard(
                              context,
                              title: "Community Chat",
                              subtitle: "Join the public chat with all app users.",
                              icon: Icons.forum_rounded,
                              topColor: const Color(0xFFFFD3A5),
                              bottomColor: const Color(0xFFFFF3E8),
                              notificationCount: 0,
                              onTap: () {
                                _showLoginRequired();
                              },
                            );
                          }

                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("users")
                                .doc(currentUser.uid)
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              final userData =
                              userSnapshot.data?.data() as Map<String, dynamic>?;

                              final lastSeen =
                              userData?["lastSeenCommunityAt"] as Timestamp?;

                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection("community_chats")
                                    .doc("global_community_chat")
                                    .collection("messages")
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final count = snapshot.hasData
                                      ? _countUnreadCommunity(snapshot.data!, lastSeen)
                                      : 0;

                                  return _chatCard(
                                    context,
                                    title: "Community Chat",
                                    subtitle: "Join the public chat with all app users.",
                                    icon: Icons.forum_rounded,
                                    topColor: const Color(0xFFFFD3A5),
                                    bottomColor: const Color(0xFFFFF3E8),
                                    notificationCount: count,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CommunityChatPage(),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color topColor,
        required Color bottomColor,
        required VoidCallback onTap,
        int notificationCount = 0,
      }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [topColor, bottomColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF2E7D5A),
                        size: 24,
                      ),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            notificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D5A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Text(
                    "Open chat",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D5A),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF2E7D5A),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}