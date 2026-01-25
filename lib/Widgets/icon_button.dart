import 'package:flutter/material.dart';

class MyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const MyIconButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: theme.cardColor, // Sử dụng màu card của theme (trắng ở light, xám đen ở dark)
        fixedSize: const Size(50, 50),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: theme.iconTheme.color), // Sử dụng màu icon của theme
    );
  }
}
