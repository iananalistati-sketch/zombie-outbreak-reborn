"""Exercise the actual spectator controller with API doubles, not engine rendering."""
import argparse
from pathlib import Path
import subprocess
import tempfile
from test_combat_controller import long_string
ROOT=Path(__file__).resolve().parents[1]
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--luau',required=True);a=p.parse_args()
    subprocess.run([a.luau,'tests/gameplay/defense_policies.spec.luau'],cwd=ROOT,check=True)
    sources={'CLIENT_SOURCE':'Spectator.client.luau','POLICY_SOURCE':'SpectatorState.luau'}
    prefix='\n'.join('local '+key+'='+long_string((ROOT/'src/maps/k17/gameplay'/file).read_text()) for key,file in sources.items())
    with tempfile.TemporaryDirectory(prefix='zo-defense-') as temp:
        path=Path(temp)/'spectator.luau';path.write_text(prefix+'\n'+(ROOT/'tests/gameplay/spectator_client.spec.luau').read_text())
        subprocess.run([a.luau,str(path)],cwd=ROOT,check=True)
