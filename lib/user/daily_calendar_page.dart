import 'package:flutter/material.dart';

class DailyCalendarPage extends StatefulWidget {
  final DateTime selectedDate;

  const DailyCalendarPage({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DailyCalendarPage> createState() => _DailyCalendarPageState();
}

class _DailyCalendarPageState extends State<DailyCalendarPage> {
  late DateTime focusedMonth;
  late DateTime selectedDay;

  static const Color darkGreen = Color(0xFF2E7D5A);
  static const Color accentOrange = Color(0xFFFFA94D);

  @override
  void initState() {
    super.initState();
    selectedDay = widget.selectedDate;
    focusedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _previousMonth() {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1);
    });
  }

  List<DateTime?> _monthDays() {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final startEmpty = firstDay.weekday % 7;

    final days = <DateTime?>[];

    for (int i = 0; i < startEmpty; i++) {
      days.add(null);
    }

    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(focusedMonth.year, focusedMonth.month, day));
    }

    return days;
  }

  String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return months[month - 1];
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final days = _monthDays();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkGreen),
        title: const Text(
          "Calendar",
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFA8E6CF),
                    Color(0xFFFFD3A5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: darkGreen,
                      size: 32,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${_monthName(focusedMonth.month)} ${focusedMonth.year}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: darkGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: darkGreen,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                _DayName("D"),
                _DayName("L"),
                _DayName("M"),
                _DayName("M"),
                _DayName("J"),
                _DayName("V"),
                _DayName("S"),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];

                  if (day == null) {
                    return const SizedBox();
                  }

                  final selected = _sameDay(day, selectedDay);
                  final today = _sameDay(day, DateTime.now());

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? darkGreen
                            : today
                            ? accentOrange.withOpacity(0.25)
                            : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${day.day}",
                          style: TextStyle(
                            color: selected ? Colors.white : darkGreen,
                            fontWeight:
                            selected || today ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, selectedDay);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Open selected day",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayName extends StatelessWidget {
  final String text;

  const _DayName(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF2E7D5A),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}