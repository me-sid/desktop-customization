#!/usr/bin/env bash
# One-command setup: Catppuccin Mocha GNOME desktop (Fedora, GNOME 50).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

echo "==> Packages"
sudo dnf install -y git stow gnome-tweaks kitty papirus-icon-theme unzip glib2-devel
sudo dnf install -y gnome-shell-extension-auto-move-windows || true
flatpak install -y flathub com.mattjakeman.ExtensionManager || true

echo "==> JetBrainsMono Nerd Font"
mkdir -p ~/.local/share/fonts
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
  curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz -o /tmp/JetBrainsMono.tar.xz
  tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.local/share/fonts
  fc-cache -f
fi

echo "==> Catppuccin cursor"
mkdir -p ~/.local/share/icons
curl -L https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-mauve-cursors.zip -o /tmp/cursors.zip
unzip -oq /tmp/cursors.zip -d ~/.local/share/icons

echo "==> Catppuccin GTK theme (if it asks to apply, choose No)"
rm -rf /tmp/Catppuccin-GTK-Theme
git clone --depth 1 https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git /tmp/Catppuccin-GTK-Theme
(cd /tmp/Catppuccin-GTK-Theme/themes && ./install.sh -m dark -a mauve)
T=~/.themes/Catppuccin-Mauve-Dark/gtk-4.0
mkdir -p ~/.config/gtk-4.0
ln -sf "$T/assets" ~/.config/gtk-4.0/assets
ln -sf "$T/gtk.css" ~/.config/gtk-4.0/gtk.css
ln -sf "$T/gtk-dark.css" ~/.config/gtk-4.0/gtk-dark.css

echo "==> Catppuccin folder colors"
rm -rf /tmp/papirus-folders
git clone --depth 1 https://github.com/catppuccin/papirus-folders.git /tmp/papirus-folders
sudo cp -r /tmp/papirus-folders/src/* /usr/share/icons/Papirus/
curl -L https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders -o /tmp/papirus-folders/papirus-folders
chmod +x /tmp/papirus-folders/papirus-folders
sudo /tmp/papirus-folders/papirus-folders -C cat-mocha-mauve --theme Papirus-Dark

echo "==> Search Pulse launcher extension"
rm -rf /tmp/search-pulse
git clone --depth 1 https://github.com/rezkycodes/search-pulse.git /tmp/search-pulse
UUID=$(grep -oP '"uuid":\s*"\K[^"]+' /tmp/search-pulse/metadata.json)
EXT=~/.local/share/gnome-shell/extensions/"$UUID"
mkdir -p ~/.local/share/gnome-shell/extensions
rm -rf "$EXT"
cp -r /tmp/search-pulse "$EXT"
rm -rf "$EXT/.git"
glib-compile-schemas "$EXT/schemas/"

echo "==> Linking configs with stow"
if [ -e ~/.config/kitty ] && [ ! -L ~/.config/kitty ]; then mv ~/.config/kitty ~/.config/kitty.bak; fi
stow -R kitty
chmod +x scripts/*.sh

echo "==> Workspaces"
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 5

echo "==> Loading saved GNOME settings"
load() { if [ -f "dconf/$2" ]; then dconf load "$1" < "dconf/$2"; else echo "  skipped $2 (not found)"; fi; }
load /org/gnome/desktop/interface/ interface.dconf
load /org/gnome/desktop/wm/keybindings/ wm-keybindings.dconf
load /org/gnome/shell/keybindings/ shell-keybindings.dconf
load /org/gnome/settings-daemon/plugins/media-keys/ keybindings.dconf
load /org/gnome/shell/extensions/ extensions.dconf
load /org/gnome/shell/ shell.dconf

echo "==> Wallpaper"
W=$(ls "$REPO"/wallpaper/* 2>/dev/null | head -1 || true)
if [ -n "${W:-}" ]; then
  gsettings set org.gnome.desktop.background picture-uri "file://$W"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$W"
fi

echo
echo "Done. Manual steps left:"
echo "  1. Extension Manager: install User Themes, Just Perfection, Blur my Shell, Executor, Tiling Shell"
echo "  2. Log out and back in, then enable all extensions"
