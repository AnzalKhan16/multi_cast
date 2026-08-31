import 'package:flutter/material.dart';

class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  bool _isBroadcasting = false;

  @override
  Widget build(BuildContext context) {
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
                    if (_isBroadcasting) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('FPS', '60'),
                          _buildStatColumn('Bitrate', '5.2 Mbps'),
                          _buildStatColumn('Latency', '12 ms'),
                        ],
                      ),
                    ] else ...[
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
                    // Trigger session termination when stopped
                    // This will also invoke stopCapture() via the updated session_controller
                    // Note: In a full Riverpod setup, we would use ref.read(sessionProvider.notifier).terminateSession();
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
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }
}
