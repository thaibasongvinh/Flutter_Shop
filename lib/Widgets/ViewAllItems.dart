import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Views/FoodItems.dart';
import 'package:fodd/Widgets/icon_button.dart';
import 'package:iconsax/iconsax.dart';

import '../Utils/Constants.dart';

class ViewAllItems extends StatefulWidget {
  const ViewAllItems({super.key});

  @override
  State<ViewAllItems> createState() => _ViewAllItemsState();
}

class _ViewAllItemsState extends State<ViewAllItems> {
  final CollectionReference completeApp = FirebaseFirestore.instance.collection("sanpham");
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Đồng bộ màu nền
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Trong suốt để thấy màu nền Scaffold
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          const SizedBox(width: 15,),
          MyIconButton(
              icon: Icons.arrow_back_ios_new,
              onPressed: (){
                Navigator.pop(context);
              },
          ),
          const Spacer(),
          Text(
              "Quik & Easy",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color, // Màu chữ theo theme
            ),
          ),
          const Spacer(),
          MyIconButton(
            icon: Iconsax.notification,
            onPressed: (){},
          ),
          const SizedBox(width: 15,),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 15, right: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10,),
            StreamBuilder(
              stream: completeApp.snapshots(),
              builder: (context,AsyncSnapshot<QuerySnapshot> streamSnapshot){
                if(streamSnapshot.hasData){
                  return GridView.builder(
                      itemCount: streamSnapshot.data!.docs.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65, // Chỉnh lại tỉ lệ để không bị đè chữ
                      ),
                      itemBuilder: (context, index){
                        final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                        return Column(
                          children: [
                            FoodItems(
                                documentSnapshot: documentSnapshot,
                            ),
                            const SizedBox(height: 5,),
                            Row(
                              children: [
                                const Icon(Iconsax.star1, color: Colors.amberAccent, size: 18),
                                const SizedBox(width: 5,),
                                Text(
                                  documentSnapshot["rating"].toString(),
                                  style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                                ),
                                Text("/5", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                                const SizedBox(width: 5,),
                                Expanded(
                                  child: Text(
                                    "(${documentSnapshot["review"]} Reviews)",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      }
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }
}
