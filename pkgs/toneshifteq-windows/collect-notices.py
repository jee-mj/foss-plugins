"""Copy complete license files from public dependency sources without extraction."""
from pathlib import Path, PurePosixPath
import sys
import tarfile

source, destination = map(Path, sys.argv[1:])


def is_notice(name):
    return name.upper().startswith(('LICENSE', 'LICENCE', 'COPYING', 'COPYRIGHT', 'DISCLAIMER', 'NOTICE'))


def write(relative, data):
    path = PurePosixPath(relative)
    if path.is_absolute() or '..' in path.parts:
        raise ValueError(f'Unsafe notice path: {relative}')
    target = destination.joinpath(*path.parts)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)


if source.is_dir():
    for path in sorted(source.rglob('*')):
        if path.is_file() and not path.is_symlink() and is_notice(path.name):
            write(path.relative_to(source).as_posix(), path.read_bytes())
else:
    with tarfile.open(source) as archive:
        for member in archive:
            if member.isfile() and is_notice(PurePosixPath(member.name).name):
                relative = PurePosixPath(member.name).parts[1:]
                if relative:
                    write('/'.join(relative), archive.extractfile(member).read())
