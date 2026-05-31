import 'package:flutter/material.dart';
import 'qcm_page.dart';
import '../user/homepage.dart';
import '../user/app_user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_page.dart';

double _midPoint(String range, {double defaultValue = 0}) {
  if (range.isEmpty) return defaultValue;
  if (range.endsWith("+")) {
    final base = double.tryParse(range.replaceAll("+", "")) ?? defaultValue;
    return base + 4;
  }
  final parts = range.split("-");
  if (parts.length == 2) {
    final a = double.tryParse(parts[0]) ?? defaultValue;
    final b = double.tryParse(parts[1]) ?? defaultValue;
    return (a + b) / 2;
  }
  return double.tryParse(range) ?? defaultValue;
}

int _calculateCalorieGoal({
  required String gender,
  required String ageRange,
  required String heightRange,
  required String weightRange,
  required String activity,
  required String goal,
}) {
  final age = _midPoint(ageRange, defaultValue: 25);
  final height = _midPoint(heightRange, defaultValue: 165);
  final weight = _midPoint(weightRange, defaultValue: 70);

  double bmr;
  if (gender.toLowerCase() == "male") {
    bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
  } else {
    bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
  }

  double activityFactor;
  switch (activity.toLowerCase()) {
    case "low":
      activityFactor = 1.2;
      break;
    case "moderate":
      activityFactor = 1.55;
      break;
    case "high":
      activityFactor = 1.725;
      break;
    default:
      activityFactor = 1.375;
  }
  double tdee = bmr * activityFactor;

  switch (goal.toLowerCase()) {
    case "lose weight":
      tdee -= 500;
      break;
    case "gain weight":
      tdee += 300;
      break;
  }

  return tdee.round().clamp(1200, 4000);
}

Map<String, int> _calcMacroGoals(int calories) {
  return {
    "fatGoal": ((calories * 0.30) / 9).round(),
    "carbGoal": ((calories * 0.40) / 4).round(),
    "proteinGoal": ((calories * 0.30) / 4).round(),
  };
}

class GenderPage extends StatelessWidget {
  const GenderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return QcmPage(
      step: 1,
      totalSteps: 6,
      question: "Select your gender",
      imagePath: "assets/images/gender.png",
      options: const ["Male", "Female"],
      onSelected: (value) {
        AppUserData.gender = value;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AgePage(),
          ),
        );
      },
    );
  }
}

class AgePage extends StatelessWidget {
  const AgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return QcmPage(
      step: 2,
      totalSteps: 6,
      question: "Select your age",
      imagePath: "assets/images/age.png",
      options: const ["10-20", "21-30", "31-40", "41-50", "51+"],
      onSelected: (value) {
        AppUserData.age = value;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HeightPage(),
          ),
        );
      },
    );
  }
}

class HeightPage extends StatelessWidget {
  const HeightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return QcmPage(
      step: 3,
      totalSteps: 6,
      question: "Select your height",
      imagePath: "assets/images/height.png",
      options: const ["140-150", "151-160", "161-170", "171-180", "181+"],
      onSelected: (value) {
        AppUserData.height = value;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WeightPage(),
          ),
        );
      },
    );
  }
}

class WeightPage extends StatelessWidget {
  const WeightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return QcmPage(
      step: 4,
      totalSteps: 6,
      question: "Select your weight",
      imagePath: "assets/images/weight.png",
      options: const ["40-50", "51-60", "61-70", "71-80", "81+"],
      onSelected: (value) {
        AppUserData.weight = value;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ActivityPage(),
          ),
        );
      },
    );
  }
}

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return QcmPage(
      step: 5,
      totalSteps: 6,
      question: "Select your activity level",
      imagePath: "assets/images/activity.png",
      options: const ["Low", "Moderate", "High"],
      onSelected: (value) {
        AppUserData.activity = value;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GoalPage(),
          ),
        );
      },
    );
  }
}

class GoalPage extends StatelessWidget {
  const GoalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return QcmPage(
      step: 6,
      totalSteps: 6,
      question: "Select your goal",
      imagePath: "assets/images/goal.png",
      options: const ["Lose Weight", "Maintain", "Gain Weight"],
      onSelected: (value) async {
        AppUserData.goal = value;

        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          final caloriesGoal = _calculateCalorieGoal(
            gender: AppUserData.gender,
            ageRange: AppUserData.age,
            heightRange: AppUserData.height,
            weightRange: AppUserData.weight,
            activity: AppUserData.activity,
            goal: AppUserData.goal,
          );

          final macros = _calcMacroGoals(caloriesGoal);

          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .set({
            "gender": AppUserData.gender,
            "age": AppUserData.age,
            "height": AppUserData.height,
            "weight": AppUserData.weight,
            "activity": AppUserData.activity,
            "goal": AppUserData.goal,

            "caloriesGoal": caloriesGoal,
            "fatGoal": macros["fatGoal"],
            "carbGoal": macros["carbGoal"],
            "proteinGoal": macros["proteinGoal"],
          }, SetOptions(merge: true));
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage(
            isNutritionist: false,
          )),
              (route) => false,
        );
      },
    );
  }
}