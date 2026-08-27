import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/webrtc_config.dart';

class WebrtcPeerConnectionManager {
  RTCPeerConnection? _peerConnection;
  
  /// Queue for early ICE candidates received before remote description is set
  final List<RTCIceCandidate> _remoteIceCandidateQueue = [];
  bool _isRemoteDescriptionSet = false;
  
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

  /// Sets the remote description and processes any queued ICE candidates
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection == null) return;
    
    await _peerConnection!.setRemoteDescription(description);
    _isRemoteDescriptionSet = true;
    
    // Flush queued ICE candidates
    for (var candidate in _remoteIceCandidateQueue) {
      await _peerConnection!.addCandidate(candidate);
    }
    _remoteIceCandidateQueue.clear();
  }

  /// Adds a remote ICE candidate. Queues it if remote description is not yet set.
  Future<void> addRemoteIceCandidate(RTCIceCandidate candidate) async {
    if (_isRemoteDescriptionSet && _peerConnection != null) {
      await _peerConnection!.addCandidate(candidate);
    } else {
      _remoteIceCandidateQueue.add(candidate);
    }
  }

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

final webrtcPeerConnectionManagerProvider = Provider<WebrtcPeerConnectionManager>((ref) {
  final manager = WebrtcPeerConnectionManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});
