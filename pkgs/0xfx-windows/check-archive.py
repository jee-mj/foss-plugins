"""Operator-side data/evaluation test: no payload execution or Nix builds.

Usage: python3 check-archive.py /path/to/0xfx-source.zip
Uses an isolated temporary Git checkout; requires the locked Nix input cached.
"""
import hashlib
import json
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

archive = Path(sys.argv[1]).resolve()
with tempfile.TemporaryDirectory(prefix='0xfx-archive-') as tmp:
    root = Path(tmp)
    with zipfile.ZipFile(archive) as z:
        for name in ['packaging/flake.nix', 'packaging/flake.lock',
                     'packaging/tests/0xfx-windows.nix',
                     'packaging/pkgs/0xfx-windows/default.nix']:
            assert name in z.namelist(), 'missing standalone archive entry: ' + name
        assert not any(n.endswith('/verification.json') for n in z.namelist())
        for name in z.namelist():
            parts = PurePosixPath(name).parts
            if parts and parts[0] == 'packaging':
                assert not PurePosixPath(name).is_absolute() and '..' not in parts, name
                assert z.getinfo(name).external_attr >> 16 == 0o100644, name
                destination = root.joinpath(*parts)
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(z.read(name))
    checkout = root / 'packaging'
    lock_before = (checkout / 'flake.lock').read_bytes()
    subprocess.run(['git', 'init', '-q', str(checkout)], check=True)
    subprocess.run(['git', '-C', str(checkout), 'add', '.'], check=True)
    uri = 'git+file://' + str(checkout)
    subprocess.run(['nix', 'flake', 'check', '--no-build', '--offline',
                    '--no-write-lock-file', '--cores', '4', '--max-jobs', '1', uri],
                   cwd=checkout, check=True)
    checks = json.loads(subprocess.check_output(
        ['nix', 'eval', '--offline', '--no-write-lock-file', '--json',
         uri + '#checks.x86_64-linux', '--apply', 'builtins.attrNames'], cwd=checkout))
    assert checks == ['archiveLayout', 'artifacts', 'installerRepack', 'recompile', 'repack'], checks
    assert (checkout / 'flake.lock').read_bytes() == lock_before
    print(json.dumps({'status': 'passed', 'mode': 'offline flake check --no-build',
                      'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
                      'lock_sha256': hashlib.sha256(lock_before).hexdigest(),
                      'checks': checks, 'lock_unchanged': True,
                      'source': 'fresh Git checkout containing only archived packaging files',
                      'payload_execution': 'not-run'}, indent=2))
