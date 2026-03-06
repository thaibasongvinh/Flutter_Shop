import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  const EditProfileScreen({super.key, required this.currentName});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  
  String? _selectedGender;
  bool _isLoading = false;
  File? _image;
  String? _profilePicUrl;
  final picker = ImagePicker();

  final List<String> _genders = ["Nam", "Nữ", "Khác"];

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _loadUserProfile();
    super.initState();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection("user_profile").doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _profilePicUrl = data["profilePic"];
          _phoneController.text = data["phone"] ?? "";
          _dobController.text = data["dob"] ?? "";
          _selectedGender = data["gender"];
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");
      
      String fileName = "${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final storageRef = FirebaseStorage.instance.ref().child("profile_pics").child(fileName);
      
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      // Ném ra lỗi của Firebase để bên ngoài bắt được
      throw Exception("Lỗi từ Firebase Storage: ${e.message} (Code: ${e.code})");
    } catch (e) {
      throw Exception("Xảy ra lỗi không xác định khi tải ảnh lên.");
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic> dataToUpdate = {
        "name": name,
        "phone": _phoneController.text.trim(),
        "dob": _dobController.text.trim(),
        "gender": _selectedGender,
      };

      if (_image != null) {
        String imageUrl = await _uploadImage(_image!);
        dataToUpdate['profilePic'] = imageUrl;
        await user.updatePhotoURL(imageUrl);
      }
      
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance.collection("user_profile").doc(user.uid).set(dataToUpdate, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật hồ sơ thành công!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
        title: Text("Chỉnh sửa hồ sơ", style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        leading: Padding(padding: const EdgeInsets.only(left: 15), child: MyIconButton(icon: Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.cardColor,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (_profilePicUrl != null && _profilePicUrl!.isNotEmpty
                          ? NetworkImage(_profilePicUrl!)
                          : const NetworkImage("https://cdn-icons-png.flaticon.com/512/3135/3135715.png")) as ImageProvider,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: kprimaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildTextField(controller: _nameController, label: "Tên đầy đủ", icon: Iconsax.user, theme: theme),
            const SizedBox(height: 15),
            _buildTextField(controller: _phoneController, label: "Số điện thoại", icon: Iconsax.call, keyboardType: TextInputType.phone, theme: theme),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: _buildTextField(controller: _dobController, label: "Ngày sinh", icon: Iconsax.calendar, theme: theme),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedGender,
                  hint: Row(children: [const Icon(Iconsax.man, color: kprimaryColor, size: 22), const SizedBox(width: 10), Text("Chọn giới tính", style: TextStyle(color: theme.hintColor))]),
                  items: _genders.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color)))).toList(),
                  onChanged: (newValue) => setState(() => _selectedGender = newValue),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Lưu thay đổi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, required String label, required IconData icon, 
    TextInputType keyboardType = TextInputType.text, required ThemeData theme
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: kprimaryColor),
      ),
    );
  }
}
