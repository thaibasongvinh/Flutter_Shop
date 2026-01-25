import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Widgets/recipe_detail.dart';
import 'package:iconsax/iconsax.dart';
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
    final favorite = providerFavorite.favorite;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Đồng bộ nền app
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Favorites",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
        elevation: 0,
      ),
      body: favorite.isEmpty ? Center(
        child: Text(
            "No Favorites yet",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ) : ListView.builder(
        itemCount: favorite.length,
        itemBuilder: (context, index) {
          String favoriteID = favorite[index];
          return FutureBuilder<DocumentSnapshot>(
              future:  FirebaseFirestore.instance.collection("sanpham").doc(favoriteID).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('Error loading item'));
                }
                var favoriteData = snapshot.data!;
                return GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetail(documentSnapshot: favoriteData)));
                  },
                  child: Stack(
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(15),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.cardColor, // Đổi màu nền trắng của thẻ
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
                              ]
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    image: DecorationImage(image: NetworkImage(favoriteData["image"]), fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(width: 10,),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        favoriteData["name"],
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                                      ),
                                      const SizedBox(height: 5,),
                                      Row(
                                        children: [
                                          const Icon(Iconsax.flash_1, size: 16, color: Colors.grey),
                                          Text("${favoriteData["cal"]} Cal", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          const Text(" | ", style: TextStyle(color: Colors.grey)),
                                          const Icon(Iconsax.clock, size: 16, color: Colors.grey),
                                          const SizedBox(width: 2,),
                                          Text("${favoriteData["time"]} Min", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ),
                      Positioned(
                        top: 50,
                        right: 35,
                        child: GestureDetector(
                          onTap: () => providerFavorite.toggleFavorite(favoriteData),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }
          );
        }
      )
    );
  }
}
