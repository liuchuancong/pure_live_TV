import 'dart:async';

import 'package:media_core_media_kit/media_core_media_kit.dart' as mk;

/// One caller-owned loopback input handed to a kernel player at open time.
///
/// [close] is idempotent: the opener retires a replaced lease while the
/// facade's request teardown may close the same lease too.
class OwnedInputLease {
  OwnedInputLease(this.uri, {this.headers, required this.onClose});

  final Uri uri;

  /// Request headers, only for a lease that falls back to a direct remote
  /// URL — a loopback relay carries its own upstream headers.
  final Map<String, String>? headers;

  final Future<void> Function() onClose;

  Future<void>? _closing;

  /// Whether this lease is a local relay input rather than a direct remote
  /// fallback.
  bool get isLoopback => uri.host == '127.0.0.1' || uri.host == 'localhost';

  Future<void> close() => _closing ??= onClose();
}

/// Produces exactly one owned input per call.
///
/// A fresh relay (or replacement of a dead one) is acquired on every open,
/// never a reused bootstrap URL.
typedef OwnedInputRecipe = Future<OwnedInputLease> Function();

OwnedInputRecipe? asOwnedInputRecipe(Object? recipe) => recipe is OwnedInputRecipe ? recipe : null;

class _OwnedLeaseState {
  OwnedInputLease? active;
}

/// Lease bookkeeping per kernel player, so a reopen on the same engine
/// retires the input the previous open carried before starting a new one.
final Expando<_OwnedLeaseState> _ownedStates = Expando<_OwnedLeaseState>();

/// media_core `customInputOpener` for the media_kit adapter.
///
/// A source carrying [mk.kMediaKitCustomInputKey] is opened through here
/// instead of the adapter's plain `player.open(Media(uri))`. The proxy is
/// cleared per open — the adapter's session option was snapshotted at
/// creation and a loopback line must never travel through it — and the
/// lease travels with the player, not with the request.
Future<void> openOwnedInputOnKernelPlayer(dynamic player, Object recipe) async {
  final owned = asOwnedInputRecipe(recipe);
  if (owned == null) {
    throw ArgumentError.value(recipe, 'recipe', 'Not an owned-input recipe');
  }

  final mkPlayer = player as mk.Player;
  final state = _ownedStates[mkPlayer] ??= _OwnedLeaseState();
  final previous = state.active;
  state.active = null;
  if (previous != null) {
    unawaited(previous.close());
  }

  final lease = await owned();
  state.active = lease;

  try {
    if (lease.isLoopback) {
      // A loopback line must never travel through the session proxy; a
      // direct-fallback lease keeps the proxy the adapter was configured
      // with.
      final platform = mkPlayer.platform as dynamic;
      await platform.setProperty('http-proxy', '');
    }
    await mkPlayer.open(
      mk.Media(lease.uri.toString(), httpHeaders: lease.headers),
      play: true,
    );
  } catch (error) {
    if (identical(state.active, lease)) {
      state.active = null;
    }
    unawaited(lease.close());
    rethrow;
  }
}
