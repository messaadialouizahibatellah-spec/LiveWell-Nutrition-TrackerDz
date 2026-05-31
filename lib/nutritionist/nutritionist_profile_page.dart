import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_post_page.dart';

class NutritionistProfilePage extends StatefulWidget {
  final Map<String, dynamic> nutritionistProfile;
  final List<Map<String, dynamic>> nutritionistPosts;

  final VoidCallback onEditProfile;
  final VoidCallback onCreatePost;
  final Function(int) onEditPost;
  final Function(int) onDeletePost;
  final Function(int) onLikePost;
  final Function(int) onSharePost;
  final Function(int, int) onDeleteComment;
  final Function(int, int, String) onReplyToComment;

  const NutritionistProfilePage({
    super.key,
    required this.nutritionistProfile,
    required this.nutritionistPosts,
    required this.onEditProfile,
    required this.onCreatePost,
    required this.onEditPost,
    required this.onDeletePost,
    required this.onLikePost,
    required this.onSharePost,
    required this.onDeleteComment,
    required this.onReplyToComment,
  });

  @override
  State<NutritionistProfilePage> createState() =>
      _NutritionistProfilePageState();
}

class _NutritionistProfilePageState extends State<NutritionistProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => FirebaseAuth.instance.currentUser;
  bool showReviews = false;

  String _firstLetter(dynamic value, String fallback) {
    final text = (value ?? "").toString().trim();
    if (text.isEmpty) return fallback;
    return text.substring(0, 1).toUpperCase();
  }

  Future<String> _getCurrentUserName() async {
    final user = currentUser;
    if (user == null) return "User";

    try {
      final nutritionistDoc =
      await _firestore.collection("nutritionists").doc(user.uid).get();

      if (nutritionistDoc.exists) {
        final data = nutritionistDoc.data();
        final name = data?["name"];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString();
        }
      }
    } catch (_) {}

    try {
      final userDoc = await _firestore.collection("users").doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final name = data?["name"];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString();
        }
      }
    } catch (_) {}

    return user.displayName ?? user.email ?? "User";
  }

  List<Map<String, dynamic>> _getComments(Map<String, dynamic> post) {
    final comments = post["comments"];

    if (comments is List) {
      return comments
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _getReplies(Map<String, dynamic> comment) {
    final replies = comment["replies"];

    if (replies is List) {
      return replies
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  bool _isPostOwner(Map<String, dynamic> post) {
    final user = currentUser;
    if (user == null) return false;

    return post["createdBy"] == user.uid;
  }

  bool _canDeleteComment(
      Map<String, dynamic> post,
      Map<String, dynamic> comment,
      ) {
    final user = currentUser;
    if (user == null) return false;

    final isPostOwner = post["createdBy"] == user.uid;
    final isCommentOwner = comment["userId"] == user.uid;

    return isPostOwner || isCommentOwner;
  }

  bool _canDeleteReply(
      Map<String, dynamic> post,
      Map<String, dynamic> reply,
      ) {
    final user = currentUser;
    if (user == null) return false;

    final isPostOwner = post["createdBy"] == user.uid;
    final isReplyOwner = reply["userId"] == user.uid;

    return isPostOwner || isReplyOwner;
  }

  Future<void> _saveComments(
      String postId,
      List<Map<String, dynamic>> comments,
      ) async {
    await _firestore.collection("posts").doc(postId).update({
      "comments": comments,
    });
  }

  Future<void> _toggleLikePost(Map<String, dynamic> post) async {
    final user = currentUser;
    if (user == null) return;

    final postId = post["postId"]?.toString();
    if (postId == null) return;

    final postRef = _firestore.collection("posts").doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);

      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};

      final likedBy = ((data["likedBy"] as List?) ?? [])
          .map((e) => e.toString())
          .toList();

      int likes = (data["likes"] as num?)?.toInt() ?? 0;

      if (likedBy.contains(user.uid)) {
        likedBy.remove(user.uid);
        if (likes > 0) likes--;
      } else {
        likedBy.add(user.uid);
        likes++;
      }

      transaction.update(postRef, {
        "likedBy": likedBy,
        "likes": likes,
      });
    });
  }

  Future<void> _sharePostReal(Map<String, dynamic> post) async {
    final postId = post["postId"]?.toString();

    if (postId == null) return;

    final postLink = "https://livewell.app/posts/$postId";

    final text =
        "${post["title"] ?? ""}\n\n${post["content"] ?? ""}\n\n$postLink";

    await Share.share(
      text,
      subject: post["title"]?.toString() ?? "Live Well Post",
    );

    await _firestore.collection("posts").doc(postId).update({
      "shares": FieldValue.increment(1),
    });
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final postId = post["postId"]?.toString();

    if (postId == null) return;

    if (!_isPostOwner(post)) return;

    await _firestore.collection("posts").doc(postId).delete();
  }

  void _editPost(Map<String, dynamic> post) {
    if (!_isPostOwner(post)) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostPage(post: post),
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          return const Icon(Icons.star, color: Color(0xFFF5AA2C), size: 20);
        } else if (rating > index && rating < index + 1) {
          return const Icon(Icons.star_half,
              color: Color(0xFFF5AA2C), size: 20);
        } else {
          return const Icon(Icons.star_border,
              color: Color(0xFFF5AA2C), size: 20);
        }
      }),
    );
  }

  Widget _profileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA8E6CF), Color(0xFFFFD3A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: widget.nutritionistProfile["profileImage"] != null
                ? AssetImage(widget.nutritionistProfile["profileImage"].toString())
                : null,
            child: widget.nutritionistProfile["profileImage"] == null
                ? const Icon(Icons.person, size: 32, color: Color(0xFF2E7D5A))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nutritionistProfile["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D5A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nutritionistProfile["specialty"] ?? "",
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.nutritionistProfile["email"] ?? "",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onEditProfile,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Color(0xFF2E7D5A),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openComments(BuildContext context, Map<String, dynamic> post) {
    final TextEditingController controller = TextEditingController();

    final postId = post["postId"]?.toString();
    if (postId == null) return;

    final List<Map<String, dynamic>> comments = _getComments(post);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> addComment() async {
              if (controller.text.trim().isEmpty) return;

              final user = currentUser;
              if (user == null) return;

              final userName = await _getCurrentUserName();

              comments.add({
                "commentId": DateTime.now().millisecondsSinceEpoch.toString(),
                "userId": user.uid,
                "user": userName,
                "text": controller.text.trim(),
                "createdAt": Timestamp.now(),
                "replies": [],
              });

              controller.clear();

              setModalState(() {});

              await _saveComments(postId, comments);
            }

            Future<void> deleteComment(int commentIndex) async {
              final comment = comments[commentIndex];

              if (!_canDeleteComment(post, comment)) return;

              comments.removeAt(commentIndex);

              setModalState(() {});

              await _saveComments(postId, comments);
            }

            Future<void> deleteReply(int commentIndex, int replyIndex) async {
              final comment = comments[commentIndex];
              final replies = _getReplies(comment);

              if (replyIndex < 0 || replyIndex >= replies.length) return;

              final reply = replies[replyIndex];

              if (!_canDeleteReply(post, reply)) return;

              replies.removeAt(replyIndex);
              comments[commentIndex]["replies"] = replies;

              setModalState(() {});

              await _saveComments(postId, comments);
            }

            void showReplyDialog(int commentIndex) {
              final replyController = TextEditingController();

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Reply"),
                    content: TextField(
                      controller: replyController,
                      decoration: const InputDecoration(
                        hintText: "Write your reply...",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final text = replyController.text.trim();

                          if (text.isEmpty) return;

                          final user = currentUser;
                          if (user == null) return;

                          final userName = await _getCurrentUserName();

                          final comment = comments[commentIndex];
                          final replies = _getReplies(comment);

                          replies.add({
                            "replyId":
                            DateTime.now().millisecondsSinceEpoch.toString(),
                            "userId": user.uid,
                            "user": userName,
                            "text": text,
                            "createdAt": Timestamp.now(),
                          });

                          comments[commentIndex]["replies"] = replies;

                          Navigator.pop(context);

                          setModalState(() {});

                          await _saveComments(postId, comments);
                        },
                        child: const Text("Send"),
                      ),
                    ],
                  );
                },
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.70,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F7F3),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Comments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D5A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: comments.isEmpty
                            ? const Center(
                          child: Text(
                            "No comments yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                            : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, commentIndex) {
                            final comment = comments[commentIndex];
                            final replies = _getReplies(comment);

                            final canDeleteComment =
                            _canDeleteComment(post, comment);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                        const Color(0xFFA8E6CF).withOpacity(0.4),

                                        backgroundImage: comment["profileImage"] != null
                                            ? AssetImage(comment["profileImage"])
                                            : null,

                                        child: comment["profileImage"] == null
                                            ? Text(
                                          _firstLetter(
                                            comment["user"],
                                            "U",
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF2E7D5A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment["user"]?.toString() ??
                                                  "",
                                              style: const TextStyle(
                                                fontWeight:
                                                FontWeight.bold,
                                                color: Color(0xFF2E7D5A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              comment["text"]?.toString() ??
                                                  "",
                                              style: const TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == "delete") {
                                            deleteComment(commentIndex);
                                          }
                                        },
                                        itemBuilder: (context) {
                                          return [
                                            if (canDeleteComment)
                                              const PopupMenuItem(
                                                value: "delete",
                                                child: Text("Delete"),
                                              ),
                                          ];
                                        },
                                      ),
                                    ],
                                  ),
                                  if (replies.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ...replies
                                        .asMap()
                                        .entries
                                        .map((replyEntry) {
                                      final replyIndex = replyEntry.key;
                                      final replyMap = replyEntry.value;

                                      final canDeleteReply =
                                      _canDeleteReply(post, replyMap);

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          left: 40,
                                          top: 8,
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F7F4),
                                          borderRadius:
                                          BorderRadius.circular(14),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor:
                                              const Color(0xFFFFD3A5),
                                              child: Text(
                                                _firstLetter(
                                                  replyMap["user"],
                                                  "D",
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                  Color(0xFF2E7D5A),
                                                  fontWeight:
                                                  FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  Text(
                                                    replyMap["user"]
                                                        ?.toString() ??
                                                        "",
                                                    style:
                                                    const TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: Color(
                                                          0xFF2E7D5A),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      height: 2),
                                                  Text(
                                                    replyMap["text"]
                                                        ?.toString() ??
                                                        "",
                                                    style:
                                                    const TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                      Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (canDeleteReply)
                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value ==
                                                      "delete") {
                                                    deleteReply(
                                                      commentIndex,
                                                      replyIndex,
                                                    );
                                                  }
                                                },
                                                itemBuilder: (context) {
                                                  return const [
                                                    PopupMenuItem(
                                                      value: "delete",
                                                      child:
                                                      Text("Delete"),
                                                    ),
                                                  ];
                                                },
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom:
                          MediaQuery.of(context).viewInsets.bottom + 14,
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextField(
                                    controller: controller,
                                    minLines: 1,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: "Write a comment...",
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFB39DDB),
                                          width: 1.6,
                                        ),
                                      ),
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: addComment,
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
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _postCard(BuildContext context, Map<String, dynamic> post, int index) {
    final user = currentUser;

    final likedBy = ((post["likedBy"] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    final bool isLiked = user != null && likedBy.contains(user.uid);
    final bool isOwner = _isPostOwner(post);

    final int commentsCount = (post["comments"] as List?)?.length ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post["title"] ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D5A),
                  ),
                ),
              ),
              if (isOwner) ...[
                IconButton(
                  onPressed: () => _editPost(post),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFFFFA94D),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.35),
                      builder: (context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7F3),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Delete Post?",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D5A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Are you sure you want to delete this post?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(18),
                                          ),
                                        ),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: Color(0xFF2E7D5A),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _deletePost(post);
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(18),
                                          ),
                                        ),
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            post["content"] ?? "",
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            post["date"] ?? "",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () => _toggleLikePost(post),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? Colors.red.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${post["likes"] ?? 0}",
                        style: TextStyle(
                          color: isLiked ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openComments(context, post),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mode_comment_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$commentsCount",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _sharePostReal(post),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        color: Colors.green,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _reviewsFromFirestore() {
    final user = currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("nutritionists")
          .doc(user.uid)
          .collection("reviews")
          .orderBy("time", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!.docs;

        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final data = reviews[index].data() as Map<String, dynamic>;
            final rating = (data["rating"] as num?)?.toDouble() ?? 0.0;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data["name"] ?? "User",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D5A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStars(rating),
                  const SizedBox(height: 8),
                  Text(
                    data["comment"] ?? "",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  Widget _postsFromFirestore() {
    final user = currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection("posts")
          .where("nutritionistUid", isEqualTo: user.uid)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text("Error: ${snapshot.error}"),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final posts = snapshot.data!.docs.map((doc) {
          final data = doc.data();
          return {...data, "postId": doc.id};
        }).toList();

        return Column(
          children: posts.asMap().entries.map((entry) {
            return _postCard(context, entry.value, entry.key);
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rating =
        (widget.nutritionistProfile["rating"] as num?)?.toDouble() ?? 0.0;
    final reviewsCount = widget.nutritionistProfile["reviewsCount"] ?? 0;

    return Container(
      color: const Color(0xFFF8F7F3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
        child: Column(
          children: [
            _profileCard(),
            const SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection("nutritionists")
                  .doc(currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;

                final rating = (data?["rating"] as num?)?.toDouble() ?? 0.0;
                final reviewsCount = data?["reviewsCount"] ?? 0;

                return Container(
                  width: double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Rating",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D5A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStars(rating),
                          const SizedBox(width: 10),
                          Text(
                            "${rating.toStringAsFixed(1)} / 5",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "$reviewsCount user reviews",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showReviews = !showReviews;
                              });
                            },
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: showReviews ? 0.5 : 0,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF2E7D5A),
                                size: 34,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            if (showReviews) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "User Reviews",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D5A),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _reviewsFromFirestore(),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Posts",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D5A),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePostPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D5A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Post",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _postsFromFirestore(),
          ],
        ),
      ),
    );
  }
}
