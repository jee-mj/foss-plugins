# Deliverable A — Executive Matrix

**Audit date:** 2026-07-22  
**Review scope:** 9 candidates for NixOS workstation integration  
**Reviewed by:** foss-plugins security review  

---

## Classification summary

| Project | Source | Reviewed Rev | Source Licence | Asset Licences | Source Complete? | Linux Formats | Build Status | Network | Filesystem | RT Safety | Nix Packageable? | Redistribution | Classification | Confidence |
|---------|--------|-------------|----------------|----------------|-----------------|---------------|--------------|---------|------------|-----------|------------------|----------------|----------------|------------|
| **Cavey** | github.com/TarcanGul/cavey | `master` (shallow) | AGPL-3.0-or-later | compatible | ✅ | VST3, Standalone | JUCE+Boost via FetchContent/vcpkg, needs net for first build | localhost:11434 only (Ollama) | Settings XML + log | ✅ SAFE — no LLM in audio callback | ✅ (with vcpkg/Ollama deps) | ✅ AGPL-3.0 permits | **accept-experimental** | High |
| **PedalKernel** | github.com/ajmwagar/pedalkernel | `main` (shallow) | AGPL-3.0 + §7 commercial restriction | compatible | ⚠️ VST3 bindings are commercial (not in repo) | CLI/JACK only (no VST3 in repo) | ✅ Hermetic (Cargo) | NONE | CLI export paths only | ✅ SAFE — alloc-free, lock-free for CLI procs | ✅ (CLI only) | ✅ AGPLv3 permits | **blocked-pending-upstream** | Medium |
| **MT Power Drum Kit 2** | powerdrumkit.com (Manda Audio) | v2.1.5.0 binary | **Proprietary** (EULA) | Proprietary | ❌ No source | VST3, Standalone | ❌ N/A (binary download) | ⚠️ UNKNOWN — binary inspection needed | ⚠️ UNKNOWN | ⚠️ UNKNOWN | ✅ FOD if EULA permits | ⚠️ EULA must be reviewed | **binary-only-manual-approval** | Low |
| **PartialString** | differentinstruments.com (Christian Baker) | v1.0.3 binary | **Proprietary** (free/PWYW, no OSI licence) | Proprietary | ❌ No source (gostringsynth is predecessor only) | VST3 | ❌ N/A (binary download) | ⚠️ UNKNOWN | ⚠️ UNKNOWN | ⚠️ UNKNOWN | ✅ FOD if redistribution OK | ⚠️ Need permission | **blocked-pending-upstream** | Low |
| **OpenKick** | github.com/navidsatarmaker/OpenKick | `main` (shallow) | **MISSING** (README claims MIT but no LICENSE file) | ⚠️ Unresolved | ✅ (small, self-contained) | VST3, Standalone | ⚠️ `GIT_TAG master` — non-deterministic | NONE | DAW state only | ✅ SAFE — no alloc/lock/IO | ✅ (after pinning JUCE) | ⚠️ No LICENSE file | **blocked-pending-upstream** | Medium |
| **Lumen** | github.com/pixelsncodes/lumen | `main` (shallow) | MIT | ⚠️ lumena submodule uninit, Inter fonts (OFL) | ⚠️ lumena submodule empty | VST3, Standalone | ⚠️ FetchContent JUCE + submodule | NONE | DAW state only | ✅ SAFE — FIFOs, atomics, ScopedNoDenormals | ⚠️ lumena dep missing | ✅ MIT permits | **blocked-pending-upstream** | Medium |
| **Setekh** | github.com/fullfxmedia/setekh | `main` (shallow) | GPL-3.0 | compatible | ✅ | VST3, AU, CLAP, LV2 | ⚠️ CPM fetches JUCE+clap-ext | NONE (hyperlinks only) | DAW state only | ⚠️ Missing ScopedNoDenormals | ✅ | ✅ GPLv3 permits | **accept-source** | High |
| **NeuralNote** | github.com/DamRsn/NeuralNote | v1.1.0 (`113f058`) | Apache-2.0 | ⚠️ Fonts/icon licences need verification | ✅ | VST3, Standalone | ⚠️ ONNX Runtime binary fetch + git submodules | ⚠️ v1.1.0 update notification | Recording to user dir | ✅ SAFE — transcription is offline | ✅ (with FOD for ONNX Runtime) | ✅ Apache-2.0 permits | **accept-source** | High |
| **RipplerX** | github.com/tiagolr/ripplerx | v1.5.19 (`7da35e4`) | GPL-3.0 | compatible | ✅ | VST3, LV2, AU | ⚠️ git submodule JUCE (unpinned) | NONE (hyperlinks only) | Settings + preset import/export | ✅ SAFE — ScopedNoDenormals, bounds-checked | ✅ (after pinning submodules) | ✅ GPLv3 permits | **accept-source** | High |

---

## Classification key

| Classification | Meaning | Count |
|----------------|---------|-------|
| **accept-source** | Source complete, licensed, buildable, low-risk. Can be packaged normally. | 3 (Setekh, NeuralNote, RipplerX) |
| **accept-experimental** | Acceptable with opt-in quarantined set, runtime restrictions, or documented caveats. | 1 (Cavey) |
| **binary-only-manual-approval** | No source; vendor binary may be locally wrapped after licensing/security approval. Must not enter public caches unless redistribution authorised. | 1 (MT Power Drum Kit 2) |
| **blocked-pending-upstream** | Material questions require upstream clarification (source completeness, licensing, buildability). | 4 (PedalKernel, PartialString, OpenKick, Lumen) |
| **reject** | Risks, licence problems, source/binary mismatch, unsafe execution model, or maintenance condition make unsuitable. | 0 |

---

## Priority-adjusted action plan

### Immediate (accept-source candidates)

1. **Setekh** — Package first. Clear GPL-3.0, LV2+VST3+CLAP, simple DSP. Only concern: missing ScopedNoDenormals (patch trivial). No CI (documentation-only issue).
2. **NeuralNote** — Package with fixed-output derivation for ONNX Runtime. Audit update notification before finalizing. Apache-2.0. Pre-reviewed in `docs/neuralnote-review.md`.
3. **RipplerX** — Package after pinning JUCE submodule to explicit commit. GPL-3.0 confirmed. Mature CI with tagged releases.

### Quarantine (experimental)

4. **Cavey** — Requires Ollama (localhost). AGPL-3.0. LLM output is sanitized (JSON coefficients only, no code execution). Classify as experimental due to LLM integration dependency and network surface (even though localhost-only).

### Requires upstream resolution

5. **OpenKick** — MISSING LICENSE file. Blocked until upstream adds one. Otherwise clean codebase, RT-safe, no network.
6. **Lumen** — Missing `lumena` submodule content. Blocked until upstream clarifies dependency. MIT licence, otherwise clean.
7. **PedalKernel** — Production VST3 bindings are commercial (not in this repo). The public repo is CLI/compiler only. Blocked for DAW use; acceptable for CLI experimentation.
8. **PartialString** — Proprietary freeware, no public source. "Free or PWYW" but not open source. Author contact available (crnbaker on GitHub). Blocked pending permission/dual-licensing decision.

### Proprietary binary

9. **MT Power Drum Kit 2** — Proprietary EULA-governed freeware. Binary inspection required before local wrapping. Redistribution likely prohibited. Manual approval needed per EULA terms.

---

## Residual risk heatmap

| Risk Category | Cavey | PedalKernel | MT-PDK2 | PartialString | OpenKick | Lumen | Setekh | NeuralNote | RipplerX |
|---------------|-------|-------------|---------|---------------|----------|-------|--------|------------|----------|
| Licence ambiguity | 🟢 | 🟡 | 🔴 | 🔴 | 🔴 | 🟢 | 🟢 | 🟡 | 🟢 |
| Network surface | 🟡 | 🟢 | 🔴 | 🔴 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |
| Build hermeticity | 🟡 | 🟢 | 🔴 | 🔴 | 🔴 | 🟡 | 🟡 | 🟡 | 🟡 |
| RT safety | 🟢 | 🟢 | 🔴 | 🔴 | 🟢 | 🟢 | 🟡 | 🟢 | 🟢 |
| Code execution risk | 🟢 | 🟢 | 🔴 | 🔴 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |
| Supply-chain risk | 🟡 | 🟡 | 🔴 | 🔴 | 🟡 | 🟡 | 🟢 | 🟡 | 🟢 |
| Source completeness | 🟢 | 🟡 | 🔴 | 🔴 | 🟢 | 🟡 | 🟢 | 🟢 | 🟢 |

🟢 = Low risk | 🟡 = Moderate risk | 🔴 = High risk / unknown without evidence
