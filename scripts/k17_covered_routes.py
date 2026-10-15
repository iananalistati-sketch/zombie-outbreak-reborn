"""Eight authored industrial shelters. No external meshes or runtime generators.

The marked paths stay clear at the 3-stud avatar diameter.  Prop suggestions are
initial storage locations, rather than a blueprint for an already sealed door.
"""


def build_covered_routes(m):
    records = []

    def box(g, name, rect, lo=1, hi=11, color='steel', material='Metal', **kw):
        return m.box(g, name, rect, lo, hi, color, material, **kw)

    def portal(g, axis, fixed, start, end, door, floor=1, height=10):
        m.wall(g, 'AccessFrame', axis, fixed, start, end, floor, floor+height,
               [(door[0], door[1], floor, floor+9, 'refugeDoor')],
               color='steel', material='Metal', thick=.5)

    def record(id_, label, group, bounds, floor, hold, approaches, stands, sights,
               view, look, hidden, style, props):
        result = dict(id=id_, label=label, model=group, bounds=bounds, floor=floor,
                      hold=hold, approaches=approaches, stands=stands,
                      sights=sights, view=view, look=look, hidden=hidden,
                      style=style, props=props)
        records.append(result)
        for name, points in approaches:
            m.route(name, points, 'refuge')
        return result

    # A maintenance lean-to follows the steam distribution line.  The staggered
    # entrance leaves a protected working recess behind the cable-reel divider.
    g='R40_PipeMaintenance'
    box(g,'MaintenancePlinth',(-140,-108,-38,-12),.1,1,'concrete','Concrete')
    box(g,'LeanToRoof',(-140,-108,-38,-12),11,11.5)
    for x in (-140,-108):box(g,'SheetSide',(x-.25,x+.25,-38,-12))
    box(g,'BackWall',(-140,-108,-38.25,-37.75))
    portal(g,'X',-12,-140,-108,(-127,-121))
    box(g,'CableReelDivider',(-129,-108,-24.25,-23.75),1,10.8,'olive')
    box(g,'PipeRack',(-139,-136,-35,-29),1,6.5,'rust')
    m.pipe(g,(-137.5,8,-36),(-137.5,8,-26),1)
    m.sign(g,-124,10,-11.6,'40 / MANUTENÇÃO DE VAPOR',width=26)
    record(40,'Abrigo da manutenção de vapor',g,[-140,-108,-38,-12],1,[-133,1,-31],
        [('R40 patio',[[-124,.1,-6],[-124,1,-18],[-133,1,-18],[-133,1,-31]]),
         ('R40 pela carga',[[-148,.1,-6],[-124,1,-6],[-124,1,-18],[-133,1,-18],[-133,1,-31]])],
        [[-133,1,-27],[-129,1,-28],[-133,1,-33],[-129,1,-33]],
        [([-124,1,-18],[-124,.1,-6]),([-133,1,-31],[-133,1,-16])],
        [-133,4,-31],[-133,6,-18],
        [[-129,1,-32],[-124,.1,-6]],'Abrigo de tubulações',
        [('Cabinet',-112,1,-34),('Cabinet',-112,1,-28),
         ('Crate',-112,1,-17),('Crate',-117,1,-17),('Crate',-137,1,-20)])

    # Short covered freight gallery: offset steel screens, a proper plinth and
    # two loading mouths.  Neither mouth crosses the north-alley through route.
    g='R41_CoveredFreight'
    box(g,'LoadingPlinth',(40,72,-108,-80),.1,1,'concrete','Concrete')
    box(g,'LoadingCanopy',(40,72,-108,-80),11,11.6)
    box(g,'BackWall',(40,72,-108.25,-107.75),1,11,'brick','Brick')
    box(g,'WestCargoWall',(39.75,40.25,-108,-80),1,11,'rust')
    portal(g,'X',-80,40,72,(60,66))
    portal(g,'Z',72,-108,-80,(-100,-94))
    box(g,'FreightBaffle',(55.75,56.25,-94,-80),1,10.8,'olive')
    box(g,'LoadingDesk',(43,50,-106,-103),1,4.2,'wood','WoodPlanks')
    m.sign(g,56,10,-79.6,'41 / CARGA COBERTA',width=25)
    record(41,'Galeria de carga coberta',g,[40,72,-108,-80],1,[48,1,-94],
        [('R41 patio',[[63,.1,-74],[63,1,-98],[48,1,-98],[48,1,-94]]),
         ('R41 leste',[[78,.1,-97],[68,1,-97],[48,1,-97],[48,1,-94]])],
        [[45,1,-95],[49,1,-95],[45,1,-90],[49,1,-90]],
        [([63,1,-98],[63,.1,-74]),([48,1,-97],[78,.1,-97])],
        [48,4,-94],[63,6,-98],
        [[48,1,-90],[63,.1,-74]],'Galeria de carga',
        [('Cabinet',44,1,-83),('Cabinet',51,1,-83),('Crate',68,1,-104),
         ('Crate',61,1,-104),('Crate',43,1,-100)])

    # A hollow original staff bus.  Its open interior is walkable; the roof,
    # engine partition and waist-height windows create actual usable cover.
    g='R42_StaffBus'
    box(g,'BusFloor',(50,64,-62,-22),.1,1,'steel','DiamondPlate')
    box(g,'BusRoof',(50,64,-62,-22),10,10.5,'olive')
    box(g,'RearEngine',(50,64,-62,-59),1,8.4,'olive')
    portal(g,'X',-22,50,64,(53,60),height=9)
    m.wall(g,'BusLeftSide','Z',50,-62,-22,1,10,
           [(-55,-30,4.2,8.2,'firePort')],color='olive',material='Metal',thick=.45)
    m.wall(g,'BusRightSide','Z',64,-62,-22,1,10,
           [(-56,-49,1,10,'refugeDoor'),(-45,-28,4.2,8.2,'firePort')],
           color='olive',material='Metal',thick=.45)
    box(g,'DriverShield',(50,58,-30.25,-29.75),1,9.5,'steel')
    for x in (50.4,63.6):
        for z in (-54,-30):
            box(g,'BusWheel',(x-.6,x+.6,z-1.7,z+1.7),0,3.4,'dark','SmoothPlastic',physical=False)
    for z in (-58.8,-36):box(g,'SeatBack',(50.6,53.4,z,z+.6),1,4,'wood','Wood')
    m.sign(g,57,9,-21.6,'42 / TRANSPORTE OPERÁRIO',width=13)
    record(42,'Ônibus de transporte operário',g,[50,64,-62,-22],1,[57,1,-40],
        [('R42 frontal',[[57,.1,-16],[57,1,-26],[61,1,-26],[61,1,-34],[57,1,-34],[57,1,-40]]),
         ('R42 traseiro',[[70,.1,-52],[60,1,-52],[57,1,-52],[57,1,-40]])],
        [[55,1,-40],[60,1,-40],[55,1,-45],[60,1,-45]],
        [([57,1,-40],[57,1,-52]),([57,1,-26],[57,.1,-16])],
        [57,4,-40],[60,6,-52],
        [[55,1,-39],[57,.1,-16]],'Transporte abandonado',
        [('Crate',54,1,-55),('Crate',60,1,-57),('Crate',52.8,1,-49),
         ('Crate',52.5,1,-33.5),('Crate',53,1,-26)])

    # A pallet sorting bay closes the otherwise exposed south-west yard.  The
    # covered dog-leg remains approachable from either industrial service lane.
    g='R43_PalletSorting'
    box(g,'SortingPlinth',(-140,-110,20,46),.1,1,'concrete','Concrete')
    box(g,'SortingCanopy',(-140,-110,20,46),11,11.6,'rust')
    box(g,'RearMasonry',(-140,-110,45.7,46.3),1,11,'brick','Brick')
    box(g,'WestMasonry',(-140.3,-139.7,20,46),1,11,'brick','Brick')
    portal(g,'X',20,-140,-110,(-128,-122))
    portal(g,'Z',-110,20,46,(32,38))
    box(g,'SortingScreen',(-131,-110,29.7,30.3),1,10.8,'olive')
    box(g,'PackingCounter',(-138,-130,43,45),1,4.2,'wood','WoodPlanks')
    m.sign(g,-125,10,19.6,'43 / TRIAGEM DE PALETES',width=26)
    record(43,'Triagem de paletes',g,[-140,-110,20,46],1,[-133,1,38],
        [('R43 patio',[[-125,.1,14],[-125,1,25],[-133,1,25],[-133,1,38]]),
         ('R43 lateral',[[-104,.1,35],[-115,1,35],[-133,1,35],[-133,1,38]])],
        [[-135,1,34],[-131,1,34],[-135,1,39],[-131,1,39]],
        [([-125,1,25],[-125,.1,14]),([-133,1,35],[-104,.1,35])],
        [-133,4,38],[-133,6,25],
        [[-131,1,39],[-125,.1,14]],'Baia de triagem',
        [('Cabinet',-114,1,42),('Cabinet',-120,1,42),('Crate',-114,1,24),
         ('Crate',-120,1,24),('Crate',-137,1,24)])

    # This maintenance redoubt fits below the existing western factory gallery,
    # using the gallery as a structural canopy rather than adding another box.
    g='R44_UnderGallery'
    box(g,'LowerGalleryRoof',(-140,-118,178,206),11.5,12,'steel','DiamondPlate')
    box(g,'WestScreen',(-139.75,-139.25,178,206),1,11.5,'olive')
    box(g,'EastScreen',(-118.5,-118,178,206),1,11.5,'olive')
    box(g,'RearScreen',(-140,-118,205.5,206),1,11.5,'olive')
    portal(g,'X',178,-140,-118,(-129,-123))
    box(g,'StaggeredToolBoard',(-139.5,-130,186.7,187.3),1,10.8,'steel')
    box(g,'MachineServiceBench',(-138,-135,196,203),1,4.2,'wood','WoodPlanks')
    m.sign(g,-129,10,177.6,'44 / SOB A GALERIA',width=20)
    record(44,'Manutenção sob a galeria',g,[-140,-118,178,206],1,[-129,1,198],
        [('R44 producao',[[-124,1,170],[-126,1,183],[-126,1,194],[-129,1,194],[-129,1,198]]),
         ('R44 oeste',[[-135,1,172],[-126,1,172],[-126,1,194],[-129,1,194],[-129,1,198]])],
        [[-132,1,192],[-127,1,192],[-132,1,198],[-127,1,198]],
        [([-126,1,194],[-126,1,172]),([-129,1,198],[-129,1,190])],
        [-129,4,198],[-126,6,180],
        [[-133,1,197],[-126,1,172]],'Abrigo sob galeria',
        [('Cabinet',-122,1,201),('Cabinet',-128,1,203),('Crate',-137,1,181),
         ('Crate',-122,1,181),('Crate',-122,1,187)])

    # A tool crib extends from the front service-gallery structure.  A solid
    # inside turn shelters the crew while its side hatch watches the press aisle.
    g='R45_ToolCrib'
    box(g,'ToolCribRoof',(54,80,90,118),11.5,12,'steel','DiamondPlate')
    box(g,'BackWall',(54,80,117.75,118.25),1,11.5,'brick','Brick')
    box(g,'WestWall',(53.75,54.25,90,118),1,11.5,'brick','Brick')
    portal(g,'X',90,54,80,(66,72),height=10.5)
    portal(g,'Z',80,90,118,(102,108),height=10.5)
    box(g,'ToolCribBaffle',(63.75,64.25,90,102),1,10.8,'olive')
    box(g,'ToolRack',(55,58,110,116),1,7,'olive')
    m.sign(g,67,10,89.6,'45 / FERRAMENTARIA',width=22)
    record(45,'Ferramentaria das prensas',g,[54,80,90,118],1,[60,1,106],
        [('R45 frente',[[69,1,84],[69,1,106],[60,1,106]]),
         ('R45 prensas',[[93,1,105],[75,1,105],[60,1,105],[60,1,106]])],
        [[59,1,105],[63,1,105],[61,1,110],[65,1,110]],
        [([69,1,106],[69,1,84]),([60,1,105],[93,1,105])],
        [60,4,106],[69,6,105],
        [[60,1,110],[69,1,84]],'Ferramentaria',
        [('Cabinet',76,1,113),('Cabinet',70,1,113),('Crate',57,1,94),
         ('Crate',59,1,100),('Crate',76,1,95)])

    # Two covered sections reuse the actual sewer lining and floor.  These are
    # walkable bends and service bays, not decorative grilles or clipped avatars.
    g='R46_SewerSwitchRoom';floor=-24
    portal(g,'X',-80,-9,9,(-3,3),floor=floor)
    portal(g,'X',-40,-9,9,(-3,3),floor=floor)
    box(g,'WestServiceLiner',(-9.25,-8.75,-80,-40),floor,floor+10)
    box(g,'EastServiceLiner',(8.75,9.25,-80,-40),floor,floor+10)
    box(g,'SwitchRoomCeiling',(-9,9,-80,-40),floor+9.6,floor+10.1)
    box(g,'SwitchgearBaffle',(-9,1,-58.3,-57.7),floor,floor+9.5,'olive')
    box(g,'SwitchgearPanel',(-8.5,-8.25,-56,-42),floor+3,floor+8,'olive',physical=False)
    m.sign(g,0,-16,-80.6,'46 / CHAVES ELÉTRICAS',width=16)
    record(46,'Sala de chaves do subterrâneo',g,[-9,9,-80,-40],floor,[2,floor,-47],
        [('R46 norte',[[0,floor,-86],[0,floor,-73],[5,floor,-73],[5,floor,-52],[2,floor,-52],[2,floor,-47]]),
         ('R46 sul',[[0,floor,-34],[0,floor,-45],[2,floor,-45],[2,floor,-47]])],
        [[0,floor,-49],[5,floor,-49],[0,floor,-44],[5,floor,-44]],
        [([5,floor,-73],[5,floor,-60]),([2,floor,-47],[0,floor,-34])],
        [2,floor+3,-47],[5,floor+5,-55],
        [[0,floor,-47],[0,floor,-86]],'Sala elétrica subterrânea',
        [('Cabinet',-5,floor,-75),('Cabinet',-5,floor,-69),('Crate',-5,floor,-63),
         ('Crate',-5,floor,-51),('Crate',-5,floor,-44)])

    g='R47_DrainControl'
    portal(g,'X',48,-9,9,(-3,3),floor=floor)
    portal(g,'X',88,-9,9,(-3,3),floor=floor)
    box(g,'WestServiceLiner',(-9.25,-8.75,48,88),floor,floor+10)
    box(g,'EastServiceLiner',(8.75,9.25,48,88),floor,floor+10)
    box(g,'DrainControlCeiling',(-9,9,48,88),floor+8.5,floor+9)
    box(g,'FloodControlCabinet',(-4,4,62,72),floor,floor+7,'olive')
    box(g,'ControlPanel',(-3.7,3.7,71.95,72.15),floor+3,floor+6.5,'dark',physical=False)
    m.sign(g,0,-16.2,47.6,'47 / CONTROLE DA DRENAGEM',width=16)
    record(47,'Posto de controle da drenagem',g,[-9,9,48,88],floor,[0,floor,79],
        [('R47 norte',[[0,floor,42],[0,floor,55],[6.5,floor,55],[6.5,floor,77],[0,floor,77],[0,floor,79]]),
         ('R47 sul',[[0,floor,94],[0,floor,79]])],
        [[-2.5,floor,78],[2.5,floor,78],[-2.5,floor,81.5],[2.5,floor,81.5]],
        [([6.5,floor,77],[6.5,floor,55]),([0,floor,79],[0,floor,94])],
        [0,floor+3,79],[6.5,floor+5,77],
        [[0,floor,79],[0,floor,42]],'Posto de drenagem',
        [('Cabinet',-6,floor,52),('Cabinet',-6,floor,58),('Crate',-5,floor,85),
         ('Crate',5,floor,85),('Crate',-6,floor,75)])
    return records
