import 'package:flutter/material.dart';
import '../../meals/meals_selection_page.dart';
import '../../meals/meal_quantity_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final roomNameController = TextEditingController();
  final roomCodeController = TextEditingController();
  final descriptionController = TextEditingController();

  Map<String, dynamic>? breakfastMeal;
  Map<String, dynamic>? lunchMeal;
  Map<String, dynamic>? dinnerMeal;
  Map<String, dynamic>? snacksMeal;

  @override
  void dispose() {
    roomNameController.dispose();
    roomCodeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _generateCode() {
    setState(() {
      roomCodeController.text = "ROOM${DateTime.now().millisecondsSinceEpoch % 10000}";
    });
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
          selectedProducts:
          List<Map<String, dynamic>>.from(selectedProducts),
        ),
      ),
    );

    if (meal != null) {
      meal["mealType"] = title;
      meal["title"] = title;

      setState(() {
        onSelected(meal);
      });
    }
  }

  Widget _mealBox({
    required String title,
    required IconData icon,
    required Map<String, dynamic>? meal,
    required VoidCallback onTap,
  }) {
    final hasMeal = meal != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D5A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasMeal ? meal["description"] : "Select $title",
                style: TextStyle(
                  color: hasMeal ? Colors.black : Colors.grey,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoom() async {
    if (roomNameController.text.trim().isEmpty ||
        roomCodeController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (breakfastMeal == null &&
        lunchMeal == null &&
        dinnerMeal == null &&
        snacksMeal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one meal"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No nutritionist logged in"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final newRoom = {
        "name": roomNameController.text.trim(),
        "code": roomCodeController.text.trim(),
        "description": descriptionController.text.trim(),
        "nutritionistUid": user.uid,
        "createdAt": Timestamp.now(),
        "programItems": [
          if (breakfastMeal != null) breakfastMeal!,
          if (lunchMeal != null) lunchMeal!,
          if (dinnerMeal != null) dinnerMeal!,
          if (snacksMeal != null) snacksMeal!,
        ],
      };

      await FirebaseFirestore.instance
          .collection("rooms")
          .add(newRoom);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Room created successfully"),
          backgroundColor: Color(0xFF2E7D5A),
        ),
      );

      Navigator.pop(context, newRoom);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        title: const Text("Create Room"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: roomNameController,
              decoration: InputDecoration(
                hintText: "Room Name",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: roomCodeController,
              decoration: InputDecoration(
                hintText: "Room Code",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generateCode,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Description",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Create Room",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}