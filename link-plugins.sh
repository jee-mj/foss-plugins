#!/usr/bin/env bash
# Symlink built foss-plugins into standard DAW plugin directories.
# Run after 'nix build' from the repo root.
set -euo pipefail

link_into() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  for bundle in "$src"/*; do
    [ -e "$bundle" ] || continue
    local name=$(basename "$bundle")
    ln -sfn "$(realpath "$bundle")" "$dst/$name"
    echo "  $name -> $dst/"
  done
}

# Free packages
for pkg in setekh ripplerx neuralnote; do
  echo "=== $pkg ==="
  nix build ".#$pkg" --no-link --print-build-logs 2>&1 | tail -1
  path=$(nix path-info ".#$pkg" 2>/dev/null) || continue

  [ -d "$path/lib/vst3" ] && link_into "$path/lib/vst3" "$HOME/.vst3"
  [ -d "$path/lib/lv2" ]  && link_into "$path/lib/lv2"  "$HOME/.lv2"
  [ -d "$path/lib/clap" ] && link_into "$path/lib/clap" "$HOME/.clap"
  [ -d "$path/bin" ]      && echo "  standalone in $path/bin"
done

echo ""
echo "Done. Restart Ardour and rescan plugins."
echo "To remove: rm -f ~/.vst3/Setekh.vst3 ~/.lv2/Setekh.lv2 ..."
