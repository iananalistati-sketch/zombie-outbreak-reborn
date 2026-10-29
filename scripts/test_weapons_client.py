#!/usr/bin/env python3
"""Execute the real Weapons LocalScript with API doubles and a presentation spy.

This tests input/protocol/cancellation, not rendering, animations or audio output.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from test_combat_controller import long_string
ROOT=Path(__file__).resolve().parents[1]

def run(luau):
    folder=ROOT/'src/maps/k17/gameplay'
    sources={'CONFIG_SOURCE':'Config.luau','RULES_SOURCE':'Rules.luau','WEAPONS_CLIENT_SOURCE':'Weapons.client.luau'}
    lines=['local '+name+'='+long_string((folder/file).read_text()) for name,file in sources.items()]
    lines.append((ROOT/'tests/gameplay/weapons_client.spec.luau').read_text())
    with tempfile.TemporaryDirectory(prefix='zo-weapons-client-') as temporary:
        path=Path(temporary)/'weapons_client.spec.luau';path.write_text('\n'.join(lines))
        subprocess.run([luau,str(path)],cwd=ROOT,check=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau',default=shutil.which('luau'))
    args=parser.parse_args()
    if not args.luau:parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
