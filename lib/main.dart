import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:test_drive/products.dart';
import 'package:test_drive/basket.dart';
import 'package:test_drive/ros_services.dart';
import 'package:test_drive/help.dart';

import 'package:flutter/services.dart';
import 'package:test_drive/map_viewer.dart';

final rosService = ROSService();
String? rosUrl = 'ws://192.168.137.142:9090';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Force landscape orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Supabase.initialize(
    url: 'https://gpsmugeykyjvgugutwks.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdwc211Z2V5a3lqdmd1Z3V0d2tzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTE1NDkwNjUsImV4cCI6MjAyNzEyNTA2NX0.bImyztNXNv9hW9rp1tvcsMaYUj15fzJ2NAHFIe7tTD0',
  );

  await rosService
      .connect(rosUrl!); // Replace with your ROS WebSocket server URL

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
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          fontFamily: GoogleFonts.lato().fontFamily,
          textTheme: GoogleFonts.latoTextTheme(),
        ),
        home: DashBoard(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}

class DashBoard extends StatefulWidget {
  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  static bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    if (_isFirstLaunch && !rosService.isConnected()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _askForROSUrl;
      });
      _isFirstLaunch = false;
    }
  }

  Future<void> get _askForROSUrl async {
    final TextEditingController _controller =
        TextEditingController(text: rosUrl);
    rosUrl = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter ROS URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Status: ${rosService.isConnected() ? "Connected" : "Disconnected"}"),
              TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: "ROS URL"),
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_controller.text);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      },
    );

    if (rosUrl != null) {
      rosService.connect(rosUrl!);
      // Wait for ROS connection before initializing basket
      await Future.doWhile(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return !rosService.isConnected();
      });

      if (rosService.isConnected()) {
        final basketState = BasketState();
        basketState.subscribeRFID();
        print('Basket initialized after ROS connection');
      } else {
        print('Failed to initialize basket: ROS connection not established');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Text('Welcome to JoeCart',
                      style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.none,
                          fontFamily: GoogleFonts.lato().fontFamily))),
              Container(
                  constraints: BoxConstraints(maxWidth: 600),
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
                              MaterialPageRoute(
                                  builder: (context) => ProductList()));
                        },
                        icon: Icon(Icons.list_alt),
                        label: const Text('View product list'),
                        style: style,
                      ),
                      // ElevatedButton.icon(
                      //     onPressed: () {
                      //       rosService.publishToTopic(
                      //           '/command', 'follow me bitch');
                      //       print("Pressed");
                      //     },
                      //     icon: Icon(Icons.follow_the_signs_rounded),
                      //     label: const Text('Follow me around'),
                      //     style: style),
                      // ElevatedButton.icon(
                      //     onPressed: () {
                      //       Navigator.push(
                      //           context,
                      //           MaterialPageRoute(
                      //               builder: (context) => MapTesting(
                      //                     rosService: rosService,
                      //                     marker: MapMarker(
                      //                         x: 0,
                      //                         y: 0,
                      //                         icon: Icons.ac_unit,
                      //                         color: Colors.blue),
                      //                   )));
                      //     },
                      //     icon: Icon(Icons.map),
                      //     label: const Text('Map testing'),
                      //     style: style),
                      // ElevatedButton.icon(
                      //     onPressed: () {},
                      //     icon: Icon(Icons.discount),
                      //     label: const Text('Promos'),
                      //     style: style),
                      ElevatedButton.icon(
                          onPressed: () {
                            sendTelegramMessage();
                          },
                          icon: Icon(Icons.help),
                          label: const Text('Get help'),
                          style: style),
                      ElevatedButton.icon(
                          onPressed: () {
                            _askForROSUrl;
                          },
                          icon: Icon(Icons.settings),
                          label: const Text('Settings'),
                          style: style),
                    ],
                  ))
            ],
          ))),
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
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.primary,
    );
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Basket(), // The shopping basket pane
        ),
        Expanded(
          flex: 10,
          child: Scaffold(
            // appBar: AppBar(
            //   leading: IconButton(
            //     icon: Icon(Icons.arrow_back),
            //     onPressed: () {
            //       if (Navigator.canPop(context)) {
            //         Navigator.of(context).pop();
            //       } else {
            //         // Do nothing or handle it differently since we're on the first route
            //       }
            //     },
            //     style:style
            //   ),
            //   backgroundColor: theme.colorScheme.primaryContainer,
            // ),
            body: child,
          ), // The main content
        ),
      ],
    );
  }
}
