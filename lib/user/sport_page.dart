import 'package:flutter/material.dart';
import 'exercise_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../auth/loginpage.dart';

class SportPage extends StatefulWidget {
  final Map<String, String>? userData;

  const SportPage({super.key, this.userData});

  @override
  State<SportPage> createState() => _SportPageState();
}

class _SportPageState extends State<SportPage> {
  String selectedPart = "upper";
  String gender = "female";
  bool isLoading = true;
  bool showLoginOverlay = false;

  @override
  void initState() {
    super.initState();
    _loadUserGender();
  }

  Future<void> _loadUserGender() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
        showLoginOverlay = true;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      gender = (data?["gender"] ?? "female").toString().toLowerCase();
    }

    setState(() => isLoading = false);
  }

  bool get isFemale => gender == "female";

  Map<String, List<Map<String, String>>> get exercises {
    if (isFemale) {
      return {
        "upper": [
          {
            "name": "Push Ups",
            "times": "10 reps",
            "description": "Chest, shoulders and arms.",
            "steps":
            "1. Place your hands slightly wider than shoulder width.\n"
                "2. Keep your body straight from head to heels.\n"
                "3. Lower your chest slowly toward the floor.\n"
                "4. Push back up to the starting position.\n"
                "5. Repeat with control.",
            "video": "https://www.youtube.com/watch?v=IODxDxX7oi4",
          },
          {
            "name": "Dumbbell Rows",
            "times": "12 reps",
            "description": "Back and posture strength.",
            "steps":
            "1. Hold a dumbbell in one hand.\n"
                "2. Bend slightly forward with a straight back.\n"
                "3. Pull the dumbbell toward your waist.\n"
                "4. Lower it slowly.\n"
                "5. Repeat, then switch sides.",
            "video": "https://www.youtube.com/watch?v=roCP6wCXPqo",
          },
          {
            "name": "Shoulder Press",
            "times": "10 reps",
            "description": "Shoulders and upper body strength.",
            "steps":
            "1. Hold dumbbells at shoulder level.\n"
                "2. Keep your core tight.\n"
                "3. Press the weights upward until arms are extended.\n"
                "4. Lower slowly back to shoulder level.\n"
                "5. Repeat with steady control.",
            "video": "https://www.youtube.com/watch?v=B-aVuyhvLHU",
          },
          {
            "name": "Biceps Curl",
            "times": "12 reps",
            "description": "Arm strengthening.",
            "steps":
            "1. Stand tall holding dumbbells by your sides.\n"
                "2. Keep elbows close to your body.\n"
                "3. Curl the weights upward.\n"
                "4. Squeeze at the top.\n"
                "5. Lower slowly and repeat.",
            "video": "https://www.youtube.com/watch?v=ykJmrZ5v0Oo",
          },
        ],
        "core": [
          {
            "name": "Plank",
            "times": "30 sec",
            "description": "Full core stability.",
            "steps":
            "1. Place forearms on the floor.\n"
                "2. Extend legs behind you.\n"
                "3. Keep your body in a straight line.\n"
                "4. Tighten your abs and glutes.\n"
                "5. Hold without dropping your hips.",
            "video": "https://www.youtube.com/watch?v=pSHjTRCQxIw",
          },
          {
            "name": "Crunches",
            "times": "15 reps",
            "description": "Abs workout.",
            "steps":
            "1. Lie on your back with knees bent.\n"
                "2. Place hands lightly behind your head.\n"
                "3. Lift your shoulders off the floor.\n"
                "4. Contract your abs at the top.\n"
                "5. Lower slowly and repeat.",
            "video": "https://www.youtube.com/watch?v=Xyd_fa5zoEU",
          },
          {
            "name": "Leg Raises",
            "times": "12 reps",
            "description": "Lower abs and hip flexors.",
            "steps":
            "1. Lie flat on your back.\n"
                "2. Keep your legs straight.\n"
                "3. Raise both legs upward slowly.\n"
                "4. Lower them without touching the floor.\n"
                "5. Repeat with control.",
            "video": "https://www.youtube.com/watch?v=JB2oyawG9KI",
          },
        ],
        "lower": [
          {
            "name": "Squats",
            "times": "15 reps",
            "description": "Legs and glutes.",
            "steps":
            "1. Stand with feet shoulder-width apart.\n"
                "2. Keep your chest up and back straight.\n"
                "3. Bend knees and lower hips down.\n"
                "4. Push through your heels to stand.\n"
                "5. Repeat smoothly.",
            "video": "https://www.youtube.com/watch?v=aclHkVaku9U",
          },
          {
            "name": "Lunges",
            "times": "12 reps",
            "description": "Leg balance.",
            "steps":
            "1. Step one leg forward.\n"
                "2. Lower your body until both knees bend.\n"
                "3. Keep your front knee aligned with your foot.\n"
                "4. Push back to the starting position.\n"
                "5. Alternate legs.",
            "video": "https://www.youtube.com/watch?v=QOVaHwm-Q6U",
          },
          {
            "name": "Glute Bridge",
            "times": "15 reps",
            "description": "Glutes and hamstrings.",
            "steps":
            "1. Lie on your back with knees bent.\n"
                "2. Place feet flat on the floor.\n"
                "3. Lift hips upward by squeezing glutes.\n"
                "4. Hold briefly at the top.\n"
                "5. Lower slowly and repeat.",
            "video": "https://www.youtube.com/watch?v=wPM8icPu6H8",
          },
        ],
      };
    }

    return {
      "upper": [
        {
          "name": "Bench Press",
          "times": "10 reps",
          "description": "Chest, shoulders and triceps.",
          "steps":
          "1. Lie flat on the bench.\n"
              "2. Grip the bar slightly wider than shoulders.\n"
              "3. Lower the bar to your chest slowly.\n"
              "4. Press it upward until arms are extended.\n"
              "5. Repeat with control.",
          "video": "https://www.youtube.com/watch?v=rT7DgCr-3pg",
        },
        {
          "name": "Rows",
          "times": "12 reps",
          "description": "Back strength and posture.",
          "steps":
          "1. Hold the weight with a firm grip.\n"
              "2. Bend slightly forward with a straight back.\n"
              "3. Pull the weight toward your torso.\n"
              "4. Lower slowly.\n"
              "5. Repeat with full range.",
          "video": "https://www.youtube.com/watch?v=FWJR5Ve8bnQ",
        },
        {
          "name": "Pull Ups",
          "times": "8 reps",
          "description": "Back and arms strength.",
          "steps":
          "1. Grab the bar with hands wider than shoulders.\n"
              "2. Hang with arms extended.\n"
              "3. Pull your body upward until chin passes the bar.\n"
              "4. Lower slowly.\n"
              "5. Repeat.",
          "video": "https://www.youtube.com/watch?v=eGo4IYlbE5g",
        },
        {
          "name": "Shoulder Press",
          "times": "10 reps",
          "description": "Shoulders and upper stability.",
          "steps":
          "1. Hold weights at shoulder height.\n"
              "2. Tighten your core.\n"
              "3. Press upward until arms are straight.\n"
              "4. Lower slowly.\n"
              "5. Repeat with control.",
          "video": "https://www.youtube.com/watch?v=qEwKCR5JCog",
        },
      ],
      "core": [
        {
          "name": "Plank",
          "times": "45 sec",
          "description": "Full core stability.",
          "steps":
          "1. Place forearms on the floor.\n"
              "2. Extend legs behind you.\n"
              "3. Keep body straight.\n"
              "4. Tighten core and glutes.\n"
              "5. Hold your position.",
          "video": "https://www.youtube.com/watch?v=pSHjTRCQxIw",
        },
        {
          "name": "Sit Ups",
          "times": "20 reps",
          "description": "Core endurance.",
          "steps":
          "1. Lie on your back with knees bent.\n"
              "2. Place hands near your head or across chest.\n"
              "3. Lift your upper body toward your knees.\n"
              "4. Lower slowly.\n"
              "5. Repeat steadily.",
          "video": "https://www.youtube.com/watch?v=1fbU_MkV7NE",
        },
        {
          "name": "Leg Raises",
          "times": "12 reps",
          "description": "Lower abs and hip flexors.",
          "steps":
          "1. Lie flat on your back.\n"
              "2. Keep legs straight.\n"
              "3. Raise them upward slowly.\n"
              "4. Lower without touching the floor.\n"
              "5. Repeat.",
          "video": "https://www.youtube.com/watch?v=JB2oyawG9KI",
        },
      ],
      "lower": [
        {
          "name": "Squats",
          "times": "12 reps",
          "description": "Quads and glutes.",
          "steps":
          "1. Stand with feet shoulder-width apart.\n"
              "2. Keep your chest up.\n"
              "3. Bend knees and lower hips down.\n"
              "4. Push through heels to stand.\n"
              "5. Repeat.",
          "video": "https://www.youtube.com/watch?v=aclHkVaku9U",
        },
        {
          "name": "Deadlift",
          "times": "10 reps",
          "description": "Posterior-chain strength.",
          "steps":
          "1. Stand with feet under the bar.\n"
              "2. Bend at hips and knees to grip the bar.\n"
              "3. Keep your back straight.\n"
              "4. Lift by driving through your legs.\n"
              "5. Lower with control.",
          "video": "https://www.youtube.com/watch?v=op9kVnSso6Q",
        },
        {
          "name": "Leg Press",
          "times": "12 reps",
          "description": "Machine lower-body work.",
          "steps":
          "1. Sit on the leg press machine.\n"
              "2. Place feet shoulder-width on the platform.\n"
              "3. Push the platform upward.\n"
              "4. Lower slowly until knees bend.\n"
              "5. Repeat.",
          "video": "https://www.youtube.com/watch?v=IZxyjW7MPJQ",
        },
      ],
    };
  }

  String get partTitle {
    switch (selectedPart) {
      case "upper":
        return "Upper Body";
      case "core":
        return "Core";
      case "lower":
        return "Lower Body";
      default:
        return "";
    }
  }

  Color _activeColor(String part) {
    final upperSelected = selectedPart == "upper";
    final lowerSelected = selectedPart == "lower";

    final shouldHighlightUpper =
        part == "upper" || part == "rightArm" || part == "leftArm";
    final shouldHighlightLower =
        part == "hips" ||
            part == "leftThigh" ||
            part == "rightThigh" ||
            part == "leftCalf" ||
            part == "rightCalf";

    if ((upperSelected && shouldHighlightUpper) ||
        (lowerSelected && shouldHighlightLower) ||
        selectedPart == part) {
      switch (selectedPart) {
        case "upper":
          return const Color(0xFFFF914D);
        case "core":
          return const Color(0xFF7B61FF);
        case "lower":
          return const Color(0xFF4D96FF);
      }
    }

    return Colors.grey.withOpacity(0.20);
  }

  @override
  Widget build(BuildContext context) {
    final currentExercises = exercises[selectedPart]!;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F3),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          showLoginOverlay
              ? ""
              : (isFemale ? "Female Muscles" : "Male Muscles"),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Stack(
          children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _chip("Upper", "upper")),
                const SizedBox(width: 8),
                Expanded(child: _chip("Core", "core")),
                const SizedBox(width: 8),
                Expanded(child: _chip("Lower", "lower")),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -10),
                        child: Container(
                          width: 145,
                          height: 340,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
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
                          child: Center(
                            child: SizedBox(
                              width: 120,
                              height: 270,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _buildBodyBase(),
                                  Positioned(
                                    top: 0,
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.18),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 44,
                                    child: _bodyPart(
                                      part: "upper",
                                      width: 62,
                                      height: 46,
                                      radius: 20,
                                    ),
                                  ),
                                  Positioned(
                                    top: 54,
                                    left: 2,
                                    child: _bodyPart(
                                      part: "leftArm",
                                      width: 18,
                                      height: 86,
                                      radius: 14,
                                      onTapPart: "upper",
                                    ),
                                  ),
                                  Positioned(
                                    top: 54,
                                    right: 2,
                                    child: _bodyPart(
                                      part: "rightArm",
                                      width: 18,
                                      height: 86,
                                      radius: 14,
                                      onTapPart: "upper",
                                    ),
                                  ),
                                  Positioned(
                                    top: 98,
                                    child: _bodyPart(
                                      part: "core",
                                      width: 44,
                                      height: 38,
                                      radius: 18,
                                    ),
                                  ),
                                  Positioned(
                                    top: 140,
                                    child: _bodyPart(
                                      part: "hips",
                                      width: 54,
                                      height: 28,
                                      radius: 16,
                                      onTapPart: "lower",
                                    ),
                                  ),
                                  Positioned(
                                    top: 170,
                                    left: 40,
                                    child: _bodyPart(
                                      part: "leftThigh",
                                      width: 16,
                                      height: 54,
                                      radius: 12,
                                      onTapPart: "lower",
                                    ),
                                  ),
                                  Positioned(
                                    top: 170,
                                    right: 40,
                                    child: _bodyPart(
                                      part: "rightThigh",
                                      width: 16,
                                      height: 54,
                                      radius: 12,
                                      onTapPart: "lower",
                                    ),
                                  ),
                                  Positioned(
                                    top: 228,
                                    left: 43,
                                    child: _bodyPart(
                                      part: "leftCalf",
                                      width: 13,
                                      height: 42,
                                      radius: 12,
                                      onTapPart: "lower",
                                    ),
                                  ),
                                  Positioned(
                                    top: 228,
                                    right: 43,
                                    child: _bodyPart(
                                      part: "rightCalf",
                                      width: 13,
                                      height: 42,
                                      radius: 12,
                                      onTapPart: "lower",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 115),
                            itemCount: currentExercises.length,
                            itemBuilder: (context, index) {
                              final ex = currentExercises[index];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ExerciseDetailPage(exercise: ex),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
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
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE8D9),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ex["name"]!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              ex["times"]!,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              ex["description"]!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

            if (showLoginOverlay) _buildLoginOverlay(),
          ],
      ));
  }

  Widget _bodyPart({
    required String part,
    required double width,
    required double height,
    required double radius,
    String? onTapPart,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPart = onTapPart ?? part;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _activeColor(part),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _buildBodyBase() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 38,
          child: Container(
            width: 74,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        Positioned(
          top: 94,
          child: Container(
            width: 46,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 134,
          child: Container(
            width: 62,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          top: 54,
          left: 5,
          child: Container(
            width: 12,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 54,
          right: 5,
          child: Container(
            width: 12,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 168,
          left: 40,
          child: Container(
            width: 16,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 168,
          right: 40,
          child: Container(
            width: 16,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 228,
          left: 43,
          child: Container(
            width: 13,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 228,
          right: 43,
          child: Container(
            width: 13,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildLoginOverlay() {
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
                const Text(
                  "Log in to unlock this feature",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D5A),
                      elevation: 6,
                      shadowColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.login, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Login Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _chip(String title, String value) {
    final selected = selectedPart == value;

    return GestureDetector(
      onTap: () => setState(() => selectedPart = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2E7D5A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}