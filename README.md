# Timewarden xbar Plugin

Menu bar launcher for [Timewarden](https://timewarden.app) mobile development. Build, deploy, and monitor Android/iOS builds from your macOS menu bar.

## Features

- **One-click builds** on Android devices and iOS simulators/physical devices
- **Live build tracking** with elapsed time in the menu bar
- **Git status** showing branch, uncommitted changes, ahead/behind remote
- **Worktree support** with per-worktree device targeting
- **Device info** including Android version, battery level, iOS version
- **Physical iOS device** detection via `devicectl`

## Install

```bash
brew install --cask xbar
```

Launch xbar once and set a plugin directory when prompted. Then:

```bash
git clone https://github.com/nicefella1/xbar-timewarden.git
cd xbar-timewarden
./install.sh /path/to/timewarden.mobile
```

The installer will:
1. Verify xbar is installed (installs via Homebrew if missing)
2. Detect your xbar plugins directory
3. Save your project path to `~/.cache/xbar-timewarden/config`
4. Copy the plugin and trigger a refresh

### One-liner

```bash
git clone https://github.com/nicefella1/xbar-timewarden.git /tmp/xbar-tw && /tmp/xbar-tw/install.sh
```

## Uninstall

```bash
./uninstall.sh
```

## Requirements

- macOS 11+
- [xbar](https://xbarapp.com)
- [Timewarden mobile](https://github.com/gettimewarden/timewarden.mobile) checkout with `run.sh` / `run-ios.sh`
- Android SDK (for Android builds)
- Xcode (for iOS builds)

## Configuration

The config lives at `~/.cache/xbar-timewarden/config`:

```bash
TIMEWARDEN_PROJECT="/path/to/timewarden.mobile"
```

Edit this file to change the project path. The plugin re-reads it on every refresh (every 30 seconds).

## Menu Structure

```
[tw icon]                           <- menu bar (shows build status when active)
|--------------------------------------------|
| ⎇ main · 1↑ · 8 changed          <- git status: branch, sync, dirty files
|   89122a4 chore: rename logger..  <- last commit
|   8 uncommitted changes           <- dirty count
|   1 ahead of remote               <- push reminder
|--------------------------------------------|
| 🤖 Android · 1 device             <- section header
|   ▶ Run                           <- default action
|   🔋 SM-S936B · A16 · 79%        <- device with battery info
|--------------------------------------------|
|  iOS · 1 device, 5 sims          <- section header
|   🔌 iPhone 16 · iOS 26.4        <- physical device (USB)
|   📱 iPhone 17 Pro               <- simulator
|   📱 iPhone 17 Pro Max
|   ...
|--------------------------------------------|
| 🔄 Refresh                        <- refresh plugin
| Preferences                       <- open xbar
|--------------------------------------------|
```

## License

MIT
