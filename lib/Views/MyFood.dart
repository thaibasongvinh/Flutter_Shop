import 'package:flutter/material.dart';
import 'package:fodd/Provider/cart.dart';
import 'package:fodd/Widgets/cart_screen.dart';
import 'package:fodd/Widgets/favorite_screen.dart';
import 'package:fodd/Views/SettingsScreen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

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
    final myCart = Provider.of<MyCart>(context);
    int cartCount = myCart.cart.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.cardColor,
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
                icon: Badge(
                  label: Text(cartCount.toString()),
                  isLabelVisible: cartCount > 0,
                  backgroundColor: Colors.red,
                  child: Icon(_selectedIndex == 2 ? Iconsax.shopping_cart5 : Iconsax.shopping_cart),
                ),
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
