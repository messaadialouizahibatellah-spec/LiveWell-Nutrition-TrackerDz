import 'package:flutter/material.dart';
import 'created_room_details_page.dart';
import 'edit_room_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyCreatedRoomsPage extends StatefulWidget {
  final List<Map<String, dynamic>>? createdRooms;

  const MyCreatedRoomsPage({
    super.key,
    this.createdRooms,
  });

  @override
  State<MyCreatedRoomsPage> createState() => _MyCreatedRoomsPageState();
}

class _MyCreatedRoomsPageState extends State<MyCreatedRoomsPage> {
  List<Map<String, dynamic>> rooms = [];

  Future<void> _editRoom(int index) async {
    final updatedRoom = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoomPage(room: rooms[index]),
      ),
    );

    if (updatedRoom != null) {
      final roomId = rooms[index]["id"];

      if (roomId != null) {
        await FirebaseFirestore.instance
            .collection("rooms")
            .doc(roomId)
            .update(Map<String, dynamic>.from(updatedRoom));
      }

      setState(() {
        rooms[index] = Map<String, dynamic>.from(updatedRoom);
      });
    }
  }

  void _openRoom(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatedRoomDetailsPage(room: rooms[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D5A)),
        title: const Text(
          "My Created Rooms",
          style: TextStyle(
            color: Color(0xFF2E7D5A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: currentUser == null
          ? const Center(
        child: Text(
          "No nutritionist logged in",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rooms")
            .where(
          "nutritionistUid",
          isEqualTo: currentUser.uid,
        )
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          rooms = snapshot.data!.docs.map((doc) {
            return {
              "id": doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                "No rooms created yet",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final room = rooms[index];

              return InkWell(
                onTap: () => _openRoom(index),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                        const Color(0xFFFFD3A5).withOpacity(0.55),
                        child: const Icon(
                          Icons.meeting_room_rounded,
                          color: Color(0xFF2E7D5A),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room["name"] ?? "",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D5A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Code: ${room["code"] ?? ""}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              room["description"] ?? "",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editRoom(index),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFFFFA94D),
                            ),
                          ),

                          IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    backgroundColor: const Color(0xFFF5F2EC),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 38,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          const Text(
                                            "Delete Room?",
                                            style: TextStyle(
                                              color: Color(0xFF2E7D5A),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            "Are you sure you want to delete this room?",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 26),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white,
                                                    elevation: 4,
                                                    shadowColor: Colors.black.withOpacity(0.08),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(22),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                  ),
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      color: Color(0xFF2E7D5A),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    elevation: 4,
                                                    shadowColor: Colors.black.withOpacity(0.12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(22),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                  ),
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                              if (confirm != true) return;

                              final roomId = room["id"];

                              await FirebaseFirestore.instance
                                  .collection("rooms")
                                  .doc(roomId)
                                  .delete();

                              final joinedDocs =
                              await FirebaseFirestore.instance
                                  .collection("joined_rooms")
                                  .where("code",
                                  isEqualTo: room["code"])
                                  .get();

                              for (final doc in joinedDocs.docs) {
                                await doc.reference.delete();
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}