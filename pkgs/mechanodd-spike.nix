{ lib, runCommand }:

# This temporary derivation proves unfree laziness only.  It is replaced by the
# real source package after the implementation plan is approved.
runCommand "mechanodd-laziness-spike" {
  meta = {
    description = "Unknown-license MechanOdd laziness preflight";
    homepage = "https://github.com/odoare/Mechanodd";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out/share"
  touch "$out/share/mechanodd-laziness-spike"
''
