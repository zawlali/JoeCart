import 'package:roslibdart/roslibdart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'dart:async';
import 'dart:io';
import 'dart:convert';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ROSService {
  late Ros ros;
  bool _isConnected = false;
  Map<String, Topic> _topics = {};
  Map<String, Service> _services = {};


  Future<bool> connect(String url,
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      Uri uri = Uri.parse(url);
      String host = uri.host;
      int port = uri.port;

      // First, check if the host is reachable
      bool isReachable = await _isHostReachable(host, timeout: timeout);
      if (!isReachable) {
        print("Host is not reachable: $host");
        return false;
      }

      // Then, check if the port is open
      bool isPortOpen = await _isPortOpen(host, port, timeout: timeout);
      if (!isPortOpen) {
        print("Port is not open: $port");
        return false;
      }

      // If both checks pass, proceed with ROS connection
      ros = Ros(url: url);
      print("Connecting to rosUrl: $url");

      // Connect to ROS
      ros.connect();

      _isConnected = true;
      print("Successfully connected to ROS");
      return true;
    } catch (e) {
      print("Failed to connect to ROS: $e");
      return false;
    }
  }

  Future<bool> _isHostReachable(String host,
      {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  Future<bool> _isPortOpen(String host, int port,
      {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (e) {
      print("Port error: $e");
      return false;
    }
  }

  void disconnect() {
    if (_isConnected) {
      ros.close();
      _isConnected = false;
      print('Disconnected from ROS');
    }
  }

  void publishToTopic(String topic, dynamic message) {
    if (_isConnected) {
      final publisher = Topic(
        ros: ros,
        name: '/command',
        type: 'std_msgs/String', // Adjust the message type as needed
        reconnectOnClose: true,
        queueSize: 10,
        queueLength: 10,
      );
      Map<String, dynamic> json = {"data": message.toString()};
      publisher.publish(json);
    } else {
      print('Not connected to ROS');
    }
  }

void publishToTopicWithType(String topic, String messageType, dynamic message) {
  if (_isConnected) {
    final publisher = Topic(
      ros: ros,
      name: topic,
      type: messageType,
      reconnectOnClose: true,
      queueSize: 10,
      queueLength: 10,
    );
    
    Map<String, dynamic> json;
    try {
      if (messageType == 'std_msgs/String') {
        json = {"data": message.toString()};
      } else if (message is Map<String, dynamic>) {
        json = message;
      } else if (message is String) {
        // Attempt to parse the string as JSON
        json = jsonDecode(message);
      } else {
        throw FormatException('Unsupported message format');
      }
      
      publisher.publish(json);
    } catch (e) {
      print('Error publishing message: $e');
      print('Topic: $topic, MessageType: $messageType');
      print('Message: $message');
      // You might want to rethrow the exception or handle it in some other way
    }
  } else {
    print('Not connected to ROS');
  }
}

  Future<void> subscribeToTopic(String topicName, String messageType,
      Function(Map<String, dynamic>) callback) async {
    if (!_isConnected) {
      print('Not connected to ROS');
      return;
    }

    if (!_topics.containsKey(topicName)) {
      _topics[topicName] = Topic(
        ros: ros,
        name: topicName,
        type: messageType,
        reconnectOnClose: true,
        queueLength: 10,
        queueSize: 10,
      );
    }

    _topics[topicName]!.subscribe((message) async {
      print("ROS Service: $message");
      await callback(message);
    });

    print('Subscribed to topic: $topicName');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    print("Attempting to unsubscribe from topic: $topic");

    if (_topics.containsKey(topic)) {
      try {
        await _topics[topic]!.unsubscribe();
        print('Unsubscribed from topic: $topic');
        _topics.remove(topic);
      } catch (e) {
        print('Error while unsubscribing from topic $topic: $e');
      }
    } else {
      print('Topic $topic not found');
    }

    print("After unsubscribe:");
  }

  Future<void> advertiseService(String serviceName, String serviceType, Future<Map<String, dynamic>> Function(Map<String, dynamic>) handler) async {
    if (!_isConnected) {
      print('Not connected to ROS');
      return;
    }

    try {
      final service = Service(name: serviceName, ros: ros, type: serviceType);
      await service.advertise(handler);
      _services[serviceName] = service;
      print('Service advertised: $serviceName');
    } catch (e) {
      print('Failed to advertise service $serviceName: $e');
    }
  }

  Future<Map<String, dynamic>?> callService(String serviceName, String serviceType, [Map<String, dynamic>? request]) async {
    if (!_isConnected) {
      print('Not connected to ROS');
      return null;
    }

    try {
      Service service;
      if (_services.containsKey(serviceName)) {
        service = _services[serviceName]!;
      } else {
        service = Service(name: serviceName, ros: ros, type: serviceType);
        _services[serviceName] = service;
      }
      
      final result = await service.call(request ?? {});
      print('Service call successful: $result');
      return result;
    } catch (e) {
      print('Failed to call service $serviceName: $e');
      return null;
    }
  }

  Future<void> cancelNavigationGoal() async {
    const serviceName = '/navigate_to_pose/_action/cancel_goal';
    const serviceType = 'action_msgs/CancelGoal';
    
    final request = {
      'goal_info': {
      'goal_id': {
        'uuid': List.filled(16, 0), // All zeros to cancel the current goal
      },
      'stamp': {
        'sec': 0,
        'nanosec': 0
      }
      }
    };

    try {
      final result = await callService(serviceName, serviceType, request);
      if (result != null) {
        print('Navigation goal cancelled: $result');
      } else {
        print('Failed to cancel navigation goal');
      }
    } catch (e) {
      print('Error cancelling navigation goal: $e');
    }
  }

  bool isConnected() {
    if (_isConnected) {
      return true;
    } else {
      return false;
    }
  }
}
