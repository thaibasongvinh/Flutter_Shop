import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Utils/Constants.dart';

class MyBanner extends StatelessWidget {
  const MyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("banners").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Hiển thị Banner mặc định nếu Firebase trống
          return _buildBanner(
            "Đang tải khuyến mãi...",
            "Khám phá ngay các món ăn hấp dẫn nhất tuần này!",
            "https://pngimg.com/d/chef_PNG190.png",
          );
        }

        // Lấy banner đầu tiên từ Firebase
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return _buildBanner(
          data["title"] ?? "Ưu đãi đặc biệt",
          data["subtitle"] ?? "Giảm giá cực sốc hôm nay!",
          data["image"] ?? "https://pngimg.com/d/chef_PNG190.png",
        );
      },
    );
  }

  Widget _buildBanner(String title, String subtitle, String imageUrl) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: kbBannerColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 25,
            left: 20,
            right: 120, // Chừa chỗ cho ảnh
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Xem ngay",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: -10,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.white, size: 50),
            ),
          ),
        ],
      ),
    );
  }
}
