import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Views/OrderDetailScreen.dart';
import 'package:fodd/Widgets/shimmer_skeleton.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    try {
      await FirebaseFirestore.instance.collection("orders").doc(orderId).update({
        "status": "Đã hủy",
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hủy đơn hàng thành công!"), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi hủy đơn hàng"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "vi_VN");
    
    final Query ordersQuery = FirebaseFirestore.instance
        .collection("orders")
        .where("userEmail", isEqualTo: user?.email);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("Lịch sử đơn hàng", style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(icon: Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(padding: const EdgeInsets.all(15), itemCount: 5, itemBuilder: (context, index) => const OrderSkeleton());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bạn chưa có đơn hàng nào", style: TextStyle(color: Colors.grey)));
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

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Đơn # ${order.id.substring(0, 6).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          _buildStatusChip(status),
                        ],
                      ),
                      const Divider(height: 25),
                      Text("Tổng tiền: ${currencyFormat.format(total)} VNĐ", style: const TextStyle(color: kprimaryColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(data["createdAt"]), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          // CHỈ CHO PHÉP HỦY KHI ĐANG "CHỜ XÁC NHẬN"
                          if (status == "Chờ xác nhận")
                            TextButton(
                              onPressed: () => _cancelOrder(context, order.id),
                              child: const Text("Hủy đơn", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            )
                          else
                            const Text("Xem chi tiết >", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
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

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status == "Đang chuẩn bị") color = Colors.orange;
    if (status == "Đang giao") color = Colors.blue;
    if (status == "Đã giao thành công") color = Colors.green;
    if (status == "Đã hủy") color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
