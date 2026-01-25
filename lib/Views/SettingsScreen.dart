import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Provider/theme_provider.dart'; // Import mới
import 'package:fodd/Utils/auth_service.dart';
import 'package:fodd/Views/LoginScreen.dart';
import 'package:fodd/Views/OrderHistoryScreen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../Utils/Constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String uid = currentUser?.uid ?? "";
    final themeProvider = Provider.of<ThemeProvider>(context);

    final DocumentReference userDoc = FirebaseFirestore.instance.collection("user_profile").doc(uid);

    return Scaffold(
      // backgroundColor tự động thay đổi theo theme
      appBar: AppBar(
        title: const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          String name = "Người dùng";
          String email = currentUser?.email ?? "Chưa cập nhật";
          String profilePic = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data["name"] ?? name;
            profilePic = data["profilePic"] ?? profilePic;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(profilePic),
                ),
                const SizedBox(height: 15),
                Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                // NÚT CHUYỂN CHẾ ĐỘ TỐI/SÁNG
                _buildSettingsTile(
                  icon: themeProvider.isDarkMode ? Iconsax.moon : Iconsax.sun_1, 
                  title: "Chế độ tối", 
                  subtitle: themeProvider.isDarkMode ? "Đang bật" : "Đang tắt",
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    activeColor: kprimaryColor,
                  ),
                  onTap: () {
                    themeProvider.toggleTheme();
                  }
                ),

                _buildSettingsTile(
                  icon: Iconsax.box, 
                  title: "Lịch sử đơn hàng", 
                  subtitle: "Xem lại các đơn đã đặt",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const OrderHistoryScreen()));
                  }
                ),
                _buildSettingsTile(
                  icon: Iconsax.user, 
                  title: "Tài khoản", 
                  subtitle: "Quản lý thông tin cá nhân",
                  onTap: () {}
                ),
                _buildSettingsTile(
                  icon: Iconsax.notification, 
                  title: "Thông báo", 
                  subtitle: "Cài đặt âm báo",
                  onTap: () {}
                ),
                const SizedBox(height: 20),
                
                ListTile(
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Iconsax.logout, color: Colors.red),
                  title: const Text("Đăng xuất", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Đăng xuất"),
                        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                          TextButton(
                            onPressed: () async {
                              await AuthService().signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, Widget? trailing, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: BoxShape.circle == null ? Colors.white : null, // Placeholder để tránh lỗi logic trước đó
        borderRadius: BorderRadius.circular(15),
      ),
      child: Builder(
        builder: (context) {
          return ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            leading: Icon(icon, color: kprimaryColor),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onTap,
          );
        }
      ),
    );
  }
}
