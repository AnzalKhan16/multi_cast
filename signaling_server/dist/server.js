"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const ws_1 = require("ws");
const os = __importStar(require("os"));
const room_manager_1 = require("./room_manager");
const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 8080;
const HOST = '0.0.0.0';
function getLocalIpAddresses() {
    const interfaces = os.networkInterfaces();
    const addresses = [];
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                addresses.push(iface.address);
            }
        }
    }
    return addresses;
}
const wss = new ws_1.WebSocketServer({ port: PORT, host: HOST }, () => {
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
const roomManager = new room_manager_1.RoomManager();
wss.on('connection', (ws, req) => {
    const clientIp = req.socket.remoteAddress;
    console.log(`[Connection] New client connected from ${clientIp}`);
    roomManager.handleConnection(ws);
});
wss.on('error', (error) => {
    console.error('[Server Error]', error);
});
