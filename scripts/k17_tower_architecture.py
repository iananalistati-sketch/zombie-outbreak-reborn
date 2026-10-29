"""Panoramic upper control cabin and supported inspection balcony for K-17.

Only the existing tower's top-floor exterior facade is replaced. Its occupied
floors, internal rooms, two stair cores, defensive positions and roof remain.
The new outer walkway uses those existing stairs through one real front portal.
"""
from __future__ import annotations

import math


GROUP = 'T_ControlTower'
FLOOR = 43
INNER = (172, 248, -36, 76)
OUTER = (166, 254, -42, 82)
DOOR = (204, 216)


def build_tower_architecture(m):
    group = m.group(GROUP)
    names = {f'{wall}{suffix}' for wall in ('Frontage', 'SideFacade')
             for suffix in ('', '_Glass', '_Frame', '_WindowHeader')}
    removed = []
    for item in list(group):
        if item.tag != 'Item':
            continue
        properties = item.find('Properties')
        name = properties.findtext('string[@name="Name"]')
        if name not in names:
            continue
        frame = properties.find('CoordinateFrame[@name="CFrame"]')
        size = properties.find('Vector3[@name="size"]')
        bottom = float(frame.findtext('Y'))-float(size.findtext('Y'))/2
        if bottom >= FLOOR-1e-6:
            removed.append(item)
    assert removed, 'Expected the original fourth-floor tower facade'
    before = m.parts
    for item in removed:
        group.remove(item)
    m.parts -= len(removed)
    m.openings[:] = [opening for opening in m.openings
                     if not (opening['model'] == GROUP
                             and opening['name'] in ('Frontage', 'SideFacade')
                             and opening['bottom'] >= FLOOR)]

    # The broad band of glazing is part of the wall construction, not a decal
    # covering an opaque wall. Spandrels and headers carry its vertical mullions.
    for axis, fixed, start, end, front in (
        ('X', -36, 172, 248, False), ('X', 76, 172, 248, True),
        ('Z', 172, -36, 76, False), ('Z', 248, -36, 76, False),
    ):
        spans = [(start+1, end-1)]
        if front:
            spans = [(start+1, DOOR[0]), (DOOR[1], end-1)]
        holes = [(a, b, 47, 54, 'window') for a, b in spans]
        if front:
            holes.append((*DOOR, FLOOR, 54, 'door'))
        m.wall(GROUP, 'ControlCabinFacade', axis, fixed, start, end,
               FLOOR, 56.4, holes=holes, color='steel', material='Metal')
        # Extra mullions establish a human-scale structural rhythm within the
        # panoramic band; the existing wall helper already supplies each centre.
        for u in range(math.ceil(start+12), math.floor(end), 12):
            if not any(a+.25 < u < b-.25 for a, b in spans):
                continue
            if any(abs(u-(a+b)/2) < .25 for a, b in spans):
                continue
            rect = (u-.1, u+.1, fixed-.2, fixed+.2) if axis == 'X' else (
                fixed-.2, fixed+.2, u-.1, u+.1)
            m.box(GROUP, 'ControlCabinMullion', rect, 47, 54,
                  'steel', 'Metal', physical=False)

    # Six-stud-wide ring joins the existing floor without steps or a new stair.
    # The floor remains open to both roles and can only be entered via the door.
    m.slab(GROUP, 'ControlInspectionWalkway', [OUTER], FLOOR,
           holes=[INNER], color='steel', material='DiamondPlate')
    for a, b in (((166, -42), (254, -42)), ((254, -42), (254, 82)),
                 ((254, 82), (166, 82)), ((166, 82), (166, -42))):
        m.rail(GROUP, a, b, FLOOR)

    # Steel cantilevers transfer the balcony back to the building at corners.
    # These are above the lower occupied floor and do not obstruct its rooms.
    for x, outside in ((172, 166), (248, 254)):
        for z in (-32, 72):
            m.line(GROUP, 'ControlBalconyCantilever',
                   (x, 39.5, z), (outside, 42.4, z), .45, 'steel')
            m.line(GROUP, 'ControlBalconyBearing',
                   (x, 42.2, z), (outside, 42.2, z), .45, 'steel')
    for rect in ((166, 254, -42.2, -41.8), (166, 254, 81.8, 82.2),
                 (165.8, 166.2, -42, 82), (253.8, 254.2, -42, 82)):
        m.box(GROUP, 'ControlBalconyEdgeBeam', rect, 41.8, 42.4,
              'steel', 'Metal', physical=False)

    # A shallow eave under the original roof shades the broad glazing band.
    # Its inner opening exactly retains the untouched roof and stair exits.
    m.slab(GROUP, 'ControlCabinEave', [(169.5, 250.5, -38.5, 78.5)],
           56.7, holes=[INNER], thick=.3, color='dark', material='Metal')

    west = [[188, FLOOR, 33], [210, FLOOR, 33], [210, FLOOR, 72],
            [210, FLOOR, 79]]
    circuit = [[232, FLOOR, 33], [210, FLOOR, 33], [210, FLOOR, 72],
               [210, FLOOR, 79], [169, FLOOR, 79], [169, FLOOR, -39],
               [251, FLOOR, -39], [251, FLOOR, 79], [210, FLOOR, 79]]
    m.route('Tower west stair to control balcony', west)
    m.route('Tower east stair and control balcony circuit', circuit)

    added = m.parts-before
    assert added <= 100, ('Tower control architecture net part budget exceeded', added)
    if not hasattr(m, 'architecture'):
        m.architecture = []
    m.architecture.append({
        'id': 'tower_control_cabin', 'model': GROUP,
        'kind': 'panoramic_control_cabin_and_inspection_walkway',
        'floor': FLOOR, 'glass_band': [47, 54],
        'walkway_outer': list(OUTER), 'walkway_inner': list(INNER),
        'walkway_width': 6, 'portal': [204, 216, 76, 43, 54],
        'reuses_stairs': [188, 232],
        'net_parts': added,
        'view': [124, 80, 136], 'look': [210, 50, 20],
        'engine_validation': 'pending',
    })
