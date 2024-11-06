import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../models/tenant.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int totalRooms = 0;
  int totalTenants = 0;
  double totalRentPaid = 0.0;
  double totalRentUnpaid = 0.0;
  int tenantsNotPaid = 0;
  int tenantsPaid = 0;
  List<Tenant> paidTenants = [];
  List<Tenant> unpaidTenants = [];
  DateTimeRange? selectedDateRange;
  List<Tenant> displayedPaidTenants = [];
  List<Tenant> displayedUnpaidTenants = [];

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
    int unpaidTenantsCount = 0;
    int paidTenantsCount = 0;
    List<Tenant> paidList = [];
    List<Tenant> unpaidList = [];

    for (var tenant in tenants) {
      final room = await DatabaseHelper.instance.getRoom(tenant.roomId!);
      if (tenant.monthsPaid > 0) {
        rentPaid += room!.rent * tenant.monthsPaid;
        paidTenantsCount++;
        paidList.add(tenant);
      } else {
        rentUnpaid += room!.rent;
        unpaidTenantsCount++;
        unpaidList.add(tenant);
      }
    }

    setState(() {
      totalRooms = rooms.length;
      totalTenants = tenants.length;
      totalRentPaid = rentPaid;
      totalRentUnpaid = rentUnpaid;
      tenantsNotPaid = unpaidTenantsCount;
      tenantsPaid = paidTenantsCount;
      paidTenants = paidList;
      unpaidTenants = unpaidList;
      displayedPaidTenants = paidList;
      displayedUnpaidTenants = unpaidList;
    });
  }

  Future<void> _pickDateRange() async {
    print("Opening date range picker...");  // Check if picker is triggered
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        print("Selected date range: ${DateFormat('MMM dd, yyyy').format(picked.start)} - ${DateFormat('MMM dd, yyyy').format(picked.end)}");
      });
    } else {
      print("Date picker dismissed without selection.");
    }
  }

  void _showTenantListDialog(String title, List<Tenant> tenants) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Container(
            width: double.maxFinite,
            child: tenants.isEmpty
                ? Text("No tenants found.")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: tenants.length,
                    itemBuilder: (context, index) {
                      final tenant = tenants[index];
                      return ListTile(
                        title: Text(tenant.name),
                        subtitle: Text(
                            'Email: ${tenant.email}\nPhone: ${tenant.mobile}'),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeText = selectedDateRange != null
        ? "${DateFormat('MMM dd, yyyy').format(selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedDateRange!.end)}"
        : "Select Date Range";

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Showing data for: $dateRangeText',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () =>
                      _showTenantListDialog('Paid Tenants', displayedPaidTenants),
                  child: _buildAnalyticsSquare(
                    title: 'Paid Tenants',
                    value: tenantsPaid.toString(),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showTenantListDialog(
                      'Unpaid Tenants', displayedUnpaidTenants),
                  child: _buildAnalyticsSquare(
                    title: 'Unpaid Tenants',
                    value: tenantsNotPaid.toString(),
                  ),
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
