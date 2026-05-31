import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({super.key});

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _markCommunitySeen();

    _scrollController.addListener(() {
      if (_scrollController.offset > 200) {
        setState(() {
          showScrollButton = true;
        });
      } else {
        setState(() {
          showScrollButton = false;
          newMessagesCount = 0;
        });
      }
    });
  }
  bool showScrollButton = false;
  int newMessagesCount = 0;
  int lastMessageCount = 0;

  String get chatId => "global_community_chat";

  void _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;


    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final fullName = userDoc.data()?['name'] ?? "Anonymous";


    await FirebaseFirestore.instance
        .collection("community_chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "text": text,
      "senderId": user.uid,
      "senderName": fullName,
      "time": Timestamp.now(),
    });

    messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F7F3),
      body: Stack(
        children: [
          const _AnimatedCommunityBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("community_chats")
                        .doc(chatId)
                        .collection("messages")
                        .orderBy("time", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final messages = snapshot.data!.docs;
                      if (_scrollController.hasClients &&
                          _scrollController.offset > 200 &&
                          messages.length > lastMessageCount) {

                        newMessagesCount += (messages.length - lastMessageCount);
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() {});
                      });

                      lastMessageCount = messages.length;

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: EdgeInsets.only(
                          left: 18,
                          right: 18,
                          top: 10,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index].data() as Map<String, dynamic>;
                          final isMe = msg["senderId"] == user?.uid;
                          final time = (msg["time"] as Timestamp).toDate();
                          final formattedTime = "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}";

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF2E7D5A) : Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFFA94D),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            msg["senderName"] ?? "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2E7D5A),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (!isMe) const SizedBox(height: 5),
                                    Text(
                                      msg["text"] ?? "",
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe ? Colors.white70 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            ),
          ),
          if (showScrollButton)
            Positioned(
              right: 20,
              bottom: 90,
              child: GestureDetector(
                onTap: () {
                  _scrollToBottom();
                  setState(() {
                    newMessagesCount = 0;
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF2E7D5A),
                        size: 30,
                      ),
                    ),

                    if (newMessagesCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            newMessagesCount.toString(),
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
            ),
        ],
      ),
    );
  }
  Future<void> _markCommunitySeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({
      "lastSeenCommunityAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2E7D5A),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  "Community Chat",
                  style: TextStyle(
                    color: Color(0xFF2E7D5A),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Public discussion space",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Color(0xFFFFA94D),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  hintText: "Write to community...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D5A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCommunityBackground extends StatefulWidget {
  const _AnimatedCommunityBackground();

  @override
  State<_AnimatedCommunityBackground> createState() =>
      _AnimatedCommunityBackgroundState();
}

class _AnimatedCommunityBackgroundState
    extends State<_AnimatedCommunityBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF8F7F3),
                Color(0xFFF7F6F1),
                Color(0xFFF3F8F5),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50 + (t * 35),
                right: -20 + (t * 22),
                child: _circle(180, const Color(0xFFA8E6CF), 0.12),
              ),
              Positioned(
                top: 90 - (t * 24),
                left: -35 + (t * 18),
                child: _circle(140, const Color(0xFFFFD3A5), 0.10),
              ),
              Positioned(
                top: 250 + (t * 28),
                right: 25 - (t * 16),
                child: _circle(90, const Color(0xFFA8E6CF), 0.08),
              ),
              Positioned(
                bottom: 130 + (t * 24),
                left: -28 + (t * 18),
                child: _circle(160, const Color(0xFFA8E6CF), 0.10),
              ),
              Positioned(
                bottom: -40 + (t * 20),
                right: -20 + (t * 15),
                child: _circle(170, const Color(0xFFFFA94D), 0.12),
              ),
              ...List.generate(8, (index) {
                final dx = (index * 37.0) % size.width;
                final dy = 120 + (index * 95.0);

                return Positioned(
                  left: dx,
                  top: dy + math.sin((t * 2 * math.pi) + index) * 8,
                  child: _circle(
                    6,
                    index % 2 == 0
                        ? const Color(0xFFA8E6CF)
                        : const Color(0xFFFFD3A5),
                    0.10,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _circle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

}