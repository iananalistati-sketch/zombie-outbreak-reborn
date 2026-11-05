#!/usr/bin/env python3
"""Execute the real movement composition module with float32 Humanoid doubles."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from test_combat_controller import long_string

ROOT = Path(__file__).resolve().parents[1]


def run(luau):
    source = (ROOT / 'src/maps/k17/gameplay/MovementState.luau').read_text()
    spec = (ROOT / 'tests/gameplay/movement_state.spec.luau').read_text()
    with tempfile.TemporaryDirectory(prefix='zo-movement-state-') as temporary:
        path = Path(temporary) / 'movement_state.spec.luau'
        path.write_text('local MOVEMENT_STATE_SOURCE=' + long_string(source) + '\n' + spec)
        subprocess.run([luau, str(path)], cwd=ROOT, check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau', default=shutil.which('luau'))
    args = parser.parse_args()
    if not args.luau:
        parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
