import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Provider/cart.dart';
import 'package:fodd/Utils/Constants.dart';
import 'package:fodd/Widgets/quantity_increment.dart';
import 'package:fodd/Views/NotificationScreen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../Provider/favorite.dart';
import '../Provider/quantity.dart';
import 'icon_button.dart';

class RecipeDetail extends StatefulWidget {
  final DocumentSnapshot<Object?> documentSnapshot;
  const RecipeDetail({super.key, required this.documentSnapshot});

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  @override
  void initState() {
    List<double> baseAmounts = widget.documentSnapshot['imgamout']
        .map<double>((amount) => double.parse(amount.toString()))
        .toList();
    Provider.of<MyQuantity>(context, listen: false).setInitialIngredientAmounts(baseAmounts);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final providerCart = MyCart.of(context);
    final providerFavorite = MyFavorite.of(context);
    final quantityProvider = Provider.of<MyQuantity>(context);
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Đồng bộ màu nền
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat ,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kbBannerColor,
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                if (providerCart.isInCart(widget.documentSnapshot.id)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Sản phẩm này đã có trong giỏ hàng rồi!"),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  providerCart.addToCart(widget.documentSnapshot, quantityProvider.currentNumber);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Đã thêm vào giỏ hàng thành công!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Add to cart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: (){},
                child: const Text("Start cooking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(
                shape: const CircleBorder(side: BorderSide(color: Colors.grey, width: 1)),
                backgroundColor: theme.cardColor, // Đồng bộ màu nút tim
              ),
                onPressed: (){
                  final isFavorite = providerFavorite.isFavorite(widget.documentSnapshot);
                  providerFavorite.toggleFavorite(widget.documentSnapshot);
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                      content: Text(isFavorite ? "Đã xóa khỏi danh sách yêu thích" : "Sản phẩm đã được thêm vào yêu thích!"),
                      backgroundColor: isFavorite ? Colors.red : Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(
                  providerFavorite.isFavorite(widget.documentSnapshot) ? Iconsax.heart5: Iconsax.heart,
                  color: providerFavorite.isFavorite(widget.documentSnapshot) ? Colors.red : theme.iconTheme.color,
                )
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: widget.documentSnapshot.id,
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height/2.1,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(widget.documentSnapshot.get("image")),
                          fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      MyIconButton(
                      icon: Icons.arrow_back_ios_new,
                        onPressed: () => Navigator.pop(context),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Center(
              child: Container(
                width: 40, height: 8,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.documentSnapshot.get("name"),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      const Icon(Iconsax.flash_1, size: 20, color: Colors.grey),
                      Text("${widget.documentSnapshot["cal"]} Cal", style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const Text(" | ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900)),
                      const Icon(Iconsax.clock, size: 20, color: Colors.grey),
                      const SizedBox(width: 5,),
                      Text("${widget.documentSnapshot["time"]} Min", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      const Icon(Iconsax.star1, color: Colors.amberAccent),
                      const SizedBox(width: 5,),
                      Text(widget.documentSnapshot["rating"].toString(), style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                      const Text("/5"),
                      const SizedBox(width: 5,),
                      Text("(${widget.documentSnapshot["review"]} Reviews)", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Ingredients", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                          const SizedBox(height: 10,),
                          const Text("How many servings?", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14)),
                        ],
                      ),
                      const Spacer(),
                      QuantityIncrement(
                        currentNumber: quantityProvider.currentNumber,
                        onAdd: () => quantityProvider.increaseQuantity(),
                        onRemove: () => quantityProvider.decreaseQuantity(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            children: widget.documentSnapshot["imgct"]
                                .map<Widget>((imageUrl) => Container(
                                      height: 60, width: 60,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                                      ),
                                    )).toList(),
                          ),
                          const SizedBox(width: 20,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.documentSnapshot["imgname"]
                                .map<Widget>((ingredientName) =>SizedBox(
                                    height: 70,
                                    child: Center(child: Text(ingredientName, style: const TextStyle(fontSize: 16, color: Colors.grey))),
                                  )).toList(),
                          ),
                          const Spacer(),
                          Column(
                            children: quantityProvider.updateIngredientAmounts()
                                .map<Widget>((amount) =>SizedBox(
                                  height: 70,
                                  child: Center(child: Text("${amount}g", style: const TextStyle(fontSize: 16, color: Colors.grey))),
                              )).toList(),
                          ),
                          const SizedBox(width: 20,),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40,), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
