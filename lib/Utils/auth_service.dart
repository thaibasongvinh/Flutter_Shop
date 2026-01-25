import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng ký và gửi link xác nhận - Thêm fullName
  Future<User?> signUp(String email, String password, String fullName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        await result.user!.sendEmailVerification();
        // Lưu fullName vào Firestore
        await _firestore.collection("user_profile").doc(result.user!.uid).set({
          "email": email,
          "name": fullName, // Lưu tên đầy đủ
          "profilePic": "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
          "createdAt": DateTime.now(),
        });
      }
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Đăng nhập và ép buộc tải lại trạng thái xác thực
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        // Ép buộc cập nhật trạng thái từ Server Google
        await result.user!.reload();
        User? refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          // Nếu chưa xác thực thì đăng xuất và báo lỗi cụ thể
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Email chưa được xác thực'
          );
        }
        return refreshedUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // Hàm gửi lại link xác thực (phòng trường hợp thất lạc mail)
  Future<void> resendVerificationEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await result.user!.sendEmailVerification();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Kiểm tra email (dùng cho Quên mật khẩu)
  Future<bool> isEmailRegistered(String email) async {
    try {
      final list = await _auth.fetchSignInMethodsForEmail(email);
      return list.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
