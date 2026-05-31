import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialistConversationPage extends StatefulWidget {
  final String specialistName;
  final String specialty;
  final String nutritionistUid;

  const SpecialistConversationPage({
    super.key,
    required this.specialistName,
    required this.specialty,
    required this.nutritionistUid,
  });

  @override
  State<SpecialistConversationPage> createState() =>
      _SpecialistConversationPageState();
}

class _SpecialistConversationPageState extends State<SpecialistConversationPage> {
  final TextEditingController messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  bool _shouldScrollToBottom = false;

  bool _showScrollToBottomBtn = false;

  int _newFromNutritionist = 0;

  final Set<String> _knownNutritionistMessageIds = <String>{};
  bool _messagesInitialized = false;

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    if (!mounted) return;

    setState(() {
      _newFromNutritionist = 0;
    });

    await _markNutritionistMessagesAsSeen();
    await FirebaseFirestore.instance
        .collection("message_requests")
        .doc(chatId)
        .set({"hasUnreadForUser": false}, SetOptions(merge: true));
  }

  String get chatId {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "user";
    return "${userId}_${widget.nutritionistUid}";
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
      "senderType": "user",
      "nutritionistUid": widget.nutritionistUid,
      "seenByNutritionist": false,
      "seenByUser": true,
      "time": Timestamp.now(),
    });

    if (!mounted) return;

    setState(() {
      _shouldScrollToBottom = true;
    });

    messageController.clear();
  }

  Future<void> _markNutritionistMessagesAsSeen() async {
    final messages = await FirebaseFirestore.instance
        .collection("specialist_chats")
        .doc(chatId)
        .collection("messages")
        .where("senderType", isEqualTo: "nutritionist")
        .where("seenByUser", isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({
        "seenByUser": true,
      });
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

      if (atBottom && _newFromNutritionist > 0) {
        _markNutritionistMessagesAsSeen();
        FirebaseFirestore.instance
            .collection("message_requests")
            .doc(chatId)
            .set({"hasUnreadForUser": false}, SetOptions(merge: true));

        setState(() {
          _newFromNutritionist = 0;
        });
      }
    });

    Future.delayed(
      const Duration(milliseconds: 500),
          () async {
        await _markNutritionistMessagesAsSeen();
        await FirebaseFirestore.instance
            .collection("message_requests")
            .doc(chatId)
            .set({
          "hasUnreadForUser": false,
        }, SetOptions(merge: true));
      },
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
              widget.specialistName,
              style: const TextStyle(
                color: Color(0xFF2E7D5A),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              widget.specialty,
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

                    final isAtBottom =
                        !_scrollController.hasClients || _scrollController.offset <= 40;

                    if (!_messagesInitialized) {
                      for (final d in docs) {
                        final data = d.data() as Map<String, dynamic>;
                        if (data["senderType"] == "nutritionist") {
                          _knownNutritionistMessageIds.add(d.id);
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
                        final isNutritionist = data["senderType"] == "nutritionist";

                        if (!isNutritionist) continue;

                        if (_knownNutritionistMessageIds.contains(change.doc.id)) {
                          continue;
                        }

                        _knownNutritionistMessageIds.add(change.doc.id);

                        if (!isAtBottom) {
                          newlyArrivedWhileUp++;
                        } else {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            change.doc.reference.update({"seenByUser": true});
                            FirebaseFirestore.instance
                                .collection("message_requests")
                                .doc(chatId)
                                .set({"hasUnreadForUser": false}, SetOptions(merge: true));
                          });
                        }
                      }

                      if (newlyArrivedWhileUp > 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;

                          setState(() {
                            _newFromNutritionist += newlyArrivedWhileUp;
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

                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(18),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final item = docs[index].data() as Map<String, dynamic>;
                        final isMe = item["senderId"] == currentUserId;

                        final timestamp = item["time"] as Timestamp?;
                        final time = timestamp != null
                            ? TimeOfDay.fromDateTime(timestamp.toDate()).format(context)
                            : "";

                        return Align(
                          alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF2E7D5A) : Colors.white,
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
                              crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["text"] ?? "",
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isMe ? Colors.white70 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
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
                            hintText: "Write a message...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 52,
                        height: 52,
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
                    if (_newFromNutritionist > 0)
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
                            _newFromNutritionist.toString(),
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