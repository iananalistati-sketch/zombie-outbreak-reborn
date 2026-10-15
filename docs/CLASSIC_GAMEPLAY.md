# K-17 — ajustes do ciclo clássico de Zombie Mod

Implementação original em Luau baseada nos comportamentos verificados em
[Zombie:Reloaded e nas comparações de CS2](CS_ZOMBIE_OPEN_SOURCE.md).
O objetivo desta etapa é corrigir combate, infecção e rodada; a aparência das
armas/garras continua provisória e não constitui reprodução visual do CS.

## Teste rápido com um jogador

1. No GitHub Desktop, selecione `main`, faça Fetch/Pull e salve seu place atual.
2. Abra novamente `builds/ZombieOutbreakReborn_K17.rbxl` em File → Open from File.
   Um place já aberto não é atualizado automaticamente pelo Pull.
3. Dê **Play**. Na Command Bar em contexto **Server**, execute:

```lua
require(game.ServerStorage.ZO_Validation.GameplayAudit).practice("Humans")
```

Você vai ao estoque do depósito e recebe um alvo zumbi parado à frente.

- **Segure o botão esquerdo**: o rifle deve disparar continuamente, com munição
  limitada. O alvo tem vida de zumbi e recebe dano e impulso ao ser atingido.
- **R**: a recarga deve levar **2,4 segundos**. Tiros ficam bloqueados durante
  a recarga; a munição só entra no carregador ao terminar.
- Esvazie o carregador: disparos adicionais não devem causar dano.
- Repita o comando para repor munição e recriar o alvo.

Para testar a infecção:

```lua
require(game.ServerStorage.ZO_Validation.GameplayAudit).practice("Zombies")
```

Surge um alvo humano à frente. O golpe de **clique esquerdo** deve convertê-lo
em zumbi quando a mira acerta e o alvo está ao alcance. O alvo muda de cor e
nome; aparece a confirmação `INFECÇÃO`. Aproxime-se se estiver longe.
Segurar o clique repete os golpes respeitando a cadência.

O treino só funciona no Studio, com um jogador, enquanto a rodada está esperando.
O HUD o identifica como treino solo. O alvo não tem IA. Ele serve para testar
inputs, dano e conversão; não substitui um adversário humano. Com dois jogadores,
a exceção de treino é ignorada e os alvos são removidos ao preparar a rodada.

No controle: RT ataca, X recarrega. Há botões de toque para essas duas ações;
os controles e a legibilidade ainda precisam ser testados nos dispositivos.

## O que mudou

| Antes | Agora |
| --- | --- |
| Proximidade com raycast infectava automaticamente | Exige um ataque de zumbi que acerte; o servidor faz o raycast de alcance curto e respeita o primeiro obstáculo |
| Primeiro infectado sempre ia ao spawn zumbi | Transformação no local por padrão; `MotherZombieTeleport` permite outra variante |
| Seleção antes da preparação terminar | Seleção entre humanos vivos no final da preparação; evita repetir os primeiros infectados da rodada anterior quando há alternativas |
| Rifle disparava por clique | Disparo contínuo enquanto o gatilho está pressionado |
| Recarga instantânea | Recarga de 2,4 s com conclusão, cancelamento e transferência de munição no servidor |
| Impulso fixo para corpo/cabeça | Impulso relacionado a dano, arma, região atingida, classe e estado no ar, com limite máximo |
| Ataque de barricada separado da infecção | Um comando de golpe, um alcance e uma cadência no servidor para acertar humanos ou objetos |
| Humano podia morrer e voltar humano durante a rodada | Morte durante a fase ativa converte o papel para zumbi; respawn mantém o papel |
| Interface de prévia de construção | Desativada no perfil clássico; R funciona como recarga |

## Parâmetros iniciais

- Mínimo de dois jogadores; intervalo 12 s; preparação 35 s; rodada 240 s.
- Primeiros infectados: `floor(vivos / 7)`, com mínimo de um e pelo menos um
  humano restante. Seleção aleatória, com preferência por não repetir mães.
- Vida humana 100; zumbi 450; velocidades 16 e 19 studs/s; respawn 5 s.
- Rifle: 30 no carregador, 120 na reserva, intervalo mínimo de 0,105 s e alcance
  de 280 studs. Dano de corpo 22; cabeça 44; braços e pernas têm fatores próprios.
- Golpe: alcance de 6 studs a partir da cabeça, intervalo mínimo de 0,7 s.
- Humanos podem atirar/recarregar durante a preparação e a fase ativa. Zumbis
  atacam na fase ativa. Morte, infecção e fim de fase cancelam recargas pendentes.
- Zumbis mortos continuam contabilizados enquanto aguardam respawn. Humanos
  vencem ao sobreviver ao temporizador; zumbis vencem quando não restam humanos.
  A rodada é cancelada quando faltam participantes ou zumbis.

São parâmetros Roblox iniciais, não valores Source convertidos nem balanceamento
aprovado. O modelo do rifle, garras e efeitos são próprios/provisórios. Não foram
importados código, animações, sons ou assets dos repositórios examinados.

## Barricadas nesta etapa

Os cinco objetos do estoque continuam ancorados e destrutíveis, com restauração
na preparação seguinte. **Ainda não há barricadas com física equivalente ao CS.**
Não é possível selecioná-los com E no perfil padrão: o protótipo anterior foi
preservado com `EnablePlacement=false`. As resistências antigas continuam como
configuração experimental desses cinco objetos, sem alegação de serem regras
de Zombie:Reloaded. O golpe novo pode destruí-los; tiros humanos são bloqueados
por eles, sem danificá-los.

## Validação

Executado na nuvem:

- Compilação Luau e execução de **160 asserções** dos módulos reais de política,
  seleção/vitória e estado da arma: cadência, munição, conclusão/cancelamento de
  recarga, entrada inválida, papéis, fases, seleção e fatores de knockback.
- **85 asserções** preservadas do protótipo de posicionamento; não significam
  que esse protótipo esteja habilitado no jogo.
- Oito testes de geometria, geração determinística, 175 percursos com 33.341
  amostras, incluindo a disposição inicial dos objetos.
- Build Rojo XML/binário. Verificação de nove fontes exatas, funções privadas
  de servidor e carregamento de um único controlador novo de rodada/combate.
  O perfil K-17 não carrega os controladores antigos de infecção por proximidade.
- Perfil Santa Aurora recompilado separadamente, com seus arquivos, scripts
  compartilhados e arquitetura preservados nesta mudança.

Esses testes não executam o motor Roblox. **Pendente no Studio:** precisão da
mira, inputs, rigs, animações, impulso real, colisões, latência, streaming, FPS e
rodadas multiplayer. Não há conexão com o Studio do usuário nesta sessão.

Auditoria de integração preparada, durante Play em contexto **Server**:

```lua
require(game.ServerStorage.ZO_Validation.GameplayAudit).run()
```

São 11 verificações preparadas de carregamento, eventos, funções de servidor,
configuração, passagem aberta e parede bloqueando raycast. Ainda não foram
executadas aqui. As auditorias antigas de mapa e objetos continuam disponíveis.

## Teste com dois clientes

1. Inicie servidor local com dois jogadores. Na preparação ambos são humanos e
   podem atirar; ao terminar um deve se transformar onde está, guardando o rifle.
2. Aproxime os personagens e aguarde sem clicar: ninguém deve ser infectado.
3. Como zumbi, ataque longe e através de parede/vidro: não deve infectar. Perto,
   com mira no humano e passagem livre, um golpe deve converter a vítima.
4. Como humano, segure o gatilho para conter o zumbi. Confira corpo/cabeça,
   tiros no ar, carregador vazio e recarga. Não deve haver tiros durante a recarga.
5. Comece uma recarga e seja infectado ou morra: não deve concluir depois da
   mudança de papel. Na rodada seguinte a munição deve ser restaurada normalmente.
6. Mate um humano por dano do cenário durante a fase ativa: ele deve aguardar
   respawn e retornar como zumbi. Mate um zumbi: ele deve retornar como zumbi.
7. Termine por infecção do último humano e, numa rodada separada, por tempo de
   sobrevivência. Confira cancelamento ao desconectar um dos dois participantes.
8. Repita duas rodadas; confira seleção inicial sem repetição consecutiva,
   restauração dos objetos, munição e ausência de inputs antigos de construção.

## Fontes e compilação

`src/maps/k17/gameplay/`: Config, Rules, WeaponState e RoundRules; autoridades
Round/Combat; controles/viewmodels Weapons e HUD. `default.project.json` mapeia
explicitamente esses arquivos. Santa Aurora continua usando os controladores
anteriores em `src/server` e `src/client`.

```sh
luau tests/gameplay/rules.spec.luau
rojo build default.project.json --output k17-validation.rbxlx
python scripts/validate_gameplay.py --place k17-validation.rbxlx
rojo build default.project.json --output builds/ZombieOutbreakReborn_K17.rbxl
```

Backup anterior: commit `48651bb`, branch `backup/before-classic-combat-48651bb`.
