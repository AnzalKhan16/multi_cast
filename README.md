# MultiCast 🚀

> **High-Performance, Zero-Latency Cross-Platform Peer-to-Peer Screen Streaming over Local Networks.**

MultiCast is an ultra-low latency, decentralized multimedia streaming system built with Flutter and WebRTC. It enables effortless, instantaneous screen sharing across **Windows, macOS, Android, iOS, and Web** on the same Local Area Network (LAN) without third-party cloud relays, subscriptions, or external internet dependencies.

---

## 🌟 Key Features

- ⚡ **Zero-Latency Direct LAN WebRTC Pipeline**: Hardware-accelerated direct peer-to-peer audio/video streaming utilizing optimized H.264 profiles.
- 📡 **Zero-Config mDNS Auto-Discovery**: Automatic network discovery powered by Bonsoir/mDNS — zero manual IP address typing or port forwarding needed.
- 🖥️ **Cross-Platform Native Capture Engine**:
  - **Windows & macOS**: Native desktop, specific application window, and display monitor capturing via `desktopCapturer` and AppKit bridges.
  - **Android**: Foreground Service with `MediaProjection` integration for smooth high-framerate mobile screencasting.
  - **Web**: HTML5 `getDisplayMedia` API integration.
- 📊 **Real-Time Telemetry & Performance HUD**: Dynamic floating overlay monitoring live FPS, bitrate (Mbps), round-trip latency (ms), jitter, and packet loss.
- 🔄 **Dynamic Adaptive Bitrate (ABR)**: In-flight congestion detection with automatic downscaling requests sent over WebRTC DataChannels to safeguard stream stability.
- 🛡️ **Resilient Self-Healing Network Pipeline**: WebSocket signaling reconnection with exponential backoff and automated ICE Restart on network stalls.

---

## 🏛️ System Architecture

MultiCast adopts a three-tier architecture ensuring seamless handshakes and direct LAN data transfer:

```text
+-----------------------------------------------------------------------------+
|                               DISCOVERY PHASE                               |
|                                                                             |
|  [ Sender Device ]   ---(mDNS / Bonsoir Broadcast: 5353/UDP)--->  [ Local LAN ]
|                                                                        |    |
|  [ Receiver Device ] <---(mDNS Auto-Discovery Listener)---------------+    |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                               SIGNALING PHASE                               |
|                                                                             |
|  [ Sender / Embedded Server ] <============================> [ Receiver ]   |
|          |                 (WebSocket Handshake)                  |         |
|          +--- SDP Offer (Munged H.264 Profile) ------------------>+         |
|          +<-- SDP Answer -----------------------------------------+         |
|          +<-- ICE Candidates Exchange --------------------------->+         |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                               STREAMING PHASE                               |
|                                                                             |
|  [ Sender Screen Capture ]                                                  |
|            |                                                                |
|            v                                                                |
|  [ Hardware Encoder (H.264) ]                                               |
|            |                                                                |
|            +--- Direct RTP/SRTP Video Track (UDP P2P) -------------> [ Receiver Viewport ]
|            +<-- RTCP Feedback (Packets Lost, Jitter, RTT) ----------+         |
|            +<-- DataChannel (Resolution Change / ABR Signals) ------+         |
+-----------------------------------------------------------------------------+
```

---

## 📂 Project Structure

```text
multi_cast/
├── multicast_app/             # Flutter Multi-Platform Client Application
│   ├── lib/
│   │   ├── core/              # Constants, Theme, Enums, ABR Controller & SDP Utils
│   │   ├── data/
│   │   │   ├── models/        # Telemetry, Devices, Capture Sources, Signaling Messages
│   │   │   └── services/      # WebRTC Peer, Screen Capture, mDNS, Stats Collector, Orchestrator
│   │   └── presentation/      # Screens (Home, Sender, Receiver), Viewport, HUD & Widgets
│   ├── android/               # Android native configuration & MediaProjection Foreground Service
│   ├── macos/                 # macOS native AppKit bridges & sandbox entitlements
│   └── web/                   # Web platform manifest & index template
├── signaling_server/          # Standalone Node.js / TypeScript WebSocket Signaling Server
├── scripts/                   # Automated Release & Compilation Scripts
│   ├── build_windows.bat      # Windows release binary build
│   ├── build_windows.ps1      # Windows PowerShell build
│   ├── build_android.sh       # Android APK & AppBundle build
│   └── build_web.sh           # Web CanvasKit release bundle build
└── README.md                  # Comprehensive Documentation
```

---

## 🚀 Quick Start Guide

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.2.0`)
- [Node.js](https://nodejs.org/) (`>= 18.x`) & `npm` (if running standalone signaling server)

---

### 1. Running the Signaling Server

You can run the standalone TypeScript signaling server (or let the app host its own embedded signaling instance):

```bash
cd signaling_server
npm install
npm run build
npm start
```

*Server listens by default on `ws://0.0.0.0:8080`.*

---

### 2. Running the MultiCast Flutter App

Run the application on your desired development target:

```bash
cd multicast_app
flutter pub get

# Run on Desktop (Windows / macOS)
flutter run -d windows
# or
flutter run -d macos

# Run on Mobile (Android Device)
flutter run -d android

# Run on Web (Chrome)
flutter run -d chrome
```

---

## 🔨 Production Build Commands

Production builds can be generated using the scripts in `scripts/`:

### Windows
```cmd
scripts\build_windows.bat
```
*Output: `multicast_app/build/windows/x64/runner/Release/multicast_app.exe`*

### Android
```bash
bash scripts/build_android.sh
```
*Output: `multicast_app/build/app/outputs/flutter-apk/app-release.apk`*

### Web
```bash
bash scripts/build_web.sh
```
*Output: `multicast_app/build/web/`*

---

## 🌐 Network Requirements & Diagnostics

- **Same Subnet**: Both sender and receiver devices must be on the same local subnet (e.g., `192.168.1.0/24`).
- **mDNS Multicast Enabled**: Router must allow IGMP / Multicast traffic on UDP port `5353`.
- **Disable AP Isolation**: Ensure "Client Isolation" or "AP Isolation" is disabled in router settings to permit direct P2P socket communication.
- **Firewall Exceptions**: Ensure incoming connections on the chosen signaling port (default `8080` / dynamic) and UDP media ports are permitted.

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
