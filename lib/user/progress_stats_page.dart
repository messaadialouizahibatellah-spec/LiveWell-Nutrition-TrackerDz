import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressStatsPage extends StatefulWidget {
  const ProgressStatsPage({super.key});

  @override
  State<ProgressStatsPage> createState() => _ProgressStatsPageState();
}

class _ProgressStatsPageState extends State<ProgressStatsPage> {
  String selectedPeriod = "Weekly";
  String selectedType = "Calories";
  List<double> firebaseData = [];
  bool isLoading = true;

  List<String> _labels() {
    if (selectedPeriod == "Weekly") {
      return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    }

    if (selectedPeriod == "Monthly") {
      return ["D1", "D5", "D10", "D15", "D20", "D25", "D30"];
    }

    return ["Jan", "Mar", "May", "Jul", "Sep", "Nov", "Dec"];
  }

  int _daysCount() {
    if (selectedPeriod == "Weekly") return 7;
    if (selectedPeriod == "Monthly") return 30;
    return 365;
  }

  List<double> _toSevenPoints(List<double> values) {
    if (values.length <= 7) return values;

    final result = <double>[];
    final chunkSize = values.length / 7;

    for (int i = 0; i < 7; i++) {
      final start = (i * chunkSize).floor();
      final end = ((i + 1) * chunkSize).floor().clamp(start + 1, values.length);

      final chunk = values.sublist(start, end);
      final total = chunk.fold<double>(0, (sum, value) => sum + value);

      result.add(total);
    }

    return result;
  }


  String _unit() {
    if (selectedType == "Calories") return "kcal";
    if (selectedType == "Water") return "ml";
    return "g";
  }

  IconData _typeIcon() {
    if (selectedType == "Calories") {
      return Icons.local_fire_department_rounded;
    }
    if (selectedType == "Water") {
      return Icons.water_drop_rounded;
    }
    return Icons.fitness_center_rounded;
  }

  Color _typeColor() {
    if (selectedType == "Calories") {
      return const Color(0xFFFFA94D);
    }
    if (selectedType == "Water") {
      return const Color(0xFF6AA5E8);
    }
    return const Color(0xFF7C83FD);
  }
  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
  Future<void> _loadCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<double> tempData = [];
    DateTime now = DateTime.now();
    final daysCount = _daysCount();

    for (int i = 0; i < daysCount; i++) {
      final day = now.subtract(Duration(days: daysCount - 1 - i));
      final dateKey = _dateKey(day);

      double total = 0;

      final snapshot = await FirebaseFirestore.instance
          .collection("user_meals")
          .where("userUid", isEqualTo: user.uid)
          .where("dateKey", isEqualTo: dateKey)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final caloriesValue = data["calories"];

        if (caloriesValue is num) {
          total += caloriesValue.toDouble();
        } else {
          total += double.tryParse(
            caloriesValue.toString().replaceAll(" kcal", "").trim(),
          ) ??
              0;
        }
      }

      tempData.add(total);
    }

    if (!mounted) return;

    setState(() {
      firebaseData = _toSevenPoints(tempData);
      isLoading = false;
    });
  }
  Future<void> _loadMacros() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<double> tempData = [];
    DateTime now = DateTime.now();
    final daysCount = _daysCount();

    for (int i = 0; i < daysCount; i++) {
      final day = now.subtract(Duration(days: daysCount - 1 - i));
      final dateKey = _dateKey(day);

      double total = 0;

      final snapshot = await FirebaseFirestore.instance
          .collection("user_meals")
          .where("userUid", isEqualTo: user.uid)
          .where("dateKey", isEqualTo: dateKey)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += (data["proteins"] as num?)?.toDouble() ?? 0;
        total += (data["carbs"] as num?)?.toDouble() ?? 0;
        total += (data["fats"] as num?)?.toDouble() ?? 0;
      }

      tempData.add(total);
    }

    if (!mounted) return;

    setState(() {
      firebaseData = _toSevenPoints(tempData);
      isLoading = false;
    });
  }

  Future<void> _loadWater() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<double> tempData = [];
    DateTime now = DateTime.now();
    final daysCount = _daysCount();

    for (int i = 0; i < daysCount; i++) {
      final day = now.subtract(Duration(days: daysCount - 1 - i));
      final dateKey = _dateKey(day);

      final doc = await FirebaseFirestore.instance
          .collection("water_tracking")
          .doc(user.uid)
          .collection("days")
          .doc(dateKey)
          .get();

      final water = doc.exists
          ? ((doc.data()?["waterMl"] ?? 0) as num).toDouble()
          : 0.0;

      tempData.add(water);
    }

    if (!mounted) return;

    setState(() {
      firebaseData = _toSevenPoints(tempData);
      isLoading = false;
    });
  }
  Future<void> _reloadData() async {
    if (!mounted) return;

    setState(() {
      firebaseData = [];
      isLoading = true;
    });

    try {
      if (selectedType == "Calories") {
        await _loadCalories();
      } else if (selectedType == "Water") {
        await _loadWater();
      } else {
        await _loadMacros();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _loadCalories();
  }
  @override
  Widget build(BuildContext context) {
    final data = firebaseData;
    final labelData = _labels();
    final unit = _unit();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)),
        title: const Text(
          "Your Progress",
          style: TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          children: [
            _headerCard(),
            const SizedBox(height: 20),
            _typeSelector(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _periodButton("Weekly"),
                  _periodButton("Monthly"),
                  _periodButton("Yearly"),
                ],
              ),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isLoading
                  ? const Padding(
                key: ValueKey("loading"),
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D5A),
                ),
              )
                  : Container(
                key: ValueKey("$selectedType-$selectedPeriod"),
                child: _chartCard(data, labelData),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _statCard(
                  "Average",
                  "${_average(data).toStringAsFixed(0)} $unit",
                  Icons.analytics_rounded,
                ),
                const SizedBox(width: 12),
                _statCard(
                  "Best",
                  "${_max(data).toStringAsFixed(0)} $unit",
                  Icons.emoji_events_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(
                  "Lowest",
                  "${_min(data).toStringAsFixed(0)} $unit",
                  Icons.trending_down_rounded,
                ),
                const SizedBox(width: 12),
                _statCard(
                  "Total",
                  "${_total(data).toStringAsFixed(0)} $unit",
                  Icons.summarize_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFA8E6CF),
            Color(0xFFFFD3A5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _typeIcon(),
            color: const Color(0xFF2E7D5A),
            size: 52,
          ),
          const SizedBox(height: 8),
          Text(
            "Track your $selectedType progress",
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _typeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _typeButton("Calories", Icons.local_fire_department_rounded),
          _typeButton("Water", Icons.water_drop_rounded),
          _typeButton("Macros", Icons.fitness_center_rounded),
        ],
      ),
    );
  }

  Widget _typeButton(String text, IconData icon) {
    final selected = selectedType == text;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (!mounted) return;

          setState(() {
            selectedType = text;
            firebaseData = [];
            isLoading = true;
          });

          try {
            if (text == "Calories") {
              await _loadCalories();
            } else if (text == "Water") {
              await _loadWater();
            } else {
              await _loadMacros();
            }
          } catch (e) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFA8E6CF) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? const Color(0xFF1B5E3C) : const Color(0xFF2E7D5A),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : const Color(0xFF2E7D5A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodButton(String text) {
    final selected = selectedPeriod == text;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = text;
          });

          _reloadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2E7D5A) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF2E7D5A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _chartCard(List<double> data, List<String> labelData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$selectedPeriod $selectedType",
            style: const TextStyle(
              color: Color(0xFF2E7D5A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Progress overview in ${_unit()}",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 220,
            child: CustomPaint(
              size: const Size(double.infinity, 220),
              painter: LineChartPainter(
                data: data,
                labels: labelData,
                lineColor: _typeColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFFFFA94D),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF2E7D5A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _max(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  double _min(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  double _total(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b);
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;

  LineChartPainter({
    required this.data,
    required this.labels,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFFFFA94D)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final double maxValue = data.reduce((a, b) => a > b ? a : b);
    final double minValue = data.reduce((a, b) => a < b ? a : b);

    final double chartHeight = size.height - 45.0;
    final double chartWidth = size.width - 20.0;

    for (int i = 0; i < 4; i++) {
      final double y = (chartHeight / 3.0) * i.toDouble();
      canvas.drawLine(
        Offset(0.0, y),
        Offset(chartWidth, y),
        gridPaint,
      );
    }

    for (int i = 0; i < data.length; i++) {
      final double x = data.length == 1
          ? 0.0
          : (chartWidth / (data.length - 1).toDouble()) * i.toDouble();

      final double normalized = maxValue == minValue
          ? 0.5
          : ((data[i] - minValue) / (maxValue - minValue)).toDouble();

      final double y = chartHeight - (normalized * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 5.0, dotPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2.0), chartHeight + 18.0),
      );
    }

    fillPath.lineTo(chartWidth, chartHeight);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}