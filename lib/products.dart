import 'dart:js_util';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_drive/main.dart';
import 'package:test_drive/basket.dart';

class ProductList extends StatefulWidget {
  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final _future = Supabase.instance.client.from('products').select();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ButtonStyle add_style = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1),
      ),
      foregroundColor: theme.colorScheme.onPrimary,
      backgroundColor: theme.colorScheme.primary,
    );

    return MainContentWithBasket(
      child: Scaffold(
          backgroundColor: theme.colorScheme.primaryContainer,
          body: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text('Product List',
                      style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.none,
                          fontFamily: GoogleFonts.lato().fontFamily))),
              Expanded(
                child: FutureBuilder(
                    future: _future,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data;
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 1000),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: ClampingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 9 / 16,
                              mainAxisExtent: 300,
                            ),
                            itemCount: products!.length,
                            itemBuilder: ((context, index) {
                              final product = products[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Expanded(
                                        child: Image.network(
                                      product['image_url'],
                                      fit: BoxFit.cover,
                                    )),
                                    ListTile(
                                      title: Text(product['name'],
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text('${product['price']}MYR'),
                                    ),
                                    ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailsPage(
                                                      product: product),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.info),
                                        label: Text('Details'),
                                        style: add_style)
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    }),
              ),
            ],
          )),
    );
  }
}

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ButtonStyle add_style = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      foregroundColor: theme.colorScheme.onPrimary,
      backgroundColor: theme.colorScheme.primary,
    );
    bool isScreenWide = MediaQuery.sizeOf(context).width >= 1000;

    return MainContentWithBasket(
      child: Scaffold(
        backgroundColor: theme.colorScheme.primaryContainer,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1100, maxHeight: 500),
              child: Row(
                children: [
                  SizedBox(
                    width: 500,
                    height: 500,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white
                          ),
                          position: DecorationPosition.background,
                          child: Image.network(
                            product['image_url'],
                            fit: BoxFit.fitHeight,
                          ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(product['name'],
                            style: theme.textTheme.headlineLarge!.copyWith(
                                fontFamily: GoogleFonts.lato().fontFamily,
                                fontWeight: FontWeight.w900)),
                        SizedBox(height: 8),
                        Text('Price: ${product['price']}MYR',
                            style: theme.textTheme.headlineSmall),
                        SizedBox(height: 8),
                        Text('Description: ${product['description']}',
                            style: theme.textTheme.bodyLarge),
                        SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Flex(
                          direction:
                              isScreenWide ? Axis.horizontal : Axis.vertical,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ElevatedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.roundabout_right),
                                label: Text('Take me there'),
                                style: add_style),
                            SizedBox(width: 20, height: 15),
                            ElevatedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.pin_drop),
                                label: Text('Show on map'),
                                style: add_style),
                            SizedBox(width: 20, height: 15),
                            ElevatedButton.icon(
                                onPressed: () {
                                  Provider.of<BasketModel>(context,
                                          listen: false)
                                      .addItem(product);
                                },
                                icon: Icon(Icons.shopping_bag),
                                label: Text('Add to cart'),
                                style: add_style),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
