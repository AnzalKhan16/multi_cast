import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/webrtc_data_channel_manager.dart';
import '../../presentation/controllers/session_controller.dart';

class LatencyMonitor {
  final Ref _ref;
  Timer? _pingTimer;
  StreamSubscription? _messageSubscription;
  final int _pingIntervalMs = 2000;
  
  // Track timestamps of sent pings
  final Map<int, DateTime> _pingTimestamps = {};

  LatencyMonitor(this._ref);

  void startMonitoring() {
    final dataChannelManager = _ref.read(webrtcDataChannelManagerProvider);
    
    _messageSubscription?.cancel();
    _messageSubscription = dataChannelManager.onMessage.listen(_handleIncomingMessage);

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(milliseconds: _pingIntervalMs), (timer) {
      _sendPing();
    });
  }

  void _sendPing() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _pingTimestamps[timestamp] = DateTime.now();
    
    _ref.read(webrtcDataChannelManagerProvider).sendMessage({
      'type': 'PING',
      'timestamp': timestamp,
    });
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    if (message['type'] == 'PONG') {
      final int originalTimestamp = message['timestamp'];
      if (_pingTimestamps.containsKey(originalTimestamp)) {
        final sentTime = _pingTimestamps[originalTimestamp]!;
        final rtt = DateTime.now().difference(sentTime).inMilliseconds;
        
        // Feed real-time latency directly into SessionController
        _ref.read(sessionProvider.notifier).updateMetrics(latency: rtt.toDouble());
        
        _pingTimestamps.remove(originalTimestamp);
      }
    }
  }

  void stopMonitoring() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _pingTimestamps.clear();
  }

  void dispose() {
    stopMonitoring();
  }
}

final latencyMonitorProvider = Provider<LatencyMonitor>((ref) {
  final monitor = LatencyMonitor(ref);
  ref.onDispose(() => monitor.dispose());
  return monitor;
});
