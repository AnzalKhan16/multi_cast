import 'package:flutter/material.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullscreen
          ? null
          : AppBar(
              title: const Text('Receiving Stream'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    // TODO: Show connection details
                  },
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isFullscreen)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green, // Good connection indicator
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connection: Excellent',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      'Source: Desktop-PC',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                margin: _isFullscreen ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: _isFullscreen ? BorderRadius.zero : BorderRadius.circular(12),
                  border: _isFullscreen ? null : Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Placeholder for video player
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Waiting for video stream...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                    // Controls overlay placeholder
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: IconButton(
                        icon: Icon(
                          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFullscreen = !_isFullscreen;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_isFullscreen) const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
