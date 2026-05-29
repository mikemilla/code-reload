import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Watches a specific Shorebird track (mapped to a git branch) for patches.
///
/// The track is set at build time via `--dart-define=BRANCH_TRACK=<branch_name>`.
/// When a new patch is detected, it downloads the update and calls [onUpdateReady].
///
/// Usage in main.dart:
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   final updater = BranchPushUpdater(
///     onUpdateReady: () {
///       // Show a snackbar or restart the app
///       // e.g., Phoenix.rebirth(context) or Restart.restartApp()
///     },
///   );
///   updater.startWatching();
///
///   runApp(MyApp());
/// }
/// ```
class BranchPushUpdater {
  static const _branchTrack = String.fromEnvironment(
    'BRANCH_TRACK',
    defaultValue: 'stable',
  );

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  Timer? _pollTimer;

  /// How often to check for updates. Default is 15 seconds.
  final Duration pollInterval;

  /// Called when an update has been downloaded and is ready to apply on restart.
  final VoidCallback? onUpdateReady;

  /// Called when an update check encounters an error.
  final void Function(Object error)? onError;

  BranchPushUpdater({
    this.pollInterval = const Duration(seconds: 15),
    this.onUpdateReady,
    this.onError,
  });

  /// The Shorebird track this app is watching.
  UpdateTrack get track => UpdateTrack(_branchTrack);

  /// The raw track name string (branch name).
  static String get trackName => _branchTrack;

  /// Whether this app has Shorebird available (only works in release mode).
  bool get isAvailable => _updater.isAvailable;

  /// Start polling for patches on the configured branch track.
  void startWatching() {
    if (kDebugMode) {
      debugPrint('[BranchPush] Skipping — Shorebird only works in release mode.');
      return;
    }

    if (!_updater.isAvailable) {
      debugPrint('[BranchPush] Shorebird updater not available on this device.');
      return;
    }

    debugPrint('[BranchPush] Watching track: $_branchTrack (polling every ${pollInterval.inSeconds}s)');
    _checkForUpdate();
    _pollTimer = Timer.periodic(pollInterval, (_) => _checkForUpdate());
  }

  /// Stop polling for updates.
  void stopWatching() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Manually trigger a single update check.
  Future<void> checkNow() => _checkForUpdate();

  /// Read the currently installed patch number (null if no patch installed).
  Future<int?> get currentPatchNumber async {
    final patch = await _updater.readCurrentPatch();
    return patch?.number;
  }

  Future<void> _checkForUpdate() async {
    try {
      final status = await _updater.checkForUpdate(track: track);

      switch (status) {
        case UpdateStatus.outdated:
          debugPrint('[BranchPush] New patch available on track "$_branchTrack". Downloading...');
          await _updater.update(track: track);
          debugPrint('[BranchPush] Patch downloaded. Restart to apply.');
          onUpdateReady?.call();
          break;
        case UpdateStatus.upToDate:
          break;
        case UpdateStatus.restartRequired:
          debugPrint('[BranchPush] Restart required to apply pending patch.');
          onUpdateReady?.call();
          break;
        case UpdateStatus.unavailable:
          break;
      }
    } catch (e) {
      debugPrint('[BranchPush] Error checking for update: $e');
      onError?.call(e);
    }
  }

  void dispose() {
    stopWatching();
  }
}
