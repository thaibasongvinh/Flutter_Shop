import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Provider/cart.dart';
import 'package:fodd/Views/SuccessScreen.dart';
import 'package:fodd/Views/AddressScreen.dart';
import 'package:fodd/Widgets/recipe_detail.dart'; // Import để chuyển hướng
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../Utils/Constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _selectedAddress;
  String _paymentMethod = "COD";
  final double _shippingFee = 15000;
  final currencyFormat = NumberFormat("#,##0", "vi_VN");

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection("user_profile").doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey("phone")) {
        setState(() {
          _phoneController.text = doc.data()!["phone"] ?? "";
        });
      }
    }
  }

  double calculateSubTotal(Map<String, CartItem> cartMap) {
    double total = 0;
    cartMap.forEach((key, item) {
      total += item.totalPrice * item.quantity;
    });
    return total;
  }

  void _showCheckoutDialog(double totalAmount, MyCart myCart) {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Xác nhận thanh toán"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Số điện thoại:", style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: "Nhập SĐT nhận hàng"),
                ),
                const SizedBox(height: 15),
                const Text("Chọn địa chỉ:", style: TextStyle(fontWeight: FontWeight.bold)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("user_profile")
                      .doc(user?.uid)
                      .collection("addresses")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddressScreen())),
                        child: const Text("+ Thêm địa chỉ mới", style: TextStyle(color: kprimaryColor)),
                      );
                    }
                    final addresses = snapshot.data!.docs;
                    if (_selectedAddress == null && addresses.isNotEmpty) {
                      _selectedAddress = (addresses.first.data() as Map<String, dynamic>)["address"];
                    }
                    return DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedAddress,
                      hint: const Text("Chọn địa chỉ đã lưu"),
                      items: addresses.map((doc) {
                        String addr = (doc.data() as Map<String, dynamic>)["address"];
                        return DropdownMenuItem(value: addr, child: Text(addr, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => _selectedAddress = val),
                    );
                  },
                ),
                const SizedBox(height: 15),
                const Text("Phương thức thanh toán:", style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<String>(value: "COD", groupValue: _paymentMethod, onChanged: (val) => setDialogState(() => _paymentMethod = val!)),
                  title: const Text("Tiền mặt (COD)"),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<String>(value: "Momo", groupValue: _paymentMethod, onChanged: (val) => setDialogState(() => _paymentMethod = val!)),
                  title: const Text("Ví Momo"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor),
              onPressed: myCart.isProcessing ? null : () async {
                if (_phoneController.text.isEmpty || _selectedAddress == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập SĐT và chọn địa chỉ")));
                  return;
                }
                
                await FirebaseFirestore.instance.collection("user_profile").doc(user?.uid).update({
                  "phone": _phoneController.text.trim(),
                });

                bool success = await myCart.placeOrder(
                  phone: _phoneController.text,
                  address: _selectedAddress!,
                  total: totalAmount,
                  paymentMethod: _paymentMethod,
                  note: _noteController.text.trim(),
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SuccessScreen()));
                }
              },
              child: myCart.isProcessing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Xác nhận", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myCart = MyCart.of(context);
    final cartItems = myCart.cart.values.toList();
    final theme = Theme.of(context);
    final subTotal = calculateSubTotal(myCart.cart);
    final totalAmount = subTotal + _shippingFee - myCart.discountAmount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text("Giỏ hàng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
        elevation: 0,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.trash, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Xóa giỏ hàng?"),
                    content: const Text("Bạn có chắc chắn muốn xóa tất cả sản phẩm khỏi giỏ hàng không?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                      TextButton(
                        onPressed: () {
                          myCart.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text("Xác nhận", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.shopping_cart, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text("Giỏ hàng của bạn đang trống", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return GestureDetector(
                      // KHI NHẤN VÀO ITEM GIỎ HÀNG THÌ VÀO XEM CHI TIẾT
                      onTap: () async {
                        final doc = await FirebaseFirestore.instance.collection("sanpham").doc(item.productId).get();
                        if (doc.exists && mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (c) => RecipeDetail(documentSnapshot: doc)));
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(item.image, width: 80, height: 80, fit: BoxFit.cover)),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("${item.selectedSize}${item.selectedToppings.isNotEmpty ? ' | ' + item.selectedToppings.join(', ') : ''}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 5),
                                    Text("${currencyFormat.format(item.totalPrice)} đ", style: const TextStyle(color: kprimaryColor, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _qtyButton(Icons.remove, () => myCart.updateQuantity(item.id, item.quantity - 1)),
                                        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold))),
                                        _qtyButton(Icons.add, () => myCart.updateQuantity(item.id, item.quantity + 1)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => myCart.removeFromCart(item.id)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
                child: Column(
                  children: [
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Ghi chú cho nhà hàng (ví dụ: Ít cay, không hành...)",
                        prefixIcon: const Icon(Iconsax.note_text, size: 18),
                        border: InputBorder.none,
                        fillColor: theme.scaffoldBackgroundColor.withOpacity(0.5),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voucherController,
                            decoration: InputDecoration(
                              hintText: "Mã giảm giá",
                              fillColor: theme.scaffoldBackgroundColor,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          onPressed: () async {
                            String? error = await myCart.applyVoucher(_voucherController.text, subTotal);
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Áp dụng mã thành công!"), backgroundColor: Colors.green));
                            }
                          },
                          child: const Text("Áp dụng", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    _priceRow("Tạm tính:", "${currencyFormat.format(subTotal)} đ", Colors.grey),
                    _priceRow("Phí giao hàng:", "${currencyFormat.format(_shippingFee)} đ", Colors.grey),
                    if (myCart.discountAmount > 0)
                      _priceRow("Giảm giá (${myCart.appliedVoucherCode}):", "- ${currencyFormat.format(myCart.discountAmount)} đ", Colors.red),
                    const Divider(height: 20),
                    _priceRow("Tổng cộng:", "${currencyFormat.format(totalAmount)} đ", kprimaryColor, isBold: true),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kprimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: () => _showCheckoutDialog(totalAmount, myCart),
                        child: const Text("Thanh toán ngay", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _priceRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: color)),
          Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: kprimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: kprimaryColor),
      ),
    );
  }
}
