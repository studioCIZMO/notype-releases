#!/bin/zsh
# Install or update NoType (formerly MyTypeless) from the latest public release:
#   curl -fsSL https://raw.githubusercontent.com/studioCIZMO/notype-releases/main/install.sh | zsh
# The app is installed only if it is signed by our Developer ID team and passes Gatekeeper (notarized).
set -euo pipefail

repo="studioCIZMO/notype-releases"
team="N723QM4R64"
bundle_id="dev.mytypeless.app"
target="/Applications/NoType.app"
legacy="/Applications/MyTypeless.app"  # pre-rename bundle name

work="$(mktemp -d)"
mount="$work/mnt"
cleanup() { hdiutil detach -quiet -force "$mount" 2>/dev/null || true; rm -rf "$work"; [[ -n "${staged:-}" ]] && rm -rf "$staged" 2>/dev/null; true; }
trap cleanup EXIT INT TERM

print "Finding the latest release…"
url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
    | sed -nE 's/.*"browser_download_url": *"([^"]+\.dmg)".*/\1/p' | head -1)"
[[ "$url" == https://github.com/$repo/releases/download/* ]] || { print -u2 "No DMG found in the latest release"; exit 1; }

print "Downloading ${url:t}…"
curl -fL --progress-bar -o "$work/NoType.dmg" "$url"

hdiutil attach -quiet -nobrowse -readonly -noautoopen -mountpoint "$mount" "$work/NoType.dmg"
app="$mount/NoType.app"

print "Verifying signature…"
codesign --verify --strict --deep "$app"
requirement="identifier \"$bundle_id\" and anchor apple generic and certificate leaf[subject.OU] = \"$team\""
codesign --verify -R="$requirement" "$app"
spctl --assess --type execute "$app"

version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")"
osascript -e "quit app id \"$bundle_id\"" 2>/dev/null || true
while pgrep -qf "/Applications/(NoType|MyTypeless)\.app/Contents/MacOS/"; do sleep 0.2; done

print "Installing NoType $version to /Applications…"
sudo_if_needed=()
[[ -w /Applications ]] || sudo_if_needed=(sudo)  # admin users can write /Applications without sudo
# Copy next to the target and re-verify that copy, then swap; the old app is removed only after the new one is in place.
staged="/Applications/.NoType-install-$$.app"
$sudo_if_needed rm -rf "$staged"
$sudo_if_needed ditto "$app" "$staged"
codesign --verify --strict --deep -R="$requirement" "$staged"
backup=""
if [[ -e "$target" ]]; then
    backup="/Applications/.NoType-backup-$$.app"
    $sudo_if_needed mv "$target" "$backup"
fi
if ! $sudo_if_needed mv "$staged" "$target"; then
    [[ -n "$backup" ]] && $sudo_if_needed mv "$backup" "$target"
    print -u2 "Install failed; the previous version was kept"
    exit 1
fi
$sudo_if_needed rm -rf "$backup" "$legacy"

open "$target"
print "Done. NoType $version is running. Follow the permission guide on first launch."
