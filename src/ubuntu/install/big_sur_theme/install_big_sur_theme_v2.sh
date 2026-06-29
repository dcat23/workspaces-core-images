#!/usr/bin/env bash
set -ex

echo "Installing Big Sur (WhiteSur) theme for Kasm — v2"

export DEBIAN_FRONTEND=noninteractive

# Compared to v1:
#   Removed: sassc, libglib2.0-dev-bin, libxml2-utils
#     (only needed by WhiteSur-gtk-theme/install.sh SCSS compilation; v2 uses
#     a pre-built release tarball instead)
#   Added: libgtk-3-bin
#     (provides gtk-update-icon-cache required by WhiteSur-icon-theme/install.sh;
#     v1 was missing this so icon caches were never correctly built)
apt-get update
apt-get install -y \
    xfce4-power-manager \
    xfce4-pulseaudio-plugin \
    xfce4-notifyd \
    xfce4-appmenu-plugin \
    xfce4-whiskermenu-plugin \
    appmenu-gtk2-module \
    appmenu-gtk3-module \
    appmenu-registrar \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    libgtk-3-bin \
    pavucontrol \
    fonts-cantarell \
    git \
    plank

WORK_DIR=/tmp/bigsur-theme-install
mkdir -p "$WORK_DIR"

# WhiteSur installer scripts resolve the calling user via logname, which has
# no output inside a Docker build. SUDO_USER=root makes them fall back to root.
export SUDO_USER=root

# ---------------------------------------------------------------------------
# GTK theme — WhiteSur (pre-built tarball, no SCSS compilation)
#
# v1 called install.sh which compiled every .scss source file via sassc and
# bundled assets into .gresource binaries via glib-compile-resources. That
# required three extra build-time packages and produced all four variants
# (Light, Dark, Light-solid, Dark-solid). v2 extracts only WhiteSur-Dark from
# the pre-built release tarball committed to the repo — identical installed
# output, zero compilation toolchain.
#
# Tarball contents: gtk-2.0/, gtk-3.0/, gtk-4.0/, xfwm4/, cinnamon/,
#                   metacity-1/, plank/dock.theme, index.theme
# ---------------------------------------------------------------------------
git clone --depth=1 https://github.com/jothi-prasath/WhiteSur-gtk-theme.git \
    "$WORK_DIR/WhiteSur-gtk-theme"

mkdir -p /usr/share/themes

if [ -f "$WORK_DIR/WhiteSur-gtk-theme/release/WhiteSur-Dark.tar.xz" ]; then
    tar -xJf "$WORK_DIR/WhiteSur-gtk-theme/release/WhiteSur-Dark.tar.xz" \
        -C /usr/share/themes/
else
    # Fallback: compile from source if the fork ever drops pre-built tarballs.
    apt-get install -y sassc libglib2.0-dev-bin libxml2-utils
    TERM=xterm-256color "$WORK_DIR/WhiteSur-gtk-theme/install.sh" \
        --silent-mode -d /usr/share/themes -n WhiteSur -c dark -o normal
fi

# ---------------------------------------------------------------------------
# Icon theme — WhiteSur
#
# install.sh is Docker-safe: pure cp + sed colour-inversion + symlinks.
# No xfconf, no dconf, no setterm calls.
# v1 lacked libgtk-3-bin so gtk-update-icon-cache never ran, leaving icon
# caches unbuilt. v2 installs libgtk-3-bin before this step.
# Produces: /usr/share/icons/WhiteSur/
#           /usr/share/icons/WhiteSur-dark/   ← used in xsettings
#           /usr/share/icons/WhiteSur-light/
# ---------------------------------------------------------------------------
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git \
    "$WORK_DIR/WhiteSur-icon-theme"
"$WORK_DIR/WhiteSur-icon-theme/install.sh" -d /usr/share/icons

# ---------------------------------------------------------------------------
# Cursor theme — WhiteSur (direct copy, no install.sh wrapper)
#
# install.sh is 29 lines that only do: cp -pr dist/ /usr/share/icons/WhiteSur-cursors
# v2 replicates that directly and skips cursors_scalable/ (SVG build sources
# that X11 never reads at runtime — saves ~2 MB per image layer).
# ---------------------------------------------------------------------------
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git \
    "$WORK_DIR/WhiteSur-cursors"
mkdir -p /usr/share/icons/WhiteSur-cursors
cp -pr "$WORK_DIR/WhiteSur-cursors/dist/cursors"    /usr/share/icons/WhiteSur-cursors/
cp     "$WORK_DIR/WhiteSur-cursors/dist/index.theme" /usr/share/icons/WhiteSur-cursors/

# ---------------------------------------------------------------------------
# SmallSur — wallpapers only
#
# install-debian.sh is never run: it calls xfconf-query which requires a live
# DISPLAY + dbus session — fatal at Docker build time. Only wallpaper assets
# are taken from this repo.
# ---------------------------------------------------------------------------
git clone --depth=1 https://github.com/jothi-prasath/SmallSur.git \
    "$WORK_DIR/SmallSur"

mkdir -p /usr/share/backgrounds/bigsur
cp -r "$WORK_DIR/SmallSur/wallpaper/"* /usr/share/backgrounds/bigsur/
cp /usr/share/backgrounds/bigsur/monterey.png /usr/share/backgrounds/bg_default.png

# ---------------------------------------------------------------------------
# Plank dock theme (written directly — no upstream file dependency)
#
# v1 copied mcOS-BS-iMacM1-Black from SmallSur then immediately overwrote its
# dock.theme. v2 writes the authoritative definition directly, skipping the
# redundant copy. Fully-transparent fill so icons float with no shelf visible —
# VNC compositing cannot render semi-transparent fills from the upstream theme.
# ---------------------------------------------------------------------------
mkdir -p /usr/share/plank/themes/mcOS-BS-iMacM1-Black
cat > /usr/share/plank/themes/mcOS-BS-iMacM1-Black/dock.theme << 'EOF'
[PlankTheme]
TopRoundness=0
BottomRoundness=0
LineWidth=0
OuterStrokeColor=0;;0;;0;;0
FillStartColor=0;;0;;0;;0
FillEndColor=0;;0;;0;;0
InnerStrokeColor=0;;0;;0;;0
HorizPadding=0.0
TopPadding=0.0
BottomPadding=0.0
ItemPadding=2.0
IndicatorSize=0.0
BadgeColor=0;;0;;0;;0
EOF

# ---------------------------------------------------------------------------
# Plank autostart + dock preferences
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
Offset=10
Theme=mcOS-BS-iMacM1-Black
Alignment=3
LockItems=false
ZoomEnabled=true
ZoomPercent=120
EOF

# ---------------------------------------------------------------------------
# Plank default launcher items
#
# Each .dockitem file maps to one launcher in the dock. Plank resolves them
# at runtime, so the pointed-to .desktop files do not need to exist at this
# build step (nemo and kitty are installed in subsequent Dockerfile layers).
# Filenames are sorted alphabetically by Plank — nemo (n) < terminal (t)
# places the file manager left of the terminal, matching macOS dock convention.
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.config/plank/dock1/launchers"
cat > "$HOME/.config/plank/dock1/launchers/nemo.dockitem" << 'EOF'
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/nemo.desktop
EOF

cat > "$HOME/.config/plank/dock1/launchers/terminal.dockitem" << 'EOF'
[PlankDockItemPreferences]
Launcher=file:///usr/share/applications/kitty.desktop
EOF

# ---------------------------------------------------------------------------
# GTK2/GTK3 fallback settings in the default profile home
#
# Belt-and-suspenders for apps that bypass xsettings and read these files
# directly. Icon theme uses WhiteSur-dark (lowercase) to match the exact
# directory name produced by WhiteSur-icon-theme/install.sh.
# ---------------------------------------------------------------------------
cat > "$HOME/.gtkrc-2.0" << 'EOF'
gtk-theme-name="WhiteSur-Dark"
gtk-icon-theme-name="WhiteSur-dark"
gtk-cursor-theme-name="WhiteSur-cursors"
gtk-font-name="Cantarell 10"
EOF

mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=WhiteSur-Dark
gtk-icon-theme-name=WhiteSur-dark
gtk-cursor-theme-name=WhiteSur-cursors
gtk-font-name=Cantarell 10
EOF

# ---------------------------------------------------------------------------
# GTK appmenu module
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

echo "Big Sur theme v2 installation complete"
