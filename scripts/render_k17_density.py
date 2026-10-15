#!/usr/bin/env python3
"""Measured floor plans of all current defensive refuges; no engine rendering."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'docs/k17-navigation.json').read_text(encoding='utf-8'))
panels=[('TÉRREO',{1}),('SEGUNDO ANDAR',{15}),('TERCEIRO ANDAR',{29}),
        ('QUARTO ANDAR',{43}),('CONTÊINER ELEVADO',{13}),('SUBTERRÂNEO',{-24,-22.5})]
out=['<svg xmlns="http://www.w3.org/2000/svg" width="1300" height="2050" viewBox="0 0 1300 2050">',
     '<rect width="1300" height="2050" fill="#142025"/>',
     '<style>text{font-family:sans-serif;fill:#e3e8db}.label{font-size:12px}.number{font-size:11px;fill:#142025;font-weight:bold}</style>',
     '<text x="36" y="40" font-size="25">K-17 / 34 REFÚGIOS · 164 OBJETOS DE BARRICADA</text>',
     '<text x="36" y="65" font-size="14">Geometria medida: posições separadas por piso. Não é captura do Roblox Studio.</text>']
for index,(title,levels) in enumerate(panels):
    x,y=30+(index%2)*640,90+(index//2)*640
    refuges=[r for r in data['refuges'] if r['floor'] in levels]
    count=sum(p['Y'] in levels for p in data['barricades'].values())
    out.append(f'<g transform="translate({x},{y})"><rect width="620" height="620" rx="12" fill="#213036"/>')
    out.append(f'<text x="16" y="28" font-size="18">{title} / {len(refuges)} refúgios · {count} objetos</text>')
    out.append('<g transform="translate(30,55) scale(.91)"><rect width="600" height="600" fill="#33443f" stroke="#789186"/>')
    if -24 in levels:
        for a,b,c,d in data['underground']:
            out.append(f'<rect x="{a+300}" y="{c+300}" width="{b-a}" height="{d-c}" fill="#526f7a"/>')
    else:
        for bld in data['buildings']:
            a,b,c,d=bld['rect']
            out.append(f'<rect x="{a+300}" y="{c+300}" width="{b-a}" height="{d-c}" fill="#716f58" stroke="#a6a58a"/>')
    for r in refuges:
        a,b,c,d=r['bounds'];px,_,pz=r['hold']
        color='#a7c4e9' if -24 in levels else '#e5c477' if min(levels)>1 else '#99d0b2'
        out.append(f'<rect x="{a+300}" y="{c+300}" width="{b-a}" height="{d-c}" fill="{color}" fill-opacity=".3" stroke="{color}"/>')
        out.append(f'<circle cx="{px+300}" cy="{pz+300}" r="9" fill="{color}"/><text class="number" x="{px+300}" y="{pz+304}" text-anchor="middle">{r["id"]}</text>')
    out.append('</g></g>')
out.append('<text x="36" y="2030" font-size="15">No jogo: M abre o mapa tático com nomes, andares e objetos por refúgio. Os números identificam as posições.</text></svg>')
target=ROOT/'docs/K17_DEFENSE_DENSITY.svg';target.write_text('\n'.join(out)+'\n',encoding='utf-8');print(target)
