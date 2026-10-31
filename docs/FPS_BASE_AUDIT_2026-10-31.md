# Etapa 1 — auditoria e escolha de base FPS

Data: 31/10/2026. Projeto auditado: `b6e97a67d5b9c2654a32a39803fe5b910eaf00ee`.
Escopo autorizado: pesquisa, auditoria e proposta. Nenhuma migração da camada FPS
foi executada. Counter Blox é referência de jogabilidade, não fonte de assets.

## Conclusão e recomendação

**Recomendo qualificar o template oficial Roblox FPS System como candidato
principal.** Ele fornece o núcleo FPS do Laser Tag e dois blasters em uma cena
de alvos. Isso permite estudar a infraestrutura FPS sem importar outra rodada,
economia ou mapa sobre o Zombie Outbreak.

Isso é uma recomendação de candidato, não a afirmação de que encontramos um
Counter Blox completo, licenciado e pronto para substituir nosso jogo. Não
encontrei essa combinação nas fontes verificadas. Também não encontrei fonte
oficial licenciada de Counter Blox que autorize copiar seus scripts e assets.
Resultados de exploração, vazamento ou descompilação foram excluídos.

O arquivo nativo do FPS System ainda precisa ser recebido e examinado. A
documentação oficial autoriza usar templates uncopylocked para iniciar projetos,
mas não identifica ali uma licença única para todo o código e assets do place.
Não atribuo MIT ao template inteiro com base na licença dos exemplos da
documentação. Avisos do arquivo e condições dos assets devem ser conferidos
antes da integração.

**Não recomendo reconstruir a infraestrutura agora.** Primeiro precisamos
qualificar essa base real; depois apresentar a substituição concreta para
aprovação. Não há comprovação de que ela inclua loja CS, agachamento, corrida
tática, skins ou personagens táticos. Esses pontos permanecem lacunas explícitas.

## Pesquisa: fontes e limites

Foram consultados repositórios reais, seus arquivos e licenças, buscas de
repositórios no GitHub e documentação oficial Roblox. As cópias de estudo ficam
fora do perfil do jogo, em `/workspace/reference-study`.

Consultas diretas à API do GitHub, Creator Store e DevForum receberam
`Tunnel connection failed: 403 Forbidden`, inclusive na repetição fora do
sandbox. A busca normal de repositórios do GitHub e os arquivos oficiais no
GitHub ficaram acessíveis. Portanto, não apresento uma busca completa do catálogo
Creator Store/DevForum nem afirmo disponibilidade atual de assets não obtidos.
Os links oficiais abaixo permitem continuar a qualificação no Studio local.

### Comparação dos candidatos

| Base e fonte verificada | Licença/reutilização | O que foi encontrado | Limitação e decisão |
| --- | --- | --- | --- |
| [Roblox FPS System / Laser Tag](https://github.com/Roblox/creator-docs/blob/c8f5276703948ef4868c9b9fd44fae619dbe2f11/content/en-us/resources/templates.md) | Documento oficial define templates como jogos uncopylocked para iniciar projetos. Licença/notices do place inteiro ainda precisam de inspeção; não presumir MIT para os assets. | Laser Tag: blasters FPS com dano, munição, recoil e dispersão configuráveis, rodadas simples e arena PBR. FPS System usa o mesmo núcleo com dois blasters e alvos. Arquivo real disponível pelo Studio conforme documentação, ainda não recebido nesta auditoria. | **Candidato principal para qualificação.** A documentação não comprova crouch, sprint, compra CS, skins, personagens táticos ou Rojo. Sem teste de execução nesta máquina. |
| [Roblox Battle Royale](https://github.com/Roblox/creator-docs/blob/c8f5276703948ef4868c9b9fd44fae619dbe2f11/content/en-us/resources/battle-royale/index.md) | Roblox Limited Use License explicitamente indicada para o projeto e documentação. | Jogo multiplayer documentado com quatro modos, nove armas preconfiguradas, construção, destruição, veículos e fluxo de partida. | **Não recomendo como base principal:** câmera em terceira pessoa e arquitetura de lobby, teleporte, tempestade e construção muito diferente. A documentação avisa que processos podem estar desatualizados. Não comprova loja CS. |
| [Roblox Weapons Kit / fork revisado](https://github.com/JustAT0rtoise/Roblox-Weapon-Kit-Fix/tree/72229de581a9c38272b10e4353804c80ac0c6379) | Original: Roblox Limited Use License. Apenas modificações do fork: MIT ©2025 JustATortoise. A pistola oficial recebida usa a licença original Roblox. | Kit completo de armas com scripts, câmera sobre o ombro, sprint/zoom, configuração, efeitos e animações. AR e pistola reais já estão no nosso pacote como apresentação; fontes completas foram revisadas. | Fonte de componentes comprovada, **não um FPS tático completo**. Não oferece compra CS/skins/crouch comprovados. Ativar o kit inteiro introduziria outra câmera, rede e escrita de WalkSpeed. Não resolve sozinho a nova missão. |
| [voximity/extract](https://github.com/voximity/extract/tree/45afa80c93eeb8f4b21a84bab8a4b14a30ff33cc) | MIT ©2019 voximity para o código examinado. | Código de deathmatch, armas, worldmodel, personagem, inventário, UI, espectador e rodada. | Faltam assets/place, chat e projeto Rojo. O README diz: “Do not expect to be able to build a game off of it.” Reutilização pontual possível, mas **não é uma base completa executável fornecida**. |
| [Draconic02171/Simple-FPS-Framework](https://github.com/Draconic02171/Simple-FPS-Framework/tree/9af6d2e35169aa48c9149ebbbb43aa5a37895471) | MIT ©2025 Draconic02171 para o código. | Código de framework e instalador remoto. | Modelos/viewmodels/animações e um place executável completo não estão incluídos no checkout examinado. Não o promover a solução completa nem executar instalador remoto sem auditoria. |
| [Giant427/Accelerator-Framework-1](https://github.com/Giant427/Accelerator-Framework-1/tree/0ffddd5754265f4eb06ae65922f762ecf2f23d11) | **Sem LICENSE** no commit examinado; origem/licenças dos modelos não comprovadas. | `.rbxl`, Rojo, scripts de armas AK/M4A4/AWP, viewmodels e câmera. | O README diz que não recomenda uso em jogo e que animações provavelmente foram deletadas. Não aprovado para cópia/produção sem autorização e assets verificáveis. |
| [lee552065-oss/tactical-fps-roblox](https://github.com/lee552065-oss/tactical-fps-roblox/tree/0e82197f5a35e44a4694c62c694b8030c0657099) | MIT ©2026 benGG. | Descrição anuncia FPS tático 5v5, mas há somente sete módulos Lua; reload repõe munição instantaneamente e GameManager altera estado/imprime mensagens. | Sem câmera, viewmodels, remotes/cliente, modelos, animações, place ou Rojo. **Esqueleto, não base completa.** |
| [JinnnnH/War-Game-Project-ROBLOX-](https://github.com/JinnnnH/War-Game-Project-ROBLOX-/tree/23ff11afb86d731fe5dc37cc200b5628f49119ae) | MIT ©2020 JinnnnH no repositório; direitos de cada modelo interno ainda não auditados. | Quatro snapshots `.rbxl` e README de uma linha, apresentado como primeiro projeto. | Sem documentação funcional, fontes organizadas ou Rojo. A inspeção binária do snapshot final não foi concluída; não afirmo que os assets ou o jogo funcionem. Não recomendo substituir o nosso núcleo por ele sem qualificação adicional. |
| [TateoDev/Roblox-Laser-Tag](https://github.com/TateoDev/Roblox-Laser-Tag/tree/981028c3bfdc5a8158a7f8d1e1e44117c3ebd492) | **Sem LICENSE** na árvore examinada. Não inferir permissão só pelo nome Laser Tag. | Possui `LaserTag.rbxl`; o README diz que os scripts publicados servem de referência e não são o projeto completo. | Native place presente não comprova autorização nem qualidade. Excluído como fonte legal comprovada. Preferir o template oficial. |
| [thewrathh/Roblox-FE-Weapon-Kit](https://github.com/thewrathh/Roblox-FE-Weapon-Kit/tree/ce683c3295e728f3d63456de030182421849e8d2) | **Sem LICENSE** no commit examinado. | GunClient, GunServer, configurações, módulos e replicadores. | Sem modelos/animações/place ou Rojo executável identificado. Não aprovado como pacote completo reutilizável. |

[sirattack/roblox-cs-fps](https://github.com/sirattack/roblox-cs-fps/tree/3bfdb2aa792b8dff6ed0121c15a599aceb8920d5)
tem apenas README de uma linha, sem implementação ou licença. O
[FPS-Multiplayer-Template](https://github.com/TheDahoom/FPS-Multiplayer-Template/tree/dd9627490d5bb6f16f84b4ffd09bfc6f036140b1)
já citado em atribuições antigas é de **Godot**, não uma base Roblox, mesmo com MIT.
Bibliotecas de spring, raycast ou câmera isoladas não foram contadas como FPS completo.

### Por que FPS System antes de Laser Tag

Ambos usam o mesmo núcleo FPS segundo a fonte oficial. FPS System tem alvos em
vez de exigir a adoção da arena e das rodadas Laser Tag. Nosso mapa e rodadas já
existem; importar outra implementação dessas partes aumenta conflito e retrabalho.
Essa escolha não reduz o sistema de zumbis nem importa os mapas do template.

Identificadores oficiais documentados:

- FPS System: place **17823017290**, universe **6106388692**.
- Laser Tag: place **17823019220**, universe **6106389365**.
- [Página oficial para abrir os templates no Studio](https://create.roblox.com/docs/resources/templates#fps-system).

## Auditoria do Zombie Outbreak atual

O projeto já contém uma camada central própria de combate, inventário e loja.
A apresentação reutiliza assets/código revisado do Weapons Kit. Não é correto
dizer que já adotamos uma base Counter Blox nem que o pacote FPS está completo.

| Sistema atual | Evidência no repositório | Estado e limite |
| --- | --- | --- |
| Mapas e arquitetura | `src/maps/k17`, `assets/maps`, fontes dos cenários anteriores em `src/maps`, `third_party/harbor-locks` | K‑17 é o perfil ativo. Também há fontes/cenários inativos a preservar. Nenhuma geometria foi alterada nesta etapa. |
| Defesas | `src/maps/k17/barricades`, catálogos/modelos e auditorias | 164 objetos, quatro dutos e 34 refúgios no perfil atual; física sob autoridade do servidor. |
| Combate/dano | `Combat.server.luau`, `Rules.luau` | Servidor valida personagem/papel/fase, cadência, munição, direção, raio e dano. Dano/knockback e acertos em props são parte desse fluxo. |
| Inventário/economia | `LoadoutState.luau`, `WeaponState.luau`, `Config.luau` | Slots primária/secundária, munição por arma, créditos, compra, recarga e troca. Valores configuráveis. |
| Armas reais | `Arsenal.rbxmx`, manifesto de origem e extrator | Rifle e Pistol embutidas. SMG/Shotgun configuradas, mas sem modelos; compra bloqueada. Não há arsenal completo, faca/granadas/sniper integrados nem sistema de skins. |
| Câmera/viewmodel/HUD | `Weapons.client.luau`, `WeaponPresentation.luau`, `WeaponAimPose.luau`, `EquipmentVisuals.server.luau` | Primeira pessoa, braços R15, ADS, recuo, áudio e modelo corporal. R6 tem limitações de animação. Visual/áudio multiplayer ainda não aprovados no motor. |
| Loja e HUD de rodada | `Loadout.client.luau`, `WeaponPreview.luau`, `HUD.client.luau` | B, prévia 3D, preço, saldo, posse, munição e tempo. Ainda não é uma loja categorizada equivalente à de Counter Blox. Qualidade visual não foi certificada. |
| Rodada/infecção | `Round.server.luau`, `RoundRules.luau`, `RoundConfig.luau` | Preparação, primeiro infectado, infecção por golpe, vitórias, reinício e transformação no lugar. Papel/equipe bloqueiam armas e loja de zumbis. |
| Movimento | Humanoid Roblox + `Round.server.luau`/`Containment.luau` | Velocidade por papel e lentidão temporária por tiro. Corrida tática/agachamento não implementados. Outro escritor de WalkSpeed pode quebrar a recuperação da lentidão. |
| Humanos/zumbis | Avatar do jogador, rig/animações e coloração por papel | Não existe pacote próprio de humanos táticos nem troca completa de animações de locomoção zumbi. |
| Zombie Escape | Não há controlador/modo implementado identificado | Está planejado. Não há um modo Escape funcional a declarar preservado/concluído. A integração FPS não o implementa automaticamente. |

### Contratos que uma migração precisa preservar

`Combat` continua sendo hoje a autoridade de munição, recarga, tiros, dano,
contenção, melee e economia. Os remotes ativos incluem `ZO_FireRifle`,
`ZO_Melee`, `ZO_LoadoutAction` e `ZO_CombatFX`; as funções privadas `Infect`,
`DamageBarricade` e `PushBarricade` não devem virar ações livres do cliente.

Os atributos replicados de papel, arma equipada, munição, créditos, recarga e
fase conectam loja, visual, servidor e rodada. Mudá-los exige adaptar todos os
consumidores, não adicionar um segundo controlador ao lado do atual.

`Round` define a base de movimento por papel. `Combat` aplica e restaura a
contenção temporária. Corrida/agachamento novos devem compor essa base e o efeito
de tiro, sem reduzir permanentemente a velocidade ou anulá-lo a cada quadro.
As montagens dinâmicas de barricadas devem continuar sendo atingidas e empurradas
pelo caminho autorizado do servidor.

## Matriz de compatibilidade proposta

Os módulos exatos do template não foram inventariados: os itens “FPS System”
abaixo são alvos de integração, não nomes de APIs que afirmamos já ter lido.

| Existente | Sistema candidato | Decisão proposta | Dependências/riscos | Prova necessária |
| --- | --- | --- | --- | --- |
| K‑17 e demais fontes de mapa | Arena/alvos do template | Manter nossos mapas; usar cena do template apenas para estudo isolado. | Escala/câmera não autorizam reconstruir geometria. | Inventário/hash dos mapas; navegação e colisões nos refúgios/dutos. |
| Barricadas, dano e impulso em props | Acertos das armas FPS | Manter catálogo, montagens e regras; conectar o acerto confirmado do novo núcleo. | Um raycast que ignore props/Tools pode permitir tiros através da defesa. | Tiro no primeiro obstáculo, impulso, golpe, quebra e reset com dois clientes. |
| Round/infecção/vitórias | Rodada simples Laser Tag | Manter autoridade de modo Zombie; não ativar rodada Laser Tag concorrente. | Equipes/respawns/equipamentos automáticos podem desfazer infecção. | Três ciclos completos, humanos/zumbis, saída/morte/reset. |
| Câmera/input/viewmodel atuais | Núcleo FPS System | Substituir como conjunto somente se a prova demonstrar ganho e compatibilidade. | Bindings, mouse, prioridade de câmera, animações e FOV duplicados. | Uma única câmera/entrada; PC/toque/gamepad; troca, morte, menus e infecção. |
| Combate autoritativo atual | Pipeline de tiros do template | Escolher um único núcleo após ler código real. Preservar todas as validações e hooks Zombie. | Não sabemos ainda o contrato de servidor do arquivo nativo. | Cadência/munição/direção no servidor; dano, hitgroup, knockback e prop como primeiro impacto. |
| LoadoutState/economia | Equipamento dos blasters | Manter regras existentes e adaptar operações à única autoridade escolhida. | Dupla munição, recarga grátis, compras duplicadas, equip após infecção. | Compra atômica, recarga/cancelamento, troca sem refil, zumbi sem arma/loja. |
| Loja B/HUD/preview | UI FPS fornecida | Conservar economia e incluir categorias/visual posteriormente; retirar HUDs duplicados. | FPS System não comprova menu CS nem economia. | Preço/saldo/posse do servidor, preview real, tempo e bloqueios de papel. |
| Rifle/pistola reais | Dois blasters do template | Preservar assets licenciados já obtidos; adaptar modelos ao contrato real do novo núcleo. | Muzzle/grip/joints, escala e timings; novos assets não comprovados. | Primeira/terceira pessoa, tiro/recarga, sons nos dois clientes. |
| Movimento Humanoid/containment | Movimento disponível no template | Preservar física e base por papel; qualificar crouch/sprint como lacunas até verificar. | Conflito WalkSpeed, altura, teto, degrau e contato corporal. | Tiros repetidos e recuperação, entrar/sair de crouch, teto baixo e barricadas. |
| Avatar/coloração atual | Personagens/skins pretendidos | Conservar identidade/papel até existir pacote tático com licença e rig compatíveis. | Não há modelos táticos/skins completos qualificados nesta pesquisa. | Rig, câmera, acessórios, animações e limpeza na infecção. |

## Migração proposta, reversão e aprovação

1. **Receber o FPS System oficial:** abrir pela página oficial ou tela inicial
   do Studio, salvar uma cópia como `FPS_System_Oficial.rbxl` e disponibilizar o
   arquivo para auditoria. Não publicar sobre o Zombie Outbreak para obter isso.
2. **Qualificar o arquivo:** registrar hash/origem/notices, ler código e assets,
   identificar câmera, viewmodel, inputs, servidor e dependências; comprovar
   quais requisitos existem e quais continuam ausentes. Não executar código
   externo no nosso jogo antes dessa revisão.
3. **Apresentar a troca concreta para aprovação:** lista dos módulos a manter,
   adaptar e substituir, com contratos reais do arquivo. Enviar o template para
   auditoria não equivale a aprovar uma reconstrução estrutural.
4. **Após aprovação**, criar branch de migração e um perfil de validação que
   referencia nossos mapas existentes. Ativar somente um conjunto FPS por perfil.
   A apresentação/controle anterior permanece recuperável no histórico, sem
   correr ao mesmo tempo que o novo sistema.
5. Integrar papel/fase/equipamento e o caminho de acertos do servidor, preservando
   os testes existentes. Validar compra, reload, knockback, props, infecção e
   reinício antes de tornar o novo perfil o padrão.
6. Só depois tratar categorias de compra, crouch/sprint, personagens, skins e
   demais armas que não forem fornecidos pelo candidato. Isso não conta como
   funcionalidade já disponível no template.

Backup recuperável desta auditoria: `backup/before-fps-base-audit-b6e97a6` e
`/workspace/backups/zombie-outbreak-reborn/before-fps-base-audit-b6e97a6.tar.gz`.
Reversão de eventual migração: trocar para a branch de backup e abrir o binário
preservado; não depende de reconstruir mapas ou apagar trabalho com reset.

### Aceitação no motor

Antes da troca padrão, executar com dois clientes: entrada/respawn, câmera e
movimento, mira/recuo, equip/disparo/reload/troca, compra por fase, dano, infecção,
remoção de armas, melee, knockback e recuperação, barreiras como primeiro impacto,
quebra/reset dos props e resultados/reinício. Crouch/sprint só passam quando
existirem e forem verificados com tetos, escadas, dutos e barricadas. Conferir
também o observador e um cliente que entra depois, áudio, animações e FPS.

Não há conexão desta nuvem com o Studio local. Não foram realizados testes
visuais, auditivos ou multiplayer nesta pesquisa. Análise de arquivos e testes
com APIs simuladas não substituem essa aprovação.

## Entrega desta etapa

Entregues: comparação com links/revisões e limites de licença, inventário atual,
matriz de compatibilidade, candidato recomendado, riscos, plano e reversão.
O relatório e o registro da missão são documentação; `src`, `assets`,
`default.project.json` e `builds` permanecem iguais ao commit auditado.

Pendente para concluir a qualificação do candidato: o arquivo oficial FPS System
e seus avisos, seguido da aprovação explícita da integração. Nenhuma arma,
mapa, barricada, controlador ou sistema de rodadas foi substituído nesta etapa.
