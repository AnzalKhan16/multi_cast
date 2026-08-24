# MultiCast Implementation Phases

## Phase 1: Foundation and Discovery
- [x] Set up project directory structure and basic scaffolding.
- [x] Configure basic dependencies in `pubspec.yaml`.
- [ ] Initialize Node.js signaling server project.
- [ ] Implement mDNS service broadcasting on the host device.
- [ ] Implement mDNS service discovery on client devices.
- [ ] Create basic UI to list discovered local peers.

## Phase 2: Local Signaling
- [ ] Develop local WebSocket signaling server to route messages.
- [ ] Implement client-side WebSocket connection and reconnection logic.
- [ ] Define signaling message payload structure (Offer, Answer, ICE candidates).
- [ ] Embed signaling logic within the host Flutter app (optional, for fully serverless experience) or run as a standalone local service.

## Phase 3: WebRTC Core
- [ ] Integrate `flutter_webrtc` and establish RTCPeerConnection between two devices.
- [ ] Handle SDP Offer/Answer lifecycle over signaling channel.
- [ ] Handle ICE Candidate gathering and exchange.
- [ ] Implement state management for connection statuses (Connecting, Connected, Disconnected).

## Phase 4: Native Capture & Permissions
- [ ] Implement desktop screen capture (Windows/macOS).
- [ ] Implement mobile screen capture (Android MediaProjection / iOS ReplayKit).
- [ ] Integrate `permission_handler` to request screen recording and network access permissions gracefully.
- [ ] Capture and attach system audio (platform-dependent).
- [ ] Attach media tracks to the WebRTC connection.

## Phase 5: UI/UX
- [ ] Design and build a clean, modern placeholder dashboard.
- [ ] Implement video renderer widget for receiving streams on clients.
- [ ] Add controls for pausing, muting, and stopping the stream.
- [ ] Create device metadata display (e.g., using `device_info_plus`).
- [ ] Add smooth transitions and error handling dialogs.

## Phase 6: Optimization
- [ ] Optimize video resolution, bitrate, and frame rate settings for LAN.
- [ ] Manage background execution and wakelocks.
- [ ] Memory and battery profiling on mobile targets.
- [ ] WebRTC connection recovery mechanisms.
