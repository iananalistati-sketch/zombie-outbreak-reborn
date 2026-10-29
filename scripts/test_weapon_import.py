#!/usr/bin/env python3
"""Verify real importer sanitation/error flow using API doubles, never Roblox networking."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
from test_combat_controller import long_string

ROOT=Path(__file__).resolve().parents[1]


def run(luau):
    source=(ROOT/'src/maps/k17/gameplay/WeaponAssetImport.luau').read_text()
    with tempfile.TemporaryDirectory(prefix='zo-weapon-import-') as temporary:
        path=Path(temporary)/'weapon_import.spec.luau'
        path.write_text('local IMPORT_SOURCE='+long_string(source)+'\n'+(ROOT/'tests/gameplay/weapon_import.spec.luau').read_text())
        subprocess.run([luau,str(path)],cwd=ROOT,check=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau',default=shutil.which('luau'))
    args=parser.parse_args()
    if not args.luau:parser.error('Provide --luau PATH or add luau to PATH')
    run(args.luau)
