"""Stable manual-copy/source ZIPs: sorted entries, fixed time and permissions."""
from pathlib import Path
import sys
import zipfile

root, destination = map(Path, sys.argv[1:])
with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED,
                     compresslevel=9) as archive:
    for path in sorted(root.rglob('*')):
        if path.is_file():
            info = zipfile.ZipInfo(path.relative_to(root).as_posix(), (1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED,
                             compresslevel=9)
