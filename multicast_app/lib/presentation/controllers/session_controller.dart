import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/stream_role.dart';
import '../../core/enums/connection_state.dart';
import '../../data/models/peer_device.dart';

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
  SessionController() : super(SessionState());

  void initializeSession(StreamRole role) {
    state = state.copyWith(
      role: role,
      connectionState: AppConnectionState.connecting,
      errorLogs: [],
    );
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
    state = SessionState(role: StreamRole.none, connectionState: AppConnectionState.disconnected);
  }
}

final sessionProvider = StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController();
});
