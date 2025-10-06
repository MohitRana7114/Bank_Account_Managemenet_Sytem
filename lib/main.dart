import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ipo/main.dart';


void main() {
  runApp(BankingApp());
}

class BankingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Banking & IPO Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double totalBalance = 0;
  double remainingBalance = 0;
  double heldAmount = 0;
  double ipoAllotmentAmount = 0;
  final TextEditingController _balanceController = TextEditingController();

  List<Map<String, dynamic>> ipoList = [];
  List<Map<String, dynamic>> transactionList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalBalance = prefs.getDouble('totalBalance') ?? 0;
      remainingBalance = prefs.getDouble('remainingBalance') ?? 0;
      heldAmount = prefs.getDouble('heldAmount') ?? 0;
      ipoAllotmentAmount = prefs.getDouble('ipoAllotmentAmount') ?? 0;
      ipoList = prefs.getString('ipoList') != null
          ? List<Map<String, dynamic>>.from(jsonDecode(prefs.getString('ipoList')!))
          : [];
      transactionList = prefs.getString('transactionList') != null
          ? List<Map<String, dynamic>>.from(jsonDecode(prefs.getString('transactionList')!))
          : [];
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalBalance', totalBalance);
    await prefs.setDouble('remainingBalance', remainingBalance);
    await prefs.setDouble('heldAmount', heldAmount);
    await prefs.setDouble('ipoAllotmentAmount', ipoAllotmentAmount);
    await prefs.setString('ipoList', jsonEncode(ipoList));
    await prefs.setString('transactionList', jsonEncode(transactionList));
  }

  void addIPO(String name, double amount) {
    setState(() {
      ipoList.add({'name': name, 'amount': amount, 'status': 'Pending'});
      heldAmount += amount;
      remainingBalance -= amount;
    });
    _saveData();
  }

  void allotIPO(String name, double amount) {
    setState(() {
      for (var ipo in ipoList) {
        if (ipo['name'] == name && ipo['amount'] == amount) {
          ipo['status'] = 'Allotted';
          break;
        }
      }
      heldAmount -= amount;
      ipoAllotmentAmount += amount;
    });
    _saveData();
  }

  void refundIPO(String name, double amount) {
    setState(() {
      for (var ipo in ipoList) {
        if (ipo['name'] == name && ipo['amount'] == amount) {
          ipo['status'] = 'Refunded';
          break;
        }
      }
      heldAmount -= amount;
      remainingBalance += amount;
    });
    _saveData();
  }

  void addTransaction(String type, String description, double amount) {
    if (amount > 0 && amount <= remainingBalance) {
      setState(() {
        remainingBalance -= amount;
        transactionList.add({'type': type, 'description': description, 'amount': amount});
      });
      _saveData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid amount or insufficient balance!")),
      );
    }
  }

  void updateBalance(double balance) {
    setState(() {
      totalBalance = balance;
      remainingBalance = balance;
      heldAmount = 0;
      ipoAllotmentAmount = 0;
      ipoList.clear();
      transactionList.clear();
    });
    _saveData();
  }

  void showDialogForIPO() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController amountController = TextEditingController();
        return AlertDialog(
          title: Text("Add IPO"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "IPO Name"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final name = nameController.text;
                final amount = double.tryParse(amountController.text) ?? 0;
                if (name.isNotEmpty && amount > 0) {
                  addIPO(name, amount);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Enter valid name and amount!")),
                  );
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void showDialogForTransaction(String type) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController descriptionController = TextEditingController();
        final TextEditingController amountController = TextEditingController();
        return AlertDialog(
          title: Text("Add $type Transaction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final description = descriptionController.text;
                final amount = double.tryParse(amountController.text) ?? 0;
                if (description.isNotEmpty && amount > 0) {
                  addTransaction(type, description, amount);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Enter valid description and amount!")),
                  );
                }
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
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
        title: Text("Banking & IPO Management"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter/Update Total Balance",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      double balance = double.tryParse(_balanceController.text) ?? 0;
                      if (balance > 0) {
                        updateBalance(balance);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Enter a valid balance!")),
                        );
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text("Total Balance: ₹${totalBalance.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Remaining Balance: ₹${remainingBalance.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Held Amount: ₹${heldAmount.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("IPO Allotment Amount: ₹${ipoAllotmentAmount.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: showDialogForIPO,
                    child: Text("Add IPO"),
                  ),
                  ElevatedButton(
                    onPressed: () => showDialogForTransaction("Transfer"),
                    child: Text("Transfer"),
                  ),
                  ElevatedButton(
                    onPressed: () => showDialogForTransaction("Other"),
                    child: Text("Other"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text("IPO List:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...ipoList.map((ipo) => Card(
                child: ListTile(
                  title: Text("${ipo['name']} - ₹${ipo['amount']}"),
                  subtitle: Text("Status: ${ipo['status']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: ipo['status'] == 'Pending'
                            ? () => allotIPO(ipo['name'], ipo['amount'])
                            : null,
                        style: TextButton.styleFrom(
                          backgroundColor: ipo['status'] == 'Pending' ? Colors.red : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Allot"),
                      ),
                      TextButton(
                        onPressed: ipo['status'] == 'Pending'
                            ? () => refundIPO(ipo['name'], ipo['amount'])
                            : null,
                        child: Text("Refund"),
                      ),
                    ],
                  ),
                ),
              )),
              SizedBox(height: 20),
              Text("Transaction List:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...transactionList.map((txn) => Card(
                child: ListTile(
                  title: Text("${txn['type']} - ${txn['description']}"),
                  subtitle: Text("Amount: ₹${txn['amount']}"),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
