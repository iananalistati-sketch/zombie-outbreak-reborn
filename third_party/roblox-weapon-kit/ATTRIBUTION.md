# Roblox Weapons Kit — origem e atribuição

**Kit original:** Roblox Corporation,
[Roblox Weapons Kit](https://create.roblox.com/docs/resources/weapons-kit).
O material original está sujeito à
[Roblox Limited Use License](ROBLOX-LIMITED-USE-LICENSE.md), que permite sua
incorporação e modificação para aplicações na plataforma Roblox nas condições
do texto preservado. Modelos, animações, áudio e código original **não são
relicenciados como MIT** por este projeto.

**Correções da distribuição:** Copyright (c) 2025 JustATortoise
(TortoiseNite / L_Moments),
[Roblox-Weapon-Kit-Fix](https://github.com/JustAT0rtoise/Roblox-Weapon-Kit-Fix).
As alterações desse autor usam a [licença MIT preservada](MIT-FIX-LICENSE.txt).

- Revisão: `72229de581a9c38272b10e4353804c80ac0c6379`.
- Arquivo arquivado: `RobloxWeaponKitFix_v1.1.4.rbxm`.
- SHA-256: `ae17731762be2382e1257c488d91e616333991f9fc12eeecb54597bc0c72fb73`.
- Manifesto verificável: [SOURCE.json](SOURCE.json).
- README original: [UPSTREAM-README.md](UPSTREAM-README.md).

O arquivo original contém o kit completo e suas fontes; ele é material de
revisão fora do perfil ativo. O runtime recebe somente a extração
`src/third_party/roblox-weapon-kit/Arsenal.rbxmx`, sem scripts ou remotes.

No K-17, `WeaponPresentation.luau` adapta trechos de `BaseWeapon` e
`BulletWeapon` para weld, reprodução de áudio, tween do ferrolho e muzzle flash.
`EquipmentVisuals.server.luau` adapta o weld e o cache de animações. Os comentários
de atribuição permanecem nesses arquivos. Posicionamento em primeira pessoa,
cancelamento e ligação aos estados do K-17 são adaptações locais.

`WeaponAimPose.luau` adapta de `BulletWeapon:onRenderStepped` a seleção da pose
na sequência de mira entre -80 e 80 graus. Aim/ADS são bancos de poses, não loops
de idle. A integração mantém a pose neutra em primeira e terceira pessoa; a
recarga continua avançando normalmente. A inclinação da câmera não é replicada
por esse adaptador. O conteúdo permanece sob as licenças acima.

O `HitSound` original de impacto (`1489924400`) foi excluído apenas da extração
ativa após o Studio informar que o asset está arquivado. As partículas de
impacto e os sons originais de tiro/recarga foram preservados, sem substituir
o som indisponível por um ID não verificado. O arquivo original continua intacto.

O recuo em `Weapons.client.luau` segue a composição do estado completo de recuo
de `ShoulderCamera:onRenderStep` do kit, com integração local antes/depois da
câmera padrão Roblox para remover o offset anterior e evitar acumulação.

Não são ativados o controlador de dano, a rede de acertos ou a câmera do kit
completo. A AR usa os assets originais de mesh, textura, áudio e animação; a
disponibilidade e as permissões desses assets devem ser verificadas no Studio.

O catálogo atual contém Rifle, SMG, Shotgun e Pistol. **Rifle e Pistol estão
empacotadas.** A pistola preta vem do modelo oficial `118912302094201`, obtido pelo
usuário no Toolbox e fornecido em `Pistolas_Oficiais.rbxl`. A Tool registra esse
SourceAssetId. A variante selecionada é `Workspace/Pistol2`; sua fonte completa
está em [pistol/OriginalPistol2.rbxmx](pistol/OriginalPistol2.rbxmx), fora do perfil
ativo. Hashes, sons e origem estão em [SOURCE.json](SOURCE.json).

A pistola usa a **Roblox Limited Use License** do kit oficial. As correções MIT
do fork separado não são atribuídas aos novos assets. Sua pasta `WeaponsSystem`
com os 16 scripts originais foi revista e excluída da extração ativa, junto de
remotes, tags sem consumidor e efeitos arquivados. Malhas, texturas, grip,
ferrolho, flash e áudio originais foram preservados. As mesmas animações de
RifleAim/ADS/Reload já presentes são as usadas pelo próprio kit da pistola.

SMG e Shotgun ainda não estão embutidas. `WeaponAssetImport` é uma ferramenta
manual opcional; Play não baixa prefabs nem substitui os modelos incluídos.
