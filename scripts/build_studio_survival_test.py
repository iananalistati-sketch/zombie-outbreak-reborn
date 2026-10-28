#!/usr/bin/env python3
"""Build an isolated Studio validation place using the production K-17 sources.

Run the result with exactly two clients in Studio. Building is not an engine test.
The playable default.project.json never receives the test drivers or short rounds.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from inspect_studio_binary import parse

ROOT = Path(__file__).resolve().parents[1]


def build(rojo, output):
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    project["name"] += " — STUDIO VALIDATION ONLY"
    tree = project["tree"]
    shared = tree["ReplicatedStorage"]["Shared"]
    shared["ProductionRoundConfig"] = shared["RoundConfig"]
    shared["RoundConfig"] = {"$path": "tests/studio/RoundConfig.luau"}
    tree["ServerScriptService"]["ZO_StudioSurvivalScenario"] = {
        "$path": "tests/studio/SurvivalScenario.server.luau"
    }
    tree["StarterPlayer"]["StarterPlayerScripts"]["ZO_StudioSurvivalDriver"] = {
        "$path": "tests/studio/SurvivalDriver.client.luau"
    }

    def absolute_paths(node):
        if not isinstance(node, dict):
            return
        for key, value in node.items():
            if key == "$path":
                node[key] = str(ROOT / value)
            else:
                absolute_paths(value)

    absolute_paths(tree)
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="zo-studio-survival-") as temporary:
        profile = Path(temporary) / "survival-test.project.json"
        profile.write_text(json.dumps(project, indent=2) + "\n", encoding="utf-8")
        subprocess.run([rojo, "build", str(profile), "--output", str(output)], cwd=ROOT, check=True)
    if output.suffix == ".rbxl":
        _, names, sources = parse(output)
        assert {"ZO_StudioSurvivalScenario", "ZO_StudioSurvivalDriver"} <= set(names)
        for relative in (
            "src/maps/k17/gameplay/Round.server.luau",
            "src/maps/k17/gameplay/Combat.server.luau",
            "src/maps/k17/gameplay/Startup.server.luau",
            "tests/studio/SurvivalScenario.server.luau",
            "tests/studio/SurvivalDriver.client.luau",
            "tests/studio/RoundConfig.luau",
        ):
            assert sources.count((ROOT / relative).read_text(encoding="utf-8")) == 1, relative
        print("PASS test native contents: current production controllers and isolated test drivers")
    print("Built TEST-ONLY place:", output)
    print("UNRUN in Roblox engine. Open in Studio > Server & Clients > 2 clients > Start.")
    print("Expect [SURVIVAL STUDIO] COMPLETE in server Output; FAIL reports the exact stage.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rojo", default=shutil.which("rojo"))
    parser.add_argument("--output", type=Path, default=ROOT / "builds/ZombieOutbreakReborn_SurvivalTest.rbxl")
    args = parser.parse_args()
    if not args.rojo:
        parser.error("Provide --rojo PATH or add rojo to PATH")
    build(args.rojo, args.output)
