import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DrinkWaterPage extends StatefulWidget {
  const DrinkWaterPage({super.key});

  @override
  State<DrinkWaterPage> createState() => _DrinkWaterPageState();
}

class _DrinkWaterPageState extends State<DrinkWaterPage>
    with SingleTickerProviderStateMixin {
  static const int maxWaterMl = 2000;
  static const int stepMl = 250;

  int waterMl = 0;
  late final AnimationController _waveController;
  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  DocumentReference<Map<String, dynamic>>? _todayWaterRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection("water_tracking")
        .doc(user.uid)
        .collection("days")
        .doc(_dateKey(DateTime.now()));
  }

  Future<void> _loadWater() async {
    final ref = _todayWaterRef();
    if (ref == null) return;

    final doc = await ref.get();

    if (doc.exists) {
      setState(() {
        waterMl = (doc.data()?["waterMl"] ?? 0) as int;
      });
    }
  }

  Future<void> _saveWater() async {
    final ref = _todayWaterRef();
    if (ref == null) return;

    await ref.set({
      "waterMl": waterMl,
      "date": _dateKey(DateTime.now()),
      "updatedAt": Timestamp.now(),
    }, SetOptions(merge: true));
  }

  double get progress => (waterMl / maxWaterMl).clamp(0.0, 1.0);
  bool get isEmpty => waterMl == 0;
  bool get isLow => waterMl > 0 && waterMl < 1500;
  bool get isGood => waterMl >= 1500;

  Color get statusColor {
    if (isEmpty) return const Color(0xFFE74C3C);
    if (isLow) return const Color(0xFFFF9800);
    return const Color(0xFF2EAD4A);
  }

  IconData get statusIcon {
    if (isEmpty) return Icons.warning_amber_rounded;
    if (isLow) return Icons.local_drink_rounded;
    return Icons.check_rounded;
  }

  String get statusMessage {
    if (isEmpty) return "You need to drink water for your health.";
    if (isLow) return "Good job! Keep drinking more water.";
    return "Excellent! You are taking great care of your health.";
  }

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _loadWater();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _addWater() {
    setState(() {
      waterMl += stepMl;
      if (waterMl > maxWaterMl) {
        waterMl = maxWaterMl;
      }
    });

    _saveWater();
  }

  void _removeWater() {
    setState(() {
      waterMl -= stepMl;
      if (waterMl < 0) {
        waterMl = 0;
      }
    });

    _saveWater();
  }

  void _showMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: statusColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Row(
          children: [
            Icon(statusIcon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.035,
            vertical: size.height * 0.012,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: size.width * 0.012,
                  top: size.height * 0.006,
                  bottom: size.height * 0.018,
                ),
                child: const Text(
                  "Drink Water",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D5A),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: size.width * 0.012,
                  bottom: size.height * 0.015,
                ),
                child: const Text(
                  "Stay hydrated and take care of your body.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final h = c.maxHeight;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        w * 0.02,
                        h * 0.01,
                        w * 0.02,
                        h * 0.01,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 58,
                            child: _BottleSection(
                              waterMl: waterMl,
                              progress: progress,
                              waveController: _waveController,
                            ),
                          ),
                          SizedBox(width: w * 0.03),
                          Expanded(
                            flex: 42,
                            child: _RightPanel(
                              waterMl: waterMl,
                              maxWaterMl: maxWaterMl,
                              onAdd: _addWater,
                              onRemove: _removeWater,
                              onDone: _showMessage,
                              statusColor: statusColor,
                              statusIcon: statusIcon,
                              statusMessage: statusMessage,
                              isFull: waterMl >= maxWaterMl,
                              isEmpty: waterMl == 0,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottleSection extends StatelessWidget {
  final int waterMl;
  final double progress;
  final AnimationController waveController;

  const _BottleSection({
    required this.waterMl,
    required this.progress,
    required this.waveController,
  });

  @override
  Widget build(BuildContext context) {
    const marks = [2000, 1500, 1000, 500, 250];

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;

        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  top: h * 0.18,
                  left: w * 0.01,
                  right: w * 0.02,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: marks.map((mark) {
                    return Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.03,
                            vertical: h * 0.008,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4D56D),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "$mark ml",
                            style: TextStyle(
                              fontSize: w * 0.032,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8A6717),
                            ),
                          ),
                        ),
                        SizedBox(width: w * 0.03),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey.withOpacity(0.35),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            _Bottle(
              progress: progress,
              ml: waterMl,
              controller: waveController,
            ),
          ],
        );
      },
    );
  }
}

class _RightPanel extends StatelessWidget {
  final int waterMl;
  final int maxWaterMl;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDone;
  final Color statusColor;
  final IconData statusIcon;
  final String statusMessage;
  final bool isFull;
  final bool isEmpty;

  const _RightPanel({
    required this.waterMl,
    required this.maxWaterMl,
    required this.onAdd,
    required this.onRemove,
    required this.onDone,
    required this.statusColor,
    required this.statusIcon,
    required this.statusMessage,
    required this.isFull,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;

        return Column(
          children: [
            SizedBox(height: h * 0.12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.065),
              decoration: BoxDecoration(
                color: const Color(0xFFF4D27B),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: w * 0.07,
                        backgroundColor: const Color(0xFFECC65E),
                        child: Icon(
                          Icons.water_drop_rounded,
                          size: w * 0.075,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: w * 0.04),
                      Expanded(
                        child: Text(
                          "Water",
                          style: TextStyle(
                            fontSize: w * 0.095,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6C4D13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h * 0.024),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: h * 0.026),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF1),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$waterMl ml",
                        style: TextStyle(
                          fontSize: w * 0.135,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.016),
                  Text(
                    "/ $maxWaterMl ml",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: w * 0.075,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: h * 0.035),
            _SquareActionButton(
              icon: Icons.add_rounded,
              onTap: isFull ? null : onAdd,
            ),
            SizedBox(height: h * 0.022),
            _SquareActionButton(
              icon: Icons.remove_rounded,
              onTap: isEmpty ? null : onRemove,
            ),
            SizedBox(height: h * 0.020),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.035,
                vertical: h * 0.012,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: statusColor.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: w * 0.08,
                  ),
                  SizedBox(width: w * 0.025),
                  Expanded(
                    child: Text(
                      statusMessage,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: w * 0.062,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onDone,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: w * 0.22,
                height: w * 0.22,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  statusIcon,
                  color: Colors.white,
                  size: w * 0.10,
                ),
              ),
            ),
            SizedBox(height: h * 0.015),
          ],
        );
      },
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _SquareActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth * 0.58, 66.0);
        final disabled = onTap == null;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: disabled ? 0.45 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFFF2D06D),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: size * 0.5,
                color: const Color(0xFF6F5313),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bottle extends StatelessWidget {
  final double progress;
  final int ml;
  final AnimationController controller;

  const _Bottle({
    required this.progress,
    required this.ml,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final double bottleHeight = c.maxHeight * 0.88;
        final double bottleWidth = c.maxWidth * 0.72;
        final double neckWidth = bottleWidth * 0.44;
        final double neckHeight = bottleHeight * 0.13;
        final double capWidth = bottleWidth * 0.52;
        final double capHeight = bottleHeight * 0.11;
        final double bodyHeight = bottleHeight * 0.78;
        final double waterHeight = bodyHeight * progress;

        return Center(
          child: SizedBox(
            width: bottleWidth + 24,
            height: bottleHeight,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: capHeight * 0.9,
                  child: Container(
                    width: neckWidth,
                    height: neckHeight,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE8F2FF),
                          Color(0xFFD4E5FB),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: capHeight + neckHeight * 0.42,
                  child: ClipPath(
                    clipper: _RealBottleClipper(),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          width: bottleWidth,
                          height: bodyHeight,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFEAF4FF),
                                Color(0xFFD7E8FC),
                              ],
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeInOut,
                          width: bottleWidth,
                          height: waterHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFA5D7FF),
                                        Color(0xFF6CB6FF),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: controller,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: _WavePainter(
                                        animationValue: controller.value,
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
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    width: capWidth,
                    height: capHeight,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF5FA2FF),
                          Color(0xFF2E79E6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E79E6).withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: capHeight + 14,
                  child: Container(
                    width: neckWidth * 0.9,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  left: bottleWidth * 0.18,
                  top: capHeight + neckHeight * 0.65,
                  child: Container(
                    width: bottleWidth * 0.08,
                    height: bodyHeight * 0.72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      "$ml ml",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3F6FBE),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RealBottleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(w * 0.24, 0);
    path.quadraticBezierTo(w * 0.12, h * 0.08, w * 0.08, h * 0.22);
    path.quadraticBezierTo(w * 0.03, h * 0.35, w * 0.03, h * 0.50);

    path.lineTo(w * 0.03, h * 0.92);
    path.quadraticBezierTo(w * 0.03, h, w * 0.15, h);
    path.lineTo(w * 0.85, h);
    path.quadraticBezierTo(w * 0.97, h, w * 0.97, h * 0.92);

    path.lineTo(w * 0.97, h * 0.50);
    path.quadraticBezierTo(w * 0.97, h * 0.35, w * 0.92, h * 0.22);
    path.quadraticBezierTo(w * 0.88, h * 0.08, w * 0.76, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _WavePainter extends CustomPainter {
  final double animationValue;

  _WavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 8.0;
    final waveLength = size.width / 1.2;

    path.moveTo(0, 20);

    for (double x = 0; x <= size.width; x++) {
      final y = 20 +
          math.sin(
            (x / waveLength * 2 * math.pi) +
                (animationValue * 2 * math.pi),
          ) *
              waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}