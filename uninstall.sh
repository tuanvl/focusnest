#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ Script này chỉ dành cho macOS."
  exit 1
fi

echo ""
echo "🧹 FocusNest — Trình gỡ cài đặt an toàn"
echo "-----------------------------------------"
echo "🔑 Vui lòng nhập mật khẩu đăng nhập máy Mac để gỡ FocusNest và khôi phục Wi-Fi"
echo "    (Khi gõ mật khẩu sẽ KHÔNG hiện ký tự hay dấu *, cứ gõ xong rồi nhấn Enter)"
sudo -v

LOCAL_UNINSTALL="/Library/Application Support/FocusNest/scripts/uninstall-macos.sh"
if [[ -f "$LOCAL_UNINSTALL" ]]; then
  sudo bash "$LOCAL_UNINSTALL"
else
  sudo bash -s <<'EOF'
set -euo pipefail
launchctl bootout system /Library/LaunchDaemons/com.songuard.daemon.plist 2>/dev/null || true
launchctl bootout system /Library/LaunchDaemons/com.songuard.cloudflared.plist 2>/dev/null || true
FW_BIN="/usr/libexec/ApplicationFirewall/socketfilterfw"
if [[ -x "$FW_BIN" ]]; then
  "$FW_BIN" --remove /usr/local/bin/songuard >/dev/null 2>&1 || true
fi
rm -f /Library/LaunchDaemons/com.songuard.daemon.plist \
      /Library/LaunchDaemons/com.songuard.cloudflared.plist \
      /usr/local/bin/songuard \
      /usr/local/bin/songuard-lock \
      /usr/local/bin/songuard-focus \
      /usr/local/bin/cloudflared \
      /etc/songuard/cloudflared.token
rm -rf "/Library/Application Support/FocusNest"

for BROWSER_DOMAIN in com.google.Chrome com.brave.Browser com.microsoft.edgemac; do
  for PREF_DIR in "/Library/Preferences" "/Library/Managed Preferences"; do
    PREF_PLIST="${PREF_DIR}/${BROWSER_DOMAIN}.plist"
    if [[ -f "$PREF_PLIST" ]]; then
      for KEY in DnsOverHttpsMode BuiltInDnsClientEnabled IncognitoModeAvailability BrowserGuestModeEnabled AllowDeletingBrowserHistory SavingBrowserHistoryDisabled QuicAllowed; do
        /usr/libexec/PlistBuddy -c "Delete :${KEY}" "$PREF_PLIST" >/dev/null 2>&1 || true
      done
      REMAINING="$(/usr/libexec/PlistBuddy -c "Print" "$PREF_PLIST" 2>/dev/null | tr -d '[:space:]' || true)"
      if [[ "$REMAINING" == "Dict{}" ]] || [[ "$REMAINING" == "{}" ]] || [[ -z "$REMAINING" ]]; then
        rm -f "$PREF_PLIST"
      fi
    fi
  done
done
killall cfprefsd 2>/dev/null || true

if networksetup -getinfo "Wi-Fi" >/dev/null 2>&1; then
  networksetup -setdnsservers "Wi-Fi" "Empty" || true
fi
dscacheutil -flushcache || true
killall -HUP mDNSResponder 2>/dev/null || true
echo "✅ Đã gỡ FocusNest và khôi phục DNS Wi-Fi về mặc định."
EOF
fi
