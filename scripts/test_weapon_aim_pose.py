#!/usr/bin/env python3
"""Check the real kit aim-pose adapter with a deterministic animation-track double.

Advances the track timeline and models delayed animation Length. This does not
load Roblox animations, render poses or approve animation permissions in Studio.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

from test_combat_controller import long_string

ROOT = Path(__file__).resolve().parents[1]


def run(luau):
    source = (ROOT / "src/maps/k17/gameplay/WeaponAimPose.luau").read_text()
    spec = (ROOT / "tests/gameplay/weapon_aim_pose.spec.luau").read_text()
    with tempfile.TemporaryDirectory(prefix="zo-weapon-aim-pose-") as temporary:
        path = Path(temporary) / "weapon_aim_pose.spec.luau"
        path.write_text("local AIM_POSE_SOURCE=" + long_string(source) + "\n" + spec)
        subprocess.run([luau, str(path)], cwd=ROOT, check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", default=shutil.which("luau"))
    args = parser.parse_args()
    if not args.luau:
        parser.error("Provide --luau PATH or add luau to PATH")
    run(args.luau)
