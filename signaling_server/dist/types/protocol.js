"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MessageType = void 0;
var MessageType;
(function (MessageType) {
    MessageType["JOIN_ROOM"] = "JOIN_ROOM";
    MessageType["ROOM_JOINED"] = "ROOM_JOINED";
    MessageType["OFFER"] = "OFFER";
    MessageType["ANSWER"] = "ANSWER";
    MessageType["ICE_CANDIDATE"] = "ICE_CANDIDATE";
    MessageType["PEER_LEFT"] = "PEER_LEFT";
    MessageType["DISCONNECT"] = "DISCONNECT";
})(MessageType || (exports.MessageType = MessageType = {}));
