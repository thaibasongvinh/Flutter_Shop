import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Widgets/Banner.dart';
import 'package:fodd/Widgets/ViewAllItems.dart';
import 'package:fodd/Widgets/icon_button.dart';
import 'package:fodd/Views/SearchScreen.dart';
import 'package:fodd/Views/NotificationScreen.dart';
import 'package:fodd/Widgets/shimmer_skeleton.dart';
import 'package:fodd/Widgets/recipe_detail.dart';
import 'package:iconsax/iconsax.dart';

import '../Utils/Constants.dart';
import 'FoodItems.dart';

class FoodDetail extends StatefulWidget {
  const FoodDetail({super.key});
  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {
  String category = "All";
  final CollectionReference categoriesItems = FirebaseFirestore.instance.collection("nhomsanpham");

  // Query cho phần gợi ý (Cuộn ngang)
  Query get suggestionQuery => category == "All"
      ? FirebaseFirestore.instance.collection("sanpham").limit(5)
      : FirebaseFirestore.instance.collection("sanpham").where("category", isEqualTo: category).limit(5);

  // Query cho phần phổ biến (Lưới dọc) - Có lọc theo Category
  Query get popularQuery => (category == "All"
      ? FirebaseFirestore.instance.collection("sanpham") 
      : FirebaseFirestore.instance.collection("sanpham").where("category", isEqualTo: category))
      .orderBy("rating", descending: true);

  String getLastName(String fullName) {
    if (fullName.isEmpty) return "Bạn";
    List<String> parts = fullName.trim().split(' ');
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: kprimaryColor,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HEADER
                      Row(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection("user_profile").doc(user?.uid).snapshots(),
                            builder: (context, snapshot) {
                              String profilePic = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
                              if (snapshot.hasData && snapshot.data!.exists) {
                                profilePic = snapshot.data!["profilePic"] ?? profilePic;
                              }
                              return Container(
                                width: 45, height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kprimaryColor, width: 2),
                                  image: DecorationImage(image: NetworkImage(profilePic), fit: BoxFit.cover),
                                ),
                              );
                            }
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance.collection("user_profile").doc(user?.uid).snapshots(),
                                  builder: (context, snapshot) {
                                    String displayName = "Bạn";
                                    if (snapshot.hasData && snapshot.data!.exists) {
                                      String fullName = snapshot.data!["name"] ?? "";
                                      if (fullName.isNotEmpty) displayName = getLastName(fullName);
                                    }
                                    return Text("Chào $displayName!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color));
                                  }
                                ),
                                Row(
                                  children: [
                                    const Icon(Iconsax.location5, size: 12, color: kprimaryColor),
                                    const SizedBox(width: 4),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance.collection("user_profile").doc(user?.uid).collection("addresses").limit(1).snapshots(),
                                      builder: (context, snapshot) {
                                        String addr = "Chưa có địa chỉ";
                                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                          addr = snapshot.data!.docs.first["address"];
                                        }
                                        return Expanded(child: Text(addr, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis));
                                      }
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection("user_profile").doc(user?.uid).collection("notifications").where("isRead", isEqualTo: false).snapshots(),
                            builder: (context, snapshot) {
                              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                              return Stack(
                                children: [
                                  MyIconButton(icon: Iconsax.notification, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()))),
                                  if (unreadCount > 0)
                                    Positioned(right: 5, top: 5, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
                                ],
                              );
                            }
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: const Row(
                            children: [
                              Icon(Iconsax.search_normal, color: Colors.grey),
                              SizedBox(width: 10),
                              Text("Tìm món ăn, trà sữa...", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const MyBanner(),

                      // CATEGORIES
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text("Danh mục", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      ),
                      StreamBuilder(
                        stream: categoriesItems.snapshots(),
                        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                          if (streamSnapshot.hasData) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  streamSnapshot.data!.docs.length,
                                  (index) => GestureDetector(
                                    onTap: () => setState(() => category = streamSnapshot.data!.docs[index]["name"]),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        color: category == streamSnapshot.data!.docs[index]["name"] ? kprimaryColor : theme.cardColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      margin: const EdgeInsets.only(right: 15),
                                      child: Text(streamSnapshot.data!.docs[index]["name"], style: TextStyle(fontWeight: FontWeight.w600, color: category == streamSnapshot.data!.docs[index]["name"] ? Colors.white : Colors.grey.shade600)),
                                    ),
                                  ),
                                )
                              ),
                            );
                          }
                          return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(5, (index) => const CategorySkeleton())));
                        },
                      ),

                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Gợi ý cho bạn", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllItems())), child: const Text("Tất cả", style: TextStyle(color: kbBannerColor, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ]
                  )
                ),
                
                // GỢI Ý CUỘN NGANG
                StreamBuilder(
                  stream: suggestionQuery.snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 5, left: 15),
                        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: snapshot.data!.docs.map((e) => FoodItems(documentSnapshot: e)).toList())),
                      );
                    }
                    return Padding(padding: const EdgeInsets.only(left: 15), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(3, (index) => const FoodItemSkeleton()))));
                  },
                ),

                // PHỔ BIẾN DẠNG LƯỚI (GRID)
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    category == "All" ? "Món ăn phổ biến" : "Phổ biến trong $category", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)
                  ),
                ),
                StreamBuilder(
                  stream: popularQuery.snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(15),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 10, mainAxisSpacing: 15),
                        itemCount: 4,
                        itemBuilder: (context, index) => const FoodItemSkeleton(),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text("Không tìm thấy món ăn nào.", style: TextStyle(color: Colors.grey))),
                      );
                    }
                    final docs = snapshot.data!.docs;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(15),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        // TÁI SỬ DỤNG FOODITEMS ĐỂ CÓ HIỆU ỨNG HERO VÀ UI MƯỢT MÀ
                        return FoodItems(documentSnapshot: docs[index]);
                      },
                    );
                  },
                ),
                const SizedBox(height: 100),
              ]
            )
          ),
        )
      ),
    );
  }
}
