# Omarchy Flatpak Menu

Adds a **Flatpak Apps** submenu to Omarchy's Install menu with curated applications and a fuzzy-search interface for browsing all of Flathub.

## Features

- 📦 **Curated Categories** - 40+ popular apps organized by category (Browsers, Communication, Development, Media, Gaming, Utilities)
- 🔍 **Flathub Search** - fzf-based fuzzy finder (like `omarchy-pkg-install`) to browse ALL ~2000 Flathub apps
- ⚡ **Smart Guards** - Apps auto-hide when already installed via Flatpak
- 🔄 **Auto-refresh** - Survives `omarchy update` config refreshes
- 🗑️ **Clean Uninstall** - Removes everything completely

## Installation

```bash
# One-liner install
curl -sSL https://raw.githubusercontent.com/omarchy/omarchy-flatpak-menu/main/install.sh | bash

# Or clone and run locally
git clone https://github.com/omarchy/omarchy-flatpak-menu
cd omarchy-flatpak-menu
./install.sh
```

Then restart the Omarchy shell:
```bash
omarchy restart shell
```

## Usage

Open the Omarchy menu (`Super+Space` by default) and navigate to:

```
Install
└── Flatpak Apps 󰏓
    ├── 🔍 Search Flathub…          ← Opens fzf search (ALL Flathub apps)
    ├── Browsers 
    │   ├── Firefox (Flatpak)
    │   ├── Chrome (Flatpak)
    │   ├── Brave Browser (Flatpak)
    │   ├── Microsoft Edge (Flatpak)
    │   ├── Zen Browser (Flatpak)
    │   └── Vivaldi (Flatpak)
    ├── Communication 󰭹
    │   ├── Discord (Flatpak)
    │   ├── Slack (Flatpak)
    │   ├── Signal (Flatpak)
    │   ├── Telegram (Flatpak)
    │   ├── WhatsApp (Flatpak)
    │   ├── Element (Flatpak)
    │   └── Thunderbird (Flatpak)
    ├── Development 󰵮
    │   ├── VS Code (Flatpak)
    │   ├── Cursor (Flatpak)
    │   ├── Zed (Flatpak)
    │   ├── GitHub Desktop (Flatpak)
    │   ├── Docker Desktop (Flatpak)
    │   ├── Postman (Flatpak)
    │   ├── Insomnia (Flatpak)
    │   ├── DBeaver (Flatpak)
    │   └── Android Studio (Flatpak)
    ├── Media 󰓇
    │   ├── Spotify (Flatpak)
    │   ├── VLC (Flatpak)
    │   ├── OBS Studio (Flatpak)
    │   ├── Kdenlive (Flatpak)
    │   ├── GIMP (Flatpak)
    │   ├── Inkscape (Flatpak)
    │   ├── Blender (Flatpak)
    │   ├── Audacity (Flatpak)
    │   └── HandBrake (Flatpak)
    ├── Gaming 
    │   ├── Steam (Flatpak)
    │   ├── Heroic Games Launcher (Flatpak)
    │   ├── Lutris (Flatpak)
    │   ├── Bottles (Flatpak)
    │   ├── MangoHud (Flatpak)
    │   ├── GameMode (Flatpak)
    │   └── Prism Launcher (Flatpak)
    └── Utilities 󰏓
        ├── Bitwarden (Flatpak)
        ├── KeePassXC (Flatpak)
        ├── ONLYOFFICE (Flatpak)
        ├── LibreOffice (Flatpak)
        ├── Obsidian (Flatpak)
        ├── Notion (Flatpak)
        ├── Flatseal (Flatpak)
        ├── Warehouse (Flatpak)
        ├── qBittorrent (Flatpak)
        └── Transmission (Flatpak)
```

### Search Flathub (fzf)

Select **🔍 Search Flathub…** to open the fuzzy finder:

```
Flatpak Apps from Flathub | TAB=multi-select | ALT-p=preview | ENTER=install
┌─────────────────────────────────────────────────────────────────────┐
│ Search: discord_                                                    │
├─────────────────────────────────────────────────────────────────────┤
│ ▸ com.discordapp.Discord     Discord       Chat for Communities    │
│   com.rtosta.zapzap          WhatsApp      Unofficial WhatsApp     │
│   org.telegram.desktop       Telegram      Official Telegram       │
├─────────────────────────────────────────────────────────────────────┤
│ Preview: flatpak remote-info flathub com.discordapp.Discord       │
│                                                                    │
│   ID:          com.discordapp.Discord                              │
│   Name:        Discord                                             │
│   Summary:     Chat for Communities and Friends                    │
│   Description: Discord is a voice, video and text communication   │
│                service...                                          │
│   Version:     0.0.27                                              │
│   Install:     123.4 MB                                            │
│   Runtime:     org.freedesktop.Platform/x86_64/24.08              │
└─────────────────────────────────────────────────────────────────────┘
```

**Controls:**
- `Tab` - Multi-select multiple apps
- `Alt-p` - Toggle preview pane
- `Alt-j/k` - Scroll preview
- `Alt-d/u` - Half-page scroll preview
- `Enter` - Install selected app(s)

## Uninstall

```bash
# Via installed uninstaller
~/.local/share/omarchy-flatpak-menu/uninstall.sh

# Or one-liner
curl -sSL https://raw.githubusercontent.com/omarchy/omarchy-flatpak-menu/main/uninstall.sh | bash
```

Then restart the shell:
```bash
omarchy restart shell
```

## How It Works

### Menu Integration
Appends entries to `~/.config/omarchy/extensions/omarchy-menu.jsonc` which Omarchy's menu watches for changes (hot-reloads automatically).

Each app entry uses a `when` guard:
```jsonc
"when": "command -v flatpak >/dev/null && ! flatpak info org.mozilla.firefox"
```
- Hides if Flatpak isn't installed
- Hides if the app is already installed via Flatpak

### Search Implementation
`omarchy-flatpak-install` uses `flatpak remote-ls flathub --app --columns=application,name,description` to fetch all apps, caches the list for 1 hour, and pipes to fzf with the same keybindings as `omarchy-pkg-install`.

### Auto-refresh Hook
A hook at `~/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh` re-applies menu entries after `omarchy update` if they were removed by a config refresh.

## Requirements

- Omarchy Linux (Arch-based)
- `flatpak` (auto-installed if missing)
- `fzf` (pre-installed on Omarchy)
- Omarchy shell commands (`omarchy-launch-floating-terminal-with-presentation`, `omarchy-show-done`, `omarchy-pkg-add`)

## File Locations

| Component | Location |
|-----------|----------|
| Search script | `~/.local/bin/omarchy-flatpak-install` |
| Helper script | `~/.local/bin/omarchy-ensure-flatpak` |
| Menu entries | `~/.config/omarchy/extensions/omarchy-menu.jsonc` |
| Update hook | `~/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh` |
| Cache | `~/.cache/omarchy-flatpak-apps.tsv` |
| Uninstaller | `~/.local/share/omarchy-flatpak-menu/uninstall.sh` |

## Customization

To add your own curated apps, edit the menu JSONC and re-run the install script, or manually append to `~/.config/omarchy/extensions/omarchy-menu.jsonc` following the same pattern.

## License

MIT License - Free to use, modify, and distribute.