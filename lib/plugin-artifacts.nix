{ lib }:

let
  formatDirectories = {
    vst3 = "lib/vst3";
    lv2 = "lib/lv2";
    clap = "lib/clap";
    standalone = "bin";
  };

  allowedTypes = [
    "file"
    "executable"
    "directory"
  ];

  fail = message: throw "plugin-artifacts: ${message}";

  isSafePath = path:
    builtins.isString path
    && path != ""
    && !(lib.hasPrefix "/" path)
    && !(lib.hasInfix "\n" path)
    && builtins.all (segment: segment != "" && segment != "." && segment != "..") (
      lib.splitString "/" path
    );

  isExactPath = path:
    isSafePath path
    && !(lib.hasInfix "*" path)
    && !(lib.hasInfix "?" path)
    && !(lib.hasInfix "[" path);

  validateArtifact = artifact:
    if !builtins.isAttrs artifact then
      fail "each artifact must be an attribute set"
    else
      let
        hasSource = artifact ? source;
        hasPattern = artifact ? pattern;
        sourceValue = if hasSource then artifact.source else artifact.pattern;
      in
      if !(artifact ? format && builtins.isString artifact.format) then
        fail "each artifact must declare a string format"
      else if !builtins.hasAttr artifact.format formatDirectories then
        fail "unsupported artifact format: ${artifact.format}"
      else if !(artifact ? type && builtins.isString artifact.type && builtins.elem artifact.type allowedTypes) then
        fail "each artifact must declare type file, executable, or directory"
      else if !(artifact ? destination && isSafePath artifact.destination) then
        fail "each artifact destination must be a safe relative path"
      else if hasSource == hasPattern then
        fail "each artifact must declare exactly one of source and pattern"
      else if !builtins.isString sourceValue then
        fail "each artifact source or pattern must be a string"
      else if !(if hasSource then isExactPath sourceValue else isSafePath sourceValue) then
        fail "each artifact source or pattern must be a safe relative path"
      else if hasPattern && lib.hasInfix "**" sourceValue then
        fail "artifact patterns must not contain **"
      else
        {
          format = artifact.format;
          type = artifact.type;
          destination = artifact.destination;
          sourceKind = if hasSource then "source" else "pattern";
          inherit sourceValue;
          outputDirectory = formatDirectories.${artifact.format};
        };

  renderArtifact = artifact:
    let
      label = "${artifact.format}/${artifact.destination}";
      sourceSetup =
        if artifact.sourceKind == "source" then
          ''
            source_path="$source_root"/${lib.escapeShellArg artifact.sourceValue}
          ''
        else
          ''
            pattern=${lib.escapeShellArg artifact.sourceValue}
            matches=()
            mapfile -t matches < <(compgen -G "$source_root/$pattern" || true)
            if [ "''${#matches[@]}" -ne 1 ]; then
              printf '%s\n' ${lib.escapeShellArg "plugin-artifacts: ${label} pattern matched zero or multiple artifacts"} >&2
              exit 1
            fi
            source_path="''${matches[0]}"
            source_root_real="$(realpath -e "$source_root")"
            source_path_real="$(realpath -e "$source_path")"
            case "$source_path_real" in
              "$source_root_real" | "$source_root_real"/*)
                ;;
              *)
                printf '%s\n' ${lib.escapeShellArg "plugin-artifacts: ${label} pattern resolved outside sourceRoot"} >&2
                exit 1
                ;;
            esac
          '';
      typeCheck =
        if artifact.type == "file" then
          ''
            if ! [ -f "$source_path" ] || [ -L "$source_path" ]; then
              printf '%s\n' ${lib.escapeShellArg "plugin-artifacts: ${label} is not a regular file"} >&2
              exit 1
            fi
          ''
        else if artifact.type == "executable" then
          ''
            if ! [ -f "$source_path" ] || [ -L "$source_path" ] || ! [ -x "$source_path" ]; then
              printf '%s\n' ${lib.escapeShellArg "plugin-artifacts: ${label} is not an executable file"} >&2
              exit 1
            fi
          ''
        else
          ''
            if ! [ -d "$source_path" ] || [ -L "$source_path" ]; then
              printf '%s\n' ${lib.escapeShellArg "plugin-artifacts: ${label} is not a directory"} >&2
              exit 1
            fi
          '';
      modeCheck = lib.optionalString (artifact.format == "standalone") ''
        if [ "$(stat -c %a "$source_path")" != "$(stat -c %a "$destination_path")" ]; then
          printf '%s\n' ${lib.escapeShellArg "plugin-artifacts: ${label} mode changed during installation"} >&2
          exit 1
        fi
      '';
    in
    ''
      ${sourceSetup}
      ${typeCheck}
      destination_path="$out"/${lib.escapeShellArg artifact.outputDirectory}/${lib.escapeShellArg artifact.destination}
      if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
        printf '%s\n' ${lib.escapeShellArg "plugin-artifacts: destination already exists for ${label}"} >&2
        exit 1
      fi
      mkdir -p "$(dirname "$destination_path")"
      cp -a "$source_path" "$destination_path"
      ${modeCheck}
    '';

  install =
    {
      sourceRoot,
      artifacts,
    }:
    if !isExactPath sourceRoot then
      fail "sourceRoot must be a safe exact relative path"
    else if !builtins.isList artifacts then
      fail "artifacts must be a list"
    else
      let
        validatedArtifacts = builtins.map validateArtifact artifacts;
      in
      builtins.deepSeq validatedArtifacts (
        let
          destinations = builtins.map (
            artifact: "${artifact.format}/${artifact.destination}"
          ) validatedArtifacts;
        in
        if builtins.length destinations != builtins.length (lib.unique destinations) then
          fail "artifact destinations must be unique per format"
        else
          ''
            source_root=${lib.escapeShellArg sourceRoot}
            ${lib.concatMapStringsSep "\n" renderArtifact validatedArtifacts}
          ''
      );
in
{
  inherit install;
}
