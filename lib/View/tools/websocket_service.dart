import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';

class WebSocketService {
  final WebSocketChannel channel;
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  WebSocketService(String url)
      : channel = WebSocketChannel.connect(Uri.parse(url)) {
    channel.stream.listen(
      (message) {
        // Add the received message to the message stream
        _messageController.add(message);
      },
      onError: (error) {
        print("WebSocket error: $error");
      },
      onDone: () {
        print("WebSocket connection closed");
      },
    );
  }

  // Expose the stream to listen for incoming messages
  Stream<String> get onMessage => _messageController.stream;

  void sendMessage(String message) {
    channel.sink.add(message);
  }

  void close() {
    channel.sink.close();
    _messageController.close();
  }

  // Continuously send live location updates
  Future<void> sendLiveLocationUpdates() async {
    await Geolocator
        .requestPermission(); // Ensure location permissions are granted
    Geolocator.getPositionStream(
            locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high, distanceFilter: 10))
        .listen((Position position) {
      if (position != null) {
        final locationMessage = jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
        sendMessage(
            locationMessage); // Send live location to the WebSocket server
      }
    });
  }
}
