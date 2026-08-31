import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/telemetry_hud_overlay.dart';
import '../../presentation/controllers/session_controller.dart';
import '../../core/enums/stream_role.dart';

class SenderScreen extends ConsumerStatefulWidget {
  const SenderScreen({super.key});

  @override
  ConsumerState<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends ConsumerState<SenderScreen> {
  bool _isBroadcasting = false;
  bool _showHud = true;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final telemetry = sessionState.telemetry;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Control'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isBroadcasting
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isBroadcasting ? Icons.sensors : Icons.sensors_off,
                      size: 64,
                      color: _isBroadcasting
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isBroadcasting ? 'Stream Active' : 'Stream Inactive',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: _isBroadcasting ? Theme.of(context).colorScheme.primary : null,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (_isBroadcasting && telemetry != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(_showHud ? Icons.visibility_off : Icons.visibility),
                        label: Text(_showHud ? 'Hide Telemetry' : 'Show Telemetry'),
                        onPressed: () {
                          setState(() {
                            _showHud = !_showHud;
                          });
                        },
                      ),
                    ] else if (!_isBroadcasting) ...[
                      Text(
                        'Ready to start broadcasting your screen to connected peers.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isBroadcasting = !_isBroadcasting;
                  });
                  if (!_isBroadcasting) {
                    ref.read(sessionProvider.notifier).terminateSession();
                  } else {
                    // For dummy UI toggle, in a real scenario this starts the call:
                    // ref.read(sessionProvider.notifier).initializeSession(StreamRole.sender...);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  backgroundColor: _isBroadcasting
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: _isBroadcasting ? Colors.white : Colors.black,
                ),
                child: Text(
                  _isBroadcasting ? 'Stop Broadcast' : 'Start Broadcast',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        
        // Mount HUD overlay if broadcasting and enabled
        if (_isBroadcasting && _showHud && telemetry != null)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: TelemetryHudOverlay(
                telemetry: telemetry,
              ),
            ),
          ),
      ],
    );
  }

}
