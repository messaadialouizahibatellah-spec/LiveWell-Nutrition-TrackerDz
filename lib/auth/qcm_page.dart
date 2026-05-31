import 'package:flutter/material.dart';

class QcmPage extends StatefulWidget {
  final String question;
  final List<String> options;
  final String imagePath;
  final void Function(String) onSelected;

  final int step;
  final int totalSteps;

  const QcmPage({
    super.key,
    required this.question,
    required this.options,
    required this.onSelected,
    required this.imagePath,
    required this.step,
    required this.totalSteps,
  });

  @override
  State<QcmPage> createState() => _QcmPageState();
}

class _QcmPageState extends State<QcmPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _imageAnimation;
  late Animation<Offset> _listAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _imageAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _listAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void handleClick(String option) async {
    await Future.delayed(const Duration(milliseconds: 150));
    widget.onSelected(option);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA8E6CF), Color(0xFFFFD3A5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                // 🔙 BACK + STEP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Step ${widget.step}/${widget.totalSteps}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 10),


                LinearProgressIndicator(
                  value: widget.step / widget.totalSteps,
                  backgroundColor: Colors.white,
                  color: Colors.green,
                  minHeight: 6,
                ),

                const SizedBox(height: 30),


                ScaleTransition(
                  scale: _imageAnimation,
                  child: FadeTransition(
                    opacity: _imageAnimation,
                    child: SizedBox(
                      height: 180,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(0.08),
                          BlendMode.lighten,
                        ),
                        child: Image.asset(
                          widget.imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),


                Text(
                  widget.question,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),


                Expanded(
                  child: SlideTransition(
                    position: _listAnimation,
                    child: ListView(
                      children: widget.options.map((option) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: GestureDetector(
                            onTap: () => handleClick(option),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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