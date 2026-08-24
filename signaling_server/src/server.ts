import { WebSocketServer } from 'ws';
import * as os from 'os';
import { RoomManager } from './room_manager';

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 8080;
const HOST = '0.0.0.0';

function getLocalIpAddresses(): string[] {
  const interfaces = os.networkInterfaces();
  const addresses: string[] = [];
  
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]!) {
      if (iface.family === 'IPv4' && !iface.internal) {
        addresses.push(iface.address);
      }
    }
  }
  return addresses;
}

const wss = new WebSocketServer({ port: PORT, host: HOST }, () => {
  console.log(`=========================================`);
  console.log(`🚀 MultiCast Signaling Server is running!`);
  console.log(`=========================================`);
  
  const localIps = getLocalIpAddresses();
  console.log(`Listening on:`);
  console.log(`- localhost:${PORT}`);
  localIps.forEach(ip => {
    console.log(`- ${ip}:${PORT} (Local Network)`);
  });
  console.log(`=========================================`);
  console.log(`Waiting for peers to connect...\n`);
});

const roomManager = new RoomManager();

wss.on('connection', (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  console.log(`[Connection] New client connected from ${clientIp}`);
  
  roomManager.handleConnection(ws);
});

wss.on('error', (error) => {
  console.error('[Server Error]', error);
});
