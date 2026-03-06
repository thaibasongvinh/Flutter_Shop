import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final double basePrice;
  final int quantity;
  final String selectedSize;
  final List<String> selectedToppings;
  final double totalPrice;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.basePrice,
    required this.quantity,
    required this.selectedSize,
    required this.selectedToppings,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      "productId": productId,
      "name": name,
      "image": image,
      "basePrice": basePrice,
      "quantity": quantity,
      "selectedSize": selectedSize,
      "selectedToppings": selectedToppings,
      "totalPrice": totalPrice,
    };
  }
}

class MyCart extends ChangeNotifier {
  Map<String, CartItem> _cartItems = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;

  String? _appliedVoucherCode;
  double _discountAmount = 0;

  Map<String, CartItem> get cart => _cartItems;
  bool get isProcessing => _isProcessing;
  double get discountAmount => _discountAmount;
  String? get appliedVoucherCode => _appliedVoucherCode;

  MyCart() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadCarts();
      } else {
        _cartItems = {};
        _appliedVoucherCode = null;
        _discountAmount = 0;
        notifyListeners();
      }
    });
  }

  String _generateCartItemId(String productId, String size, List<String> toppings) {
    toppings.sort();
    return "${productId}_${size}_${toppings.join(",")}";
  }

  Future<void> addToCart({
    required DocumentSnapshot product,
    required int quantity,
    required String size,
    required List<String> toppings,
    required double itemTotalPrice,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = product.data() as Map<String, dynamic>;
    String cartItemId = _generateCartItemId(product.id, size, toppings);

    if (_cartItems.containsKey(cartItemId)) {
      int newQty = _cartItems[cartItemId]!.quantity + quantity;
      await updateQuantity(cartItemId, newQty);
    } else {
      CartItem newItem = CartItem(
        id: cartItemId,
        productId: product.id,
        name: data["name"],
        image: data["image"] ?? data["picture"],
        basePrice: (data["price"] ?? 0).toDouble(),
        quantity: quantity,
        selectedSize: size,
        selectedToppings: toppings,
        totalPrice: itemTotalPrice,
      );

      await _firestore.collection("user_profile").doc(user.uid).collection("carts").doc(cartItemId).set(newItem.toMap());
      _cartItems[cartItemId] = newItem;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
    } else {
      await _firestore.collection("user_profile").doc(user.uid).collection("carts").doc(cartItemId).update({"quantity": newQuantity});
      final oldItem = _cartItems[cartItemId]!;
      _cartItems[cartItemId] = CartItem(
        id: oldItem.id,
        productId: oldItem.productId,
        name: oldItem.name,
        image: oldItem.image,
        basePrice: oldItem.basePrice,
        quantity: newQuantity,
        selectedSize: oldItem.selectedSize,
        selectedToppings: oldItem.selectedToppings,
        totalPrice: oldItem.totalPrice,
      );
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection("user_profile").doc(user.uid).collection("carts").doc(cartItemId).delete();
    _cartItems.remove(cartItemId);
    notifyListeners();
  }

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshots = await _firestore.collection("user_profile").doc(user.uid).collection("carts").get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
    _cartItems = {};
    _appliedVoucherCode = null;
    _discountAmount = 0;
    notifyListeners();
  }

  Future<void> loadCarts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot snapshot = await _firestore.collection("user_profile").doc(user.uid).collection("carts").get();
      Map<String, CartItem> tempItems = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        tempItems[doc.id] = CartItem(
          id: doc.id,
          productId: data["productId"],
          name: data["name"],
          image: data["image"],
          basePrice: (data["basePrice"] ?? 0).toDouble(),
          quantity: data["quantity"],
          selectedSize: data["selectedSize"] ?? "Thường",
          selectedToppings: List<String>.from(data["selectedToppings"] ?? []),
          totalPrice: (data["totalPrice"] ?? 0).toDouble(),
        );
      }
      _cartItems = tempItems;
      notifyListeners();
    } catch (e) {
      print("Error loading carts: $e");
    }
  }

  Future<String?> applyVoucher(String code, double currentTotal) async {
    try {
      final query = await _firestore.collection("vouchers").where("code", isEqualTo: code.toUpperCase()).get();
      if (query.docs.isEmpty) return "Mã giảm giá không tồn tại!";

      final voucher = query.docs.first.data();
      final expiry = (voucher["expiryDate"] as Timestamp).toDate();
      
      if (DateTime.now().isAfter(expiry)) return "Mã giảm giá đã hết hạn!";
      if (currentTotal < (voucher["minOrder"] ?? 0)) return "Đơn hàng tối thiểu để dùng mã này là ${voucher["minOrder"]}đ";

      _appliedVoucherCode = code.toUpperCase();
      _discountAmount = (voucher["discount"] as num).toDouble();
      notifyListeners();
      return null;
    } catch (e) {
      return "Lỗi khi áp dụng mã giảm giá";
    }
  }

  Future<bool> placeOrder({
    required String phone,
    required String address,
    required double total,
    required String paymentMethod,
    required String note, // Thêm ghi chú
  }) async {
    final user = _auth.currentUser;
    if (user == null || _cartItems.isEmpty) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final orderRef = _firestore.collection("orders").doc();
      
      batch.set(orderRef, {
        "userId": user.uid,
        "userEmail": user.email,
        "phone": phone,
        "address": address,
        "total": total,
        "discount": _discountAmount,
        "voucherCode": _appliedVoucherCode,
        "items": _cartItems.values.map((item) => item.toMap()).toList(),
        "paymentMethod": paymentMethod,
        "note": note, // Lưu ghi chú vào đơn hàng
        "status": "Chờ xác nhận",
        "createdAt": FieldValue.serverTimestamp(),
      });

      final notifyRef = _firestore.collection("user_profile").doc(user.uid).collection("notifications").doc();
      batch.set(notifyRef, {
        "title": "Đặt hàng thành công",
        "body": "Đơn hàng của bạn đang được hệ thống xác nhận.",
        "isRead": false,
        "type": "order",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await batch.commit();
      await clearCart();
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  static MyCart of(BuildContext context, {bool listen = true}) {
    return Provider.of<MyCart>(context, listen: listen);
  }
}
