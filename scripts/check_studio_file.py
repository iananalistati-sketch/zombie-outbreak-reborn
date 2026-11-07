#!/usr/bin/env python3
"""Verify the actual native K-17 place and the checksum used by the Windows opener."""
import argparse
import hashlib
import json
from pathlib import Path
from inspect_studio_binary import parse

ROOT=Path(__file__).resolve().parents[1]
BINARY=ROOT/'builds/ZombieOutbreakReborn_K17.rbxl'
MANIFEST=ROOT/'builds/K17.release.json'


def release(binary):
    classes,names,sources=parse(binary)
    required={'ZO_K17Foundry','R16_FilterRoom','R17_YardWorkshop','R18_CoolantRoom',
              'V_StockroomVent','V_FilterVent','V_YardVent','V_CoolantVent','Startup','RefugeAudit','TacticalMap','K17Refuges',
              'R48_UnderStair','R49_UnderStair','Loadout','LoadoutState','Containment','ZO_WeaponAssets',
              'EquipmentVisuals','WeaponPresentation','WeaponAimPose','PresentationConfig','WeaponPreview','WeaponAssets','WeaponAssetImport',
              'RifleAim','RifleReload','RifleAimDownSights','MuzzleFlash','Pistol'}
    required|={'Movement','MovementState','MovementConfig','MovementPose','WeaponMotion','WeaponSkins','Skins','Classic','Gold',
               'SMG','Shotgun','Bronze','White','Sand','Silver','TrainingDirector','TrainingAnimation','TrainingConfig','TrainingState','TrainingRig','TacticalSpring','TacticalRecoil','TacticalState','RefugeHeaderSign','AdministrationGuideStripe'}
    required|={'MonitorClerestoryGlass','MonitorEndCheek','ReceivingCanopyRoof','ExhaustFlue','AirBalanceHeader',
               'ControlCabinFacade','ControlInspectionWalkway'}
    required|={'EscapeSession','EscapeState','EscapeConfig','EscapeObjectives','Control1','Control2','Control3','R50_EvacuationBay','EvacuationGate'}
    required|={'HoldGates','EscapeHoldGates','GeneratorExit','MaintenanceExit','R51_GeneratorHold','EscapeRouteSigns','Spectator','SpectatorState','RouteGuide'}
    required|={'ViewRig','WeaponHandling','ImpactProfiles','RoundStats'}
    required|={'R52_RingWorkshop','R53_ValveRoom','EvacuationStatus','WorkshopBlastReturn','ValveRoomBlastReturn'}
    required|={'TrainingSpawn','Flashlight'}
    required|={'ShotPrediction'}
    assert required<=set(names),'K-17 map/features missing: '+str(required-set(names))
    assert names.count('ZO_K17Foundry')==1,'Expected exactly one K-17 map'
    assert names.count('Hull')==187,'Expected current Survival and Escape defense barricades'
    assert not {'ZO_SantaAurora','ZO_HarborCollision','HarborLocks_Survival_Visual'}&set(names),'Legacy scene in K-17 build'
    assert not {'ZO_StudioSurvivalScenario','ZO_StudioSurvivalDriver'}&set(names),'Automated Studio drivers in playable release'
    assert not {'ZO_ReusedWeaponKit','ReusedRiflePresentation','RifleCasing','Bullet'}&set(names),'Unused former weapon templates in release'
    assert 'WeaponsSystem' not in names,'An upstream combat system was bundled with the pistol'
    assert len(names)==sum(count for _,count in classes.values()),'Incomplete native Name properties'
    for path in ('src/maps/k17/GameConfig.luau','src/maps/k17/gameplay/Round.server.luau','src/maps/k17/gameplay/HUD.client.luau','src/maps/k17/gameplay/Startup.server.luau','src/maps/k17/gameplay/TacticalMap.client.luau',
                 'src/maps/k17/barricades/Server.server.luau','src/maps/k17/barricades/Config.luau','src/maps/k17/barricades/Physics.luau',
                 'src/maps/k17/gameplay/Combat.server.luau','src/maps/k17/gameplay/Config.luau','src/maps/k17/gameplay/LoadoutState.luau',
                 'src/maps/k17/gameplay/Containment.luau','src/maps/k17/gameplay/WeaponAimPose.luau','src/maps/k17/gameplay/Loadout.client.luau','src/maps/k17/gameplay/Weapons.client.luau',
                 'src/maps/k17/gameplay/MovementState.luau','src/maps/k17/gameplay/MovementConfig.luau','src/maps/k17/gameplay/MovementPose.luau',
                 'src/maps/k17/gameplay/Movement.server.luau','src/maps/k17/gameplay/Movement.client.luau',
                 'src/maps/k17/gameplay/WeaponMotion.luau','src/maps/k17/gameplay/ShotPrediction.luau',
                 'src/maps/k17/gameplay/TacticalSpring.luau','src/maps/k17/gameplay/TacticalRecoil.luau',
                 'src/maps/k17/gameplay/TacticalState.luau',
                 'src/maps/k17/gameplay/EscapeConfig.luau','src/maps/k17/gameplay/EscapeState.luau','src/maps/k17/gameplay/EscapeSession.luau',
                 'src/maps/k17/gameplay/HoldGates.luau','src/maps/k17/gameplay/RouteGuide.luau','src/maps/k17/gameplay/SpectatorState.luau','src/maps/k17/gameplay/Spectator.client.luau',
                 'src/maps/k17/gameplay/ViewRig.luau','src/maps/k17/gameplay/WeaponHandling.luau','src/maps/k17/gameplay/ImpactProfiles.luau','src/maps/k17/gameplay/RoundStats.luau',
                 'src/maps/k17/gameplay/TrainingDirector.server.luau','src/maps/k17/gameplay/TrainingAnimation.client.luau','src/maps/k17/gameplay/Flashlight.client.luau',
                 'src/maps/k17/gameplay/TrainingConfig.luau','src/maps/k17/gameplay/TrainingState.luau','src/maps/k17/gameplay/TrainingRig.luau',
                 'src/maps/k17/gameplay/WeaponSkins.luau',
                 'src/maps/k17/gameplay/EquipmentVisuals.server.luau','src/maps/k17/gameplay/WeaponPresentation.luau',
                 'src/maps/k17/gameplay/PresentationConfig.luau','src/maps/k17/gameplay/WeaponPreview.luau',
                 'src/maps/k17/gameplay/WeaponAssets.server.luau','src/maps/k17/gameplay/WeaponAssetImport.luau',
                 'tests/k17/K17Audit.luau'):
        assert sources.count((ROOT/path).read_text(encoding='utf-8'))==1,'Outdated/missing native source: '+path
    data=binary.read_bytes()
    assert sum(count for name,count in classes.values() if name=='Tool')==10,'Expected four firearms and six reviewed cosmetic Tools'
    assert sum(count for name,count in classes.values() if name=='MeshPart')==24,'Bundled weapon/skin meshes missing'
    assert sum(count for name,count in classes.values() if name=='WedgePart')>=8,'Inclined monitor end cheeks missing'
    return {'file':BINARY.name,'map':'ZO_K17Foundry','sha256':hashlib.sha256(data).hexdigest(),
            'bytes':len(data),'instances':len(names),'barricades':names.count('Hull'),'ducts':4}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary',type=Path,default=BINARY)
    parser.add_argument('--manifest',type=Path,default=MANIFEST)
    parser.add_argument('--write',action='store_true',help='Write the checksum only after inspecting native contents')
    args=parser.parse_args()
    expected=release(args.binary)
    if args.write:args.manifest.write_text(json.dumps(expected,indent=2)+'\n',encoding='utf-8')
    else:assert json.loads(args.manifest.read_text(encoding='utf-8'))==expected,'Native place/manifest differ; rebuild and run --write'
    print(f'PASS native K-17: {expected["instances"]} instances, {expected["barricades"]} props, four ducts, current controllers, no Santa Aurora; SHA-256 verified')


if __name__=='__main__':main()
