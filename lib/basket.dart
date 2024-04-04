import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class BasketModel with ChangeNotifier {
  Map<int, Map<String, dynamic>> _items = {};

  List<Map<String, dynamic>> get items => _items.values.toList();

  double get total => _items.values.fold(0, (previousValue, item) => previousValue + item['price'] * item['quantity']);

  void addItem(Map<String, dynamic> item) {
    if (_items.containsKey(item['product_id'])) {
      _items[item['product_id']]!['quantity'] += 1;
    } else {
      item['quantity'] = 1;
      _items[item['product_id']] = item;
    }

   print('Item added: ${_items[item['product_id']]}'); // Debug print

    notifyListeners();
  }

  void removeItem(int product_id) {
    if (_items.containsKey(product_id) && _items[product_id]!['quantity'] > 1) {
      _items[product_id]!['quantity'] -= 1;
    } else {
      _items.remove(product_id);
    }
    notifyListeners();
  }
}


class Basket extends StatefulWidget {
  @override
  _BasketState createState() => _BasketState();
}

class _BasketState extends State<Basket> {
  List<Map<String,dynamic>> basketItems = [];


  @override 
  Widget build(BuildContext context) {

    final basketModel = Provider.of<BasketModel>(context);
    final basketItems = basketModel.items;
    final total = basketModel.total;
    final theme = Theme.of(context);
    final hasItems = basketItems.isNotEmpty;

    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: TextStyle(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.bold, 
        fontFamily: GoogleFonts.lato().fontFamily,
      ),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      )
    );

    return Container(
      color: theme.colorScheme.background,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'Your shopping cart 🛒',
               style: TextStyle(
                fontSize: 30,
                color: theme.colorScheme.primary,
                decoration: TextDecoration.none,
                fontFamily: GoogleFonts.lato().fontFamily
               )
            )
          ),
          Expanded(
            child: hasItems
            ? GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 10,
                childAspectRatio: 3,
              ), 
              itemCount: basketItems.length,
              itemBuilder:(context, index) {
                final item = basketItems[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 90,
                              height: 90,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  item['image_url'],
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),   
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(7.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('${item['price']*item['quantity']} MYR', style: TextStyle(fontSize: 14)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Qty: ${item['quantity']}', style: TextStyle(fontSize: 14)),
                                      ],
                                    )
                                    // You can add more info or buttons here
                                  ],
                                ),
                              ),
                            ),                   
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            onPressed: () {
                              Provider.of<BasketModel>(context, listen: false).removeItem(item['product_id']);
                            }, 
                            icon: Icon(Icons.delete),
                            style: style,
                          ),
                        )
                      )
                    ]
                  )
                );
              },
            )
            : Center(child: Text('Place some items in the basket', style: theme.textTheme.bodyLarge),)
          ),
          hasItems ? Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${total}MYR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                    color: theme.colorScheme.primary,
                  )
                ),
                SizedBox(height: 10),
                Center(
                  child: Container(
                    constraints: BoxConstraints(minWidth: double.infinity),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CheckoutPage())
                        );
                      }, 
                      icon: Icon(Icons.payment), 
                      label: Text('Checkout', style: TextStyle(fontSize: 19, fontFamily: GoogleFonts.lato().fontFamily),),
                      style : style
                    )
                  ),
                )
              ],
            )
          )
          : SizedBox.shrink(),
        ],
      )
    );
  }
}

class CheckoutPage extends StatefulWidget {

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _selectedPaymentMethod;

  final List<String> paymentOptions = ['QR Pay', 'NFC Pay', 'Saved cards'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final basketModel = Provider.of<BasketModel>(context);
    final basketItems = basketModel.items;
    final total = basketModel.total;
    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.background,
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
                    fontFamily: GoogleFonts.lato().fontFamily
                  )
                ),
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
                              item['image_url'],
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                        title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Qty: ${item['quantity']}'),
                        trailing: Text('${item['price']*item['quantity']} MYR', style: TextStyle(fontSize: 13)),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Total: ${total} MYR',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.lato().fontFamily),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Choose a payment method',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.background,
                  ),
                  value: _selectedPaymentMethod, // The currently selected value
                  items: paymentOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  },
                  dropdownColor: theme.colorScheme.background,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle place order logic
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: Text('Place Order', style: TextStyle(color: theme.colorScheme.onPrimary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 