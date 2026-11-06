# Fontes dos componentes FPS táticos

Este pacote preserva fontes reais e suas licenças para três adaptações limitadas
do K-17. Os arquivos em `source/` são cópias exatas, inertes, fora do perfil Rojo.
[SOURCE.json](SOURCE.json) registra repositórios, revisões, tamanhos e SHA-256 dos
originais e das licenças. A licença do projeto não foi alterada.

## Movimento — UnitySourceMovement

Origem: [Olezen/UnitySourceMovement](https://github.com/Olezen/UnitySourceMovement/tree/726e98f5f50ebb28aba2f6444808ec8ff0021532),
revisão `726e98f5f50ebb28aba2f6444808ec8ff0021532`.
**MIT, Copyright (c) 2019 Ole Ellefsen Farner**;
[licença integral](unity-source-movement/LICENSE).

- [SurfPhysics.cs](unity-source-movement/source/SurfPhysics.cs): fricção com
  velocidade de parada, aceleração pela projeção na direção desejada e
  aceleração aérea limitada.
- [SurfController.cs](unity-source-movement/source/SurfController.cs): composição
  da velocidade desejada e separação entre entrada no chão e no ar.

[SourceMovement.luau](../../src/maps/k17/gameplay/SourceMovement.luau) porta esse
núcleo matemático de C# para Luau. O adaptador
[SourceMotor.client.luau](../../src/maps/k17/gameplay/SourceMotor.client.luau)
integra o cálculo ao personagem Roblox e às regras existentes do K-17. Não são
importados o controlador Unity completo, seu resolvedor de colisões, escadas,
natação, deslize, cenas ou assets.

## Recuo — CIA-SAC-ACS

Origem: [jasonconba/CIA-SAC-ACS](https://github.com/jasonconba/CIA-SAC-ACS/tree/678d94f104f06589c652b5b6b62020837b5ea74c),
revisão `678d94f104f06589c652b5b6b62020837b5ea74c`.
**Apache License 2.0**; [licença integral](acs/License.txt).
Não foi localizado arquivo `NOTICE` na raiz dessa revisão.

[TacticalRecoil.luau](../../src/maps/k17/gameplay/TacticalRecoil.luau) adapta a
aritmética de recuo vertical da câmera e seleção horizontal com sinal de
[Recoil.lua](acs/source/Recoil.lua). A adaptação substitui os estados globais,
dependências e amostragem upstream por ajuste determinístico por arma e estado
do K-17. Esses ajustes pertencem ao K-17; não são padrões de spray copiados do
Evostrike. [Weapons.client.luau](../../src/maps/k17/gameplay/Weapons.client.luau)
consome o módulo dentro do controlador de armas existente.

O original completo fica arquivado para revisão. Não são ativados o motor ACS,
seu módulo Spring, recuo do viewmodel, roll, bipé, contraimpulso atrasado,
inventário, remotes, dano ou dependências de pacotes.

## Mola escalar — spr de Fractality

Origem arquivada: [c_spr.lua no Evostrike](https://github.com/beters02/Evostrike/blob/221a3a2f67451145b94836b794c0df072c6a28ee/src/shared/lib/c_spr.lua),
revisão `221a3a2f67451145b94836b794c0df072c6a28ee`.
O próprio [arquivo](spr/source/c_spr.lua) declara **Copyright (c) 2023 Fractality**
e **MIT**, com ligação à biblioteca original [Fraktality/spr](https://github.com/Fraktality/spr).
A [licença MIT integral](spr/LICENSE) foi obtida desse repositório; o blob Git
`80dc9a3e54325ad5fd6d2bad4a3c876b9bed76e3` foi conferido contra o conteúdo
decodificado da [resposta da API preservada](spr/license-api.json).

[TacticalSpring.luau](../../src/maps/k17/gameplay/TacticalSpring.luau) adapta
somente a atualização analítica escalar de posição/velocidade do ramo
`LinearSpring.step` com amortecimento crítico (`d == 1`).
[WeaponMotion.luau](../../src/maps/k17/gameplay/WeaponMotion.luau) usa esse cálculo
para suavizar a apresentação da arma. Não são importados o agendador de
propriedades de Instances, conversões de tipos, molas de rotação ou os outros
ramos de amortecimento.

O Evostrike completo tem licença GPLv2. A reutilização aqui se limita à
biblioteca de terceiro explicitamente marcada MIT no próprio arquivo. Nenhum
controlador ou outro código GPL-only do motor Evostrike é integrado, e seus
assets não são copiados. A decisão de licença se baseia nessa declaração do
arquivo e na licença original preservada, não na localização das pastas.

A preservação dos fontes e os testes fora do motor não comprovam câmera,
colisões, controles ou multiplayer no Roblox Studio.
