import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/capture_source.dart';
import 'desktop_capture_service.dart';
import 'macos_capture_service.dart';

abstract class BaseDesktopCapturer {
  Future<List<CaptureSource>> getAvailableSources({bool includeWindows = true});
  Future<MediaStream> startCapture(CaptureSource source, {int fps = 60});
}

// Unified provider that delegates to the appropriate platform implementation
final unifiedDesktopCaptureServiceProvider = Provider<BaseDesktopCapturer>((ref) {
  if (Platform.isMacOS) {
    return ref.read(macOsCaptureServiceProvider) as BaseDesktopCapturer;
  } else if (Platform.isWindows) {
    // We assume desktopCaptureServiceProvider from desktop_capture_service.dart
    return ref.read(desktopCaptureServiceProvider) as BaseDesktopCapturer;
  } else {
    throw UnsupportedError('Unsupported platform for desktop capture.');
  }
});
