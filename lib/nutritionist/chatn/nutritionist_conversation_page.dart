import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionistConversationPage extends StatefulWidget {
  final String userName;
  final String roomName;
  final String userUid;

  const NutritionistConversationPage({
    super.key,
    required this.userName,
    required this.roomName,
    required this.userUid,
  });

  @override
  State<NutritionistConversationPage> createState() =>
      _NutritionistConversationPageState();
}

class _NutritionistConversationPageState
    extends State<NutritionistConversationPage> {
  final TextEditingController messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  bool _shouldScrollToBottom = false;
  bool _showScrollToBottomBtn = false;
  int _newFromUser = 0;

  final Set<String> _knownUserMessageIds = <String>{};
  bool _messagesInitialized = false;

  String get chatId {
    final nutritionistId =
        FirebaseAuth.instance.currentUser?.uid ?? "nutritionist";

    return "${widget.userUid}_$nutritionistId";
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    if (!mounted) return;

    setState(() {
      _newFromUser = 0;
    });

    await _markUserMessagesAsSeen();
    await FirebaseFirestore.instance
        .collection("message_requests")
        .doc(chatId)
        .set({"hasUnreadForNutritionist": false}, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("specialist_chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "text": text,
      "senderId": user.uid,
      "senderType": "nutritionist",
      "nutritionistUid": user.uid,
      "userUid": widget.userUid,
      "seenByUser": false,
      "seenByNutritionist": true,
      "time": Timestamp.now(),
    });

    if (!mounted) return;

    setState(() {
      _shouldScrollToBottom = true;
    });

    messageController.clear();

    await FirebaseFirestore.instance.collection("message_requests").doc(chatId).set({
      "hasUnreadForUser": true,
    }, SetOptions(merge: true));
  }

  Future<void> _markUserMessagesAsSeen() async {
    final messages = await FirebaseFirestore.instance
        .collection("specialist_chats")
        .doc(chatId)
        .collection("messages")
        .where("senderType", isEqualTo: "user")
        .where("seenByNutritionist", isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({
        "seenByNutritionist": true,
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!mounted) return;

      final shouldShow =
          _scrollController.hasClients && _scrollController.offset > 80;

      if (shouldShow != _showScrollToBottomBtn) {
        setState(() {
          _showScrollToBottomBtn = shouldShow;
        });
      }

      final atBottom =
          !_scrollController.hasClients || _scrollController.offset <= 40;

      if (atBottom && _newFromUser > 0) {
        _markUserMessagesAsSeen();
        FirebaseFirestore.instance
            .collection("message_requests")
            .doc(chatId)
            .set({"hasUnreadForNutritionist": false}, SetOptions(merge: true));

        setState(() {
          _newFromUser = 0;
        });
      }
    });

    Future.delayed(
      const Duration(milliseconds: 500),
          () async {
        await _markUserMessagesAsSeen();
        await FirebaseFirestore.instance
            .collection("message_requests")
            .doc(chatId)
            .set({
          "hasUnreadForNutritionist": false,
        }, SetOptions(merge: true));
      },
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _messageBubble(Map<String, dynamic> message) {
    final bool isMe = message["isMe"] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2E7D5A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message["text"] ?? "",
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message["time"] ?? "",
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(
                color: Color(0xFF2E7D5A),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              widget.roomName,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("specialist_chats")
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

                    final qs = snapshot.data!;
                    final docs = qs.docs;

                    final isAtBottom = !_scrollController.hasClients ||
                        _scrollController.offset <= 40;

                    if (!_messagesInitialized) {
                      for (final d in docs) {
                        final data = d.data() as Map<String, dynamic>;
                        if (data["senderType"] == "user") {
                          _knownUserMessageIds.add(d.id);
                        }
                      }
                      _messagesInitialized = true;
                    } else {
                      int newlyArrivedWhileUp = 0;

                      final double oldOffset = _scrollController.hasClients
                          ? _scrollController.offset
                          : 0.0;
                      final double oldMax = _scrollController.hasClients
                          ? _scrollController.position.maxScrollExtent
                          : 0.0;

                      for (final change in qs.docChanges) {
                        if (change.type != DocumentChangeType.added) continue;

                        final data = change.doc.data() as Map<String, dynamic>;
                        final isUser = data["senderType"] == "user";

                        if (!isUser) continue;

                        if (_knownUserMessageIds.contains(change.doc.id)) {
                          continue;
                        }

                        _knownUserMessageIds.add(change.doc.id);

                        if (!isAtBottom) {
                          newlyArrivedWhileUp++;
                        } else {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            change.doc.reference.update({
                              "seenByNutritionist": true,
                            });

                            FirebaseFirestore.instance
                                .collection("message_requests")
                                .doc(chatId)
                                .set({
                              "hasUnreadForNutritionist": false,
                            }, SetOptions(merge: true));
                          });
                        }
                      }

                      if (newlyArrivedWhileUp > 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;

                          setState(() {
                            _newFromUser += newlyArrivedWhileUp;
                          });

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_scrollController.hasClients) return;

                            final double newMax =
                                _scrollController.position.maxScrollExtent;
                            final double delta = newMax - oldMax;

                            final double target =
                            (oldOffset + delta).clamp(0.0, newMax);

                            _scrollController.jumpTo(target);
                          });
                        });
                      }
                    }

                    if (_shouldScrollToBottom) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                      _shouldScrollToBottom = false;
                    }

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No messages yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final item = docs[index].data() as Map<String, dynamic>;

                        final timestamp = item["time"] as Timestamp?;

                        return _messageBubble({
                          "text": item["text"] ?? "",
                          "isMe": item["senderId"] == currentUserId,
                          "time": timestamp != null
                              ? TimeOfDay.fromDateTime(
                            timestamp.toDate(),
                          ).format(context)
                              : "",
                        });
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F7F3),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: "Write a message...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF2E7D5A),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_showScrollToBottomBtn)
            Positioned(
              right: 18,
              bottom: 95,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 30,
                        color: Color(0xFF2E7D5A),
                      ),
                    ),
                    if (_newFromUser > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _newFromUser.toString(),
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
}