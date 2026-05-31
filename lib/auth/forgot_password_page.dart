import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  int step = 0;

  final emailController = TextEditingController();

  bool isLoading = false;

  Timer? timer;
  int secondsLeft = 180;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _animation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_controller);
  }

  @override
  void dispose() {
    emailController.dispose();
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void startTimer() {
    timer?.cancel();

    setState(() {
      secondsLeft = 180;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() {
          secondsLeft--;
        });
      }
    });
  }

  String get timerText {
    final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> sendResetEmail() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      setState(() {
        step = 1;
      });

      startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent"),
          backgroundColor: Color(0xFF2E7D5A),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Failed to send reset email"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resendResetEmail() async {
    if (secondsLeft > 0) return;
    await sendResetEmail();
  }

  void back() {
    if (step > 0) {
      setState(() {
        step--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget circleIcon(IconData icon) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5AA2C).withOpacity(0.12),
            blurRadius: 18,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 58,
        color: const Color(0xFFF5AA2C),
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF5C5560)),
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: Colors.black87, width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: Color(0xFF2E7D5A), width: 1.6),
        ),
      ),
    );
  }

  Widget mainButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          elevation: 8,
          shadowColor: Colors.green.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget emailStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Forgot Password",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E7D5A),
          ),
        ),
        const SizedBox(height: 32),
        circleIcon(Icons.lock_outline_rounded),
        const SizedBox(height: 32),
        const Text(
          "Please enter your email address to receive a password reset link.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 30),
        inputField(
          controller: emailController,
          hint: "Email Address",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 34),
        mainButton("Send", sendResetEmail),
      ],
    );
  }

  Widget verifyStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Check Your Email",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E7D5A),
          ),
        ),
        const SizedBox(height: 32),
        circleIcon(Icons.mark_email_read_outlined),
        const SizedBox(height: 32),
        Text(
          "We sent a password reset link to\n${emailController.text.trim()}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "You can resend after: $timerText",
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: secondsLeft == 0 ? resendResetEmail : null,
          child: Text(
            "Resend Email",
            style: TextStyle(
              color: secondsLeft == 0
                  ? const Color(0xFFF5AA2C)
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        mainButton("Back to Login", () {
          Navigator.pop(context);
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFA8E6CF),
              Color(0xFFFFD3A5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: back,
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF2E7D5A),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.78,
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: step == 0 ? emailStep() : verifyStep(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}