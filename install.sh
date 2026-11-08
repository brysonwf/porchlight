#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Install Porchlight (the grouped-approval UI for OpenSnitch). As root, on the device:
#   sh install.sh            -> /usr/local/bin/porchlight + autostart for every user, opensnitch-ui's autostart off
# Into a mounted root from another system: ROOT=/mnt/root sh install.sh. Needs the opensnitch + python3-opensnitch-ui
# packages (Debian: apt install opensnitch python3-opensnitch-ui qtwayland5).
set -e
export LANG=C.UTF-8          # kwriteconfig (Qt) complains loudly under the plain C locale
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
# KWin (Plasma): a window rule keeps Porchlight's cards above everything else and lets them take focus - on Wayland
# a normal window cannot ask for that itself (a card behind the browser timed out to deny, 2026-11-08)
KW=$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)
for h in "$R"/home/*; do
  [ -d "$h" ] && [ -n "$KW" ] || continue
  f="$h/.config/kwinrulesrc"; install -d "$h/.config"
  rules=$($KW --help > /dev/null 2>&1; grep -m1 '^rules=' "$f" 2>/dev/null | cut -d= -f2)
  case ",$rules," in *,porchlight,*) ;; *) rules=${rules:+$rules,}porchlight ;; esac
  $KW --file "$f" --group General --key rules "$rules"
  $KW --file "$f" --group General --key count "$(echo "$rules" | tr ',' '\n' | grep -c .)"
  for kv in "Description=Porchlight: firewall cards on top" wmclass=porchlight wmclassmatch=1 wmclasscomplete=false \
            above=true aboverule=2 fsplevel=0 fsplevelrule=2 skiptaskbar=false; do
    $KW --file "$f" --group porchlight --key "${kv%%=*}" "${kv#*=}"
  done
  chown --reference="$h" "$f" 2>/dev/null || true
done
# running sessions pick the rule up at once
command -v dbus-send > /dev/null && for b in /run/user/*/bus; do
  u=$(stat -c %U "$b" 2>/dev/null) || continue
  su "$u" -c "DBUS_SESSION_BUS_ADDRESS=unix:path=$b dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure" 2>/dev/null || true
done
echo "Porchlight installed: it starts with the next session (or run: porchlight)"
