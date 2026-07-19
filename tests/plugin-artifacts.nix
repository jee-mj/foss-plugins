{ bash, runCommand, pluginArtifacts }:

let
  fixtures = {
    valid-file-and-bundle = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "Plugin.clap";
          type = "executable";
          destination = "Plugin.clap";
        }
        {
          format = "vst3";
          source = "Plugin.vst3";
          type = "directory";
          destination = "Plugin.vst3";
        }
        {
          format = "standalone";
          source = "Plugin";
          type = "executable";
          destination = "Plugin";
        }
      ];
    };

    missing-artifact = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "missing.clap";
          type = "executable";
          destination = "missing.clap";
        }
      ];
    };

    ambiguous-pattern = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          pattern = "*.clap";
          type = "executable";
          destination = "Plugin.clap";
        }
      ];
    };

    wrong-type = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "Plugin.vst3";
          type = "executable";
          destination = "Plugin.vst3";
        }
      ];
    };

    duplicate-destination = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "first.clap";
          type = "executable";
          destination = "first.clap";
        }
        {
          format = "clap";
          source = "second.clap";
          type = "executable";
          destination = "first.clap";
        }
      ];
    };

    traversal = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "../escape.clap";
          type = "executable";
          destination = "escape.clap";
        }
      ];
    };

    source-and-pattern = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "Plugin.clap";
          pattern = "*.clap";
          type = "executable";
          destination = "Plugin.clap";
        }
      ];
    };

    missing-source-and-pattern = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          type = "executable";
          destination = "Plugin.clap";
        }
      ];
    };

    unsupported-format = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "au";
          source = "Plugin.au";
          type = "file";
          destination = "Plugin.au";
        }
      ];
    };

    unsupported-type = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "Plugin.clap";
          type = "symlink";
          destination = "Plugin.clap";
        }
      ];
    };

    absolute-path = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "/Plugin.clap";
          type = "executable";
          destination = "Plugin.clap";
        }
      ];
    };

    empty-segment = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "nested//Plugin.clap";
          type = "executable";
          destination = "Plugin.clap";
        }
      ];
    };

    dot-segment = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "./Plugin.clap";
          type = "executable";
          destination = "Plugin.clap";
        }
      ];
    };

    globstar-pattern = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          pattern = "**/*.clap";
          type = "executable";
          destination = "Plugin.clap";
        }
      ];
    };

    glob-bearing-source = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          source = "Plugin*.clap";
          type = "executable";
          destination = "Plugin.clap";
        }
      ];
    };

    dot-prefixed-traversal-pattern = {
      sourceRoot = "build";
      artifacts = [
        {
          format = "clap";
          pattern = ".?/outside.clap";
          type = "executable";
          destination = "escaped.clap";
        }
      ];
    };
  };

  expectsStaticFailure = name: manifest:
    if (builtins.tryEval (builtins.deepSeq (pluginArtifacts.install manifest) true)).success then
      throw "plugin-artifacts fixture expected ${name} to fail during evaluation"
    else
      true;

  staticFailures = [
    "duplicate-destination"
    "traversal"
    "source-and-pattern"
    "missing-source-and-pattern"
    "unsupported-format"
    "unsupported-type"
    "absolute-path"
    "empty-segment"
    "dot-segment"
    "globstar-pattern"
    "glob-bearing-source"
  ];
in
assert builtins.all (name: expectsStaticFailure name fixtures.${name}) staticFailures;
runCommand "foss-plugins-plugin-artifacts" { } ''
  ${bash}/bin/bash -euo pipefail <<'EOF'
  mkdir -p build/Plugin.vst3/Contents/x86_64-linux
  printf '%s\n' plugin > build/Plugin.clap
  chmod 751 build/Plugin.clap
  printf '%s\n' bundle > build/Plugin.vst3/Contents/x86_64-linux/Plugin.so
  printf '%s\n' standalone > build/Plugin
  chmod 751 build/Plugin
  printf '%s\n' second > build/Second.clap
  chmod 751 build/Second.clap
  printf '%s\n' outside > outside.clap
  chmod 751 outside.clap

  ${pluginArtifacts.install fixtures."valid-file-and-bundle"}

  test "$(stat -c %a "$out/lib/clap/Plugin.clap")" = 751
  test -f "$out/lib/vst3/Plugin.vst3/Contents/x86_64-linux/Plugin.so"
  test "$(stat -c %a "$out/bin/Plugin")" = 751

  if (
    out="$TMPDIR/missing-artifact"
    ${pluginArtifacts.install fixtures."missing-artifact"}
  ); then
    printf '%s\n' "missing artifact unexpectedly installed" >&2
    exit 1
  fi

  if (
    out="$TMPDIR/ambiguous-pattern"
    ${pluginArtifacts.install fixtures."ambiguous-pattern"}
  ); then
    printf '%s\n' "ambiguous pattern unexpectedly installed" >&2
    exit 1
  fi

  if (
    out="$TMPDIR/wrong-type"
    ${pluginArtifacts.install fixtures."wrong-type"}
  ); then
    printf '%s\n' "wrong artifact type unexpectedly installed" >&2
    exit 1
  fi

  dot_prefixed_out="$TMPDIR/dot-prefixed-traversal"
  if (
    shopt -s dotglob
    shopt -u globskipdots
    out="$dot_prefixed_out"
    ${pluginArtifacts.install fixtures."dot-prefixed-traversal-pattern"}
  ); then
    printf '%s\n' "dot-prefixed traversal pattern unexpectedly installed" >&2
    exit 1
  fi
  test ! -e "$dot_prefixed_out/lib/clap/escaped.clap"
  EOF
''
