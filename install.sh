#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ FocusNest hiện hỗ trợ cho máy tính Mac (macOS Apple Silicon & Intel)."
  exit 1
fi

RELEASE_BASE="https://github.com/tuanvl/focusnest/releases/latest/download"
TMP_DIR="$(mktemp -d /tmp/focusnest-install.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo "🛡️  Chào mừng ba mẹ đến với FocusNest cho MacBook"
echo "--------------------------------------------------"
echo "⬇️  [1/3] Đang tải bộ cài FocusNest (hỗ trợ cả chip Apple Silicon & Intel)..."

curl -fsSL "$RELEASE_BASE/focusnest-macos-universal.tar.gz" -o "$TMP_DIR/focusnest-macos-universal.tar.gz"
curl -fsSL "$RELEASE_BASE/checksums.txt" -o "$TMP_DIR/checksums.txt"

echo "🔐 [2/3] Đang kiểm tra tính toàn vẹn SHA-256 của bộ cài..."
grep "focusnest-macos-universal.tar.gz" "$TMP_DIR/checksums.txt" > "$TMP_DIR/checksum.single.txt"
(cd "$TMP_DIR" && shasum -a 256 -c checksum.single.txt >/dev/null)

tar -xzf "$TMP_DIR/focusnest-macos-universal.tar.gz" -C "$TMP_DIR"

echo "🔑 [3/3] Vui lòng nhập mật khẩu đăng nhập máy Mac để cài đặt hệ thống bảo vệ"
echo "    (Lưu ý: khi gõ mật khẩu trên Terminal sẽ KHÔNG hiện ký tự hay dấu *, cứ gõ xong rồi nhấn Enter)"
sudo -v

sudo bash "$TMP_DIR/scripts/install-macos.sh" --init-family --open-browser

echo ""
echo "🎉 Hoàn tất! Nếu trình duyệt chưa tự mở, hãy truy cập: http://localhost:8080"
