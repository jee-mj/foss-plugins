# Audio catalog and first native batch — verification

Snapshot: 2026-10-17, x86_64-linux. This records a bounded first batch, not
completion of all 104 implementations. No system activation or DAW test occurred.

## Delivered

- 104 stable repository identities in `catalog/audio-104.json`, independent of
  Nix package availability and private workstation installer tooling.
- Public acquisition references for 24 Windows candidates, including the original
  Basilica suite; 22 exact asset selections and two unresolved/manual routes.
- Native source packages `peakeater` 0.8.2 and `toneshifteq` 1.3.0, each with
  VST3, CLAP and LV2 outputs. Source pins and build evidence are in their docs.
- Copyright evidence, uncertainty and consumer judgement recorded separately from
  implementation priority; no copyright-free claim based on AI involvement.

## Verification commands and observed results

Run from this checkout's Git root. CLI Git autodetection preserves the source
boundary; do not replace these commands with an unfiltered raw checkout import.

```sh
python3 tests/audio-catalog.py
nix build --no-link --no-write-lock-file --cores 4 --max-jobs 1 \
  .#peakeater .#toneshifteq \
  .#checks.x86_64-linux.audio-catalog \
  .#checks.x86_64-linux.peakeater \
  .#checks.x86_64-linux.toneshifteq \
  .#checks.x86_64-linux.free-package-set \
  .#checks.x86_64-linux.package-metadata \
  .#checks.x86_64-linux.module-default \
  .#checks.x86_64-linux.module-options \
  .#checks.x86_64-linux.plugin-artifacts
nix flake check --no-build --no-write-lock-file
git diff --check
git diff --cached --check
```

All commands exited zero. Six catalog tests passed, including the independent
captured ID-to-repository fixture. Both packages and eight selected checks built
successfully (previously built outputs may be reused). The ToneShiftEQ test was
subsequently strengthened to check immediate loading and format entrypoints for
all four ELF objects, then rebuilt successfully.

`nix flake check --no-build` evaluated all exported derivations; it does not build
every package/check. Nix emitted an expected `unknown flake output 'catalog'`
warning for the custom metadata output. The explicit catalog check validates it.
The existing Downspout build/check was evaluated, not rebuilt by these commands.

An independent review found no concrete defects in the two package recipes.
The catalog review identified missing stable identity regression coverage; the
independent fixture and sixth test address that gap. Layout/loading checks do
not instantiate plugins, create GUIs or prove audio correctness.

## Remaining work

- 102 catalog records are not new local package exports. Some already have
  independent nixpkgs routes; source-only and platform-uncertain entries need
  further work. Suites must be expanded before counting installable products.
- No Windows assets have been downloaded or installed by this batch; the manifest
  records upstream URLs/digests, not locally present sources or computed hashes.
- No consumer configuration was changed to select the two packages, and no
  system or user profile was activated. Native discovery and host acceptance
  remain consumer integration steps.
- All 104 catalog records remain runtime-untested. DAW scanning, GUI, audio/MIDI,
  automation, sidechains, latency and state recall must be exercised separately.
