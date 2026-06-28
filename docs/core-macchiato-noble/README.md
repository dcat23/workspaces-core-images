# macOS Big Sur Core Desktop

**Ubuntu Noble core image with a macOS Big Sur–styled desktop.**

This is a Kasm core image built on `ubuntu:24.04` that bakes the WhiteSur/Big Sur macOS theme, Plank dock, Nemo file manager, and Kitty terminal into the base so downstream workspace images inherit the full macOS look without re-applying any theme layer.

---

## What's Included

### Theme Stack

| Component | Source | Details |
|---|---|---|
| **GTK theme** | [WhiteSur-gtk-theme](https://github.com/jothi-prasath/WhiteSur-gtk-theme) | Dark variant only; extracted from pre-built release tarball (no SCSS compilation at build time) |
| **Icon theme** | [WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme) | WhiteSur, WhiteSur-dark, WhiteSur-light — icon caches built via `gtk-update-icon-cache` |
| **Cursor theme** | [WhiteSur-cursors](https://github.com/vinceliuice/WhiteSur-cursors) | WhiteSur-cursors; pre-compiled XCursor binaries copied directly from `dist/` |
| **Window decorations** | WhiteSur-gtk-theme (xfwm4) | WhiteSur-Dark — traffic-light buttons on the left (`CHM\|O`) |
| **Dock** | [Plank](https://launchpad.net/plank) | Themed with `mcOS-BS-iMacM1-Black` (transparent fill for VNC); always visible; autostarts with session |
| **Wallpapers** | [SmallSur](https://github.com/jothi-prasath/SmallSur) | 5 wallpapers in `/usr/share/backgrounds/bigsur/` |
| **File manager** | [Nemo](https://github.com/linuxmint/nemo) | Replaces Thunar; includes `nemo-fileroller` archive integration |
| **Terminal emulator** | [Kitty](https://sw.kovidgoyal.net/kitty/) | Default terminal; registered via `exo-open` and `update-alternatives` |

### Default Active Settings

| Setting | Value |
|---|---|
| GTK theme | WhiteSur-Dark |
| Icon theme | WhiteSur-dark |
| Cursor theme | WhiteSur-cursors |
| Window manager theme | WhiteSur-Dark |
| Window button layout | `CHM\|O` — Close/Hide/Maximize on the left, app icon on the right |
| Compositing | Enabled (`use_compositing=true`, `sync_to_vblank=false`) |
| Default wallpaper | `monterey.png` |
| Plank dock visibility | Always visible (`HideMode=0`) |
| Plank theme | mcOS-BS-iMacM1-Black (transparent fill — floating icons) |
| Panel background | `rgba(0, 0, 0, 0.30)` — 30% black tint |
| Default file manager | Nemo |
| Default terminal | Kitty (shell: `/bin/bash`) |

### Top Panel Layout

```
[ App Icon ]  [ App Menu (appmenu) ]  ── spacer ──  [ Date/Time ]  ── spacer ──  [ Systray ]  [ Volume ]  [ Power ]
```

### XFCE Plugins Installed

| Plugin | Package |
|---|---|
| Global app menu | `xfce4-appmenu-plugin` + `appmenu-gtk{2,3}-module` + `appmenu-registrar` |
| Volume control | `xfce4-pulseaudio-plugin` |
| Power manager | `xfce4-power-manager` |
| Notifications | `xfce4-notifyd` |

---

## Wallpapers

All SmallSur wallpapers are installed to `/usr/share/backgrounds/bigsur/`:

| File | Style |
|---|---|
| `monterey.png` | Purple/blue gradient — **default** |
| `contours.png` | Abstract contour lines |
| `smallsur.png` | SmallSur brand gradient |
| `ventura.jpg` | macOS Ventura landscape |
| `cyberpunk.jpg` | Cyberpunk neon cityscape |

---

## Build

```bash
docker build \
  -f dockerfile-macchiato-core-noble \
  --build-arg BASE_IMAGE=ubuntu:24.04 \
  --build-arg DISTRO=ubuntu \
  -t kasmweb/core-macchiato-noble:dev .
```

## Run

```bash
docker run --rm -it \
  --shm-size=512m \
  -p 6901:6901 \
  -e VNC_PW=password \
  kasmweb/core-macchiato-noble:dev
```

Access via browser at `https://<host>:6901` — user: `kasm_user`, password: `password`.

---

## Image Metadata

| Field | Value |
|---|---|
| **Base image** | `ubuntu:24.04` |
| **Dockerfile** | `dockerfile-macchiato-core-noble` |
| **XFCE config** | `src/ubuntu/xfce-macchiato-v2/.config/` |
| **Install scripts** | `src/ubuntu/install/big_sur_theme/install_big_sur_theme_v2.sh` |
| | `src/ubuntu/install/nemo/install_nemo.sh` |
| | `src/ubuntu/install/kitty/install_kitty.sh` |
| **Type** | Core (base image for downstream workspaces) |

---

## Extending This Image

Downstream workspace images can inherit from this core:

```dockerfile
FROM kasmweb/core-macchiato-noble:develop
USER root
# Install your app here
USER 1000
```

### Change the wallpaper

```dockerfile
FROM kasmweb/core-macchiato-noble:develop
USER root
RUN cp /usr/share/backgrounds/bigsur/ventura.jpg /usr/share/backgrounds/bg_default.png
USER 1000
```

### Adjust panel transparency

Edit `background-rgba` in `src/ubuntu/xfce-macchiato-v2/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml`:

```xml
<value type="double" value="0.300000"/>  <!-- fourth value: 0.0 = transparent, 1.0 = opaque -->
```

Rebuild after changing it.
