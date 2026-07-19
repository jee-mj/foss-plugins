#!/usr/bin/env bash
# Verifies that unknown-license packages are opt-in and lazy.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
system="x86_64-linux"
nix_cmd=(nix --option warn-dirty false)

# Normal inspection and checks must not need unfree permission.
env -u NIXPKGS_ALLOW_UNFREE \
  "${nix_cmd[@]}" flake show --no-write-lock-file "$repo_root" >/dev/null

pure_package_names="$(env -u NIXPKGS_ALLOW_UNFREE \
  "${nix_cmd[@]}" eval --json --no-write-lock-file \
    "$repo_root#packages.$system" --apply 'builtins.attrNames')"
case "$pure_package_names" in
  *mechanodd*)
    printf '%s\n' "MechanOdd must not appear in pure package output inspection." >&2
    exit 1
    ;;
esac

env -u NIXPKGS_ALLOW_UNFREE \
  "${nix_cmd[@]}" flake check --no-write-lock-file "$repo_root"

# These checks separately demonstrate the module-default and free-set paths.
env -u NIXPKGS_ALLOW_UNFREE \
  "${nix_cmd[@]}" build --no-link --no-write-lock-file \
    "$repo_root#checks.$system.module-default"
env -u NIXPKGS_ALLOW_UNFREE \
  "${nix_cmd[@]}" build --no-link --no-write-lock-file \
    "$repo_root#checks.$system.free-package-set"

# MechanOdd becomes visible only when the caller explicitly opts in.
impure_package_names="$(NIXPKGS_ALLOW_UNFREE=1 \
  "${nix_cmd[@]}" eval --impure --json --no-write-lock-file \
    "$repo_root#packages.$system" --apply 'builtins.attrNames')"
case "$impure_package_names" in
  *mechanodd*)
    ;;
  *)
    printf '%s\n' "MechanOdd must appear in impure package output inspection." >&2
    exit 1
    ;;
esac
