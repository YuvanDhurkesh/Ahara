import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../config/api_config.dart';

class SocketService {
  static io.Socket? _socket;
  
  static io.Socket get socket {
    if (_socket == null) {
      init();
    }
    return _socket!;
  }

  static void init() {
    final baseUrl = ApiConfig.baseUrl; // Ensure this is just the domain/IP without /api
    final socketUrl = baseUrl.endsWith('/api') 
        ? baseUrl.substring(0, baseUrl.length - 4) 
        : baseUrl;

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket']) // Use websocket transport
      .disableAutoConnect()     // Disable auto-connection
      .build());

    _socket!.onConnect((_) {
      debugPrint('Connected to Socket.io server ⚡');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from Socket.io server');
    });

    _socket!.onConnectError((err) {
      debugPrint('Socket.io Connect Error: $err');
    });

    _socket!.connect();
  }

  static void joinOrderRoom(String orderId) {
    if (socket.connected) {
      socket.emit('join_order', orderId);
    } else {
      socket.once('connect', (_) {
        socket.emit('join_order', orderId);
      });
    }
  }

  static void updateLocation(String orderId, double lat, double lng) {
    socket.emit('update_location', {
      'orderId': orderId,
      'lat': lat,
      'lng': lng,
    });
  }

  static void onLocationUpdate(Function(double lat, double lng) callback) {
    socket.on('location_updated', (data) {
      if (data != null && data['lat'] != null && data['lng'] != null) {
        callback(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );
      }
    });
  }

  static void sendMessage({
    required String orderId,
    required String senderId,
    required String senderRole,
    required String text,
  }) {
    debugPrint("Sending Message -> Order: $orderId | Role: $senderRole | Text: $text");
    socket.emit('send_message', {
      'orderId': orderId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
    });
  }

  static void onReceiveMessage(Function(Map<String, dynamic> message) callback) {
    debugPrint("Setting up onReceiveMessage listener");
    socket.on('receive_message', (data) {
      debugPrint("Received Message Payload: $data");
      if (data != null) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  static void offReceiveMessage() {
    socket.off('receive_message');
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
