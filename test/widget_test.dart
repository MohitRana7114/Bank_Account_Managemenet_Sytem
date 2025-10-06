import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipo/main.dart'; // Import your main.dart file

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the BankingApp widget and trigger a frame.
    await tester.pumpWidget(BankingApp()); // Replace MyApp with BankingApp

    // Verify the initial state (you can customize these expectations for your app).
    expect(find.text('Enter/Update Total Balance'), findsOneWidget);
    expect(find.text('Total Balance: ₹0.00'), findsOneWidget);

    // Add more interactions and expectations as needed.
  });
}
