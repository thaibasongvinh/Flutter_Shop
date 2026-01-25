import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Provider/cart.dart';
import 'package:fodd/Provider/theme_provider.dart'; // Import mới
import 'package:fodd/Views/LoginScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'Provider/favorite.dart';
import 'Provider/quantity.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await updatePrices();

  runApp(const MyApp());
}

Future<void> updatePrices() async {
  try {
    var collection = FirebaseFirestore.instance.collection('sanpham');
    var querySnapshots = await collection.get();
    for (var doc in querySnapshots.docs) {
      final data = doc.data();
      if (data['price'] == null) {
        await doc.reference.update({'price': 50000});
      }
    }
  } catch (e) {
    print("Lỗi cập nhật giá: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()), // Thêm ThemeProvider
          ChangeNotifierProvider(create: (_) => MyFavorite()),
          ChangeNotifierProvider(create: (_) => MyQuantity()),
          ChangeNotifierProvider(create: (_) => MyCart()),
        ],
        child: Consumer<ThemeProvider>( // Sử dụng Consumer để lắng nghe thay đổi Theme
          builder: (context, themeProvider, child) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: themeProvider.lightTheme,
                darkTheme: themeProvider.darkTheme,
                themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                home: const LoginScreen(),
            );
          },
        )
    );
  }
}
