import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class BeaconState {
  final bool isActive;
  final bool isSending;
  final DateTime? lastSent;

  const BeaconState({
    this.isActive = false,
    this.isSending = false,
    this.lastSent,
  });

  BeaconState copyWith({bool? isActive, bool? isSending, DateTime? lastSent}) {
    return BeaconState(
      isActive: isActive ?? this.isActive,
      isSending: isSending ?? this.isSending,
      lastSent: lastSent ?? this.lastSent,
    );
  }
}

class BeaconStateNotifier extends StateNotifier<BeaconState> {
  BeaconStateNotifier() : super(const BeaconState());

  Future<void> sendBeacon() async {
    state = state.copyWith(isSending: true);
    try {
      await ApiService.sendBeacon();
      state = state.copyWith(
        isActive: true,
        isSending: false,
        lastSent: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isSending: false);
      rethrow;
    }
  }
}

final beaconStateProvider =
    StateNotifierProvider<BeaconStateNotifier, BeaconState>((ref) {
  return BeaconStateNotifier();
});
