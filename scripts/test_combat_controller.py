#!/usr/bin/env python3
"""Run the real Combat Script against deterministic Roblox API doubles.

This checks authority, inventory, hit processing, timers and economy. It does not
run Roblox networking, character contacts, raycast geometry or the physics solver.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def long_string(value):
    equals = ""
    while "]" + equals + "]" in value:
        equals += "="
    return "[" + equals + "[" + value + "]" + equals + "]"


def run(luau):
    sources = {
        "COMBAT_SOURCE": "Combat.server.luau",
        "CONFIG_SOURCE": "Config.luau",
        "RULES_SOURCE": "Rules.luau",
        "WEAPON_SOURCE": "WeaponState.luau",
        "LOADOUT_SOURCE": "LoadoutState.luau",
        "CONTAINMENT_SOURCE": "Containment.luau",
    }
    folder = ROOT / "src/maps/k17/gameplay"
    lines = [
        "local " + name + "=" + long_string((folder / source).read_text())
        for name, source in sources.items()
    ]
    lines.append((ROOT / "tests/gameplay/combat_runtime.spec.luau").read_text())
    with tempfile.TemporaryDirectory(prefix="zo-combat-controller-") as temporary:
        harness = Path(temporary) / "combat_runtime.spec.luau"
        harness.write_text("\n".join(lines))
        subprocess.run([luau, str(harness)], cwd=ROOT, check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", default=shutil.which("luau"))
    args = parser.parse_args()
    if not args.luau:
        parser.error("Provide --luau PATH or add luau to PATH")
    run(args.luau)
