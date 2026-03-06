import 'package:flutter/material.dart';
import 'package:fodd/Views/OnboardingScreen.dart';
import 'package:fodd/Views/MyFood.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Utils/Constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    // Kiểm tra nếu người dùng đã đăng nhập trước đó
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MyFood()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const OnboardingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Thay đổi bằng Logo của bạn
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kprimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fastfood, size: 100, color: kprimaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              "FODD App",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kprimaryColor,
                letterSpacing: 2
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: kprimaryColor),
          ],
        ),
      ),
    );
  }
}
