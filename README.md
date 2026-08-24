# MultiCast

MultiCast is a high-performance, cross-platform local peer-to-peer screen sharing application designed for seamless screen casting across Windows, macOS, iOS, and Android devices over local networks.

## System Architecture

MultiCast relies on a decentralized, peer-to-peer architecture for video and audio transmission while utilizing local network discovery to minimize configuration.

- **Discovery (mDNS/Bonjour):** Devices announce their presence and discover other peers on the local network automatically using Multicast DNS. This completely eliminates the need for manual IP entry.
- **Signaling (WebSockets):** Once peers discover each other, a local lightweight signaling server (or embedded server) handles the exchange of SDP (Session Description Protocol) and ICE (Interactive Connectivity Establishment) candidates between devices to set up the WebRTC connection.
- **Transport (WebRTC):** The actual screen and audio data are streamed peer-to-peer using WebRTC, which provides low-latency, high-throughput, and secure data channels perfectly suited for real-time video broadcasting over LAN.

## Local Network Requirements

To ensure optimal performance and connectivity:
- All devices must be connected to the same local area network (LAN) or Wi-Fi network.
- The router/network switch must support Multicast DNS (mDNS) traffic for discovery.
- AP Isolation / Client Isolation must be disabled on the Wi-Fi router to allow peer-to-peer communication.
- Firewalls must allow traffic on the dynamically allocated WebRTC UDP ports and the specific TCP port chosen for the signaling WebSocket server.
