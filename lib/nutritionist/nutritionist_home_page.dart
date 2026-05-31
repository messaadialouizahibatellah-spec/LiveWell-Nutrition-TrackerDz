import 'package:flutter/material.dart';

class NutritionistHomePage extends StatelessWidget {
  final List<Map<String, dynamic>> createdRooms;
  final Map<String, dynamic> nutritionistProfile;
  final VoidCallback onCreateRoom;
  final VoidCallback onOpenMyRooms;

  const NutritionistHomePage({
    super.key,
    required this.createdRooms,
    required this.nutritionistProfile,
    required this.onCreateRoom,
    required this.onOpenMyRooms,
  });

  Widget _profileCard() {
    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: nutritionistProfile["profileImage"] != null
                ? AssetImage(nutritionistProfile["profileImage"])
                : null,
            child: nutritionistProfile["profileImage"] == null
                ? const Icon(
              Icons.person,
              size: 32,
              color: Color(0xFF2E7D5A),
            )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nutritionistProfile["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D5A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nutritionistProfile["specialty"] ?? "",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nutritionistProfile["email"] ?? "",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFA8E6CF).withOpacity(0.35),
              child: Icon(
                icon,
                color: const Color(0xFF2E7D5A),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D5A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _profileCard(),
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
            child: Text(
              "Total Rooms: ${createdRooms.length}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D5A),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _homeButton(
            icon: Icons.meeting_room_rounded,
            title: "Create Room",
            subtitle: "Create a new nutrition room",
            onTap: onCreateRoom,
          ),
          const SizedBox(height: 14),
          _homeButton(
            icon: Icons.list_alt_rounded,
            title: "My Rooms",
            subtitle: "View and manage your rooms",
            onTap: onOpenMyRooms,
          ),
        ],
      ),
    );
  }
}