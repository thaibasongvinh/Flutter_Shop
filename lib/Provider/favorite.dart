import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class MyFavorite extends ChangeNotifier {
  List<String> _favoriteIds = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> get favorite => _favoriteIds;

  MyFavorite() {
    // Tự động lắng nghe thay đổi tài khoản
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadFavorites(); // Load dữ liệu khi có người đăng nhập
      } else {
        _favoriteIds = []; // Xóa trắng khi đăng xuất
        notifyListeners();
      }
    });
  }

  CollectionReference? get _userFavoriteCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection("user_profile").doc(user.uid).collection("favorites");
  }

  Future<void> toggleFavorite(DocumentSnapshot product) async {
    final user = _auth.currentUser;
    final collection = _userFavoriteCollection;
    if (collection == null || user == null) return;

    String productId = product.id;
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      await collection.doc(productId).delete();
    } else {
      _favoriteIds.add(productId);
      await collection.doc(productId).set({
        "productId": productId,
        "userEmail": user.email,
        "addedAt": DateTime.now(),
      });
    }
    notifyListeners();
  }

  bool isFavorite(DocumentSnapshot product) {
    return _favoriteIds.contains(product.id);
  }

  Future<void> loadFavorites() async {
    final collection = _userFavoriteCollection;
    if (collection == null) return;

    try {
      QuerySnapshot snapshot = await collection.get();
      _favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
      notifyListeners();
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  static MyFavorite of(BuildContext context, {bool listen = true}) {
    return Provider.of<MyFavorite>(context, listen: listen);
  }
}
