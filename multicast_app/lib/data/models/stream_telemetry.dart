class StreamTelemetry {
  final double fps;
  final double latencyMs;
  final double bitrateKbps;
  final int packetsLost;
  final double jitterMs;
  final int resolutionWidth;
  final int resolutionHeight;

  const StreamTelemetry({
    this.fps = 0.0,
    this.latencyMs = 0.0,
    this.bitrateKbps = 0.0,
    this.packetsLost = 0,
    this.jitterMs = 0.0,
    this.resolutionWidth = 0,
    this.resolutionHeight = 0,
  });

  StreamTelemetry copyWith({
    double? fps,
    double? latencyMs,
    double? bitrateKbps,
    int? packetsLost,
    double? jitterMs,
    int? resolutionWidth,
    int? resolutionHeight,
  }) {
    return StreamTelemetry(
      fps: fps ?? this.fps,
      latencyMs: latencyMs ?? this.latencyMs,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      packetsLost: packetsLost ?? this.packetsLost,
      jitterMs: jitterMs ?? this.jitterMs,
      resolutionWidth: resolutionWidth ?? this.resolutionWidth,
      resolutionHeight: resolutionHeight ?? this.resolutionHeight,
    );
  }
}
