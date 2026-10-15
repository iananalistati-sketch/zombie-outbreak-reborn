#!/usr/bin/env python3
"""Execute actual barricade startup/reset code with deterministic Roblox API doubles.

This tests control flow and failure handling, not engine simulation or networking.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def quote(source):
    equals = ''
    while ']' + equals + ']' in source:
        equals += '='
    return '[' + equals + '[' + source + ']' + equals + ']'


def run(luau):
    lines = []
    for name, path in {
        'SERVER_SOURCE': 'src/maps/k17/barricades/Server.server.luau',
        'CONFIG_SOURCE': 'src/maps/k17/barricades/Config.luau',
        'RULES_SOURCE': 'src/maps/k17/barricades/Rules.luau',
        'PHYSICS_SOURCE': 'src/maps/k17/barricades/Physics.luau',
    }.items():
        lines.append('local ' + name + '=' + quote((ROOT / path).read_text()))
    lines.append((ROOT / 'tests/barricades/runtime.spec.luau').read_text())
    with tempfile.TemporaryDirectory(prefix='zo-barricades-runtime-') as folder:
        harness = Path(folder) / 'runtime.spec.luau'
        harness.write_text('\n'.join(lines))
        subprocess.run([luau, str(harness)], cwd=ROOT, check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau', default=shutil.which('luau'))
    args = parser.parse_args()
    if not args.luau:
        parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
