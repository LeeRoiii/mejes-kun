import 'package:flutter/material.dart';
import '../database_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int totalRooms = 0;
  int totalTenants = 0;
  double totalRentPaid = 0.0;
  double totalRentUnpaid = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    final rooms = await DatabaseHelper.instance.getAllRooms();
    final tenants = await DatabaseHelper.instance.getAllTenants();

    double rentPaid = 0.0;
    double rentUnpaid = 0.0;

    for (var tenant in tenants) {
      if (tenant.monthsPaid > 0) {
        final room = await DatabaseHelper.instance.getRoom(tenant.roomId!);
        rentPaid += room!.rent * tenant.monthsPaid;
      } else {
        final room = await DatabaseHelper.instance.getRoom(tenant.roomId!);
        rentUnpaid += room!.rent;
      }
    }

    setState(() {
      totalRooms = rooms.length;
      totalTenants = tenants.length;
      totalRentPaid = rentPaid;
      totalRentUnpaid = rentUnpaid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnalyticsSquare(
                  title: 'Total Rooms',
                  value: totalRooms.toString(),
                ),
                _buildAnalyticsSquare(
                  title: 'Total Tenants',
                  value: totalTenants.toString(),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnalyticsSquare(
                  title: 'Rent Paid',
                  value: '\$${totalRentPaid.toStringAsFixed(2)}',
                ),
                _buildAnalyticsSquare(
                  title: 'Rent Unpaid',
                  value: '\$${totalRentUnpaid.toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSquare({required String title, required String value}) {
    return Container(
      width: 150,
      height: 150,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
