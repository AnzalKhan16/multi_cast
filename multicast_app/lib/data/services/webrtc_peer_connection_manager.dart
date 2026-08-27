import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/constants/webrtc_config.dart';

class WebrtcPeerConnectionManager {
  RTCPeerConnection? _peerConnection;
  
  /// Stream controller for local ICE candidates to be sent to signaling server
  final StreamController<RTCIceCandidate> _localIceCandidateController = StreamController<RTCIceCandidate>.broadcast();
  Stream<RTCIceCandidate> get onLocalIceCandidate => _localIceCandidateController.stream;

  /// Stream controller for connection state changes
  final StreamController<RTCPeerConnectionState> _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get onConnectionState => _connectionStateController.stream;

  Future<void> initializePeerConnection() async {
    _peerConnection = await createPeerConnection(WebRTCConfig.defaultConfiguration);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _localIceCandidateController.add(candidate);
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      _connectionStateController.add(state);
      
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          print('WebRTC Connection State: ${state.name}');
          break;
      }
    };
  }
  
  RTCPeerConnection? get peerConnection => _peerConnection;

  Future<void> dispose() async {
    await _localIceCandidateController.close();
    await _connectionStateController.close();
    
    if (_peerConnection != null) {
      final senders = await _peerConnection!.getSenders();
      for (var sender in senders) {
        await sender.track?.stop();
        await _peerConnection!.removeTrack(sender);
      }
      
      await _peerConnection!.close();
      _peerConnection = null;
    }
  }
}
