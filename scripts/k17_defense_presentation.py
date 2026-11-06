"""Authored wayfinding and administration finish; no downloaded map content.

All additions are query/collision-free finishes on existing structures. Header
signs use the real door apertures, so they do not close the measured routes.
"""
import copy


def build_defense_presentation(m):
    def two_sided(sign):
        gui=sign.find('Item')
        other=copy.deepcopy(gui)
        other.find('Properties/string[@name="Name"]').text='ReverseLettering'
        face=other.find('Properties/token[@name="Face"]')
        face.text='2' if face.text=='5' else '5'
        sign.append(other)

    # Identify the room at its actual aperture, rather than at a floating point
    # in the middle of an interior. Labels match the tactical map/HUD IDs.
    for refuge in m.refuges:
        portals=[o for o in m.openings if o['model']==refuge['model'] and o['kind'] in ('refugeDoor','door')]
        for opening in portals:
            middle=(opening['start']+opening['end'])/2
            width=max(4,min(12,opening['end']-opening['start']+1.5))
            x,z=(middle,opening['fixed']) if opening['axis']=='X' else (opening['fixed'],middle)
            sign=m.sign(refuge['model'],x,opening['top']+.65,z,
                        f'{refuge["id"]:02d} / {refuge["label"].upper()}',width=width,color='blue')
            props=sign.find('Properties')
            props.find('string[@name="Name"]').text='RefugeHeaderSign'
            props.find('Vector3[@name="size"]/Y').text='1.1'
            if opening['axis']=='Z':
                cf=props.find('CoordinateFrame')
                for key,value in {'R00':0,'R02':1,'R20':-1,'R22':0}.items():cf.find(key).text=str(value)
            two_sided(sign)
            # Mount the lettering directly on an existing lintel when possible.
            # This avoids another physical Part per doorway and reuses the
            # authored structural header, including its lighting/occlusion.
            host=None
            for item in list(m.group(refuge['model']).findall('Item')):
                p=item.find('Properties')
                if item.attrib['class']!='Part' or p.findtext('bool[@name="CanCollide"]')!='true':continue
                cf=p.find('CoordinateFrame');size=p.find('Vector3[@name="size"]')
                if all(abs(value-float(cf.find(axis).text))<=float(size.find(axis).text)/2+.01
                       for axis,value in zip('XYZ',(x,opening['top']+.2,z))):
                    host=item;break
            if host is not None:
                for gui in list(sign.findall('Item')):
                    gui.find('Properties/string[@name="Name"]').text='RefugeHeaderSign'
                    if opening['axis']=='Z':
                        face=gui.find('Properties/token[@name="Face"]');face.text='0' if face.text=='5' else '3'
                    host.append(gui)
                m.group(refuge['model']).remove(sign);m.parts-=1

    g='A_Administration'
    for floor in (1,):
        # Continuous circulation remains 16 studs wide. Thin painted lines and
        # service trims communicate the spine without changing its collisions.
        for x in (-74.8,-61.2):
            m.box(g,'AdministrationGuideStripe',(x-.11,x+.11,-246,-128),floor+.015,floor+.04,'yellow',physical=False,shadow=False)
        for z in (-135,-174,-223):
            m.box(g,'AdministrationCrossStripe',(-74.8,-61.2,z-.1,z+.1),floor+.02,floor+.045,'yellow',physical=False,shadow=False)
        sign=m.sign(g,-68,floor+12.2,-124.65,f'A{floor//14} / PATIO - SAIDA',width=15,face=5,color='blue')
        sign.find('Properties/string[@name="Name"]').text='AdministrationExitSign'
        m.sign(g,-68,floor+12.2,-249.35,'ESCADAS / ARQUIVO / SERVICO',width=15,face=2,color='blue')
        for z in (-136,-180,-226):
            # Cabinets and gauges are flush to existing solid corridor walls,
            # outside the suite-door apertures. No invisible collision volume.
            m.box(g,'ServiceCabinet',(-75.68,-75.25,z-1.8,z+1.8),floor+2.1,floor+5.4,'olive','Metal',physical=False)
            for zz in (z-1,z,z+1):
                m.box(g,'CabinetLouvre',(-75.24,-75.17,zz-.06,zz+.06),floor+3,floor+4.8,'dark','Metal',physical=False)
            m.box(g,'ServiceConduit',(-75.48,-75.28,z-.16,z+.16),floor+5.4,floor+12,'steel','Metal',physical=False)
        # Ceiling beams and a visible cable raceway give the corridor depth;
        # existing fixtures provide illumination, avoiding many new lights.
        m.box(g,'CableRaceway',(-68.6,-67.4,-245,-130),floor+12.4,floor+12.7,'steel','Metal',physical=False)
        for z in (-142,-185,-228):
            m.box(g,'RacewaySuspension',(-75.6,-60.4,z-.1,z+.1),floor+12.8,floor+13,'dark','Metal',physical=False)

    # Window casings and sill caps along both admin frontages; use each real
    # opening, retaining its glazing and the original sight lines.
    for o in m.openings:
        if o['model']!=g or o['axis']!='X' or o['kind']!='window' or o['bottom']>12:continue
        for y in (o['bottom']-.12,o['top']+.12):
            m.box(g,'AdministrationWindowTrim',(o['start']-.2,o['end']+.2,o['fixed']-.24,o['fixed']+.24),y-.1,y+.1,'white',physical=False)
    m.architecture.append({'id':'defense-presentation-v02','model':g,'features':[
        'Two-sided refuge signs on real door headers','Administration painted circulation spine',
        'Ground-floor electrical service cabinets and suspended raceway','Ground-floor frontage window casings']})
