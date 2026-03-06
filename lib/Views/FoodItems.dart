import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Widgets/recipe_detail.dart';
import 'package:iconsax/iconsax.dart';

import '../Utils/Constants.dart';

class FoodItems extends StatelessWidget {
  final DocumentSnapshot documentSnapshot;
  const FoodItems({super.key, required this.documentSnapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = documentSnapshot.data() as Map<String, dynamic>;
    
    // Kiểm tra trạng thái hết hàng
    final bool isAvailable = data.containsKey("isAvailable") ? data["isAvailable"] : true;

    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetail(documentSnapshot: documentSnapshot),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Xin lỗi, món ăn này hiện đã hết hàng!"), backgroundColor: Colors.red)
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        width: 180,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: documentSnapshot.id,
                  child: ColorFiltered(
                    // Nếu hết hàng thì làm mờ ảnh (Grayscale)
                    colorFilter: isAvailable 
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                        : const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ]),
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(data["image"] ?? data["picture"]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data["name"] ?? "No Name",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? theme.textTheme.bodyLarge?.color : Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Iconsax.flash_1, size: 16, color: Colors.grey),
                    Text(
                      "${data["cal"]} Cal",
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const Text(" | ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900)),
                    const Icon(Iconsax.clock, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      "${data["time"]} Min",
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            // Hiển thị nhãn "Hết hàng" nếu cần
            if (!isAvailable)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Hết hàng",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
