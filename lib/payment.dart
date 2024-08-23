import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_drive/basket.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final basketModel = Provider.of<BasketModel>(context);
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Payment',
                style: GoogleFonts.lato(
                    fontSize: 50,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.none)),
            SizedBox(
              height: 10,
            ),
            Text(
              'Scan the QR code to make payment',
              style: GoogleFonts.lato(fontSize: 18),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              width: 300.0,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/media/qr_payment.jpg',
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Amount',
                    style: GoogleFonts.lato(
                        fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  // SizedBox(height: 10),
                  Text(
                    '${total % 1 == 0 ? total.toInt() : total.toStringAsFixed(2)} MYR',
                    style: GoogleFonts.lato(
                        fontSize: 28, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => PaymentConfirmationScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.lato(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentConfirmationScreen extends StatefulWidget {
  @override
  _PaymentConfirmationScreenState createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  bool _isVerifying = true;

  @override
  void initState() {
    super.initState();
    _startVerification();
  }

  void _startVerification() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isVerifying
            ? _buildVerifyingContent(theme)
            : _buildThankYouContent(theme, context),
      ),
    );
  }

  Widget _buildVerifyingContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
        SizedBox(height: 20),
        Text(
          'Verifying...',
          style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildThankYouContent(ThemeData theme, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 100,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: 20),
        Text(
          'Thank you for shopping with JoeCart!',
          style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            // Reset basket state
            Provider.of<BasketModel>(context, listen: false).clearBasket();
            // Navigate to home and remove all previous routes
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Return to Dashboard',
            style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
