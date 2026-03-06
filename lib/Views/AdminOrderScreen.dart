import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class AdminOrderScreen extends StatelessWidget {
  const AdminOrderScreen({super.key});

  Future<void> _updateStatus(BuildContext context, String orderId, String userId, String newStatus) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Không tìm thấy ID người dùng!"), backgroundColor: Colors.red));
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection("orders").doc(orderId);
      
      batch.update(orderRef, {"status": newStatus});

      String title = "";
      String body = "";
      
      switch (newStatus) {
        case "Đang chuẩn bị":
          title = "Nhà hàng đã nhận đơn!";
          body = "Món ăn của bạn đang được chế biến.";
          break;
        case "Đang giao":
          title = "Đơn hàng đang đến!";
          body = "Tài xế đang giao món ăn tới bạn.";
          break;
        case "Đã giao thành công":
          title = "Giao hàng thành công";
          body = "Chúc bạn ngon miệng! Đừng quên đánh giá nhé.";
          break;
        case "Đã hủy":
          title = "Đơn hàng bị hủy";
          body = "Rất tiếc, đơn hàng #$orderId đã bị hủy.";
          break;
      }

      final notifyRef = FirebaseFirestore.instance
          .collection("user_profile")
          .doc(userId)
          .collection("notifications")
          .doc();
      
      batch.set(notifyRef, {
        "title": title,
        "body": body,
        "isRead": false,
        "type": "order",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await batch.commit();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã cập nhật: $newStatus"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi cập nhật trạng thái"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Quản lý Đơn hàng", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(icon: Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("orders").orderBy("createdAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!.docs;
          if (orders.isEmpty) return const Center(child: Text("Không có đơn hàng nào"));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data() as Map<String, dynamic>;
              final String status = data["status"] ?? "Chờ xác nhận";
              final String userId = data["userId"] ?? "";
              final double total = (data["total"] ?? 0).toDouble();
              
              final List items = data["items"] is List ? data["items"] : [];

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
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
                    _infoLine(Iconsax.user, data["userEmail"] ?? "Ẩn danh"),
                    _infoLine(Iconsax.location, data["address"] ?? "Không rõ"),
                    _infoLine(Iconsax.money_send, "${currencyFormat.format(total)} VNĐ"),
                    
                    const SizedBox(height: 10),
                    const Text("Danh sách món:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ...items.map((item) {
                      final i = item as Map<String, dynamic>;
                      return Text("• ${i['name']} (${i['selectedSize']}) x ${i['quantity']}", 
                        style: const TextStyle(fontSize: 11, color: Colors.grey));
                    }),

                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status == "Chờ xác nhận")
                          _adminButton("Nhận đơn", Colors.orange, () => _updateStatus(context, order.id, userId, "Đang chuẩn bị")),
                        if (status == "Đang chuẩn bị")
                          _adminButton("Giao hàng", Colors.blue, () => _updateStatus(context, order.id, userId, "Đang giao")),
                        if (status == "Đang giao")
                          _adminButton("Hoàn thành", Colors.green, () => _updateStatus(context, order.id, userId, "Đã giao thành công")),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)))]),
    );
  }

  Widget _adminButton(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
}
