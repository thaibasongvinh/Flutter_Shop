import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Provider/cart.dart'; // Import Cart Provider
import 'package:fodd/Widgets/recipe_detail.dart';
import 'package:fodd/Widgets/shimmer_skeleton.dart'; // Import Shimmer
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../Provider/favorite.dart';
import '../Utils/Constants.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    final providerFavorite = MyFavorite.of(context);
    final providerCart = MyCart.of(context);
    final favorite = providerFavorite.favorite;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Yêu thích",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        elevation: 0,
      ),
      body: favorite.isEmpty ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.heart_slash, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text(
              "Danh sách yêu thích trống",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      ) : ListView.builder(
        itemCount: favorite.length,
        itemBuilder: (context, index) {
          String favoriteID = favorite[index];
          return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("sanpham").doc(favoriteID).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // SỬ DỤNG SHIMMER KHI ĐANG TẢI
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: ShimmerSkeleton(height: 100, width: double.infinity),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                  return const SizedBox();
                }
                var favoriteData = snapshot.data!;
                final data = favoriteData.data() as Map<String, dynamic>;
                final bool isAvailable = data.containsKey("isAvailable") ? data["isAvailable"] : true;

                return GestureDetector(
                  onTap: (){
                    if (isAvailable) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetail(documentSnapshot: favoriteData)));
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                    ),
                    child: Row(
                      children: [
                        // Ảnh món ăn (Làm mờ nếu hết hàng)
                        ColorFiltered(
                          colorFilter: isAvailable 
                            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                            : const ColorFilter.matrix([0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]),
                          child: Container(
                            width: 100, height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(image: NetworkImage(data["image"]), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data["name"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isAvailable ? theme.textTheme.bodyLarge?.color : Colors.grey)),
                              const SizedBox(height: 5),
                              Text("${currencyFormat.format(data["price"])} đ", style: const TextStyle(color: kprimaryColor, fontWeight: FontWeight.bold)),
                              if (!isAvailable)
                                const Text("Tạm hết hàng", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        
                        // NÚT CHỨC NĂNG
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => providerFavorite.toggleFavorite(favoriteData),
                              child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                            ),
                            const SizedBox(height: 15),
                            // THÊM NHANH VÀO GIỎ HÀNG
                            if (isAvailable)
                              GestureDetector(
                                onTap: () {
                                  providerCart.addToCart(
                                    product: favoriteData,
                                    quantity: 1,
                                    size: "Vừa",
                                    toppings: [],
                                    itemTotalPrice: (data["price"] ?? 0).toDouble(),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm vào giỏ!"), duration: Duration(seconds: 1)));
                                },
                                child: const Icon(Iconsax.add_circle5, color: kprimaryColor, size: 28),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
          );
        }
      )
    );
  }
}
