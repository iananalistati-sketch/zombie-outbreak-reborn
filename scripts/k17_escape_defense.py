"""Retention doors, coherent generator cover and signs for the measured ZE path."""
import copy
import xml.etree.ElementTree as ET


def build_escape_defense(m,config):
    g='EscapeHoldGates'
    for data in config['HoldGates']:
        a,b=data['Min'],data['Max']
        gate=m.box(g,data['Name'],(a[0],b[0],a[2],b[2]),a[1],b[1],'steel','Metal',physical=False,alpha=1)
        # Lettering is part of the door and is enabled only when it is closed.
        sign=m.sign(g,(a[0]+b[0])/2,(a[1]+b[1])/2,(a[2]+b[2])/2,
                    'RETENÇÃO / DEFENDA OS FLANCOS',width=b[0]-a[0],color='yellow')
        gui=sign.find('Item')
        gui.find('Properties/Vector2[@name="CanvasSize"]/Y').text=str(1024*(b[1]-a[1])/(b[0]-a[0]))
        label=gui.find('Item/Properties')
        label.find('UDim2[@name="Size"]/YS').text='.18'
        pos=ET.SubElement(label,'UDim2',name='Position')
        for key,value in [('XS',0),('XO',0),('YS',.41),('YO',0)]:ET.SubElement(pos,key).text=str(value)
        gate.append(gui)
        reverse=copy.deepcopy(gui);reverse.find('Properties/token[@name="Face"]').text='2';gate.append(reverse)
        for surface in gate.findall('Item'):m.prop(surface.find('Properties'),'bool','Enabled',False)
        m.group(g).remove(sign);m.parts-=1
        for x in (a[0]-.2,b[0]+.2):
            m.box(g,'RetentionFramePost',(x-.2,x+.2,a[2]-.2,b[2]+.2),a[1],b[1]+.4,'steel','Metal',physical=False)
        m.box(g,'RetentionHeader',(a[0]-.4,b[0]+.4,a[2]-.2,b[2]+.2),b[1],b[1]+.5,'steel','Metal',physical=False)

    g='R51_GeneratorHold'
    m.sign(g,132,8,-229.4,'51 / DEFESA DO GERADOR',width=14,face=2,color='blue')
    hold=[130,1,-220];approach=[[144,1,-224],[144,1,-220],hold]
    m.route('R51 generator defense approach',approach,'refuge')
    m.refuges.append(dict(id=51,label='Defesa do gerador',model=g,bounds=[126,168,-230,-208],floor=1,hold=hold,
        approaches=[('R51 generator defense approach',approach)],stands=[[130,1,-220],[130,1,-216]],capacity=2,
        sights=[([144,1,-220],[144,1,-200])],view=[130,4,-220],look=[144,6,-210],hidden=[hold,[144,1,-210]],
        style='Defesa de objetivo',props=[('Cabinet',136,1,-215),('Cabinet',156,1,-215),('Crate',130,1,-210),
            ('Table',156,1,-221),('Crate',164,1,-215)]))

    g='EscapeRouteSigns'
    # A supported entrance frame at the north shaft; remaining plaques mount on
    # the real retaining walls so there are no floating guide boards.
    for x in (22,38):m.box(g,'DescentSignPost',(x-.12,x+.12,-60.2,-59.8),0,8.6,'steel','Metal',physical=False)
    m.box(g,'DescentSignBeam',(22,38,-60.2,-59.8),8.4,8.6,'steel','Metal',physical=False)
    m.sign(g,30,7,-59.6,'DESCIDA / BOMBAS - ZE 2',width=16,face=2,color='blue')
    sign=m.sign(g,-229.6,-16.5,-212,'ANEL DE MANUTENÇÃO / SIGA PARA BOMBAS',width=18,face=2,color='blue')
    cf=sign.find('Properties/CoordinateFrame')
    for key,value in {'R00':0,'R02':1,'R20':-1,'R22':0}.items():cf.find(key).text=str(value)
    m.sign(g,-108,-16,153.6,'BOMBAS / VIGIE OS ACESSOS',width=24,color='blue')
    m.sign(g,140,-16.5,187.6,'SUBIDA LESTE / EXTRAÇÃO',width=18,color='blue')
