import 'package:flutter/material.dart';
import '../../meals/meals_selection_page.dart';
import '../../meals/meal_quantity_page.dart';

class EditRoomPage extends StatefulWidget {
  final Map<String, dynamic> room;

  const EditRoomPage({
    super.key,
    required this.room,
  });

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  late TextEditingController roomNameController;
  late TextEditingController roomCodeController;
  late TextEditingController descriptionController;

  Map<String, dynamic>? breakfastMeal;
  Map<String, dynamic>? lunchMeal;
  Map<String, dynamic>? dinnerMeal;
  Map<String, dynamic>? snacksMeal;

  @override
  void initState() {
    super.initState();

    roomNameController =
        TextEditingController(text: widget.room["name"] ?? "");
    roomCodeController =
        TextEditingController(text: widget.room["code"] ?? "");
    descriptionController =
        TextEditingController(text: widget.room["description"] ?? "");

    final program = widget.room["programItems"] as List? ?? [];

    for (var meal in program) {
      switch (meal["title"]) {
        case "Breakfast":
          breakfastMeal = Map<String, dynamic>.from(meal);
          break;
        case "Lunch":
          lunchMeal = Map<String, dynamic>.from(meal);
          break;
        case "Dinner":
          dinnerMeal = Map<String, dynamic>.from(meal);
          break;
        case "Snacks":
          snacksMeal = Map<String, dynamic>.from(meal);
          break;
      }
    }
  }

  @override
  void dispose() {
    roomNameController.dispose();
    roomCodeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectMeal({
    required String title,
    required Function(Map<String, dynamic>) onSelected,
  }) async {
    final selectedProducts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MealsSelectionPage(),
      ),
    );

    if (selectedProducts == null) return;

    final meal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealQuantityPage(
          mealTitle: title,
          selectedProducts: List<Map<String, dynamic>>.from(selectedProducts),
        ),
      ),
    );

    if (meal != null) {
      setState(() {
        onSelected(Map<String, dynamic>.from(meal));
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Widget _mealBox({
    required String title,
    required IconData icon,
    required Map<String, dynamic>? meal,
    required VoidCallback onTap,
  }) {
    final hasMeal = meal != null;

    final calories = hasMeal ? _toDouble(meal["calories"]) : 0.0;
    final proteins = hasMeal ? _toDouble(meal["proteins"]) : 0.0;
    final carbs = hasMeal ? _toDouble(meal["carbs"]) : 0.0;
    final fats = hasMeal ? _toDouble(meal["fats"]) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2E7D5A)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D5A),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasMeal ? (meal["description"] ?? "") : "Select $title",
                    style: TextStyle(
                      color: hasMeal ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasMeal) ...[
                    const SizedBox(height: 8),
                    Text(
                      "${calories.toStringAsFixed(0)} kcal",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D5A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "P ${proteins.toStringAsFixed(1)}g  |  G ${carbs.toStringAsFixed(1)}g  |  L ${fats.toStringAsFixed(1)}g",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final updatedRoom = {
      ...widget.room,
      "name": roomNameController.text.trim(),
      "code": roomCodeController.text.trim(),
      "description": descriptionController.text.trim(),
      "programItems": [
        if (breakfastMeal != null) breakfastMeal!,
        if (lunchMeal != null) lunchMeal!,
        if (dinnerMeal != null) dinnerMeal!,
        if (snacksMeal != null) snacksMeal!,
      ],
    };

    Navigator.pop(context, updatedRoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)),
        title: const Text(
          "Edit Room",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: roomNameController,
              decoration: const InputDecoration(
                labelText: "Room Name",
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: roomCodeController,
              decoration: const InputDecoration(
                labelText: "Room Code",
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
              ),
            ),
            const SizedBox(height: 20),
            _mealBox(
              title: "Breakfast",
              icon: Icons.free_breakfast,
              meal: breakfastMeal,
              onTap: () => _selectMeal(
                title: "Breakfast",
                onSelected: (m) => breakfastMeal = m,
              ),
            ),
            _mealBox(
              title: "Lunch",
              icon: Icons.lunch_dining,
              meal: lunchMeal,
              onTap: () => _selectMeal(
                title: "Lunch",
                onSelected: (m) => lunchMeal = m,
              ),
            ),
            _mealBox(
              title: "Dinner",
              icon: Icons.dinner_dining,
              meal: dinnerMeal,
              onTap: () => _selectMeal(
                title: "Dinner",
                onSelected: (m) => dinnerMeal = m,
              ),
            ),
            _mealBox(
              title: "Snacks",
              icon: Icons.cookie,
              meal: snacksMeal,
              onTap: () => _selectMeal(
                title: "Snacks",
                onSelected: (m) => snacksMeal = m,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 170,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3ECFF),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    color: Color(0xFF6E5AA6),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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