# Zombie Outbreak Reborn — versão 0.4

Zombie Escape e Zombie Survival/Mod baseados no Counter-Strike: preparação,
infecção por ataque, contenção por tiros, barricadas físicas e rodadas multiplayer.
[Pacote 0.4 e validação](docs/RELEASE_0_4.md) ·
[Direção e próximas entregas](docs/PROJECT_DIRECTION.md).

**Projeto principal:** `iananalistati-sketch/zombie-outbreak-reborn`, branch
**main**. O repositório `zombie-outbreak-fps-lab` permanece como pesquisa
arquivada. O arquivo CounterBlox_CS não é esta versão do produto.

## Abrir e testar

1. No GitHub Desktop, selecione **zombie-outbreak-reborn → main**.
2. Faça **Fetch origin → Pull origin**, salve e feche o place anterior.
3. Abra **ABRIR_JOGO.cmd** e execute **Play** no Studio. O HUD deve mostrar
   **ZOMBIE OUTBREAK / v0.4.0** no canto inferior direito.

Não é necessário configurar HTTP, API Services, DataStore ou uma whitelist.
A primeira sessão usa somente o conteúdo embarcado e serviços normais de
personagem/assets do Roblox. Meshes, texturas, sons e o avatar continuam
dependendo de disponibilidade e permissões da plataforma.

## O que testar nesta versão

- **Defesa durante Escape:** a saída da estação elétrica e a subida de manutenção
  entram em retenção durante as respectivas defesas. Uma porta ocupada por
  personagem ou objeto aguarda passagem livre para fechar. O fim da defesa,
  resultado ou cancelamento libera a passagem.
- **Orientação e cobertura:** o marcador aponta para o próximo acesso da rota,
  com indicação de subir/descer. Há novas placas no subterrâneo e uma posição
  protegida junto ao gerador, com cinco objetos móveis.
- **Espectador:** mortos e jogadores que chegam com a rodada em andamento
  acompanham zumbis vivos. Setas esquerda/direita, L1/R1 ou botões trocam o alvo
  quando há mais de um. O retorno ao personagem restaura a câmera. Teste com
  três clientes para ter um zumbi vivo para observar enquanto outro renasce.
- **Zombie Escape:** com dois clientes, a primeira rodada é Escape. Siga o
  marcador e acione os três painéis em sequência: gerador, bombas subterrâneas
  e portão. Defenda os tempos de 12, 15 e 20 segundos. O portão abre uma janela
  de 18 segundos; humanos vivos dentro do terminal ao final escapam. O timeout
  geral sem extração dá vitória aos zumbis. **B → Munição** permite reabastecer
  reservas com créditos durante Escape; armas novas são compradas na preparação.
- **Zombie Survival/Mod:** a rodada seguinte mantém o confronto por infecção
  e defesa de posições. Humanos vencem resistindo ao relógio; zumbis vencem
  convertendo os humanos. A rotação segue Escape → Survival → Escape.
- **Interface e combate:** HUD compacto com vida, munição, recarga e localização;
  avisos de fase, confirmação de abate e registro de abates/infecções. **Tab**
  abre o placar de sessão; há botão na tela e D-pad esquerdo no controle.
- **Defesa:** mire em uma barricada próxima para conferir sua resistência.
  Os infectados do treino tentam golpear objetos que bloqueiam seu caminho.
  Placas nas entradas identificam refúgios; o térreo da administração recebeu
  faixas de circulação, sinalização e acabamento de instalações/janelas.
- **Sozinho:** o treino começa automaticamente. Após cinco segundos entram
  infectados que perseguem e atacam. São três ondas de 3, 4 e 5 inimigos,
  com até três ativos simultaneamente. Vitória ou morte levam a nova tentativa.
- **Combate:** clique dispara; botão direito mira; R recarrega; 1/2 ou Q trocam
  slots; B abre o arsenal. Há rifle, pistola, SMG e escopeta com modelos reais.
  Abates no treino concedem créditos de sessão para experimentar o arsenal.
- **Multiplayer:** em Server & Clients, inicie dois clientes. O treino sai,
  ocorre intervalo/preparação, e um jogador vira zumbi. Clique para golpear e
  infectar. Confirme resultado e troca de modo na próxima rodada.
- **Mapa:** M abre o mapa tático; explore interiores e posições defensivas.
  Atire nos objetos para movê-los e teste a recuperação do zumbi após tiros.

Shift corre; Alt caminha; Ctrl/C agacham. Compra é permitida no treino e na
preparação. O servidor mantém autoridade sobre munição, dano, créditos e
resultado. A versão não salva progresso entre sessões.

## Conteúdo e limites

K-17 tem interiores, vários andares, 36 refúgios, quatro dutos e 175 objetos de
barricada. Há quatro classes de armas e seis acabamentos adicionais. Os
modelos oficiais e componentes reutilizados têm licenças e procedência em
`third_party/`. O jogo usa primeira pessoa própria e movimento nativo Roblox.

O controlador Source experimental e os motores Counter Blox/Evostrike não
executam nesta versão. A progressão persistente fica para entregas posteriores.
O usuário informou ter realizado as validações da 0.1 e 0.2. As alterações da
0.4 precisam de validação real de câmera, navegação, física, interação e multiplayer no
Studio; compilar não equivale a jogar. O mapa K-17 é original e foi adaptado
para a primeira rota de evacuação. Equivalência completa à física Source
depende de ajustes no motor e testes, não é uma funcionalidade comprovada.

## Desenvolvimento

Fontes de gameplay em `src/maps/k17/gameplay/`; cenários e geração em `scripts/`.
Python 3, Rojo 7.7.1 e Luau 0.742 são as ferramentas de desenvolvimento.

```sh
python scripts/test_training.py --luau CAMINHO_DO_LUAU
python scripts/test_tactical_hud.py --luau CAMINHO_DO_LUAU
python scripts/test_escape.py --luau CAMINHO_DO_LUAU
python scripts/test_defense.py --luau CAMINHO_DO_LUAU
rojo build default.project.json --output builds/ZombieOutbreakReborn_K17.rbxl
python scripts/check_studio_file.py --write
```

O place de `SurvivalTest` é um cenário separado de validação com dois clientes,
não o jogo normal. O atalho verifica o checksum do build jogável. Backups e
histórico anterior permanecem disponíveis no Git.
