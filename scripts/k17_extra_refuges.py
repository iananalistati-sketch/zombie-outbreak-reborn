"""Sixteen authored defensive rooms in the occupied K-17 buildings.

Room portals stay beside the main circulation spine. An inner return wall breaks
entry sight lines; the intact floor above closes every room. These edits reuse
existing rooms rather than adding disconnected bunkers to the yard.
"""

CENTERS={'A_Administration':-68,'B_PowerStation':144,'D_Warehouse':-217,'T_ControlTower':210}
STYLES={
    'Reception':'Recepção com entrada em L', 'ServerVault':'Sala de servidores recuada',
    'FirstAid':'Ambulatório com biombo', 'ProjectionBooth':'Cabine com anteparo',
    'ArchiveStacks':'Arquivo com estantes profundas', 'ManagementSafe':'Sala de gerência com cofre',
    'ElectricalStores':'Peças com corredores entre estantes', 'MaintenanceShop':'Oficina com bancada de máquinas',
    'NetworkControl':'Controle com racks', 'SwitchgearControl':'Posto de chaves protegido',
    'PartsPicking':'Célula de separação em L', 'PackingCell':'Célula de embalagem em L',
    'UpperToolroom':'Ferramentaria em andar alto', 'WarehouseWatch':'Vigia com anteparo',
    'RadioPost':'Posto elevado de rádio', 'InstrumentPost':'Posto elevado de instrumentos',
}


def overrides_room(name,level,a,begin):
    """Skip the generic bench/shelf/suite-divider pass in authored rooms only."""
    if name in ('A_Administration','B_PowerStation'):
        return begin==-174
    if name=='D_Warehouse':
        return (level==0 and begin==8) or (level==1 and begin==54)
    if name=='T_ControlTower' and begin==-35:
        return (level==2 and a<210) or (level==3 and a>210)
    return False


def build_extra_refuges(m):
    data=[]

    def record(id_,label,model,bounds,floor,hold,approaches,stands,sights,view,look,hidden,style,props):
        item=dict(id=id_,label=label,model=model,bounds=bounds,floor=floor,hold=hold,
                  approaches=approaches,stands=stands,sights=sights,view=view,look=look,
                  hidden=hidden,style=STYLES[style],props=props,entryCount=1,
                  retreat='Acesso único: se a porta cair, o grupo precisa abrir caminho para sair.')
        data.append(item)
        for name,points in approaches:m.route(name,points,'refuge')

    def pocket(id_,label,building,level,west,begin,end,style):
        cx=CENTERS[building]
        rect=next(b['rect'] for b in m.buildings if b['name']==building)
        a,b=(rect[0]+.5,cx-8.3) if west else (cx+8.3,rect[1]-.5)
        x0,x1=a+1,b-1;back=begin+1;front=begin+18
        y=1+14*level;g=f'R{id_:02d}_{style}'
        width=x1-x0
        def x(u):return x0+u if west else x1-u
        def box(name,u0,u1,z0,z1,lo,hi,color='steel',mat='Metal',physical=True):
            xa,xb=sorted((x(u0),x(u1)))
            return m.box(g,name,(xa,xb,z0,z1),y+lo,y+hi,color,mat,physical=physical)
        door=x(width-9);holdx=x(9)
        m.wall(g,'RecessedEntry','X',front,x0,x1,y,y+10.8,
               [(door-3,door+3,y,y+9,'refugeDoor')],color='plaster',thick=.5)
        # Closed rear wall prevents the old rear-room opening becoming a second
        # wide entrance. The original inter-room circulation remains outside it.
        m.wall(g,'SecureRear','X',back,x0,x1,y,y+10.8,color='aged',thick=.5)
        for fixed in (x0,x1):
            m.wall(g,'SideReturn','Z',fixed,back,front,y,y+10.8,color='plaster',thick=.5)
        m.box(g,'LowServiceCeiling',(x0,x1,back,front),y+10.8,y+11.3,'aged')
        box('SightlineReturn',width-17.3,width-16.7,back,begin+12,0,10.8,'brick','Brick')
        # A low service counter is usable cover along the outside wall. It leaves
        # a clear four-person bay and the entire dogleg approach at front-3.
        box('WallWorkCounter',.4,2.4,begin+7,begin+14,0,3.3,'wood','WoodPlanks')
        box('CounterMetalEdge',.35,2.6,begin+7,begin+14,3.2,3.5,'steel',physical=False)
        box('EmergencyStrip',3,width-3,front-.8,front-.5,9.7,9.95,'light','Neon',False)
        # Centre-room equipment changes the silhouette and gives additional
        # concealment without obstructing circulation or movable prop homes.
        if width>55:
            if style in ('ServerVault','NetworkControl'):
                for u in (27,33,39):box('CommunicationsRack',u,u+4,begin+2,begin+8,0,7.8,'dark')
            elif style in ('ArchiveStacks','ElectricalStores'):
                for u in (26,34,42):
                    box('DeepArchiveShelf',u,u+1.3,begin+2,begin+9,0,7.8,'olive')
                    for h in (2,4,6):box('ShelfContents',u+1.3,u+3.4,begin+2.5,begin+8.5,h,h+1.1,'wood','Wood',False)
            elif style=='FirstAid':
                box('TreatmentBed',26,35,begin+3,begin+8,0,2.7,'white','SmoothPlastic')
                box('PrivacyScreen',38,38.4,begin+2,begin+10,0,7.5,'blue','SmoothPlastic')
            elif style=='ProjectionBooth':
                box('ProjectionConsole',26,38,begin+3,begin+7,0,3.7,'steel')
                box('ProjectorScreen',24,42,back+.3,back+.55,3.6,8.8,'white','SmoothPlastic',False)
            elif style=='MaintenanceShop':
                box('MachineBench',26,40,begin+3,begin+8,0,3.6,'olive')
                for u in (28,34,38):box('MachineHousing',u,u+2,begin+4,begin+7,3.6,6,'steel')
            elif style=='SwitchgearControl':
                box('ProtectedSwitchgear',26,42,begin+2,begin+6,0,7.8,'olive')
                for u in (28,33,38):box('SwitchLabel',u,u+2.7,begin+6,begin+6.12,4.8,6,'yellow','SmoothPlastic',False)
            elif style=='ManagementSafe':
                box('MeetingTable',27,39,begin+3,begin+8,0,3.3,'wood','Wood')
                box('ConcreteSafe',42,48,begin+2,begin+8,0,7,'dark')
            else:
                box('ReceptionCounter',26,42,begin+3,begin+7,0,4.1,'wood','WoodPlanks')
                box('ServiceScreen',38,38.4,begin+2,begin+10,4.1,8,'steel')
        else:
            # The warehouse has narrow rooms: vertical equipment adds identity
            # while keeping the usable floor free for actual movable barricades.
            box('ToolDisplay',.35,.55,begin+3,begin+6,4,8,'dark',physical=False)
            box('VerticalDuct',width-2.2,width-1.2,back+.5,back+2,0,10.8,'steel',physical=False)
        m.sign(g,(x0+x1)/2,y+9.9,front+.32,f'{id_:02d} / {label.upper()}',width=min(width-3,44))
        mid=(begin+end)/2
        hold=[holdx,y,begin+10]
        approach=[[cx,y,mid],[door,y,mid],[door,y,front-3],[holdx,y,front-3],hold]
        stands=[[x(u),y,begin+z] for u,z in ((7,8),(11,8),(7,12),(11,12))]
        sights=[([door,y,front-3],[door,y,front+5]),([door,y,front-6],[door,y,front+8])]
        # These are only homes: the runtime allows the objects to leave the room.
        props=[(kind,x(u),y,begin+3.5) for kind,u in
               [('Cabinet',4),('Table',10),('Crate',16),('Cabinet',width-5),('Crate',width-11)]]
        record(id_,label,g,[x0,x1,back,front],y,hold,[(f'R{id_:02d} acesso protegido',approach)],stands,sights,
               [holdx,y+3,begin+10],[door,y+5,front],(hold,[cx,y,mid]),style,props)

    rooms=[
        (19,'Recepcao protegida','A_Administration',0,True,-174,-126,'Reception'),
        (20,'Almoxarifado de TI','A_Administration',0,False,-174,-126,'ServerVault'),
        (21,'Ambulatorio','A_Administration',1,True,-174,-126,'FirstAid'),
        (22,'Cabine de projecao','A_Administration',1,False,-174,-126,'ProjectionBooth'),
        (23,'Arquivo contabil','A_Administration',2,True,-174,-126,'ArchiveStacks'),
        (24,'Gerencia recuada','A_Administration',2,False,-174,-126,'ManagementSafe'),
        (25,'Pecas eletricas','B_PowerStation',0,True,-174,-126,'ElectricalStores'),
        (26,'Oficina eletrica','B_PowerStation',0,False,-174,-126,'MaintenanceShop'),
        (27,'Controle de redes','B_PowerStation',1,True,-174,-126,'NetworkControl'),
        (28,'Operacao de chaves','B_PowerStation',1,False,-174,-126,'SwitchgearControl'),
        (29,'Picking de pecas','D_Warehouse',0,True,8,54,'PartsPicking'),
        (30,'Embalagem rapida','D_Warehouse',0,False,8,54,'PackingCell'),
        (31,'Ferramentaria alta','D_Warehouse',1,True,54,100,'UpperToolroom'),
        (32,'Vigia do deposito','D_Warehouse',1,False,54,100,'WarehouseWatch'),
    ]
    for args in rooms:pocket(*args)

    def tower(id_,label,level,west,style):
        y=1+14*level;g=f'R{id_:02d}_{style}';cx=210
        x0,x1=(173.5,200.7) if west else (219.3,246.5)
        width=x1-x0
        def x(u):return x0+u if west else x1-u
        def box(name,u0,u1,z0,z1,lo,hi,color='steel',physical=True):
            xa,xb=sorted((x(u0),x(u1)))
            return m.box(g,name,(xa,xb,z0,z1),y+lo,y+hi,color,'Metal',physical=physical)
        # A side-entry control cell, with a second return hiding the operator bay.
        doorwall=x(width-8)
        m.wall(g,'ControlCellEntry','Z',doorwall,-35,-17,y,y+10.8,
               [(-28,-22,y,y+9,'refugeDoor')],color='plaster',thick=.5)
        for zz in (-35,-17):m.wall(g,'ControlCellEnd','X',zz,x0,x1,y,y+10.8,color='aged',thick=.5)
        outer=x0 if west else x1;inner=x1 if west else x0
        m.wall(g,'OuterControlSide','Z',outer,-35,-17,y,y+10.8,color='plaster',thick=.5)
        m.wall(g,'SpineVestibule','Z',inner,-35,-17,y,y+10.8,
               [(-28,-22,y,y+9,'refugeDoor')],color='plaster',thick=.5)
        m.box(g,'ControlCeiling',(x0,x1,-35,-17),y+10.8,y+11.3,'aged')
        box('OperatorReturn',11.7,12.3,-35,-28,0,10.8,'brick')
        box('InstrumentCounter',.5,2.5,-33,-20,0,3.3,'olive')
        box('AnalogPanel',.25,.5,-31,-27,4,8,'dark',False)
        box('StatusStrip',.4,.65,-25,-20,8.5,8.8,'light',False)
        hold=[x(7),y,-30]
        approach=[[cx,y,-25],[x(width-4),y,-25],[x(7),y,-25],hold]
        stands=[[x(u),y,z] for u,z in ((5,-31),(9,-31),(5,-27),(9,-27))]
        props=[(k,x(u),y,z) for k,u,z in
               [('Cabinet',16,-32.5),('Crate',22,-32.5),('Crate',16,-19.5),('Crate',22,-19.5),('Table',7,-19.5)]]
        m.sign(g,(x0+x1)/2,y+10,-17.35,f'{id_:02d} / {label.upper()}',width=24)
        record(id_,label,g,[x0,x1,-35,-17],y,hold,[(f'R{id_:02d} posto alto',approach)],stands,
               [([x(17),y,-25],[cx,y,-25]),([x(14),y,-25],[cx,y,-25])],
               [x(7),y+3,-30],[doorwall,y+5,-25],(hold,[cx,y,-25]),style,props)

    tower(33,'Radio da torre',2,True,'RadioPost')
    tower(34,'Instrumentos da torre',3,False,'InstrumentPost')
    return data
