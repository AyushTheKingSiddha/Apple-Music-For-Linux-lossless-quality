# Apple Music lossless on Linux (Ubuntu)

Runs the official Apple Music Android app in [Waydroid](https://waydro.id) so you get **lossless (ALAC) playback on Linux**, which the web player and Linux clients like Cider can't do (they're limited to 256 kbps AAC).

One script installs and configures everything. Step-by-step instructions for non-technical users are in [GUIDE.txt](GUIDE.txt).

## Quick start

1. Set a password on your Apple account at https://account.apple.com (use "Forgot password?" if you only ever signed in with an email code).
2. Download **Apple Music 4.7.0** (x86_64 / nodpi variant) from [APKMirror](https://www.apkmirror.com/apk/apple/apple-music/apple-music-4-7-0-release/) and put the `.apk` next to `setup.sh`.
3. Run, as your normal user, on a Wayland session:
   ```bash
   bash setup.sh
   ```
4. Open Apple Music from your app menu, sign in, and turn on Settings → Audio Quality → Lossless.

## What the script does

- Installs Waydroid (with Google apps) from the official repo.
- Pins Waydroid to your Intel/AMD GPU (NVIDIA doesn't work and leaves Android stuck on a black screen).
- Makes Android report a retail Pixel 5 build: Apple Music refuses to sign in on Waydroid's default developer build.
- Fixes Android's internet when `ufw` or Docker block forwarding.
- Opens Android apps in normal windows instead of fullscreen.
- Installs the Apple Music APK you downloaded.

## Limits

- **24-bit/48 kHz max.** Waydroid's audio is fixed at 48 kHz, so Hi-Res Lossless (96/192 kHz) isn't possible, and output is not bit-perfect.
- **Don't update Apple Music.** Version 7.x fails sign-in (`commerceAuthenticationFailed`) on Waydroid. 4.7.0 is the newest version tested; it has the Favourite Songs playlist.
- NVIDIA-only machines aren't supported (Waydroid needs Intel or AMD graphics).
- Apple can block old app versions at any time.

## Undo

```bash
waydroid session stop
sudo apt remove waydroid
sudo rm -rf /var/lib/waydroid ~/.local/share/waydroid
```

## Notes

This repo doesn't include or modify the Apple Music app, and doesn't bypass its DRM. You need your own Apple Music subscription. Not affiliated with Apple.

Credits: [Ivon's Blog](https://ivonblog.com/en-us/posts/play-apple-music-android-on-linux/) and [this gist](https://gist.github.com/sohamukute/076ff3f4a40ee5dbc9acbe226cee2b95) for the Waydroid approach.
