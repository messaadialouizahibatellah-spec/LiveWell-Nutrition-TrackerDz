import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealQuantityPage extends StatefulWidget {
  final String mealTitle;
  final List<Map<String, dynamic>> selectedProducts;

  const MealQuantityPage({
    super.key,
    required this.mealTitle,
    required this.selectedProducts,
  });

  @override
  State<MealQuantityPage> createState() => _MealQuantityPageState();
}

class _MealQuantityPageState extends State<MealQuantityPage> {
  late List<Map<String, dynamic>> productsWithValues;

  @override
  void initState() {
    super.initState();
    productsWithValues = widget.selectedProducts.map((product) {
      final grams =
          (product["grams"] as num?)?.toDouble() ?? 100.0;

      return {
        ...Map<String, dynamic>.from(product),
        "gramsController": TextEditingController(
          text: grams.toStringAsFixed(0),
        ),
        "grams": grams,
        "calories": _calc(product["caloriesPer100g"], grams),
        "proteins": _calc(product["proteinsPer100g"], grams),
        "carbs": _calc(product["carbsPer100g"], grams),
        "fats": _calc(product["fatsPer100g"], grams),
      };
    }).toList();
  }

  double _calc(dynamic per100g, double grams) {
    if (per100g == null) return 0.0;
    if (per100g is num) return (per100g.toDouble() * grams) / 100;

    final value = double.tryParse(per100g.toString()) ?? 0.0;
    return (value * grams) / 100;
  }

  void _updateNutrition(int index, String value) {
    final grams = double.tryParse(value) ?? 0;
    setState(() {
      productsWithValues[index]["grams"] = grams;
      productsWithValues[index]["calories"] =
          _calc(productsWithValues[index]["caloriesPer100g"], grams);
      productsWithValues[index]["proteins"] =
          _calc(productsWithValues[index]["proteinsPer100g"], grams);
      productsWithValues[index]["carbs"] =
          _calc(productsWithValues[index]["carbsPer100g"], grams);
      productsWithValues[index]["fats"] =
          _calc(productsWithValues[index]["fatsPer100g"], grams);
    });
  }

  double get totalCalories => productsWithValues.fold(
    0.0,
        (sum, item) => sum + ((item["calories"] as num?)?.toDouble() ?? 0.0),
  );

  double get totalProteins => productsWithValues.fold(
    0.0,
        (sum, item) => sum + ((item["proteins"] as num?)?.toDouble() ?? 0.0),
  );

  double get totalCarbs => productsWithValues.fold(
    0.0,
        (sum, item) => sum + ((item["carbs"] as num?)?.toDouble() ?? 0.0),
  );

  double get totalFats => productsWithValues.fold(
    0.0,
        (sum, item) => sum + ((item["fats"] as num?)?.toDouble() ?? 0.0),
  );

  Map<String, dynamic> _buildMealBlock() {
    final items = productsWithValues.map((p) {
      // item نزيد بلا TextEditingController بش يقدر يتسجل في Firestore
      return {
        "name": p["name"],
        "brand": p["brand"],
        "image": p["image"],

        "grams": (p["grams"] as num?)?.toDouble() ?? 0.0,
        "calories": (p["calories"] as num?)?.toDouble() ?? 0.0,
        "proteins": (p["proteins"] as num?)?.toDouble() ?? 0.0,
        "carbs": (p["carbs"] as num?)?.toDouble() ?? 0.0,
        "fats": (p["fats"] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();

    return {
      "title": widget.mealTitle,
      "items": items,
      "description": items
          .map((e) =>
      "${e["name"]} (${(e["grams"] as double).toStringAsFixed(0)}g)")
          .join(", "),
      "calories": totalCalories,
      "proteins": totalProteins,
      "carbs": totalCarbs,
      "fats": totalFats,
    };
  }

  @override
  void dispose() {
    for (final product in productsWithValues) {
      final controller = product["gramsController"];
      if (controller is TextEditingController) {
        controller.dispose();
      }
    }
    super.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)),
        title: Text(
          widget.mealTitle,
          style: const TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _buildMealBlock());
            },
            child: const Text(
              "Done",
              style: TextStyle(
                color: Color(0xFF2E7D5A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Calories: ${totalCalories.toStringAsFixed(0)} kcal",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D5A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _macroChip(
                      "P",
                      "${totalProteins.toStringAsFixed(1)} g",
                      Colors.blue,
                    ),
                    _macroChip(
                      "G",
                      "${totalCarbs.toStringAsFixed(1)} g",
                      Colors.orange,
                    ),
                    _macroChip(
                      "L",
                      "${totalFats.toStringAsFixed(1)} g",
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: productsWithValues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = productsWithValues[index];
                final gramsController =
                product["gramsController"] as TextEditingController;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                        product["name"].toString(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D5A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: gramsController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _updateNutrition(index, value),
                        decoration: InputDecoration(
                          hintText: "Quantity in grams",
                          suffixText: "g",
                          prefixIcon: const Icon(Icons.scale_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _macroChip(
                            "Kcal",
                            ((product["calories"] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1),
                            const Color(0xFF2E7D5A),
                          ),
                          _macroChip(
                            "P",
                            "${(product["proteins"] as double).toStringAsFixed(1)} g",
                            Colors.blue,
                          ),
                          _macroChip(
                            "G",
                            "${(product["carbs"] as double).toStringAsFixed(1)} g",
                            Colors.orange,
                          ),
                          _macroChip(
                            "L",
                            "${(product["fats"] as double).toStringAsFixed(1)} g",
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}