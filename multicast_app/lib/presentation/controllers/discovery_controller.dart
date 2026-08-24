import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/peer_device.dart';

class DiscoveryState {
  final String? localIp;
  final bool isDiscovering;
  final List<PeerDevice> discoveredPeers;
  final String? errorMessage;

  DiscoveryState({
    this.localIp,
    this.isDiscovering = false,
    this.discoveredPeers = const [],
    this.errorMessage,
  });

  DiscoveryState copyWith({
    String? localIp,
    bool? isDiscovering,
    List<PeerDevice>? discoveredPeers,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiscoveryState(
      localIp: localIp ?? this.localIp,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      discoveredPeers: discoveredPeers ?? this.discoveredPeers,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DiscoveryController extends StateNotifier<DiscoveryState> {
  DiscoveryController() : super(DiscoveryState());

  void setLocalIp(String ip) {
    state = state.copyWith(localIp: ip);
  }

  void startDiscovery() {
    state = state.copyWith(isDiscovering: true, clearError: true);
  }

  void stopDiscovery() {
    state = state.copyWith(isDiscovering: false);
  }

  void addPeer(PeerDevice peer) {
    if (!state.discoveredPeers.any((p) => p.id == peer.id)) {
      state = state.copyWith(
        discoveredPeers: [...state.discoveredPeers, peer],
      );
    }
  }

  void updatePeer(PeerDevice peer) {
    final updatedPeers = state.discoveredPeers.map((p) {
      return p.id == peer.id ? peer : p;
    }).toList();
    state = state.copyWith(discoveredPeers: updatedPeers);
  }

  void removePeer(String peerId) {
    final updatedPeers = state.discoveredPeers.where((p) => p.id != peerId).toList();
    state = state.copyWith(discoveredPeers: updatedPeers);
  }

  void clearPeers() {
    state = state.copyWith(discoveredPeers: []);
  }

  void setError(String error) {
    state = state.copyWith(
      isDiscovering: false,
      errorMessage: error,
    );
  }
}

final discoveryProvider = StateNotifierProvider<DiscoveryController, DiscoveryState>((ref) {
  return DiscoveryController();
});
