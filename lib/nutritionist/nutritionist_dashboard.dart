import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'roomn/create_room_page.dart';
import 'roomn/my_created_rooms_page.dart';
import '../meals/meals_page.dart';
import 'chatn/nutritionist_chat_page.dart';
import 'chatn/nutritionist_requests_page.dart';
import 'edit_nutritionist_profile_page.dart';
import 'create_post_page.dart';

import 'nutritionist_home_page.dart';
import 'nutritionist_profile_page.dart';
import 'nutritionist_bottom_bar.dart';

class NutritionistDashboard extends StatefulWidget {
  const NutritionistDashboard({super.key});

  @override
  State<NutritionistDashboard> createState() =>
      _NutritionistDashboardState();
}

class _NutritionistDashboardState extends State<NutritionistDashboard> {
  int selectedIndex = 0;

  List<Map<String, dynamic>> createdRooms = [];

  List<Map<String, String>> chatUsers = [];


  Map<String, dynamic> nutritionistProfile = {
    "name": "Dr. Sarah",
    "specialty": "Clinical Nutritionist",
    "email": "nutritionist@email.com",
    "bio":
    "Helping people build healthy nutrition habits with simple and effective meal plans.",
    "wilaya": "Alger",
    "rating": 4.8,
    "reviewsCount": 27,
    "profileImage": "assets/images/nutritionist_female.png",
    "gender": "female",
  };
  List<Map<String, dynamic>> nutritionistPosts = [];
  @override
  void initState() {
    super.initState();
    _loadRooms();
    _loadPosts();
    _loadChatUsers();
  }

  Future<void> _loadRooms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("rooms")
        .where("nutritionistUid", isEqualTo: user.uid)
        .get();

    if (!mounted) return;

    setState(() {
      createdRooms = snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data()})
          .toList();
    });
  }

  Future<void> _loadPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("posts")
        .where("nutritionistUid", isEqualTo: user.uid)
        .orderBy("timestamp", descending: true)
        .get();

    if (!mounted) return;

    setState(() {
      nutritionistPosts = snapshot.docs
          .map((doc) => {"postId": doc.id, ...doc.data()})
          .toList();
    });
  }
  Future<void> _loadChatUsers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("message_requests")
        .where("nutritionistUid", isEqualTo: user.uid)
        .get();

    if (!mounted) return;

    final List<Map<String, String>> users =
    snapshot.docs.map<Map<String, String>>((doc) {
      final data = doc.data();

      return {
        "name": (data["userName"] ?? "User").toString(),
        "room": (data["goal"] ?? "").toString(),
      };
    }).toList();

    setState(() {
      chatUsers = users;
    });
  }

  Future<void> _createRoom() async {
    final newRoom = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRoomPage(),
      ),
    );

    if (newRoom != null) {
      await _loadRooms();
    }
  }

  Future<void> _openMyRooms() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyCreatedRoomsPage(
          createdRooms: createdRooms,
        ),
      ),
    );

    await _loadRooms();
  }

  Future<void> _openRequests() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NutritionistRequestsPage(),
      ),
    );

    await _loadChatUsers();
  }

  Future<void> _editProfile() async {
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNutritionistProfilePage(
          profile: nutritionistProfile,
        ),
      ),
    );

    if (updatedProfile != null) {
      setState(() {
        nutritionistProfile = Map<String, dynamic>.from(updatedProfile);
      });
    }
  }

  Future<void> _createPost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostPage(),
      ),
    );

    await _loadPosts();
  }

  Future<void> _editPost(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostPage(
          post: nutritionistPosts[index],
        ),
      ),
    );

    await _loadPosts();
  }

  void _deletePost(int index) {
    setState(() {
      nutritionistPosts.removeAt(index);
    });
  }

  void _likePost(int index) {
    setState(() {
      if (nutritionistPosts[index]["isLiked"] == true) {
        nutritionistPosts[index]["isLiked"] = false;
        nutritionistPosts[index]["likes"] =
            (nutritionistPosts[index]["likes"] ?? 1) - 1;
      } else {
        nutritionistPosts[index]["isLiked"] = true;
        nutritionistPosts[index]["likes"] =
            (nutritionistPosts[index]["likes"] ?? 0) + 1;
      }
    });
  }

  void _sharePost(int index) {
    setState(() {
      nutritionistPosts[index]["shares"] =
          (nutritionistPosts[index]["shares"] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Post shared"),
        backgroundColor: Color(0xFF2E7D5A),
      ),
    );
  }

  void _deleteComment(int postIndex, int commentIndex) {
    setState(() {
      (nutritionistPosts[postIndex]["comments"] as List).removeAt(commentIndex);
    });
  }

  void _replyToComment(
      int postIndex,
      int commentIndex,
      String replyText,
      ) {
    if (replyText.trim().isEmpty) return;

    setState(() {
      final comments = nutritionistPosts[postIndex]["comments"] as List;
      final comment = comments[commentIndex] as Map<String, dynamic>;

      if (comment["replies"] == null) {
        comment["replies"] = [];
      }

      (comment["replies"] as List).add({
        "user": nutritionistProfile["name"] ?? "Nutritionist",
        "text": replyText.trim(),
      });
    });
  }

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("No nutritionist logged in"),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("nutritionists")
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;

          nutritionistProfile["name"] = data["name"] ?? "Nutritionist";
          nutritionistProfile["email"] = data["email"] ?? "";
          nutritionistProfile["nutritionistId"] =
              data["nutritionistId"] ?? "";
          nutritionistProfile["uid"] = user.uid;
          nutritionistProfile["specialty"] =
              data["specialty"] ?? "";

          nutritionistProfile["bio"] =
              data["bio"] ?? "";

          nutritionistProfile["wilaya"] =
              data["wilaya"] ?? "";

          nutritionistProfile["gender"] =
              data["gender"] ?? "female";

          nutritionistProfile["profileImage"] =
              data["profileImage"] ??
                  "assets/images/nutritionist_female.png";
        }

        final pages = [
          NutritionistHomePage(
            createdRooms: createdRooms,
            nutritionistProfile: nutritionistProfile,
            onCreateRoom: _createRoom,
            onOpenMyRooms: _openMyRooms,
          ),
          const MealsPage(),
          NutritionistChatPage(users: chatUsers),
          NutritionistProfilePage(
            nutritionistProfile: nutritionistProfile,
            nutritionistPosts: nutritionistPosts,
            onEditProfile: _editProfile,
            onCreatePost: _createPost,
            onEditPost: _editPost,
            onDeletePost: _deletePost,
            onLikePost: _likePost,
            onSharePost: _sharePost,
            onDeleteComment: _deleteComment,
            onReplyToComment: _replyToComment,
          ),
        ];

        final titles = [
          "Nutritionist Space",
          "Meals",
          "Chat",
          "Profile",
        ];

        return PopScope(
            canPop: false,
            child: Scaffold(
          backgroundColor: const Color(0xFFF8F7F3),
          extendBody: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)),
            title: Text(
              titles[selectedIndex],
              style: const TextStyle(
                color: Color(0xFF2E7D5A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: pages[selectedIndex],
          ),
          bottomNavigationBar: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("message_requests")
                .where("nutritionistUid", isEqualTo: user.uid)
                .where("status", isEqualTo: "pending")
                .snapshots(),
            builder: (context, requestSnapshot) {
              final pendingCount =
              requestSnapshot.hasData ? requestSnapshot.data!.docs.length : 0;

              return NutritionistBottomBar(
                selectedIndex: selectedIndex,
                messageRequestsCount: pendingCount,
                onTabSelected: _onTabSelected,
                onOpenRequests: _openRequests,
              );
            },
          ),
            ),
        );
      },
    );
  }
}