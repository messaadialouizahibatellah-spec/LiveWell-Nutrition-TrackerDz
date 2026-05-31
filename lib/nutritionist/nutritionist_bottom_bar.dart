import 'package:flutter/material.dart';

class NutritionistBottomBar extends StatelessWidget {
  final int selectedIndex;
  final int messageRequestsCount;
  final Function(int) onTabSelected;
  final VoidCallback onOpenRequests;

  const NutritionistBottomBar({
    super.key,
    required this.selectedIndex,
    required this.messageRequestsCount,
    required this.onTabSelected,
    required this.onOpenRequests,
  });

  Widget _navItem({
    required IconData icon,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Icon(
        icon,
        size: 30,
        color: isSelected ? const Color(0xFFF5AA2C) : Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D5A),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home_rounded, index: 0),
              _navItem(icon: Icons.restaurant_menu_rounded, index: 1),
              const SizedBox(width: 70),
              _navItem(icon: Icons.chat_bubble_rounded, index: 2),
              _navItem(icon: Icons.person_outline_rounded, index: 3),
            ],
          ),
          Positioned(
            top: -18,
            child: GestureDetector(
              onTap: onOpenRequests,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5AA2C),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    if (messageRequestsCount > 0)
                      Positioned(
                        top: 14,
                        right: 18,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            messageRequestsCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}