import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _minOrderController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _addVoucher() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin và chọn ngày hết hạn!")));
      return;
    }

    await FirebaseFirestore.instance.collection("vouchers").add({
      "code": _codeController.text.trim().toUpperCase(),
      "discount": double.parse(_discountController.text),
      "minOrder": double.parse(_minOrderController.text),
      "expiryDate": Timestamp.fromDate(_selectedDate!),
      "createdAt": FieldValue.serverTimestamp(),
    });

    _codeController.clear();
    _discountController.clear();
    _minOrderController.clear();
    setState(() => _selectedDate = null);
    if (mounted) Navigator.pop(context);
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tạo Voucher mới"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: "Mã giảm giá (VD: GIAM50K)"),
                    validator: (v) => v!.isEmpty ? "Không được để trống" : null,
                  ),
                  TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Số tiền giảm (VNĐ)"),
                    validator: (v) => v!.isEmpty ? "Trống" : null,
                  ),
                  TextFormField(
                    controller: _minOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Đơn tối thiểu (VNĐ)"),
                    validator: (v) => v!.isEmpty ? "Trống" : null,
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_selectedDate == null ? "Chọn ngày hết hạn" : "HSD: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}"),
                    trailing: const Icon(Iconsax.calendar),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setDialogState(() => _selectedDate = picked);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(onPressed: _addVoucher, child: const Text("Tạo mã")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Quản lý Voucher"),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(icon: Icons.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kprimaryColor,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("vouchers").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final vouchers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: vouchers.length,
            itemBuilder: (context, index) {
              final data = vouchers[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Iconsax.ticket_discount, color: kprimaryColor, size: 30),
                  title: Text(data["code"], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Giảm ${currencyFormat.format(data["discount"])}đ - Đơn từ ${currencyFormat.format(data["minOrder"])}đ"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => vouchers[index].reference.delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
