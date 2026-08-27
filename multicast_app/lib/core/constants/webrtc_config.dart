class WebRTCConfig {
  /// Default configuration for local LAN peer-to-peer streaming.
  /// Disables public STUN/TURN servers to enforce pure local subnet mode.
  static final Map<String, dynamic> defaultConfiguration = {
    'iceServers': [
      // For pure local network, we can omit STUN/TURN. 
      // If a fallback is needed for testing across complex local topologies,
      // an internal STUN server could be added here.
    ],
    'sdpSemantics': 'unified-plan',
    'iceTransportPolicy': 'all',
    'bundlePolicy': 'max-bundle',
  };

  /// Optional media constraints for screen sharing and audio.
  static final Map<String, dynamic> defaultMediaConstraints = {
    'audio': true,
    'video': {
      'mandatory': {
        'minWidth': '1280',
        'minHeight': '720',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    }
  };
}
