import 'package:flutter/material.dart';
import 'questions.dart';
import '../user/app_user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool hasMinLength = false;
  bool hasNumber = false;
  bool hasLetter = false;
  bool hasSymbol = false;

  bool passwordsMatch = false;
  bool isTypingConfirm = false;
  final FocusNode passwordFocusNode = FocusNode();
  bool showPasswordConditions = false;

  bool showNameError = false;
  bool showEmailError = false;

  bool showPasswordError = false;
  bool showConfirmError = false;

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

    passwordFocusNode.addListener(() {
      setState(() {
        showPasswordConditions = passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    _controller.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void checkPassword(String value) {
    setState(() {
      hasMinLength = value.length >= 7;
      hasNumber = RegExp(r'[0-9]').hasMatch(value);
      hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
      hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    });
  }

  bool isPasswordValid() {
    return hasMinLength && hasNumber && hasLetter && hasSymbol;
  }

  Widget buildCondition(String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: valid ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: valid ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset("assets/images/logos1.png", height: 120),
                  const SizedBox(height: 10),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Sign up to get started",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(showNameError ? _animation.value : 0, 0),
                        child: child,
                      );
                    },
                    child: TextField(
                      controller: name,
                      onChanged: (_) {
                        setState(() {
                          showNameError = false;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Full Name",
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: showNameError
                                ? Colors.red
                                : Colors.grey.shade500,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: showNameError
                                ? Colors.red
                                : Colors.green,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(showEmailError ? _animation.value : 0, 0),
                        child: child,
                      );
                    },
                    child: TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        setState(() {
                          showEmailError = false;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: showEmailError
                                ? Colors.red
                                : Colors.grey.shade500,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: showEmailError
                                ? Colors.red
                                : Colors.green,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  if (showPasswordConditions ||
                      password.text.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildCondition(
                            "At least 7 characters",
                            hasMinLength,
                          ),
                          buildCondition(
                            "Contains a number",
                            hasNumber,
                          ),
                          buildCondition(
                            "Contains a letter",
                            hasLetter,
                          ),
                          buildCondition(
                            "Contains a symbol",
                            hasSymbol,
                          ),
                        ],
                      ),
                    ),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          showPasswordError ? _animation.value : 0,
                          0,
                        ),
                        child: child,
                      );
                    },
                    child: TextField(
                      controller: password,
                      focusNode: passwordFocusNode,
                      obscureText: hidePassword,
                      onChanged: (value) {
                        checkPassword(value);
                        setState(() {
                          showPasswordError = false;
                          passwordsMatch =
                              confirmPassword.text == password.text;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: showPasswordError
                                ? Colors.red
                                : Colors.grey.shade500,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: showPasswordError
                                ? Colors.red
                                : (isPasswordValid()
                                ? Colors.green
                                : Colors.grey),
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () async {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          showConfirmError ? _animation.value : 0,
                          0,
                        ),
                        child: child,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: confirmPassword,
                          obscureText: hideConfirmPassword,
                          onChanged: (value) {
                            setState(() {
                              isTypingConfirm = value.isNotEmpty;
                              passwordsMatch = value == password.text;
                              showConfirmError = false;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Confirm Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isTypingConfirm)
                                  Icon(
                                    passwordsMatch
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: passwordsMatch
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    hideConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      hideConfirmPassword =
                                      !hideConfirmPassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: showConfirmError
                                    ? Colors.red
                                    : Colors.grey.shade500,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: showConfirmError
                                    ? Colors.red
                                    : (!isTypingConfirm
                                    ? Colors.grey
                                    : (passwordsMatch
                                    ? Colors.green
                                    : Colors.red)),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (isTypingConfirm)
                          Row(
                            children: [
                              Icon(
                                passwordsMatch
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color:
                                passwordsMatch ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                passwordsMatch
                                    ? "Password confirmed"
                                    : "Passwords do not match",
                                style: TextStyle(
                                  color: passwordsMatch
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {

                        if (name.text.trim().isEmpty ||
                            email.text.trim().isEmpty ||
                            password.text.isEmpty ||
                            confirmPassword.text.isEmpty) {

                          setState(() {
                            showNameError = name.text.trim().isEmpty;
                            showEmailError = email.text.trim().isEmpty;
                            showPasswordError = password.text.isEmpty;
                            showConfirmError = confirmPassword.text.isEmpty;
                          });

                          _controller.forward(from: 0);

                          return;
                        }

                        if (!isPasswordValid()) {

                          setState(() {
                            showPasswordError = true;
                          });

                          _controller.forward(from: 0);

                          return;
                        }

                        if (password.text != confirmPassword.text) {

                          setState(() {
                            showConfirmError = true;
                          });

                          _controller.forward(from: 0);

                          return;
                        }

                        try {

                          final credential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: email.text.trim(),
                            password: password.text.trim(),
                          );

                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(credential.user!.uid)
                              .set({

                            "uid": credential.user!.uid,
                            "name": name.text.trim(),
                            "email": email.text.trim(),
                            "role": "user",
                            "gender": "",
                            "age": "",
                            "height": "",
                            "weight": "",
                            "activity": "",
                            "goal": "",
                            "createdAt": FieldValue.serverTimestamp(),

                          });

                          AppUserData.name = name.text.trim();
                          AppUserData.email = email.text.trim();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GenderPage(),
                            ),
                          );

                        } on FirebaseAuthException catch (e) {

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.message ?? "Sign up failed"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}