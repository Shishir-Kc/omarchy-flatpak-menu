# Omarchy Flatpak Menu

Adds a **Flatpak Apps** submenu to Omarchy's Install menu with curated applications and a fuzzy-search interface for browsing all of Flathub.

## Features

- [PKG] **Curated Categories** - 40+ popular apps organized by category (Browsers, Communication, Development, Media, Gaming, Utilities)
- [SEARCH] **Flathub Search** - fzf-based fuzzy finder (like `omarchy-pkg-install`) to browse ALL ~2000 Flathub apps
- [FAST] **Smart Guards** - Apps auto-hide when already installed via Flatpak
- [SYNC] **Auto-refresh** - Survives `omarchy update` config refreshes
- [CLEAN] **Clean Uninstall** - Removes everything completely

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
└── Flatpak Apps [FLATPAK]
    ├── [SEARCH] Search Flathub...          <- Opens fzf search (ALL Flathub apps)
    ├── [WEB] Browsers
    │   ├── [FIREFOX] Firefox (Flatpak)
    │   ├── [CHROME] Chrome (Flatpak)
    │   ├── [BRAVE] Brave Browser (Flatpak)
    │   ├── [EDGE] Microsoft Edge (Flatpak)
    │   ├── [ZEN] Zen Browser (Flatpak)
    │   └── [VIVALDI] Vivaldi (Flatpak)
    ├── [CHAT] Communication
    │   ├── [DISCORD] Discord (Flatpak)
    │   ├── [SLACK] Slack (Flatpak)
    │   ├── [SIGNAL] Signal (Flatpak)
    │   ├── [TELEGRAM] Telegram (Flatpak)
    │   ├── [WHATSAPP] WhatsApp (Flatpak)
    │   ├── [ELEMENT] Element (Flatpak)
    │   └── [THUNDERBIRD] Thunderbird (Flatpak)
    ├── [DEV] Development
    │   ├── [VSCODE] VS Code (Flatpak)
    │   ├── [CURSOR] Cursor (Flatpak)
    │   ├── [ZED] Zed (Flatpak)
    │   ├── [GITHUB] GitHub Desktop (Flatpak)
    │   ├── [DOCKER] Docker Desktop (Flatpak)
    │   ├── [POSTMAN] Postman (Flatpak)
    │   ├── [INSOMNIA] Insomnia (Flatpak)
    │   ├── [DBEAVER] DBeaver (Flatpak)
    │   └── [ANDROID] Android Studio (Flatpak)
    ├── [MEDIA] Media
    │   ├── [SPOTIFY] Spotify (Flatpak)
    │   ├── [VLC] VLC (Flatpak)
    │   ├── [OBS] OBS Studio (Flatpak)
    │   ├── [KDENLIVE] Kdenlive (Flatpak)
    │   ├── [GIMP] GIMP (Flatpak)
    │   ├── [INKSCAPE] Inkscape (Flatpak)
    │   ├── [BLENDER] Blender (Flatpak)
    │   ├── [AUDACITY] Audacity (Flatpak)
    │   └── [HANDBRAKE] HandBrake (Flatpak)
    ├── [GAME] Gaming
    │   ├── [STEAM] Steam (Flatpak)
    │   ├── [HEROIC] Heroic Games Launcher (Flatpak)
    │   ├── [LUTRIS] Lutris (Flatpak)
    │   ├── [BOTTLES] Bottles (Flatpak)
    │   ├── [MANGOHUD] MangoHud (Flatpak)
    │   ├── [GAMEMODE] GameMode (Flatpak)
    │   └── [PRISM] Prism Launcher (Flatpak)
    └── [TOOLS] Utilities
        ├── [BITWARDEN] Bitwarden (Flatpak)
        ├── [KEEPASSXC] KeePassXC (Flatpak)
        ├── [ONLYOFFICE] ONLYOFFICE (Flatpak)
        ├── [LIBREOFFICE] LibreOffice (Flatpak)
        ├── [OBSIDIAN] Obsidian (Flatpak)
        ├── [NOTION] Notion (Flatpak)
        ├── [FLATSEAL] Flatseal (Flatpak)
        ├── [WAREHOUSE] Warehouse (Flatpak)
        ├── [QBITTORRENT] qBittorrent (Flatpak)
        └── [TRANSMISSION] Transmission (Flatpak)
```

### Search Flathub (fzf)

Select **[SEARCH] Search Flathub...** to open the fuzzy finder:

```
Flatpak Apps from Flathub | TAB=multi-select | ALT-p=preview | ENTER=install
+---------------------------------------------------------------+
| Search: discord_                                              |
+---------------------------------------------------------------+
| > com.discordapp.Discord     Discord       Chat for Communities|
|   com.rtosta.zapzap          WhatsApp      Unofficial WhatsApp|
|   org.telegram.desktop       Telegram      Official Telegram  |
+---------------------------------------------------------------+
| Preview: flatpak remote-info flathub com.discordapp.Discord  |
|                                                              |
|   ID:          com.discordapp.Discord                        |
|   Name:        Discord                                       |
|   Summary:     Chat for Communities and Friends              |
|   Description: Discord is a voice, video and text           |
|                communication service...                      |
|   Version:     0.0.27                                        |
|   Install:     123.4 MB                                      |
|   Runtime:     org.freedesktop.Platform/x86_64/24.08        |
+---------------------------------------------------------------+
| TAB=multi | ALT-p=preview | ENTER=install                     |
+---------------------------------------------------------------+
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