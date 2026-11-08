# Porchlight

Firewall approvals grouped by **who is asking**. Porchlight is a phone-friendly user interface for the
[OpenSnitch](https://github.com/evilsocket/opensnitch) application firewall: instead of a pop-up for every program and
address, it asks in plain words, once per group, and remembers the answer for the whole group.

- **"Your carrier (AT&T) wants to connect"** - the modem and mobile network services (the name comes from the SIM).
- **"The system wants to connect"** - updates, the clock, network checks, local name discovery.
- **"Chromium Web Browser wants to connect"** - one rule per installed app (helper processes count as the app).
- **"Something unknown wants to connect"** - anything else, with the full details (program, command line, user,
  addresses) one tap away.

Big Allow / Deny buttons, one request at a time, unanswered requests are denied after 30 seconds (OpenSnitch's way).
OpenSnitch's daemon does the hard part - holding each new connection, finding the program behind it, and enforcing the
rules; Porchlight replaces only its pop-up window and speaks the daemon's own protocol.

Built for the Microsoft Surface Duo (first generation) running Debian with Plasma Mobile; nothing in it is
Duo-specific.

## Install

Debian (trixie or newer):

    apt install opensnitch python3-opensnitch-ui qtwayland5
    sh install.sh             # as root

`install.sh` puts `porchlight` in `/usr/local/bin`, starts it with every graphical session, and turns the stock
OpenSnitch pop-up off for existing users (both would use the same socket). Run it by hand with `porchlight`.

## Groups

Built-in groups match programs by name (scripts by their script, so a rule for one Python tool never covers every
Python program). Add or change groups in `/etc/porchlight/groups.json` or `~/.config/porchlight/groups.json`:

    {"backup": {"title": "Your backup wants to connect", "why": "Nightly backups.", "processes": ["restic", "rclone"]}}

Settings: `PORCHLIGHT_TIMEOUT` (seconds, default 30), `PORCHLIGHT_SOCKET` (default `unix:///tmp/osui.sock`, the
daemon's `Server.Address`).

## Not yet

- **Android apps (Waydroid):** their traffic is forwarded from the container's bridge, not sent by a local program, so
  OpenSnitch does not see it. Planned: queue the bridge too and name the Android app from its user id.
- Rules can be reviewed and removed with OpenSnitch's own UI (`opensnitch-ui`) or as files in `/etc/opensnitchd/rules`.

## License

GPL-3.0-or-later (it uses OpenSnitch's GPL-3.0 protocol modules). See [LICENSE](LICENSE).

## How this was made

Written by Claude (Anthropic's AI) working on the phone end to end, with Bryson directing and testing.
