"""Small two-person recesses below the high ends of existing stair flights."""


def build_stair_niches(m):
    records=[]
    for id_,cx,label in ((48,-132,'Recuo sob escada da administracao'),(49,232,'Recuo sob escada da energia')):
        g=f'R{id_}_UnderStair'
        x0,x1=cx-6,cx+6
        m.box(g,'LowProtectionRoof',(x0,x1,-199,-187),8.5,8.8,'steel','Metal')
        for z in (-199,-187):m.box(g,'StairRecessEnd',(x0,x1,z-.2,z+.2),1,8.5,'aged')
        m.box(g,'StairRecessBack',(x0-.2,x0+.2,-199,-187),1,8.5,'aged')
        m.wall(g,'LowEntry','Z',x1,-199,-187,1,8.5,
               [(-197,-191,1,8.2,'alcoveDoor')],color='steel',material='Metal',thick=.4)
        m.box(g,'InnerReturn',(cx+.8,cx+1.2,-199,-195.5),1,8.5,'brick','Brick')
        m.sign(g,cx,7.4,-186.65,f'{id_} / RECUO SOB ESCADA',width=11)
        hold=[cx-3,1,-197]
        approach=[[cx+10,1,-193],[cx+3,1,-193],[cx-3,1,-193],hold]
        m.route(f'R{id_} acesso sob escada',approach,'refuge')
        records.append(dict(id=id_,label=label,model=g,bounds=[x0,x1,-199,-187],floor=1,hold=hold,
            approaches=[(f'R{id_} acesso sob escada',approach)],stands=[[cx-3,1,-197],[cx-3,1,-193]],
            sights=[([cx+3,1,-193],[cx+10,1,-193]),([cx+3,1,-194],[cx+10,1,-194])],
            view=[cx-3,4,-195],look=[cx+3,6,-193],hidden=[hold,[cx+10,1,-193]],
            style='Recuo sob escada',capacity=2,
            props=[('Crate',cx-2.5,1,-189.5),('Crate',cx+2.5,1,-189.5)]))
    return records
