#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://kaz1071.github.io/chromebook-guardian"
DEST="guardian.sh"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if [[ -e "$DEST" ]]; then
  echo "Refusing to overwrite existing $DEST."
  echo "Move it or rename it, then run this installer again."
  exit 1
fi

if command -v curl >/dev/null 2>&1; then
  curl -fL --retry 2 --connect-timeout 15 "$BASE_URL/guardian.sh" -o "$TMP"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$TMP" "$BASE_URL/guardian.sh"
else
  echo "This installer needs curl or wget."
  exit 1
fi

if [[ ! -s "$TMP" ]]; then
  echo "Download failed: the file is empty."
  exit 1
fi

mv "$TMP" "$DEST"
trap - EXIT
chmod 600 "$DEST"

echo "Downloaded $DEST. It has NOT been executed."
echo "Review it first with: less $DEST"
echo "When you're satisfied, run: chmod +x $DEST && ./$DEST"
