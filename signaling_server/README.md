# MultiCast Signaling Server

A lightweight local WebSocket signaling server for the MultiCast application, designed to facilitate WebRTC peer discovery and SDP exchange over a local network.

## Prerequisites

- Node.js (v18+)
- npm

## Setup & Run

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Start the server** (runs via `ts-node` for dev or pre-built for prod):
   ```bash
   npm run dev
   ```
   Or to build and run production:
   ```bash
   npm run build
   npm start
   ```

The server binds to `0.0.0.0` on port `8080` (or `PORT` env variable) to listen across all local network interfaces. Upon startup, it will log the local IP addresses you can use to connect your Flutter clients.
