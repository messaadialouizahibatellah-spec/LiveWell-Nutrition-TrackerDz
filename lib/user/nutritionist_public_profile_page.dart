import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatu/specialist_conversation_page.dart';
import '../post_comments_sheet.dart';

class NutritionistPublicProfilePage extends StatefulWidget {
  final String name;
  final String specialty;
  final String image;
  final String bio;
  final String wilaya;
  final double initialRating;
  final List<Map<String, dynamic>> initialReviews;
  final String nutritionistUid;

  const NutritionistPublicProfilePage({
    super.key,
    required this.name,
    required this.specialty,
    required this.image,
    required this.bio,
    required this.wilaya,
    required this.initialRating,
    required this.initialReviews,
    required this.nutritionistUid,
  });

  @override
  State<NutritionistPublicProfilePage> createState() =>
      _NutritionistPublicProfilePageState();
}

class _NutritionistPublicProfilePageState
    extends State<NutritionistPublicProfilePage> {
  late double averageRating;
  late List<Map<String, dynamic>> userReviews;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    userReviews =
        widget.initialReviews.map((e) => Map<String, dynamic>.from(e)).toList();
    averageRating = _calculateAverageRating();
  }

  double _calculateAverageRating() {
    if (userReviews.isEmpty) return widget.initialRating;
    final total = userReviews.fold<double>(
      0,
          (sum, review) => sum + ((review["rating"] ?? 0) as num).toDouble(),
    );
    return total / userReviews.length;
  }

  Future<void> _toggleLikePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection("posts").doc(postId);

    await _firestore.runTransaction((transaction) async {
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

  Future<void> _sharePost(Map<String, dynamic> post) async {
    final text = "${post["title"] ?? ""}\n\n${post["content"] ?? ""}\n\nLive Well Nutrition";
    await Share.share(text, subject: post["title"] ?? "Live Well Post");
    final postId = post["postId"];
    if (postId != null) {
      await _firestore.collection("posts").doc(postId).update({
        "shares": FieldValue.increment(1),
      });
    }
  }

  Widget _buildStaticStars(int rating, {double size = 18}) {
    return Row(
      children: List.generate(
        5,
            (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFFA94D),
          size: size,
        ),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review, int reviewIndex, VoidCallback onDelete) {
    final isMyReview = review["userId"] == currentUser?.uid;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFDDF3EA),
            child: Text((review["name"] ?? "U").toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Color(0xFF2E7D5A), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D5A), fontSize: 15)),
                const SizedBox(height: 4),
                _buildStaticStars((review["rating"] ?? 0) as int),
                const SizedBox(height: 6),
                Text(review["comment"] ?? "", style: const TextStyle(color: Colors.black87, height: 1.35)),
              ],
            ),
          ),
          if (isMyReview)
            PopupMenuButton<String>(
              onSelected: (value) { if (value == "delete") onDelete(); },
              itemBuilder: (context) => const [PopupMenuItem(value: "delete", child: Text("Delete"))],
            ),
        ],
      ),
    );
  }

  void _openReviewsSheet() {
    double selectedRating = 0;
    String? ratingError;
    final TextEditingController reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(color: Color(0xFFF8F7F3), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(20))),
                      const SizedBox(height: 14),
                      const Text("Reviews", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF2E7D5A))),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Your Rating", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D5A))),
                                  if (ratingError != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                                      child: Text(ratingError!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: List.generate(5, (index) {
                                      final starNumber = index + 1;
                                      return GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            selectedRating = starNumber.toDouble();
                                            ratingError = null;
                                          });
                                        },
                                        child: Icon(starNumber <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded, color: const Color(0xFFFFA94D), size: 32),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: reviewController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: "Write your comment...",
                                      filled: true,
                                      fillColor: const Color(0xFFF8F7F3),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final user = currentUser;
                                        if (user == null) return;

                                        final comment = reviewController.text.trim();

                                        if (selectedRating == 0) {
                                          setModalState(() {
                                            ratingError = "Please select a rating";
                                          });
                                          return;
                                        }

                                        final reviewRef = _firestore
                                            .collection("nutritionists")
                                            .doc(widget.nutritionistUid)
                                            .collection("reviews")
                                            .doc(user.uid);

                                        await reviewRef.set({
                                          "userId": user.uid,
                                          "name": user.displayName ?? "User",
                                          "rating": selectedRating.toInt(),
                                          "comment": comment,
                                          "time": Timestamp.now(),
                                        });

                                        final snapshot = await _firestore
                                            .collection("nutritionists")
                                            .doc(widget.nutritionistUid)
                                            .collection("reviews")
                                            .get();

                                        double total = 0;
                                        for (var doc in snapshot.docs) {
                                          total += (doc["rating"] as num).toDouble();
                                        }

                                        final double avg = snapshot.docs.isEmpty
                                            ? 0.0
                                            : (total / snapshot.docs.length).toDouble();


                                        await _firestore
                                            .collection("nutritionists")
                                            .doc(widget.nutritionistUid)
                                            .update({
                                          "rating": avg,
                                          "reviewsCount": snapshot.docs.length,
                                        });
                                        setState(() {
                                          userReviews = snapshot.docs.map((doc) {
                                            return doc.data() as Map<String, dynamic>;
                                          }).toList();

                                          averageRating = avg;
                                        });

                                        setModalState(() {
                                          ratingError = null;
                                          selectedRating = 0;
                                          reviewController.clear();
                                        });

                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA94D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                                      child: const Text("Enregistrer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection("nutritionists")
                                  .doc(widget.nutritionistUid)
                                  .collection("reviews")
                                  .orderBy("time", descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final reviews = snapshot.data!.docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return {
                                    ...data,
                                    "reviewId": doc.id,
                                  };
                                }).toList();

                                if (reviews.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(child: Text("No reviews yet")),
                                  );
                                }

                                return Column(
                                  children: reviews
                                      .asMap()
                                      .entries
                                      .map((entry) => _reviewCard(entry.value, entry.key, () async {
                                    await _deleteReview(entry.value["reviewId"]);
                                  }))
                                      .toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
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
  Future<void> _deleteReview(String reviewId) async {
    await _firestore
        .collection("nutritionists")
        .doc(widget.nutritionistUid)
        .collection("reviews")
        .doc(reviewId)
        .delete();

    final snapshot = await _firestore
        .collection("nutritionists")
        .doc(widget.nutritionistUid)
        .collection("reviews")
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc["rating"] as num).toDouble();
    }

    final double avg = snapshot.docs.isEmpty
        ? 0.0
        : (total / snapshot.docs.length).toDouble();

    await _firestore
        .collection("nutritionists")
        .doc(widget.nutritionistUid)
        .update({
      "rating": avg,
      "reviewsCount": snapshot.docs.length,
    });
  }
  Widget _postsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("posts")
          .where("nutritionistUid", isEqualTo: widget.nutritionistUid)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {...data, "postId": doc.id};
        }).toList();
        return Column(children: posts.map((post) => _profilePostCard(post)).toList());
      },
    );
  }

  Widget _profilePostCard(Map<String, dynamic> post) {
    final postId = post["postId"];
    final likedBy = List<String>.from(post["likedBy"] ?? []);
    final bool isLiked = currentUser != null && likedBy.contains(currentUser!.uid);
    final int likes = post["likes"] ?? 0;
    final List<dynamic> commentsList = post["comments"] ?? [];
    final int commentsCount = commentsList.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post["title"] ?? "", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E7D5A))),
          const SizedBox(height: 6),
          Text(post["content"] ?? "", style: const TextStyle(color: Colors.black87, height: 1.4)),
          const SizedBox(height: 10),
          Text(post["date"] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () => _toggleLikePost(postId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: isLiked ? Colors.red.withOpacity(0.12) : Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: isLiked ? Colors.red : Colors.grey, size: 20),
                      const SizedBox(width: 6),
                      Text("$likes", style: TextStyle(color: isLiked ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showPostComments(post),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.mode_comment_outlined, color: Colors.blue, size: 20),
                      const SizedBox(width: 6),
                      Text("$commentsCount", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _sharePost(post),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.share_outlined, color: Colors.green, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostComments(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCommentsSheet(post: post),
    );
  }

  Future<void> _sendMessageRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final requestId = "${user.uid}_${widget.nutritionistUid}";
    final requestDoc = await FirebaseFirestore.instance.collection("message_requests").doc(requestId).get();
    if (requestDoc.exists && (requestDoc.data()?["status"] == "accepted")) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SpecialistConversationPage(specialistName: widget.name, specialty: widget.specialty, nutritionistUid: widget.nutritionistUid)));
      return;
    }
    await FirebaseFirestore.instance.collection("message_requests").doc(requestId).set({
      "userUid": user.uid, "userName": userData["name"] ?? "User", "nutritionistUid": widget.nutritionistUid, "nutritionistName": widget.name, "message": "Wants to contact you", "status": "pending", "createdAt": Timestamp.now(),
    });
    Navigator.push(context, MaterialPageRoute(builder: (context) => SpecialistConversationPage(specialistName: widget.name, specialty: widget.specialty, nutritionistUid: widget.nutritionistUid)));
  }

  @override
  Widget build(BuildContext context) {
    final reviewsCount = userReviews.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)), title: Text(widget.name, style: const TextStyle(color: Color(0xFF2E7D5A), fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFFFFD3A5)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(26)),
              child: Column(
                children: [
                  CircleAvatar(radius: 42, backgroundColor: Colors.white, backgroundImage: AssetImage(widget.image)),
                  const SizedBox(height: 14),
                  Text(widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D5A))),
                  const SizedBox(height: 6),
                  Text(widget.specialty, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
              child: Text(widget.bio, style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15)),
            ),
            const SizedBox(height: 18),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("nutritionists")
                  .doc(widget.nutritionistUid)
                  .collection("reviews")
                  .snapshots(),
              builder: (context, snapshot) {
                final reviews = snapshot.hasData ? snapshot.data!.docs : [];

                double total = 0;
                for (var doc in reviews) {
                  final data = doc.data() as Map<String, dynamic>;
                  total += ((data["rating"] ?? 0) as num).toDouble();
                }

                final double liveAverage =
                reviews.isEmpty
                    ? widget.initialRating
                    : (total / reviews.length).toDouble();

                return GestureDetector(
                  onTap: _openReviewsSheet,
                  child: Container(
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
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFA94D), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Reviews",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Color(0xFF2E7D5A))),
                              const SizedBox(height: 3),
                              Text(
                                "${liveAverage.toStringAsFixed(1)} / 5  •  ${reviews.length} reviews",
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFFF3FBF7), borderRadius: BorderRadius.circular(22)),
              child: const Text("Posts", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E7D5A))),
            ),
            const SizedBox(height: 12),
            _postsSection(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D5A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                onPressed: _sendMessageRequest,
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: const Text("Send Message", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}