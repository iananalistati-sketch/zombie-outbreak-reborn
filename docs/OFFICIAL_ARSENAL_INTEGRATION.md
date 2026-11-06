# Arsenal oficial aplicado

As quatro classes configuradas agora têm modelos reais incluídos no K-17:
carabina, pistola, SMG e escopeta. Os downloads oficiais de SMG/escopeta foram
obtidos com HTTP200, examinados como dados e integrados ao núcleo existente.
Não há importação automática ao iniciar Play, segundo sistema de combate nem
reconstrução do mapa.

| Arma | Acabamentos incluídos | Loja | Munição K-17 |
| --- | --- | ---: | --- |
| Carabina | Original | $1.500; inicial equipada | 30/120 |
| Pistola | Preta, clássica, dourada | Inicial/secundária | 12/72 |
| SMG | Original, bronze, branca | $1.000 | 32/160 |
| Escopeta | Original, areia, prata | $2.200 | 8/48 |

São **quatro armas e seis skins adicionais**, dez templates visuais ao todo.
Os acabamentos não alteram dano, munição ou preço. Seleção fica por sessão e
permanece entre rodadas/respawns. O núcleo K-17 conserva a SMG automática e a
escopeta semiautomática com sete projéteis por cartucho. Os valores nativos
do prefab (SMG30/escopeta5 e cinco projéteis) não substituem o balanceamento.

## Origem e revisão

- [SMG — Roblox Resources](https://create.roblox.com/store/asset/119916677125479):
  252.906 bytes, SHA-256 `61703285cb11bad6c5a24cbd37d0caea40824f877e7c0cd3e1e161d8bdf974c1`.
- [Shotgun — Roblox Resources](https://create.roblox.com/store/asset/104068096273092):
  245.860 bytes, SHA-256 `63858a4c5a91e83894fffe2647cb3a43fc57ceff48e91002d1b4e1f122a6bf41`.
- Autor verificado pelo endpoint oficial: grupo Roblox Resources3529469.
  Licença: Roblox Limited Use License do Weapons Kit. O campo IsPublicDomain
  da API registra disponibilidade no Roblox, sem reclassificar o material CC0.

Binários exatos, metadados e mapeamento das variantes ficam em
`third_party/roblox-weapon-kit/official-prefabs`. Os SourceAssetIds internos
legados4842212980/4842215723 são conservados, separados dos IDs atuais da loja.

Cada pacote contém três Tools com16 scripts cada. Os16 corpos únicos são os
mesmos da pistola já revisada, comparados integralmente após normalização de
CRLF para XML. Não foram executados. A extração remove WeaponsSystem inteiro,
scripts, remotes, bindables, PackageLinks, WeaponType e tags; corrige referências
e conserva meshes, texturas, attachments, áudio e dados físicos nativos.

Sons originais: SMG4812801977/3821793228; escopeta3821792787/3821792115.
As três animações R15 RifleAim/ADS/Reload são exatamente as já incluídas pelo
kit. Os novos modelos não têm BoltMotor: não se anuncia animação própria de
ferrolho/pump inexistente. O recuo e o flash continuam no adaptador existente.

O RBXM original tem três raízes. O conversor de revisão acrescenta só uma pasta
temporária para o Rojo e verifica nomes/fontes preservados. Os originais não
são alterados. Para reproduzir:

```sh
rojo build third_party/roblox-weapon-kit/upstream.project.json --output /tmp/upstream.rbxlx
python scripts/build_official_weapon_review.py --output /tmp/prefabs.rbxlx
python scripts/extract_reused_weapon_kit.py /tmp/upstream.rbxlx --prefabs /tmp/prefabs.rbxlx --check
```

## Como conferir quando houver Studio

Faça Pull de `feat/fps-combat-package` e reabra `ABRIR_K17.cmd`; atualizar Git não
troca um place salvo já aberto. O arquivo binário e o checksum acompanham esta
entrega. Nenhum comando de captura é necessário para as quatro armas incluídas.

1. Na preparação, abra **B**, escolha **SMG** ou **Escopetas** e compre. A loja
   deve debitar o valor uma vez e equipar a primária com seu modelo real.
2. Confira a prévia e selecione os acabamentos disponíveis. Use **Aplicar
   aparência**; compare prévia, primeira pessoa e arma na mão do outro jogador.
3. **1** equipa a primária, **2** a pistola e **R** recarrega. Segurar disparo
   repete a SMG; na escopeta, cada clique produz um disparo e gasta um cartucho.
4. Confira sons de tiro/recarga, mira e braços R15. Com dois clientes, confira
   dano/knockback, remoção da arma na infecção e retorno na rodada seguinte.

## Evidências e limites

Extração e reprodução,11 testes nativos de assets,26 verificações do catálogo,
233 de combate,130 da loja,122 do cliente de armas,38 do importador e38 de
equipamento passaram com os fontes reais/APIs simuladas. Também passam o ciclo
Survival39 e a rodada41. Compilação Luau/Rojo e os vínculos do modelo embarcado
verificam as quatro classes/seis skins dentro do place, não só nas configurações.

Renderização, permissões de cada mesh/som/animação, navegação, áudio e multiplayer
no motor Roblox permanecem pendentes. O cenário automático separado preserva
seus24 checks anteriores; os quatro passos acima são validação adicional manual.
Faca, sniper e demais classes não foram integradas nesta entrega.

Backup anterior: `backup/before-official-arsenal-4c837cd` e tar verificado na nuvem.
Mapa, barricadas, dutos, refúgios, rodada, infecção e preços foram preservados.
