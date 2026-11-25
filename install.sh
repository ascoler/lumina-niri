#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

echo "==> Installing Arch Linux dependencies..."
sudo pacman -S --needed --noconfirm \
    niri quickshell awww matugen cava brightnessctl wlsunset \
    satty grim slurp hyprpicker wl-clipboard cliphist playerctl \
    alacritty kitty hyprlock fastfetch starship inter-font \
    ttf-jetbrains-mono-nerd python-pillow networkmanager bluez-utils

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.cache/theme" \
    "$HOME/.cache/lumina" "$HOME/.local/share/lumina" "$BACKUP_DIR"

link_item() {
    local src="$1"
    local dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "  Backing up $dst -> $BACKUP_DIR/"
        mv "$dst" "$BACKUP_DIR/"
    fi
    ln -sfn "$src" "$dst"
}

echo "==> Linking configuration directories..."
mkdir -p "$HOME/.config/niri" "$HOME/.config/quickshell" "$HOME/.config/systemd/user" "$HOME/.config/waybar/scripts"
link_item "$DOTFILES_DIR/.config/niri/config.kdl" "$HOME/.config/niri/config.kdl"
link_item "$DOTFILES_DIR/.config/quickshell/lumina" "$HOME/.config/quickshell/lumina"
link_item "$DOTFILES_DIR/.config/systemd/user/lumina-shell.service" "$HOME/.config/systemd/user/lumina-shell.service"
link_item "$DOTFILES_DIR/.config/waybar/scripts/waybar-wttr.py" "$HOME/.config/waybar/scripts/waybar-wttr.py"

for cfg in alacritty kitty fastfetch hypr hyprlock rofi cava; do
    if [ -d "$DOTFILES_DIR/.config/$cfg" ]; then
        link_item "$DOTFILES_DIR/.config/$cfg" "$HOME/.config/$cfg"
    fi
done
[ -f "$DOTFILES_DIR/.config/starship.toml" ] && link_item "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

echo "==> Linking helper scripts..."
for bin in "$DOTFILES_DIR"/.local/bin/*; do
    chmod +x "$bin"
    ln -sfn "$bin" "$HOME/.local/bin/$(basename "$bin")"
done

[ -f "$HOME/.local/share/lumina/notes.md" ] || printf "# Quick Scratchpad\n" > "$HOME/.local/share/lumina/notes.md"

echo "==> Enabling Lumina Shell systemd user service..."
systemctl --user disable --now waybar.service swaync.service swayosd.service 2>/dev/null || true
systemctl --user daemon-reload
systemctl --user enable --now lumina-shell.service

echo "==> Indexing wallpapers & generating initial palette..."
[ -f "$HOME/.cache/theme/bar_style" ] || printf "aurora\n" > "$HOME/.cache/theme/bar_style"
[ -x "$HOME/.local/bin/rice-wallpaper-index" ] && "$HOME/.local/bin/rice-wallpaper-index" || true
[ -x "$HOME/.local/bin/rice-theme-generator" ] && "$HOME/.local/bin/rice-theme-generator" || true

echo "Done! Reload Niri with: niri msg action load-config-file"
