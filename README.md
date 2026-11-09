# MyTypeless (macOS)

Local, private voice dictation for macOS 26+. This repository holds only signed, notarized builds; the source is private.

## Install (Terminal)

```sh
curl -fsSL https://raw.githubusercontent.com/studioCIZMO/mytypeless-releases/main/install.sh | zsh
```

The installer downloads the latest DMG from [Releases](https://github.com/studioCIZMO/mytypeless-releases/releases/latest). It checks the Developer ID signature (team `N723QM4R64`) and Gatekeeper notarization, then installs to `/Applications` and launches the app. Run the same command again to update.

## Install (manual)

Download `MyTypeless-<version>.dmg` from [Releases](https://github.com/studioCIZMO/mytypeless-releases/releases/latest), open it, and drag MyTypeless to Applications.

On first launch, a guide walks through the four permissions: Microphone, Speech Recognition, Accessibility and Input Monitoring. After that the app checks this repository for updates.
