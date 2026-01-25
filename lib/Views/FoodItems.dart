import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../Provider/favorite.dart';
import '../Widgets/recipe_detail.dart';

class FoodItems extends StatefulWidget {
  final DocumentSnapshot<Object?> documentSnapshot;
  const FoodItems({super.key, required this.documentSnapshot});

  @override
  State<FoodItems> createState() => _FoodItemsState();
}

class _FoodItemsState extends State<FoodItems> {
  @override
  Widget build(BuildContext context) {
    final provider = MyFavorite.of(context);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: (){
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RecipeDetail(
                  documentSnapshot: widget.documentSnapshot,
                ),
            ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 230,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: widget.documentSnapshot.id,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: NetworkImage(widget.documentSnapshot["image"]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                Text(
                  widget.documentSnapshot["name"],
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color, // Màu chữ theo theme
                  ),
                ),
                const SizedBox(height: 5,),
                Row(
                  children: [
                    const Icon(Iconsax.flash_1, size: 16, color: Colors.grey),
                    Text(
                        "${widget.documentSnapshot["cal"]} Cal",
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const Text(" | ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900)),
                    const Icon(Iconsax.clock, size: 16, color: Colors.grey),
                    const SizedBox(width: 5,),
                    Text(
                      "${widget.documentSnapshot["time"]} Min",
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 5,
              right: 5,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.cardColor.withOpacity(0.9), // Nền icon tim theo theme
                child: InkWell(
                  onTap: (){
                    final isFavorite = provider.isFavorite(widget.documentSnapshot);
                    provider.toggleFavorite(widget.documentSnapshot);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFavorite ? "Đã xóa khỏi yêu thích" : "Đã thêm vào yêu thích"),
                        backgroundColor: isFavorite ? Colors.red : Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Icon(
                    provider.isFavorite(widget.documentSnapshot) ? Iconsax.heart5 : Iconsax.heart,
                    color: provider.isFavorite(widget.documentSnapshot) ? Colors.red : theme.iconTheme.color,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
