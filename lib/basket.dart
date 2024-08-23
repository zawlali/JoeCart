import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_drive/checkout.dart';
import 'package:test_drive/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BasketModel with ChangeNotifier {
  Map<int, Map<String, dynamic>> _items = {};

  List<Map<String, dynamic>> get items => _items.values.toList();

  double get total => _items.values.fold(
      0,
      (previousValue, item) =>
          previousValue + item['price'] * item['quantity']);

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

  void removeItem(int productId) {
    if (_items.containsKey(productId) && _items[productId]!['quantity'] > 1) {
      _items[productId]!['quantity'] -= 1;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clearBasket() {
    _items.clear();
    notifyListeners();
  }

  Future<void> handleRFIDData(String data) async {
    try {
      if (data.startsWith('ADD: ')) {
        final rfidTag = data.substring(5);
        print("Trying to add: $rfidTag");
        final response = await Supabase.instance.client
            .from('products')
            .select()
            .eq('rfid_tag', rfidTag)
            .single();

        if (response != null) addItem(response);
      } else if (data.startsWith('REMOVE: ')) {
        final rfidTag = data.substring(8);
        print("Trying to remove: $rfidTag");
        final itemToRemove = _items.values.firstWhere(
          (item) => item['rfid_tag'] == rfidTag,
          orElse: () => {},
        );
        if (itemToRemove['product_id'] != null) {
          removeItem(itemToRemove['product_id']);
        } else {
          print("Item not in basket");
        }
      }
    } on PostgrestException catch (error) {
      print('Supabase error: ${error.message}');
      // You can add more error handling here, like showing a snackbar
    } catch (error) {
      print('Unexpected error: $error');
      // Handle other unexpected errors
    }
  }
}

class Basket extends StatefulWidget {
  @override
  BasketState createState() => BasketState();
}

class BasketState extends State<Basket> {
  List<Map<String, dynamic>> basketItems = [];

  @override
  void initState() {
    super.initState();
    if (rosService.isConnected()) {
      subscribeRFID();
    }
  }

  void subscribeRFID() {
    rosService.subscribeToTopic(
        '/rfid_data', 'std_msgs/String', _handleRFIDMessage);
  }

  // @override
  // void dispose() {
  //   rosService.unsubscribeFromTopic('/rfid_data');
  //   super.dispose();
  // }

  void _handleRFIDMessage(dynamic message) {
    final basketModel = Provider.of<BasketModel>(context, listen: false);
    print("RFID Message Handler: $message");
    basketModel.handleRFIDData(message['data']);  
  }

  @override
  Widget build(BuildContext context) {
    final basketModel = Provider.of<BasketModel>(context);
    final basketItems = basketModel.items;
    final total = basketModel.total;
    final theme = Theme.of(context);
    final hasItems = basketItems.isNotEmpty;
    final ScrollController _scrollController = ScrollController();

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
        ));

    return Container(
        color: theme.colorScheme.surface,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.all(10),
                child: Text('Your shopping cart 🛒',
                    style: TextStyle(
                        fontSize: 30,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.none,
                        fontFamily: GoogleFonts.lato().fontFamily))),
            Expanded(
                child: hasItems
                    ? Stack(
                        children: [
                          Scrollbar(
                            thumbVisibility: true,
                            interactive: true,
                            thickness: 7,
                            radius: Radius.circular(10),
                            controller: _scrollController,
                            child: GridView.builder(
                              controller: _scrollController,
                              shrinkWrap: false,
                              primary: false,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 5),
                              itemCount: basketItems.length,
                              itemBuilder: (context, index) {
                                final item = basketItems[index];
                                return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 0, right: 10),
                                        child: Row(
                                          children: <Widget>[
                                            SizedBox(
                                              width: 80,
                                              height: 90,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(0),
                                                child: Image.network(
                                                  item['image_url'] ??
                                                      'https://via.placeholder.com/150',
                                                  fit: BoxFit.fitWidth,
                                                ),
                                              ),
                                            ),
                                            Flexible(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(7.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(item['name'],
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                GoogleFonts
                                                                        .lato()
                                                                    .fontFamily)),
                                                    Text(
                                                        '${item['price']} MYR/pc',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontFamily:
                                                                GoogleFonts
                                                                        .lato()
                                                                    .fontFamily)),
                                                    Text(
                                                        'Qty: ${item['quantity']}',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontFamily:
                                                                GoogleFonts
                                                                        .lato()
                                                                    .fontFamily))
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
                                          child: Text(
                                              "${(item['price'] * item['quantity']) % 1 == 0 ? (item['price'] * item['quantity']).toInt() : (item['price'] * item['quantity']).toStringAsFixed(2)} MYR",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: GoogleFonts.lato()
                                                      .fontFamily)),
                                        ),
                                      )
                                    ]));
                              },
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Text('Place some items in the basket',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                fontFamily: GoogleFonts.lato().fontFamily)),
                      )),
            hasItems
                ? Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total: ${total.toStringAsFixed(2)} MYR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.none,
                              color: theme.colorScheme.primary,
                              fontFamily: GoogleFonts.lato().fontFamily,
                            )),
                        SizedBox(height: 10),
                        Center(
                          child: Container(
                              constraints:
                                  BoxConstraints(minWidth: double.infinity),
                              child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                CheckoutPage()));
                                  },
                                  icon: Icon(Icons.payment),
                                  label: Text(
                                    'Checkout',
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontFamily:
                                            GoogleFonts.lato().fontFamily),
                                  ),
                                  style: style)),
                        )
                      ],
                    ))
                : SizedBox.shrink(),
          ],
        ));
  }
}
