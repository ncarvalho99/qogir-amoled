#!/usr/bin/env bash
# Qogir AMOLED installer for KDE Plasma 6 (user install, no root needed).
#
#   ./install.sh              install everything
#   ./install.sh --apply      install and switch the desktop to Qogir AMOLED
#   ./install.sh --no-icons   skip the Qogir icon/cursor theme download
#   ./install.sh --uninstall  remove everything this script installed

set -euo pipefail

SRC_DIR=$(cd "$(dirname "$0")" && pwd)
NAME=Qogir-amoled
GTK_NAME=Qogir-Amoled
GTK_THEME=$GTK_NAME-Dark
LNF_ID=com.github.ncarvalho99.Qogir-amoled
ICONS_REPO=https://github.com/vinceliuice/Qogir-icon-theme

DATA=${XDG_DATA_HOME:-$HOME/.local/share}
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
THEMES_DIR=$HOME/.themes
ICONS_DIR=$DATA/icons

apply=false
icons=true
uninstall=false

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --apply) apply=true ;;
    --no-icons) icons=false ;;
    -u|--uninstall) uninstall=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root."
  exit 1
fi

qdbus_cmd() {
  command -v qdbus6 || command -v qdbus || true
}

# GTK 4 / libadwaita apps read ~/.config/gtk-4.0/gtk.css. Plasma owns that file
# (it keeps an @import of colors.css there), so we import the theme instead of
# symlinking over it: if Plasma rewrites the file it can't touch the theme.
GTK4_MARK='/* qogir-amoled */'

install_gtk4_css() {
  local css=$CONFIG/gtk-4.0/gtk.css
  mkdir -p "$CONFIG/gtk-4.0"
  remove_gtk4_css
  {
    echo "$GTK4_MARK @import url(\"file://$THEMES_DIR/$GTK_THEME/gtk-4.0/gtk-dark.css\");"
    [[ -f $css ]] && cat "$css"
  } > "$css.new"
  mv "$css.new" "$css"
}

remove_gtk4_css() {
  local css=$CONFIG/gtk-4.0/gtk.css
  [[ -f $css ]] || return 0
  sed -i "\|^/\* qogir-amoled \*/|d" "$css"
  [[ -s $css ]] || rm -f "$css"
  return 0
}

do_uninstall() {
  echo "Removing Qogir AMOLED..."
  rm -rf "$DATA/plasma/desktoptheme/$NAME" \
         "$DATA/plasma/look-and-feel/$LNF_ID" \
         "$DATA/aurorae/themes/$NAME" "$DATA/aurorae/themes/$NAME-circle" \
         "$DATA/color-schemes/QogirAmoled.colors" \
         "$DATA/wallpapers/$NAME" \
         "$CONFIG/Kvantum/$NAME" "$CONFIG/Kvantum/$NAME-translucent" \
         "$THEMES_DIR/$GTK_NAME"{,-Light,-Dark}{,-hdpi,-xhdpi}
  remove_gtk4_css
  echo "Done. The Qogir icon/cursor theme in $ICONS_DIR was left in place."
}

install_kde() {
  echo "==> Plasma: color scheme, Plasma style, window decorations, global theme, wallpaper"
  mkdir -p "$DATA"/{color-schemes,plasma/desktoptheme,plasma/look-and-feel,aurorae/themes,wallpapers} "$CONFIG/Kvantum"
  cp "$SRC_DIR/kde/color-schemes/QogirAmoled.colors" "$DATA/color-schemes/"
  rm -rf "$DATA/plasma/desktoptheme/$NAME" "$DATA/plasma/look-and-feel/$LNF_ID" \
         "$DATA/aurorae/themes/$NAME" "$DATA/aurorae/themes/$NAME-circle" "$DATA/wallpapers/$NAME" \
         "$CONFIG/Kvantum/$NAME" "$CONFIG/Kvantum/$NAME-translucent"
  cp -r "$SRC_DIR/kde/plasma/desktoptheme/$NAME" "$DATA/plasma/desktoptheme/"
  cp -r "$SRC_DIR/kde/plasma/look-and-feel/$LNF_ID" "$DATA/plasma/look-and-feel/"
  cp -r "$SRC_DIR/kde/aurorae/themes/$NAME" "$SRC_DIR/kde/aurorae/themes/$NAME-circle" "$DATA/aurorae/themes/"
  cp -r "$SRC_DIR/kde/wallpaper/$NAME" "$DATA/wallpapers/"
  echo "==> Kvantum"
  cp -r "$SRC_DIR/kde/Kvantum/$NAME" "$SRC_DIR/kde/Kvantum/$NAME-translucent" "$CONFIG/Kvantum/"
}

install_gtk() {
  echo "==> GTK 2/3/4 theme ($GTK_THEME)"
  mkdir -p "$THEMES_DIR"
  local log
  log=$(mktemp)
  if ! "$SRC_DIR/gtk/install.sh" -n "$GTK_NAME" -c dark -d "$THEMES_DIR" >"$log" 2>&1; then
    cat "$log"
    rm -f "$log"
    exit 1
  fi
  rm -f "$log"
  install_gtk4_css
}

install_icons() {
  echo "==> Qogir icon + cursor theme (downloaded from $ICONS_REPO)"
  local tmp
  tmp=$(mktemp -d)
  git clone -q --depth 1 "$ICONS_REPO" "$tmp/icons"
  mkdir -p "$ICONS_DIR"
  (cd "$tmp/icons" && ./install.sh -c all -t default -d "$ICONS_DIR" >/dev/null)
  rm -rf "$tmp"
}

check_deps() {
  local missing=()
  command -v kvantummanager >/dev/null || missing+=("kvantum (application style)")
  command -v gtk-update-icon-cache >/dev/null || missing+=("gtk-update-icon-cache")
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo
    echo "Optional packages not found:"
    printf '  - %s\n' "${missing[@]}"
    echo "On Arch/CachyOS: sudo pacman -S --needed kvantum kvantum-qt5 gtk-update-icon-cache"
  fi
}

apply_theme() {
  echo "==> Applying Qogir AMOLED"
  plasma-apply-lookandfeel -a "$LNF_ID" >/dev/null
  # The global theme can't pick a Kvantum theme, so set it here.
  mkdir -p "$CONFIG/Kvantum"
  printf '[General]\ntheme=%s\n' "$NAME" > "$CONFIG/Kvantum/kvantum.kvconfig"
  # Let Plasma's GTK integration write settings.ini, gsettings and xsettingsd.
  local q
  q=$(qdbus_cmd)
  if [[ -n $q ]] && $q org.kde.GtkConfig /GtkConfig >/dev/null 2>&1; then
    $q org.kde.GtkConfig /GtkConfig org.kde.GtkConfig.setGtkTheme "$GTK_THEME" >/dev/null
  else
    kwriteconfig6 --file "$CONFIG/gtk-3.0/settings.ini" --group Settings --key gtk-theme-name "$GTK_THEME"
    kwriteconfig6 --file "$CONFIG/gtk-4.0/settings.ini" --group Settings --key gtk-theme-name "$GTK_THEME"
  fi
  if command -v flatpak >/dev/null; then
    flatpak override --user --filesystem="$THEMES_DIR:ro" --filesystem=xdg-config/gtk-3.0:ro \
      --filesystem=xdg-config/gtk-4.0:ro --env=GTK_THEME="$GTK_THEME" 2>/dev/null || true
  fi
  echo "Done. Log out and back in if some apps still show the old theme."
}

if $uninstall; then
  do_uninstall
  exit 0
fi

install_kde
install_gtk
$icons && install_icons
check_deps
$apply && apply_theme

echo
echo "Qogir AMOLED installed."
$apply || echo "Apply it in System Settings > Colors & Themes > Global Theme > Qogir AMOLED, or run ./install.sh --apply"
