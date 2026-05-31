import 'package:flutter/material.dart';
import 'home_dashboard_page.dart';
import '../meals/meals_page.dart';
import 'drink_water_page.dart';
import 'sport_page.dart';
import 'chatu/user_chat_page.dart';
import 'explore_page.dart';
import 'roomu/join_room_page.dart';
import 'roomu/my_rooms_page.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/loginpage.dart';

class HomePage extends StatefulWidget {
  final Map<String, String>? userData;
  final bool showLoginOnStart;

  const HomePage({
    super.key,
    this.userData,
    this.showLoginOnStart = false,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  bool showRoomActions = false;
  late bool showLoginOverlay;
  @override
  void initState() {
    super.initState();
    showLoginOverlay = widget.showLoginOnStart;
  }

  static const Color darkGreen = Color(0xFF2E7D5A);
  static const Color accentOrange = Color(0xFFFFA94D);

  void _toggleRoomActions() {
    setState(() {
      showRoomActions = !showRoomActions;
    });
  }

  void _openJoinRoom() {
    setState(() {
      showRoomActions = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JoinRoomPage(),
      ),
    );
  }

  void _openMyRooms() {
    setState(() {
      showRoomActions = false;
      selectedIndex = 6;
    });
  }
  void _goHomeDashboard() {
    setState(() {
      showRoomActions = false;
      selectedIndex = 0;
    });
  }

  Widget _getSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return HomeDashboardPage(userData: widget.userData);
      case 1:
        return const MealsPage(showTitle: true);
      case 2:
        return const DrinkWaterPage();
      case 3:
        return SportPage(userData: widget.userData);
      case 4:
        return const UserChatPage();
      case 5:
        return const ExplorePage();
      case 6:
        return MyRoomsPage(onGoHome: _goHomeDashboard);
      default:
        return HomeDashboardPage(userData: widget.userData);

    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true,
        body: Stack(
          children: [
            _getSelectedPage(),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: SizedBox(
        height: 138,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: Center(child: _bottomItem(Icons.home_rounded, 0))),
                    Expanded(child: Center(child: _bottomItem(Icons.restaurant_menu_rounded, 1))),
                    Expanded(child: Center(child: _bottomItem(Icons.water_drop_outlined, 2))),
                    const SizedBox(width: 72),
                    Expanded(child: Center(child: _bottomItem(Icons.fitness_center_rounded, 3))),
                    Expanded(child: Center(child: _bottomItem(Icons.chat_bubble_outline_rounded, 4))),
                    Expanded(child: Center(child: _bottomItem(Icons.public_rounded, 5))),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 86,
              left: 18,
              right: 18,
              child: IgnorePointer(
                ignoring: !showRoomActions,
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        offset: showRoomActions ? Offset.zero : const Offset(-0.35, 0.35),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: showRoomActions ? 1 : 0,
                          child: _roomActionButton(
                            icon: Icons.meeting_room_rounded,
                            label: "My Rooms",
                            onTap: _openMyRooms,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        offset: showRoomActions ? Offset.zero : const Offset(0.35, 0.35),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: showRoomActions ? 1 : 0,
                          child: _roomActionButton(
                            icon: Icons.login_rounded,
                            label: "Join Room",
                            onTap: _openJoinRoom,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 24,
              child: GestureDetector(
                onTap: _toggleRoomActions,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: accentOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AnimatedRotation(
                    turns: showRoomActions ? 0.125 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    child: Icon(
                      showRoomActions ? Icons.close_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem(IconData icon, int index) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        final isGuest = FirebaseAuth.instance.currentUser == null;

        setState(() {
          showRoomActions = false;

          selectedIndex = index;
          showLoginOverlay = false;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: isSelected ? 1.06 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isSelected ? 1 : 0.82,
          child: Icon(
            icon,
            color: isSelected ? accentOrange : Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _roomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: darkGreen, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: darkGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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