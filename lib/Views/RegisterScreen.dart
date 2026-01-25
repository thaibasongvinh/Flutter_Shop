import 'package:flutter/material.dart';
import 'package:fodd/Utils/auth_service.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _register() async {
    String fullName = _fullNameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin", Colors.orange);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Mật khẩu phải có ít nhất 6 ký tự", Colors.orange);
      return;
    }

    if (password != _confirmPasswordController.text) {
      _showSnackBar("Mật khẩu xác nhận không khớp!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signUp(email, password, fullName);

      if (user != null) {
        await _authService.signOut();
        setState(() => _isLoading = false);
        if (mounted) {
          _showSnackBar(
            "Link xác thực đã được gửi tới Email của bạn. Vui lòng nhấn vào link trong Gmail trước khi đăng nhập!", 
            Colors.green
          );
          Navigator.pop(context);
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackBar("Đăng ký thất bại. Email này có thể đã tồn tại.", Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Lỗi: ${e.toString()}", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.user_add, size: 80, color: kprimaryColor),
              const SizedBox(height: 20),
              Text(
                "Tạo tài khoản mới",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 10),
              Text(
                "Đăng ký để nhận link xác thực qua Gmail",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
              ),
              const SizedBox(height: 30),
              
              TextField(
                controller: _fullNameController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Tên đầy đủ của bạn",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Iconsax.user, color: Colors.grey),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Email của bạn",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Iconsax.sms, color: Colors.grey),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Mật khẩu (tối thiểu 6 ký tự)",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Iconsax.key, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "Xác nhận mật khẩu",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Iconsax.key, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Đăng ký & Gửi link xác thực",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
