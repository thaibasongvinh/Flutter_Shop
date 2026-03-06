import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Provider/theme_provider.dart';
import 'package:fodd/Utils/auth_service.dart';
import 'package:fodd/Views/AdminOrderScreen.dart';
import 'package:fodd/Views/AdminDashboardScreen.dart';
import 'package:fodd/Views/AdminProductScreen.dart';
import 'package:fodd/Views/AdminVoucherScreen.dart';
import 'package:fodd/Views/AdminBannerScreen.dart';
import 'package:fodd/Views/AdminCategoryScreen.dart';
import 'package:fodd/Views/AddressScreen.dart';
import 'package:fodd/Views/EditProfileScreen.dart';
import 'package:fodd/Views/LoginScreen.dart';
import 'package:fodd/Views/OrderHistoryScreen.dart';
import 'package:fodd/Views/VoucherScreen.dart'; 
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
                GestureDetector(
                  onLongPress: () => _showAdminOptions(context),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(profilePic),
                  ),
                ),
                const SizedBox(height: 15),
                Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),
                
                _buildSettingsTile(
                  context,
                  icon: themeProvider.isDarkMode ? Iconsax.moon : Iconsax.sun_1, 
                  title: "Chế độ tối", 
                  subtitle: themeProvider.isDarkMode ? "Đang bật" : "Đang tắt",
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                    activeColor: kprimaryColor,
                  ),
                  onTap: () => themeProvider.toggleTheme()
                ),

                _buildSettingsTile(
                  context,
                  icon: Iconsax.box, 
                  title: "Lịch sử đơn hàng", 
                  subtitle: "Xem lại các món bạn đã đặt",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const OrderHistoryScreen()));
                  }
                ),
                _buildSettingsTile(
                  context,
                  icon: Iconsax.user, 
                  title: "Hồ sơ cá nhân", 
                  subtitle: "Chỉnh sửa thông tin & SĐT",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(currentName: name)));
                  }
                ),
                _buildSettingsTile(
                  context,
                  icon: Iconsax.location, 
                  title: "Địa chỉ nhận hàng", 
                  subtitle: "Quản lý các địa chỉ đã lưu",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const AddressScreen()));
                  }
                ),
                _buildSettingsTile(
                  context,
                  icon: Iconsax.ticket_discount, 
                  title: "Kho Voucher", 
                  subtitle: "Các mã giảm giá đang có",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const VoucherScreen()));
                  }
                ),
                _buildSettingsTile(
                  context,
                  icon: Iconsax.key, 
                  title: "Đổi mật khẩu", 
                  subtitle: "Thay đổi mật khẩu trực tiếp",
                  onTap: () => _showChangePasswordDialog(context),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Align(alignment: Alignment.centerLeft, child: Text("Hỗ trợ khách hàng", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                ),

                _buildSettingsTile(
                  context,
                  icon: Iconsax.call, 
                  title: "Hotline hỗ trợ", 
                  subtitle: "0123.456.789",
                  onTap: () => _launchUrl('tel:0123456789'),
                ),
                _buildSettingsTile(
                  context,
                  icon: Iconsax.message_2, 
                  title: "Chat với chúng tôi", 
                  subtitle: "Hỗ trợ qua Messenger/Zalo",
                  onTap: () => _launchUrl('https://m.me/yourpage'), 
                ),
                
                const SizedBox(height: 20),
                
                ListTile(
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Iconsax.logout, color: Colors.blue),
                  title: const Text("Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _showLogoutDialog(context),
                ),
                
                const SizedBox(height: 10),

                ListTile(
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  leading: const Icon(Iconsax.user_remove, color: Colors.red),
                  title: const Text("Xóa tài khoản", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => _showDeleteAccountDialog(context),
                ),

                const SizedBox(height: 30),
                const Text("FODD App v1.0.2", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Text("© 2024 - Design by Thai Ba Song Vinh", style: TextStyle(color: Colors.grey, fontSize: 10)),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAdminOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Chế độ Quản trị", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Iconsax.status, color: Colors.orange),
                title: const Text("Quản lý đơn hàng"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminOrderScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.box, color: Colors.blue),
                title: const Text("Quản lý sản phẩm"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminProductScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.category, color: Colors.cyan),
                title: const Text("Quản lý danh mục"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminCategoryScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.image, color: Colors.pink),
                title: const Text("Quản lý Banner"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminBannerScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.ticket_discount, color: Colors.purple),
                title: const Text("Quản lý Voucher"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminVoucherScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.graph, color: Colors.green),
                title: const Text("Thống kê doanh thu"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminDashboardScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Đổi mật khẩu mới"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mật khẩu hiện tại", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mật khẩu mới", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Xác nhận mật khẩu mới", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                String oldP = oldPassController.text.trim();
                String newP = newPassController.text.trim();
                String confirmP = confirmPassController.text.trim();

                if (oldP.isEmpty || newP.isEmpty || confirmP.isEmpty) return;
                if (newP != confirmP) return;
                if (oldP == newP) return;

                setDialogState(() => isLoading = true);
                try {
                  await AuthService().updatePassword(oldP, newP);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đổi mật khẩu thành công!"), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu hiện tại sai!"), backgroundColor: Colors.red));
                  }
                }
                setDialogState(() => isLoading = false);
              },
              child: const Text("Cập nhật"),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              }
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  // --- LOGIC XÓA TÀI KHOẢN THÔNG MINH ---
  void _showDeleteAccountDialog(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    // Kiểm tra xem user đăng nhập bằng Google hay Email
    bool isGoogleUser = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    if (isGoogleUser) {
      // Nếu là user Google: Chỉ cần xác nhận, không cần mật khẩu
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Xác nhận xóa tài khoản", style: TextStyle(color: Colors.red)),
          content: const Text("Tài khoản Google của bạn sẽ được gỡ khỏi hệ thống. Mọi dữ liệu sẽ bị xóa vĩnh viễn."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection("user_profile").doc(user?.uid).delete();
                await user?.delete();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
                }
              },
              child: const Text("Xác nhận xóa", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      // Nếu là user Email: Bắt buộc nhập mật khẩu để Re-auth
      final TextEditingController passController = TextEditingController();
      bool isLoading = false;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Xác nhận xóa tài khoản", style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Vì lý do bảo mật, vui lòng nhập mật khẩu để xác nhận xóa vĩnh viễn tài khoản này."),
                const SizedBox(height: 15),
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isLoading ? null : () async {
                  if (passController.text.isEmpty) return;
                  setDialogState(() => isLoading = true);
                  try {
                    await AuthService().deleteUserAccount(passController.text.trim());
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu sai!"), backgroundColor: Colors.red));
                    }
                  }
                  setDialogState(() => isLoading = false);
                },
                child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Xác nhận xóa", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint("Lỗi gọi link: $e");
    }
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, required String subtitle, Widget? trailing, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(icon, color: kprimaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}
