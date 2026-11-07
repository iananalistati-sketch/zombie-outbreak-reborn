# Zombie Outbreak Reborn — versão 0.8

Zombie Escape e Zombie Survival/Mod baseados no Counter-Strike: preparação,
infecção por ataque, contenção por tiros, barricadas físicas e rodadas multiplayer.
[Pacote 0.8 e validação](docs/RELEASE_0_8.md) ·
[Direção e próximas entregas](docs/PROJECT_DIRECTION.md).

**Projeto principal:** `iananalistati-sketch/zombie-outbreak-reborn`, branch
**main**. O repositório `zombie-outbreak-fps-lab` permanece como pesquisa
arquivada. O arquivo CounterBlox_CS não é esta versão do produto.

## Abrir e testar

1. No GitHub Desktop, selecione **zombie-outbreak-reborn → main**.
2. Faça **Fetch origin → Pull origin**, salve e feche o place anterior.
3. Abra **ABRIR_JOGO.cmd** e execute **Play** no Studio. O HUD deve mostrar
   **ZOMBIE OUTBREAK / v0.8.0** no canto inferior direito.

Não é necessário configurar HTTP, API Services, DataStore ou uma whitelist.
A primeira sessão usa somente o conteúdo embarcado e serviços normais de
personagem/assets do Roblox. Meshes, texturas, sons e o avatar continuam
dependendo de disponibilidade e permissões da plataforma.

## O que testar nesta versão

- **Combate/FPS:** enquadramento por arma, recuo revisto e sensibilidade de mouse
  acompanhando a mira. Ao soltar a mira, abrir menu ou perder foco, o controle
  anterior é restaurado. Pistola e escopeta aceitam um clique até 120ms antes
  do fim do intervalo entre disparos; cancelar o controle descarta esse clique.
- **Resposta e munição:** contador visual responde ao tiro e se reconcilia com
  confirmações do servidor. A última bala não repete som/recuo indefinidamente
  enquanto a munição ainda está replicando. Dano e munição reais continuam no servidor.
- **Áudio e clarão:** oito referências públicas da Creator Store substituem
  os sons antigos nas quatro classes e acabamentos. Tiros sobrepõem até seis
  vozes; recarga acompanha a duração autorizada. Há um clarão curto no cano.
  A reprodução/permissão dos novos áudios ainda precisa do teste no Studio.
- **Play sozinho agora mostra Escape:** você começa perto do gerador. Após
  cinco segundos, siga o marcador, segure **E** junto ao painel e defenda.
  Atravesse até as bombas, depois até o terminal. Só entrar na área e concluir
  a janela de extração dá vitória; eliminar NPCs não substitui os objetivos.
- **Perseguição durante o percurso:** até quatro NPCs ativos, com dificuldade
  por setor, ataques e dano às barricadas. Pontos ocupados ou diretamente
  visíveis à frente são descartados. NPCs deixados muito longe são retirados
  sem conceder abates. O HUD identifica **ZE / TREINO SOLO**.
- **Fim de tarde e lanterna:** iluminação revisada e facho em primeira pessoa.
  **F**, D-pad direito ou botão de toque ligam/desligam. A lanterna é local,
  desliga ao morrer/espectar e não altera tiro, câmera ou física.
- **Travessia e perseguição:** no Escape, completar o gerador e alcançar o
  anel oeste libera retornos de zumbis na descida norte. Completar as bombas
  e alcançar o corredor sul libera o retorno na travessia das bombas. Só quem
  renasce usa esses postos; zumbis vivos continuam onde estão. Pontos próximos
  de humanos ou ocupados são descartados, com alternativa nos postos anteriores.
- **Dois abrigos subterrâneos:** **M → piso subterrâneo → 52/53**. A oficina do
  anel oeste e a câmara de válvulas têm dois acessos cada, recuo protegido,
  instalações próprias e seis objetos de barricada por sala.
- **Informação no cenário:** os três painéis distinguem bloqueado, disponível,
  defendendo e concluído pela cor do indicador. O terminal mostra a contagem
  real de extração e humanos na área. O HUD avisa quando a horda avança e indica
  ao zumbi o setor liberado para retorno.
- **Armas e recarga:** braços reais do avatar em primeira pessoa para R6 e
  R15. Rifle, SMG e pistola movimentam o próprio carregador durante a recarga;
  a escopeta movimenta a bomba após disparar. Trocar de arma durante a recarga
  deve restaurar o modelo. O R6 usa pose procedural; o R15 conserva os clips
  revisados. A arma nas mãos também aparece no treino solo.
- **Impactos:** metal, madeira, pedra/concreto, vidro e infectados recebem
  partículas distintas, usando a textura existente. Confira superfícies
  próximas e tiros rápidos; os efeitos têm limite e expiração.
- **Resultado da rodada:** painel pessoal com abates, infecções, objetivos,
  dano efetivo, precisão, bônus realmente recebido e saldo. O treino não entra
  nesses números. Feche pelo ×; a próxima rodada deve exibir dados novos.
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
- **Sozinho:** exercício de Escape com NPCs começa automaticamente, no mesmo
  mapa e com os mesmos objetivos/portões do modo multiplayer. Vitória, morte
  ou falha de extração levam a nova tentativa. O treino fica separado das
  estatísticas de rodadas e não consome a rotação Escape → Survival.
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

K-17 tem interiores, vários andares, 38 refúgios, quatro dutos e 187 objetos de
barricada. Há quatro classes de armas e seis acabamentos adicionais. Os
modelos oficiais e componentes reutilizados têm licenças e procedência em
`third_party/`. O jogo usa primeira pessoa própria e movimento nativo Roblox.

O controlador Source experimental e os motores Counter Blox/Evostrike não
executam nesta versão. A progressão persistente fica para entregas posteriores.
O usuário informou ter realizado as validações da 0.1 e 0.2. As alterações da
0.3–0.8 precisam de validação real de câmera, navegação, física, áudio e multiplayer no
Studio; compilar não equivale a jogar. O mapa K-17 é original e foi adaptado
para a primeira rota de evacuação. Equivalência completa à física Source
depende de ajustes no motor e testes, não é uma funcionalidade comprovada.

## Desenvolvimento

Fontes de gameplay em `src/maps/k17/gameplay/`; cenários e geração em `scripts/`.
Python 3, Rojo 7.7.1 e Luau 0.742 são as ferramentas de desenvolvimento.

```sh
python scripts/test_training.py --luau CAMINHO_DO_LUAU
python scripts/test_solo_escape.py --luau CAMINHO_DO_LUAU
python scripts/test_tactical_hud.py --luau CAMINHO_DO_LUAU
python scripts/test_escape.py --luau CAMINHO_DO_LUAU
python scripts/test_defense.py --luau CAMINHO_DO_LUAU
python scripts/test_combat_presentation.py --luau CAMINHO_DO_LUAU
rojo build default.project.json --output builds/ZombieOutbreakReborn_K17.rbxl
python scripts/check_studio_file.py --write
```

O place de `SurvivalTest` é um cenário separado de validação com dois clientes,
não o jogo normal. O atalho verifica o checksum do build jogável. Backups e
histórico anterior permanecem disponíveis no Git.
