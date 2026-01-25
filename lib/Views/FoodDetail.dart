import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Widgets/Banner.dart';
import 'package:fodd/Widgets/ViewAllItems.dart';
import 'package:fodd/Widgets/icon_button.dart';
import 'package:fodd/Views/SearchScreen.dart';
import 'package:fodd/Views/NotificationScreen.dart';
import 'package:iconsax/iconsax.dart';

import '../Utils/Constants.dart';
import 'FoodItems.dart';

class FoodDetail extends StatefulWidget{
  const FoodDetail({super.key});
  @override
  State<FoodDetail> createState() => _FoodDetailState();
}

class _FoodDetailState extends State<FoodDetail> {

  String category = "All";
  final CollectionReference categoriesItems = FirebaseFirestore.instance.collection("nhomsanpham");
  Query get fileteredRecipes => FirebaseFirestore.instance.collection("sanpham").where("category", isEqualTo: category);
  Query get allRecipes => FirebaseFirestore.instance.collection("sanpham");
  Query get selectedRecipes => category == "All" ? allRecipes : fileteredRecipes;

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
      backgroundColor: theme.scaffoldBackgroundColor, // Đồng bộ nền
      body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal:15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance.collection("user_profile").doc(user?.uid).snapshots(),
                            builder: (context, snapshot) {
                              String displayName = "Chào bạn";
                              if (snapshot.hasData && snapshot.data!.exists) {
                                String fullName = snapshot.data!["name"] ?? "";
                                if (fullName.isNotEmpty) {
                                  displayName = "Chào ${getLastName(fullName)}";
                                }
                              }
                              return Text(
                                  displayName,
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color, // Đồng bộ màu chữ
                                      height: 1
                                  )
                              );
                            }
                          ),
                          const Spacer(),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("user_profile")
                                .doc(user?.uid)
                                .collection("notifications")
                                .where("isRead", isEqualTo: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int unreadCount = 0;
                              if (snapshot.hasData) {
                                unreadCount = snapshot.data!.docs.length;
                              }

                              return Stack(
                                children: [
                                  MyIconButton(
                                      icon: Iconsax.notification,
                                      onPressed: (){
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const NotificationScreen()),
                                        );
                                      },
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 5,
                                      top: 5,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }
                          )
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SearchScreen()),
                            );
                          },
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: theme.cardColor, // Đồng bộ màu ô search
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              children: [
                                const Icon(Iconsax.search_normal, color: Colors.grey,),
                                const SizedBox(width: 10,),
                                Text(
                                  "Search...",
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const MyBanner(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "Food",style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      StreamBuilder(
                          stream: categoriesItems.snapshots(),
                          builder: (context,AsyncSnapshot<QuerySnapshot> streamSnapshot){
                            if(streamSnapshot.hasData){
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                    streamSnapshot.data!.docs.length,
                                        (index)=> GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              category = streamSnapshot.data!.docs[index]["name"];
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(25),
                                              color: category == streamSnapshot.data!.docs[index]["name"] ? kprimaryColor : theme.cardColor,
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            margin: const EdgeInsets.only(right: 20),
                                            child: Text(
                                              streamSnapshot.data!.docs[index]["name"],
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: category == streamSnapshot.data!.docs[index]["name"] ? Colors.white : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ),
                                  )
                                ),
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                      ),

                      const SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Quik & Easy",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                                letterSpacing: 0.1
                            ),
                          ),
                          TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllItems()));
                              },
                              child: const Text(
                                  "View all",
                                  style: TextStyle(color: kbBannerColor, fontWeight: FontWeight.w600),
                              ),
                          ),
                        ],
                      ),
                    ]
                  )
                ),
                StreamBuilder(
                  stream: selectedRecipes.snapshots(),
                  builder: (context,AsyncSnapshot<QuerySnapshot> snapshot){
                    if(snapshot.hasData){
                      final List<DocumentSnapshot> recipes = snapshot.data!.docs;
                      return Padding(
                        padding: const EdgeInsets.only(top: 5, left: 15),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: recipes.map((e) => FoodItems(documentSnapshot: e)).toList(),
                          ),
                        ),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ]
            )
          )
      ),
    );
  }
}
