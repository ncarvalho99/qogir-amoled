#!/usr/bin/env bash
# Generates kde/ (the Plasma 6 AMOLED variant) from an upstream Qogir-kde checkout.
#
#   tools/build-kde.sh /path/to/Qogir-kde
#
# Only the dark pieces of upstream are used; everything is renamed to
# Qogir-amoled so it can live next to a regular Qogir install.

set -euo pipefail

UP=${1:?usage: $0 /path/to/Qogir-kde}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/kde
AMOLEDIFY=$ROOT/tools/amoledify.py
NAME=Qogir-amoled
LNF_ID=com.github.ncarvalho99.Qogir-amoled

rm -rf "$OUT"
mkdir -p "$OUT"/{color-schemes,plasma/desktoptheme,plasma/look-and-feel,aurorae/themes,Kvantum,wallpaper}

# --- Color scheme -----------------------------------------------------------
sed -e 's/^Name=.*/Name=Qogir AMOLED/' -e 's/^ColorScheme=.*/ColorScheme=QogirAmoled/' \
  "$UP/color-schemes/QogirDark.colors" > "$OUT/color-schemes/QogirAmoled.colors"
python3 "$AMOLEDIFY" "$OUT/color-schemes/QogirAmoled.colors"
# Tooltip alternate shade; kept out of palette.tsv because the GTK close button needs it.
sed -i 's/=47,52,63$/=15,15,15/' "$OUT/color-schemes/QogirAmoled.colors"

# --- Plasma style -----------------------------------------------------------
PT=$OUT/plasma/desktoptheme/$NAME
mkdir -p "$PT"
cp -r "$UP/plasma/desktoptheme/Qogir/." "$PT"
cp -r "$UP/plasma/desktoptheme/Qogir-dark/." "$PT"
cp "$OUT/color-schemes/QogirAmoled.colors" "$PT/colors"
sed -i -e "s/^Name=.*/Name=Qogir AMOLED/" -e "s/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=$NAME/" \
  -e "s/^defaultWallpaperTheme=.*/defaultWallpaperTheme=$NAME/" "$PT/metadata.desktop"
cat > "$PT/metadata.json" <<EOF
{
    "KPackageStructure": "Plasma/Theme",
    "KPlugin": {
        "Authors": [
            { "Name": "Vinceliuice", "Email": "vinceliuice@hotmail.com" },
            { "Name": "ncarvalho99" }
        ],
        "Category": "Plasma Theme",
        "Description": "Qogir dark with a pure black (AMOLED) palette",
        "EnabledByDefault": true,
        "Id": "$NAME",
        "License": "GPL 3.0",
        "Name": "Qogir AMOLED",
        "ServiceTypes": ["Plasma/Theme"],
        "Version": "1.0",
        "Website": "https://github.com/ncarvalho99/qogir-amoled"
    }
}
EOF
python3 "$AMOLEDIFY" "$PT"
python3 "$ROOT/tools/fix-svg-styles.py" "$PT"

# --- Window decorations (Aurorae) --------------------------------------------
for shape in '' '-circle'; do
  src=$UP/aurorae/themes/Qogir-dark$shape
  dst=$OUT/aurorae/themes/$NAME$shape
  cp -r "$src" "$dst"
  mv "$dst/Qogir-dark${shape}rc" "$dst/$NAME${shape}rc"
  sed -i -e "s/^Name=.*/Name=Qogir AMOLED${shape/-circle/ (circle)}/" \
    -e "s/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=$NAME$shape/" "$dst/metadata.desktop"
  # KWin 6 only lists Aurorae themes that ship a metadata.json.
  cat > "$dst/metadata.json" <<EOF
{
    "KPackageStructure": "KWin/Aurorae",
    "KPlugin": {
        "Authors": [
            { "Name": "Vince Liuice", "Email": "vinceliuice@hotmail.com" },
            { "Name": "ncarvalho99" }
        ],
        "EnabledByDefault": true,
        "Id": "$NAME$shape",
        "License": "GPLv3",
        "Name": "Qogir AMOLED${shape/-circle/ (circle)}",
        "Version": "1.0"
    }
}
EOF
  python3 "$AMOLEDIFY" "$dst"
done

# --- Kvantum ----------------------------------------------------------------
# Qogir-amoled is opaque: upstream's translucency lets the wallpaper bleed
# through and turns the black into grey. The translucent look is kept as an
# optional variant. (Upstream's "-solid" config is older and draws disabled
# text in #393a44, unreadable on black, so it isn't used.)
mkdir -p "$OUT/Kvantum/$NAME" "$OUT/Kvantum/$NAME-translucent"
cp "$UP/Kvantum/Qogir-dark/Qogir-dark.svg" "$OUT/Kvantum/$NAME/$NAME.svg"
cp "$UP/Kvantum/Qogir-dark/Qogir-dark.kvconfig" "$OUT/Kvantum/$NAME/$NAME.kvconfig"
cp "$UP/Kvantum/Qogir-dark/Qogir-dark.svg" "$OUT/Kvantum/$NAME-translucent/$NAME-translucent.svg"
cp "$UP/Kvantum/Qogir-dark/Qogir-dark.kvconfig" "$OUT/Kvantum/$NAME-translucent/$NAME-translucent.kvconfig"
sed -i -E \
  -e 's/^(translucent_windows|blurring|popup_blurring|blur_translucent)=true/\1=false/' \
  -e 's/^(transparent_dolphin_view|transparent_pcmanfm_sidepane|transparent_pcmanfm_view|transparent_menutitle)=true/\1=false/' \
  -e 's/^(reduce_window_opacity|reduce_menu_opacity)=.*/\1=0/' \
  "$OUT/Kvantum/$NAME/$NAME.kvconfig"
python3 "$AMOLEDIFY" "$OUT/Kvantum"

# --- Wallpaper --------------------------------------------------------------
cp -r "$UP/wallpaper/Qogir-dark" "$OUT/wallpaper/$NAME"
sed -i -e "s/\"Id\": \"Qogir-dark\"/\"Id\": \"$NAME\"/" -e "s/\"Name\": \"Qogir-dark\"/\"Name\": \"Qogir AMOLED\"/" \
  "$OUT/wallpaper/$NAME/metadata.json"
rm -f "$OUT/wallpaper/$NAME/metadata.desktop"

# --- Global theme -----------------------------------------------------------
# The upstream panel layout is left out on purpose: it would replace the
# user's panels and still points at a Plasma 5 wallpaper.
LNF=$OUT/plasma/look-and-feel/$LNF_ID
mkdir -p "$LNF/contents"
cp -r "$UP/plasma/look-and-feel/com.github.vinceliuice.Qogir-dark/contents/"{previews,splash} "$LNF/contents/"
python3 "$AMOLEDIFY" "$LNF/contents/splash"
cat > "$LNF/metadata.json" <<EOF
{
    "KPackageStructure": "Plasma/LookAndFeel",
    "KPlugin": {
        "Authors": [
            { "Name": "Vince Liuice", "Email": "vinceliuice@hotmail.com" },
            { "Name": "ncarvalho99" }
        ],
        "Category": "Global Themes (Plasma 6)",
        "Description": "Qogir dark with a pure black (AMOLED) palette",
        "EnabledByDefault": true,
        "Id": "$LNF_ID",
        "License": "GPLv3",
        "Name": "Qogir AMOLED",
        "ServiceTypes": ["Plasma/LookAndFeel"],
        "Website": "https://github.com/ncarvalho99/qogir-amoled"
    },
    "Keywords": "Desktop;Workspace;Appearance;Look and Feel;Logout;Lock;Suspend;Shutdown;Hibernate;",
    "X-KDE-fallbackPackage": "org.kde.breezedark.desktop",
    "X-Plasma-MainScript": "defaults",
    "X-Plasma-APIVersion": "2"
}
EOF
cat > "$LNF/contents/defaults" <<EOF
[kcminputrc][Mouse]
cursorTheme=Qogir-Dark

[kdeglobals][General]
ColorScheme=QogirAmoled

[kdeglobals][Icons]
Theme=Qogir-Dark

[kdeglobals][KDE]
widgetStyle=kvantum-dark

[kwinrc][DesktopSwitcher]
LayoutName=org.kde.breeze.desktop

[kwinrc][WindowSwitcher]
LayoutName=org.kde.breeze.desktop

[kwinrc][org.kde.kdecoration2]
BorderSize=None
ButtonsOnLeft=
ButtonsOnRight=IAX
library=org.kde.kwin.aurorae
theme=__aurorae__svg__$NAME-circle

[plasmarc][Theme]
name=$NAME
EOF

git -C "$UP" rev-parse HEAD > "$OUT/UPSTREAM_COMMIT"
echo "kde/ generated from $(cat "$OUT/UPSTREAM_COMMIT")"
