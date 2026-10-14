# Zombie Outbreak Reborn

Survival multiplayer em Luau para Roblox Studio, sincronizado com **Rojo 7.7.1**.

## Mapa ativo: Distrito Santa Aurora

Um quarteirão urbano de serviços com arquitetura conectada:

- **Mercearia Aurora:** loja mobiliada, caixa, estoque e saída lateral.
- **Administração:** escritórios no segundo andar, escada interna e escada de incêndio.
- **Oficina Luz:** garagem, recepção, bancada e acessos de serviço.
- **Armazém Ferrovia:** área de carga, estantes e mezanino com duas escadas.
- Rua com calçadas, faixa de pedestres, drenagem, iluminação e estacionamento.

O mapa usa objetos nativos do Roblox e materiais do motor. **Aparece fora de Play
e não exige importar GLB**, buscar modelos no Toolbox ou publicar meshes.
As janelas têm vidro com colisão; portas e acessos são vãos reais.

[Planta e documentação](docs/SANTA_AURORA.md) · [Planta do térreo](docs/SANTA_AURORA_PLAN.svg)

## Abrir no Windows sem Codex local

1. No GitHub Desktop, use **Fetch origin**, selecione a branch
   `feat/santa-aurora-urban-map` e faça Pull se houver atualização.
   Preserve suas alterações locais antes de trocar de branch.
2. No Roblox Studio, salve uma cópia do seu place atual como backup.
3. Use **File → Open from File** para abrir
   `builds/ZombieOutbreakReborn_SantaAurora.rbxlx` da pasta do repositório.
4. Em Explorer, selecione `Workspace → ZO_SantaAurora` e pressione **F**.
5. Faça Play para explorar; use teste local com **dois jogadores** para iniciar rodadas.

Esse arquivo já contém o mapa, a iluminação e os scripts. Abra-o como place de
teste separado: ele não precisa ser importado como modelo nem publicado por cima
do jogo existente.

O arquivo em `builds/` é uma compilação desta entrega. Depois de editar os scripts,
recompile com Rojo ou use a sincronização para ver as alterações.

## Sincronizar com Rojo

No terminal, na raiz do repositório:

```sh
rojo serve default.project.json
```

Conecte o plugin Rojo no Studio ao servidor local. O Codex desktop não é
necessário. **Antes de sincronizar em um place antigo**, faça backup e mova os
mapas antigos para ServerStorage, incluindo `HarborLocks_Survival_Visual`,
`ZO_HarborCollision`, `ZO_Survival` e `ZO_TestSpawns`, caso existam.
O projeto preserva objetos desconhecidos no Workspace; ele não apaga suas
importações automaticamente.

## Compilar e verificar

Python padrão e Rojo 7.7.1:

```sh
python scripts/build_santa_aurora.py --check
rojo build default.project.json --output builds/ZombieOutbreakReborn_SantaAurora.rbxlx
python scripts/validate_santa_aurora.py --place builds/ZombieOutbreakReborn_SantaAurora.rbxlx
```

No Windows, `py` pode substituir `python`. Para mudar a arquitetura, edite
`scripts/build_santa_aurora.py` e execute-o sem `--check` antes de recompilar.
Não edite o modelo gerado esperando que as mudanças sobrevivam à regeneração.

**Validação na nuvem:** compilação Luau e Rojo; 14 percursos conferidos contra as
colisões do modelo. **Ainda pendente:** física Humanoid, PathfindingService,
qualidade visual, FPS e multiplayer no Roblox Studio.

Durante Play, na Command Bar em contexto **Server**:

```lua
require(game.ServerStorage.ZO_Validation.SantaAuroraAudit)()
```

A auditoria imprime `[ZO AUDIT]` com resultados de spawn, portas/paredes e
navegação. Veja o [roteiro de teste](docs/SANTA_AURORA.md) para inspeção manual.

## Código e arquivos anteriores

- `src/server`, `src/client`, `src/shared`: sistemas Luau existentes e configuração.
- `src/maps/santa-aurora`: modelo do mapa ativo.
- `tests/studio`: auditoria executável no Studio.
- `assets/maps`, `third_party` e os modelos antigos em `src/maps`: histórico
  preservado; não são carregados pelo projeto ativo.
- Fontes/licenças do Harbor anterior: [HARBOR_LOCKS_SOURCES.md](docs/HARBOR_LOCKS_SOURCES.md).

O projeto anterior foi preservado antes da edição; base Git:
`34b08175968a5420e35229037b64bb7ca933110b`.
