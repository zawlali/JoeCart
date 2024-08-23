import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:test_drive/ros_services.dart';
import "package:flutter_rviz/struct/occupancy_grid.dart";
import "package:flutter_rviz/utils/og_to_image.dart";

import 'package:flutter_rviz/flutter_rviz.dart';

class MapMarker {
  final double x;
  final double y;
  final Color color;
  final IconData icon;

  MapMarker({
    required this.x,
    required this.y,
    this.color = Colors.red,
    this.icon = Icons.location_on,
  });
}

class OccupancyGridViewer extends StatefulWidget {
  final ROSService rosService;
  final MapMarker? initialMarker;

  OccupancyGridViewer({
    required this.rosService,
    this.initialMarker,
    Key? key,
  }) : super(key: key);

  @override
  _OccupancyGridViewerState createState() => _OccupancyGridViewerState();
}

class _OccupancyGridViewerState extends State<OccupancyGridViewer> {
  Uint8List? imageData;
  double resolution = 0.0;
  double originX = 0.0;
  double originY = 0.0;
  bool isSubscribed = false;
  List<MapMarker> markers = [];
  double minX = 0, maxX = 0, minY = 0, maxY = 0;
  late OccupancyGrid result;

  @override
  void initState() {
    super.initState();
    callMapService();
    if (widget.initialMarker != null) {
      addMarker(widget.initialMarker!);
      print('Added initial marker ${widget.initialMarker}');
    }
  }

  Future<void> callMapService() async {
    if (!widget.rosService.isConnected()) {
      print('Not connected to ROS');
      return;
    }

    try {
      Map<dynamic, dynamic>? result = await widget.rosService.callService(
        'map_server/map',
        'nav_msgs/srv/GetMap',
      );
      if (result != null) {
        print('Service call successful: $result');
        _handleMapMessage(result);
      } else {
        print('Service call failed');
      }
    } catch (e) {
      print('Error calling service: $e');
    }
  }

  void _handleMapMessage(Map<dynamic, dynamic> message) {
    print("Started handling map message");
    if (!mounted) return;

    result = OccupancyGrid.fromJson(message['data']);
  }

  // Uint8List _convertMapToImage(List<int> mapData, int width, int height) {
  //   final image = img.Image(width: width, height: height);

  //   for (int y = 0; y < height; y++) {
  //     for (int x = 0; x < width; x++) {
  //       final index = (height - 1 - y) * width + x;
  //       if (index >= mapData.length) continue;

  //       final value = mapData[index];

  //       int color;
  //       if (value == -1) {
  //         color = img.getColor(128, 128, 128);
  //       } else {
  //         final intensity = 255 - ((value.clamp(0, 100) * 255) ~/ 100);
  //         color = img.getColor(intensity, intensity, intensity);
  //       }

  //       image.setPixel(x, y, color);
  //     }
  //   }

  //   return Uint8List.fromList(img.encodePng(image));
  // }

  void addMarker(MapMarker marker) {
    setState(() {
      markers.add(marker);
    });
  }

  void clearMarkers() {
    setState(() {
      markers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (imageData == null) {
      return Center(child: CircularProgressIndicator());
    }

    int mapWidth = imageData!.buffer.asByteData().getInt32(16, Endian.big);
    int mapHeight = imageData!.buffer.asByteData().getInt32(20, Endian.big);

    final offsetX = -minX / resolution;
    final offsetY = -minY / resolution;

    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            boundaryMargin: EdgeInsets.all(20.0),
            minScale: 0.1,
            maxScale: 4.0,
            child: Stack(
              children: [
                Image.memory(occupancyGridToImageBytes(result)),
                ...markers.map((marker) {
                  final pixelX = (marker.x - originX) / resolution;
                  final pixelY = -((marker.y - originY) / resolution);

                  final pixelX_offset = pixelX + offsetX;
                  final pixelY_offset = pixelY - offsetY + mapHeight;

                  print(
                    'Pixel: $pixelX, $pixelY\n'
                    'Marker: ${marker.x}, ${marker.y}\n'
                    'Origin: $originX, $originY\n'
                    'Resolution: $resolution\n'
                    'Map size: $mapWidth x $mapHeight\n'
                    'Offset: $offsetX, $offsetY\n'
                    'PixelWOffset: $pixelX_offset, $pixelY_offset',
                  );
                  return Positioned(
                    left: pixelX_offset,
                    top: pixelY_offset,
                    child: Icon(marker.icon, color: marker.color, size: 24),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Resolution: ${resolution.toStringAsFixed(3)} m/pixel\n'
            'Origin: (${originX.toStringAsFixed(2)}, ${originY.toStringAsFixed(2)})',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class MapTesting extends StatelessWidget {
  final ROSService rosService;
  final MapMarker? marker;

  MapTesting({required this.rosService, this.marker});

  @override
  Widget build(BuildContext context) {
    print("Initial marker: $marker");
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Testing'),
      ),
      body: OccupancyGridViewer(
        rosService: rosService,
        initialMarker: marker,
      ),
    );
  }
}
