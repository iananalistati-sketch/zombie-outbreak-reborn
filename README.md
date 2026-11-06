# Zombie Outbreak Reborn — versão 0.1

Zombie Survival com preparação, infecção, defesa por barricadas, armas e
rodadas multiplayer. [Direção e próximas entregas](docs/PROJECT_DIRECTION.md).

**Projeto principal:** `iananalistati-sketch/zombie-outbreak-reborn`, branch
**main**. O repositório `zombie-outbreak-fps-lab` permanece como pesquisa
arquivada. O arquivo CounterBlox_CS não é esta versão do produto.

## Abrir e testar

1. No GitHub Desktop, selecione **zombie-outbreak-reborn → main**.
2. Faça **Fetch origin → Pull origin**, salve e feche o place anterior.
3. Abra **ABRIR_JOGO.cmd** e execute **Play** no Studio. O HUD deve mostrar
   **ZOMBIE OUTBREAK · v0.1.0**.

Não é necessário configurar HTTP, API Services, DataStore ou uma whitelist.
A primeira sessão usa somente o conteúdo embarcado e serviços normais de
personagem/assets do Roblox. Meshes, texturas, sons e o avatar continuam
dependendo de disponibilidade e permissões da plataforma.

## O que testar nesta versão

- **Sozinho:** o treino começa automaticamente. Após cinco segundos entram
  infectados que perseguem e atacam. São três ondas de 3, 4 e 5 inimigos,
  com até três ativos simultaneamente. Vitória ou morte levam a nova tentativa.
- **Combate:** clique dispara; botão direito mira; R recarrega; 1/2 ou Q trocam
  slots; B abre o arsenal. Há rifle, pistola, SMG e escopeta com modelos reais.
  Abates no treino concedem créditos de sessão para experimentar o arsenal.
- **Multiplayer:** em Server & Clients, inicie dois clientes. O treino sai,
  ocorre intervalo/preparação, e um jogador vira zumbi. Clique para golpear e
  infectar. Confirme resultado e início da próxima rodada.
- **Mapa:** M abre o mapa tático; explore interiores e posições defensivas.
  Atire nos objetos para movê-los e teste a recuperação do zumbi após tiros.

Shift corre; Alt caminha; Ctrl/C agacham. Compra é permitida no treino e na
preparação. O servidor mantém autoridade sobre munição, dano, créditos e
resultado. A versão não salva progresso entre sessões.

## Conteúdo e limites

K-17 tem interiores, vários andares, 34 refúgios, quatro dutos e 164 objetos de
barricada. Há quatro classes de armas e seis acabamentos adicionais. Os
modelos oficiais e componentes reutilizados têm licenças e procedência em
`third_party/`. O jogo usa primeira pessoa própria e movimento nativo Roblox.

O controlador Source experimental e os motores Counter Blox/Evostrike não
executam nesta versão. Zombie Escape e progressão persistente ficam para
entregas posteriores. A validação real de aparência, áudio, navegação, física
e multiplayer no Studio permanece pendente; compilar não equivale a jogar.

## Desenvolvimento

Fontes de gameplay em `src/maps/k17/gameplay/`; cenários e geração em `scripts/`.
Python 3, Rojo 7.7.1 e Luau 0.742 são as ferramentas de desenvolvimento.

```sh
python scripts/test_training.py --luau CAMINHO_DO_LUAU
rojo build default.project.json --output builds/ZombieOutbreakReborn_K17.rbxl
python scripts/check_studio_file.py --write
```

O place de `SurvivalTest` é um cenário separado de validação com dois clientes,
não o jogo normal. O atalho verifica o checksum do build jogável. Backups e
histórico anterior permanecem disponíveis no Git.
