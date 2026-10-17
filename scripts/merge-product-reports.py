#!/usr/bin/env python3
"""Merge offline reports; validate completely before atomically replacing output."""

import argparse
import json
import os
from pathlib import Path
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
from product_catalog import IDENTITY_FIXTURE, load_json, merge_reports


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reports", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(argv)
    temporary = None
    try:
        identities = load_json(IDENTITY_FIXTURE)
        expected = {identity + ".json" for identity in identities}
        actual = {path.name for path in args.reports.iterdir()}
        if actual != expected:
            raise ValueError("report file set mismatch; missing=" + ",".join(sorted(expected - actual))
                             + "; extra=" + ",".join(sorted(actual - expected)))
        reports = []
        for identity in identities:
            path = args.reports / (identity + ".json")
            if path.is_symlink() or not path.is_file():
                raise ValueError(f"{identity}: report must be a regular, non-symlink file")
            report = load_json(path)
            if not isinstance(report, dict) or report.get("identity") != identity:
                raise ValueError(f"{identity}: filename/identity mismatch")
            reports.append(report)
        result = merge_reports(reports)
        output = args.output
        if output.resolve() == IDENTITY_FIXTURE.resolve() or output.resolve().is_relative_to(args.reports.resolve()):
            raise ValueError("output must not overwrite an identity fixture or input report")
        content = json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False, allow_nan=False) + "\n"
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=output.parent,
                                         prefix="." + output.name + ".", suffix=".tmp", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, output)
        temporary = None
        print(f"Merged {len(reports)} repositories, {result['product_count']} source/delivery records.")
        return 0
    except (OSError, ValueError, UnicodeError) as error:
        print(str(error), file=sys.stderr)
        return 1
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    sys.exit(main())
