import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    
    final Query ordersQuery = FirebaseFirestore.instance
        .collection("orders")
        .where("userEmail", isEqualTo: user?.email);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Lịch sử đơn hàng", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: theme.textTheme.bodyLarge?.color
          )
        ),
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
        stream: ordersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.box, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  const Text("Bạn chưa có đơn hàng nào", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final List<DocumentSnapshot> docs = snapshot.data!.docs;
          docs.sort((a, b) {
            Timestamp t1 = a["createdAt"] ?? Timestamp.now();
            Timestamp t2 = b["createdAt"] ?? Timestamp.now();
            return t2.compareTo(t1);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var order = docs[index];
              final data = order.data() as Map<String, dynamic>;
              final double total = (data["total"] ?? 0).toDouble();
              final String status = data["status"] ?? "Đang xử lý";
              final Map items = data["items"] ?? {};

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05), 
                      blurRadius: 10, 
                      spreadRadius: 2
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Mã ĐH: ${order.id.substring(0, 8).toUpperCase()}", 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14,
                            color: theme.textTheme.bodyLarge?.color
                          )
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                    Divider(height: 20, color: theme.dividerColor),
                    Text(
                      "Số lượng món: ${items.length}", 
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Ngày đặt: ${_formatDate(data["createdAt"])}", 
                      style: const TextStyle(color: Colors.grey, fontSize: 13)
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tổng tiền:", 
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color
                          )
                        ),
                        Text(
                          "${total.toStringAsFixed(0)} VNĐ", 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18, 
                            color: kprimaryColor
                          )
                        ),
                      ],
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

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == "Đã giao") color = Colors.green;
    if (status == "Đã hủy") color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp as Timestamp).toDate();
    String minute = date.minute.toString().padLeft(2, '0');
    return "${date.day}/${date.month}/${date.year} ${date.hour}:$minute";
  }
}
