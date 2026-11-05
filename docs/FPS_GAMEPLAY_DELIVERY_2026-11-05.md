# Entrega de jogabilidade FPS — 05/11/2026

Branch `feat/fps-combat-package`. Base anterior: `13603bf`. Esta entrega segue o
novo pedido de implementar melhorias na base existente, com autonomia e sem
aguardar acesso local ao Studio. O Foundry/K-17, os mapas inativos, as 164
barricadas, os quatro dutos e os 34 refúgios não foram reconstruídos.

## Funcionalidades implementadas nesta etapa

- **Shift:** corrida configurável, multiplicador 1,25. Humano: 16→20;
  zumbi: 19→23,75. **Alt:** caminhada a metade da velocidade. **Ctrl/C:**
  agachar segurando/alternando. L3/toque alternam corrida; B no controle alterna
  agachamento quando os menus estão fechados. WASD/Space continuam no
  controlador padrão do Roblox, sem instalar outro controlador concorrente.
- A velocidade continua composta por `MovementState`: equipe × postura ×
  contenção temporária por tiro. Corrida/agachamento não anulam o efeito nem
  usam uma velocidade já reduzida como nova base. Sob teto baixo, tentar correr
  não força a cabeça para dentro do obstáculo: a postura permanece agachada.
- A arma permanece visível e abaixa suavemente ao correr. Corrida cancela ADS
  e a sequência de disparos local. O servidor rejeita pedidos de tiro nessa
  postura antes de gastar munição ou cadência. Recarga, troca e compra preservam
  suas regras; não ficam bloqueadas somente porque o jogador está correndo.
- Balanço discreto ao caminhar/correr e reação ao mouse no viewmodel, adaptados
  do Extract MIT. Mirar/agachar reduzem o deslocamento. São offsets somente do
  modelo: não alteram câmera, vetor do tiro, dano ou a mira balística do servidor.
- Precisão configurável: agachado no chão aplica dispersão ×0,75; no ar, ×1,8.
  A penalidade aérea prevalece sobre a postura agachada. ADS conserva suas
  configurações por arma. A mira usa a mesma regra e velocidade horizontal
  observada, em vez de inferir movimento somente da tecla pressionada.

## Estado real dos demais requisitos

| Requisito | Estado na entrega |
| --- | --- |
| Primeira pessoa, WASD e Space | Preservados; câmera padrão e apresentação existente. Navegação real ainda depende do Studio. |
| Rifle automático e pistola | Dois modelos reais incluídos, com meshes, texturas e sons originais. Nenhum novo modelo anunciado. |
| SMG e escopeta | Estatísticas, compra e disparos já preparados; **modelos ainda ausentes**, portanto compra/equipamento continuam bloqueados. |
| Faca humana | **Não implementada**: não há modelo/conjunto de apresentação licenciado qualificado incluído. Zumbi mantém ataque corpo a corpo. |
| Munição/reserva, R, troca, recuo, headshots, hitmarker | Preservados no combate atual com autoridade do servidor; não reescritos. |
| Animações | Mantidos Aim/ADS/Reload do kit, ferrolho/flash e poses existentes; acrescentados offsets de corrida/movimento. Não há novo pacote completo de animações táticas validado. |
| Loja B | Preservadas categorias, seleção, prévia 3D, preços, saldo e economia do servidor. Não foi criado outro menu. |
| Infecção, primeiro zumbi, equipes, vitória e rodadas | Preservados. A infecção atual ocorre por golpe de proximidade validado; **contato corporal automático não foi acrescentado**. |
| Knockback e barricadas | Fluxo existente preservado; parâmetros continuam configuráveis. Física real e equilíbrio precisam do motor. |
| Zombie Escape | Planejado; nenhum mapa ou controlador Escape foi criado. |

## Componentes reutilizados e origem

- [Roblox Weapons Kit](https://create.roblox.com/docs/resources/weapons-kit):
  assets e adaptadores de apresentação já existentes. Distribuição examinada:
  [JustAT0rtoise/Roblox-Weapon-Kit-Fix](https://github.com/JustAT0rtoise/Roblox-Weapon-Kit-Fix/tree/72229de581a9c38272b10e4353804c80ac0c6379).
  O original usa Roblox Limited Use License; correções do fork usam MIT. A
  pistola preta vem do arquivo oficial fornecido pelo usuário. Origem, revisão,
  exclusão dos scripts legados e hashes em
  [third_party/roblox-weapon-kit](../third_party/roblox-weapon-kit/ATTRIBUTION.md).
- [voximity/extract](https://github.com/voximity/extract/tree/45afa80c93eeb8f4b21a84bab8a4b14a30ff33cc),
  MIT: controles/postura já adaptados; nesta etapa, reutilizadas as funções
  senoidais de movimento, interpolação por faixa de velocidade e sway do mouse
  de `Client/Weapons.lua`. Fonte original byte a byte, licença e hash
  `92fba016349391dc37271b5456377fb27202e319bcee5b06bd154a8ed8c26d9d`
  arquivados em [third_party/extract-movement](../third_party/extract-movement/ATTRIBUTION.md).

Os scripts originais completos permanecem fora do runtime. As adaptações não
ativam outra câmera, rede de dano, inventário ou sistema de rodadas. A integração
do FPS System oficial não ocorreu: faltam fontes/arquivo e avisos examinados.
O simples acesso a uma página ou ao nome de um modelo não foi contado como
importação. Não foram incorporados assets proprietários de Counter Blox/CS.

Pesquisa complementar de modelos nesta sessão:

- Tentativa de obter a [SMG oficial](https://assetdelivery.roblox.com/v1/asset/?id=119916677125479):
  `Tunnel connection failed: 403 Forbidden`, no proxy antes de alcançar o
  serviço. Nenhum binário foi recebido. Isso não prova que o asset foi removido
  nem permite concluir quais permissões ele teria dentro do Studio.
- [Busca GitHub por shotgun/rbxm](https://github.com/search?q=roblox+shotgun+rbxm&type=repositories)
  e [por modelos/licenças](https://github.com/search?q=roblox+weapon+models+license&type=repositories):
  HTTP 200 para as páginas de busca; nenhum novo candidato foi qualificado
  quanto a modelo/licença. Páginas de busca não equivalem a assets recebidos.
- Reaproveitada a [auditoria dos candidatos existentes](FPS_BASE_AUDIT_2026-10-31.md):
  Extract fornece código MIT, mas não os modelos; Accelerator/FE Weapon Kit não
  têm licença comprovada na revisão examinada. Não foram integrados por suposição.

## Arquivos alterados

- `MovementConfig`, `MovementState`, `Movement.server` e `Movement.client`:
  corrida/controles e composição com a contenção existente.
- `Config`, `Rules`, `Combat.server`: precisão e rejeição de tiro em corrida.
- `WeaponMotion` novo e `Weapons.client`: integração do movimento visual,
  postura de corrida, cancelamento de mira e feedback.
- Perfil Rojo, verificadores de fontes/binário e CI: vinculam o único módulo
  novo e verificam os fontes efetivamente compilados.
- Testes reais com APIs simuladas e cenário isolado de Studio; binários e
  manifesto de checksum atualizados. Os construtores/cenas dos mapas não mudam.

Problemas de integração corrigidos: Shift antes acionava caminhada, em desacordo
com o novo pedido; a regra de escala anterior impedia representar corrida acima
da base; a nova postura precisava bloquear tiros também no servidor, sem gastar
munição/cadência. A mira também inferia movimento pela intenção do Humanoid,
enquanto o servidor já usava deslocamento observado. Agora compartilham a regra
de precisão e o mesmo limiar de velocidade horizontal.

## Verificações executadas e limitações

| Teste dos fontes reais com APIs simuladas | Verificações |
| --- | ---: |
| Estado de movimento | 85 |
| Servidor de movimento/postura | 45 |
| Cliente de movimento | 74 |
| Matemática do viewmodel | 15 |
| Regras de combate | 196 |
| Controlador de combate | 165 |
| Cliente de armas | 107 |
| Rodadas | 41 |
| Ciclo Survival integrado | 39 |
| Loja | 73 |

Também são executados compilação Luau/Rojo, testes de apresentação/equipamento,
regressões de barricadas e verificações de fontes/checksum dos places. O arquivo
de validação separado passa a conter **24 verificações preparadas para o motor**,
incluindo corrida, disparo recusado sem dano/munição e recuperação de velocidade.
**Esse cenário não foi executado no Roblox Studio.** Os testes simulados não
comprovam aparência, áudio, física, passagem por dutos ou multiplayer real.

Não há conexão desta nuvem com o Studio do usuário. O perfil Rojo mapeia os
fontes atuais e os binários são recompilados; isso não sincroniza uma experiência
salva/Team Create ou um place antigo já aberto no computador. Nenhum teste foi
anunciado como execução no Studio ou controle do VS Code local.

## Pendências e próxima etapa

Continuam pendentes os modelos completos de SMG/escopeta/faca, possíveis permissões
de meshes/sons/animações e a validação física/visual com dois clientes. Completar
o arsenal com arquivos realmente licenciados e auditáveis é a próxima etapa
recomendada antes de expandir mapas. O trabalho que exige o usuário fica para
quando houver acesso ao Studio; nenhuma ação local é necessária para guardar
esta entrega.

Para abrir depois: Pull da branch acima e `ABRIR_K17.cmd`. O jogo normal usa
`builds/ZombieOutbreakReborn_K17.rbxl`; o cenário automático separado usa
`builds/ZombieOutbreakReborn_SurvivalTest.rbxl`.

Backup anterior: `backup/before-fps-gameplay-13603bf` e tar verificado na nuvem.
`main` permanece na versão estável enquanto faltarem os modelos do pacote FPS.
