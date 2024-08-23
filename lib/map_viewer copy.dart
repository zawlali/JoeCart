// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
// import 'package:test_drive/ros_services.dart';
// import "package:flutter_rviz/struct/occupancy_grid.dart";
// import "package:flutter_rviz/utils/og_to_image.dart";

// import 'package:flutter_rviz/flutter_rviz.dart';

// class MapMarker {
//   final double x;
//   final double y;
//   final Color color;
//   final IconData icon;

//   MapMarker({
//     required this.x,
//     required this.y,
//     this.color = Colors.red,
//     this.icon = Icons.location_on,
//   });
// }

// class OccupancyGridViewer extends StatefulWidget {
//   final ROSService rosService;
//   final MapMarker? initialMarker;

//   OccupancyGridViewer({
//     required this.rosService,
//     this.initialMarker,
//     Key? key,
//   }) : super(key: key);

//   @override
//   _OccupancyGridViewerState createState() => _OccupancyGridViewerState();
// }

// class _OccupancyGridViewerState extends State<OccupancyGridViewer> {
//   Uint8List? imageData;
//   double resolution = 0.0;
//   double originX = 0.0;
//   double originY = 0.0;
//   bool isSubscribed = false;
//   List<MapMarker> markers = [];
//   double minX = 0, maxX = 0, minY = 0, maxY = 0;
//   late OccupancyGrid result;

//   @override
//   void initState() {
//     super.initState();
//     _subscribeToMap();
//     if (widget.initialMarker != null) {
//       addMarker(widget.initialMarker!);
//       print('Added initial marker ${widget.initialMarker}');
//     }
//   }

//   void _subscribeToMap() {
//     if (!isSubscribed) {
//       widget.rosService.subscribeToTopic(
//         '/map',
//         'nav_msgs/msg/OccupancyGrid',
//         _handleMapMessage,
//       );
//       isSubscribed = true;
//     }
//   }

//   void _unsubscribeFromMap() {
//     if (isSubscribed) {
//       widget.rosService.unsubscribeFromTopic('/map');
//       isSubscribed = false;
//     }
//   }

//   void _handleMapMessage(Map<String, dynamic> message) {
//     print("Started handling map message");
//     if (!mounted) return;
//     print("Widget is mounted");

//     final int width = message['info']['width'];
//     final int height = message['info']['height'];
//     final List<int> data = List<int>.from(message['data']);

//     resolution = message['info']['resolution'];
//     originX = message['info']['origin']['position']['x'];
//     originY = message['info']['origin']['position']['y'];

//     // Calculate the actual map bounds in ROS coordinates
//     minX = originX;
//     minY = originY;
//     maxX = originX + width * resolution;
//     maxY = originY + height * resolution;

//     print("Map bounds: ($minX, $minY) to ($maxX, $maxY)");
//     print("Map origin: ($originX, $originY)");
//     print("Map resolution: $resolution");

//     setState(() {
//       print("Updating state with new map data");
//       imageData = _convertMapToImage(data, width, height);
//     });
//   }

//   Uint8List _convertMapToImage(List<int> mapData, int width, int height) {
//     final image = img.Image(width: width, height: height);

//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         final index = (height - 1 - y) * width + x;
//         if (index >= mapData.length) continue;

//         final value = mapData[index];

//         int color;
//         if (value == -1) {
//           color = img.getColor(128, 128, 128);
//         } else {
//           final intensity = 255 - ((value.clamp(0, 100) * 255) ~/ 100);
//           color = img.getColor(intensity, intensity, intensity);
//         }

//         image.setPixel(x, y, color);
//       }
//     }

//     return Uint8List.fromList(img.encodePng(image));
//   }

//   void addMarker(MapMarker marker) {
//     setState(() {
//       markers.add(marker);
//     });
//   }

//   void clearMarkers() {
//     setState(() {
//       markers.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (imageData == null) {
//       return Center(child: CircularProgressIndicator());
//     }

//     int mapWidth = imageData!.buffer.asByteData().getInt32(16, Endian.big);
//     int mapHeight = imageData!.buffer.asByteData().getInt32(20, Endian.big);

//     final offsetX = -minX / resolution;
//     final offsetY = -minY / resolution;

//     return Column(
//       children: [
//         Expanded(
//           child: InteractiveViewer(
//             boundaryMargin: EdgeInsets.all(20.0),
//             minScale: 0.1,
//             maxScale: 4.0,
//             child: Stack(
//               children: [
//                 Image.memory(imageData!),
//                 ...markers.map((marker) {
//                   final pixelX = (marker.x - originX) / resolution;
//                   final pixelY = -((marker.y - originY) / resolution);

//                   final pixelX_offset = pixelX + offsetX;
//                   final pixelY_offset = pixelY - offsetY + mapHeight;

//                   print(
//                     'Pixel: $pixelX, $pixelY\n'
//                     'Marker: ${marker.x}, ${marker.y}\n'
//                     'Origin: $originX, $originY\n'
//                     'Resolution: $resolution\n'
//                     'Map size: $mapWidth x $mapHeight\n'
//                     'Offset: $offsetX, $offsetY\n'
//                     'PixelWOffset: $pixelX_offset, $pixelY_offset',
//                   );
//                   return Positioned(
//                     left: pixelX_offset,
//                     top: pixelY_offset,
//                     child: Icon(marker.icon, color: marker.color, size: 24),
//                   );
//                 }).toList(),
//               ],
//             ),
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(
//             'Resolution: ${resolution.toStringAsFixed(3)} m/pixel\n'
//             'Origin: (${originX.toStringAsFixed(2)}, ${originY.toStringAsFixed(2)})',
//             textAlign: TextAlign.center,
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _unsubscribeFromMap();
//     super.dispose();
//   }
// }

// class MapTesting extends StatelessWidget {
//   final ROSService rosService;
//   final MapMarker? marker;

//   MapTesting({required this.rosService, this.marker});

//   @override
//   Widget build(BuildContext context) {
//     print("Initial marker: $marker");
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Map Testing'),
//       ),
//       body: OccupancyGridViewer(
//         rosService: rosService,
//         initialMarker: marker,
//       ),
//     );
//   }
// }
