"""Run the actual tactical HUD with API doubles, plus pure presentation policies.

Checks state transitions/cleanup, not visual layout or real engine rendering.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile
from test_combat_controller import long_string
ROOT=Path(__file__).resolve().parents[1]
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--luau',required=True);args=parser.parse_args()
    subprocess.run([args.luau,'tests/gameplay/tactical_state.spec.luau'],cwd=ROOT,check=True)
    sources={'HUD_SOURCE':'HUD.client.luau','STATE_SOURCE':'TacticalState.luau','CONFIG_SOURCE':'Config.luau'}
    prefix='\n'.join('local '+key+'='+long_string((ROOT/'src/maps/k17/gameplay'/file).read_text()) for key,file in sources.items())
    with tempfile.TemporaryDirectory(prefix='zo-tactical-hud-') as temp:
        path=Path(temp)/'hud.luau';path.write_text(prefix+'\n'+(ROOT/'tests/gameplay/tactical_hud.spec.luau').read_text())
        subprocess.run([args.luau,str(path)],cwd=ROOT,check=True)
