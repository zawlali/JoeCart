import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_drive/main.dart';
import 'package:test_drive/basket.dart';
import 'package:test_drive/map_viewer.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';

class ProductList extends StatefulWidget {
  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final _future = Supabase.instance.client.from('products').select();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ButtonStyle addStyle = ElevatedButton.styleFrom(
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
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 100.0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Product List',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                        fontFamily: GoogleFonts.lato().fontFamily),
                  ),
                  centerTitle: true,
                ),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              SliverPadding(
                padding: EdgeInsets.all(10),
                sliver: FutureBuilder(
                    future: _future,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final products = snapshot.data;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 9 / 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = products[index];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailsPage(product: product),
                                  ),
                                );
                              },
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Expanded(
                                        child: Image.network(
                                      product['image_url'] ??
                                          'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                    )),
                                    ListTile(
                                      title: Text(
                                        product['name'],
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      subtitle: Text(
                                        '${product['price']}MYR',
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                        style: addStyle)
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: products!.length,
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
    final ButtonStyle addStyle = ElevatedButton.styleFrom(
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
        appBar: AppBar(
          // title: Text('Product Details'),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white),
                      position: DecorationPosition.background,
                      child: Image.network(
                        product['image_url'] ??
                            'https://via.placeholder.com/150',
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                              onPressed: () async {
                                final shelfData = await Supabase.instance.client
                                    .from('shelves')
                                    .select('x, y')
                                    .eq('id', product['shelf_id'])
                                    .single();

                                if (shelfData != null) {
                                  final poseStamped = {
                                    "header": {"frame_id": "map"},
                                    "pose": {
                                      "position": {
                                        "x": shelfData['x'],
                                        "y": shelfData['y'],
                                        "z": 0.0
                                      },
                                      "orientation": {
                                        "x": 0.0,
                                        "y": 0.0,
                                        "z": 0.0,
                                        "w": 1.0
                                      }
                                    }
                                  };
                                  rosService.publishToTopicWithType(
                                      '/goal_pose',
                                      'geometry_msgs/PoseStamped',
                                      poseStamped);
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NavigationPage(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.roundabout_right),
                              label: Text('Take me there'),
                              style: addStyle),
                          // SizedBox(width: 20, height: 15),
                          // ElevatedButton.icon(
                          //     onPressed: () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (context) => MapTesting(
                          //               rosService: rosService,
                          //               marker: MapMarker(
                          //                 x: 0,
                          //                 y: 0,
                          //                 icon: Icons.shopping_cart,
                          //                 color: Colors.green,
                          //               )),
                          //         ),
                          //       );
                          //     },
                          //     icon: Icon(Icons.pin_drop),
                          //     label: Text('Show on map'),
                          //     style: addStyle),
                          // SizedBox(width: 20, height: 15),
                          // ElevatedButton.icon(
                          //     onPressed: () {
                          //       Provider.of<BasketModel>(context, listen: false)
                          //           .addItem(product);
                          //     },
                          //     icon: Icon(Icons.shopping_bag),
                          //     label: Text('Add to cart'),
                          //     style: addStyle),
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
    );
  }
}

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  String _navigationStatus = 'Taking you to location';
  bool _hasReachedDestination = false;
  bool _isActiveNavigation = true;

  @override
  void initState() {
    super.initState();
    _subscribeToNavigationTopic();
  }

  void _subscribeToNavigationTopic() {
    rosService.subscribeToTopic(
      '/navigate_to_pose/_action/status',
      'action_msgs/GoalStatusArray',
      _handleNavigationStatus,
    );
  }

  void _handleNavigationStatus(Map<String, dynamic> message) {
    if (!mounted) return;
    print('Navigation status: $message');
    if (message['status_list'] != null && message['status_list'].isNotEmpty) {
      var statusList = message['status_list'] as List;

      // Sort the status list by timestamp, most recent first
      statusList.sort((a, b) {
        int aTime = a['goal_info']['stamp']['sec'] * 1000000000 +
            a['goal_info']['stamp']['nanosec'];
        int bTime = b['goal_info']['stamp']['sec'] * 1000000000 +
            b['goal_info']['stamp']['nanosec'];
        return bTime.compareTo(aTime);
      });

      // Get the most recent active goal, or the most recent goal if no active goals
      var currentGoalStatus = statusList.firstWhere(
        (status) => status['status'] == 2, // 2 is ACTIVE
        orElse: () => statusList.first,
      );

      int status = currentGoalStatus['status'];
      print("Current goal status: $status");
      setState(() {
        switch (status) {
          case 1: // PENDING
            _navigationStatus = 'Waiting to start navigation...';
            _hasReachedDestination = false;
            _isActiveNavigation = true;
            break;
          case 2: // ACTIVE
            _navigationStatus = 'Taking you to location';
            _hasReachedDestination = false;
            _isActiveNavigation = true;
            break;
          case 4: // SUCCEEDED
            _navigationStatus = 'You have reached your destination';
            _hasReachedDestination = true;
            _isActiveNavigation = false;
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) Navigator.of(context).pop();
            });
            break;
          case 3: // PREEMPTED
          case 5: // ABORTED
            _navigationStatus = 'Navigation was cancelled or aborted';
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) Navigator.of(context).pop();
            });
          case 6: // REJECTED
            _navigationStatus = 'Navigation was cancelled or aborted';
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) Navigator.of(context).pop();
            });
          case 7: // LOST
            _navigationStatus = 'Navigation was cancelled or aborted';
            _hasReachedDestination = false;
            _isActiveNavigation = false;
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) Navigator.of(context).pop();
            });
            break;
        }
      });
    }
  }

  void cancelNavigationGoal() {
    final cancelMessage = {
      'goal_info': {
        'goal_id': {
          'uuid': [], // Empty array to cancel the current goal
        },
        'stamp': {'sec': 0, 'nanosec': 0}
      }
    };

    rosService.publishToTopicWithType(
      '/navigate_to_pose/_action/cancel_goal',
      'action_msgs/CancelGoal',
      jsonEncode(cancelMessage),
    );

    setState(() {
      _isActiveNavigation = false;
      _navigationStatus = 'Navigation cancelled';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ButtonStyle addStyle = ElevatedButton.styleFrom(
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      foregroundColor: theme.colorScheme.onPrimary,
      backgroundColor: theme.colorScheme.primary,
    );


    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!_hasReachedDestination)
              Column(
                children: [
                  Text("Navigating to product's location",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Lottie.network(
                    'https://lottie.host/e4c7e6b9-fc40-4255-82f1-2607dd2702e1/TKdMtT8dnh.json',
                    width: 201,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    _navigationStatus,
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  if (_isActiveNavigation)
                    ElevatedButton.icon(
                        onPressed: () {
                          rosService.cancelNavigationGoal();
                          Future.delayed(Duration(seconds: 2), () {
                            if (mounted) Navigator.of(context).pop();
                          });
                        },
                        icon: Icon(Icons.cancel),
                        label: Text('Cancel Navigation'),
                        style: addStyle)
                ],
              ),
            if (_hasReachedDestination)
              Column(
                children: [
                  Lottie.network(
                    'https://lottie.host/40f0d52f-213e-4f37-866b-410e85f231cf/A1kqCK5GQe.json',
                    width: 201,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 10,),
                  Text(
                    _navigationStatus,
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    rosService.unsubscribeFromTopic('/navigate_to_pose/_action/status');
    super.dispose();
  }
}
