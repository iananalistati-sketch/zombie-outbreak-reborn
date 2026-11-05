#!/usr/bin/env python3
"""Run the real tactical movement client with API doubles, never Studio physics."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from test_combat_controller import long_string

ROOT = Path(__file__).resolve().parents[1]


def run(luau):
    folder = ROOT / 'src/maps/k17/gameplay'
    lines = [
        'local MOVEMENT_CLIENT_SOURCE=' + long_string((folder / 'Movement.client.luau').read_text()),
        'local MOVEMENT_CONFIG_SOURCE=' + long_string((folder / 'MovementConfig.luau').read_text()),
        (ROOT / 'tests/gameplay/movement_client.spec.luau').read_text(),
    ]
    with tempfile.TemporaryDirectory(prefix='zo-movement-client-') as temporary:
        path = Path(temporary) / 'movement_client.spec.luau'
        path.write_text('\n'.join(lines))
        subprocess.run([luau, str(path)], cwd=ROOT, check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau', default=shutil.which('luau'))
    args = parser.parse_args()
    if not args.luau:
        parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
