import 'package:flutter/material.dart';
import 'package:test_drive/basket.dart';
import 'package:test_drive/payment.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';


class CheckoutPage extends StatefulWidget {
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final basketModel = Provider.of<BasketModel>(context);
    final basketItems = basketModel.items;
    final total = basketModel.total;
    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.primary,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              // Do nothing or handle it differently since we're on the first route
            }
          },
          style: style,
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Checkout',
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.none,
                        fontFamily: GoogleFonts.lato().fontFamily)),
                SizedBox(height: 16),
                Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: basketItems.length,
                    itemBuilder: (context, index) {
                      final item = basketItems[index];
                      return ListTile(
                        leading: SizedBox(
                          height: 50,
                          width: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item['image_url'] ??
                                          'https://via.placeholder.com/150',
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                        title: Text(item['name'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Qty: ${item['quantity']}'),
                        trailing: Text(
                            '${item['price'] * item['quantity']} MYR',
                            style: TextStyle(fontSize: 13)),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Total: ${total % 1 == 0 ? total.toInt() : total.toStringAsFixed(2)} MYR',
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.lato().fontFamily),
                ),
                SizedBox(height: 20),
                Text("Please select a payment method"),
                SizedBox(height: 10),
                Row(
                  children: [
                    _buildPaymentButton('QR Pay', Icons.qr_code),
                    SizedBox(width: 8),
                    _buildPaymentButton('Saved Card', Icons.credit_card),
                    SizedBox(width: 8),
                    _buildPaymentButton('NFC Pay', Icons.contactless),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPaymentMethod != null
                    ? () {
                        // Navigate to payment page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PaymentScreen()),
                        );
                      }
                    : null, // Button is disabled when no payment method is selected
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: theme.colorScheme.primary, // Grey when disabled
                    // disabledForegroundColor: Colors.blue, // Light grey text when disabled
                    disabledBackgroundColor: Colors.grey
                  ),
                  child: Text('Proceed to Payment',
                      style: TextStyle(color: _selectedPaymentMethod != null
                        ? theme.colorScheme.onPrimary
                        : Colors.white)), // Darker grey text when disabled
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String method, IconData icon) {
  final theme = Theme.of(context);
  final isSelected = _selectedPaymentMethod == method;

  return Expanded(
    child: Container(
      height: 48,
      child: Stack(
        children: [
          Positioned.fill(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
              icon: Icon(icon),
              label: Text(method),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: isSelected ? theme.colorScheme.secondary : Colors.grey,
                foregroundColor: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}