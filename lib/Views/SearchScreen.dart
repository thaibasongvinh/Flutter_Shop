import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Views/FoodItems.dart';
import 'package:iconsax/iconsax.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            autofocus: true,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: const InputDecoration(
              hintText: "Search for food...",
              prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? Center(child: Text("Type something to search!", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("sanpham").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No items found"));
                }

                final results = snapshot.data!.docs.where((doc) {
                  final name = doc["name"].toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (results.isEmpty) {
                  return const Center(child: Text("No items found matching your search"));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: results.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return FoodItems(documentSnapshot: results[index]);
                  },
                );
              },
            ),
    );
  }
}
