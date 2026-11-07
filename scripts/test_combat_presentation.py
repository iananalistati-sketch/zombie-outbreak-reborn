"""Run actual view-rig and presentation code with transform/Instance doubles.

Verifies cloning, R6 grip, reload cancellation and bounded material FX; not rendering.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile
from test_combat_controller import long_string
ROOT=Path(__file__).resolve().parents[1]
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--luau',required=True);a=p.parse_args()
    subprocess.run([a.luau,'tests/gameplay/combat_presentation_policies.spec.luau'],cwd=ROOT,check=True)
    files={'RIG_SOURCE':'ViewRig.luau','PRESENTER_SOURCE':'WeaponPresentation.luau','HANDLING_SOURCE':'WeaponHandling.luau','IMPACTS_SOURCE':'ImpactProfiles.luau'}
    prefix='\n'.join('local '+key+'='+long_string((ROOT/'src/maps/k17/gameplay'/file).read_text()) for key,file in files.items())
    with tempfile.TemporaryDirectory(prefix='zo-presentation-') as temp:
        path=Path(temp)/'presentation.luau';path.write_text(prefix+'\n'+(ROOT/'tests/gameplay/combat_presentation_runtime.spec.luau').read_text())
        subprocess.run([a.luau,str(path)],cwd=ROOT,check=True)
