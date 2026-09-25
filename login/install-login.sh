#!/usr/bin/env bash
# Themes the login screen with Qogir AMOLED. Needs root; called by
# ./install.sh --login. Supports Plasma Login Manager (Plasma 6's replacement
# for SDDM) and SDDM.
#
#   sudo login/install-login.sh ICONS_SRC_DIR     install and apply
#   sudo login/install-login.sh --uninstall       restore the previous login look
#
# The greeter runs as the "plasmalogin" user, so it can't see themes in your
# home directory: the pieces it uses (color scheme, Plasma style, icons,
# cursors, wallpaper) are installed to /usr/local/share, and its own
# kdeglobals/plasmarc/kcminputrc are pointed at them.

set -euo pipefail

SRC_DIR=$(cd "$(dirname "$0")/.." && pwd)
NAME=Qogir-amoled
PREFIX=/usr/local/share
PLM_USER=plasmalogin
PLM_CONF=/etc/plasmalogin.conf
BACKUP_DIR=/var/lib/qogir-amoled/login-backup
WALLPAPER=$PREFIX/wallpapers/$NAME/contents/images/1920x1080.jpg

if [[ $EUID -ne 0 ]]; then
  echo "This needs root: sudo $0 $*"
  exit 1
fi

SDDM_THEMES=/usr/share/sddm/themes
SDDM_CONF=/etc/sddm.conf.d/qogir-amoled.conf

# --- SDDM ---------------------------------------------------------------------
if ! getent passwd "$PLM_USER" >/dev/null; then
  if ! command -v sddm >/dev/null; then
    echo "Neither Plasma Login Manager nor SDDM is installed; nothing to do."
    exit 0
  fi
  if [[ ${1:-} == --uninstall ]]; then
    rm -rf "$SDDM_THEMES/$NAME" "$SDDM_CONF"
    echo "SDDM theme removed."
  else
    rm -rf "${SDDM_THEMES:?}/$NAME"
    cp -r "$SRC_DIR/kde/sddm/$NAME" "$SDDM_THEMES/"
    chmod -R u=rwX,go=rX "$SDDM_THEMES/$NAME"
    install -d /etc/sddm.conf.d
    printf '[Theme]\nCurrent=%s\n' "$NAME" > "$SDDM_CONF"
    echo "SDDM theme set to Qogir AMOLED."
  fi
  exit 0
fi

# --- Plasma Login Manager -----------------------------------------------------
PLM_HOME=$(getent passwd "$PLM_USER" | cut -d: -f6)
PLM_CFG=$PLM_HOME/.config
MANAGED_FILES=(kdeglobals plasmarc kcminputrc)

backup() {
  [[ -d $BACKUP_DIR ]] && return 0
  mkdir -p "$BACKUP_DIR"
  for f in "${MANAGED_FILES[@]}"; do
    [[ -f $PLM_CFG/$f ]] && cp -a "$PLM_CFG/$f" "$BACKUP_DIR/$f"
  done
  [[ -f $PLM_CONF ]] && cp -a "$PLM_CONF" "$BACKUP_DIR/plasmalogin.conf"
  return 0
}

write_user_config() {
  local file=$PLM_CFG/$1
  cat > "$file"
  chown "$PLM_USER:$PLM_USER" "$file"
  chmod 600 "$file"
}

do_install() {
  local icons_src=${1:?usage: $0 ICONS_SRC_DIR}

  echo "==> Installing theme files to $PREFIX"
  install -d "$PREFIX"/{color-schemes,plasma/desktoptheme,wallpapers,icons}
  install -m 644 "$SRC_DIR/kde/color-schemes/QogirAmoled.colors" "$PREFIX/color-schemes/"
  rm -rf "$PREFIX/plasma/desktoptheme/$NAME" "$PREFIX/wallpapers/$NAME"
  cp -r "$SRC_DIR/kde/plasma/desktoptheme/$NAME" "$PREFIX/plasma/desktoptheme/"
  cp -r "$SRC_DIR/kde/wallpaper/$NAME" "$PREFIX/wallpapers/"
  for theme in Qogir Qogir-Dark; do
    rm -rf "${PREFIX:?}/icons/$theme"
    cp -a "$icons_src/$theme" "$PREFIX/icons/"
  done
  chmod -R u=rwX,go=rX "$PREFIX"/{color-schemes/QogirAmoled.colors,plasma/desktoptheme/$NAME,wallpapers/$NAME,icons/Qogir,icons/Qogir-Dark}
  command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q "$PREFIX/icons/Qogir-Dark" || true

  echo "==> Configuring the login screen"
  backup
  install -d -o "$PLM_USER" -g "$PLM_USER" "$PLM_CFG"

  # Same shape Plasma writes when a color scheme is applied: the scheme's
  # groups plus the name, then the icon theme.
  {
    grep -v '^\(Name\|ColorScheme\)=' "$SRC_DIR/kde/color-schemes/QogirAmoled.colors" \
      | sed '/^\[General\]/a ColorScheme=QogirAmoled'
    printf '\n[Icons]\nTheme=Qogir-Dark\n'
  } | write_user_config kdeglobals
  printf '[Theme]\nname=%s\n' "$NAME" | write_user_config plasmarc
  printf '[Mouse]\ncursorTheme=Qogir-Dark\n' | write_user_config kcminputrc

  kwriteconfig6 --file "$PLM_CONF" --group Greeter --key WallpaperPluginId org.kde.image
  kwriteconfig6 --file "$PLM_CONF" --group Greeter --group Wallpaper --group org.kde.image --group General \
    --key Image "file://$WALLPAPER"

  echo "Login screen set to Qogir AMOLED. It takes effect at the next login screen."
}

do_uninstall() {
  if [[ -d $BACKUP_DIR ]]; then
    echo "==> Restoring the previous login screen settings"
    for f in "${MANAGED_FILES[@]}"; do
      if [[ -f $BACKUP_DIR/$f ]]; then
        cp -a "$BACKUP_DIR/$f" "$PLM_CFG/$f"
      else
        rm -f "$PLM_CFG/$f"
      fi
    done
    [[ -f $BACKUP_DIR/plasmalogin.conf ]] && cp -a "$BACKUP_DIR/plasmalogin.conf" "$PLM_CONF"
    rm -rf "$(dirname "$BACKUP_DIR")"
  fi
  echo "==> Removing theme files from $PREFIX"
  rm -rf "$PREFIX/color-schemes/QogirAmoled.colors" "$PREFIX/plasma/desktoptheme/$NAME" \
         "$PREFIX/wallpapers/$NAME" "$PREFIX/icons/Qogir" "$PREFIX/icons/Qogir-Dark"
}

if [[ ${1:-} == --uninstall ]]; then
  do_uninstall
else
  do_install "$@"
fi
