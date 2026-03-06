import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../Utils/Constants.dart';
import '../Widgets/icon_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "vi_VN");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Dashboard doanh thu", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: MyIconButton(
            icon: Icons.arrow_back_ios_new,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("orders").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final orders = snapshot.data!.docs;
          double totalRevenue = 0;
          int completedOrders = 0;
          Map<String, double> dailyRevenue = {};

          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final double orderTotal = (data["total"] ?? 0).toDouble();
            final String status = data["status"] ?? "";
            final Timestamp? timestamp = data["createdAt"];

            if (status == "Đã giao thành công") {
              totalRevenue += orderTotal;
              completedOrders++;

              if (timestamp != null) {
                String date = DateFormat('dd/MM').format(timestamp.toDate());
                dailyRevenue[date] = (dailyRevenue[date] ?? 0) + orderTotal;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ tổng quan
                Row(
                  children: [
                    _buildStatCard(
                      "Tổng doanh thu",
                      "${currencyFormat.format(totalRevenue)} đ",
                      Iconsax.money_send,
                      Colors.green,
                      theme,
                    ),
                    const SizedBox(width: 15),
                    _buildStatCard(
                      "Đơn thành công",
                      completedOrders.toString(),
                      Iconsax.box_tick,
                      Colors.orange,
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text("Biểu đồ doanh thu gần đây", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // Biểu đồ
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final dates = dailyRevenue.keys.toList();
                              if (value.toInt() < dates.length) {
                                return Text(dates[value.toInt()], style: const TextStyle(fontSize: 10));
                              }
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailyRevenue.values.toList().asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          }).toList(),
                          isCurved: true,
                          color: kprimaryColor,
                          barWidth: 4,
                          belowBarData: BarAreaData(show: true, color: kprimaryColor.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
