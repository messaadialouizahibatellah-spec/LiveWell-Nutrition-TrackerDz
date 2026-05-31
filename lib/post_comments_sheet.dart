import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostCommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCommentsSheet({
    super.key,
    required this.post,
  });

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  String _imageByGender(String gender) {
    return gender == "male"
        ? "assets/images/nutritionist_male.png"
        : "assets/images/nutritionist_female.png";
  }

  String _fixedNutritionistImage(Map<String, dynamic> data) {
    final gender = (data["gender"] ?? "female").toString().toLowerCase();

    final savedImage =
    (data["profileImage"] ?? data["image"] ?? "").toString();

    if (savedImage.isEmpty) {
      return _imageByGender(gender);
    }

    if (savedImage.contains("nutritionist_male.png") ||
        savedImage.contains("nutritionist_female.png")) {
      return _imageByGender(gender);
    }

    return savedImage;
  }

  Widget _commentAvatar(Map<String, dynamic> comment) {
    final userType = (comment["userType"] ?? "").toString();
    final userId = (comment["userId"] ?? "").toString();

    if (userType == "nutritionist" && userId.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection("nutritionists").doc(userId).snapshots(),
        builder: (context, snapshot) {
          String image = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            image = _fixedNutritionistImage(data);
          } else {
            final gender =
            (comment["gender"] ?? "female").toString().toLowerCase();
            image = _imageByGender(gender);
          }

          final ImageProvider provider =
          image.startsWith("http") ? NetworkImage(image) : AssetImage(image);

          return CircleAvatar(
            backgroundColor: const Color(0xFFA8E6CF).withOpacity(0.45),
            backgroundImage: provider,
          );
        },
      );
    }

    final image = (comment["userImage"] ?? "").toString();

    ImageProvider? provider;
    if (image.isNotEmpty) {
      provider = image.startsWith("http") ? NetworkImage(image) : AssetImage(image);
    }

    return CircleAvatar(
      backgroundColor: const Color(0xFFA8E6CF).withOpacity(0.45),
      backgroundImage: provider,
      child: provider == null
          ? Text(
        (comment["userName"] ?? "U")
            .toString()
            .substring(0, 1)
            .toUpperCase(),
        style: const TextStyle(fontSize: 12),
      )
          : null,
    );
  }
  final TextEditingController _controller = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar("You need to login first");
      return;
    }

    final text = _controller.text.trim();

    if (text.isEmpty) {
      _showSnackBar("Please write a comment");
      return;
    }

    String userName = "User";
    String userImage = "";
    String userGender = "user";

    final nutritionistDoc =
    await _firestore.collection("nutritionists").doc(user.uid).get();

    if (nutritionistDoc.exists) {
      final nutritionistData =
      nutritionistDoc.data() as Map<String, dynamic>;

      userName =
      nutritionistData["name"]?.toString().trim().isNotEmpty == true
          ? nutritionistData["name"]
          : (nutritionistData["username"] ?? "Nutritionist");

      final gender =
      (nutritionistData["gender"] ?? "female")
          .toString()
          .toLowerCase();
      userGender = gender;

      userImage = _fixedNutritionistImage(nutritionistData);

    } else {

      final userDoc =
      await _firestore.collection("users").doc(user.uid).get();

      final userData = userDoc.data() ?? {};

      userName =
      userData["name"]?.toString().trim().isNotEmpty == true
          ? userData["name"]
          : (userData["username"] ?? "User");

      userImage =
          userData["profileImage"] ??
              userData["image"] ??
              "";
    }

    final newComment = {
      "commentId":
      "${DateTime.now().millisecondsSinceEpoch}_${user.uid}",
      "userId": user.uid,
      "userName": userName,
      "user": userName,
      "userImage": userImage,
      "userType": nutritionistDoc.exists ? "nutritionist" : "user",
      "gender": userGender,
      "text": text,
      "timestamp": Timestamp.now(),
    };

    await _firestore
        .collection("posts")
        .doc(widget.post["postId"])
        .update({
      "comments": FieldValue.arrayUnion([newComment]),
      "commentsCount": FieldValue.increment(1),
    });

    _controller.clear();

    _showSnackBar("Comment added successfully");
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final postDoc = await _firestore
        .collection("posts")
        .doc(widget.post["postId"])
        .get();

    final postData = postDoc.data() as Map<String, dynamic>;

    final nutritionistUid = postData["nutritionistUid"];

    final bool isCommentOwner =
        comment["userId"] == user.uid;

    final bool isNutritionist =
        nutritionistUid == user.uid;

    if (!isCommentOwner && !isNutritionist) {
      _showSnackBar(
          "You don't have permission to delete this comment");
      return;
    }

    await _firestore
        .collection("posts")
        .doc(widget.post["postId"])
        .update({
      "comments": FieldValue.arrayRemove([comment]),
      "commentsCount": FieldValue.increment(-1),
    });

    _showSnackBar("Comment deleted");
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F7F3),
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Comments",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D5A),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection("posts")
                      .doc(widget.post["postId"])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return const Center(
                        child: Text("No comments yet"),
                      );
                    }

                    final data =
                    snapshot.data!.data()
                    as Map<String, dynamic>;

                    final List<dynamic> commentsRaw =
                        data["comments"] ?? [];

                    final comments = commentsRaw
                        .map((e) =>
                    Map<String, dynamic>.from(e as Map))
                        .toList();

                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          "No comments yet.\nBe the first to comment!",
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];

                        final bool isMyComment =
                            currentUser != null &&
                                comment["userId"] ==
                                    currentUser!.uid;

                        final bool isNutritionist =
                            currentUser != null &&
                                widget.post["nutritionistUid"] ==
                                    currentUser!.uid;

                        final bool canDelete =
                            isMyComment || isNutritionist;

                        return ListTile(
                          leading: _commentAvatar(comment),
                          title: Text(
                            comment["userName"] ??
                                comment["user"] ??
                                "User",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),

                          subtitle:
                          Text(comment["text"] ?? ""),

                          trailing: canDelete
                              ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                _deleteComment(comment),
                          )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.only(
                  bottom:
                  MediaQuery.of(context).viewInsets.bottom +
                      20,
                  left: 16,
                  right: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Write a comment...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    IconButton(
                      onPressed: _addComment,
                      icon: const Icon(
                        Icons.send,
                        color: Color(0xFF2E7D5A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}