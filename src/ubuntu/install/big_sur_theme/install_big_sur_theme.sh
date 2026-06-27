#!/usr/bin/env bash
set -ex

echo "Installing Big Sur (WhiteSur) theme for Kasm"

export DEBIAN_FRONTEND=noninteractive

# Omitted from original SmallSur install-debian.sh (unavailable on Noble):
#   xfce4-indicator-plugin    — removed from Ubuntu repos after Focal
#   xfce4-sensors-plugin      — hardware sensors unavailable in containers
#   xfce4-statusnotifier-plugin — merged into systray plugin in XFCE 4.18
#   ulauncher                 — not in Noble apt repos
#
# xfce4-appmenu-plugin IS in Noble universe; appmenu-gtk{2,3}-module +
# appmenu-registrar provide the DBus bridge for the global menu panel plugin.
apt-get update
apt-get install -y \
    xfce4-power-manager \
    xfce4-pulseaudio-plugin \
    xfce4-notifyd \
    xfce4-appmenu-plugin \
    appmenu-gtk2-module \
    appmenu-gtk3-module \
    appmenu-registrar \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    sassc \
    git \
    plank \
    libglib2.0-dev-bin \
    libxml2-utils

WORK_DIR=/tmp/bigsur-theme-install
mkdir -p "$WORK_DIR"

# WhiteSur installer scripts resolve the calling user via logname, which has
# no output inside a Docker build. SUDO_USER=root makes them resolve to root.
export SUDO_USER=root

# ---------------------------------------------------------------------------
# GTK theme — WhiteSur
# Installed system-wide so both kasm-default-profile and kasm-user pick it up.
# -c is repeatable; one call installs both variants without the second wiping
# what the first laid down.
# ---------------------------------------------------------------------------
git clone --depth=1 https://github.com/jothi-prasath/WhiteSur-gtk-theme.git \
    "$WORK_DIR/WhiteSur-gtk-theme"
# --silent-mode: skips setterm/terminal cursor calls that fail in Docker.
# Omitting -c installs all color variants (Dark + Light) by default.
TERM=xterm-256color "$WORK_DIR/WhiteSur-gtk-theme/install.sh" --silent-mode -d /usr/share/themes

# ---------------------------------------------------------------------------
# Icon theme — WhiteSur
# ---------------------------------------------------------------------------
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git \
    "$WORK_DIR/WhiteSur-icon-theme"
"$WORK_DIR/WhiteSur-icon-theme/install.sh" -d /usr/share/icons

# ---------------------------------------------------------------------------
# Cursor theme — WhiteSur
# ---------------------------------------------------------------------------
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git \
    "$WORK_DIR/WhiteSur-cursors"
( cd "$WORK_DIR/WhiteSur-cursors" && bash install.sh )

# ---------------------------------------------------------------------------
# SmallSur assets — wallpapers and Plank theme
# The install-debian.sh from this repo is not run; only its bundled assets
# are used.
# ---------------------------------------------------------------------------
git clone --depth=1 https://github.com/jothi-prasath/SmallSur.git \
    "$WORK_DIR/SmallSur"

mkdir -p /usr/share/backgrounds/bigsur
cp -r "$WORK_DIR/SmallSur/wallpaper/"* /usr/share/backgrounds/bigsur/
cp /usr/share/backgrounds/bigsur/monterey.png /usr/share/backgrounds/bg_default.png

mkdir -p /usr/share/plank/themes
cp -rp "$WORK_DIR/SmallSur/plank/mcOS-BS-iMacM1-Black" /usr/share/plank/themes/
if [ -d "$WORK_DIR/WhiteSur-gtk-theme/src/other/plank" ]; then
    cp -rp "$WORK_DIR/WhiteSur-gtk-theme/src/other/plank/"* /usr/share/plank/themes/
fi

# ---------------------------------------------------------------------------
# Plank autostart
# ---------------------------------------------------------------------------
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/plank.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Comment=Dock
Exec=plank
Icon=plank
Terminal=false
StartupNotify=false
Categories=Utility;
EOF

mkdir -p "$HOME/.config/plank/dock1"
cat > "$HOME/.config/plank/dock1/settings" << 'EOF'
[PlankDockPreferences]
CurrentWorkspaceOnly=false
IconSize=48
HideMode=0
UnhideDelay=0
Theme=mcOS-BS-iMacM1-Black
Alignment=3
LockItems=false
ZoomPercent=120
EOF

# ---------------------------------------------------------------------------
# GTK2/3 theme pointers in the default profile home
# Belt-and-suspenders for apps that read these files directly rather than
# going through xsettings.
# ---------------------------------------------------------------------------
cat > "$HOME/.gtkrc-2.0" << 'EOF'
gtk-theme-name="WhiteSur-Dark"
gtk-icon-theme-name="WhiteSur-Dark"
gtk-cursor-theme-name="WhiteSur-cursors"
gtk-font-name="Sans 10"
EOF

mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=WhiteSur-Dark
gtk-icon-theme-name=WhiteSur-Dark
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=Sans 10
EOF

# ---------------------------------------------------------------------------
# GTK appmenu module
# Exports running app menus over DBus so xfce4-appmenu-plugin can display
# them in the panel. Loaded by setting GTK_MODULES at session start.
# ---------------------------------------------------------------------------
mkdir -p /etc/X11/Xsession.d
cat > /etc/X11/Xsession.d/81appmenu << 'EOF'
export GTK_MODULES="${GTK_MODULES:+$GTK_MODULES:}appmenu-gtk-module"
EOF
chmod +x /etc/X11/Xsession.d/81appmenu

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
chown -R 1000:0 "$HOME"
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;

rm -rf "$WORK_DIR"

if [ -z "${SKIP_CLEAN+x}" ]; then
    apt-get autoclean
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
fi

echo "Big Sur theme installation complete"
