import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Đăng ký bằng Email & Password
  Future<User?> signUp(String email, String password, String fullName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        await result.user!.sendEmailVerification();
        // Cập nhật tên vào Firebase Auth Profile
        await result.user!.updateDisplayName(fullName);
        
        await _firestore.collection("user_profile").doc(result.user!.uid).set({
          "email": email,
          "name": fullName,
          "profilePic": "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final docRef = _firestore.collection("user_profile").doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            "email": user.email,
            "name": user.displayName ?? "Người dùng Google",
            "profilePic": user.photoURL ?? "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
            "createdAt": FieldValue.serverTimestamp(),
          });
        }
      }
      return user;
    } catch (e) {
      print("Lỗi đăng nhập Google: $e");
      return null;
    }
  }

  // Cập nhật mật khẩu
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    }
  }

  // Xóa tài khoản
  Future<void> deleteUserAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("Không tìm thấy người dùng.");
    }
    
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await _firestore.collection("user_profile").doc(user.uid).delete();
    await user.delete();
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      if (result.user != null) {
        await result.user!.reload();
        User? refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
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
    await _googleSignIn.signOut();
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
}
