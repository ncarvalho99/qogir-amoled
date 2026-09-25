#!/usr/bin/env bash
# Regenerates gtk/ (the GTK 2/3/4 theme) from an upstream Qogir-theme checkout.
#
#   tools/build-gtk.sh /path/to/Qogir-theme
#
# Needs sassc (set SASSC=/path/to/sassc if it isn't on PATH).

set -euo pipefail

UP=${1:?usage: $0 /path/to/Qogir-theme}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/gtk
SASSC=${SASSC:-$(command -v sassc || true)}
[[ -x $SASSC ]] || { echo "sassc not found (set SASSC=/path/to/sassc)"; exit 1; }

rsync -a --delete --exclude .git --exclude release "$UP/" "$OUT/"

# The original AMOLED palette.
python3 "$ROOT/tools/amoledify.py" "$OUT/src/_sass/_colors.scss" "$OUT"/src/gtk-2.0/theme*/gtkrc-Dark

# Nautilus 48+ icon-strip sidebar and AMOLED background image (GTK 4 only).
cp "$ROOT/gtk-amoled/_nautilus.scss" "$OUT/src/_sass/gtk/_amoled-nautilus.scss"
cp "$ROOT"/gtk-amoled/assets/* "$OUT/src/gtk/assets/assets-common/"
for f in "$OUT"/src/gtk/theme-4.0/gtk{,-Dark,-Light}.scss; do
  echo "@import '../../_sass/gtk/amoled-nautilus';" >> "$f"
done

# Regenerate the precompiled CSS so installing doesn't need sassc.
tmpbin=$(mktemp -d)
ln -s "$SASSC" "$tmpbin/sassc"
(cd "$OUT" && PATH=$tmpbin:$PATH ./parse-sass.sh >/dev/null)
rm -rf "$tmpbin" "$OUT/src/_sass/_tweaks-temp.scss"

git -C "$UP" rev-parse HEAD > "$OUT/UPSTREAM_COMMIT"
echo "gtk/ generated from $(cat "$OUT/UPSTREAM_COMMIT")"
