import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../config/api_config.dart';

class SocketService {
  static IO.Socket? _socket;
  
  static IO.Socket get socket {
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

    _socket = IO.io(socketUrl, IO.OptionBuilder()
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
    socket.emit('join_order', orderId);
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

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
