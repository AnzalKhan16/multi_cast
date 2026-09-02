import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/stream_role.dart';
import '../models/capture_source.dart';
import '../models/peer_device.dart';
import 'mdns_broadcast_service.dart';
import 'mdns_discovery_service.dart';
import 'screen_capture_service.dart';
import 'webrtc_peer_connection_manager.dart';
import '../../presentation/controllers/session_controller.dart';
import 'local_signaling_server.dart';
import 'signaling_client.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class SessionOrchestrator {
  final Ref _ref;
  Timer? _stallMonitorTimer;
  int _lastBytesReceived = 0;
  int _stallCount = 0;

  SessionOrchestrator(this._ref);

  Future<void> startBroadcastingSession(CaptureSource? source, String deviceName) async {
    final sessionController = _ref.read(sessionProvider.notifier);
    
    final localPeerId = const Uuid().v4();
    final roomId = 'multicast_room';
    
    final localSignaling = _ref.read(localSignalingServerProvider);
    final port = await localSignaling.startServer();
    
    if (port == null) {
      sessionController.logError('Failed to start local signaling server.');
      return;
    }
    
    final localIp = await _getLocalIpAddress();
    final serverUrl = 'ws://$localIp:$port';

    sessionController.initializeSession(
      StreamRole.sender,
      serverUrl: serverUrl,
      roomId: roomId,
      localPeerId: localPeerId,
    );

    final mdnsBroadcast = _ref.read(mdnsBroadcastServiceProvider);
    await mdnsBroadcast.startBroadcast(deviceName, port);

    try {
      final captureService = _ref.read(screenCaptureServiceProvider);
      final localStream = await captureService.startCapture(source: source);
      final webrtcManager = _ref.read(webrtcPeerConnectionManagerProvider);
      await webrtcManager.addLocalStream(localStream);
    } catch (e) {
      sessionController.logError('Failed to capture screen stream: $e');
      await endCurrentSession();
      return;
    }
  }

  Future<void> joinReceiverSession(PeerDevice targetPeer) async {
    final sessionController = _ref.read(sessionProvider.notifier);
    
    final localPeerId = const Uuid().v4();
    final roomId = 'multicast_room'; 
    
    final serverUrl = 'ws://${targetPeer.ipAddress}:${targetPeer.port}';

    sessionController.initializeSession(
      StreamRole.receiver,
      serverUrl: serverUrl,
      roomId: roomId,
      localPeerId: localPeerId,
    );

    sessionController.bindRemotePeer(targetPeer);
    
    _startStallMonitor();
  }

  void _startStallMonitor() {
    _stallMonitorTimer?.cancel();
    _stallCount = 0;
    _lastBytesReceived = 0;
    
    _stallMonitorTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final sessionState = _ref.read(sessionProvider);
      if (sessionState.connectionState != AppConnectionState.connected) return;
      
      final telemetry = sessionState.telemetry;
      if (telemetry != null) {
        if (telemetry.packetsLost > 50 || telemetry.fps == 0) {
          _stallCount++;
        } else {
          _stallCount = 0;
        }

        if (_stallCount >= 3) {
          print('Network stalled for 9 seconds. Triggering ICE Restart.');
          _stallCount = 0;
          await triggerIceRestart();
        }
      }
    });
  }

  Future<void> triggerIceRestart() async {
    final webrtcManager = _ref.read(webrtcPeerConnectionManagerProvider);
    final sessionState = _ref.read(sessionProvider);
    final signalingClient = _ref.read(signalingClientProvider);
    
    if (sessionState.remotePeer == null || sessionState.localPeerId == null) return;

    try {
      if (sessionState.role == StreamRole.sender) {
        final offer = await webrtcManager.restartIce(true);
        if (offer != null) {
          signalingClient.sendOffer(
            sessionState.remotePeer!.id, 
            {'sdp': offer.sdp, 'type': offer.type}, 
            sessionState.localPeerId!
          );
        }
      } else if (sessionState.role == StreamRole.receiver) {
        // Wait for the sender to send the new offer. Or we can just restart ICE as well.
        // Actually flutter_webrtc ICE restart is driven by the side initiating the restart.
        // Usually, the sender initiates or the receiver sends a new offer. Let's have receiver send offer.
        final offer = await webrtcManager.restartIce(true);
        if (offer != null) {
          signalingClient.sendOffer(
            sessionState.remotePeer!.id, 
            {'sdp': offer.sdp, 'type': offer.type}, 
            sessionState.localPeerId!
          );
        }
      }
    } catch (e) {
      print('ICE Restart failed: $e');
    }
  }

  Future<void> endCurrentSession() async {
    _stallMonitorTimer?.cancel();
    
    final sessionController = _ref.read(sessionProvider.notifier);
    
    final mdnsBroadcast = _ref.read(mdnsBroadcastServiceProvider);
    await mdnsBroadcast.stopBroadcast();
    
    final mdnsDiscovery = _ref.read(mdnsDiscoveryServiceProvider);
    mdnsDiscovery.stopDiscovery();

    final localSignaling = _ref.read(localSignalingServerProvider);
    await localSignaling.stopServer();

    final webrtcManager = _ref.read(webrtcPeerConnectionManagerProvider);
    await webrtcManager.dispose();

    sessionController.terminateSession();
  }
  
  Future<String> _getLocalIpAddress() async {
    return '127.0.0.1'; // Simplified for example, implement actual local IP resolution
  }
}

final sessionOrchestratorProvider = Provider<SessionOrchestrator>((ref) {
  return SessionOrchestrator(ref);
});
