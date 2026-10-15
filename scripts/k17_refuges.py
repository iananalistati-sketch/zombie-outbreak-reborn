"""Authored defensive interiors. Coordinates use the actual K-17 architectural grid."""


def build_refuges(m):
    data=[]
    def portal(group,axis,fixed,a,b,low,start,end):
        m.wall(group,'SecurityPartition',axis,fixed,a,b,low,low+10.4,
               [(start,end,low,low+9,'refugeDoor')],color='plaster',thick=.5)
        # A real steel lintel and side jambs, not an invisible choke volume.
        for u in (start-.12,end+.12):
            rect=(u-.12,u+.12,fixed-.36,fixed+.36) if axis=='X' else (fixed-.36,fixed+.36,u-.12,u+.12)
            m.box(group,'DoorJamb',rect,low,low+9,'steel','Metal',physical=False)
    def record(id_,label,group,bounds,floor,hold,approaches,stands,sights,view,look):
        data.append(dict(id=id_,label=label,model=group,bounds=bounds,floor=floor,
                         hold=hold,approaches=approaches,stands=stands,sights=sights,view=view,look=look))
        for name,points in approaches:m.route(name,points,'refuge')

    g='R07_Stockroom'
    portal(g,'Z',-231,100,148,1,120,126)
    portal(g,'X',104,-264,-231,1,-247,-241)
    m.box(g,'PackingBench',(-258,-247,129,131),1,4.2,'wood','WoodPlanks')
    m.box(g,'BenchApron',(-258,-247,130.7,131),4.2,5,'steel','Metal',physical=False)
    for x in (-258,-254,-250):
        m.box(g,'PalletStack',(x,x+2.8,140,145),1,3.4,'wood','WoodPlanks')
    m.sign(g,-248,10,147.35,'07 / ESTOQUE · EMBALAGEM',width=28)
    m.lamp(g,-246,11.8,136,range_=30)
    record(7,'Estoque de embalagem',g,[-264,-225,100,148],1,[-250,1,123],
        [('R07 corredor',[[-217,1,123],[-250,1,123]]),
         ('R07 sala vizinha',[[-244,1,96],[-244,1,116],[-250,1,116],[-250,1,123]])],
        [[-253,1,119],[-253,1,123],[-253,1,127],[-247,1,123]],
        [([-250,1,123],[-217,1,123]),([-247,1,123],[-244,1,96])],[-255,4,123],[-231,6,123])

    g='R02_Archive'
    portal(g,'Z',-84,-250,-230,15,-242,-236)
    portal(g,'X',-234,-148,-84,15,-115,-109)
    for a in (-145,-135,-125):
        m.box(g,'RecordCabinet',(a,a+7,-248.8,-246.8),15,22.8,'olive','Metal')
        for y in (16,18,20):
            m.box(g,'FileDrawer',(a+.2,a+6.8,-246.8,-246.65),y,y+1.35,'steel','Metal',physical=False)
    m.box(g,'SortingCounter',(-118,-110,-247,-244),15,18.2,'wood','Wood')
    m.sign(g,-130,24,-249.2,'02 / ARQUIVO MORTO',width=26,face=2)
    m.lamp(g,-126,26,-240,range_=35)
    record(2,'Arquivo morto',g,[-148,-76,-250,-230],15,[-132,15,-239],
        [('R02 corredor',[[-68,15,-239],[-132,15,-239]]),
         ('R02 servico',[[-112,15,-224],[-112,15,-239],[-132,15,-239]])],
        [[-136,15,-242],[-130,15,-242],[-136,15,-238],[-130,15,-238]],
        [([-132,15,-239],[-80,15,-239]),([-112,15,-239],[-112,15,-228])],[-140,18,-239],[-84,20,-239])

    g='R10_ReceivingOffice'
    portal(g,'X',74,-112,-60,1,-85,-79)
    portal(g,'Z',-60,74,104,1,86,92)
    m.wall(g,'MasonryBack','Z',-112,74,104,1,11.4,color='brick',material='Brick',thick=.5)
    m.wall(g,'DispatchCounterWindow','X',104,-112,-60,1,11.4,
           [(-106,-90,4.5,9.5,'firePort')],color='brick',material='Brick',thick=.5)
    m.box(g,'OfficeCeiling',(-112,-60,74,104),11.4,12,'aged')
    m.box(g,'DispatchCounter',(-106,-90,102,103.8),1,4.2,'wood','WoodPlanks')
    m.box(g,'CounterSteelEdge',(-106,-90,101.9,102.15),4.1,4.4,'steel','Metal',physical=False)
    m.box(g,'CheckingDesk',(-104,-94,80,83),1,4.3,'wood','WoodPlanks')
    m.box(g,'DispatchBoard',(-111.7,-111.5,79,87),5,9,'dark','Metal',physical=False)
    m.sign(g,-98,10,103.65,'10 / EXPEDIÇÃO',width=16)
    m.lamp(g,-96,10.8,92,range_=28)
    record(10,'Posto de expedicao',g,[-112,-60,74,104],1,[-98,1,95],
        [('R10 carga',[[-82,0,58],[-82,1,78],[-82,1,94],[-98,1,94],[-98,1,95]]),
         ('R10 producao',[[-48,1,94],[-54,1,89],[-98,1,89],[-98,1,95]])],
        [[-101,1,94],[-97,1,94],[-101,1,98],[-97,1,98]],
        [([-98,1,95],[-82,1,70]),([-98,1,97],[-98,1,118])],[-99,4,95],[-82,6,74])

    g='R14_ContainerPost'
    portal(g,'Z',-64,-89,-75,13,-85,-79)
    # Two shipping modules now form a continuous upper room. The second stair is
    # supported at both ends and joins the open east end through a loading landing.
    m.stair(g,'EastContainerStair',-20,-120,'Z',1,10,32,12,1,24)
    m.box(g,'StairFooting',(-26,-14,-122,-118),0,1)
    m.box(g,'LoadingLanding',(-34,-14,-88,-76),12.4,13,'steel','DiamondPlate')
    for x in (-33,-15):m.box(g,'LandingColumn',(x-.2,x+.2,-77,-76.6),0,12.4,'steel','Metal')
    m.rail(g,(-32,-76),(-14,-76),13)
    m.box(g,'SecuredCargo',(-51,-49,-88,-85),13,16.3,'wood','WoodPlanks')
    m.sign(g,-49,21,-88.65,'14 / CARGA RETIDA',width=22,face=2)
    m.lamp(g,-50,23.5,-82,range_=30)
    record(14,'Conteiner de carga retida',g,[-96,-32,-89,-75],13,[-56,13,-82],
        [('R14 oeste',[[-142,0,-82],[-136,1,-82],[-104,13,-82],[-56,13,-82]]),
         ('R14 leste',[[-20,1,-122],[-20,1,-120],[-20,13,-88],[-20,13,-82],[-56,13,-82]])],
        [[-62,13,-84],[-57,13,-84],[-62,13,-80],[-57,13,-80]],
        [([-56,13,-82],[-100,13,-82]),([-56,13,-82],[-25,13,-82])],[-60,16,-82],[-32,18,-82])

    g='R15_PumpBay'
    portal(g,'Z',-94,134,164,-24,141,147)
    portal(g,'Z',-42,122,154,-24,141,147)
    m.box(g,'OperatorBay',(-88,-50,151,163),-24,-22.5,'concrete')
    for x in (-82,-56):m.stair(g,'BaySteps',x,145,'Z',1,6,6,1.5,-24,3)
    for a,b in [(-88,-85.5),(-78.5,-59.5),(-52.5,-50)]:m.rail(g,(a,151),(b,151),-22.5)
    for x in (-82,-68,-54):
        m.box(g,'PumpPlinth',(x-3,x+3,125,132),-24,-23.4,'concrete')
        m.box(g,'PumpMotor',(x-2,x+2,126,131),-23.4,-19,'olive','Metal')
        m.pipe(g,(x,-20,131),(x,-20,136),.9)
    m.sign(g,-69,-15.8,163.35,'15 / CONTROLE DAS BOMBAS',width=30)
    record(15,'Baia de controle das bombas',g,[-100,-36,122,164],-22.5,[-70,-22.5,158],
        [('R15 oeste',[[-108,-24,144],[-82,-24,144],[-82,-24,145],[-82,-22.5,151],[-82,-22.5,158],[-70,-22.5,158]]),
         ('R15 leste',[[-28,-24,144],[-56,-24,144],[-56,-24,145],[-56,-22.5,151],[-56,-22.5,155],[-70,-22.5,158]])],
        [[-80,-22.5,158],[-74,-22.5,158],[-68,-22.5,158],[-62,-22.5,158]],
        [([-70,-22.5,158],[-96,-24,144]),([-70,-22.5,158],[-40,-24,144])],[-70,-19.5,158],[-94,-18.5,144])
    m.refuges=data
