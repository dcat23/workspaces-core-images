#!/usr/bin/env bash
set -ex

# Install Nemo as the default file manager, replacing the Thunar daemon
# that the core XFCE session launches via execThunar.sh.
#
# Unlike the workspace-image version of this script, there is no need to
# sed-patch xfce4-session.xml here: the macchiato XFCE config source file
# at src/ubuntu/xfce-macchiato/.config/.../xfce4-session.xml already
# references /usr/bin/execNemo.sh as Client3_Command directly.

apt-get update
apt-get install -y nemo nemo-fileroller

# ── 1. Session daemon ─────────────────────────────────────────────────────────
# Mirrors the execThunar.sh pattern from core so the XFCE failsafe session
# can source generate_container_user before spawning nemo.
cat > /usr/bin/execNemo.sh << 'EOF'
#!/bin/sh
. /dockerstartup/generate_container_user
/usr/bin/nemo --no-default-window
EOF
chmod +x /usr/bin/execNemo.sh

# ── 2. exo-open FileManager helper ───────────────────────────────────────────
mkdir -p /usr/share/xfce4/helpers
cat > /usr/share/xfce4/helpers/nemo.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Icon=system-file-manager
Type=X-XFCE-Helper
Name=Nemo
X-XFCE-Binaries=nemo;
X-XFCE-Category=FileManager
X-XFCE-Commands=%B;
X-XFCE-CommandsWithParameter=%B "%s";
EOF

# ── 3. helpers.rc ─────────────────────────────────────────────────────────────
set_file_manager_helper() {
    local rc_file="$1"
    local rc_dir
    rc_dir="$(dirname "$rc_file")"
    mkdir -p "$rc_dir"

    if [ -f "$rc_file" ]; then
        if grep -q '^FileManager=' "$rc_file"; then
            sed -i 's/^FileManager=.*/FileManager=nemo/' "$rc_file"
        else
            printf 'FileManager=nemo\n' >> "$rc_file"
        fi
    else
        printf '[Default Applications]\nFileManager=nemo\n' > "$rc_file"
    fi
}

set_file_manager_helper /etc/xdg/xfce4/helpers.rc
set_file_manager_helper "$HOME/.config/xfce4/helpers.rc"

# ── 4. MIME defaults ──────────────────────────────────────────────────────────
xdg-mime default nemo.desktop inode/directory
xdg-mime default nemo.desktop application/x-gnome-saved-search
update-alternatives --install /usr/bin/x-file-manager x-file-manager /usr/bin/nemo 100

mkdir -p /etc/xdg
cat > /etc/xdg/mimeapps.list << 'EOF'
[Default Applications]
inode/directory=nemo.desktop
application/x-gnome-saved-search=nemo.desktop
EOF

# ── 5. Application menu visibility ───────────────────────────────────────────
NEMO_DESKTOP=/usr/share/applications/nemo.desktop
if [ -f "$NEMO_DESKTOP" ]; then
    sed -i 's/^Categories=.*/Categories=System;FileManager;GTK;Utility;Core;/' "$NEMO_DESKTOP"
fi

# ── 6. Cleanup ────────────────────────────────────────────────────────────────
chown -R 1000:0 "$HOME"
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z "${SKIP_CLEAN+x}" ]; then
    apt-get autoclean
    rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*
fi
