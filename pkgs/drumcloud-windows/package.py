"""Deterministic packaging and static PE inspection; never execute payloads."""

import json
import os
from pathlib import Path
import sys
import zipfile


def package(root, destination):
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for file in sorted(root.rglob("*")):
            if file.is_file():
                info = zipfile.ZipInfo(file.relative_to(root).as_posix(), (1980, 1, 1, 0, 0, 0))
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                archive.writestr(info, file.read_bytes(), compresslevel=9)


def imports(root):
    import pefile

    result = {}
    for pattern in ("CLAP/*.clap", "VST3/*/Contents/x86_64-win/*.vst3"):
        for file in sorted(root.glob(pattern)):
            pe = pefile.PE(str(file))
            result[file.relative_to(root).as_posix()] = sorted(
                entry.dll.decode().lower() for entry in pe.DIRECTORY_ENTRY_IMPORT
            )
    (root / "Notices/PE-IMPORTS.json").write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    if sys.argv[1] == "--imports":
        imports(Path(sys.argv[2]))
    elif sys.argv[1] == "--normalize":
        root = Path(sys.argv[2])
        for file in [root, *root.rglob("*")]:
            os.utime(file, (315532800, 315532800))
    else:
        package(Path(sys.argv[1]), sys.argv[2])
