import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoRendererManager {
  RTCVideoRenderer? _renderer;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  RTCVideoRenderer? get renderer => _renderer;

  /// Instantiates and initializes the underlying WebRTC video texture.
  Future<void> initializeRenderer() async {
    if (_isInitialized) return;
    
    _renderer = RTCVideoRenderer();
    await _renderer!.initialize();
    _isInitialized = true;
  }

  /// Binds an incoming remote stream to the renderer's srcObject.
  void attachStream(MediaStream stream) {
    if (!_isInitialized || _renderer == null) {
      throw StateError('Renderer must be initialized before attaching a stream.');
    }
    _renderer!.srcObject = stream;
  }

  /// Releases the stream and disposes the texture to prevent GPU memory leaks.
  Future<void> disposeRenderer() async {
    if (!_isInitialized || _renderer == null) return;
    
    _renderer!.srcObject = null;
    await _renderer!.dispose();
    _renderer = null;
    _isInitialized = false;
  }
}

final videoRendererManagerProvider = Provider<VideoRendererManager>((ref) {
  final manager = VideoRendererManager();
  
  // Ensure the renderer is properly disposed when the provider is torn down
  ref.onDispose(() {
    manager.disposeRenderer();
  });
  
  return manager;
});
