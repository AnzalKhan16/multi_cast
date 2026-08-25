import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/stream_role.dart';
import '../../core/enums/connection_state.dart';
import '../../data/models/peer_device.dart';
import '../../data/models/signaling_message.dart';
import '../../data/services/signaling_client.dart';

final signalingClientProvider = Provider((ref) {
  final client = SignalingClient();
  ref.onDispose(() => client.dispose());
  return client;
});

class StreamMetrics {
  final double fps;
  final double bitrate;
  final double packetLoss;

  StreamMetrics({
    this.fps = 0.0,
    this.bitrate = 0.0,
    this.packetLoss = 0.0,
  });

  StreamMetrics copyWith({
    double? fps,
    double? bitrate,
    double? packetLoss,
  }) {
    return StreamMetrics(
      fps: fps ?? this.fps,
      bitrate: bitrate ?? this.bitrate,
      packetLoss: packetLoss ?? this.packetLoss,
    );
  }
}

class SessionState {
  final StreamRole role;
  final AppConnectionState connectionState;
  final PeerDevice? remotePeer;
  final StreamMetrics metrics;
  final List<String> errorLogs;

  SessionState({
    this.role = StreamRole.none,
    this.connectionState = AppConnectionState.idle,
    this.remotePeer,
    StreamMetrics? metrics,
    this.errorLogs = const [],
  }) : metrics = metrics ?? StreamMetrics();

  SessionState copyWith({
    StreamRole? role,
    AppConnectionState? connectionState,
    PeerDevice? remotePeer,
    StreamMetrics? metrics,
    List<String>? errorLogs,
  }) {
    return SessionState(
      role: role ?? this.role,
      connectionState: connectionState ?? this.connectionState,
      remotePeer: remotePeer ?? this.remotePeer,
      metrics: metrics ?? this.metrics,
      errorLogs: errorLogs ?? this.errorLogs,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  final Ref _ref;
  StreamSubscription<SignalingMessage>? _signalingSubscription;

  SessionController(this._ref) : super(SessionState());

  void initializeSession(StreamRole role, {String? serverUrl, String? roomId, String? localPeerId}) {
    state = state.copyWith(
      role: role,
      connectionState: AppConnectionState.connecting,
      errorLogs: [],
    );

    if (serverUrl != null && roomId != null && localPeerId != null) {
      _connectSignaling(serverUrl, roomId, localPeerId);
    }
  }

  void _connectSignaling(String serverUrl, String roomId, String localPeerId) {
    final client = _ref.read(signalingClientProvider);
    
    try {
      client.connect(serverUrl);
      client.joinRoom(roomId, localPeerId);
      
      _signalingSubscription?.cancel();
      _signalingSubscription = client.messageStream.listen((message) {
        _handleSignalingMessage(message);
      });
      
      state = state.copyWith(connectionState: AppConnectionState.connected);
    } catch (e) {
      logError('Failed to connect to signaling: $e');
    }
  }

  void _handleSignalingMessage(SignalingMessage message) {
    if (message.type == SignalingMessageType.error) {
      logError(message.errorMessage ?? 'Unknown signaling error');
    } else if (message.type == SignalingMessageType.disconnect || message.type == SignalingMessageType.peerLeft) {
      logError('Peer disconnected.');
      terminateSession();
    }
    // Note: OFFER, ANSWER, ICE_CANDIDATE handling will be implemented directly in the WebRTC controllers.
  }

  void bindRemotePeer(PeerDevice peer) {
    state = state.copyWith(
      remotePeer: peer,
      connectionState: AppConnectionState.connected,
    );
  }

  void updateMetrics({double? fps, double? bitrate, double? packetLoss}) {
    state = state.copyWith(
      metrics: state.metrics.copyWith(
        fps: fps,
        bitrate: bitrate,
        packetLoss: packetLoss,
      ),
    );
  }

  void logError(String error) {
    state = state.copyWith(
      errorLogs: [...state.errorLogs, error],
      connectionState: AppConnectionState.error,
    );
  }

  void terminateSession() {
    _signalingSubscription?.cancel();
    _ref.read(signalingClientProvider).disconnect();
    state = SessionState(role: StreamRole.none, connectionState: AppConnectionState.disconnected);
  }

  @override
  void dispose() {
    _signalingSubscription?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(ref);
});
