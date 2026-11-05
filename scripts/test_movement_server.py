#!/usr/bin/env python3
"""Run actual movement controller, pose and speed-state with Roblox API doubles.

This does not run Roblox motor replication, contacts, networking or rendering.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from test_combat_controller import long_string

ROOT = Path(__file__).resolve().parents[1]


def run(luau):
    folder = ROOT / 'src/maps/k17/gameplay'
    names = {'CONFIG_SOURCE': 'MovementConfig.luau', 'STATE_SOURCE': 'MovementState.luau',
             'POSE_SOURCE': 'MovementPose.luau', 'MOVEMENT_SOURCE': 'Movement.server.luau'}
    source = ['local ' + name + '=' + long_string((folder / filename).read_text())
              for name, filename in names.items()]
    source.append((ROOT / 'tests/gameplay/movement_server.spec.luau').read_text())
    with tempfile.TemporaryDirectory(prefix='zo-movement-server-') as temporary:
        path = Path(temporary) / 'movement_server.spec.luau'
        path.write_text('\n'.join(source))
        subprocess.run([luau, str(path)], cwd=ROOT, check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau', default=shutil.which('luau'))
    args = parser.parse_args()
    if not args.luau:
        parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
