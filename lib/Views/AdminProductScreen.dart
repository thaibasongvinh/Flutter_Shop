import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Views/AddProductScreen.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class AdminProductScreen extends StatelessWidget {
  const AdminProductScreen({super.key});

  Future<void> _toggleAvailability(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection("sanpham")
        .doc(docId)
        .update({"isAvailable": !currentStatus});
  }

  Future<void> _deleteProduct(BuildContext context, String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa sản phẩm này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection("sanpham").doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa sản phẩm thành công"), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _editPrice(BuildContext context, String docId, double currentPrice) {
    final TextEditingController priceController =
        TextEditingController(text: currentPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chỉnh sửa giá"),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: "VNĐ"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              double? newPrice = double.tryParse(priceController.text);
              if (newPrice != null) {
                await FirebaseFirestore.instance
                    .collection("sanpham")
                    .doc(docId)
                    .update({"price": newPrice});
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Quản lý Sản phẩm", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_square, color: kprimaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddProductScreen())),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("sanpham").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bool isAvailable = data["isAvailable"] ?? true;
              final double price = (data["price"] ?? 0).toDouble();

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        data["image"] ?? "", 
                        width: 60, height: 60, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60, height: 60, color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${price.toStringAsFixed(0)} đ", style: const TextStyle(color: kprimaryColor)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.edit, size: 20),
                      onPressed: () => _editPrice(context, docs[index].id, price),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _deleteProduct(context, docs[index].id),
                    ),
                    Switch(
                      value: isAvailable,
                      activeColor: kprimaryColor,
                      onChanged: (val) => _toggleAvailability(docs[index].id, isAvailable),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
