#!/bin/bash
# Made by AyushTheKingSiddha (https://github.com/AyushTheKingSiddha). All rights reserved; see LICENSE.
# Installs Waydroid and Apple Music 4.7.0 (lossless) on Ubuntu.
# Usage: bash setup.sh   (run from this folder, as your normal user, not with sudo)
set -e
cd "$(dirname "$0")"

say()  { printf '\n\033[1;32m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$1"; exit 1; }

[ "$(id -u)" != 0 ] || fail "Don't use sudo. Just run: bash setup.sh"
[ "$XDG_SESSION_TYPE" = wayland ] || fail "You are not on Wayland. Log out, click the gear icon at the login screen, pick 'Ubuntu' (not 'Ubuntu on Xorg'), log in, and run this again."
APK=$(ls com.apple.android.music_*.apk 2>/dev/null | head -1)
[ -n "$APK" ] || fail "The Apple Music .apk file must be in this same folder."

say "Step 1/6: Installing Waydroid (enter your laptop password if asked)"
sudo apt-get update -qq
sudo apt-get install -y curl ca-certificates
if ! command -v waydroid >/dev/null; then
  curl -fsSL https://repo.waydro.id | sudo bash
  sudo apt-get install -y waydroid
fi

say "Step 2/6: Downloading Android (about 800 MB, can take a while)"
[ -f /var/lib/waydroid/images/system.img ] || sudo waydroid init -s GAPPS

say "Step 3/6: Configuring graphics, device identity and network"
CFG=/var/lib/waydroid/waydroid.cfg
sudo cp -n "$CFG" "$CFG.bak"
# Waydroid can't use NVIDIA graphics; pin the first Intel/AMD GPU.
GPU=""
for n in /dev/dri/renderD*; do
  drv=$(basename "$(readlink -f /sys/class/drm/$(basename "$n")/device/driver)")
  [ "$drv" != nvidia ] && { GPU=$n; break; }
done
[ -n "$GPU" ] || fail "Only an NVIDIA graphics card was found. Waydroid needs Intel or AMD graphics."
sudo sed -i '/^drm_device/d' "$CFG"
sudo sed -i "/^\[waydroid\]/a drm_device = $GPU" "$CFG"
# Report a retail Pixel build (Apple Music refuses developer/rooted builds); [properties] is the last section.
FP="google/redfin/redfin:13/TQ3A.230901.001/10750268:user/release-keys"
sudo sed -i '/^ro\.\(build\|system\.build\|vendor\.build\|bootimage\.build\|odm\.build\|system_ext\.build\|vendor_dlkm\.build\|product\)\./d; /^persist\.waydroid\.\(fake_wifi\|multi_windows\)/d' "$CFG"
sudo tee -a "$CFG" >/dev/null <<EOF
ro.build.type = user
ro.build.tags = release-keys
ro.build.fingerprint = $FP
ro.system.build.fingerprint = $FP
ro.vendor.build.fingerprint = $FP
ro.bootimage.build.fingerprint = $FP
ro.odm.build.fingerprint = $FP
ro.system_ext.build.fingerprint = $FP
ro.vendor_dlkm.build.fingerprint = $FP
ro.product.brand = google
ro.product.manufacturer = Google
ro.product.model = Pixel 5
ro.product.name = redfin
ro.product.device = redfin
persist.waydroid.fake_wifi = com.apple.android.music
persist.waydroid.multi_windows = true
EOF
# Firewall and Docker block Android's internet by default.
if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
  # Only Waydroid's interface: DNS/DHCP in, and routing in/out.
  sudo ufw allow in on waydroid0 to any port 53
  sudo ufw allow in on waydroid0 to any port 67
  sudo ufw route allow in on waydroid0
  sudo ufw route allow out on waydroid0
fi
if command -v docker >/dev/null; then
  # Docker drops forwarded traffic; let only waydroid0 through via DOCKER-USER (re-added on every Docker start).
  RULES='iptables -C DOCKER-USER -i waydroid0 -j ACCEPT 2>/dev/null || iptables -I DOCKER-USER -i waydroid0 -j ACCEPT; iptables -C DOCKER-USER -o waydroid0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || iptables -I DOCKER-USER -o waydroid0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT'
  sudo mkdir -p /etc/systemd/system/docker.service.d
  printf '[Service]\nExecStartPost=/bin/sh -c "%s"\n' "$RULES" | sudo tee /etc/systemd/system/docker.service.d/waydroid-forward.conf >/dev/null
  sudo systemctl daemon-reload
  sudo sh -c "$RULES" || true  # DOCKER-USER exists only while Docker runs; the drop-in covers the next start
fi

say "Step 4/6: Applying settings"
waydroid session stop >/dev/null 2>&1 || true
sudo systemctl stop waydroid-container
sudo waydroid upgrade --offline
sudo systemctl enable --now waydroid-container

say "Step 5/6: Starting Android (first start can take 2-3 minutes)"
waydroid session start >/dev/null 2>&1 &
for i in $(seq 1 90); do
  [ "$(waydroid prop get sys.boot_completed 2>/dev/null)" = 1 ] && break
  sleep 2
done
[ "$(waydroid prop get sys.boot_completed 2>/dev/null)" = 1 ] || fail "Android did not start. Restart the laptop and run this script again."

say "Step 6/6: Installing Apple Music"
waydroid app install "$APK"
sleep 5
waydroid app list | grep -q com.apple.android.music || fail "Apple Music did not install. Run the script again."

say "All done! Open 'Apple Music' from your app menu (it may take a minute to show up)."
echo "Next: follow 'After the script' in GUIDE.txt."
