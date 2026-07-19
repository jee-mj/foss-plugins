{ lib, runCommand }:

runCommand "foss-plugins-free-spike" {
  meta = {
    description = "Minimal free package used by the MechanOdd laziness preflight";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out/share"
  touch "$out/share/free-package-set-spike"
''
