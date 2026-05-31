import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../nutritionist/nutritionist_dashboard.dart';
import 'welcome_page.dart';

class NutritionistSignUpPage extends StatefulWidget {
  const NutritionistSignUpPage({super.key});

  @override
  State<NutritionistSignUpPage> createState() =>
      _NutritionistSignUpPageState();
}

class _NutritionistSignUpPageState extends State<NutritionistSignUpPage>
    with SingleTickerProviderStateMixin {
  final idController = TextEditingController();
  final nameController = TextEditingController();
  final officialTitleController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedWilaya;
  String? selectedGender;

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  bool hasMinLength = false;
  bool hasNumber = false;
  bool hasLetter = false;
  bool hasSymbol = false;

  bool passwordsMatch = false;
  bool isTypingConfirm = false;
  final FocusNode passwordFocusNode = FocusNode();
  bool showPasswordConditions = false;

  bool showPasswordError = false;
  bool showConfirmError = false;
  bool showIdError = false;
  bool showNameError = false;
  bool showTitleError = false;
  bool showGenderError = false;
  bool showWilayaError = false;
  bool showEmailError = false;


  late AnimationController _controller;
  late Animation<double> _animation;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey idKey = GlobalKey();
  final GlobalKey genderKey = GlobalKey();
  final GlobalKey wilayaKey = GlobalKey();
  final GlobalKey emailKey = GlobalKey();

  final List<String> wilayas = const [
    "01 - Adrar",
    "02 - Chlef",
    "03 - Laghouat",
    "04 - Oum El Bouaghi",
    "05 - Batna",
    "06 - Béjaïa",
    "07 - Biskra",
    "08 - Béchar",
    "09 - Blida",
    "10 - Bouira",
    "11 - Tamanrasset",
    "12 - Tébessa",
    "13 - Tlemcen",
    "14 - Tiaret",
    "15 - Tizi Ouzou",
    "16 - Alger",
    "17 - Djelfa",
    "18 - Jijel",
    "19 - Sétif",
    "20 - Saïda",
    "21 - Skikda",
    "22 - Sidi Bel Abbès",
    "23 - Annaba",
    "24 - Guelma",
    "25 - Constantine",
    "26 - Médéa",
    "27 - Mostaganem",
    "28 - M'Sila",
    "29 - Mascara",
    "30 - Ouargla",
    "31 - Oran",
    "32 - El Bayadh",
    "33 - Illizi",
    "34 - Bordj Bou Arréridj",
    "35 - Boumerdès",
    "36 - El Tarf",
    "37 - Tindouf",
    "38 - Tissemsilt",
    "39 - El Oued",
    "40 - Khenchela",
    "41 - Souk Ahras",
    "42 - Tipaza",
    "43 - Mila",
    "44 - Aïn Defla",
    "45 - Naâma",
    "46 - Aïn Témouchent",
    "47 - Ghardaïa",
    "48 - Relizane",
    "49 - Timimoun",
    "50 - Bordj Badji Mokhtar",
    "51 - Ouled Djellal",
    "52 - Béni Abbès",
    "53 - In Salah",
    "54 - In Guezzam",
    "55 - Touggourt",
    "56 - Djanet",
    "57 - El M'Ghair",
    "58 - El Menia",
  ];

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
        showPasswordConditions =
            passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    officialTitleController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void checkPassword(String value) {
    setState(() {
      hasMinLength = value.length >= 7;
      hasNumber = RegExp(r'[0-9]').hasMatch(value);
      hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
      hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
      showPasswordError = false;
      passwordsMatch =
          confirmPasswordController.text == passwordController.text;
    });
  }

  bool isPasswordValid() {
    return hasMinLength && hasNumber && hasLetter && hasSymbol;
  }

  bool isValidId(String value) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6}$').hasMatch(value);
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
  Future<void> _scrollToField(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.25,
    );
  }
  Future<void> createAccount() async {
    setState(() {
      showIdError = idController.text.trim().isEmpty;
      showNameError = nameController.text.trim().isEmpty;
      showTitleError = officialTitleController.text.trim().isEmpty;
      showGenderError = selectedGender == null;
      showWilayaError = selectedWilaya == null;
      showEmailError = emailController.text.trim().isEmpty;
      showPasswordError = passwordController.text.isEmpty;
      showConfirmError = confirmPasswordController.text.isEmpty;
    });

    if (showIdError ||
        showNameError ||
        showTitleError ||
        showGenderError ||
        showWilayaError ||
        showEmailError ||
        showPasswordError ||
        showConfirmError) {
      _controller.forward(from: 0);
      if (showIdError) {
        await _scrollToField(idKey);
      } else if (showNameError) {
        await _scrollController.animateTo(120, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showTitleError) {
        await _scrollController.animateTo(200, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showGenderError) {
        await _scrollToField(genderKey);
      } else if (showWilayaError) {
        await _scrollToField(wilayaKey);
      } else if (showEmailError) {
        await _scrollToField(emailKey);
      } else if (showPasswordError) {
        await _scrollController.animateTo(520, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showConfirmError) {
        await _scrollController.animateTo(680, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
      return;
    }

    if (!isValidId(idController.text.trim())) {
      setState(() {
        showIdError = true;
      });
      _controller.forward(from: 0);
      if (showIdError) {
        await _scrollToField(idKey);
      } else if (showNameError) {
        await _scrollController.animateTo(120, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showTitleError) {
        await _scrollController.animateTo(200, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showGenderError) {
        await _scrollToField(genderKey);
      } else if (showWilayaError) {
        await _scrollToField(wilayaKey);
      } else if (showEmailError) {
        await _scrollToField(emailKey);
      } else if (showPasswordError) {
        await _scrollController.animateTo(520, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showConfirmError) {
        await _scrollController.animateTo(680, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
      return;
    }

    if (!isPasswordValid()) {
      setState(() {
        showPasswordError = true;
      });
      _controller.forward(from: 0);
      if (showIdError) {
        await _scrollToField(idKey);
      } else if (showNameError) {
        await _scrollController.animateTo(120, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showTitleError) {
        await _scrollController.animateTo(200, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showGenderError) {
        await _scrollToField(genderKey);
      } else if (showWilayaError) {
        await _scrollToField(wilayaKey);
      } else if (showEmailError) {
        await _scrollToField(emailKey);
      } else if (showPasswordError) {
        await _scrollController.animateTo(520, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showConfirmError) {
        await _scrollController.animateTo(680, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        showConfirmError = true;
        passwordsMatch = false;
        isTypingConfirm = true;
      });
      _controller.forward(from: 0);
      if (showIdError) {
        await _scrollToField(idKey);
      } else if (showNameError) {
        await _scrollController.animateTo(120, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showTitleError) {
        await _scrollController.animateTo(200, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showGenderError) {
        await _scrollToField(genderKey);
      } else if (showWilayaError) {
        await _scrollToField(wilayaKey);
      } else if (showEmailError) {
        await _scrollToField(emailKey);
      } else if (showPasswordError) {
        await _scrollController.animateTo(520, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else if (showConfirmError) {
        await _scrollController.animateTo(680, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
      return;
    }
    final enteredId = idController.text.trim();

    final cardDoc = await FirebaseFirestore.instance
        .collection("professional_cards")
        .doc(enteredId)
        .get();

    if (!cardDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Nutritionist ID"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cardData = cardDoc.data()!;

    if (cardData["isActive"] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This ID is disabled"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cardData["used"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This ID has already been used"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection("nutritionists")
          .doc(credential.user!.uid)
          .set({
        "uid": credential.user!.uid,
        "nutritionistId": idController.text.trim(),
        "name": nameController.text.trim(),
        "officialTitle": officialTitleController.text.trim(),
        "specialty": officialTitleController.text.trim(),
        "email": emailController.text.trim(),
        "wilaya": selectedWilaya,
        "gender": selectedGender!.toLowerCase(),
        "profileImage": selectedGender!.toLowerCase() == "male"
            ? "assets/images/nutritionist_male.png"
            : "assets/images/nutritionist_female.png",
        "bio": "",
        "role": "nutritionist",
        "rating": 0,
        "reviewsCount": 0,
        "createdAt": Timestamp.now(),
      });
      await FirebaseFirestore.instance
          .collection("professional_cards")
          .doc(enteredId)
          .update({
        "email": emailController.text.trim(),
        "used": true,
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const WelcomePage(
            isNutritionist: true,
          ),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Signup failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget normalField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required bool hasError,
    required VoidCallback onClearError,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(hasError ? _animation.value : 0, 0),
          child: child,
        );
      },
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => onClearError(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.shade500,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.green,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget wilayaDropdown() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset:
          Offset(showWilayaError ? _animation.value : 0, 0),
          child: child,
        );
      },
      child: DropdownButtonFormField<String>(
        value: selectedWilaya,
        isExpanded: true,
        menuMaxHeight: 300,

        decoration: InputDecoration(
          hintText: "Wilaya",
          prefixIcon: const Icon(Icons.location_on_outlined),
          filled: true,
          fillColor: Colors.white,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: showWilayaError
                  ? Colors.red
                  : Colors.grey.shade500,
              width: 1.5,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: showWilayaError
                  ? Colors.red
                  : Colors.green,
              width: 2,
            ),
          ),
        ),

        items: wilayas.map((wilaya) {
          return DropdownMenuItem<String>(
            value: wilaya,
            child: Text(wilaya),
          );
        }).toList(),

        onChanged: (value) {
          setState(() {
            selectedWilaya = value;
            showWilayaError = false;
          });
        },
      ),
    );
  }
  Widget genderDropdown() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(showGenderError ? _animation.value : 0, 0),
          child: child,
        );
      },
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: "Gender",
          prefixIcon: const Icon(Icons.wc_rounded),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: showGenderError ? Colors.red : Colors.grey.shade500,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: showGenderError ? Colors.red : Colors.green,
              width: 2,
            ),
          ),
        ),
        items: const [
          DropdownMenuItem(value: "Female", child: Text("Female")),
          DropdownMenuItem(value: "Male", child: Text("Male")),
        ],
        onChanged: (value) {
          setState(() {
            selectedGender = value;
            showGenderError = false;
          });
        },
      ),
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
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              25,
              20,
              25,
              MediaQuery.of(context).viewInsets.bottom + 25,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF2E7D5A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Image.asset(
                  "assets/images/logos1.png",
                  height: 110,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Create Nutritionist Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Create your specialist profile",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 35),

                KeyedSubtree(
                  key: idKey,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(showIdError ? _animation.value : 0, 0),
                        child: child,
                      );
                    },
                    child: TextField(
                      controller: idController,
                      maxLength: 6,
                      onChanged: (_) {
                        setState(() {
                          showIdError = false;
                        });
                      },
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "Nutritionist ID",
                        prefixIcon: const Icon(Icons.badge_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: showIdError
                                ? Colors.red
                                : Colors.grey.shade500,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: showIdError ? Colors.red : Colors.green,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                normalField(
                  controller: nameController,
                  hint: "Full Name",
                  icon: Icons.person_outline,
                  hasError: showNameError,
                  onClearError: () {
                    setState(() {
                      showNameError = false;
                    });
                  },
                ),

                const SizedBox(height: 18),

                normalField(
                  controller: officialTitleController,
                  hint: "Official Title",
                  icon: Icons.workspace_premium_outlined,
                  hasError: showTitleError,
                  onClearError: () {
                    setState(() {
                      showTitleError = false;
                    });
                  },
                ),
                const SizedBox(height: 18),

                KeyedSubtree(
                  key: genderKey,
                  child: genderDropdown(),
                ),

                const SizedBox(height: 18),

                KeyedSubtree(
                  key: wilayaKey,
                  child: wilayaDropdown(),
                ),

                const SizedBox(height: 18),

                KeyedSubtree(
                  key: emailKey,
                  child: normalField(
                    controller: emailController,
                    hint: "Email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    hasError: showEmailError,
                    onClearError: () {
                      setState(() {
                        showEmailError = false;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 18),
                if (showPasswordConditions ||
                    passwordController.text.isNotEmpty)
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
                      offset:
                      Offset(showPasswordError ? _animation.value : 0, 0),
                      child: child,
                    );
                  },
                  child: TextField(
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    obscureText: hidePassword,
                    onChanged: checkPassword,
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
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

      AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset:
                      Offset(showConfirmError ? _animation.value : 0, 0),
                      child: child,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: hideConfirmPassword,
                        onChanged: (value) {
                          setState(() {
                            isTypingConfirm = value.isNotEmpty;
                            passwordsMatch = value == passwordController.text;
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
                                onPressed: () {
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
                              color: passwordsMatch ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              passwordsMatch
                                  ? "Password confirmed"
                                  : "Passwords do not match",
                              style: TextStyle(
                                color:
                                passwordsMatch ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: createAccount,
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
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
    ],
            ),
          ),
        ),
      ),
    );
  }
}

