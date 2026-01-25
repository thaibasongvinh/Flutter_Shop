import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final notificationRef = FirebaseFirestore.instance
        .collection("user_profile")
        .doc(user?.uid)
        .collection("notifications");

    return Scaffold(
      // Sử dụng màu nền của hệ thống
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Thông báo", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Theme.of(context).textTheme.bodyLarge?.color // Tự đổi màu chữ tiêu đề
          )
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationRef.orderBy("createdAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bạn chưa có thông báo nào"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var notifyDoc = snapshot.data!.docs[index];
              final data = notifyDoc.data() as Map<String, dynamic>;
              
              final bool isRead = data.containsKey("isRead") ? data["isRead"] : false;
              final String type = data.containsKey("type") ? data["type"] : "system";
              final String title = data.containsKey("title") ? data["title"] : "Thông báo";
              final String body = data.containsKey("body") ? data["body"] : "";

              return GestureDetector(
                onTap: () async {
                  await notifyDoc.reference.update({"isRead": true});
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    // Sử dụng màu Card của hệ thống
                    color: isRead ? Theme.of(context).cardColor : kprimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: isRead ? null : Border.all(color: kprimaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.grey.withOpacity(0.2) : kprimaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          type == "order" ? Iconsax.shopping_bag : Iconsax.notification,
                          color: isRead ? Colors.grey : kprimaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              body, 
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), 
                                fontSize: 14
                              )
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(data["createdAt"]), 
                              style: const TextStyle(color: Colors.grey, fontSize: 11)
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        const CircleAvatar(radius: 4, backgroundColor: Colors.red),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime date = (timestamp as Timestamp).toDate();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute - ${date.day}/${date.month}/${date.year}";
  }
}
