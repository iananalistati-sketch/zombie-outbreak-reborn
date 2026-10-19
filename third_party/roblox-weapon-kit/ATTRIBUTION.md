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
`src/third_party/roblox-weapon-kit/Presentation.rbxmx`, sem scripts ou remotes.

No K-17, `ReusedRiflePresentation.luau` adapta trechos de `BaseWeapon` e
`BulletWeapon` para weld, reprodução de áudio, tween do ferrolho e muzzle flash.
`EquipmentVisuals.server.luau` adapta o weld e o cache de animações. Os comentários
de atribuição permanecem nesses arquivos. Posicionamento em primeira pessoa,
cancelamento e ligação aos estados do K-17 são adaptações locais.

Não são ativados o controlador de dano, a rede de acertos ou a câmera do kit
completo. A AR usa os assets originais de mesh, textura, áudio e animação; a
disponibilidade e as permissões desses assets devem ser verificadas no Studio.
