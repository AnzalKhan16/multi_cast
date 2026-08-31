import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../widgets/video_stream_viewport.dart';
import '../widgets/stream_control_bar.dart';
import '../../data/services/webrtc_peer_connection_manager.dart';
import '../../data/services/video_renderer_manager.dart';
import '../../presentation/controllers/session_controller.dart';

class ReceiverScreen extends ConsumerStatefulWidget {
  const ReceiverScreen({super.key});

  @override
  ConsumerState<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends ConsumerState<ReceiverScreen> {
  StreamSubscription<MediaStream>? _streamSubscription;
  bool _isConnected = false;
  RTCVideoViewObjectFit _objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;

  @override
  void initState() {
    super.initState();
    _subscribeToStream();
  }

  void _subscribeToStream() {
    final webrtcManager = ref.read(webrtcPeerConnectionManagerProvider);
    final rendererManager = ref.read(videoRendererManagerProvider);

    _streamSubscription = webrtcManager.onRemoteStream.listen((stream) async {
      await rendererManager.initializeRenderer();
      rendererManager.attachStream(stream);
      
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    });
  }

  void _disconnect() {
    ref.read(sessionProvider.notifier).terminateSession();
    // Assuming popping the route is handled by a listener on session state in the router/app level,
    // but we can also pop directly if needed:
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rendererManager = ref.watch(videoRendererManagerProvider);
    final renderer = rendererManager.renderer;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          VideoStreamViewport(
            renderer: renderer,
            objectFit: _objectFit,
            isConnected: _isConnected,
          ),
          
          if (_isConnected)
            StreamControlBar(
              currentFit: _objectFit,
              onFitToggle: (fit) {
                setState(() {
                  _objectFit = fit;
                });
              },
              onDisconnect: _disconnect,
            ),
            
          // Close button at top left, always visible or when hovered
          if (!_isConnected)
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: _disconnect,
              ),
            ),
        ],
      ),
    );
  }
}
