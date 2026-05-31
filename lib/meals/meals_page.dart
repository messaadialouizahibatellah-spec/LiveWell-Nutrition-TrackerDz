import 'package:flutter/material.dart';
import 'food_data.dart';

class MealsPage extends StatefulWidget {
  final bool showTitle;

  const MealsPage({
    super.key,
    this.showTitle = false,
  });

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  final TextEditingController searchController = TextEditingController();
  late List<Map<String, dynamic>> filteredFoods;

  @override
  void initState() {
    super.initState();
    filteredFoods = List<Map<String, dynamic>>.from(foods);
  }

  void _search(String value) {
    setState(() {
      final query = value.toLowerCase();

      filteredFoods = foods.where((food) {
        final name = (food["name"] ?? "").toString().toLowerCase();
        final brand = (food["brand"] ?? "").toString().toLowerCase();
        final category = (food["category"] ?? "").toString().toLowerCase();
        final origin = (food["origin"] ?? "").toString().toLowerCase();

        return name.contains(query) ||
            brand.contains(query) ||
            category.contains(query) ||
            origin.contains(query);
      }).toList();
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
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F7F3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle)
            const Padding(
              padding: EdgeInsets.only(left: 28, top: 48, bottom: 22),
              child: Text(
                "Meals",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E7D5A),
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              widget.showTitle ? 0 : 20,
              20,
              20,
            ),
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

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredFoods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final food = filteredFoods[index];
                final healthLevel = (food["healthLevel"] ?? "good").toString();

                return Container(
                  padding: const EdgeInsets.all(14),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          food["image"] ?? "",
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 72,
                              height: 72,
                              color: const Color(0xFFF1F1F1),
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${food["name"]} (${food["brand"]})",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D5A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${food["category"]} • ${food["origin"]}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "${food["caloriesPer100g"]} kcal / 100g",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
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
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _macroChip(
                                  "P",
                                  "${food["proteinsPer100g"]} g",
                                  Colors.blue,
                                ),
                                _macroChip(
                                  "C",
                                  "${food["carbsPer100g"]} g",
                                  Colors.orange,
                                ),
                                _macroChip(
                                  "F",
                                  "${food["fatsPer100g"]} g",
                                  Colors.green,
                                ),
                              ],
                            ),
                          ],
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
    );
  }}