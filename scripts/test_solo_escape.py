"""Run real solo exercise + Round/Combat/Session together and local light lifecycle.

Uses deterministic service doubles; does not run Roblox rendering or physics.
"""
import argparse
from pathlib import Path
import subprocess
import tempfile
from test_combat_controller import long_string

ROOT=Path(__file__).resolve().parents[1]


def run(luau):
    names={'COMBAT_SOURCE':'Combat.server','ROUND_SOURCE':'Round.server','STARTUP_SOURCE':'Startup.server',
           'CONFIG_SOURCE':'Config','RULES_SOURCE':'Rules','WEAPON_SOURCE':'WeaponState','LOADOUT_SOURCE':'LoadoutState',
           'CONTAINMENT_SOURCE':'Containment','MOVEMENT_STATE_SOURCE':'MovementState','WEAPON_SKINS_SOURCE':'WeaponSkins',
           'ROUND_RULES_SOURCE':'RoundRules','ROUND_STATS_SOURCE':'RoundStats','ESCAPE_CONFIG_SOURCE':'EscapeConfig',
           'ESCAPE_STATE_SOURCE':'EscapeState','SESSION_SOURCE':'EscapeSession','HOLD_GATES_SOURCE':'HoldGates',
           'TRAINING_SOURCE':'TrainingDirector.server','TRAINING_CONFIG_SOURCE':'TrainingConfig','TRAINING_STATE_SOURCE':'TrainingState'}
    files={key:'src/maps/k17/gameplay/'+name+'.luau' for key,name in names.items()}
    files.update(ROUND_CONFIG_SOURCE='src/maps/k17/RoundConfig.luau',MAP_CONFIG_SOURCE='src/maps/k17/Config.luau',
                 SIMULATION_SOURCE='tests/gameplay/support/CombatSimulation.luau')
    prefix='\n'.join('local '+key+'='+long_string((ROOT/file).read_text()) for key,file in files.items())
    with tempfile.TemporaryDirectory(prefix='zo-solo-escape-') as folder:
        file=Path(folder)/'exercise.luau';file.write_text(prefix+'\n'+(ROOT/'tests/gameplay/solo_escape.spec.luau').read_text())
        subprocess.run([luau,str(file)],cwd=ROOT,check=True)
        light=Path(folder)/'flashlight.luau'
        light.write_text('local SOURCE='+long_string((ROOT/'src/maps/k17/gameplay/Flashlight.client.luau').read_text())+'\n'+
                         (ROOT/'tests/gameplay/flashlight.spec.luau').read_text())
        subprocess.run([luau,str(light)],cwd=ROOT,check=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--luau',required=True)
    run(parser.parse_args().luau)
