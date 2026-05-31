import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateProgramItemPage extends StatefulWidget {
  const CreateProgramItemPage({super.key});

  @override
  State<CreateProgramItemPage> createState() => _CreateProgramItemPageState();
}

class _CreateProgramItemPageState extends State<CreateProgramItemPage> {
  final mealNameController = TextEditingController();
  final caloriesController = TextEditingController();
  final notesController = TextEditingController();

  String selectedMealType = "Breakfast";

  final List<String> mealTypes = [
    "Breakfast",
    "Lunch",
    "Dinner",
    "Snacks",
  ];

  @override
  void dispose() {
    mealNameController.dispose();
    caloriesController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProgramItem() async {
    if (mealNameController.text.trim().isEmpty ||
        caloriesController.text.trim().isEmpty ||
        notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("program_items").add({
      "nutritionistUid": user.uid,
      "title": selectedMealType,
      "mealName": mealNameController.text.trim(),
      "calories": caloriesController.text.trim(),
      "notes": notesController.text.trim(),
      "createdAt": Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Program item added successfully"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
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
          "Add Program Item",
          style: TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: mealNameController,
              decoration: InputDecoration(
                hintText: "Meal / Product Name",
                prefixIcon: const Icon(Icons.restaurant_menu_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Calories",
                prefixIcon: const Icon(Icons.local_fire_department_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMealType,
                  isExpanded: true,
                  items: mealTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMealType = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Notes / Quantity / Description",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _saveProgramItem,
                child: const Text(
                  "Save Item",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
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