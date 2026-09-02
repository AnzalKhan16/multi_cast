import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/connection_state.dart';
import '../../core/enums/stream_role.dart';
import '../../presentation/controllers/session_controller.dart';
import '../../presentation/controllers/discovery_controller.dart';
import '../models/capture_source.dart';
import '../models/peer_device.dart';
import 'local_signaling_server.dart';
import 'screen_capture_service.dart';
import 'webrtc_peer_connection_manager.dart';

class SessionOrchestrator {
  final Ref _ref;
  Timer? _stallMonitorTimer;
  int _stallCount = 0;

  SessionOrchestrator(this._ref);

  String _generatePeerId(String prefix) {
    final random = Random().nextInt(999999);
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$random';
  }

  /// Starts a full broadcasting session from end-to-end
  Future<void> startBroadcastingSession(CaptureSource? source, String deviceName) async {
    final sessionController = _ref.read(sessionProvider.notifier);
    
    // 1. Initialize local state
    final localPeerId = _generatePeerId('sender');
    const roomId = 'multicast_room';
    
    // 2. Start Local Signaling Server
    final localSignaling = _ref.read(localSignalingServerProvider);
    const port = 8080;
    try {
      await localSignaling.start(port: port);
    } catch (e) {
      sessionController.logError('Failed to start local signaling server: $e');
      return;
    }
    
    final localIp = await _getLocalIpAddress();
    final serverUrl = 'ws://$localIp:$port';

    // 3. Update Session State
    sessionController.initializeSession(
      StreamRole.sender,
      serverUrl: serverUrl,
      roomId: roomId,
      localPeerId: localPeerId,
    );

    // 4. Start mDNS Broadcast
    final mdnsBroadcast = _ref.read(mdnsBroadcastServiceProvider);
    await mdnsBroadcast.startBroadcasting(
      deviceName: deviceName,
      deviceType: 'desktop',
      signalingPort: port,
    );

    // 5. Start Screen Capture & Add to WebRTC (we don't create offer until a receiver joins)
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

  /// Joins a broadcasting session as a receiver
  Future<void> joinReceiverSession(PeerDevice targetPeer) async {
    final sessionController = _ref.read(sessionProvider.notifier);
    
    // 1. Initialize local state
    final localPeerId = _generatePeerId('receiver');
    const roomId = 'multicast_room'; // Default room name used by the app
    
    final serverUrl = 'ws://${targetPeer.ipAddress}:${targetPeer.port}';

    // 2. Update Session State & Connect Signaling
    sessionController.initializeSession(
      StreamRole.receiver,
      serverUrl: serverUrl,
      roomId: roomId,
      localPeerId: localPeerId,
    );

    // Bind remote peer early so signaling messages know who to talk to
    sessionController.bindRemotePeer(targetPeer);

    // Start stall monitoring for resilient recovery
    _startStallMonitor();
  }

  void _startStallMonitor() {
    _stallMonitorTimer?.cancel();
    _stallCount = 0;
    
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
          _stallCount = 0;
          await triggerIceRestart();
        }
      }
    });
  }

  /// Triggers an ICE restart across WebRTC peer connections and signals the remote peer
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
            sessionState.localPeerId!,
          );
        }
      } else if (sessionState.role == StreamRole.receiver) {
        final offer = await webrtcManager.restartIce(true);
        if (offer != null) {
          signalingClient.sendOffer(
            sessionState.remotePeer!.id, 
            {'sdp': offer.sdp, 'type': offer.type}, 
            sessionState.localPeerId!,
          );
        }
      }
    } catch (e) {
      // ICE restart error logged or handled silently
    }
  }

  /// Gracefully terminates all ongoing capture, signaling, discovery, and connections
  Future<void> endCurrentSession() async {
    _stallMonitorTimer?.cancel();
    
    final sessionController = _ref.read(sessionProvider.notifier);
    
    // 1. Stop mDNS Broadcast
    final mdnsBroadcast = _ref.read(mdnsBroadcastServiceProvider);
    await mdnsBroadcast.stopBroadcasting();
    
    // 2. Stop Discovery
    _ref.read(discoveryProvider.notifier).stopDiscovery();

    // 3. Stop Local Signaling Server (if running)
    final localSignaling = _ref.read(localSignalingServerProvider);
    await localSignaling.stop();

    // 4. Close WebRTC Connections & DataChannels
    final webrtcManager = _ref.read(webrtcPeerConnectionManagerProvider);
    await webrtcManager.dispose();

    // 5. Clean up state
    sessionController.terminateSession();
  }
  
  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (!address.isLoopback && address.address.startsWith('192.168.')) {
            return address.address;
          }
        }
      }
      
      // Fallback
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      // Fallback
    }
    return '127.0.0.1';
  }
}

final sessionOrchestratorProvider = Provider<SessionOrchestrator>((ref) {
  return SessionOrchestrator(ref);
});

