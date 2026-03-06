import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Provider/cart.dart';
import 'package:fodd/Utils/Constants.dart';
import 'package:fodd/Widgets/quantity_increment.dart';
import 'package:fodd/Views/NotificationScreen.dart';
import 'package:fodd/Views/ReviewScreen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../Provider/favorite.dart';
import '../Provider/quantity.dart';
import 'icon_button.dart';
import 'cart_screen.dart'; // Import để chuyển hướng

class RecipeDetail extends StatefulWidget {
  final DocumentSnapshot<Object?> documentSnapshot;
  const RecipeDetail({super.key, required this.documentSnapshot});

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  String _selectedSize = "Vừa";
  final List<String> _selectedToppings = [];

  final Map<String, double> _sizePrices = {"Nhỏ": 0, "Vừa": 10000, "Lớn": 20000};
  final Map<String, double> _toppingPrices = {"Thêm phô mai": 5000, "Thêm trứng": 7000, "Thêm xúc xích": 10000};

  @override
  void initState() {
    List<double> baseAmounts = widget.documentSnapshot['imgamout']
        .map<double>((amount) => double.parse(amount.toString()))
        .toList();
    Provider.of<MyQuantity>(context, listen: false).setInitialIngredientAmounts(baseAmounts);
    super.initState();
  }

  double _calculateCurrentItemPrice() {
    double base = (widget.documentSnapshot["price"] ?? 0).toDouble();
    double sizeExtra = _sizePrices[_selectedSize] ?? 0;
    double toppingExtra = 0;
    for (var t in _selectedToppings) {
      toppingExtra += _toppingPrices[t] ?? 0;
    }
    return base + sizeExtra + toppingExtra;
  }

  @override
  Widget build(BuildContext context) {
    final providerCart = MyCart.of(context);
    final providerFavorite = MyFavorite.of(context);
    final quantityProvider = Provider.of<MyQuantity>(context);
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    double itemPrice = _calculateCurrentItemPrice();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tổng cộng", style: TextStyle(color: Colors.grey)),
                      Text("${(itemPrice * quantityProvider.currentNumber).toStringAsFixed(0)} đ",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kprimaryColor)),
                    ],
                  ),
                ),
                // NÚT THÊM VÀO GIỎ
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      providerCart.addToCart(
                        product: widget.documentSnapshot,
                        quantity: quantityProvider.currentNumber,
                        size: _selectedSize,
                        toppings: _selectedToppings,
                        itemTotalPrice: itemPrice,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm vào giỏ hàng!"), backgroundColor: Colors.green));
                    },
                    child: const Text("Thêm giỏ hàng", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                // NÚT MUA NGAY
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kprimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () async {
                      await providerCart.addToCart(
                        product: widget.documentSnapshot,
                        quantity: quantityProvider.currentNumber,
                        size: _selectedSize,
                        toppings: _selectedToppings,
                        itemTotalPrice: itemPrice,
                      );
                      if (context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                      }
                    },
                    child: const Text("Mua ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
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
                      image: DecorationImage(image: NetworkImage(widget.documentSnapshot.get("image")), fit: BoxFit.cover),
                    ),
                  ),
                ),
                Positioned(
                  top: 40, left: 10, right: 10,
                  child: Row(
                    children: [
                      MyIconButton(icon: Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
                      const Spacer(),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.documentSnapshot.get("name"), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color))),
                      IconButton(
                          onPressed: (){
                            final isFavorite = providerFavorite.isFavorite(widget.documentSnapshot);
                            providerFavorite.toggleFavorite(widget.documentSnapshot);
                          },
                          icon: Icon(
                            providerFavorite.isFavorite(widget.documentSnapshot) ? Iconsax.heart5: Iconsax.heart,
                            color: providerFavorite.isFavorite(widget.documentSnapshot) ? Colors.red : theme.iconTheme.color,
                          )
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Iconsax.flash_1, size: 20, color: Colors.grey),
                      Text("${widget.documentSnapshot["cal"]} Cal", style: const TextStyle(color: Colors.grey)),
                      const Text(" | "),
                      const Icon(Iconsax.clock, size: 20, color: Colors.grey),
                      Text("${widget.documentSnapshot["time"]} Min", style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      const Icon(Iconsax.star1, color: Colors.amberAccent, size: 20),
                      Text(" ${widget.documentSnapshot["rating"]} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("(${widget.documentSnapshot["review"]})", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),

                  const SizedBox(height: 25),
                  const Text("Chọn Size", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: _sizePrices.keys.map((size) {
                      bool isSelected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = size),
                        child: Container(
                          margin: const EdgeInsets.only(right: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? kprimaryColor : theme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? kprimaryColor : Colors.grey.shade300),
                          ),
                          child: Text(size, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 25),
                  const Text("Thêm Topping", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  ..._toppingPrices.keys.map((topping) {
                    bool isSelected = _selectedToppings.contains(topping);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(topping, style: const TextStyle(fontSize: 15)),
                      subtitle: Text("+ ${_toppingPrices[topping]}đ", style: const TextStyle(color: Colors.grey)),
                      value: isSelected,
                      activeColor: kprimaryColor,
                      onChanged: (val) {
                        setState(() {
                          if (val!) { _selectedToppings.add(topping); }
                          else { _selectedToppings.remove(topping); }
                        });
                      },
                    );
                  }).toList(),

                  const SizedBox(height: 25),
                  Row(
                    children: [
                      const Text("Nguyên liệu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      QuantityIncrement(
                        currentNumber: quantityProvider.currentNumber,
                        onAdd: () => quantityProvider.increaseQuantity(),
                        onRemove: () => quantityProvider.decreaseQuantity(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: (widget.documentSnapshot["imgct"] as List).map((url) => Container(
                          height: 60, width: 60, margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)),
                        )).toList(),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (widget.documentSnapshot["imgname"] as List).map((name) => SizedBox(
                            height: 70, child: Text(name, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                          )).toList(),
                        ),
                      ),
                      Column(
                        children: quantityProvider.updateIngredientAmounts().map((amount) => SizedBox(
                          height: 70, child: Text("${amount}g", style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                        )).toList(),
                      ),
                    ],
                  ),

                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Đánh giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ReviewScreen(productId: widget.documentSnapshot.id, productName: widget.documentSnapshot["name"]))),
                        child: const Text("Viết đánh giá", style: TextStyle(color: kprimaryColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection("reviews").where("productId", isEqualTo: widget.documentSnapshot.id).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("Chưa có bình luận nào.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length > 3 ? 3 : docs.length,
                          itemBuilder: (context, index) {
                            var review = docs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(review["userName"] ?? "Ẩn danh", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Row(children: List.generate(review["rating"] ?? 5, (i) => const Icon(Iconsax.star1, color: Colors.amber, size: 12))),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(review["comment"] ?? "", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        );
                      }
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}