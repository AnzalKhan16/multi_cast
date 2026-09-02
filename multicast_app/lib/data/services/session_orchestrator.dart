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
import 'package:uuid/uuid.dart';
import 'dart:io';

class SessionOrchestrator {
  final Ref _ref;

  SessionOrchestrator(this._ref);

  /// Starts a full broadcasting session from end-to-end
  Future<void> startBroadcastingSession(CaptureSource? source, String deviceName) async {
    final sessionController = _ref.read(sessionProvider.notifier);
    
    // 1. Initialize local state
    final localPeerId = const Uuid().v4();
    final roomId = 'multicast_room';
    
    // 2. Start Local Signaling Server
    final localSignaling = _ref.read(localSignalingServerProvider);
    final port = await localSignaling.startServer();
    
    if (port == null) {
      sessionController.logError('Failed to start local signaling server on any port.');
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
    await mdnsBroadcast.startBroadcast(deviceName, port);

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
    final localPeerId = const Uuid().v4();
    final roomId = 'multicast_room'; // Default room name used by the app
    
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

    // Wait for the WebRTC connection state to process the offer/answer
    // The session_controller already listens to incoming offers and will generate the answer.
  }

  /// Gracefully terminates all ongoing capture, signaling, discovery, and connections
  Future<void> endCurrentSession() async {
    final sessionController = _ref.read(sessionProvider.notifier);
    
    // 1. Stop mDNS Broadcast
    final mdnsBroadcast = _ref.read(mdnsBroadcastServiceProvider);
    await mdnsBroadcast.stopBroadcast();
    
    // 2. Stop mDNS Discovery (if running)
    final mdnsDiscovery = _ref.read(mdnsDiscoveryServiceProvider);
    mdnsDiscovery.stopDiscovery();

    // 3. Stop Local Signaling Server (if running)
    final localSignaling = _ref.read(localSignalingServerProvider);
    await localSignaling.stopServer();

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
      print('Failed to get local IP: $e');
    }
    return '127.0.0.1';
  }
}

final sessionOrchestratorProvider = Provider<SessionOrchestrator>((ref) {
  return SessionOrchestrator(ref);
});
