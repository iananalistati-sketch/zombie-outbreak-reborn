#!/usr/bin/env python3
"""Run the actual Source movement kernel and client with Roblox API doubles.

These checks do not execute Roblox physics, networking, or PlayerModule itself.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

from test_combat_controller import long_string

ROOT = Path(__file__).resolve().parents[1]


def run(luau):
    folder = ROOT / "src/maps/k17/gameplay"
    sources = {
        "SOURCE_MOVEMENT_SOURCE": "SourceMovement.luau",
        "SOURCE_MOTOR_SOURCE": "SourceMotor.client.luau",
    }
    declarations = [
        "local " + name + "=" + long_string((folder / source).read_text())
        for name, source in sources.items()
    ]
    with tempfile.TemporaryDirectory(prefix="zo-source-movement-") as temporary:
        for name in ("source_movement", "source_motor"):
            harness = Path(temporary) / (name + ".spec.luau")
            spec = ROOT / "tests/gameplay" / (name + ".spec.luau")
            harness.write_text("\n".join([*declarations, spec.read_text()]))
            subprocess.run([luau, str(harness)], cwd=ROOT, check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", default=shutil.which("luau"))
    args = parser.parse_args()
    if not args.luau:
        parser.error("Provide --luau PATH or add luau to PATH")
    run(args.luau)
