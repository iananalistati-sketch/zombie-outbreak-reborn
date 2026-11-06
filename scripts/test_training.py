"""Execute actual training state/director with deterministic API doubles."""
import argparse
from pathlib import Path
import subprocess
import tempfile
from test_combat_controller import long_string
ROOT=Path(__file__).resolve().parents[1]
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--luau',required=True);a=p.parse_args()
    subprocess.run([a.luau,'tests/gameplay/training_state.spec.luau'],cwd=ROOT,check=True)
    sources={'CONFIG_SOURCE':'TrainingConfig.luau','STATE_SOURCE':'TrainingState.luau',
             'DIRECTOR_SOURCE':'TrainingDirector.server.luau','MOVEMENT_SOURCE':'MovementState.luau','RIG_SOURCE':'TrainingRig.luau'}
    prefix='\n'.join('local '+key+'='+long_string((ROOT/'src/maps/k17/gameplay'/file).read_text()) for key,file in sources.items())
    with tempfile.TemporaryDirectory(prefix='zo-training-') as temp:
        path=Path(temp)/'director.luau';path.write_text(prefix+'\n'+(ROOT/'tests/gameplay/training_director.spec.luau').read_text())
        subprocess.run([a.luau,str(path)],cwd=ROOT,check=True)
