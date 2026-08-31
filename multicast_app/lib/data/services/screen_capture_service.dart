import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/capture_source.dart';
import 'base_desktop_capturer.dart';
import 'mobile_capture_service.dart';

class ScreenCaptureService {
  final Ref _ref;

  ScreenCaptureService(this._ref);

  bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Retrieves available capture sources for desktop platforms.
  /// Returns an empty list on mobile or web as they typically prompt the user directly.
  Future<List<CaptureSource>> getDesktopSources({bool includeWindows = true}) async {
    if (isMobile || kIsWeb) {
      return [];
    }
    
    final desktopCapturer = _ref.read(unifiedDesktopCaptureServiceProvider);
    return await desktopCapturer.getAvailableSources(includeWindows: includeWindows);
  }

  /// Starts screen capture. 
  /// [source] is required for Desktop environments, but ignored on Mobile/Web.
  Future<MediaStream> startCapture({CaptureSource? source, int fps = 60, int maxBitrate = 6000000}) async {
    if (kIsWeb) {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': true,
      };
      return await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
    } 
    
    if (isMobile) {
      final mobileCapturer = _ref.read(mobileCaptureServiceProvider);
      return await mobileCapturer.startMobileScreenCapture(fps: fps, maxBitrate: maxBitrate);
    } 
    
    // Desktop
    if (source == null) {
      throw ArgumentError('CaptureSource must be provided for desktop platforms.');
    }
    final desktopCapturer = _ref.read(unifiedDesktopCaptureServiceProvider);
    return await desktopCapturer.startCapture(source, fps: fps);
  }

  /// Stops any currently active capture sessions.
  Future<void> stopCapture() async {
    if (isMobile) {
      await _ref.read(mobileCaptureServiceProvider).stopCapture();
    }
    // Note: Desktop streams manage their own lifecycle via MediaStream tracks when the session ends.
  }
}

final screenCaptureServiceProvider = Provider<ScreenCaptureService>((ref) {
  return ScreenCaptureService(ref);
});
