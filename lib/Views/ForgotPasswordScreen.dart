import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Utils/auth_service.dart';
import 'package:fodd/Widgets/icon_button.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  void _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Vui lòng nhập Email của bạn", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("user_profile")
          .where("email", isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() => _isLoading = false);
        _showSnackBar("Email này chưa được đăng ký!", Colors.red);
        return;
      }

      bool success = await _authService.sendPasswordResetEmail(email);
      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          _showSnackBar("Link đặt lại mật khẩu đã được gửi!", Colors.green);
          Navigator.pop(context);
        }
      } else {
        if (mounted) _showSnackBar("Có lỗi xảy ra, vui lòng thử lại sau.", Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Lỗi kết nối. Vui lòng thử lại.", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Đồng bộ màu nền
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(
            icon: Icons.arrow_back_ios_new, 
            onPressed: () => Navigator.pop(context)
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Iconsax.key_square, size: 80, color: kprimaryColor),
            const SizedBox(height: 30),
            Text(
              "Quên mật khẩu?",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 10),
            Text(
              "Nhập email của bạn để nhận liên kết đặt lại mật khẩu mới.",
              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 16),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: "Nhập Email",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Iconsax.sms, color: Colors.grey),
                filled: true,
                fillColor: theme.cardColor, // Đồng bộ màu ô nhập liệu
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Gửi yêu cầu", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
