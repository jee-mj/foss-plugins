{ runCommand, python3, binding, artifactCheck }:
runCommand "basilica-${binding.name}-current-proof" {
  nativeBuildInputs = [ python3 ];
} ''
  python3 ${./write-proof.py} \
    ${builtins.toFile "basilica-${binding.name}-binding.json" (builtins.unsafeDiscardStringContext (builtins.toJSON binding))} \
    ${artifactCheck} "$out"
''
