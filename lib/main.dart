import 'dart:js_util';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:test_drive/products.dart';
import 'package:test_drive/basket.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(    
    url: 'https://gpsmugeykyjvgugutwks.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdwc211Z2V5a3lqdmd1Z3V0d2tzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTE1NDkwNjUsImV4cCI6MjAyNzEyNTA2NX0.bImyztNXNv9hW9rp1tvcsMaYUj15fzJ2NAHFIe7tTD0',  
  );

   runApp(
    ChangeNotifierProvider(
      create: (context) => BasketModel(),
      child: MyApp(),
    ),
   );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        home: LandingPage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)){
      favorites.remove(current);
    }
    else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class LandingPage extends StatelessWidget {
  @override
  
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final ButtonStyle style = ElevatedButton.styleFrom(
    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    fixedSize: const Size(160, 50), // Adjust the fixed size as needed
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );

  return Scaffold(
    backgroundColor: theme.colorScheme.primaryContainer,
    body: Center(
      child: SizedBox(
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Welcome to\n',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w100,
                      color: theme.colorScheme.primary
                    )
                  ),
                  TextSpan(
                    text: 'Joe Cart',
                    style: TextStyle(
                      fontSize: 90,
                      fontWeight: FontWeight.w900,
                      fontFamily: GoogleFonts.lato().fontFamily,
                      color: theme.colorScheme.primary
                    ),                
                  )
                ])
              ),
            ),
            Center(
              child: Expanded(
                child: Container(
                  // Constrain the width of the GridView to fit its content
                  constraints: BoxConstraints(maxWidth: 500), // Adjust this value as needed
                  child: GridView.count(
                    shrinkWrap: true, // Needed to limit the GridView size to its content
                    physics: NeverScrollableScrollPhysics(), // Disables scrolling within the GridView
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: <Widget>[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DashBoard())
                          );
                        },
                        style: style,
                        icon: Icon(Icons.badge),
                        label: const Text('Sign in  '),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DashBoard())
                          );
                        },
                        style: style,
                        icon: Icon(Icons.swipe_vertical),
                        label: const Text('Use as guest'),
                      ),
                      // Add more buttons if needed
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
  );
}
}

class DashBoard extends StatelessWidget{
  
  @override
  Widget build(BuildContext context) {
    print('running');
    final theme = Theme.of(context);
    final ButtonStyle style = ElevatedButton.styleFrom(
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold, 
        fontFamily: GoogleFonts.lato().fontFamily,
      ),
      fixedSize: const Size(160, 50), // Adjust the fixed size as needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return MainContentWithBasket(
      child: Scaffold(
        backgroundColor: theme.colorScheme.primaryContainer,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text('JoeCart Dashboard',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.none,
                    fontFamily: GoogleFonts.lato().fontFamily
                  )
                )
              ),
              Container(
                constraints: BoxConstraints(maxWidth: 800),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProductList())
                        );
                      }, 
                      icon: Icon(Icons.list_alt), 
                      label: const Text('View product list'),
                      style: style,
              
                    ),
                    ElevatedButton.icon(
                      onPressed: () {}, 
                      icon: Icon(Icons.follow_the_signs_rounded), 
                      label: const Text('Follow me around'),
                      style: style
                    ),
                    ElevatedButton.icon(
                      onPressed: () {}, 
                      icon: Icon(Icons.history), 
                      label: const Text('View past orders'),
                      style: style
                    ),
                    ElevatedButton.icon(
                      onPressed: () {}, 
                      icon: Icon(Icons.discount), 
                      label: const Text('Promos'),
                      style: style
                    ),
                    ElevatedButton.icon(
                      onPressed: () {}, 
                      icon: Icon(Icons.help), 
                      label: const Text('Get help'),
                      style: style
                    ),
                    ElevatedButton.icon(
                      onPressed: () {}, 
                      icon: Icon(Icons.logout), 
                      label: const Text('Log out'),
                      style: style
                    ),
                  ],
                )
              )
            ],
          )
        )
      ),
    );
  }
}

class MainContentWithBasket extends StatelessWidget {
  final Widget child;

  MainContentWithBasket({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.background,
      foregroundColor: theme.colorScheme.primary,
    );
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Basket(), // The shopping basket pane
        ),
        Expanded(
          flex: 3,
          child: Scaffold(
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
                style:style
              ),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
            body: child,  
          ), // The main content
        ),
      ],
    );
  }
}
