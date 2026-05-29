# branch_push

Branch-based code push for Flutter apps. Push a commit to a branch, and the app on your device updates automatically — no reinstall, no app store.

Built on top of [Shorebird](https://shorebird.dev), mapping git branches to Shorebird tracks so only YOUR device (watching that specific branch) receives the update. Production users are never affected.

## How It Works

```
You push to branch "feature-xyz"
  → GitHub Action triggers
  → Shorebird creates a patch on the "feature-xyz" track
  → Your device polls that track every 15 seconds
  → Patch downloaded, app restarts with new code
```

Only apps built with `BRANCH_TRACK=feature-xyz` will receive patches on that track. Your production users check the `stable` track and never see branch patches.

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Shorebird CLI](https://docs.shorebird.dev/): `curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash`
- A Shorebird account (free tier: 5,000 patch installs/month)
- A GitHub repository for your Flutter app

## Installation

```bash
dart pub global activate --source path .
```

Or from git:

```bash
dart pub global activate --source git https://github.com/YOUR_USER/branch_push.git
```

## Quick Start

### 1. Initialize in your Flutter project

```bash
cd /path/to/your/flutter/app
branch_push init
```

This will:
- Run `shorebird init` (if not already done)
- Set `auto_update: false` in `shorebird.yaml`
- Add `shorebird_code_push` to your `pubspec.yaml`
- Generate `lib/src/branch_push_updater.dart`
- Generate `.github/workflows/branch_push.yml`

### 2. Integrate the updater in your app

```dart
import 'src/branch_push_updater.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final updater = BranchPushUpdater(
    onUpdateReady: () {
      // Restart the app to apply the patch
      // Use package:flutter_phoenix or similar
    },
  );
  updater.startWatching();

  runApp(MyApp());
}
```

### 3. Create an initial release

```bash
branch_push release --branch feature-xyz --platform android
```

This builds a Shorebird release with `BRANCH_TRACK=feature-xyz` baked in and installs it on your connected device.

### 4. Add your Shorebird token to GitHub

```bash
shorebird login:ci
```

Copy the token and add it as `SHOREBIRD_TOKEN` in your GitHub repo: Settings → Secrets → Actions.

### 5. Push code and watch it update

```bash
git checkout feature-xyz
# make changes to Dart code
git add . && git commit -m "update UI" && git push
```

Within ~15 seconds, your device will download the patch and restart with the new code.

## Commands

### `branch_push init`

Initialize branch_push in a Flutter project.

| Option | Description |
|--------|-------------|
| `-d, --directory` | Path to Flutter project (default: current directory) |

### `branch_push release`

Create a Shorebird release for a specific branch track and install on device.

| Option | Description |
|--------|-------------|
| `-b, --branch` | **(required)** Branch/track name to watch |
| `-p, --platform` | `android` or `ios` (default: android) |
| `-d, --directory` | Path to Flutter project |
| `--flavor` | Build flavor |
| `-t, --target` | Main entry point |

### `branch_push install`

Install the app on a device for a specific branch track (uses `shorebird preview`).

| Option | Description |
|--------|-------------|
| `-b, --branch` | **(required)** Branch/track name to watch |
| `-p, --platform` | `android` or `ios` (default: android) |
| `--release-version` | Version to install (reads pubspec.yaml if omitted) |
| `-d, --directory` | Path to Flutter project |

## Architecture

```
┌─────────────────────────────────────────────┐
│  Your Device                                │
│  App built with BRANCH_TRACK=feature-xyz    │
│  └─ BranchPushUpdater polls "feature-xyz"   │
│     track every 15s                         │
└────────────────────┬────────────────────────┘
                     │ checks for patches
                     ▼
┌─────────────────────────────────────────────┐
│  Shorebird CDN                              │
│  Track: "feature-xyz" → patch #3            │
│  Track: "stable"      → (production)       │
└────────────────────┬────────────────────────┘
                     ▲ uploads patch
                     │
┌─────────────────────────────────────────────┐
│  GitHub Actions                             │
│  on push to "feature-xyz":                  │
│    shorebird patch --track feature-xyz      │
└─────────────────────────────────────────────┘
```

## Limitations

- **Dart code only**: Shorebird patches Dart code. Native code changes (plugins, platform code) require a new release.
- **Release mode only**: The app must be a release build. Debug mode doesn't support Shorebird.
- **Polling delay**: Default 15s polling interval. Configurable via `BranchPushUpdater(pollInterval: ...)`.
- **Restart required**: Patches apply on app restart. The updater calls `onUpdateReady` so you can trigger a restart.

## Troubleshooting

**"Shorebird CLI not found"**
Install Shorebird: `curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash`

**"No release found for version X"**
The GitHub Action needs a matching release. Run `branch_push release --branch <name>` first with the same version in `pubspec.yaml`.

**App not updating**
- Confirm the app is a release build (not debug)
- Check that `BRANCH_TRACK` matches the branch name exactly
- Verify the GitHub Action ran successfully
- Check Shorebird console for the patch status

**"Release version mismatch"**
The `--release-version` in the GitHub Action must match the version your device's app was built with. Keep `pubspec.yaml` version stable between releases.
