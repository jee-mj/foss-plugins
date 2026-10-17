"""Deterministic, complete data archive; never follows symlinks."""
import sys
import zipfile
from pathlib import Path

root, output = map(Path, sys.argv[1:])
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for path in sorted(root.rglob('*')):
        if path.is_symlink():
            raise ValueError(f'symlink in payload: {path}')
        if path.is_file():
            info = zipfile.ZipInfo(path.relative_to(root).as_posix(), (1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, path.read_bytes(), compresslevel=9)
