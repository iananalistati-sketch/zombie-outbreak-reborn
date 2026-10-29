# Rifle do Roblox Weapons Kit no K-17

> Registro da integração inicial da AR. O helper e o pacote de apresentação
> exclusivos foram substituídos pelo [pacote FPS genérico](FPS_COMBAT_PACKAGE.md).
> As instruções e atributos antigos abaixo descrevem aquela versão.

A carabina inicial (`Rifle`) agora usa a **AR real do Roblox Weapons Kit**:
meshes de rifle, carregador e ferrolho, sons de disparo/recarga, muzzle flash e
animações R15. A submetralhadora, escopeta, metralhadora e pistola continuam com
os modelos procedurais anteriores.

O componente veio do [Roblox Weapon Kit Fix, de JustATortoise](https://github.com/JustAT0rtoise/Roblox-Weapon-Kit-Fix/tree/72229de581a9c38272b10e4353804c80ac0c6379).
O arquivo original, revisão, SHA-256 e licenças estão em
[third_party/roblox-weapon-kit](../third_party/roblox-weapon-kit/ATTRIBUTION.md).
O kit completo está arquivado para revisão; seus scripts não entram no perfil
de execução. A extração usada pelo jogo contém somente apresentação.

## O que foi integrado

- `ReplicatedStorage.ZO_ReusedWeaponKit`: AR original, animações e efeitos,
  sem scripts ou remotes externos.
- `ReusedRiflePresentation`: adapta trechos oficiais de `BaseWeapon` e
  `BulletWeapon` para weld do modelo, sons, tween do ferrolho e muzzle flash.
- `EquipmentVisuals`: equipa o modelo corporal `ZO_EquippedRifle` e reproduz
  as animações R15 de postura/recarga para os observadores.
- `Weapons`: mostra uma cópia da AR em primeira pessoa e despacha os efeitos.

Inventário, munição, cadência, acertos, dano, knockback e barricadas continuam
sob o controlador existente do K-17. Não foi ativado um segundo sistema de
combate nem a câmera sobre o ombro do kit completo. As animações importadas não
oferecem suporte R6; nesse rig permanece o modelo sem essas animações.

## Conferir no Studio

1. No GitHub Desktop, atualize a `main` com **Fetch origin → Pull origin**.
   Salve o place atual e abra **ABRIR_K17.cmd**. O Pull não troca um place aberto.
2. Inicie **Server & Clients** com dois jogadores. Durante a preparação,
   confira a AR inicial em primeira pessoa e nas mãos do outro humano.
3. Dispare e use **R** para recarregar. Confira som, flash, ferrolho e a
   animação vista pelo outro jogador. Use **2**, depois **1** ou **Q**: a troca
   deve cancelar a recarga e preservar a munição já controlada pelo servidor.
4. Abra **B** ou **M**: a arma em primeira pessoa deve sair da frente do menu.
   Morra ou seja infectado: a AR corporal também deve desaparecer. Voltar à
   condição humana numa nova rodada deve restaurar sua apresentação.

No Output, procure mensagens `[K17]` sobre assets/animações. Para diagnóstico:

| Local | Atributo | Valores |
| --- | --- | --- |
| Jogador, contexto Client | `ZO_ReusedWeaponAssetsStatus` | `Loading`, `Ready`, `Failed` |
| Jogador, contexto Server | `ZO_RifleVisualStatus` | `Idle`, `Ready`, `AnimationUnavailable`, `NoR15Animation`, `Error` |
| Script `EquipmentVisuals`, contexto Server | `ZO_EquipmentVisualsReady` | `true` após configurar o adaptador |

O status de assets verifica o carregamento da AR no cliente; ele não comprova
permissões das animações, aparência ou funcionamento multiplayer. Os assets
continuam dependendo do serviço de conteúdo e das permissões Roblox.

As verificações de arquivo, licença, referências internas e compilação podem
rodar na nuvem. **Renderização, grip, animações, sons e permissões ainda precisam
ser conferidos no motor Roblox Studio.** Não há conexão desta nuvem com o Studio
local nem equivalência de gameplay com CS:GO/CS2 comprovada.
