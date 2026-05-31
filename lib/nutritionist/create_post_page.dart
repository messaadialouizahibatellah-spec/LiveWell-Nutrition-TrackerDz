import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostPage extends StatefulWidget {
  final Map<String, dynamic>? post;

  const CreatePostPage({
    super.key,
    this.post,
  });

  @override
  State<CreatePostPage> createState() =>
      _CreatePostPageState();
}

class _CreatePostPageState
    extends State<CreatePostPage> {

  late TextEditingController titleController;
  late TextEditingController contentController;

  bool isLoading = false;

  bool get isEditMode => widget.post != null;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.post?["title"] ?? "",
    );

    contentController = TextEditingController(
      text: widget.post?["content"] ?? "",
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {

    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {

      setState(() {
        isLoading = true;
      });

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final userDoc =
      await FirebaseFirestore.instance
          .collection("nutritionists")
          .doc(user.uid)
          .get();

      final userData =
          userDoc.data() ?? {};

      final postData = {

        "title":
        titleController.text.trim(),
        "content":
        contentController.text.trim(),


        "createdBy": user.uid,
        "createdByName":
        userData["name"] ?? "Anonymous",

        "nutritionistUid": user.uid,

        "nutritionistName":
        userData["name"] ?? "Nutritionist",

        "specialty":
        userData["specialty"] ??
            "Nutritionist",

        "image":
        userData["profileImage"] ??
            "assets/images/nutritionist_female.png",


      };

      if (isEditMode &&
          widget.post?["postId"] != null) {

        await FirebaseFirestore.instance
            .collection("posts")
            .doc(widget.post!["postId"])
            .update({
          ...postData,
          "updatedAt": FieldValue.serverTimestamp(),
        });

      } else {

        final postRef =
        FirebaseFirestore.instance
            .collection("posts")
            .doc();

        await postRef.set({

          "postId": postRef.id,

          ...postData,
          "timestamp": FieldValue.serverTimestamp(),
          "date": "Today",


          "likes": 0,
          "likedBy": [],
          "commentsCount": 0,
          "shares": 0,
        });
      }

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration _input(
      String hint,
      IconData icon,
      ) {

    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(icon),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),

      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(22),

        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(22),

        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(22),

        borderSide: const BorderSide(
          color: Color(0xFF2E7D5A),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xFFF8F7F3),

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        centerTitle: true,

        iconTheme: const IconThemeData(
          color: Color(0xFF2E7D5A),
        ),

        title: Text(

          isEditMode
              ? "Edit Post"
              : "Create Post",

          style: const TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(

              controller: titleController,

              decoration: _input(
                "Post Title",
                Icons.title,
              ),
            ),

            const SizedBox(height: 16),

            TextField(

              controller: contentController,

              maxLines: 7,

              decoration: _input(
                "Post Content",
                Icons.article_outlined,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(

              width: double.infinity,

              height: 58,

              child: ElevatedButton(

                onPressed:
                isLoading
                    ? null
                    : _publishPost,

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  const Color(0xFF2E7D5A),

                  elevation: 0,

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(30),
                  ),
                ),

                child:
                isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Text(

                  isEditMode
                      ? "Save Post"
                      : "Publish Post",

                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}