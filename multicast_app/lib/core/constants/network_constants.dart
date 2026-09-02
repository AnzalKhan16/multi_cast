class NetworkConstants {
  static const String mdnsServiceName = '_multicast._tcp';
  static const int defaultSignalingPort = 8080;
  static const String defaultSignalingUrl = 'wss://multicast-signaling.onrender.com';
  
  // TXT Record Keys
  static const String txtKeyDeviceName = 'deviceName';
  static const String txtKeyDeviceType = 'deviceType';
  static const String txtKeySignalingPort = 'signalingPort';
}
