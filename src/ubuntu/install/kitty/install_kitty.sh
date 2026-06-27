#!/usr/bin/env bash
set -ex

# Install Kitty as the default terminal emulator.

apt-get update
apt-get install -y kitty

# ── 1. exo-open TerminalEmulator helper ───────────────────────────────────────
mkdir -p /usr/share/xfce4/helpers
cat > /usr/share/xfce4/helpers/kitty.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Icon=kitty
Type=X-XFCE-Helper
Name=kitty
X-XFCE-Binaries=kitty;
X-XFCE-Category=TerminalEmulator
X-XFCE-Commands=%B;
X-XFCE-CommandsWithParameter=%B %s;
EOF

# ── 2. helpers.rc ─────────────────────────────────────────────────────────────
set_terminal_helper() {
    local rc_file="$1"
    local rc_dir
    rc_dir="$(dirname "$rc_file")"
    mkdir -p "$rc_dir"

    if [ -f "$rc_file" ]; then
        if grep -q '^TerminalEmulator=' "$rc_file"; then
            sed -i 's/^TerminalEmulator=.*/TerminalEmulator=kitty/' "$rc_file"
        else
            printf 'TerminalEmulator=kitty\n' >> "$rc_file"
        fi
    else
        printf '[Default Applications]\nTerminalEmulator=kitty\n' > "$rc_file"
    fi
}

set_terminal_helper /etc/xdg/xfce4/helpers.rc
set_terminal_helper "$HOME/.config/xfce4/helpers.rc"

# ── 3. Shell ──────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/kitty"
printf 'shell /bin/bash\n' >> "$HOME/.config/kitty/kitty.conf"
chown -R 1000:0 "$HOME/.config/kitty"

# ── 4. update-alternatives ────────────────────────────────────────────────────
# Priority 50 — higher than xterm (10) and xfce4-terminal (20).
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/kitty 50

# ── 5. Cleanup ────────────────────────────────────────────────────────────────
chown -R 1000:0 "$HOME"
find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \;
if [ -z "${SKIP_CLEAN+x}" ]; then
    apt-get autoclean
    rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*
fi
