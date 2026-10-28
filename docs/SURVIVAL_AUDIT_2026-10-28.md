# Auditoria e estabilização de Zombie Survival — 28/10/2026

Estado: auditoria dos fontes realizada, correções reproduzidas e verificações
de servidor executadas na nuvem. **A aprovação da primeira entrega funcional
continua pendente de Roblox Studio.** Não houve execução do motor, captura visual
ou partida multiplayer real nesta nuvem.

## O que foi preservado

O perfil ativo é `default.project.json`. O K-17 possui aproximadamente 600 × 600
studs, cinco edifícios, subterrâneo, 34 refúgios e 164 objetos de barricada. A
verificação geométrica não comprova arquitetura convincente nem qualidade visual.

`Round.server.luau` já implementava espera por jogadores, preparação, escolha dos
primeiros infectados, transformação no local, contagem de equipes, vitória humana
por tempo, vitória zumbi por infecção e reinício automático. `Combat.server.luau`
já controlava munição, cadência, recarga, dano, infecção por golpe e economia no
servidor. Esses sistemas foram mantidos e corrigidos.

O arquivo e as licenças do Roblox Weapons Kit continuam preservados em
`third_party/roblox-weapon-kit`. Também foram examinadas as bases públicas
`voximity/extract` e `Draconic02171/Simple-FPS-Framework`: a primeira declara não
ser um jogo compilável; a segunda depende de recursos importados e não substitui
o Survival completo. Esta revisão não adiciona outro framework de combate.

## Defeitos reproduzidos e corrigidos

| Defeito anterior | Correção |
| --- | --- |
| A raiz ou o Humanoid demoravam mais de dez segundos; o personagem podia entrar na rodada sem registrar a própria morte | Carregamento por eventos, conexão de morte independente da raiz e descarte de callbacks de personagens antigos |
| O personagem era contado como pronto antes de entrar no Workspace | Prontidão exige entrada no mundo; o setup acompanha AncestryChanged |
| Um personagem já removido do Workspace ainda podia disparar durante a troca de personagem | Verificação de ancestralidade, bloqueio durante CharacterRemoving e cancelamento da recarga |
| Uma peça atingida dentro de um Model aninhado no personagem não recebia dano ou infecção | Busca do personagem responsável através dos ancestrais, preservando o tratamento das barricadas |

Os testes novos falharam com as fontes anteriores e passaram após as correções.
O backup anterior às alterações é a branch
`backup/before-survival-audit-2a95689`; o histórico Git foi preservado.

Arquivos principais desta revisão:

- Produção: `src/maps/k17/gameplay/Round.server.luau` e `Combat.server.luau`.
- Regressões: `tests/gameplay/round-controller.spec.luau`,
  `combat_runtime.spec.luau` e `support/CombatSimulation.luau`.
- Integração: `tests/gameplay/survival_cycle.spec.luau` e
  `scripts/test_survival_cycle.py`; runner de combate atualizado para reutilizar
  a infraestrutura existente.
- Studio: `tests/studio/`, `scripts/build_studio_survival_test.py` e o novo
  `builds/ZombieOutbreakReborn_SurvivalTest.rbxl`.
- Entrega: validadores, CI, README, AGENTS, esta auditoria, arquivo normal
  `builds/ZombieOutbreakReborn_K17.rbxl` e seu manifesto SHA-256.

## Verificações executadas

- Compilação dos fontes Luau e builds Rojo do jogo normal e do cenário de teste.
- Regressões: 41 verificações do controlador de rodada e 110 de combate passaram,
  com APIs simuladas. Os 21 testes Python de geometria/assets passaram.
- Teste integrado: `Round`, `Combat` e `Startup` compartilham os mesmos jogadores,
  relógio e função privada `Infect`. Confere dano, munição, recarga, infecção,
  recompensas, reinício, morte e substituição de personagem, duas condições de
  vitória, entrada tardia e cancelamento por desconexão em três rodadas.
  As 39 verificações desse cenário passaram.
- Suítes existentes de inventário, regras, contenção, barricadas e geometria.
- Identidade dos fontes nos arquivos compilados; configuração normal preservada;
  drivers e rodadas curtas restritos ao arquivo de validação separado.

Comandos do teste integrado e das regressões:

```sh
python scripts/test_round_controller.py --luau CAMINHO_DO_LUAU
python scripts/test_combat_controller.py --luau CAMINHO_DO_LUAU
python scripts/test_survival_cycle.py --luau CAMINHO_DO_LUAU
```

Os testes de servidor usam doubles das APIs: não executam rede, raycasts contra
a geometria real, física, carregamento de assets ou respawn automático do motor.
A criação do personagem substituto é fornecida pelo teste. As barricadas são
isoladas no teste integrado e possuem sua suíte própria.

## Validação necessária no Studio

Abra o arquivo já compilado `builds/ZombieOutbreakReborn_SurvivalTest.rbxl`.
Execute **Server & Clients → 2 clientes** e aguarde sem controlar os personagens.
O [roteiro](../tests/studio/README.md) explica as condições verificadas e a saída
`[SURVIVAL STUDIO] COMPLETE` ou `FAIL` com a etapa.

Esse cenário foi preparado para chamar os remotes de produção a partir dos
clientes e observar o dano, recarga, infecção e resultados reais no servidor.
**Ele foi compilado; ainda não foi executado no Studio.** Os personagens ficam
ancorados para repetir as linhas de tiro; isso não aprova movimentação ou física.

## Critérios ainda não aprovados

- Ciclo multiplayer no motor, controles, colisões, streaming, FPS e equilíbrio.
- Qualidade visual e arquitetônica do mapa industrial (fase 3).
- Modelos das outras quatro armas, áudio, animações, mira e apresentação do
  arsenal (fase 4). A troca anterior da AR não resolveu essas pendências.
- Animações, áudio e apresentação específicos dos zumbis.
- Zombie Escape: ainda não implementado; permanece na fase 5, após Survival.

Há implementações de vários critérios nos fontes, mas isso não marca todos os
critérios de aceitação como concluídos. A próxima evidência necessária é a
execução do arquivo de validação no Studio e um teste de jogabilidade do K-17.
