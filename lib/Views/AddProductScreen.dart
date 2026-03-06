import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _calController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  File? _image;
  bool _isLoading = false;
  String? _selectedCategory;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _image == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin, chọn ảnh và danh mục!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child("products").child("$fileName.jpg");
      await storageRef.putFile(_image!);
      String imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection("sanpham").add({
        "name": _nameController.text.trim(),
        "price": double.parse(_priceController.text),
        "cal": int.parse(_calController.text),
        "time": int.parse(_timeController.text),
        "category": _selectedCategory,
        "image": imageUrl,
        "isAvailable": true,
        "rating": 5.0,
        "review": 0,
        "imgct": [], 
        "imgamout": [],
        "imgname": [],
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thêm món thành công!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi thêm món"), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm món mới", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(icon: Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                  ),
                  child: _image == null ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Iconsax.camera, size: 50, color: Colors.grey), Text("Nhấn để chọn ảnh")],
                  ) : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Tên món ăn", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Giá (VNĐ)", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Trống" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _calController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Calo", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Trống" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Thời gian nấu (phút)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 20),
              
              // ĐỌC DANH MỤC TỪ FIREBASE THAY VÌ VIẾT CỨNG
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("nhomsanpham").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final categories = snapshot.data!.docs.map((doc) => doc["name"].toString()).toList();
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: const Text("Chọn danh mục"),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    validator: (v) => v == null ? "Vui lòng chọn danh mục" : null,
                  );
                },
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Đăng món lên Shop", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
