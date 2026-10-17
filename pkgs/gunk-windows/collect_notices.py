"""Lossless raw-byte notice stream and reconstruction index for pinned JUCE modules."""
import hashlib
import json
import sys
from pathlib import Path

modules_root, destination = map(Path, sys.argv[1:3])
modules = sys.argv[3:]
paths = sorted(path for module in modules for path in (modules_root / module).rglob("*")
               if path.is_file())
destination.mkdir(parents=True, exist_ok=True)
records = []
source_bytes = 0
with (destination / "JUCE-component-source-notices.txt").open("wb") as stream:
    stream.write(b"JUCE 7.0.12 embedded component notices and complete module source bytes\n"
                 b"Source bytes are unmodified, including line endings and binary bytes.\n"
                 b"Use JUCE-component-source-index.json byte offsets for exact reconstruction.\n")
    for path in paths:
        if path.is_symlink():
            raise ValueError(f"unexpected source symlink: {path}")
        name = path.relative_to(modules_root).as_posix()
        data = path.read_bytes()
        stream.write(f"\n===== BEGIN SOURCE FILE: {name} ({len(data)} bytes) =====\n".encode("utf-8"))
        records.append({"path": name, "offset": stream.tell(), "length": len(data),
                        "sha256": hashlib.sha256(data).hexdigest()})
        stream.write(data)
        stream.write(f"\n===== END SOURCE FILE: {name} =====\n".encode("utf-8"))
        source_bytes += len(data)
    stream_bytes = stream.tell()
index = {"format": "juce-component-source-notices-v1", "file_count": len(records),
         "source_bytes": source_bytes, "stream_bytes": stream_bytes, "records": records}
(destination / "JUCE-component-source-index.json").write_bytes(
    (json.dumps(index, sort_keys=True, indent=2) + "\n").encode("utf-8"))
