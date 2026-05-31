import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'nutritionist_public_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../post_comments_sheet.dart';
import 'dart:ui';
import '../auth/loginpage.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];

  bool get isGuest => FirebaseAuth.instance.currentUser == null;
  String _nutritionistImage(Map<String, dynamic> item) {
    final profileImage = (item["profileImage"] ?? item["image"] ?? "").toString();
    final gender = (item["gender"] ?? "female").toString().toLowerCase();

    if (profileImage.isNotEmpty) {
      return profileImage;
    }

    if (gender == "male") {
      return "assets/images/nutritionist_male.png";
    }

    return "assets/images/nutritionist_female.png";
  }
  String _formatPostDate(dynamic value) {
    if (value == null) return "";

    DateTime date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else {
      return value.toString();
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final postDay = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(postDay).inDays;

    const weekDays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    if (diffDays == 0) {
      return "Today";
    }

    if (diffDays > 0 && diffDays < 7) {
      return weekDays[date.weekday - 1];
    }

    if (date.year == now.year) {
      return "${date.day} ${months[date.month - 1]}";
    }

    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }


  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _search(String value, List<Map<String, dynamic>> allData) {
    final query = value.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        filteredItems = List<Map<String, dynamic>>.from(allData);
      } else {
        filteredItems = allData.where((item) {
          if (item["type"] == "profile") {
            final name = (item["name"] ?? "").toString().toLowerCase();
            final specialty = (item["specialty"] ?? "").toString().toLowerCase();
            final wilaya = (item["wilaya"] ?? "").toString().toLowerCase();
            return name.contains(query) || specialty.contains(query) || wilaya.contains(query);
          } else {
            final author = (item["author"] ?? "").toString().toLowerCase();
            final title = (item["title"] ?? "").toString().toLowerCase();
            final content = (item["content"] ?? "").toString().toLowerCase();
            final specialty = (item["specialty"] ?? "").toString().toLowerCase();
            return author.contains(query) || title.contains(query) || content.contains(query) || specialty.contains(query);
          }
        }).toList();
      }
    });
  }
  void _showLoginRequired({String message = "Login to interact with posts"}) {
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
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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

  void _openProfile(Map<String, dynamic> item) {
    final String name = item["type"] == "profile" ? (item["name"] ?? "") : (item["author"] ?? "");
    final String specialty = item["specialty"] ?? "";
    final String image = _nutritionistImage(item);
    final String bio = item["bio"] ?? "Professional nutrition guidance and helpful educational content.";
    final String wilaya = item["wilaya"] ?? "Algeria";
    final double rating = ((item["rating"] as num?)?.toDouble() ?? 4.7);
    final String nutritionistUid = item["nutritionistUid"] ?? "";
    final List<Map<String, dynamic>> reviews = (item["reviews"] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NutritionistPublicProfilePage(
          name: name,
          specialty: specialty,
          image: image,
          bio: bio,
          wilaya: wilaya,
          initialRating: rating,
          initialReviews: reviews,
          nutritionistUid: nutritionistUid,
        ),
      ),
    );
  }

  void _toggleLikePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection("posts").doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data["likedBy"] ?? []);
      int likes = (data["likes"] ?? 0) as int;

      if (likedBy.contains(user.uid)) {
        likedBy.remove(user.uid);
        likes = (likes - 1).clamp(0, 999);
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

  void _sharePost(Map<String, dynamic> item) {
    final String postId = (item["postId"] ?? "").toString();

    final String link =
        "https://livewell.app/posts/$postId";

    final String text =
        "${item["title"] ?? ""}\n\n"
        "${item["content"] ?? ""}\n\n"
        "$link";

    Share.share(
      text,
      subject: item["title"]?.toString() ?? "Live Well Post",
    );
  }

  void _openComments(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCommentsSheet(post: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Discover", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF2E7D5A))),
                  const SizedBox(height: 6),
                  const Text("Explore nutritionists and their latest posts", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) => _search(value, allItems),
                      decoration: const InputDecoration(hintText: "Search nutritionist name...", prefixIcon: Icon(Icons.search), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("nutritionists").snapshots(),
                builder: (context, nutritionistsSnapshot) {
                  if (!nutritionistsSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("posts").orderBy("timestamp", descending: true).snapshots(),
                    builder: (context, postsSnapshot) {
                      if (!postsSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final List<Map<String, dynamic>> items = [];
                      for (var doc in nutritionistsSnapshot.data!.docs) {
                        items.add({"type": "profile", "nutritionistUid": doc.id, ...doc.data() as Map<String, dynamic>});
                      }
                      for (var doc in postsSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nutritionistUid = data["nutritionistUid"] ?? "";

                        Map<String, dynamic> nutritionistData = {};

                        for (var nDoc in nutritionistsSnapshot.data!.docs) {
                          if (nDoc.id == nutritionistUid) {
                            nutritionistData = nDoc.data() as Map<String, dynamic>;
                            break;
                          }
                        }

                        items.add({
                          "type": "post",
                          ...data,
                          "postId": doc.id,

                          "author": nutritionistData["name"] ?? data["createdByName"] ?? "Anonymous",
                          "specialty": nutritionistData["specialty"] ?? data["specialty"] ?? "",
                          "image": nutritionistData["profileImage"] ?? data["image"],
                          "profileImage": nutritionistData["profileImage"],
                          "gender": nutritionistData["gender"] ?? data["gender"] ?? "female",
                          "bio": nutritionistData["bio"] ?? "",
                          "wilaya": nutritionistData["wilaya"] ?? "",
                          "rating": nutritionistData["rating"] ?? 0,
                          "nutritionistUid": nutritionistUid,
                        });
                      }
                      items.sort((a, b) {
                        final aTime = (a["timestamp"] ?? a["createdAt"]) as Timestamp?;
                        final bTime = (b["timestamp"] ?? b["createdAt"]) as Timestamp?;

                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;

                        return bTime.compareTo(aTime);
                      });

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            allItems = items;
                            if (searchController.text.isEmpty) {
                              filteredItems = List<Map<String, dynamic>>.from(allItems);
                            } else {
                              _search(searchController.text, allItems);
                            }
                          });
                        }
                      });

                      if (filteredItems.isEmpty && searchController.text.isNotEmpty) {
                        return const Center(child: Text("No matching results", style: TextStyle(color: Colors.grey, fontSize: 16)));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          if (item["type"] == "profile") {
                            return _profileCard(item);
                          } else {
                            return _realtimePostCard(item);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        if (isGuest) {
          _showLoginRequired(message: "Login to view profile");
          return;
        }
        _openProfile(item);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDDF3EA), Color(0xFFF3FBF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(_nutritionistImage(item)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["name"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D5A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item["specialty"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item["bio"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Color(0xFF5FAF8E)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item["wilaya"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFF5FAF8E)),
                      const SizedBox(width: 3),
                      Text(
                        "${item["rating"] ?? 4.7}",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                "View",
                style: TextStyle(
                  color: Color(0xFF5FAF8E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _realtimePostCard(Map<String, dynamic> item) {
    final String postId = item["postId"];
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("posts").doc(postId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final likes = data["likes"] ?? 0;
        final comments = (data["comments"] as List?) ?? [];
        final likedBy = List<String>.from(data["likedBy"] ?? []);
        final bool isLiked = FirebaseAuth.instance.currentUser != null && likedBy.contains(FirebaseAuth.instance.currentUser!.uid);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isGuest) {
                        _showLoginRequired(message: "Login to view profile");
                        return;
                      }
                      _openProfile(item);
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFA8E6CF).withOpacity(0.30),
                      backgroundImage: AssetImage(_nutritionistImage(item)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["author"] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D5A), fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item["specialty"] ?? "",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatPostDate(data["timestamp"] ?? item["timestamp"] ?? item["createdAt"]),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item["title"] ?? "",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                item["content"] ?? "",
                style: const TextStyle(color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isGuest) {
                        _showLoginRequired(message: "Login to interact with posts");
                        return;
                      }
                      _toggleLikePost(postId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLiked ? Colors.red.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: isLiked ? Colors.red : Colors.grey, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "$likes",
                            style: TextStyle(color: isLiked ? Colors.red : Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (isGuest) {
                        _showLoginRequired(message: "Login to interact with posts");
                        return;
                      }
                      _openComments({
                        "postId": postId,
                        "nutritionistUid": item["nutritionistUid"],
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mode_comment_outlined, color: Colors.blue, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "${comments.length}",
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (isGuest) {
                        _showLoginRequired(message: "Login to interact with posts");
                        return;
                      }
                      _sharePost(item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.share_outlined, color: Colors.green, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}