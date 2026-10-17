# Product and route catalog

`lib/product_catalog.py` validates source-backed product reports without network
access, building, downloading, or executing plugins or installers. It uses the
captured identity map in `tests/product-catalog-identities.json`: AUDIO-001 through
AUDIO-104 followed by ten additional BA repositories in numeric order. The
original 104 mappings are independently checked against the earlier capture.

Three BA identities are aliases of existing primaries, never additional reports:
AUDIO-003 → BA-013, AUDIO-007 → BA-006, AUDIO-058 → BA-004. Repository spelling and
aliases must match the fixture exactly. Repository uniqueness is also checked
case-insensitively.

## Merge an offline capture

```sh
python scripts/merge-product-reports.py --reports REPORT_DIRECTORY --output OUTPUT_FILE
```

The directory must contain exactly one `<primary-identity>.json` regular file for
each of the 114 identities. Missing or extra files, duplicate JSON keys (including
nested keys), non-JSON constants, filename/identity mismatches and invalid reports
fail before any output replacement. Symlink reports are rejected. Successful
output is serialized deterministically into a temporary file beside the output,
flushed and atomically replaced. An invalid merge leaves existing output intact.
The output must be outside the report directory and must not overwrite the
identity fixture. This is an offline capture merge, not a filesystem transaction
against concurrently changing inputs.

Output schema version 1 contains `captured_date` (`2026-10-17`), `source_catalog`
(`catalog/audio-104.json`), `repositories` (the ordered reports) and
`product_count`. Product order within a report is preserved. The captured 165
records are known source/delivery targets, including applications, utilities and
firmware. This count is not an installed-plugin count, artifact inventory or
readiness claim; a later reviewed capture may have a different count.

## Validation API and report structure

```python
from lib.product_catalog import validation_errors, merge_reports

errors = validation_errors(report)  # deterministic list of path-qualified strings
catalog = merge_reports(reports)   # ValueError on any invalid or incomplete set
```

Reports require `identity`, `repository`, `alias_ids`, `source_revision`,
`disposition`, `reason`, `products`, `evidence`, `copyright_notes`, `next_action`.
Disposition is `applicable`, `needs-evidence` or `skip`. An unavailable source
revision is null with an explicit evidence gap in the reason. A revision, when
given, is a full 40- or 64-hex commit. Pinned reports require matching evidence
for their primary repository. Evidence objects contain `url`, `revision`,
`summary`; URLs must be public HTTPS without credentials. Strict IPv4 and IPv6
literals must be globally routable; ambiguous numeric spellings (shortened,
zero-padded or hexadecimal addresses) cannot fall back to DNS hostnames.

Primary source evidence supports `https://github.com/OWNER/REPO/` followed by
`blob/COMMIT/PATH`, `tree/COMMIT[/PATH]`, `commit/COMMIT` or `raw/COMMIT/PATH`,
and `https://raw.githubusercontent.com/OWNER/REPO/COMMIT/PATH`. The embedded
commit must be full-length and exactly equal to the evidence revision. Primary
source evidence must also match the report's canonical repository and source
revision. Mutable branch/tag refs are rejected in these source forms, even if
the evidence separately declares a full commit. Release pages, package indexes
and unsupported URL forms are supplementary only; they cannot establish the
source revision. Supplementary evidence may have a null revision.

Public metadata recursively rejects known private project markers, recognizable
credential-bearing URLs in prose, and local paths (including root-home and UNC
paths). Both nested keys and values are checked after percent decoding. Ordinary
uses of the word "private" and escaped source plugin identifiers remain valid.
This structural filter is not a general secret scanner; review free-form prose
before publication.

Products require `id`, `name`, `kind`, `formats`, `plugin_ids`, `native`, `windows`.
The ID is `<primary-identity>/<lowercase-hyphenated-source-target-slug>`, unique
within the report. Kinds are `instrument`, `effect`, `midi`, `application`,
`utility`, `scaffold`, `unknown`. Formats are evidenced target names, not inferred
host capabilities. Unresolved formats and missing plugin IDs may remain empty.
`plugin_ids` maps listed formats to source identifiers; nested source-code fields,
explicit nulls, byte strings, numeric IDs and four-word FUID arrays are retained.
The validator never derives a class UUID from manufacturer/plugin codes.

### Lossless source-ID encoding

Raw reports may contain actual NUL characters in source-ID string values.
Canonical merging deep-copies validated reports and recursively replaces only
those string values inside `products[*].plugin_ids` with:

```json
{"source_encoding": "utf8-hex", "bytes_hex": "4175746f6b69744472756d4d30303100"}
```

This example round-trips the exact 16 UTF-8 bytes of the source identifier
`AutokitDrumM001` followed by NUL. Consumers recover the original bytes by hex
decoding `bytes_hex`, and the original string by strict UTF-8 decoding. This is a
catalog representation namespace for the same opaque upstream ID, not a new UUID.
No bytes are guessed, padded, truncated or implicitly interpreted as UUIDs.
Other formats may have different byte lengths; no universal 16-byte rule applies.

An encoding object has exactly the two keys shown, the marker `utf8-hex`, and a
nonempty string of contiguous hexadecimal byte pairs. Decoded bytes must be valid
UTF-8 containing an actual NUL; this escape format is reserved for NUL-bearing
source IDs. Decoded text remains subject to public-metadata checks. Raw report
validation still accepts NULs only in source-ID values, not keys or prose.
Textual backslash-plus-`0` source literals remain unchanged. Reports supplied by
the caller remain unchanged, and merging canonical reports again is idempotent.
Canonical output contains no actual NUL string values and is suitable for JSON
consumers whose string representation cannot contain NULs.

Native routes require `status`, `attributes`, `reason`, `next_action`. Status is
`packaged`, `reuse-nixpkgs`, `source-candidate`, `upstream-binary`, `port-required`,
`not-applicable`, `needs-evidence`. Packaged/reuse routes require package references.

Windows routes require `status`, `architecture`, `toolchain`, `artifact_type`,
`installer_source_status`, `reason`, `next_action`. Status is `source-candidate`,
`requires-windows-builder`, `upstream-fallback`, `port-required`, `not-applicable`,
`needs-evidence`. Architectures are `x86_64`, `x86`, `arm64`, `multi`, `unknown`.
Artifact types are `manual-copy-archive`, `exe-installer`, `msi-installer`,
`installer-zip`, `plugin-bundle`, `source-only`, `unknown`, `none`.
Installer-source statuses are `present`, `not-found`, `unverified`,
`not-applicable`. A plugin ZIP does not establish an installer. Build success,
installation and readiness are not route statuses.

## Evidence boundary

Validation checks structure, identity and internal pin consistency, not the truth
of upstream statements, actual package exports or payload contents. Source
inspection must separately confirm targets, source identifiers, dependencies,
build definitions and release provenance. No source-verification callback is
executed by the validator or merger. Copyright notes are retained as information;
missing or unclear licensing is not converted into a technical route gate.
`needs-evidence` and `skip` records are retained unchanged.

Run the portable tests, optionally including an external report capture:

```sh
python -m unittest discover -s tests -p test_product_catalog.py -v
PRODUCT_REPORTS=REPORT_DIRECTORY python -m unittest discover -s tests -p test_product_catalog.py -v
```
