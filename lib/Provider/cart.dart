import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class MyCart extends ChangeNotifier {
  Map<String, int> _cartItems = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, int> get cart => _cartItems;

  MyCart() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadCarts();
      } else {
        _cartItems = {};
        notifyListeners();
      }
    });
  }

  CollectionReference? get _userCartCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection("user_profile").doc(user.uid).collection("carts");
  }

  Future<void> addToCart(DocumentSnapshot product, int quantity) async {
    final user = _auth.currentUser;
    final collection = _userCartCollection;
    if (collection == null || user == null) return;

    String productId = product.id;
    
    await collection.doc(productId).set({
      "productId": productId,
      "quantity": quantity,
      "userEmail": user.email,
      "addedAt": DateTime.now(),
    });

    _cartItems[productId] = quantity;
    notifyListeners();
  }

  Future<void> removeFromCart(String productId) async {
    final collection = _userCartCollection;
    if (collection == null) return;

    await collection.doc(productId).delete();
    _cartItems.remove(productId);
    notifyListeners();
  }

  // Hàm xóa sạch giỏ hàng (Dùng sau khi thanh toán thành công)
  Future<void> clearCart() async {
    final collection = _userCartCollection;
    if (collection == null) return;

    final snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
    _cartItems = {};
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _cartItems.containsKey(productId);
  }

  Future<void> loadCarts() async {
    final collection = _userCartCollection;
    if (collection == null) return;

    try {
      QuerySnapshot snapshot = await collection.get();
      Map<String, int> tempItems = {};
      for (var doc in snapshot.docs) {
        tempItems[doc.id] = doc["quantity"];
      }
      _cartItems = tempItems;
      notifyListeners();
    } catch (e) {
      print("Error loading carts: $e");
    }
  }

  static MyCart of(BuildContext context, {bool listen = true}) {
    return Provider.of<MyCart>(context, listen: listen);
  }
}
