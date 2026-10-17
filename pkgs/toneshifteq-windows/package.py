"""Deterministic manual-copy ZIP; no Windows payload is executed."""
import os
from pathlib import Path
import sys
import zipfile

if sys.argv[1] == "--normalize":
    root = Path(sys.argv[2])
    for path in [root, *root.rglob("*")]:
        os.utime(path, (315532800, 315532800))
else:
    root = Path(sys.argv[1])
    with zipfile.ZipFile(sys.argv[2], "w") as archive:
        for path in sorted(root.rglob("*")):
            if path.is_file():
                info = zipfile.ZipInfo(path.relative_to(root).as_posix(), (1980, 1, 1, 0, 0, 0))
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                archive.writestr(info, path.read_bytes(), compresslevel=9)
