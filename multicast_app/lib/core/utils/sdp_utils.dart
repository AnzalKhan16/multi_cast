class SdpUtils {
  /// Prioritizes H.264 (preferably Baseline profile) for lower latency hardware decoding.
  /// Also sets the maximum video bitrate.
  static String optimizeSdp(String sdp, {int maxVideoBitrateKbps = 5000}) {
    String modifiedSdp = sdp;
    
    modifiedSdp = _prioritizeH264(modifiedSdp);
    modifiedSdp = _setVideoBitrate(modifiedSdp, maxVideoBitrateKbps);
    
    return modifiedSdp;
  }

  /// Finds and prioritizes H.264 payload types in the m=video line.
  static String _prioritizeH264(String sdp) {
    final lines = sdp.split('\r\n');
    int mLineIndex = -1;
    String? h264PayloadType;

    // First pass: find the H.264 payload type from rtpmap
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('a=rtpmap:') && lines[i].toLowerCase().contains('h264')) {
        final match = RegExp(r'a=rtpmap:(\d+)\s').firstMatch(lines[i]);
        if (match != null) {
          h264PayloadType = match.group(1);
          break; // Grab the first H264 payload type found
        }
      }
    }

    if (h264PayloadType == null) return sdp; // H.264 not found

    // Second pass: modify the m=video line
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('m=video ')) {
        mLineIndex = i;
        break;
      }
    }

    if (mLineIndex != -1) {
      final elements = lines[mLineIndex].split(' ');
      if (elements.length > 3) {
        // Elements: m=video <port> <profile> <pt1> <pt2> ...
        final pts = elements.sublist(3);
        pts.remove(h264PayloadType);
        pts.insert(0, h264PayloadType); // Move H.264 to the front
        lines[mLineIndex] = '${elements[0]} ${elements[1]} ${elements[2]} ${pts.join(' ')}';
      }
    }

    return lines.join('\r\n');
  }

  /// Injects 'b=AS:' (Application Specific Maximum) bitrate modifier for video.
  static String _setVideoBitrate(String sdp, int maxBitrateKbps) {
    final lines = sdp.split('\r\n');
    int mLineIndex = -1;
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('m=video ')) {
        mLineIndex = i;
        break;
      }
    }
    
    if (mLineIndex == -1) return sdp;
    
    // Check if b=AS already exists right after m=video line
    bool hasBitrate = false;
    int insertIndex = mLineIndex + 1;
    while (insertIndex < lines.length && (lines[insertIndex].startsWith('c=') || lines[insertIndex].startsWith('b='))) {
      if (lines[insertIndex].startsWith('b=AS:')) {
        lines[insertIndex] = 'b=AS:$maxBitrateKbps';
        hasBitrate = true;
        break;
      }
      insertIndex++;
    }
    
    if (!hasBitrate) {
      lines.insert(insertIndex, 'b=AS:$maxBitrateKbps');
    }
    
    return lines.join('\r\n');
  }
}
