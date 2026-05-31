import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'user/homepage.dart';
import 'nutritionist/nutritionist_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LiveWellApp());
}

class LiveWellApp extends StatelessWidget {
  const LiveWellApp({super.key});

  Future<Widget> _getStartPage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SplashScreen();
    }

    final nutritionistDoc = await FirebaseFirestore.instance
        .collection("nutritionists")
        .doc(user.uid)
        .get();

    if (nutritionistDoc.exists) {
      return const NutritionistDashboard();
    }

    return const HomePage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Live Well",
      home: FutureBuilder<Widget>(
        future: _getStartPage(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return snapshot.data!;
        },
      ),
    );
  }
}