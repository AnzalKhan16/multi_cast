import 'package:flutter/material.dart';
import '../widgets/network_status_bar.dart';
import '../widgets/device_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MultiCast'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NetworkStatusBar(),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement share screen action
                      },
                      icon: const Icon(Icons.screen_share),
                      label: const Text('Share My Screen'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement join screen action
                      },
                      icon: const Icon(Icons.connected_tv),
                      label: const Text('Join a Screen'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Discovered Peers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Mock list of devices
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final mockDevices = [
                    {'name': 'Desktop-PC', 'ip': '192.168.1.101', 'type': DeviceType.windows},
                    {'name': 'MacBook Pro', 'ip': '192.168.1.102', 'type': DeviceType.apple},
                    {'name': 'Galaxy S23', 'ip': '192.168.1.103', 'type': DeviceType.android},
                  ];
                  final device = mockDevices[index];
                  return DeviceCard(
                    deviceName: device['name'] as String,
                    ipAddress: device['ip'] as String,
                    deviceType: device['type'] as DeviceType,
                    onTap: () {
                      // TODO: Implement connection logic
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
