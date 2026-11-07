"""Two original service rooms opening onto the existing maintenance ring.

The floor/ceiling/envelope are part of TUNNELS; these are fitted interiors,
not freestanding boxes intersecting the old tunnel lining.
"""


ROOMS=[(-210,-168,-60,-20),(80,122,188,226)]


def build_maintenance_refuges(m):
    floor=-24
    g='R52_RingWorkshop'
    m.wall(g,'WorkshopFront','Z',-210,-60,-20,floor,-13.5,
           [(-58,-50,floor,-14.5,'refugeDoor'),(-30,-22,floor,-14.5,'refugeDoor')],color='steel',material='Metal',thick=.5)
    m.box(g,'WorkshopBlastReturn',(-196,-195,-60,-40),floor,-14,'aged')
    # A fitted workbench, tool-board and overhead service pipes explain the
    # room's purpose; all small trim is visual and outside the swept routes.
    m.box(g,'RepairWorkbench',(-171,-169,-51,-39),floor,floor+3,'steel','Metal')
    m.box(g,'WorkbenchTop',(-171.3,-168.8,-51.3,-38.7),floor+3,floor+3.25,'wood','WoodPlanks',physical=False)
    m.box(g,'ToolBoard',(-168.8,-168.65,-50,-40),floor+4,floor+7,'dark','Metal',physical=False)
    for z in (-48,-45,-42):
        m.box(g,'MountedServiceTool',(-169.05,-168.8,z-.12,z+.12),floor+4.5,floor+6.3,'rust','Metal',physical=False)
    m.line(g,'WorkshopServicePipe',(-204,-14.4,-58),(-170,-14.4,-58),.45,'rust')
    m.sign(g,-190,-16,-59.4,'52 / OFICINA DO ANEL OESTE',width=27,face=2,color='blue')
    sign=m.sign(g,-210.35,-15.8,-40,'52 / RECUO - DOIS ACESSOS',width=14,color='blue')
    frame=sign.find('Properties/CoordinateFrame')
    for key,value in {'R00':0,'R02':1,'R20':-1,'R22':0}.items():frame.find(key).text=str(value)
    m.lamp(g,-183,-14.2,-35,range_=36)
    hold=[-178,floor,-48]
    paths=[('R52 workshop north approach',[[-220,floor,-54],[-202,floor,-54],[-202,floor,-34],[-190,floor,-34],[-190,floor,-48],hold]),
           ('R52 workshop south approach',[[-220,floor,-26],[-202,floor,-26],[-178,floor,-26],hold])]
    for name,points in paths:m.route(name,points,'refuge')
    m.refuges.append(dict(id=52,label='Oficina do anel oeste',model=g,bounds=list(ROOMS[0]),floor=floor,hold=hold,
        approaches=paths,stands=[hold,[-174,floor,-48],[-178,floor,-42],[-174,floor,-42]],
        sights=[([-202,floor,-54],[-220,floor,-54])],hidden=[hold,[-220,floor,-54]],
        view=[-178,floor+3,-48],look=[-196,floor+5,-35],style='Recuo de manutenção',
        props=[('Cabinet',-173.5,floor,-56),('Crate',-184,floor,-56),('Crate',-206.5,floor,-44),
               ('Cabinet',-204,floor,-21.8),('Table',-186,floor,-21.8),('Crate',-173,floor,-34)]))

    g='R53_ValveRoom'
    m.wall(g,'ValveRoomFront','X',188,80,122,floor,-13.5,
           [(88,96,floor,-14.5,'refugeDoor'),(112,120,floor,-14.5,'refugeDoor')],color='steel',material='Metal',thick=.5)
    m.box(g,'ValveRoomBlastReturn',(80,104,200.5,201.5),floor,-14,'aged')
    # Manifold and gauges sit against the far wall, leaving a real retreat
    # behind the return. Both entrances connect to the southern ring corridor.
    m.line(g,'ValveManifold',(94,-17,225.2),(118,-17,225.2),.6,'rust')
    for x in (96,104,112):
        m.line(g,'ValveRiser',(x,-23,225.2),(x,-14.4,225.2),.4,'steel')
        m.box(g,'ValveWheel',(x-.5,x+.5,224.7,225),-20,-19,'red','Metal',physical=False)
        m.box(g,'PressureGauge',(x-.45,x+.45,224.7,224.95),-16,-15.1,'white','Metal',physical=False)
    m.sign(g,104,-16,187.6,'53 / CÂMARA DE VÁLVULAS',width=14,face=5,color='blue')
    m.sign(g,92,-16.2,201.8,'RECUO / VIGIE A ENTRADA LESTE',width=19,face=2,color='olive')
    m.lamp(g,108,-14.2,211,range_=35)
    hold=[84,floor,216]
    paths=[('R53 valve room west approach',[[92,floor,178],[92,floor,195],[110,floor,195],[110,floor,208],[84,floor,208],hold]),
           ('R53 valve room east approach',[[116,floor,178],[116,floor,216],hold])]
    for name,points in paths:m.route(name,points,'refuge')
    m.refuges.append(dict(id=53,label='Câmara de válvulas',model=g,bounds=list(ROOMS[1]),floor=floor,hold=hold,
        approaches=paths,stands=[hold,[88,floor,216],[84,floor,222],[88,floor,222]],
        sights=[([92,floor,195],[92,floor,178])],hidden=[hold,[92,floor,178]],
        view=[84,floor+3,216],look=[110,floor+5,208],style='Recuo de manutenção',
        props=[('Cabinet',83.5,floor,192),('Table',96,floor,222),('Cabinet',118,floor,222),
               ('Crate',106,floor,204),('Crate',99,floor,204),('Crate',106,floor,222)]))
    m.architecture.append({'id':'maintenance_defense_rooms','model':'U1_MaintenanceNetwork','features':[
        'Two service interiors integrated into the tunnel floor and envelope',
        'Two entrances each, protected retreat, repair bench and valve manifold',
        'Twelve movable barricade props, four group positions per room']})
