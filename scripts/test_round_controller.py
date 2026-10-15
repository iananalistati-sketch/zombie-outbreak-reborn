#!/usr/bin/env python3
"""Execute the actual server controller in Luau with deterministic Roblox doubles.

This covers startup/control flow, not Studio physics, rendering or networking.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]


def long_string(value):
    eq=''
    while ']'+eq+']' in value:
        eq+='='
    return '['+eq+'['+value+']'+eq+']'


def run(luau):
    sources={
        'ROUND_SOURCE':'src/maps/k17/gameplay/Round.server.luau',
        'STARTUP_SOURCE':'src/maps/k17/gameplay/Startup.server.luau',
    }
    config={
        'ROUND_CONFIG':'src/maps/k17/RoundConfig.luau',
        'MAP_CONFIG':'src/maps/k17/Config.luau',
        'ROUND_RULES':'src/maps/k17/gameplay/RoundRules.luau',
        'GAMEPLAY_RULES':'src/maps/k17/gameplay/Rules.luau',
    }
    lines=[]
    for key,path in sources.items():
        source=ROOT/path
        lines.append('local '+key+'='+long_string(source.read_text()) if source.exists() else 'local '+key+'=nil')
    for key,path in config.items():
        lines.append('local '+key+'=assert(loadstring('+long_string((ROOT/path).read_text())+'))()')
    lines.append((ROOT/'tests/gameplay/round-controller.spec.luau').read_text())
    with tempfile.TemporaryDirectory(prefix='zo-round-controller-') as folder:
        harness=Path(folder)/'controller.spec.luau'
        harness.write_text('\n'.join(lines))
        subprocess.run([luau,str(harness)],cwd=ROOT,check=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau',default=shutil.which('luau'))
    args=parser.parse_args()
    parser.error('Provide --luau PATH or add luau to PATH') if not args.luau else run(args.luau)
