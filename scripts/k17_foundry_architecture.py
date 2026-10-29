"""Foundry roof monitors and receiving canopy, built into the existing K-17 shell.

The four existing skylights were placed over an uncut opaque roof. This replaces
that assembly with actual apertures, framed clerestory glazing and inclined
metal roofs. WedgePart end cheeks use Roblox's native high edge at local +Z.
No asset uploads, custom textures, scripts or additional lights are introduced.
"""
from __future__ import annotations

import math


GROUP = 'C_FoundryHall'
ROOF = (-142, 124, 68, 246)
MONITORS = [(x, z) for x in (-80, 20) for z in (112, 214)]


def _sloped_sheet(m, name, x0, x1, z0, z1, low, high):
    """A rectangular sheet whose local +Z rises towards the clerestory face."""
    span = z1-z0
    rise = high-low
    angle = math.atan2(rise, span)
    length = math.hypot(span, rise)
    item = m.box(GROUP, name, (x0, x1, -length/2, length/2), -.22, .22,
                 'aged', 'CorrodedMetal')
    frame = item.find('./Properties/CoordinateFrame[@name="CFrame"]')
    c, s = math.cos(angle), math.sin(angle)
    values = [(x0+x1)/2, (low+high)/2, (z0+z1)/2,
              1, 0, 0, 0, c, s, 0, -s, c]
    for key, value in zip(['X', 'Y', 'Z']+
                          [f'R{i}{j}' for i in range(3) for j in range(3)], values):
        frame.find(key).text = str(round(value, 6))
    return item


def build_foundry_architecture(m):
    """Replace only the opaque skylight/roof assembly; preserve floor-29 routes."""
    group = m.group(GROUP)
    replaced = {'FactoryRoof', 'SkylightCurb', 'SkylightGlazing', 'SkylightMullion'}
    removed = []
    for item in list(group):
        if item.tag != 'Item':
            continue
        if item.findtext('./Properties/string[@name="Name"]') in replaced:
            assert item.get('class') == 'Part', 'Unexpected roof source geometry'
            removed.append(item)
    assert len(removed) == 21, 'Expected the original roof and four skylight assemblies'
    before = m.parts
    for item in removed:
        group.remove(item)
    m.parts -= len(removed)

    holes = [(x-16, x+16, z-8, z+8) for x, z in MONITORS]
    m.slab(GROUP, 'FactoryRoof', [ROOF], 29, holes=holes, color='aged')

    for index, (x, z) in enumerate(MONITORS, 1):
        x0, x1, z0, z1 = x-16, x+16, z-8, z+8
        # Curb surrounds the aperture; it never caps the opening below the glass.
        for rect in ((x0-.6, x0+.3, z0-.6, z1+.6),
                     (x1-.3, x1+.6, z0-.6, z1+.6),
                     (x0+.3, x1-.3, z0-.6, z0+.3),
                     (x0+.3, x1-.3, z1-.3, z1+.6)):
            m.box(GROUP, 'MonitorCurb', rect, 29, 30.4, 'steel', 'Metal')

        # Native triangular cheeks close both ends under the inclined roof.
        # Their conservative AABBs remain outside every authored roof route.
        for xx in (x0, x1):
            cheek = m.box(GROUP, 'MonitorEndCheek',
                          (xx-.18, xx+.18, z0, z1), 30.4, 38.4,
                          'steel', 'Metal')
            cheek.set('class', 'WedgePart')

        # The high south face admits daylight through an actual roof aperture.
        m.box(GROUP, 'MonitorClerestoryGlass',
              (x0+.2, x1-.2, z1-.08, z1+.08), 30.4, 38.35,
              'glass', 'Glass', alpha=.35, shadow=False)
        for xx in (x-8, x, x+8):
            m.box(GROUP, 'MonitorGlazingMullion',
                  (xx-.1, xx+.1, z1-.18, z1+.18), 30.4, 38.4,
                  'steel', 'Metal', physical=False)
        m.box(GROUP, 'MonitorClerestoryHead',
              (x0-.3, x1+.3, z1-.25, z1+.25), 38.25, 38.55,
              'steel', 'Metal', physical=False)
        _sloped_sheet(m, 'MonitorInclinedRoof',
                      x0-.6, x1+.6, z0-.4, z1+.4, 30.5, 38.9)
        # A low eave/gutter terminates the folded roof without an open foot gap.
        m.box(GROUP, 'MonitorLowEave',
              (x0-.6, x1+.6, z0-.5, z0-.2), 30.25, 30.8,
              'dark', 'Metal', physical=False)

    # A cantilevered freight canopy belongs to the existing receiving portal.
    # Brackets start above head height and sit outside the 20-stud door opening.
    # No posts interrupt Central distribution at z=56 or receiving route x=-82.
    m.box(GROUP, 'ReceivingCanopyRoof', (-114, -50, 48, 67.5),
          18.4, 18.85, 'steel', 'Metal')
    m.box(GROUP, 'ReceivingCanopyFascia', (-114, -50, 47.8, 48.2),
          17.9, 18.9, 'rust', 'Metal', physical=False)
    for xx in (-110, -54):
        m.line(GROUP, 'ReceivingCantileverChord',
               (xx, 18.1, 67), (xx, 18.1, 49), .45, 'steel')
        m.line(GROUP, 'ReceivingCantileverBrace',
               (xx, 14.8, 67), (xx, 18.1, 49), .32, 'steel')
        m.box(GROUP, 'ReceivingWallBearing',
              (xx-.6, xx+.6, 66.6, 67.2), 14.2, 18.5,
              'steel', 'Metal', physical=False)
    m.box(GROUP, 'ReceivingCanopyRearBeam', (-114, -50, 66.6, 67.2),
          17.9, 18.5, 'steel', 'Metal', physical=False)

    added = m.parts-before
    assert added <= 70, ('Foundry architecture net part budget exceeded', added)
    if not hasattr(m, 'architecture'):
        m.architecture = []
    m.architecture.append({
        'id': 'foundry_roof_monitors', 'model': GROUP,
        'kind': 'native_sawtooth_roof_monitors',
        'apertures': [list(rect) for rect in holes],
        'aperture_floor': 29, 'monitor_height': 39.2,
        'native_wedge_high_edge': '+Z',
        'canopy': [-114, -50, 48, 67.5],
        'canopy_underside': 18.4,
        'net_parts': added,
        'view': [-42, 51, 32], 'look': [-30, 32, 155],
        'engine_validation': 'pending',
    })
