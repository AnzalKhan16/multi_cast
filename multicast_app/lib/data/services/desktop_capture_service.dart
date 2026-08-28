import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/capture_source.dart';

class DesktopCaptureService {
  Future<List<CaptureSource>> getAvailableSources({bool includeWindows = true}) async {
    final types = [SourceType.Screen];
    if (includeWindows) {
      types.add(SourceType.Window);
    }
    
    // Request desktop sources using flutter_webrtc's desktopCapturer
    final sources = await desktopCapturer.getSources(types: types);
    
    return sources.map((DesktopCapturerSource source) {
      return CaptureSource(
        id: source.id,
        name: source.name,
        type: source.id.startsWith('window:') 
            ? CaptureSourceType.window 
            : CaptureSourceType.screen,
        thumbnail: source.thumbnail,
      );
    }).toList();
  }
}

final desktopCaptureServiceProvider = Provider<DesktopCaptureService>((ref) {
  return DesktopCaptureService();
});
