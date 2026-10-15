"""Enclosed maintenance refuges and full-size bent ventilation passages."""


def build_shelters(m,record,boundary):
    def duct(name,rects,ports,path,hidden,floor=1):
        g='V_'+name
        m.slab(g,'DuctFloor',rects,floor+.06,thick=.25,color='steel',material='DiamondPlate')
        m.slab(g,'DuctRoof',rects,floor+8,thick=.3,color='steel',material='Metal')
        for axis,fixed,a,b in boundary(rects):
            holes=[(start,end,floor,floor+7.2,'ductPortal') for ax,fix,start,end in ports if ax==axis and fix==fixed]
            m.wall(g,'DuctWall',axis,fixed,a,b,floor,floor+7.7,holes,color='steel',material='Metal',thick=.35)
        m.route(name,path,'duct')
        m.ducts.append(dict(name=name,model=g,points=path,width=7.2,height=7.2,hidden=hidden))
        return g

    # A bent passage inside the warehouse, entered at either end. No fake grilles.
    duct('StockroomVent',[(-263,-252,105,113),(-263,-255,105,123)],
         [('Z',-252,105.4,112.6),('X',123,-262.6,-255.4)],
         [[-249,1,109],[-259,1,109],[-259,1,125]],
         [[-259,1,119],[-249,1,109]])

    def shell(g,rect,front,side,window=None):
        x0,x1,z0,z1=rect
        # Interior rooms reuse the continuous production slab. The yard needs a plinth.
        if g=='R17_YardWorkshop':m.box(g,'RefugeFloor',rect,.1,1,'concrete')
        m.box(g,'RefugeRoof',rect,11,11.5,'concrete')
        holes=[(*front,1,10,'refugeDoor')]
        if window:holes.append((*window,4.5,8,'firePort'))
        m.wall(g,'FrontWall','X',z0,x0,x1,1,11,holes,color='brick',material='Brick',thick=.6)
        m.wall(g,'BackWall','X',z1,x0,x1,1,11,color='brick',material='Brick',thick=.6)
        which,fixed,start,end=side
        for x in (x0,x1):
            m.wall(g,'SideWall','Z',x,z0,z1,1,11,
                   [(start,end,1,8.2,'ductPortal')] if which=='Z' and x==fixed else [],color='aged',thick=.6)
        # Local emissive fixtures use existing sector lights; no extra PointLights.
        m.box(g,'StripFixture',(x0+3,x1-3,z1-1.5,z1-1),9.8,10,'light','Neon',physical=False,shadow=False)

    g='R16_FilterRoom'
    shell(g,(-104,-66,172,202),(-86,-80),('Z',-66,192.4,199.6),(-101,-94))
    m.box(g,'EntryBaffle',(-88,-66,181.7,182.3),1,10.8,'plaster')
    m.box(g,'FilterBank',(-102,-99,184,188),1,7.5,'olive','Metal')
    m.box(g,'ServiceBench',(-87,-79,199,201),1,4.3,'wood','WoodPlanks')
    m.sign(g,-85,10,171.6,'16 / FILTROS · ACESSO TÉCNICO',width=28)
    duct('FilterVent',[(-66,-55,192,200),(-63,-55,192,212)],
         [('Z',-66,192.4,199.6),('X',212,-62.6,-55.4)],
         [[-69,1,196],[-59,1,196],[-59,1,215]],
         [[-69,1,196],[-59,1,215]])
    record(16,'Sala de filtros',g,[-104,-55,172,215],1,[-94,1,193],
        [('R16 porta',[[-83,1,167],[-83,1,177],[-94,1,177],[-94,1,193]]),
         ('R16 duto',[[-59,1,215],[-59,1,196],[-94,1,196],[-94,1,193]])],
        [[-97,1,191],[-93,1,191],[-97,1,195],[-93,1,195]],
        [([-83,1,177],[-83,1,167]),([-94,1,196],[-59,1,196])],[-95,4,193],[-94,6,177])

    g='R17_YardWorkshop'
    shell(g,(72,108,26,54),(96,102),('Z',108,42.4,49.6),(79,86))
    m.box(g,'EntryBaffle',(91.7,92.3,26,38),1,10.8,'plaster')
    m.box(g,'ToolBench',(74,83,50,52),1,4.3,'wood','WoodPlanks')
    m.box(g,'FusePanel',(72.35,72.6,37,43),4.5,8.5,'olive','Metal',physical=False)
    m.sign(g,90,10,25.6,'17 / OFICINA DO PÁTIO',width=28)
    duct('YardVent',[(108,120,42,50),(112,120,42,64)],
         [('Z',108,42.4,49.6),('X',64,112.4,119.6)],
         [[104,1,46],[116,1,46],[116,1,65]],
         [[104,1,46],[116,1,65]])
    m.box('V_YardVent','EntryStep',(111.8,120.2,64,66.5),0,.5,'steel','DiamondPlate')
    record(17,'Oficina do patio',g,[72,120,26,64],1,[84,1,43],
        [('R17 porta',[[99,.1,21],[99,1,34],[99,1,42],[84,1,42],[84,1,43]]),
         ('R17 duto',[[116,.1,65],[116,1,46],[84,1,46],[84,1,43]])],
        [[81,1,40],[85,1,40],[81,1,44],[85,1,44]],
        [([99,1,42],[99,.1,21]),([84,1,46],[116,1,46])],[84,4,43],[99,6,42])

    g='R18_CoolantRoom'
    shell(g,(50,92,194,218),(68,74),('Z',92,206.4,213.6),(54,61))
    m.box(g,'EntryBaffle',(69,92,203.7,204.3),1,10.8,'plaster')
    for x in (81,87):
        m.box(g,'CoolantTank',(x-1.5,x+1.5,197,201),1,7,'olive','Metal')
        m.pipe(g,(x,5,201),(x,5,203),.6)
    m.box(g,'OperatorDesk',(52,60,215,217),1,4.2,'wood','WoodPlanks')
    m.sign(g,71,10,193.6,'18 / REFRIGERAÇÃO',width=28)
    duct('CoolantVent',[(92,107,206,214),(99,107,190,214)],
         [('Z',92,206.4,213.6),('X',190,99.4,106.6)],
         [[89,1,210],[103,1,210],[103,1,187]],
         [[89,1,210],[103,1,187]])
    record(18,'Sala de refrigeracao',g,[50,107,190,218],1,[62,1,210],
        [('R18 porta',[[71,1,190],[71,1,199],[63,1,199],[63,1,210],[62,1,210]]),
         ('R18 duto',[[103,1,187],[103,1,210],[62,1,210]])],
        [[62,1,207],[66,1,207],[62,1,212],[66,1,212]],
        [([71,1,199],[71,1,190]),([66,1,210],[103,1,210])],[62,4,210],[63,6,199])
