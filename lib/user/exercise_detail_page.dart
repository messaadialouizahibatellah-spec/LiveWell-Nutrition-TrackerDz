import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseDetailPage extends StatefulWidget {
  final Map<String, String> exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late YoutubePlayerController _controller;
  String? videoId;
  String _dateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  int _caloriesForExercise(String name) {
    final n = name.toLowerCase();

    if (n.contains("plank")) return 20;
    if (n.contains("push")) return 45;
    if (n.contains("squat")) return 60;
    if (n.contains("lunge")) return 55;
    if (n.contains("crunch")) return 35;
    if (n.contains("leg")) return 50;
    if (n.contains("press")) return 65;
    if (n.contains("row")) return 55;
    if (n.contains("curl")) return 35;
    if (n.contains("deadlift")) return 80;

    return 40;
  }

  Future<void> _markExerciseDone() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You need to login first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final exercise = widget.exercise;
    final name = exercise["name"] ?? "Exercise";
    final dateKey = _dateKey(DateTime.now());
    final exerciseId = name.toLowerCase().replaceAll(" ", "_");

    await FirebaseFirestore.instance
        .collection("user_sports")
        .doc(user.uid)
        .collection("days")
        .doc(dateKey)
        .collection("exercises")
        .doc(exerciseId)
        .set({
      "name": name,
      "times": exercise["times"] ?? "",
      "description": exercise["description"] ?? "",
      "video": exercise["video"] ?? "",
      "caloriesBurned": _caloriesForExercise(name),
      "completedAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Exercise saved ✅"),
        backgroundColor: Color(0xFF2E7D5A),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final videoUrl = widget.exercise["video"] ?? "";
    videoId = YoutubePlayer.convertUrlToId(videoUrl);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "",
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F3),
        elevation: 0,
        centerTitle: true,
        title: Text(
          exercise["name"] ?? "Exercise Details",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (videoId != null && videoId!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: const Color(0xFF2E7D5A),
                  progressColors: const ProgressBarColors(
                    playedColor: Color(0xFF2E7D5A),
                    handleColor: Color(0xFF2E7D5A),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  "Video not available",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8D9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise["name"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          exercise["times"] ?? "",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionCard(
              title: "Description",
              child: Text(
                exercise["description"] ?? "",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: "Steps",
              child: Text(
                exercise["steps"] ?? "",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _markExerciseDone,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  "Mark as Done",
                  style: TextStyle(
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

  Widget _sectionCard({required String title, required Widget child}) {
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
