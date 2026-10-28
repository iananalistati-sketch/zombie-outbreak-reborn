#!/usr/bin/env python3
"""Execute Round, Combat and Startup together using shared Roblox API doubles.

This is a server integration test, not a Studio multiplayer or physics test.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

from test_combat_controller import long_string

ROOT = Path(__file__).resolve().parents[1]


def run(luau):
    sources = {
        'COMBAT_SOURCE': 'src/maps/k17/gameplay/Combat.server.luau',
        'ROUND_SOURCE': 'src/maps/k17/gameplay/Round.server.luau',
        'STARTUP_SOURCE': 'src/maps/k17/gameplay/Startup.server.luau',
        'CONFIG_SOURCE': 'src/maps/k17/gameplay/Config.luau',
        'RULES_SOURCE': 'src/maps/k17/gameplay/Rules.luau',
        'WEAPON_SOURCE': 'src/maps/k17/gameplay/WeaponState.luau',
        'LOADOUT_SOURCE': 'src/maps/k17/gameplay/LoadoutState.luau',
        'CONTAINMENT_SOURCE': 'src/maps/k17/gameplay/Containment.luau',
        'ROUND_CONFIG_SOURCE': 'src/maps/k17/RoundConfig.luau',
        'ROUND_RULES_SOURCE': 'src/maps/k17/gameplay/RoundRules.luau',
        'MAP_CONFIG_SOURCE': 'src/maps/k17/Config.luau',
        'SIMULATION_SOURCE': 'tests/gameplay/support/CombatSimulation.luau',
    }
    lines = ['local ' + key + '=' + long_string((ROOT / path).read_text())
             for key, path in sources.items()]
    lines.append((ROOT / 'tests/gameplay/survival_cycle.spec.luau').read_text())
    with tempfile.TemporaryDirectory(prefix='zo-survival-cycle-') as temporary:
        harness = Path(temporary) / 'survival_cycle.spec.luau'
        harness.write_text('\n'.join(lines))
        subprocess.run([luau, str(harness)], cwd=ROOT, check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau', default=shutil.which('luau'))
    args = parser.parse_args()
    if not args.luau:
        parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
