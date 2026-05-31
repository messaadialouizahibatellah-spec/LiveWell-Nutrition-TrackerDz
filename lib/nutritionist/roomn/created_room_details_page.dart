import 'package:flutter/material.dart';

class CreatedRoomDetailsPage extends StatelessWidget {
  final Map<String, dynamic> room;

  const CreatedRoomDetailsPage({
    super.key,
    required this.room,
  });

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  double _totalCalories() {
    final items = (room["programItems"] as List?) ?? [];
    return items.fold(0.0, (sum, item) {
      return sum + _toDouble(item["calories"]);
    });
  }

  double _totalProteins() {
    final items = (room["programItems"] as List?) ?? [];
    return items.fold(0.0, (sum, item) {
      return sum + _toDouble(item["proteins"]);
    });
  }

  double _totalCarbs() {
    final items = (room["programItems"] as List?) ?? [];
    return items.fold(0.0, (sum, item) {
      return sum + _toDouble(item["carbs"]);
    });
  }

  double _totalFats() {
    final items = (room["programItems"] as List?) ?? [];
    return items.fold(0.0, (sum, item) {
      return sum + _toDouble(item["fats"]);
    });
  }

  Widget _macroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programItems = (room["programItems"] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)),
        title: Text(
          room["name"] ?? "Room Details",
          style: const TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
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
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room["name"] ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D5A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Code: ${room["code"] ?? ""}",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room["description"] ?? "",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Program Summary",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D5A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Total Calories: ${_totalCalories().toStringAsFixed(0)} kcal",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _macroChip(
                        "P",
                        "${_totalProteins().toStringAsFixed(1)} g",
                        Colors.blue,
                      ),
                      _macroChip(
                        "G",
                        "${_totalCarbs().toStringAsFixed(1)} g",
                        Colors.orange,
                      ),
                      _macroChip(
                        "L",
                        "${_totalFats().toStringAsFixed(1)} g",
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Program Meals",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D5A),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (programItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "No meals added yet",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...programItems.map((meal) {
                final items = (meal["items"] as List?) ?? [];

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal["title"] ?? "",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D5A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meal["description"] ?? "",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Calories: ${_toDouble(meal["calories"]).toStringAsFixed(0)} kcal",
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _macroChip(
                            "P",
                            "${_toDouble(meal["proteins"]).toStringAsFixed(1)} g",
                            Colors.blue,
                          ),
                          _macroChip(
                            "G",
                            "${_toDouble(meal["carbs"]).toStringAsFixed(1)} g",
                            Colors.orange,
                          ),
                          _macroChip(
                            "L",
                            "${_toDouble(meal["fats"]).toStringAsFixed(1)} g",
                            Colors.green,
                          ),
                        ],
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          "Products:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              "- ${item["name"]} (${_toDouble(item["grams"]).toStringAsFixed(0)}g)",
                              style: const TextStyle(color: Colors.black87),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}