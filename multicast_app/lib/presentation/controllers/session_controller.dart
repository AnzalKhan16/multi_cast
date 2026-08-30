import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/stream_role.dart';
import '../../core/enums/connection_state.dart';
import '../../data/models/peer_device.dart';
import '../../data/models/capture_source.dart';
import '../../data/models/signaling_message.dart';
import '../../data/services/signaling_client.dart';
import '../../data/services/webrtc_peer_connection_manager.dart';
import '../../data/services/desktop_capture_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

final signalingClientProvider = Provider((ref) {
  final client = SignalingClient();
  ref.onDispose(() => client.dispose());
  return client;
});

class StreamMetrics {
  final double fps;
  final double bitrate;
  final double packetLoss;
  final double latency;

  StreamMetrics({
    this.fps = 0.0,
    this.bitrate = 0.0,
    this.packetLoss = 0.0,
    this.latency = 0.0,
  });

  StreamMetrics copyWith({
    double? fps,
    double? bitrate,
    double? packetLoss,
    double? latency,
  }) {
    return StreamMetrics(
      fps: fps ?? this.fps,
      bitrate: bitrate ?? this.bitrate,
      packetLoss: packetLoss ?? this.packetLoss,
      latency: latency ?? this.latency,
    );
  }
}

class SessionState {
  final StreamRole role;
  final AppConnectionState connectionState;
  final PeerDevice? remotePeer;
  final StreamMetrics metrics;
  final List<String> errorLogs;
  final String? localPeerId;
  final String? roomId;

  SessionState({
    this.role = StreamRole.none,
    this.connectionState = AppConnectionState.idle,
    this.remotePeer,
    StreamMetrics? metrics,
    this.errorLogs = const [],
    this.localPeerId,
    this.roomId,
  }) : metrics = metrics ?? StreamMetrics();

  SessionState copyWith({
    StreamRole? role,
    AppConnectionState? connectionState,
    PeerDevice? remotePeer,
    StreamMetrics? metrics,
    List<String>? errorLogs,
    String? localPeerId,
    String? roomId,
  }) {
    return SessionState(
      role: role ?? this.role,
      connectionState: connectionState ?? this.connectionState,
      remotePeer: remotePeer ?? this.remotePeer,
      metrics: metrics ?? this.metrics,
      errorLogs: errorLogs ?? this.errorLogs,
      localPeerId: localPeerId ?? this.localPeerId,
      roomId: roomId ?? this.roomId,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  final Ref _ref;
  StreamSubscription<SignalingMessage>? _signalingSubscription;
  StreamSubscription<RTCPeerConnectionState>? _webrtcStateSubscription;

  SessionController(this._ref) : super(SessionState()) {
    final webrtcManager = _ref.read(webrtcPeerConnectionManagerProvider);
    _webrtcStateSubscription = webrtcManager.onConnectionState.listen((rtcState) {
      _handleWebRTCConnectionState(rtcState);
    });

    // Listen to local ICE candidates and route them to signaling server
    webrtcManager.onLocalIceCandidate.listen((candidate) {
      final client = _ref.read(signalingClientProvider);
      if (state.remotePeer != null && state.localPeerId != null) {
        client.sendCandidate(
          state.remotePeer!.id, 
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
          state.localPeerId!,
        );
      }
    });
  }

  void _handleWebRTCConnectionState(RTCPeerConnectionState rtcState) {
    AppConnectionState newState = state.connectionState;
    switch (rtcState) {
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        newState = AppConnectionState.connecting;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        newState = AppConnectionState.connected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        newState = AppConnectionState.disconnected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        newState = AppConnectionState.error;
        break;
    }
    
    if (state.connectionState != newState) {
      state = state.copyWith(connectionState: newState);
    }
  }

  void initializeSession(StreamRole role, {String? serverUrl, String? roomId, String? localPeerId}) {
    state = state.copyWith(
      role: role,
      connectionState: AppConnectionState.connecting,
      errorLogs: [],
      localPeerId: localPeerId,
      roomId: roomId,
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

  /// Starts the call (Sender Flow) by creating and sending an SDP offer
  Future<void> startCall(PeerDevice targetPeer, {CaptureSource? source}) async {
    bindRemotePeer(targetPeer);
    
    final webrtcManager = _ref.read(webrtcPeerConnectionManagerProvider);
    
    // If a source is provided, start capture and add it to the WebRTC connection
    if (source != null) {
      try {
        // Integrate DesktopCaptureService to acquire stream
        final captureService = _ref.read(desktopCaptureServiceProvider);
        final localStream = await captureService.startCapture(source);
        await webrtcManager.addLocalStream(localStream);
      } catch (e) {
        logError('Failed to capture desktop stream: $e');
        return;
      }
    }

    final offer = await webrtcManager.createOffer();
    
    if (offer != null && state.localPeerId != null) {
      _ref.read(signalingClientProvider).sendOffer(targetPeer.id, {'sdp': offer.sdp, 'type': offer.type}, state.localPeerId!);
    } else {
      logError('Failed to create offer or localPeerId is null.');
    }
  }

  void _handleSignalingMessage(SignalingMessage message) async {
    final webrtcManager = _ref.read(webrtcPeerConnectionManagerProvider);

    switch (message.type) {
      case SignalingMessageType.error:
        logError(message.errorMessage ?? 'Unknown signaling error');
        break;
      case SignalingMessageType.disconnect:
      case SignalingMessageType.peerLeft:
        logError('Peer disconnected.');
        terminateSession();
        break;
      case SignalingMessageType.offer:
        if (message.sdp != null && message.senderPeerId != null) {
          // Bind the remote peer if not bound
          if (state.remotePeer == null) {
             bindRemotePeer(PeerDevice(
               id: message.senderPeerId!,
               name: 'Unknown Sender',
               ipAddress: 'Unknown',
               deviceType: DeviceType.unknown,
             ));
          }

          await webrtcManager.handleRemoteOffer(message.sdp!);
          final answer = await webrtcManager.createAnswer();
          
          if (answer != null && state.localPeerId != null) {
            _ref.read(signalingClientProvider).sendAnswer(
              message.senderPeerId!, 
              {'sdp': answer.sdp, 'type': answer.type}, 
              state.localPeerId!
            );
          }
        }
        break;
      case SignalingMessageType.answer:
        if (message.sdp != null) {
          await webrtcManager.handleRemoteAnswer(message.sdp!);
        }
        break;
      case SignalingMessageType.iceCandidate:
        if (message.candidate != null) {
          final rtcCandidate = RTCIceCandidate(
            message.candidate!['candidate'],
            message.candidate!['sdpMid'],
            message.candidate!['sdpMLineIndex'],
          );
          await webrtcManager.addRemoteIceCandidate(rtcCandidate);
        }
        break;
      default:
        break;
    }
  }

  void bindRemotePeer(PeerDevice peer) {
    state = state.copyWith(
      remotePeer: peer,
      connectionState: AppConnectionState.connected,
    );
  }

  void updateMetrics({double? fps, double? bitrate, double? packetLoss, double? latency}) {
    state = state.copyWith(
      metrics: state.metrics.copyWith(
        fps: fps,
        bitrate: bitrate,
        packetLoss: packetLoss,
        latency: latency,
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
    _webrtcStateSubscription?.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(ref);
});
