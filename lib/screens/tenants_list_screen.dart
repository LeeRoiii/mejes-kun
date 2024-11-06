import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../models/room.dart';
import '../database_helper.dart';

class TenantsListScreen extends StatefulWidget {
  @override
  _TenantsListScreenState createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends State<TenantsListScreen> {
  List<Tenant> tenants = [];

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    final tenantsList = await DatabaseHelper.instance.getAllTenants();
    setState(() {
      tenants = tenantsList;
    });
  }

  Future<Room?> _getRoomForTenant(int roomId) async {
    return await DatabaseHelper.instance.getRoom(roomId);
  }

  void _showAddTenantDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    String selectedSex = 'Male';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Renter'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name of the Renter'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: mobileController,
                  decoration: InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                ),
                DropdownButtonFormField<String>(
                  value: selectedSex,
                  items: ['Male', 'Female'].map((String sex) {
                    return DropdownMenuItem<String>(
                      value: sex,
                      child: Text(sex),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSex = newValue ?? 'Male';
                    });
                  },
                  decoration: InputDecoration(labelText: 'Sex'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                final email = emailController.text;
                final mobile = mobileController.text;

                if (name.isNotEmpty && email.isNotEmpty && mobile.isNotEmpty) {
                  final newTenant = Tenant(
                    name: name,
                    email: email,
                    mobile: mobile,
                    sex: selectedSex,
                    monthsPaid: 0, // Initialize monthsPaid to 0 for a new tenant
                  );

                  await DatabaseHelper.instance.addTenant(newTenant);
                  _loadTenants(); // Reload tenants after adding

                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenants List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddTenantDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: tenants.length,
        itemBuilder: (context, index) {
          final tenant = tenants[index];

          return FutureBuilder<Room?>(
            future: tenant.roomId != null ? _getRoomForTenant(tenant.roomId!) : Future.value(null),
            builder: (context, snapshot) {
              String roomInfo = '';
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                final room = snapshot.data!;
                roomInfo = '\nRoom: ${room.name}, Rent: ${room.rent}';
              } else if (snapshot.hasError) {
                roomInfo = '\nError loading room info';
              }

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(tenant.name),
                  subtitle: Text(
                    'Email: ${tenant.email}\n'
                    'Mobile: ${tenant.mobile}\n'
                    'Sex: ${tenant.sex}\n'
                    'Months Paid: ${tenant.monthsPaid}' // Display months paid here
                    '${roomInfo.isNotEmpty ? roomInfo : ''}',
                  ),
                  trailing: tenant.roomId != null
                      ? Icon(Icons.home, color: Colors.green)
                      : Icon(Icons.home_outlined, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
