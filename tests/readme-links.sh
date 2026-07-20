#!/usr/bin/env bash
set -euo pipefail

readme_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/README.md"

for upstream_url in \
  https://github.com/amsynth/amsynth \
  https://github.com/crispinha/modal-synth \
  https://github.com/gadalleore/Space_Dust_Synthesizer \
  https://github.com/Hornfisk/squelchbox \
  https://github.com/kayrockscreenprinting/ultramaster_kr106 \
  https://github.com/odoare/Mechanodd \
  https://github.com/giulioz/rdpiano; do
  grep -Fqx "$upstream_url" <(grep -o 'https://[^)]*' "$readme_path")
done

grep -Fq "Conditional packages" "$readme_path"
grep -Fq "NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#mechanodd" "$readme_path"
grep -Fq "NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#rdpiano" "$readme_path"

if grep -Eq '/home/|hosts/' "$readme_path"; then
  printf '%s\n' "README contains a prohibited external configuration reference." >&2
  exit 1
fi
