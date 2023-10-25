import 'dart:math';
import 'package:dart_amqp/dart_amqp.dart';
import 'dart:developer' as developer;

/// An AMQP service for handling connections, channels, and callbacks.
class AmqpService {
  static late Client _client;
  static Channel? _channel;
  static int _maxReconnectionCount = 0;

  static Function()? _onConnected;
  static Function()? _onDisconnected;
  static Function(Exception)? _onError;

  /// Creates a new instance of the AMQP service.
  factory AmqpService(ConnectionSettings connectionSettings) {
    return AmqpService._internal(connectionSettings);
  }

  AmqpService._internal(ConnectionSettings connectionSettings) {
    _maxReconnectionCount = connectionSettings.maxConnectionAttempts;
    if (connectionSettings.connectionName != null) {
      connectionSettings.connectionName =
          _getRandomConnectionName(connectionSettings.connectionName!);
    }
    _client = Client(settings: connectionSettings);
  }

  /// Gets the underlying AMQP client.
  static Client getClient() {
    return _client;
  }

  /// Gets the currently open channel, if available.
  static Channel? getChannel() {
    return _channel;
  }

  /// Sets a callback to be executed when the connection is established.
  static void onConnected(Function()? callback) {
    _onConnected = callback;
  }

  /// Sets a callback to be executed when the connection is disconnected.
  static void onDisconnected(Function()? callback) {
    _onDisconnected = callback;
  }

  /// Sets a callback to be executed when an error occurs.
  static void onError(Function(Exception) callback) {
    _onError = callback;
  }

  /// Establishes the AMQP connection.
  static void connect() async {
    await _client
        .channel()
        .then((channel) => _onClientConnectedAndChannelCreated(channel))
        .catchError((error) {
      _handleError(error);
    });
  }

  /// Handles the connection and channel creation event.
  static void _onClientConnectedAndChannelCreated(Channel? connectedChannel) {
    _channel = connectedChannel;
    //Reset max connection count
    _maxReconnectionCount = _client.settings.maxConnectionAttempts;
    _client.errorListener((error) => _handleError(error));

    developer.log('\x1b[32m AMQP client Connected', name: 'AMQP');

    if (_onConnected != null) {
      _onConnected!();
    }
  }

  /// Handles AMQP errors and initiates reconnection if needed.
  static void _handleError(Exception ex) {
    developer.log(" [*] Exception $ex");
    if (_onError != null) {
      _onError!(ex);
    }
    if (ex is FatalException ||
        ex is ConnectionFailedException ||
        ex is ConnectionException ||
        ex is ChannelException) {
      _reconnect();
    }
  }

  /// Initiates the reconnection process after a disconnection.
  static void _reconnect() async {
    if (_maxReconnectionCount != -1) {
      // Reconnection limit not infinite decrement _maxReconnectionCount
      _maxReconnectionCount -= 1;
    }
    if (_maxReconnectionCount == 0) {
      // Reconnection limit reached
      return;
    }

    _client.close().then((_) {
      if (_channel != null) {
        _channel!.close();
      }
    }).then((_) {
      // Call the onDisconnected callback when disconnection occurs
      if (_onDisconnected != null) {
        _onDisconnected!();
      }
      // Wait before attempting reconnection (e.g., exponential backoff).
      Future.delayed(_client.settings.reconnectWaitTime, () {
        connect();
      });
    });
  }

  /// Generates a random connection name.
  static String _getRandomConnectionName(String connectionName) {
    return '${_getRandomString(8)}_$connectionName';
  }

  /// Generates a random string of the specified length.
  static String _getRandomString(int length) {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}
