"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RoomManager = void 0;
const ws_1 = require("ws");
const protocol_1 = require("./types/protocol");
class RoomManager {
    // Map of peerId -> Client
    clients = new Map();
    // Map of roomId -> Set of peerIds
    rooms = new Map();
    /**
     * Register a new client connection. The peerId isn't known until they join a room.
     */
    handleConnection(socket) {
        let currentPeerId = null;
        socket.on('message', (data) => {
            try {
                const message = JSON.parse(data);
                // When a client sends a JOIN_ROOM message, we register their peerId
                if (message.type === protocol_1.MessageType.JOIN_ROOM && !currentPeerId) {
                    currentPeerId = message.peerId;
                }
                if (currentPeerId) {
                    this.handleMessage(currentPeerId, socket, message);
                }
            }
            catch (error) {
                console.error('Invalid message received:', error);
            }
        });
        socket.on('close', () => {
            if (currentPeerId) {
                this.handleDisconnect(currentPeerId);
            }
        });
        socket.on('error', (error) => {
            console.error(`Socket error for peer ${currentPeerId || 'unknown'}:`, error);
            if (currentPeerId) {
                this.handleDisconnect(currentPeerId);
            }
        });
    }
    handleMessage(peerId, socket, message) {
        switch (message.type) {
            case protocol_1.MessageType.JOIN_ROOM:
                this.joinRoom(peerId, socket, message.roomId);
                break;
            case protocol_1.MessageType.OFFER:
            case protocol_1.MessageType.ANSWER:
            case protocol_1.MessageType.ICE_CANDIDATE:
                this.routeMessage(message.targetPeerId, message);
                break;
            default:
                console.warn('Unhandled message type:', message.type);
        }
    }
    joinRoom(peerId, socket, roomId) {
        // 1. Register client
        this.clients.set(peerId, { socket, roomId });
        // 2. Add to room
        if (!this.rooms.has(roomId)) {
            this.rooms.set(roomId, new Set());
        }
        this.rooms.get(roomId).add(peerId);
        console.log(`Peer ${peerId} joined room ${roomId}`);
        // 3. Acknowledge room join
        this.sendToClient(peerId, {
            type: protocol_1.MessageType.ROOM_JOINED,
            roomId,
            peerId,
        });
    }
    routeMessage(targetPeerId, message) {
        this.sendToClient(targetPeerId, message);
    }
    broadcastToRoom(roomId, message, excludePeerId) {
        const peers = this.rooms.get(roomId);
        if (!peers)
            return;
        for (const peerId of peers) {
            if (peerId !== excludePeerId) {
                this.sendToClient(peerId, message);
            }
        }
    }
    sendToClient(peerId, message) {
        const client = this.clients.get(peerId);
        if (client && client.socket.readyState === ws_1.WebSocket.OPEN) {
            client.socket.send(JSON.stringify(message));
        }
        else {
            console.warn(`Cannot send message to peer ${peerId} - client not found or socket closed`);
        }
    }
    handleDisconnect(peerId) {
        const client = this.clients.get(peerId);
        if (!client)
            return;
        const { roomId } = client;
        this.clients.delete(peerId);
        if (roomId) {
            const room = this.rooms.get(roomId);
            if (room) {
                room.delete(peerId);
                // Notify others in the room that this peer left
                this.broadcastToRoom(roomId, {
                    type: protocol_1.MessageType.PEER_LEFT,
                    peerId,
                });
                // Clean up empty room
                if (room.size === 0) {
                    this.rooms.delete(roomId);
                }
            }
            console.log(`Peer ${peerId} left room ${roomId} (disconnected)`);
        }
        else {
            console.log(`Peer ${peerId} disconnected`);
        }
    }
}
exports.RoomManager = RoomManager;
