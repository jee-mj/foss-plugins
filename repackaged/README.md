# Repackaged Assets

This directory contains proprietary or manually-downloaded files required by certain package derivations.
These files are NOT committed to the git repository (see `.gitignore`).

## Files needed

### MT Power Drum Kit 2

Place the following files in this directory:

- `MTPDK-2.1.5.0-VST3-64bit-Linux-FULL.zip` (61.2 MB)
  - Download from: https://www.powerdrumkit.com/linux.php
  - SHA256: `kL+1M4s+d28rHuhW4yuCxDa2he3Q2uYVty3aENFCzUQ=`

- `MT-PowerDrumKit_2_Drum_Map_for_Ardour.zip`
  - Download from: https://www.powerdrumkit.com/download76187.php
  - SHA256: `idL4EhtQz7DW9taBFHmDRJxPj3V0deGJg9oYPFZQ3u4=`

### NeuralNote ONNX Runtime

Place the result of building ONNX Runtime from ort-builder here:

- `onnxruntime-neuralnote/` directory containing:
  - `lib/libonnxruntime.a`
  - `include/onnxruntime/`
  - `model.with_runtime_opt.ort` (optional — already committed in NeuralNote source)

  Build from: https://github.com/tiborvass/libonnxruntime-neuralnote

## Usage

After placing the files, build with:

```bash
# MT Power Drum Kit
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#mt-power-drum-kit

# NeuralNote (once ONNX Runtime is built)
nix build .#neuralnote
```
