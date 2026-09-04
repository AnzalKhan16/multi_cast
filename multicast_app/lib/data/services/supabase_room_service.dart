import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRoomService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates a new active room in the `stream_rooms` table.
  Future<void> createRoom({
    required String roomCode,
    String hostName = 'Host',
    String title = 'MultiCast Live Screen',
  }) async {
    try {
      await _supabase.from('stream_rooms').insert({
        'room_code': roomCode,
        'host_name': hostName,
        'title': title,
        'is_active': true,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // In a real app, use a proper logger here
      debugPrint('Error creating room: $e');
    }
  }

  /// Closes a room by setting it to inactive and recording the end time.
  Future<void> closeRoom(String roomCode) async {
    try {
      await _supabase
          .from('stream_rooms')
          .update({
            'is_active': false,
            'ended_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('room_code', roomCode);
    } catch (e) {
      debugPrint('Error closing room: $e');
    }
  }

  /// Returns a realtime stream of active rooms.
  Stream<List<Map<String, dynamic>>> getActiveRoomsStream() {
    return _supabase
        .from('stream_rooms')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false);
  }

  /// Logs telemetry metrics during a broadcast.
  Future<void> logTelemetry({
    required String roomCode,
    required double fps,
    required double latencyMs,
    required double bitrateKbps,
    required double packetsLost,
  }) async {
    try {
      await _supabase.from('stream_telemetry_logs').insert({
        'room_code': roomCode,
        'fps': fps,
        'latency_ms': latencyMs,
        'bitrate_kbps': bitrateKbps,
        'packets_lost': packetsLost,
        'logged_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging telemetry: $e');
    }
  }
}
