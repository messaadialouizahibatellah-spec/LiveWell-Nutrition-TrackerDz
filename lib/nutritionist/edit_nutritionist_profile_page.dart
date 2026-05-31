import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/nutritionist_login_page.dart';

class EditNutritionistProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditNutritionistProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<EditNutritionistProfilePage> createState() =>
      _EditNutritionistProfilePageState();
}

class _EditNutritionistProfilePageState
    extends State<EditNutritionistProfilePage> {
  late TextEditingController nameController;
  late TextEditingController specialtyController;
  late TextEditingController emailController;
  late TextEditingController bioController;

  String? selectedWilaya;
  late String selectedProfileImage;
  late String selectedGender;

  final List<String> wilayas = const [
    "01 - Adrar",
    "02 - Chlef",
    "03 - Laghouat",
    "04 - Oum El Bouaghi",
    "05 - Batna",
    "06 - Béjaïa",
    "07 - Biskra",
    "08 - Béchar",
    "09 - Blida",
    "10 - Bouira",
    "11 - Tamanrasset",
    "12 - Tébessa",
    "13 - Tlemcen",
    "14 - Tiaret",
    "15 - Tizi Ouzou",
    "16 - Alger",
    "17 - Djelfa",
    "18 - Jijel",
    "19 - Sétif",
    "20 - Saïda",
    "21 - Skikda",
    "22 - Sidi Bel Abbès",
    "23 - Annaba",
    "24 - Guelma",
    "25 - Constantine",
    "26 - Médéa",
    "27 - Mostaganem",
    "28 - M'Sila",
    "29 - Mascara",
    "30 - Ouargla",
    "31 - Oran",
    "32 - El Bayadh",
    "33 - Illizi",
    "34 - Bordj Bou Arréridj",
    "35 - Boumerdès",
    "36 - El Tarf",
    "37 - Tindouf",
    "38 - Tissemsilt",
    "39 - El Oued",
    "40 - Khenchela",
    "41 - Souk Ahras",
    "42 - Tipaza",
    "43 - Mila",
    "44 - Aïn Defla",
    "45 - Naâma",
    "46 - Aïn Témouchent",
    "47 - Ghardaïa",
    "48 - Relizane",
    "49 - Timimoun",
    "50 - Bordj Badji Mokhtar",
    "51 - Ouled Djellal",
    "52 - Béni Abbès",
    "53 - In Salah",
    "54 - In Guezzam",
    "55 - Touggourt",
    "56 - Djanet",
    "57 - El M'Ghair",
    "58 - El Menia",
  ];

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.profile["name"] ?? "");
    specialtyController =
        TextEditingController(text: widget.profile["specialty"] ?? "");
    emailController = TextEditingController(text: widget.profile["email"] ?? "");
    bioController = TextEditingController(text: widget.profile["bio"] ?? "");

    final oldWilaya = widget.profile["wilaya"]?.toString();

    if (oldWilaya != null && wilayas.contains(oldWilaya)) {
      selectedWilaya = oldWilaya;
    } else if (oldWilaya != null && oldWilaya.trim().isNotEmpty) {
      selectedWilaya = wilayas.firstWhere(
            (wilaya) => wilaya.toLowerCase().contains(oldWilaya.toLowerCase()),
        orElse: () => "",
      );

      if (selectedWilaya == "") {
        selectedWilaya = null;
      }
    } else {
      selectedWilaya = null;
    }
    selectedGender = widget.profile["gender"] ?? "female";

    selectedProfileImage =
    (selectedGender == "male")
        ? "assets/images/nutritionist_male.png"
        : "assets/images/nutritionist_female.png";
  }

  @override
  void dispose() {
    nameController.dispose();
    specialtyController.dispose();
    emailController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> _saveToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("nutritionists")
        .doc(user.uid)
        .update({
      "name": nameController.text.trim(),
      "specialty": specialtyController.text.trim(),
      "officialTitle": specialtyController.text.trim(),
      "email": emailController.text.trim(),
      "bio": bioController.text.trim(),
      "wilaya": selectedWilaya ?? "",
      "profileImage": selectedProfileImage,
      "gender": selectedGender,
    });

    final updatedProfile = {
      ...widget.profile,
      "name": nameController.text.trim(),
      "specialty": specialtyController.text.trim(),
      "officialTitle": specialtyController.text.trim(),
      "email": emailController.text.trim(),
      "bio": bioController.text.trim(),
      "wilaya": selectedWilaya ?? "",
      "profileImage": selectedProfileImage,
      "gender": selectedGender,
    };

    Navigator.pop(context, updatedProfile);
  }
  void _selectGender(String gender) {
    setState(() {
      selectedGender = gender;

      selectedProfileImage = gender == "male"
          ? "assets/images/nutritionist_male.png"
          : "assets/images/nutritionist_female.png";
    });
  }
  void _logout() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7F3),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD3A5).withOpacity(0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF2E7D5A),
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Logout",
                  style: TextStyle(
                    color: Color(0xFF2E7D5A),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Are you sure you want to logout?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: Color(0xFF2E7D5A),
                            width: 1.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Color(0xFF2E7D5A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFFFFA94D),
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const NutritionistLoginPage(),
                            ),
                                (route) => false,
                          );
                        },
                        child: const Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
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
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: const Icon(
        Icons.edit_outlined,
        color: Colors.black54,
        size: 22,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
  Widget _genderCard({
    required String gender,
    required String imagePath,
    required String label,
  }) {
    final isSelected = selectedGender == gender;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectGender(gender),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFA8E6CF).withOpacity(0.35)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2E7D5A)
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(imagePath),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF2E7D5A)
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget wilayaDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedWilaya,
      isExpanded: true,
      menuMaxHeight: 300,
      decoration: InputDecoration(
        hintText: "Wilaya",
        prefixIcon: const Icon(Icons.location_on_outlined),
        suffixIcon: const Icon(
          Icons.edit_outlined,
          color: Colors.black54,
          size: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      items: wilayas.map((wilaya) {
        return DropdownMenuItem<String>(
          value: wilaya,
          child: Text(wilaya),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedWilaya = value;
        });
      },
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
        title: const Text(
          "Settings",
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
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(selectedProfileImage),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                _genderCard(
                  gender: "male",
                  imagePath: "assets/images/nutritionist_male.png",
                  label: "Male",
                ),

                const SizedBox(width: 12),

                _genderCard(
                  gender: "female",
                  imagePath: "assets/images/nutritionist_female.png",
                  label: "Female",
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: _input("Full Name", Icons.person_outline),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: specialtyController,
              decoration:
              _input("Official Title", Icons.workspace_premium_outlined),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: emailController,
              decoration: _input("Email", Icons.email_outlined),
            ),

            const SizedBox(height: 14),

            wilayaDropdown(),

            const SizedBox(height: 14),

            TextField(
              controller: bioController,
              maxLines: 4,
              decoration: _input("Bio", Icons.edit_note_outlined),
            ),

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveToFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
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