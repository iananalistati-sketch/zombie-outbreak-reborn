#!/usr/bin/env python3
"""Run the stand-alone Studio capture command with API doubles, not Roblox."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from test_combat_controller import long_string

ROOT = Path(__file__).resolve().parents[1]


def run(luau):
    source = (ROOT / 'tools/studio/CaptureOfficialWeapons.luau').read_text()
    spec = (ROOT / 'tests/gameplay/weapon_capture.spec.luau').read_text()
    with tempfile.TemporaryDirectory(prefix='zo-weapon-capture-') as temporary:
        path = Path(temporary) / 'weapon_capture.spec.luau'
        path.write_text('local CAPTURE_SOURCE=' + long_string(source) + '\n' + spec)
        subprocess.run([luau, str(path)], cwd=ROOT, check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau', default=shutil.which('luau'))
    args = parser.parse_args()
    if not args.luau:
        parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
