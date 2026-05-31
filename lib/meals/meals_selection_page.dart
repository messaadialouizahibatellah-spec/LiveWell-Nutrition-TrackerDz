import 'package:flutter/material.dart';
import 'food_data.dart';

class MealsSelectionPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelectedMeals;

  const MealsSelectionPage({
    super.key,
    this.initialSelectedMeals = const [],
  });

  @override
  State<MealsSelectionPage> createState() => _MealsSelectionPageState();
}

class _MealsSelectionPageState extends State<MealsSelectionPage> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> allMeals = foods;

  late List<Map<String, dynamic>> filteredMeals;
  late List<Map<String, dynamic>> selectedMeals;

  @override
  void initState() {
    super.initState();

    selectedMeals = widget.initialSelectedMeals.map((oldMeal) {
      final oldName = oldMeal["name"];

      final fullMeal = allMeals.firstWhere(
            (meal) => meal["name"] == oldName,
        orElse: () => oldMeal,
      );

      return {
        ...Map<String, dynamic>.from(fullMeal),
        "grams": oldMeal["grams"] ?? 100.0,
      };
    }).toList();

    filteredMeals = [
      ...selectedMeals,
      ...allMeals.where(
            (meal) => !selectedMeals.any(
              (selected) => selected["name"] == meal["name"],
        ),
      ),
    ];
  }

  void _search(String value) {
    setState(() {
      final query = value.toLowerCase();

      filteredMeals = allMeals.where((meal) {
        final name = (meal["name"] ?? "").toString().toLowerCase();
        final brand = (meal["brand"] ?? "").toString().toLowerCase();
        final category = (meal["category"] ?? "").toString().toLowerCase();
        final origin = (meal["origin"] ?? "").toString().toLowerCase();

        return name.contains(query) ||
            brand.contains(query) ||
            category.contains(query) ||
            origin.contains(query);
      }).toList();
    });
  }

  bool _isSelected(Map<String, dynamic> meal) {
    return selectedMeals.any((item) => item["name"] == meal["name"]);
  }

  void _toggleMeal(Map<String, dynamic> meal) {
    setState(() {
      final index =
      selectedMeals.indexWhere((item) => item["name"] == meal["name"]);

      if (index != -1) {
        selectedMeals.removeAt(index);
      } else {
        selectedMeals.add(Map<String, dynamic>.from(meal));
      }
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

  Color _healthColor(String level) {
    switch (level) {
      case "good":
        return Colors.green;
      case "medium":
        return Colors.orange;
      case "bad":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _healthLabel(String level) {
    switch (level) {
      case "good":
        return "Healthy";
      case "medium":
        return "Moderate";
      case "bad":
        return "Less Healthy";
      default:
        return "Unknown";
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
          "Select Meals",
          style: TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, selectedMeals);
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: "Search by name, brand, or category...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          if (selectedMeals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedMeals.map((meal) {
                    return Chip(
                      label: Text(
                        "${meal["name"]} (${meal["brand"]})",
                      ),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => _toggleMeal(meal),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredMeals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final meal = filteredMeals[index];
                final isSelected = _isSelected(meal);
                final healthLevel = (meal["healthLevel"] ?? "good").toString();

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          meal["image"] ?? "",
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFFA8E6CF),
                              child: Icon(
                                Icons.restaurant_menu,
                                color: Color(0xFF2E7D5A),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${meal["name"]} (${meal["brand"]})",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D5A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${meal["category"]} • ${meal["origin"]}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "${meal["caloriesPer100g"]} kcal / 100g",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _healthColor(healthLevel)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _healthLabel(healthLevel),
                                    style: TextStyle(
                                      color: _healthColor(healthLevel),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _macroChip(
                                  "P",
                                  "${meal["proteinsPer100g"]} g",
                                  Colors.blue,
                                ),
                                _macroChip(
                                  "C",
                                  "${meal["carbsPer100g"]} g",
                                  Colors.orange,
                                ),
                                _macroChip(
                                  "F",
                                  "${meal["fatsPer100g"]} g",
                                  Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleMeal(meal),
                        activeColor: const Color(0xFF2E7D5A),
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
