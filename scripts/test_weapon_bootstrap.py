#!/usr/bin/env python3
"""Run the real bundled-weapon bootstrap with API doubles, never Roblox."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from test_combat_controller import long_string

ROOT = Path(__file__).resolve().parents[1]


def run(luau):
    folder = ROOT / 'src/maps/k17/gameplay'
    source = (folder / 'WeaponAssets.server.luau').read_text()
    config = (folder / 'Config.luau').read_text()
    spec = (ROOT / 'tests/gameplay/weapon_bootstrap.spec.luau').read_text()
    with tempfile.TemporaryDirectory(prefix='zo-weapon-bootstrap-') as temporary:
        path = Path(temporary) / 'weapon_bootstrap.spec.luau'
        path.write_text('local BOOTSTRAP_SOURCE=' + long_string(source)
                        + '\nlocal CONFIG_SOURCE=' + long_string(config) + '\n' + spec)
        subprocess.run([luau, str(path)], cwd=ROOT, check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau', default=shutil.which('luau'))
    args = parser.parse_args()
    if not args.luau:
        parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
