import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fodd/Views/FoodItems.dart';
import 'package:fodd/Widgets/shimmer_skeleton.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = "";
  String _sortBy = "Mặc định"; // Mặc định, Giá tăng, Giá giảm, Rating
  List<String> _history = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveHistory(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_history.contains(query)) {
      _history.insert(0, query);
      if (_history.length > 5) _history.removeLast();
      await prefs.setStringList('search_history', _history);
      setState(() {});
    }
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _history = [];
    });
  }

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
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            onSubmitted: (value) => _saveHistory(value.trim()),
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
      body: Column(
        children: [
          // THANH BỘ LỌC VÀ SẮP XẾP
          if (_searchQuery.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  _filterChip("Mặc định"),
                  _filterChip("Giá tăng dần"),
                  _filterChip("Giá giảm dần"),
                  _filterChip("Đánh giá cao"),
                ],
              ),
            ),

          Expanded(
            child: _searchQuery.isEmpty
                ? _buildHistory(theme)
                : _buildResults(theme),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _sortBy == label;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kprimaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildHistory(ThemeData theme) {
    if (_history.isEmpty) {
      return Center(child: Text("Type something to search!", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tìm kiếm gần đây", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(onPressed: _clearHistory, child: const Text("Xóa tất cả", style: TextStyle(color: Colors.red))),
            ],
          ),
        ),
        Wrap(
          children: _history.map((q) => GestureDetector(
            onTap: () {
              _searchController.text = q;
              setState(() => _searchQuery = q.toLowerCase());
            },
            child: Container(
              margin: const EdgeInsets.only(left: 15, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
              child: Text(q),
            ),
          )).toList(),
        )
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("sanpham").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const FoodItemSkeleton(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No items found"));

        List<DocumentSnapshot> results = snapshot.data!.docs.where((doc) {
          final name = doc["name"].toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        // XỬ LÝ SẮP XẾP
        if (_sortBy == "Giá tăng dần") {
          results.sort((a, b) => (a["price"] ?? 0).compareTo(b["price"] ?? 0));
        } else if (_sortBy == "Giá giảm dần") {
          results.sort((a, b) => (b["price"] ?? 0).compareTo(a["price"] ?? 0));
        } else if (_sortBy == "Đánh giá cao") {
          results.sort((a, b) => (b["rating"] ?? 0).compareTo(a["rating"] ?? 0));
        }

        if (results.isEmpty) return const Center(child: Text("No items found matching your search"));

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: results.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => FoodItems(documentSnapshot: results[index]),
        );
      },
    );
  }
}
