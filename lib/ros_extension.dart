import 'dart:async';
import 'package:roslibdart/roslibdart.dart';

extension RosExtensions on Ros {
  Future<void> connectWithTimeout(Duration timeout) async {
    Completer<void> completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = this.statusStream.listen((status) {
      if (status == Status.connected) {
        if (!completer.isCompleted) completer.complete();
        subscription.cancel();
      } else if (status == Status.errored) {
        if (!completer.isCompleted)
          completer.completeError("Connection failed");
        subscription.cancel();
      }
    });

    this.connect();

    try {
      await completer.future.timeout(timeout);
    } on TimeoutException {
      subscription.cancel();
      throw TimeoutException("Connection timed out");
    } catch (e) {
      subscription.cancel();
      throw Exception("Failed to connect: $e");
    }
  }
}
