#!/usr/bin/env python3
"""Join exactly 104 offline assessment reports without changing catalog identity."""

import argparse
import json
import os
from pathlib import Path
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib.catalog_acceleration import validation_errors


ROOT = Path(__file__).resolve().parents[1]
IDENTITIES = ROOT / "tests/audio-catalog-identities.json"
IDS = [f"AUDIO-{i:03d}" for i in range(1, 105)]


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key {key}")
        result[key] = value
    return result


def _decode(data):
    return json.loads(data, object_pairs_hook=_unique_object)


def _entries(catalog, identities):
    if not isinstance(catalog, dict) or type(catalog.get("schema_version")) is not int or catalog["schema_version"] not in (1, 2):
        raise ValueError("catalog requires schema_version 1 or 2")
    entries = catalog.get("entries")
    if not isinstance(entries, list) or len(entries) != 104:
        raise ValueError("catalog requires exactly 104 entries")
    indexed = {}
    for entry in entries:
        if not isinstance(entry, dict) or not isinstance(entry.get("id"), str):
            raise ValueError("malformed catalog entry")
        ident = entry["id"]
        if ident in indexed:
            raise ValueError(f"duplicate catalog ID {ident}")
        indexed[ident] = entry
    if {k: e.get("repository") for k, e in indexed.items()} != identities:
        raise ValueError("catalog identity differs from captured ID-to-repository fixture")
    return indexed


def merge(catalog_path, reports_dir, output_path):
    """Validate completely before atomic replacement; return the merged catalog.

    The byte comparison guards cooperative in-place edits during validation.
    It is deliberately immediately before replace, but is not a filesystem CAS.
    """
    catalog_path, reports_dir, output_path = map(Path, (catalog_path, reports_dir, output_path))
    initial = catalog_path.read_bytes()
    catalog = _decode(initial)
    identities = _decode(IDENTITIES.read_bytes())
    if not isinstance(identities, dict) or sorted(identities) != IDS:
        raise ValueError("identity fixture must contain the original 104 IDs")
    entries = _entries(catalog, identities)
    if not reports_dir.is_dir():
        raise ValueError("reports must be a directory")
    reports = {}
    for path in sorted(reports_dir.glob("*.json")):
        report = _decode(path.read_bytes())
        if not isinstance(report, dict) or set(report) != {"id", "acceleration"} or not isinstance(report["id"], str):
            raise ValueError(f"{path.name}: report must contain only id and acceleration")
        ident = report["id"]
        if ident not in entries:
            raise ValueError(f"extra report ID {ident}")
        if ident in reports:
            raise ValueError(f"duplicate report ID {ident}")
        errors = validation_errors(report)
        if errors:
            raise ValueError(f"{ident}: " + "; ".join(errors))
        reports[ident] = report["acceleration"]
    missing = sorted(set(entries) - set(reports))
    if missing:
        raise ValueError("missing report IDs: " + ", ".join(missing))
    catalog["entries"] = [dict(entries[ident], acceleration=reports[ident]) for ident in IDS]
    catalog["schema_version"] = 2
    _entries(catalog, identities)
    data = (json.dumps(catalog, indent=2, sort_keys=True, ensure_ascii=False, allow_nan=False) + "\n").encode("utf-8")
    in_place = catalog_path.resolve() == output_path.resolve()
    if not in_place and output_path.exists():
        in_place = os.path.samefile(catalog_path, output_path)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="wb", dir=output_path.parent, prefix=".merge-acceleration-", suffix=".tmp", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        if in_place and catalog_path.read_bytes() != initial:
            raise ValueError("input catalog changed during in-place merge")
        os.replace(temporary, output_path)
        temporary = None
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return catalog


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--reports", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        merge(args.catalog, args.reports, args.output)
    except (ValueError, OSError, UnicodeError) as error:
        parser.exit(1, f"merge-acceleration: {error}\n")
    print("Merged 104 acceleration reports (schema_version 2).")


if __name__ == "__main__":
    main()
