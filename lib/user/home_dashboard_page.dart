import 'package:flutter/material.dart';
import 'user_profile_page.dart';
import 'progress_stats_page.dart';
import '../meals/meals_selection_page.dart';
import '../meals/meal_quantity_page.dart';
import 'daily_calendar_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../auth/loginpage.dart';

class HomeDashboardPage extends StatefulWidget {
  final Map<String, String>? userData;

  const HomeDashboardPage({super.key, this.userData});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  bool showLoginOverlay = false;

  static const Color appGreen    = Color(0xFFA8E6CF);
  static const Color darkGreen   = Color(0xFF2E7D5A);
  static const Color accentOrange = Color(0xFFFFA94D);

  int    _caloriesGoal  = 2000;
  int    _fatGoal       = 0;
  int    _carbGoal      = 0;
  int    _proteinGoal   = 0;
  bool   _loadingGoal   = true;


  late DateTime selectedDate;
  late List<DateTime> weekDays;



  int _calculateCalorieGoal({
    required String gender,
    required String ageRange,
    required String heightRange,
    required String weightRange,
    required String activity,
    required String goal,
  }) {

    double age    = _midPoint(ageRange,    defaultValue: 25);
    double height = _midPoint(heightRange, defaultValue: 165);
    double weight = _midPoint(weightRange, defaultValue: 70);


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


  double _midPoint(String range, {double defaultValue = 0}) {
    if (range.isEmpty) return defaultValue;
    if (range.endsWith("+")) {
      // مثل "51+" → نأخذ 55
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


  void _calcMacroGoals(int calories) {

    _fatGoal     = ((calories * 0.30) / 9).round();
    _carbGoal    = ((calories * 0.40) / 4).round();
    _proteinGoal = ((calories * 0.30) / 4).round();
  }


  Future<void> _loadUserGoal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingGoal = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() => _loadingGoal = false);
        return;
      }

      final data = doc.data()!;

      final goal = _calculateCalorieGoal(
        gender:      data["gender"]   ?? "male",
        ageRange:    data["age"]      ?? "21-30",
        heightRange: data["height"]   ?? "161-170",
        weightRange: data["weight"]   ?? "61-70",
        activity:    data["activity"] ?? "moderate",
        goal:        data["goal"]     ?? "maintain",
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"caloriesGoal": goal});

      setState(() {
        _caloriesGoal = goal;
        _calcMacroGoals(goal);
        _loadingGoal  = false;
      });
    } catch (_) {
      setState(() => _loadingGoal = false);
    }
  }


  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }


  @override
  void initState() {
    super.initState();
    if (widget.userData?["fromRoom"] == "true") {
      Future.delayed(Duration.zero, () async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        final dateKey = _dateKey(DateTime.now());

        final mealType = widget.userData?["mealType"] ?? "Breakfast";

        await FirebaseFirestore.instance
            .collection("user_meals")
            .doc("${uid}_${mealType}_$dateKey")
            .set({
          "userUid": uid,
          "mealType": mealType,
          "dateKey": dateKey,
          "description": widget.userData?["description"],
          "calories": widget.userData?["calories"],
          "items": widget.userData?["items"],
          "updatedAt": Timestamp.now(),
        });
      });
    }

    selectedDate = DateTime.now();
    weekDays = _generateWeekDays(selectedDate);

    final isGuest = FirebaseAuth.instance.currentUser == null;

    if (isGuest) {
      showLoginOverlay = true;
      _loadingGoal = false;
    } else {
      _loadUserGoal();
    }
  }

  List<DateTime> _generateWeekDays(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday % 7));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }


  double _mealValue(Map<String, dynamic>? meal, String key) {
    if (meal == null) return 0.0;
    final v = meal[key];
    if (v is num) return v.toDouble();
    return double.tryParse(
      v.toString().replaceAll(" kcal", ""),
    ) ?? 0.0;
  }


  Future<void> _selectMeal({
    required String title,
    Map<String, dynamic>? existingMeal,
  }) async {
    final existingItems =
        (existingMeal?["items"] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
            [];

    final selectedProducts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealsSelectionPage(
          initialSelectedMeals: existingItems,
        ),
      ),
    );
    if (selectedProducts == null) return;

    final products = List<Map<String, dynamic>>.from(selectedProducts);

    if (products.isEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final dateKey = _dateKey(selectedDate);
      final docId = "${uid}_${title}_$dateKey";

      await FirebaseFirestore.instance
          .collection("user_meals")
          .doc(docId)
          .delete();

      if (!mounted) return;

      setState(() {});

      return;
    }

    final meal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealQuantityPage(
          mealTitle: title,
          selectedProducts: products,
        ),
      ),
    );
    if (meal == null) return;

    final uid      = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final dateKey  = _dateKey(selectedDate);
    final docId    = "${uid}_${title}_$dateKey";   // ← مرتبط باليوم

    await FirebaseFirestore.instance
        .collection("user_meals")
        .doc(docId)
        .set({
      "userUid":   uid,
      "mealType":  title,
      "dateKey":   dateKey,
      ...Map<String, dynamic>.from(meal),
      "updatedAt": Timestamp.now(),
    });
    if (!mounted) return;

    setState(() {
      selectedDate = DateTime.now();
      weekDays = _generateWeekDays(selectedDate);
    });
  }

  void _goToPreviousDay() => setState(() {
    selectedDate = selectedDate.subtract(const Duration(days: 1));
    weekDays     = _generateWeekDays(selectedDate);
  });

  void _goToNextDay() => setState(() {
    selectedDate = selectedDate.add(const Duration(days: 1));
    weekDays     = _generateWeekDays(selectedDate);
  });

  Future<void> _openCalendarPage() async {
    final picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCalendarPage(selectedDate: selectedDate),
      ),
    );
    if (picked is DateTime) {
      setState(() {
        selectedDate = picked;
        weekDays     = _generateWeekDays(selectedDate);
      });
    }
  }

  String _headerTitle() {
    final now = DateTime.now();
    if (selectedDate.day   == now.day &&
        selectedDate.month == now.month &&
        selectedDate.year  == now.year) return "Aujourd'hui";
    return "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
  }


  @override
  Widget build(BuildContext context) {
    if (_loadingGoal) {
      return const Center(child: CircularProgressIndicator());
    }

    final uid      = FirebaseAuth.instance.currentUser?.uid ?? "";
    final dateKey  = _dateKey(selectedDate);

    final mealsStream = FirebaseFirestore.instance
        .collection("user_meals")
        .where("userUid", isEqualTo: uid)
        .where("dateKey", isEqualTo: dateKey)
        .snapshots();

    return Stack(
      children: [
      StreamBuilder<QuerySnapshot>(
      stream: mealsStream,
      builder: (context, snapshot) {

        final Map<String, Map<String, dynamic>> mealsMap = {};
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final type = (data["mealType"] ?? "").toString();
            mealsMap[type] = data;
          }
        }

        final breakfastMeal = mealsMap["Breakfast"];
        final lunchMeal     = mealsMap["Lunch"];
        final dinnerMeal    = mealsMap["Dinner"];
        final snacksMeal    = mealsMap["Snacks"];


        final double consumed =
            _mealValue(breakfastMeal, "calories") +
                _mealValue(lunchMeal,     "calories") +
                _mealValue(dinnerMeal,    "calories") +
                _mealValue(snacksMeal,    "calories");

        final double totalFats     =
            _mealValue(breakfastMeal, "fats")    +
                _mealValue(lunchMeal,     "fats")    +
                _mealValue(dinnerMeal,    "fats")    +
                _mealValue(snacksMeal,    "fats");

        final double totalCarbs    =
            _mealValue(breakfastMeal, "carbs")   +
                _mealValue(lunchMeal,     "carbs")   +
                _mealValue(dinnerMeal,    "carbs")   +
                _mealValue(snacksMeal,    "carbs");

        final double totalProteins =
            _mealValue(breakfastMeal, "proteins") +
                _mealValue(lunchMeal,     "proteins") +
                _mealValue(dinnerMeal,    "proteins") +
                _mealValue(snacksMeal,    "proteins");

        final int caloriesConsumed  = consumed.round();
        final int caloriesRemaining = _caloriesGoal - caloriesConsumed;

        return Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTopSection(
                  caloriesConsumed:  caloriesConsumed,
                  caloriesRemaining: caloriesRemaining,
                ),
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        _buildMacrosCard(
                          totalFats:     totalFats,
                          totalCarbs:    totalCarbs,
                          totalProteins: totalProteins,
                        ),
                        const SizedBox(height: 14),
                        _mealCard(
                          "Breakfast",
                          "Add your breakfast",
                          Icons.free_breakfast_rounded,
                          breakfastMeal,
                              () => _selectMeal(
                            title: "Breakfast",
                            existingMeal: breakfastMeal,
                          ),
                        ),
                        _mealCard(
                          "Lunch",
                          "Add your lunch",
                          Icons.lunch_dining_rounded,
                          lunchMeal,
                              () => _selectMeal(
                            title: "Lunch",
                            existingMeal: lunchMeal,
                          ),
                        ),
                        _mealCard(
                          "Dinner",
                          "Add your dinner",
                          Icons.dinner_dining_rounded,
                          dinnerMeal,
                              () => _selectMeal(
                            title: "Dinner",
                            existingMeal: dinnerMeal,
                          ),
                        ),
                        _mealCard(
                          "Snacks",
                          "Add your snacks",
                          Icons.cookie_rounded,
                          snacksMeal,
                              () => _selectMeal(
                            title: "Snacks",
                            existingMeal: snacksMeal,
                          ),
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      ),

        if (showLoginOverlay) _buildLoginOverlay(),

      ],
    );
  }

  Widget _buildTopSection({
    required int caloriesConsumed,
    required int caloriesRemaining,
  }) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topInset + 18, 18, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3CFA3), Color(0xFFE8E7CC), Color(0xFFC6EEDD)],
          stops: [0.0, 0.48, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          _buildTopHeader(),
          const SizedBox(height: 18),
          _buildWeekCalendar(),
          const SizedBox(height: 26),
          _buildCaloriesSection(
            caloriesConsumed:  caloriesConsumed,
            caloriesRemaining: caloriesRemaining,
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfilePage()),
            );

            setState(() {
              _loadingGoal = true;
            });

            await _loadUserGoal();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentOrange,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white, size: 28,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _goToPreviousDay,
          child: const Icon(Icons.chevron_left_rounded,
              color: Colors.white, size: 30),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _openCalendarPage,
            child: Text(
              _headerTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: _goToNextDay,
          child: const Icon(Icons.chevron_right_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgressStatsPage()),
          ),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentOrange,
                width: 2,
              ),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCalendar() {
    const dayLetters = ["D", "L", "M", "M", "J", "V", "S"];
    return SizedBox(
      height: 96,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(weekDays.length, (i) {
          final day = weekDays[i];
          final isSelected =
              day.day == selectedDate.day &&
                  day.month == selectedDate.month &&
                  day.year  == selectedDate.year;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                selectedDate = day;
                weekDays     = _generateWeekDays(selectedDate);
              }),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [
                      Colors.white.withOpacity(0.24),
                      Colors.white.withOpacity(0.10),
                    ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dayLetters[i],
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 16)),
                      const SizedBox(height: 6),
                      Text("${day.day}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 24,
                          )),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCaloriesSection({
    required int caloriesConsumed,
    required int caloriesRemaining,
  }) {
    final progress = (caloriesConsumed / _caloriesGoal).clamp(0.0, 1.0);
    final exceeded = caloriesConsumed > _caloriesGoal;
    final reached  = caloriesConsumed == _caloriesGoal;
    final progressColor = exceeded ? Colors.red : darkGreen;

    String? message;
    if (exceeded) message = "You exceeded your calories goal";
    else if (reached) message = "Perfect goal reached 🎯";

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _smallStat("$caloriesConsumed", "consommé")),
            SizedBox(
              width: 150, height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150, height: 150,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$caloriesRemaining",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "kcal restants",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _smallStat("$_caloriesGoal", "objectif")),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: progressColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _smallStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            )),
        const SizedBox(height: 6),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
      ],
    );
  }

  Widget _buildMacrosCard({
    required double totalFats,
    required double totalCarbs,
    required double totalProteins,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MacroItem(
              letter: "L",
              current: totalFats.round(),
              goal: _fatGoal,
              dotColor: appGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MacroItem(
              letter: "G",
              current: totalCarbs.round(),
              goal: _carbGoal,
              dotColor: const Color(0xFF7C83FD),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MacroItem(
              letter: "P",
              current: totalProteins.round(),
              goal: _proteinGoal,
              dotColor: accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealCard(
      String title,
      String subtitle,
      IconData icon,
      Map<String, dynamic>? meal,
      VoidCallback onTap,
      ) {
    final hasMeal  = meal != null;
    final calories = hasMeal ? _mealValue(meal, "calories") : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: darkGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    hasMeal
                        ? "${meal["description"] ?? ""}"
                        : subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  if (hasMeal) ...[
                    const SizedBox(height: 5),
                    Text(
                      "${calories.toStringAsFixed(0)} kcal",
                      style: const TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hasMeal ? "Edit" : "Add",
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
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
                            letterSpacing: 0.5,
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
}


class _MacroItem extends StatelessWidget {
  final String letter;
  final int    current;
  final int    goal;
  final Color  dotColor;

  const _MacroItem({
    required this.letter,
    required this.current,
    required this.goal,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = goal > 0
        ? (current / goal).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(builder: (context, constraints) {
      final double barWidth = constraints.maxWidth;

      return Column(
        children: [
          Row(
            children: [
              Text(letter,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: dotColor,
                    fontSize: 18,
                  )),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$current / $goal",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 4,
                width: barWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E7E7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                height: 4,
                width: barWidth * ratio,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}