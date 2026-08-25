import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/signaling_message.dart';

class SignalingClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 10);
  static const Duration _pongTimeout = Duration(seconds: 5);

  final _messageController = StreamController<SignalingMessage>.broadcast();
  Stream<SignalingMessage> get messageStream => _messageController.stream;

  bool get isConnected => _channel != null;

  /// Connects to the signaling server via WebSocket.
  void connect(String serverUrl) {
    if (_channel != null) {
      disconnect();
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      
      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final message = SignalingMessage.fromJson(data);
            
            // Handle Heartbeats
            if (message.type == SignalingMessageType.pong) {
              _pongTimeoutTimer?.cancel();
              return;
            }
            if (message.type == SignalingMessageType.ping) {
              _sendMessage(SignalingMessage(type: SignalingMessageType.pong));
              return;
            }

            _messageController.add(message);
          } catch (e) {
            print('Failed to parse signaling message: $e');
          }
        },
        onError: (error) {
          print('Signaling socket error: $error');
          _messageController.add(SignalingMessage(
            type: SignalingMessageType.error,
            errorMessage: error.toString(),
          ));
          disconnect();
        },
        onDone: () {
          print('Signaling socket closed.');
          disconnect();
        },
      );
      print('Connected to signaling server at $serverUrl');
      _startHeartbeat();
    } catch (e) {
      print('Failed to connect to signaling server: $e');
      rethrow;
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendMessage(SignalingMessage(type: SignalingMessageType.ping));
      
      _pongTimeoutTimer = Timer(_pongTimeout, () {
        print('Pong timeout! Connection lost over local Wi-Fi.');
        disconnect();
      });
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
  }

  /// Announces this peer to a specific room on the signaling server.
  void joinRoom(String roomId, String peerId) {
    _sendMessage(SignalingMessage(
      type: SignalingMessageType.joinRoom,
      roomId: roomId,
      peerId: peerId,
    ));
  }

  /// Routes an SDP offer to a target peer.
  void sendOffer(String targetPeerId, Map<String, dynamic> sdp, String senderPeerId) {
    _sendMessage(SignalingMessage(
      type: SignalingMessageType.offer,
      targetPeerId: targetPeerId,
      senderPeerId: senderPeerId,
      sdp: sdp,
    ));
  }

  /// Routes an SDP answer to a target peer.
  void sendAnswer(String targetPeerId, Map<String, dynamic> sdp, String senderPeerId) {
    _sendMessage(SignalingMessage(
      type: SignalingMessageType.answer,
      targetPeerId: targetPeerId,
      senderPeerId: senderPeerId,
      sdp: sdp,
    ));
  }

  /// Routes local ICE candidates to a target peer.
  void sendCandidate(String targetPeerId, Map<String, dynamic> candidate, String senderPeerId) {
    _sendMessage(SignalingMessage(
      type: SignalingMessageType.iceCandidate,
      targetPeerId: targetPeerId,
      senderPeerId: senderPeerId,
      candidate: candidate,
    ));
  }

  /// Encodes and sends the message over the active socket channel.
  void _sendMessage(SignalingMessage message) {
    if (_channel != null) {
      _channel!.sink.add(message.toJson());
    } else {
      print('Cannot send message, WebSocket is not connected.');
    }
  }

  /// Gracefully closes socket sinks and cleans up active subscriptions.
  void disconnect() {
    _stopHeartbeat();
    _subscription?.cancel();
    _subscription = null;
    
    _channel?.sink.close();
    _channel = null;
    
    print('Disconnected from signaling server.');
  }

  /// Cleans up the stream controller when the client is permanently destroyed.
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
