import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});

  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {

  void _showAddBannerDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController subtitleController = TextEditingController();
    File? imageFile;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Thêm Banner mới"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setDialogState(() => imageFile = File(pickedFile.path));
                    }
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                    child: imageFile == null 
                      ? const Icon(Iconsax.camera, color: Colors.grey) 
                      : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(imageFile!, fit: BoxFit.cover)),
                  ),
                ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tiêu đề")),
                TextField(controller: subtitleController, decoration: const InputDecoration(labelText: "Phụ đề")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (titleController.text.isEmpty || imageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin và chọn ảnh")));
                  return;
                }
                
                setDialogState(() => isLoading = true);
                try {
                  String fileName = DateTime.now().millisecondsSinceEpoch.toString();
                  Reference ref = FirebaseStorage.instance.ref().child("banners").child("$fileName.jpg");
                  
                  // Tải file lên
                  await ref.putFile(imageFile!);
                  String url = await ref.getDownloadURL();

                  // Lưu vào Firestore
                  await FirebaseFirestore.instance.collection("banners").add({
                    "title": titleController.text.trim(),
                    "subtitle": subtitleController.text.trim(),
                    "image": url,
                    "createdAt": FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  print("Lỗi upload banner: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Lỗi: ${e.toString()}"), // Hiện lỗi chi tiết
                      backgroundColor: Colors.red,
                    ));
                  }
                } finally {
                  setDialogState(() => isLoading = false);
                }
              },
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Tải lên"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Quản lý Banner"),
        centerTitle: true,
        leading: Padding(padding: const EdgeInsets.only(left: 15), child: MyIconButton(icon: Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kprimaryColor,
        onPressed: _showAddBannerDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("banners").orderBy("createdAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final banners = snapshot.data!.docs;
          if (banners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.image, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Chưa có banner nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final data = banners[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(data["image"], width: 60, height: 40, fit: BoxFit.cover)),
                  title: Text(data["title"], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data["subtitle"] ?? "", maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red), 
                    onPressed: () async {
                      // Xóa ảnh trên Storage trước khi xóa document (tối ưu dung lượng)
                      try {
                        await FirebaseStorage.instance.refFromURL(data["image"]).delete();
                      } catch (e) {
                        print("Không thể xóa file ảnh: $e");
                      }
                      await banners[index].reference.delete();
                    }
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
