{ callPackage, runCommand, python3, _7zz, nsis }:

let
  package = callPackage ../pkgs/wolf-shaper-windows { };
  # Two packaging realizations, sharing the expensive source compilation.
  repack = package.override { repackSalt = "independent-repack"; };
  python = python3.withPackages (p: [ p.pefile ]);
in
runCommand "wolf-shaper-windows-artifacts" {
  nativeBuildInputs = [ python _7zz ];
  plugin = package;
  installer = package.installer;
  repacked = repack;
  repackedInstaller = repack.installer;
  nsisHelper = "${nsis}/share/nsis/Plugins/x86-unicode/System.dll";
} ''
  python - <<'PY'
  import hashlib
  import os
  from pathlib import Path
  import subprocess
  import zipfile
  import pefile

  root = Path(os.environ["plugin"])
  payload = root / "payload"
  required = {
      "VST3/wolf-shaper.vst3/Contents/x86_64-win/wolf-shaper.vst3": b"GetPluginFactory",
      "CLAP/wolf-shaper.clap": b"clap_entry",
  }
  allowed_imports = {
      "kernel32.dll", "msvcrt.dll", "user32.dll", "gdi32.dll", "opengl32.dll",
      "comdlg32.dll", "shell32.dll", "ole32.dll", "advapi32.dll", "winmm.dll", "ntdll.dll",
  }
  report = []
  for relative, entry in required.items():
      file = payload / relative
      pe = pefile.PE(str(file))
      assert pe.FILE_HEADER.Machine == 0x8664, relative
      assert pe.OPTIONAL_HEADER.Magic == 0x20b, relative
      assert pe.FILE_HEADER.Characteristics & 0x2000, "plugin must be a DLL"
      exports = {s.name for s in pe.DIRECTORY_ENTRY_EXPORT.symbols}
      assert entry in exports, (relative, exports)
      imports = {i.dll.decode().lower() for i in pe.DIRECTORY_ENTRY_IMPORT}
      assert imports <= allowed_imports, (relative, imports - allowed_imports)
      report.append(f"{relative}: PE32+ AMD64 DLL; imports={sorted(imports)}")
  assert not list(payload.rglob("*.exe")), "manual payload contains an executable"
  assert (payload / "Notices/LICENSE-wolf-shaper").stat().st_size > 1000
  assert (payload / "Notices/BUILD-INFO.txt").is_file()
  for notice in ["LICENSE-CLAP", "LICENSE-MCF-Gthread", "LICENSE-Chivo", "LICENSE-Pugl",
                 "GNU-runtime-licenses/gcc-exception-3.1.txt", "MinGW-w64/COPYING"]:
      assert (payload / "Notices" / notice).stat().st_size > 100, notice

  archive = root / "wolf-shaper-1.0.2-windows-x86_64.zip"
  expected = {p.relative_to(payload).as_posix(): p.read_bytes()
              for p in payload.rglob("*") if p.is_file()}
  with zipfile.ZipFile(archive) as z:
      assert set(z.namelist()) == set(expected), z.namelist()
      for name, data in expected.items():
          assert z.read(name) == data, name
  exe = Path(os.environ["installer"]) / "wolf-shaper-1.0.2-windows-x86_64-setup.exe"
  setup = pefile.PE(str(exe))
  assert setup.FILE_HEADER.Machine in (0x14c, 0x8664), "installer must be real Windows PE"
  report.append(f"installer: NSIS PE machine=0x{setup.FILE_HEADER.Machine:04x}")
  subprocess.run(["7zz", "x", str(exe), "-oextracted", "-y", "-mmt=4", "-bd"], check=True)
  extracted = Path("extracted")
  # NSIS SetOutPath directories are represented by 7-Zip as $COMMONFILES64/...
  embedded = {p.relative_to(extracted).as_posix(): p.read_bytes()
              for p in extracted.rglob("*") if p.is_file()}
  # x64.nsh's RunningX64 check embeds this pinned NSIS helper (not a plugin payload).
  helper = extracted / "$PLUGINSDIR/System.dll"
  assert helper.read_bytes() == Path(os.environ["nsisHelper"]).read_bytes()
  assert pefile.PE(str(helper)).FILE_HEADER.Machine == 0x14c
  destinations = {
      "VST3": "$COMMONFILES64/VST3",
      "CLAP": "$COMMONFILES64/CLAP",
      "Notices": "$COMMONFILES64/Wolf Shaper/Notices",
  }
  expected_embedded = {"$PLUGINSDIR/System.dll": Path(os.environ["nsisHelper"]).read_bytes()}
  for name, data in expected.items():
      category, separator, relative = name.partition("/")
      assert category in destinations and separator and relative, name
      expected_embedded[destinations[category] + "/" + relative] = data

  def verify_installer_payload(files):
      assert set(files) == set(expected_embedded), (
          "installer destinations differ",
          {"missing": set(expected_embedded) - set(files),
           "unexpected": set(files) - set(expected_embedded)},
      )
      for destination, data in expected_embedded.items():
          assert hashlib.sha256(files[destination]).digest() == hashlib.sha256(data).digest(), destination

  verify_installer_payload(embedded)
  # Mutate paths only: identical payload bytes under an extra parent must fail.
  for destination in [
      "$COMMONFILES64/VST3/wolf-shaper.vst3/Contents/x86_64-win/wolf-shaper.vst3",
      "$COMMONFILES64/CLAP/wolf-shaper.clap",
      "$COMMONFILES64/Wolf Shaper/Notices/BUILD-INFO.txt",
      "$PLUGINSDIR/System.dll",
  ]:
      misplaced = dict(embedded)
      misplaced["extra-parent/" + destination] = misplaced.pop(destination)
      try:
          verify_installer_payload(misplaced)
      except AssertionError:
          pass
      else:
          raise AssertionError(f"accepted extra-parent installer path: {destination}")
  report.append("strict installer destinations: real payload accepted; four extra-parent cases rejected")
  for first, second in [
      (archive, Path(os.environ["repacked"]) / archive.name),
      (exe, Path(os.environ["repackedInstaller"]) / exe.name),
  ]:
      assert first.read_bytes() == second.read_bytes(), f"non-deterministic repack: {first.name}"
      report.append(f"independent packaging realizations byte-identical: {first.name}: "
                    + hashlib.sha256(first.read_bytes()).hexdigest())
  Path(os.environ["out"]).write_text("\n".join(report) + "\n")
  print("\n".join(report))
  PY
''
