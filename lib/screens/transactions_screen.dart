import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tenant.dart';
import '../models/transaction.dart';
import '../database_helper.dart';

class TransactionsScreen extends StatefulWidget {
  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Tenant> tenantsWithRooms = [];
  Tenant? selectedTenant;
  final TextEditingController rentAmountController = TextEditingController();
  final TextEditingController amountGivenController = TextEditingController();
  List<Transaction> recentTransactions = [];
  String invoiceMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTenantsWithRooms();
    _loadRecentTransactions();
  }

  Future<void> _loadTenantsWithRooms() async {
    final allTenants = await DatabaseHelper.instance.getAllTenants();
    final tenantsWithRoomAssigned = allTenants.where((tenant) => tenant.roomId != null).toList();
    setState(() {
      tenantsWithRooms = tenantsWithRoomAssigned;
    });
  }

  Future<void> _loadRecentTransactions() async {
    final transactions = await DatabaseHelper.instance.getRecentTransactions();
    setState(() {
      recentTransactions = transactions;
    });
  }

  Future<void> _fetchTenantRent(Tenant tenant) async {
    if (tenant.roomId != null) {
      final room = await DatabaseHelper.instance.getRoom(tenant.roomId!);
      if (room != null) {
        setState(() {
          rentAmountController.text = room.rent.toStringAsFixed(2);
        });
      }
    } else {
      setState(() {
        rentAmountController.clear();
      });
    }
  }

  void _calculatePayment() async {
    if (selectedTenant == null) {
      _showSnackbar('Please select a tenant.');
      return;
    }

    final rentAmount = double.tryParse(rentAmountController.text) ?? 0;
    final amountGiven = double.tryParse(amountGivenController.text) ?? 0;

    if (rentAmount <= 0 || amountGiven <= 0) {
      _showSnackbar('Please enter valid amounts.');
      return;
    }

    if (amountGiven < rentAmount) {
      _showSnackbar('The amount given is less than the required rent. Please enter a sufficient amount.');
      return;
    }

    final monthsCovered = (amountGiven / rentAmount).floor();
    final remainingBalance = amountGiven - (monthsCovered * rentAmount);

    final confirmed = await _showConfirmationDialog();
    if (confirmed) {
      setState(() {
        invoiceMessage = '''
Invoice for ${selectedTenant!.name}\n
Monthly Rent: \$${rentAmount.toStringAsFixed(2)}\n
Amount Given: \$${amountGiven.toStringAsFixed(2)}\n
Months Covered: $monthsCovered\n
Remaining Balance: \$${remainingBalance.toStringAsFixed(2)}\n
Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}
''';
      });

      final updatedMonthsPaid = selectedTenant!.monthsPaid + monthsCovered;
      selectedTenant = selectedTenant!.copyWith(monthsPaid: updatedMonthsPaid);
      await DatabaseHelper.instance.updateTenant(selectedTenant!);

      final transaction = Transaction(
        tenantId: selectedTenant!.id!,
        amountGiven: amountGiven,
        monthsCovered: monthsCovered,
        remainingBalance: remainingBalance,
        date: DateFormat('MMM dd, yyyy').format(DateTime.now()),
      );
      await _saveTransaction(transaction);

      _showInvoiceDialog();
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Payment'),
          content: Text('Are you sure you want to proceed with this payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Invoice'),
          content: Text(invoiceMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            TextButton(
              onPressed: _sendEmail,
              child: Text('Send via Email'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendEmail() async {
    if (selectedTenant == null || selectedTenant!.email.isEmpty) {
      _showSnackbar('Tenant does not have a valid email address.');
      return;
    }

    final subject = Uri.encodeComponent('Rent Payment Invoice');
    final body = Uri.encodeComponent(invoiceMessage);
    final emailUri = Uri.parse('mailto:${selectedTenant!.email}?subject=$subject&body=$body');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showSnackbar('Could not open email client.');
    }
  }

  Future<void> _saveTransaction(Transaction transaction) async {
    await DatabaseHelper.instance.addTransaction(transaction);
    _loadRecentTransactions();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Record Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<Tenant>(
                      hint: Text('Select Tenant'),
                      value: selectedTenant,
                      items: tenantsWithRooms.map((tenant) {
                        return DropdownMenuItem<Tenant>(
                          value: tenant,
                          child: Text(tenant.name),
                        );
                      }).toList(),
                      onChanged: (Tenant? newTenant) async {
                        setState(() {
                          selectedTenant = newTenant;
                        });
                        if (newTenant != null) {
                          await _fetchTenantRent(newTenant);
                        }
                      },
                      decoration: InputDecoration(labelText: 'Tenant Name'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: rentAmountController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Monthly Rent Amount',
                        hintText: 'Auto-filled based on tenant selection',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: amountGivenController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount Given',
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _calculatePayment,
                      child: Text('Calculate'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: recentTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = recentTransactions[index];
                  final tenant = tenantsWithRooms.firstWhere(
                    (tenant) => tenant.id == transaction.tenantId,
                    orElse: () => Tenant(
                      id: transaction.tenantId,
                      name: 'Unknown Tenant',
                      email: '',
                      mobile: '',
                      sex: '',
                    ),
                  );

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(tenant.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount Given: \$${transaction.amountGiven.toStringAsFixed(2)}'),
                          Text('Months Covered: ${transaction.monthsCovered}'),
                          Text('Remaining Balance: \$${transaction.remainingBalance.toStringAsFixed(2)}'),
                          Text('Date: ${transaction.date}'),
                        ],
                      ),
                      leading: Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
