import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  void _addAddress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thêm địa chỉ mới"),
        content: TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            hintText: "Nhập địa chỉ đầy đủ",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor),
            onPressed: () async {
              if (_addressController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection("user_profile")
                    .doc(user?.uid)
                    .collection("addresses")
                    .add({
                  "address": _addressController.text.trim(),
                  "isDefault": false,
                  "createdAt": DateTime.now(),
                });
                _addressController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.white)),
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
        title: Text("Địa chỉ của tôi", style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("user_profile")
            .doc(user?.uid)
            .collection("addresses")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.location, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Chưa có địa chỉ nào được lưu", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: kprimaryColor,
                    child: Icon(Iconsax.location, color: Colors.white, size: 18),
                  ),
                  title: Text(data["address"], style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => docs[index].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kprimaryColor,
        onPressed: _addAddress,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
