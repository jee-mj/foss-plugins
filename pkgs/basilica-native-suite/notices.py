"""Copy license/copyright/third-party evidence preserving source-relative paths."""
import shutil
import sys
from pathlib import Path

source, destination = map(Path,sys.argv[1:])
for path in source.rglob('*'):
    if path.is_file() and not path.is_symlink():
        relative = path.relative_to(source)
        # Source build directory and bundled VCS metadata are not upstream notices.
        if any(part in ('build','.git') for part in relative.parts):
            continue
        named = any(word in path.name.lower() for word in
                    ('license','licence','copying','copyright','ofl','third-party','cc0','notice','disclaimer'))
        # JUCE vendors code with complete permissive notices inside the source
        # rather than separate license files. Preserve those files verbatim too.
        payload = path.read_bytes()
        textual_notice = b'\0' not in payload and any(word in payload.lower() for word in
                                                    (b'copyright',b'permission is hereby granted',b'redistribution and use'))
        if not (named or textual_notice):
            continue
        target = destination/relative
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(path,target)
