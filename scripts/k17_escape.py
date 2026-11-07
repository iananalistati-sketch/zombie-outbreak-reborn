"""Original evacuation route through the existing K-17, never a CS map import."""
import json

CONFIG={
    'Duration':360,'ExtractionSeconds':18,'ActivationRange':8,
    'MotherSpawn':[-68,1,-246],
    'SpawnDistance':48,
    'InitialSpawns':[[-68,1,-246],[-68,1,-238],[-68,1,-230]],
    'Respawns':[
        {'AfterStage':1,'Label':'Descida norte',
         'Advance':{'Min':[-230,-25,-200],'Max':[-168,-13,-40]},
         'Points':[[0,-24,-146],[0,-24,-154],[0,-24,-162]]},
        {'AfterStage':2,'Label':'Travessia das bombas',
         'Advance':{'Min':[-10,-25,168],'Max':[148,-13,188]},
         'Points':[[-160,-24,144],[-152,-24,144],[-144,-24,144]]},
    ],
    'Extraction':{'Min':[214,-1,216],'Max':[242,12,240]},
    'HoldGates':[
        {'Stage':1,'Name':'GeneratorExit','Min':[138,1,-124.2],'Max':[150,12,-123.8]},
        {'Stage':2,'Name':'MaintenanceExit','Min':[133,.1,122.2],'Max':[147,10.5,123.2]},
    ],
    'Stages':[
        {'Label':'Gerador de emergência','Hint':'Entre na estação elétrica, na ala norte.','Point':[144,1,-224],'Control':[150,4,-228],'HoldSeconds':12},
        {'Label':'Bombeamento subterrâneo','Hint':'Desça pelas escadarias de manutenção. M mostra o percurso.','Point':[-70,-22.5,158],'Control':[-70,-19.5,162],'HoldSeconds':15},
        {'Label':'Portão de evacuação','Hint':'Suba pela escadaria leste e siga para o terminal no estacionamento.','Point':[224,.1,254],'Control':[231.5,3.1,254],'HoldSeconds':20},
    ],
}


def luau(value):
    if isinstance(value,dict):return 'table.freeze({'+','.join(k+'='+luau(v) for k,v in value.items())+'})'
    if isinstance(value,list):return 'table.freeze({'+','.join(luau(v) for v in value)+'})'
    return json.dumps(value,ensure_ascii=False)


def build_escape(m):
    # Connected walkable routes join the measured rooms and stair shafts.
    # North stairs descend into the maintenance ring; east stairs return to the
    # loading yard. These are checked with the same body clearance as Survival.
    m.route('ZE start to emergency generator',[[-68,1,-136],[-68,1,-124],[-68,.1,-120],
        [144,.1,-120],[144,1,-124],[144,1,-224]],'escape')
    m.route('ZE generator to pump defense',[[144,1,-224],[144,1,-124],[144,.1,-116],[20,.1,-116],
        [20,0,-50],[30,0,-50],[30,0,-56],[30,0,-62],[30,-24,-110],[30,-24,-120],[0,-24,-120],
        [0,-24,-212],[-220,-24,-212],[-220,-24,144],[-108,-24,144],[-82,-24,144],[-82,-24,145],
        [-82,-22.5,151],[-82,-22.5,158],[-70,-22.5,158]],'escape')
    m.route('ZE pump defense to evacuation',[[-70,-22.5,158],[-56,-22.5,155],[-56,-22.5,151],
        [-56,-24,145],[-56,-24,144],[0,-24,144],[0,-24,178],[140,-24,178],[140,-24,172],
        [140,0,124],[140,0,116],[170,0,116],[170,0,260],[228,.08,260],[224,.1,254]],'escape')
    g='EscapeObjectives'
    for index,stage in enumerate(CONFIG['Stages'],1):
        x,y,z=stage['Control']
        part=m.box(g,f'Control{index}',(x-1,x+1,z-.28,z+.28),stage['Point'][1],y+3,'steel','Metal')
        part.find('Properties/bool[@name="CanQuery"]').text='true'
        p=m.item(part,'ProximityPrompt','Activate').find('Properties')
        for kind,key,value in [('string','ActionText','Acionar'),('string','ObjectText',stage['Label']),
                               ('float','HoldDuration',1),('float','MaxActivationDistance',8),
                               ('bool','RequiresLineOfSight',True),('bool','Enabled',False)]:m.prop(p,kind,key,value)
        m.box(g,f'Indicator{index}',(x-.6,x+.6,z-.36,z-.29),y+.4,y+.8,'yellow','Neon',physical=False)
        for xx in (x-.45,x,x+.45):m.box(g,'ControlButton',(xx-.12,xx+.12,z-.37,z-.29),y-.7,y-.4,'red','Metal',physical=False)
        m.sign(g,x,y+2.5,z,f'ZE {index} / {stage["Label"].upper()}',width=10,color='blue')
        m.route(f'Escape objective {index} stance',[stage['Point'],stage['Point']],'escape')

    g='R50_EvacuationBay'
    m.box(g,'DockRoof',(211.5,244.5,213.5,243),12.5,13,'steel','Metal')
    for x in (212,244):
        m.wall(g,'DockSide','Z',x,214,242,.1,12.5,
               [(220,232,5,9,'window')],color='aged')
    m.wall(g,'DockRear','X',214,212,244,.1,12.5,color='brick',material='Brick')
    m.box(g,'InnerBlastReturn',(222,222.5,225,235),.1,8.5,'olive','Metal')
    # Full-height terminal gate is disabled outside Escape. The structure is a
    # usable Survival refuge with the same open entrance when Escape is inactive.
    gate=m.box(g,'EvacuationGate',(212.5,243.5,241.5,242.2),.1,12.5,'steel','Metal',physical=False,alpha=1)
    gate.find('Properties/bool[@name="CanQuery"]').text='false'
    for x in (212,244):m.box(g,'DockColumn',(x-.5,x+.5,213.5,243),12,12.5,'steel','Metal',physical=False)
    for x in (214,242):
        m.box(g,'DockBollard',(x-.4,x+.4,246,246.8),.1,3.2,'yellow','Metal')
    for x in (216,220,224,228,232,236,240):
        m.box(g,'DockThresholdMark',(x-.8,x+.8,243,244),.11,.14,'yellow',physical=False)
    m.sign(g,228,11,242.6,'50 / EVACUAÇÃO - ACESSO CONTROLADO',width=30,face=2,color='blue')
    m.sign(g,228,10.6,214.7,'AGUARDE A EXTRAÇÃO / PROTEJA A ENTRADA',width=28,face=2,color='olive')
    m.lamp(g,228,12,226,range_=34)
    # Visible roof ventilation, framed glazing and conduit give the shelter a
    # service-building function; keep the roof inaccessible and nonessential.
    for x in (218,238):
        m.box(g,'VentilatorHousing',(x-1.5,x+1.5,224,227),13,14.2,'steel','Metal',physical=False)
        for z in (224.5,225.2,225.9,226.6):m.box(g,'VentilatorSlat',(x-1.2,x+1.2,z-.05,z+.05),14.2,14.3,'dark','Metal',physical=False)
    m.box(g,'DockConduit',(212.6,212.85,215,239),10,10.25,'rust','Metal',physical=False)
    hold=[218,.1,220]
    approach=[[228,.1,254],[228,.1,238],[228,.1,220],hold]
    m.route('R50 terminal approach',approach,'escape')
    # The road-side route avoids the existing wheel stops and quarantine fence.
    m.route('Escape terminal road',[[266,.08,260],[228,.08,260],[228,.1,254]],'escape')
    m.refuges.append(dict(id=50,label='Terminal de evacuação',model=g,bounds=[212,244,214,242],floor=.1,hold=hold,
        approaches=[('R50 terminal approach',approach)],stands=[[216,.1,220],[220,.1,220],[216,.1,224],[220,.1,224]],
        sights=[([228,.1,232],[228,.1,254])],view=[218,3.1,220],look=[228,5.1,240],hidden=[hold,[228,.1,254]],
        style='Terminal de evacuação',props=[('Cabinet',236,.1,246),('Table',218,0,250),('Crate',236,.1,225),
            ('Crate',240,.1,225),('Cabinet',216,.1,234),('Crate',238,0,254)]))
    m.architecture.append({'id':'escape_evacuation_terminal','model':g,'features':[
        'Three sequential controllers inside existing power/pump/yard sectors',
        'Sheltered extraction bay, shutter, cover, framed glazing and six physical props']})
    from k17_escape_defense import build_escape_defense
    build_escape_defense(m,CONFIG)
    # Every candidate is a measured standing position connected to the route;
    # the runtime also rejects occupied volumes and nearby living humans.
    for level,points in enumerate([CONFIG['InitialSpawns']]+[r['Points'] for r in CONFIG['Respawns']]):
        connection=[[-68,1,-224],[0,-24,-120],[-108,-24,144]][level]
        for index,point in enumerate(points,1):
            m.route(f'Infection return {level}/{index}',[point,connection],'spawn')
    board=m.sign('R50_EvacuationBay',228,8.1,214.7,'ZE / AGUARDE A SEQUÊNCIA',width=27,face=2,color='dark')
    board.find('Properties/string[@name="Name"]').text='EvacuationStatus'
