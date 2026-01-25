import 'package:flutter/material.dart';
import 'package:fodd/Widgets/cart_screen.dart';
import 'package:fodd/Widgets/favorite_screen.dart';
import 'package:fodd/Views/SettingsScreen.dart';
import 'package:iconsax/iconsax.dart';

import '../Utils/Constants.dart';
import 'FoodDetail.dart';

class MyFood extends StatefulWidget{
  const MyFood({super.key});
  @override
  State<MyFood> createState() => _MyFoodState();
}

class _MyFoodState extends State<MyFood> {
  int _selectedIndex = 0;
  void _onItemTapped(index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  late final List<Widget> _pages;
  @override
  void initState() {
    _pages = [
      const FoodDetail(),
      const FavoriteScreen(),
      const CartScreen(),
      const SettingsScreen(),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Tự đổi theo theme
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.cardColor, // Đổi màu nền thanh điều hướng
          elevation: 0,
          iconSize: 28,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: kprimaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(color: kprimaryColor, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14,fontWeight: FontWeight.w500),
          items: [
            BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 0 ? Iconsax.home5 : Iconsax.home4),
                label: 'Home'
            ),
            BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 1 ? Iconsax.heart5 : Iconsax.heart4),
                label: 'Favorite'
            ),
            BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 2 ? Iconsax.shop_add5 : Iconsax.shop_add4),
                label: 'Cart'
            ),
            BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 3 ? Iconsax.setting_21 : Iconsax.setting_2),
                label: 'Setting'
            ),
          ]
      ),
      body: _pages[_selectedIndex],
    );
  }
}
