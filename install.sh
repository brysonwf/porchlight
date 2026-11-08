#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Install Porchlight (the grouped-approval UI for OpenSnitch). As root, on the device:
#   sh install.sh            -> /usr/local/bin/porchlight + autostart for every user, opensnitch-ui's autostart off
# Into a mounted root from another system: ROOT=/mnt/root sh install.sh. Needs the opensnitch + python3-opensnitch-ui
# packages (Debian: apt install opensnitch python3-opensnitch-ui qtwayland5).
set -e
R=${ROOT:-}; D=$(dirname "$0")
install -Dm755 "$D/porchlight" "$R/usr/local/bin/porchlight"
install -d "$R/etc/xdg/autostart"
cat > "$R/etc/xdg/autostart/porchlight.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Porchlight
Comment=Firewall approvals grouped by who is asking
Exec=/usr/local/bin/porchlight
Icon=security-high
NoDisplay=true
X-KDE-autostart-phase=1
EOF
# both UIs would fight over the same socket: the stock OpenSnitch UI does not autostart any more (a Hidden=true
# override in each user's ~/.config/autostart; the package's own file stays untouched)
if [ -f "$R/etc/xdg/autostart/opensnitch_ui.desktop" ]; then
  for h in "$R"/home/*; do
    [ -d "$h" ] || continue
    install -d "$h/.config/autostart"
    printf '[Desktop Entry]\nType=Application\nName=OpenSnitch\nHidden=true\n' > "$h/.config/autostart/opensnitch_ui.desktop"
    chown -R --reference="$h" "$h/.config/autostart" 2>/dev/null || true
  done
fi
echo "Porchlight installed: it starts with the next session (or run: porchlight)"
