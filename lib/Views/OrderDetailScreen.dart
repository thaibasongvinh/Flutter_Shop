import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Widgets/recipe_detail.dart'; 
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class OrderDetailScreen extends StatelessWidget {
  final DocumentSnapshot order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final data = order.data() as Map<String, dynamic>;
    final theme = Theme.of(context);
    final List items = data["items"] is List ? data["items"] : [];
    final double total = (data["total"] ?? 0).toDouble();
    final double discount = (data["discount"] ?? 0).toDouble();
    final String status = data["status"] ?? "Chờ xác nhận";
    final currencyFormat = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("Chi tiết đơn hàng", style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(icon: Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStep(Iconsax.document_text, "Đã đặt", _getStepIndex(status) >= 0),
                      _buildDivider(_getStepIndex(status) >= 1),
                      _buildStep(Iconsax.status, "Chế biến", _getStepIndex(status) >= 1),
                      _buildDivider(_getStepIndex(status) >= 2),
                      _buildStep(Iconsax.truck, "Đang giao", _getStepIndex(status) >= 2),
                      _buildDivider(_getStepIndex(status) >= 3),
                      _buildStep(Iconsax.tick_circle, "Đã nhận", _getStepIndex(status) >= 3),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    status == "Đã hủy" ? "Đơn hàng đã bị hủy" : "Trạng thái hiện tại: $status",
                    style: TextStyle(
                      color: status == "Đã hủy" ? Colors.red : kprimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text("Thông tin giao hàng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildInfoCard(theme, [
              _infoRow(Iconsax.user, "Người nhận", data["userName"] ?? "Khách hàng"),
              _infoRow(Iconsax.call, "Số điện thoại", data["phone"] ?? "N/A"),
              _infoRow(Iconsax.location, "Địa chỉ", data["address"] ?? "N/A"),
              _infoRow(Iconsax.card, "Thanh toán", data["paymentMethod"] ?? "COD"),
              if (data["note"] != null && data["note"].toString().isNotEmpty)
                _infoRow(Iconsax.note, "Ghi chú", data["note"]),
            ]),

            const SizedBox(height: 25),

            const Text("Món ăn đã đặt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            
            Column(
              children: items.map((item) {
                final i = item as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () async {
                    final doc = await FirebaseFirestore.instance.collection("sanpham").doc(i["productId"]).get();
                    // SỬA LỖI: Dùng context.mounted thay vì mounted
                    if (doc.exists && context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => RecipeDetail(documentSnapshot: doc)));
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(i["image"] ?? "", width: 60, height: 60, fit: BoxFit.cover, 
                            errorBuilder: (c, e, s) => const Icon(Icons.fastfood, size: 40, color: Colors.grey)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("${i['selectedSize']}${i['selectedToppings'].isNotEmpty ? ' | ' + (i['selectedToppings'] as List).join(', ') : ''}", 
                                style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              Text("Số lượng: ${i['quantity']}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text("${currencyFormat.format(i["totalPrice"] * i["quantity"])} đ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            _buildInfoCard(theme, [
              if (discount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Giảm giá", style: TextStyle(color: Colors.red)),
                      Text("- ${currencyFormat.format(discount)} đ", style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tổng cộng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("${currencyFormat.format(total)} đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: kprimaryColor)),
                ],
              ),
            ]),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  int _getStepIndex(String status) {
    switch (status) {
      case "Chờ xác nhận": return 0;
      case "Đang chuẩn bị": return 1;
      case "Đang giao": return 2;
      case "Đã giao thành công": return 3;
      default: return -1;
    }
  }

  Widget _buildStep(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Icon(icon, color: isActive ? kprimaryColor : Colors.grey.shade300, size: 24),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? kprimaryColor : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildDivider(bool isActive) {
    return Container(
      width: 30, height: 2,
      color: isActive ? kprimaryColor : Colors.grey.shade300,
    );
  }

  Widget _buildInfoCard(ThemeData theme, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
