"""Inspect tar metadata only; reject anything outside the runtime/header allowlist."""

import sys
import tarfile
from pathlib import PurePosixPath

metadata = {"LICENSE", "ThirdPartyNotices.txt", "VERSION_NUMBER", "GIT_COMMIT_ID", "README.md", "Privacy.md"}
libraries = {"libonnxruntime.so", "libonnxruntime.so.1", "libonnxruntime.so.1.24.4",
             "libonnxruntime_providers_shared.so", "libonnxruntime_providers_cuda.so",
             "libonnxruntime_providers_tensorrt.so"}
with tarfile.open(sys.argv[1], "r:gz") as archive:
    members = archive.getmembers()
    roots = {PurePosixPath(member.name).parts[0] for member in members}
    assert len(roots) == 1, roots
    for member in members:
        path = PurePosixPath(member.name)
        assert not path.is_absolute() and ".." not in path.parts, member.name
        relative = PurePosixPath(*path.parts[1:])
        if member.issym():
            assert relative.parent == PurePosixPath("lib"), member.name
            assert member.linkname in libraries, member.linkname
        else:
            assert member.isdir() or member.isfile(), member.name
        allowed = (member.isdir() or str(relative) in metadata
                   or (relative.parts[0] == "include" and relative.suffix == ".h")
                   or (relative.parent == PurePosixPath("lib") and relative.name in libraries)
                   or (str(relative).startswith("lib/cmake/onnxruntime/") and relative.suffix == ".cmake")
                   or str(relative) == "lib/pkgconfig/libonnxruntime.pc")
        assert allowed, f"unexpected payload (not an audited model-free runtime member): {member.name}"
        print(member.name)
