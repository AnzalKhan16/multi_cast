import 'dart:typed_data';

enum CaptureSourceType {
  screen,
  window,
}

class CaptureSource {
  final String id;
  final String name;
  final CaptureSourceType type;
  final Uint8List? thumbnail;

  CaptureSource({
    required this.id,
    required this.name,
    required this.type,
    this.thumbnail,
  });

  @override
  String toString() {
    return 'CaptureSource(id: $id, name: $name, type: ${type.name})';
  }
}
