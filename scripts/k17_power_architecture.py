"""Original rooftop exhaust plant for K-17's electrical conversion building.

Two enclosed air-handling trains collect warm air through exterior risers and
discharge above the roof. Geometry uses the existing native Part/cylinder API;
there are no imported assets, runtime generators or cosmetic smoke emitters.
"""


def build_power_architecture(m):
    """Give the power station a process-plant silhouette, keeping its roof routes.

    The occupied roof stays at Y=29. Equipment stands north of the stair landing
    spine at Z=-181; overhead ducts have seven studs of clearance below them.
    """
    g = 'B_PowerStation_ProcessSystems'
    if g in m.models:
        return
    before = m.parts

    def box(name, rect, lo, hi, color='steel', physical=False):
        return m.box(g, name, rect, lo, hi, color, 'Metal', physical=physical)

    def pipe(name, a, b, diameter, color='steel', physical=False):
        item = m.pipe(g, a, b, diameter, color=color)
        # Map.pipe returns the authored native cylinder; retain its exact axis.
        properties = item.find('Properties')
        properties.find('string[@name="Name"]').text = name
        properties.find('bool[@name="CanCollide"]').text = str(physical).lower()
        properties.find('bool[@name="CanQuery"]').text = str(physical).lower()
        return item

    for index, x in enumerate((96, 192), 1):
        z = -225
        # Service housings have full collision. The visible panels and vents
        # refine an actual equipment enclosure rather than obstructing a route.
        m.box(g, 'ExhaustPlantPlinth', (x-12, x+12, z-11, z+11),
              29, 29.6, 'concrete', 'Concrete')
        box('AirHandlerHousing', (x-9, x+9, z-8, z+8), 29.6, 36.8,
            'olive', physical=True)
        box('MaintenanceDoor', (x-7, x+7, z+8, z+8.12), 30.4, 35.9, 'dark')
        for dx in (-3.5, 3.5):
            box('DoorPull', (x+dx-.09, x+dx+.09, z+8.12, z+8.4), 32.1, 33.8)
        box('LocalDisconnect', (x+6.4, x+8.4, z+8.12, z+8.7), 32.1, 35, 'yellow')
        for y in (31.4, 33, 34.6):
            box('HousingVentLouvre', (x-8, x+8, z-8.15, z-8), y, y+.14, 'dark')

        # Round flues, bolted collars and rain hoods break the flat office-like
        # roof outline. The main flue is solid; tiny fastening parts are query-free.
        pipe('FlueBaseCollar', (x, 36.5, z), (x, 37.4, z), 13)
        pipe('ExhaustFlue', (x, 37.3, z), (x, 64, z), 9.5,
             'rust', physical=True)
        for y in (46.8, 60.8):
            pipe('FlueExpansionBand', (x, y, z), (x, y+.35, z), 10.3)
        for dx in (-3.2, 3.2):
            m.line(g, 'RainHoodStandoff', (x+dx, 63.5, z),
                   (x+dx, 65.7, z), .16, 'steel')
        pipe('FlueRainHood', (x, 65.7, z), (x, 66.25, z), 14)

        # The riser is outside the front wall. It turns over the occupied roof,
        # never through a stairwell, doorway or the marked defensive positions.
        pipe('RoofExtractionDuct', (x, 38.5, z), (x, 38.5, -121), 5)
        for zz in (-203, -168, -145):
            pipe('DuctJointFlange', (x, 38.5, zz-.15),
                 (x, 38.5, zz+.15), 6)
        pipe('ExteriorWarmAirRiser', (x, 6, -121), (x, 38.5, -121), 3.5)
        pipe('WallIntakeConnection', (x, 6, -125), (x, 6, -121), 3.5)
        for y in (17, 28):
            box('RiserWallBracket', (x-2.2, x+2.2, -124.2, -120),
                y, y+.22)
        for zz in (-206, -154):
            box('DuctSupportPedestal', (x-.6, x+.6, zz-2.6, zz+2.6),
                29, 36.1, physical=True)
        m.sign(g, x, 34.1, z+8.3, f'EXAUSTÃO  /  E-{index:02}',
               width=14, face=2)

    # A shared balance header makes the paired plant read as one designed
    # system. Its supporting feet stay in the unused northern roof strip.
    pipe('AirBalanceHeader', (96, 38.5, -239), (192, 38.5, -239), 3)
    for x in (96, 192):
        pipe('BalanceHeaderBranch', (x, 38.5, -239), (x, 38.5, -225), 3)
        box('HeaderSupportFoot', (x-.6, x+.6, -241, -237),
            29, 37, physical=True)

    if not hasattr(m, 'architecture'):
        m.architecture = []
    m.architecture.append({
        'id': 'power_exhaust_plant',
        'name': 'Power station exhaust plant',
        'model': g,
        'features': ['two cylindrical exhaust flues', 'service housings',
                     'exterior intake risers', 'overhead extraction ducts',
                     'shared balance header'],
        'bounds': [84, 204, -243, -118],
        'floor': 29,
        'top': 66.25,
        'parts': m.parts-before,
        'view': [144, 32, -150],
        'look': [144, 47, -225],
        'engine_validation': 'pending',
    })
