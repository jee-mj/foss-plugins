"""Canonical manual-copy archive; never loads or executes a Windows payload."""

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


if __name__ == "__main__":
    if sys.argv[1] == "--normalize":
        root = Path(sys.argv[2])
        for file in [root, *root.rglob("*")]:
            os.utime(file, (315532800, 315532800))
    else:
        package(Path(sys.argv[1]), sys.argv[2])
