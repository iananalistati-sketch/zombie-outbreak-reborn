#!/usr/bin/env python3
"""Run the real world-equipment controller and aim-pose adapter with API doubles.

Exercises animation timeline use/lifecycle, not Roblox rendering or networking.
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
    sources = {
        'CONFIG_SOURCE': 'Config.luau',
        'PRESENTATION_CONFIG_SOURCE': 'PresentationConfig.luau',
        'AIM_POSE_SOURCE': 'WeaponAimPose.luau',
        'EQUIPMENT_SOURCE': 'EquipmentVisuals.server.luau',
    }
    lines = ['local ' + name + '=' + long_string((folder / file).read_text())
             for name, file in sources.items()]
    lines.append((ROOT / 'tests/gameplay/equipment_visuals.spec.luau').read_text())
    with tempfile.TemporaryDirectory(prefix='zo-equipment-visuals-') as temporary:
        path = Path(temporary) / 'equipment_visuals.spec.luau'
        path.write_text('\n'.join(lines))
        subprocess.run([luau, str(path)], cwd=ROOT, check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau', default=shutil.which('luau'))
    args = parser.parse_args()
    if not args.luau:
        parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
