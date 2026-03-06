import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class VoucherScreen extends StatelessWidget {
  const VoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Kho Voucher", style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Tạm thời lấy tất cả để kiểm tra kết nối
        stream: FirebaseFirestore.instance.collection("vouchers").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.ticket_expired, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Chưa có mã giảm giá nào", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Quay lại"),
                  )
                ],
              ),
            );
          }

          final vouchers = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final data = vouchers[index].data() as Map<String, dynamic>;
              
              // Xử lý ngày tháng an toàn
              String dateStr = "Không thời hạn";
              if (data["expiryDate"] != null) {
                final expiryDate = (data["expiryDate"] as Timestamp).toDate();
                dateStr = DateFormat('dd/MM/yyyy').format(expiryDate);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        decoration: const BoxDecoration(
                          color: kprimaryColor,
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(15)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.ticket_discount, color: Colors.white, size: 30),
                            SizedBox(height: 5),
                            Text("VOUCHER", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Mã: ${data["code"] ?? "N/A"}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Giảm ngay ${currencyFormat.format(data["discount"] ?? 0)}đ",
                                style: const TextStyle(color: kprimaryColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Đơn tối thiểu: ${currencyFormat.format(data["minOrder"] ?? 0)}đ",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const Divider(),
                              Text(
                                "Hết hạn: $dateStr",
                                style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
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
}
