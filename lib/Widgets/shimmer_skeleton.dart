import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 15,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class FoodItemSkeleton extends StatelessWidget {
  const FoodItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 15),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton(height: 150, width: 180),
          SizedBox(height: 10),
          ShimmerSkeleton(height: 20, width: 120),
          SizedBox(height: 5),
          ShimmerSkeleton(height: 15, width: 80),
        ],
      ),
    );
  }
}

class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 15),
      child: ShimmerSkeleton(height: 40, width: 100, borderRadius: 25),
    );
  }
}

class OrderSkeleton extends StatelessWidget {
  const OrderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerSkeleton(height: 15, width: 100),
              ShimmerSkeleton(height: 25, width: 80, borderRadius: 10),
            ],
          ),
          SizedBox(height: 15),
          ShimmerSkeleton(height: 15, width: 150),
          SizedBox(height: 5),
          ShimmerSkeleton(height: 15, width: 120),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerSkeleton(height: 15, width: 80),
              ShimmerSkeleton(height: 20, width: 100),
            ],
          ),
        ],
      ),
    );
  }
}
