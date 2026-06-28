# Claude Desktop Account Switcher

A lightweight GUI tool to switch between multiple [Claude Desktop](https://github.com/aaddrick/claude-desktop-debian) accounts on Linux — no re-logging in required.

![Bash](https://img.shields.io/badge/bash-4%2B-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## The Problem

Claude Desktop is an Electron app that stores session data in `~/.config/Claude/`. Electron encrypts this data using a key stored in the **GNOME Keyring** (`libsecret` / `safeStorage` API). This means:

- You can't just copy the config folder between accounts — the encryption key won't match and Claude forces you to log in again.
- There's no built-in multi-account support in Claude Desktop.
- Every existing account switcher tool (CCSwitcher, claude-multi-account, claude-account-switcher) is **macOS-only**.

## The Solution

Instead of copying session files, this tool gives each account its own **permanent isolated directory** and launches Claude Desktop with `--user-data-dir` pointing to it. No copying, no keyring mismatch, no forced re-login.

```
~/.config/Claude-accounts/
├── personal/     ← Account 1 lives here permanently
├── work/         ← Account 2 lives here permanently
└── .current      ← Tracks which account is active
```

Switching just kills Claude and relaunches it pointing at the right folder.

---

## Compatibility

| Platform | Status | Notes |
|----------|--------|-------|
| **Fedora 44 Workstation (GNOME)** | ✅ Tested & working | Primary target |
| Ubuntu 22.04+ (GNOME) | ✅ Should work | Zenity + claude-desktop required |
| Debian 12+ (GNOME) | ✅ Should work | Zenity + claude-desktop required |
| Arch Linux (GNOME) | ✅ Should work | Install zenity from pacman |
| Linux (KDE Plasma) | ⚠️ Partial | Zenity works but looks non-native |
| Linux (other DEs) | ⚠️ Untested | Needs zenity installed |
| **macOS** | ❌ Not supported | Use [CCSwitcher](https://github.com/XueshiQiao/CCSwitcher) instead |
| **Windows** | ❌ Not supported | Use [claude-profile-switcher](https://github.com/NeezerGu/claude-profile-switcher) instead |
| Claude Code CLI | ❌ Wrong tool | Use [claude-swap](https://github.com/realiti4/claude-swap) instead |

**Required:**
- [claude-desktop](https://github.com/aaddrick/claude-desktop-debian) — unofficial Linux port of Claude Desktop (aaddrick build)
- `zenity` — GNOME GTK dialog tool (pre-installed on most GNOME distros)
- `bash` 4+

---

## Installation

### One command

```bash
git clone https://github.com/Adam-Zaghloul/claude-desktop-switcher.git
cd claude-desktop-switcher
bash install.sh
```

The installer will:
- Install `zenity` automatically if missing (via `dnf`, `apt`, or `pacman`)
- Copy the script to `~/.local/bin/claude-switcher.sh`
- Add a **Claude Switcher** entry to your GNOME app launcher

### Manual install

```bash
# Copy the script
mkdir -p ~/.local/bin
cp claude-switcher.sh ~/.local/bin/claude-switcher.sh
chmod +x ~/.local/bin/claude-switcher.sh

# Add to app launcher
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/claude-switcher.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Switcher
Comment=Switch between Claude Desktop accounts
Exec=bash /home/$USER/.local/bin/claude-switcher.sh
Icon=claude-desktop
Terminal=false
Categories=Utility;
Keywords=claude;account;switch;
StartupNotify=false
EOF

update-desktop-database ~/.local/share/applications/
```

---

## Usage

Run from terminal:
```bash
bash ~/.local/bin/claude-switcher.sh
```

Or search **Claude Switcher** in your GNOME app launcher (Super key).

### First-time setup

1. Open Claude Switcher → **Add new account**
2. Give it a name (e.g. `personal`, `work`, `free`)
3. Claude Desktop opens a fresh window — wait ~20 seconds for the login page
4. Log into your account
5. Repeat for each additional account

### Switching accounts

1. Open Claude Switcher → **Switch account**
2. Select the account you want
3. Claude Desktop closes and relaunches into that account (~5–10 seconds)

### Menu options

| Option | What it does |
|--------|--------------|
| 🔄 Switch account | Pick a saved account and relaunch Claude into it |
| ➕ Add new account | Create a fresh isolated session and log in |
| 🗑️ Remove account | Delete a saved session from disk |
| ℹ️ Status | Show active account, running state, and all saved accounts |

---

## How It Works

### Why other approaches fail

Most Linux account switcher attempts work by copying `~/.config/Claude/` between profiles. This fails because:

1. Claude Desktop uses Electron's `safeStorage` API
2. On GNOME, `safeStorage` stores an encryption key in **GNOME Keyring** (`libsecret`)
3. The Local Storage files in `~/.config/Claude/` are encrypted with that key
4. When you copy the folder to another profile and restore it, the keyring key no longer matches → Claude can't decrypt the session → forces login

### Why this tool works

Each account gets a permanent directory under `~/.config/Claude-accounts/<name>/`. Claude Desktop is launched with:

```bash
claude-desktop --user-data-dir="$HOME/.config/Claude-accounts/<name>"
```

This tells Electron to use that directory as its entire data root — cookies, Local Storage, cache, everything. Each directory has its own isolated safeStorage key in the keyring, tied permanently to that path. No copying ever happens, so there's no keyring mismatch.

---

## File Structure

```
~/.config/Claude-accounts/
├── personal/
│   ├── Cookies
│   ├── Local Storage/
│   ├── Session Storage/
│   └── ...
├── work/
│   └── ...
└── .current          ← name of the currently active account

~/.local/bin/
└── claude-switcher.sh

~/.local/share/applications/
└── claude-switcher.desktop
```

---

## Uninstall

```bash
rm ~/.local/bin/claude-switcher.sh
rm ~/.local/share/applications/claude-switcher.desktop
update-desktop-database ~/.local/share/applications/

# Optional: remove all saved account sessions
rm -rf ~/.config/Claude-accounts/
```

---

## Related Tools

| Tool | Platform | For |
|------|----------|-----|
| [claude-swap](https://github.com/realiti4/claude-swap) | Linux / macOS / Windows | Claude Code CLI |
| [CCSwitcher](https://github.com/XueshiQiao/CCSwitcher) | macOS | Claude Code (menu bar) |
| [claude-profile-switcher](https://github.com/NeezerGu/claude-profile-switcher) | Windows | Claude Desktop |
| [claude-desktop-debian](https://github.com/aaddrick/claude-desktop-debian) | Linux | Claude Desktop itself |

---

## License

MIT — see [LICENSE](LICENSE)
