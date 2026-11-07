"""Run actual Round + Combat + Startup + EscapeSession with shared API doubles."""
import argparse
from pathlib import Path
import subprocess
import tempfile
from test_combat_controller import long_string
ROOT=Path(__file__).resolve().parents[1]
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--luau',required=True);a=p.parse_args()
    subprocess.run([a.luau,'tests/gameplay/escape_state.spec.luau'],cwd=ROOT,check=True)
    files={'COMBAT_SOURCE':'Combat.server','ROUND_SOURCE':'Round.server','STARTUP_SOURCE':'Startup.server',
        'CONFIG_SOURCE':'Config','RULES_SOURCE':'Rules','WEAPON_SOURCE':'WeaponState','LOADOUT_SOURCE':'LoadoutState',
        'CONTAINMENT_SOURCE':'Containment','MOVEMENT_STATE_SOURCE':'MovementState','WEAPON_SKINS_SOURCE':'WeaponSkins',
        'ROUND_RULES_SOURCE':'RoundRules','ESCAPE_CONFIG_SOURCE':'EscapeConfig','ESCAPE_STATE_SOURCE':'EscapeState','SESSION_SOURCE':'EscapeSession','HOLD_GATES_SOURCE':'HoldGates','ROUND_STATS_SOURCE':'RoundStats'}
    sources={key:'src/maps/k17/gameplay/'+name+'.luau' for key,name in files.items()}
    sources.update(ROUND_CONFIG_SOURCE='src/maps/k17/RoundConfig.luau',MAP_CONFIG_SOURCE='src/maps/k17/Config.luau',
        SIMULATION_SOURCE='tests/gameplay/support/CombatSimulation.luau')
    prefix='\n'.join('local '+key+'='+long_string((ROOT/file).read_text()) for key,file in sources.items())
    with tempfile.TemporaryDirectory(prefix='zo-escape-') as temp:
        path=Path(temp)/'escape.luau';path.write_text(prefix+'\n'+(ROOT/'tests/gameplay/escape_cycle.spec.luau').read_text())
        subprocess.run([a.luau,str(path)],cwd=ROOT,check=True)
