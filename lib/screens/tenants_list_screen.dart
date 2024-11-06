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
          title: Text('Add Tenant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
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
                    monthsPaid: 0,
                  );

                  await DatabaseHelper.instance.addTenant(newTenant);
                  _loadTenants();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showTenantOptions(Tenant tenant) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Tenant Details'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditTenantDialog(tenant);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Tenant'),
              onTap: () async {
                Navigator.of(context).pop();
                _confirmDeleteTenant(tenant);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteTenant(Tenant tenant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Tenant'),
          content: Text('Are you sure you want to delete ${tenant.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteTenant(tenant);
    }
  }

  Future<void> _deleteTenant(Tenant tenant) async {
    if (tenant.roomId != null) {
      final room = await DatabaseHelper.instance.getRoom(tenant.roomId!);
      if (room != null) {
        // Remove the tenant's name from the occupants list
        room.occupants.remove(tenant.name);

        // Update the room in the database to save changes
        await DatabaseHelper.instance.updateRoom(room);
      }
    }

    // Delete the tenant from the database
    await DatabaseHelper.instance.deleteTenant(tenant.id!);
    _loadTenants();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tenant.name} has been deleted.')),
    );
  }

  void _showEditTenantDialog(Tenant tenant) {
    final TextEditingController nameController = TextEditingController(text: tenant.name);
    final TextEditingController emailController = TextEditingController(text: tenant.email);
    final TextEditingController mobileController = TextEditingController(text: tenant.mobile);
    String selectedSex = tenant.sex;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Tenant Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: mobileController,
                  decoration: InputDecoration(labelText: 'Mobile'),
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
                      selectedSex = newValue ?? tenant.sex;
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
                final updatedTenant = tenant.copyWith(
                  name: nameController.text,
                  email: emailController.text,
                  mobile: mobileController.text,
                  sex: selectedSex,
                );
                await DatabaseHelper.instance.updateTenant(updatedTenant);
                _loadTenants();
                Navigator.of(context).pop();
              },
              child: Text('Save'),
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
                  onTap: () => _showTenantOptions(tenant),
                  title: Text(tenant.name),
                  subtitle: Text(
                    'Email: ${tenant.email}\n'
                    'Mobile: ${tenant.mobile}\n'
                    'Sex: ${tenant.sex}\n'
                    'Months Paid: ${tenant.monthsPaid}' 
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
