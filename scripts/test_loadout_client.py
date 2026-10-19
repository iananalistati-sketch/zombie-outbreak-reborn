#!/usr/bin/env python3
"""Execute the real loadout LocalScript against deterministic Roblox UI doubles.

This checks event wiring, server-result protocol and asynchronous request state.
It does not render UI or run Roblox input, networking or character simulation.
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
    folder = ROOT / "src/maps/k17/gameplay"
    sources = {
        "LOADOUT_CLIENT_SOURCE": "Loadout.client.luau",
        "CONFIG_SOURCE": "Config.luau",
        "RULES_SOURCE": "Rules.luau",
    }
    lines = [
        "local " + name + "=" + long_string((folder / source).read_text())
        for name, source in sources.items()
    ]
    lines.append((ROOT / "tests/gameplay/loadout_client.spec.luau").read_text())
    with tempfile.TemporaryDirectory(prefix="zo-loadout-client-") as temporary:
        harness = Path(temporary) / "loadout_client.spec.luau"
        harness.write_text("\n".join(lines))
        subprocess.run([luau, str(harness)], cwd=ROOT, check=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", default=shutil.which("luau"))
    args = parser.parse_args()
    if not args.luau:
        parser.error("Provide --luau PATH or add luau to PATH")
    run(args.luau)
