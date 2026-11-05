# Extract — origem da adaptação de movimento

Projeto original: [voximity/extract](https://github.com/voximity/extract), revisão
[`45afa80c93eeb8f4b21a84bab8a4b14a30ff33cc`](https://github.com/voximity/extract/tree/45afa80c93eeb8f4b21a84bab8a4b14a30ff33cc).
Licença: **MIT, Copyright (c) 2019 voximity**, preservada integralmente em
[LICENSE](LICENSE).

As fontes originais foram arquivadas sem alterações para revisão:

- `Client/Character.lua` → [source/Character.lua](source/Character.lua).
- `Server/Weapons.lua` → [source/Weapons.lua](source/Weapons.lua).
- `Client/Weapons.lua` → [source/ClientWeapons.lua](source/ClientWeapons.lua).

[SOURCE.json](SOURCE.json) registra a origem, revisão e SHA-256 de cada arquivo
e da licença. Esses arquivos de referência ficam fora do perfil de execução.

No K-17, `Movement.client.luau` adapta a seleção de estados de movimento e a
interpolação do deslocamento da câmera ao agachar de `Client/Character.lua`.
`MovementPose.luau` adapta o padrão de deslocamento do torso/quadris presente em
`prepareTorsoWeld` e na interpolação de agachamento de `Server/Weapons.lua`.
A integração usa os Motor6Ds existentes dos rigs R6/R15 e estados aprovados pelo
servidor; não importa o controlador de personagem completo do projeto original.

`WeaponMotion.luau` adapta os senos do balanço da arma ao caminhar/correr, a
interpolação entre faixas de velocidade e a suavização da oscilação do mouse de
`Client/Weapons.lua` (bloco de apresentação nas linhas 1460–1565). O K-17 reduz
as amplitudes, suaviza pelo tempo de quadro, normaliza o delta do mouse e
estabiliza a arma ao mirar/agachar. O módulo retorna apenas um deslocamento
local do modelo da arma; não escreve câmera, FOV, movimento ou direção de tiro.

Os sistemas upstream de armas/dano/rede, câmera, inventário e rodadas não são
ativados. Não foram importados os assets ausentes do upstream. As alterações de
integração e a composição com as regras Zombie pertencem ao K-17.

A reutilização de código e a compilação não comprovam postura, câmera, colisões
ou sincronização no motor Roblox. A validação real no Studio continua pendente.
