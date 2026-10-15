# Zombie Outbreak Reborn

Zombie Survival / Zombie Mod em Luau para Roblox Studio. **Mapa ativo: K-17.**

## K-17 — Complexo de Contenção

Mapa novo, independente de Santa Aurora e Harbor, com aproximadamente **600 × 600
studs**. Cinco edifícios com interiores, três acessos ao subterrâneo, coberturas,
galerias, contêineres e 18 posições de resistência identificadas.

- Administração com três andares e escritórios subdivididos.
- Estação de energia com dois andares e ligação elevada à administração.
- Fundição com prensas, esteiras, ponte rolante, postos de solda e mezanino.
- Depósito de dois andares com estantes e ligação à galeria da fundição.
- Torre de controle com quatro andares.
- Pátio industrial, tubulações, estacionamento, vans e circuito de manutenção.

[Documentação e roteiro de teste](docs/K17.md) · [Planta](docs/K17_PLAN.svg) ·
[Pesquisa realizada e limitações](docs/K17_REFERENCES.md)

[Revisão de projetos abertos de Zombie Mod para CS2 e CS:GO](docs/CS_ZOMBIE_OPEN_SOURCE.md):
referências verificadas de infecção, knockback e diferenças do protótipo atual.

**Atual: [início da partida, quatro dutos e novos abrigos](docs/K17_START_AND_DUCTS.md).**
Infecção por golpe, primeiros infectados transformados no local, tiro contínuo,
recarga temporizada e knockback configurável. A prévia de construção anterior
está desativada. **Oito refúgios, quatro dutos com curvas e 40 objetos de barricada**. Os novos abrigos são filtros, oficina do pátio e refrigeração.

![Cortes geométricos dos refúgios; não é captura do Roblox Studio](docs/K17_REFUGES.png)

## Abrir no Windows

1. No GitHub Desktop, selecione **main**, faça **Fetch origin → Pull origin**.
   Preserve eventuais alterações locais antes de atualizar.
2. Salve uma cópia do seu place atual como backup. Desconecte o plugin Rojo se
   estiver ligado ao projeto anterior.
3. Use **Repository → Show in Explorer** no GitHub Desktop e dê dois cliques
   em **`ABRIR_K17.cmd`**, na raiz do repositório. Ele confere o SHA-256 da
   entrega e abre o caminho completo de `builds/ZombieOutbreakReborn_K17.rbxl`.
4. Selecione `Workspace → ZO_K17Foundry` e pressione **F**.
5. Use Play para explorar. Para iniciar as rodadas, teste com dois jogadores.

**“Recentes” reabre o place salvo anteriormente.** O Pull atualiza os arquivos
do Git e não troca o mapa de um place já aberto. O mapa urbano de dois prédios
e rua central é Santa Aurora, disponível no arquivo de nome `SantaAurora`.
O arquivo do K-17 tem `ZO_K17Foundry`, os 40 objetos e os quatro dutos; seu
binário foi decodificado para conferir esses itens e a ausência de Santa Aurora.

Se a associação de arquivos do Windows não abrir o Studio, o atalho mostra o
caminho exato. Use **File → Open from File** no Studio e selecione esse arquivo.
O atalho Windows ainda precisa ser executado no computador do usuário; esta
nuvem validou o conteúdo e o checksum, sem abrir o Studio.

Para visitar diretamente os locais alterados, durante **Play**, com um jogador,
use a **Command Bar em contexto Server**:

```lua
require(game.ServerStorage.ZO_Validation.RefugeAudit).visit(16)
```

Troque `16` por `17`, `18`, `7`, `2`, `10`, `14` ou `15` para visitar os demais. Empurre os objetos
por contato ou tiros; **R** recarrega. Veja o [roteiro dos refúgios](docs/K17_REFUGES.md).
O [treino com alvos de combate](docs/CLASSIC_GAMEPLAY.md) também está disponível.

O arquivo já contém o mapa, os scripts e a iluminação. É um place binário nativo
compactado; não exige GLB, Toolbox, upload de meshes ou Codex local.
É uma compilação desta entrega: depois de editar os fontes, recompile ou sincronize.

## Onde estão os fontes

```text
scripts/build_k17.py               construção original do mapa
scripts/k17_refuges.py             interiores defensivos
scripts/k17_shelters.py            três abrigos novos e quatro dutos
src/maps/k17/K17Foundry.rbxmx       cena persistente gerada
src/maps/k17/*.luau                configurações e diagnóstico do K-17
src/maps/k17/barricades/           catálogo único, modelos e física dos objetos
src/maps/k17/gameplay/             combate, infecção por golpe, rodada e HUD atuais
src/server/                       controladores anteriores usados por Santa Aurora
src/client/                       cliente anterior e bootstrap compartilhado
scripts/validate_k17.py            checagem de colisão e circulação
tests/k17/K17Audit.luau            auditoria preparada para o Studio
```

A geração acontece no desenvolvimento; não há gerador de cenário rodando durante
as partidas. Edite o construtor para mudanças permanentes na arquitetura.

## Sincronizar e compilar

Instale Rojo **7.7.1**. Na raiz do repositório:

```sh
rojo serve default.project.json
```

Conecte o plugin Rojo no Studio. Use um place de teste separado para evitar
sobreposição com mapas antigos preservados no seu Workspace.
Se o servidor Rojo já estava aberto antes do Pull, encerre-o e inicie novamente
com o comando acima; depois reconecte o plugin para carregar o perfil novo.

Python padrão basta para gerar/verificar; no Windows, `py` pode substituir `python`:

```sh
python scripts/build_k17.py
python scripts/build_k17.py --check
python scripts/build_k17_barricades.py --check
python scripts/validate_k17.py --quiet
python scripts/validate_refuges.py
python -m unittest discover -s tests -p 'test_*.py'
rojo build default.project.json --output builds/ZombieOutbreakReborn_K17.rbxl
python scripts/check_studio_file.py --write
```

A CI compila e disponibiliza um artifact atualizado do place. As imagens são
prévias geométricas do modelo: não representam materiais, iluminação ou gameplay
renderizados pelo Roblox Studio.

## Estado de validação

**Executado na nuvem:** geração, compilação Luau/Rojo, 189 percursos com 34.927
amostras de apoio/espaço livre, 15 testes de geometria, 160 asserções do combate/
rodada, testes de execução dos controladores com APIs simuladas, 198 da política de impulso e 85 das regras de barricadas preservadas. Verificação das fontes ativas
no place. Os percursos também foram checados com os 40 objetos presentes.

**Pendente no Studio:** Humanoid, navegação real, aparência, FPS/streaming,
controles/colisões das barricadas, multiplayer e equilíbrio. Ainda não se afirma qualidade visual equivalente ao
Counter-Strike ou desempenho aprovado.

Durante Play, na Command Bar em contexto **Server**:

```lua
require(game.ServerStorage.ZO_Validation.K17Audit)()
```

Envie as linhas `[K17 AUDIT]` e os erros do Output para investigar falhas.
A navegação calculada não substitui caminhar pelos acessos nem testar com jogadores.

## Mapa anterior preservado

Santa Aurora continua disponível, sem alteração em seu modelo, gerador ou build:

```sh
rojo serve santa-aurora.project.json
```

Ou abra `builds/ZombieOutbreakReborn_SantaAurora.rbxlx` diretamente.
O projeto anterior está no commit `63b3546` e na branch de backup
`backup/before-k17-63b3546`. A documentação histórica que menciona
`default.project.json` para Santa Aurora deve usar o perfil preservado acima.

Os GLBs e modelos antigos permanecem no histórico e não são carregados no K-17.
O Rojo preserva instâncias desconhecidas no Workspace: sincronizar sobre um
place antigo pode manter os dois cenários. Abra o arquivo K-17 separado para
validar sem apagar seu mapa anterior.
