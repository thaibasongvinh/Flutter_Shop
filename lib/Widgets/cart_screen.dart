import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Provider/cart.dart';
import 'package:fodd/Widgets/recipe_detail.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double calculateTotal(List<DocumentSnapshot> docs, Map<String, int> cartMap) {
    double total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = data['price'] ?? 0;
      final quantity = cartMap[doc.id] ?? 0;
      total += (price is int ? price.toDouble() : price) * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final myCart = MyCart.of(context);
    final cartMap = myCart.cart;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text("Carts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
        elevation: 0,
      ),
      body: cartMap.isEmpty
          ? const Center(child: Text("Giỏ hàng trống", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)))
          : FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection("sanpham")
                  .where(FieldPath.documentId, whereIn: cartMap.keys.toList())
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Giỏ hàng trống"));
                }

                final docs = snapshot.data!.docs;
                final totalAmount = calculateTotal(docs, cartMap);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var cartData = docs[index];
                          final data = cartData.data() as Map<String, dynamic>;
                          final int quantity = cartMap[cartData.id] ?? 1;
                          final double price = (data['price'] ?? 0).toDouble();
                          final String imageUrl = data['image'] ?? data['picture'] ?? "";

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetail(documentSnapshot: cartData)));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.cardColor, // Đồng bộ nền thẻ
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(data["name"] ?? "No Name", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                                          const SizedBox(height: 5),
                                          Text("${price.toStringAsFixed(0)} VNĐ x $quantity", style: const TextStyle(color: kprimaryColor, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(Iconsax.flash_1, size: 16, color: Colors.grey),
                                              Text("${data["cal"]} Cal", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              const Text(" | ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                              const Icon(Iconsax.clock, size: 16, color: Colors.grey),
                                              const SizedBox(width: 2),
                                              Text("${data["time"]} Min", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => myCart.removeFromCart(cartData.id),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor, // Đồng bộ nền phần thanh toán
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Tổng tiền:", style: TextStyle(fontSize: 18, color: Colors.grey)),
                              Text("${totalAmount.toStringAsFixed(0)} VNĐ", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kprimaryColor)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Thanh toán"),
                                    content: Text("Xác nhận thanh toán ${totalAmount.toStringAsFixed(0)} VNĐ?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                                      TextButton(
                                        onPressed: () async {
                                          final user = FirebaseAuth.instance.currentUser;
                                          final batch = FirebaseFirestore.instance.batch();
                                          final orderRef = FirebaseFirestore.instance.collection("orders").doc();
                                          batch.set(orderRef, {
                                            "userEmail": user?.email,
                                            "total": totalAmount,
                                            "items": cartMap,
                                            "status": "Đang xử lý",
                                            "createdAt": DateTime.now(),
                                          });
                                          final notifyRef = FirebaseFirestore.instance.collection("user_profile").doc(user?.uid).collection("notifications").doc();
                                          batch.set(notifyRef, {"title": "Đặt hàng thành công", "body": "Đơn hàng trị giá ${totalAmount.toStringAsFixed(0)} VNĐ của bạn đã được tiếp nhận.", "isRead": false, "type": "order", "createdAt": DateTime.now()});
                                          await batch.commit();
                                          await myCart.clearCart();
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanh toán thành công!"), backgroundColor: Colors.green));
                                          }
                                        },
                                        child: const Text("Xác nhận"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text("Thanh toán", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
