{ callPackage, runCommand, python3, p7zip }:
let
  package = callPackage ../pkgs/0xfx-windows { };
in {
  archiveLayout = runCommand "0xfx-source-archive-entry-paths" { nativeBuildInputs = [ python3 ]; } ''
    python - <<'PY'
    import zipfile
    with zipfile.ZipFile('${package}/0xfx-source.zip') as z:
        for name in ['packaging/flake.nix', 'packaging/flake.lock',
                     'packaging/tests/0xfx-windows.nix',
                     'packaging/pkgs/0xfx-windows/default.nix']:
            assert name in z.namelist(), 'missing standalone archive entry: ' + name
        assert not any(name.endswith('/verification.json') for name in z.namelist())
    PY
    touch "$out"
  '';
  artifacts = runCommand "0xfx-windows-data-only-artifacts" {
    nativeBuildInputs = [ (python3.withPackages (p: [ p.pefile ])) p7zip ];
  } ''
    python ${../pkgs/0xfx-windows/verify.py} ${package} "$out"
  '';
  repack = runCommand "0xfx-independent-repack" { nativeBuildInputs = [ python3 ]; } ''
    python ${../pkgs/0xfx-windows/package.py} ${package}/payload manual.zip
    python ${../pkgs/0xfx-windows/package.py} ${package}/source source.zip
    cmp manual.zip ${package}/0xfx-windows-x86_64.zip
    cmp source.zip ${package}/0xfx-source.zip
    touch "$out"
  '';
  installerRepack = let again = callPackage ../pkgs/0xfx-windows { repackSalt = "independent-installer-repack"; };
  in runCommand "0xfx-independent-installer-repack" { } ''
    cmp ${package}/installer/0xfx-1.3.0-source-x86_64-setup.exe ${again}/installer/0xfx-1.3.0-source-x86_64-setup.exe
    cmp ${package}/0xfx-windows-x86_64.zip ${again}/0xfx-windows-x86_64.zip
    cmp ${package}/0xfx-source.zip ${again}/0xfx-source.zip
    touch "$out"
  '';
  recompile = let again = callPackage ../pkgs/0xfx-windows { compileSalt = "independent-source-recompile"; };
  in runCommand "0xfx-independent-source-recompile" { } ''
    for name in CLAP/0xFX.clap VST3/0xFX.vst3/Contents/x86_64-win/0xFX.vst3 GUI/0xfx_gui.exe Console/0xfx_standalone.exe; do
      cmp "${package.compiled}/$name" "${again.compiled}/$name"
    done
    touch "$out"
  '';
}
