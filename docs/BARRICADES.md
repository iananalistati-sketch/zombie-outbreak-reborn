# Estoque do depósito — primeira defesa interativa

> **Documento histórico do protótipo `65fad8b`.** A prévia e seus controles de
> posicionamento estão desativados no perfil atual. O ataque agora é unificado
> com a infecção por golpe. Para testar a versão atual, use
> [Ciclo clássico de Zombie Mod](CLASSIC_GAMEPLAY.md). As instruções de E/R/X
> abaixo descrevem o protótipo preservado, não o padrão atual.

O esconderijo **07**, no térreo do setor **D**, recebeu cinco objetos modelados:
dois armários metálicos, uma mesa de oficina tombada e duas caixas industriais.
A porta do corredor e o acesso pela sala vizinha continuam utilizáveis. A mudança
é uma primeira versão jogável para testar esse ciclo antes de repetir pelo mapa.

## Abrir e experimentar sozinho

1. No GitHub Desktop, use **main → Fetch origin → Pull origin**.
2. Faça backup do seu place e abra `builds/ZombieOutbreakReborn_K17.rbxl` no Studio.
3. Dê **Play**. Na **Command Bar**, em contexto **Server**, execute:

```lua
require(game.ServerStorage.ZO_Validation.BarricadeAudit).practice("Humans")
```

O comando leva você ao estoque, habilita o treino e escolhe o papel humano.
Só funciona no **Studio**, com **um jogador**, enquanto a rodada está aguardando.
O HUD de rodada continuará mostrando a espera. Rifle e infecção continuam
dependendo da partida normal; o treino é específico das barricadas.

- Mire no objeto e pressione **E** para selecionar.
- Mire no chão: a prévia verde indica uma posição aceita pelas consultas locais;
  vermelha indica obstáculo, falta de apoio ou limite da área. O servidor decide.
- **R** gira 90 graus; **E** confirma; **X** cancela.
- Reposicione em etapas curtas. Para virar perto de uma porta, gire primeiro
  na área livre: a rotação exige espaço para a diagonal completa do objeto.

Para experimentar os golpes, no mesmo Play e na Command Bar **Server**:

```lua
require(game.ServerStorage.ZO_Validation.BarricadeAudit).practice("Zombies")
```

Aproxime-se, mire no objeto e **clique ou segure o botão esquerdo do mouse**.
**Stop → Play** restaura os objetos para repetir o treino.

No controle: **X** seleciona/confirma, **Y** gira, **B** cancela e **RT** golpeia.
Há botões de toque para essas ações. A compatibilidade completa de rifle/UI com
controle e celulares ainda precisa de trabalho e teste no dispositivo.

## Comportamento nesta versão

O objeto **permanece sólido na posição original durante a prévia**. Confirmar
uma posição válida move o modelo inteiro de uma vez; cancelar não desloca nada.
Não há arrasto com física livre. Isso evita tremores de peças e evita tornar
uma barricada invulnerável ou invisível enquanto alguém a reposiciona.

Somente humanos vivos podem montar a defesa, na preparação ou durante a rodada.
A seleção reduz a velocidade para 10 studs/s e guarda o rifle. Um objeto pode
ser selecionado por um sobrevivente por vez; é liberado ao cancelar, confirmar,
afastar-se, morrer, trocar de equipe, sair ou após 25 segundos.

O servidor valida alcance, papel, fase da rodada, linha de visão, posse, rotação,
limites da sala, colisão, presença de jogadores, piso e trajeto. Não permite
empilhar nem levar os objetos a outros andares. A movimentação fica restrita ao
estoque e às soleiras das suas duas entradas. Barricadas podem fechar uma porta:
os zumbis podem quebrá-las e também atacar pelo flanco.

| Objeto | Quantidade | Vida | Golpes de zumbi |
| --- | ---: | ---: | ---: |
| Armário metálico | 2 | 360 | 8 |
| Mesa tombada | 1 | 225 | 5 |
| Caixa industrial | 2 | 180 | 4 |

Cada golpe causa 45 de dano, com intervalo mínimo de 0,7 s, alcance de 7 studs
até a superfície e linha de visão validada no servidor. Essas são configurações
iniciais, **não balanceamento aprovado**. Ao destruir, o objeto deixa de bloquear
movimento, tiro e consultas. Os cinco objetos são restaurados no começo da
preparação seguinte. Tiros humanos são bloqueados por objetos sólidos e não
destroem as barricadas. A infecção existente continua funcionando por proximidade
com linha de visão; o golpe novo serve para destruir esses objetos.

A preparação do K-17 passou de 10 para **35 segundos**, para deslocamento e defesa.
As demais posições do mapa e as barricadas antigas de madeira continuam estáticas.

## Validação e roteiro multiplayer

Executado na nuvem:

- Compilação dos scripts e execução de **85 asserções** no módulo real de regras:
  alcance, limites, rotação, estados, papéis, morte, entradas inválidas/NaN/infinito
  e restrições do treino solo.
- **Oito testes Python**: modelos/colisões reais, apoio, ausência de sobreposição,
  circulação com os objetos e controles negativos que bloqueiam portas/túneis ou
  removem piso. Todos os 175 percursos e as 15 defesas continuam livres na
  disposição inicial dos objetos.
- Geração determinística dos modelos, compilação Rojo XML/binária e checagens
  de presença dos sistemas. O gerador original de arquitetura não foi alterado.

Não executado aqui: APIs físicas do Roblox, controles, streaming, cooperação,
latência, renderização, FPS e equilíbrio. A prévia local não substitui a
validação do servidor e pode divergir quando outro jogador move um objeto.

Antes de mover os objetos, faça Play e rode em **Server**, permanecendo longe deles:

```lua
require(game.ServerStorage.ZO_Validation.BarricadeAudit).run()
```

São 19 verificações preparadas de carregamento, colisão/apoio dos cinco objetos
e rejeição de parede/altura sem piso. Ainda precisam ser executadas no Studio.

Depois teste com dois clientes, sem ativar o treino solo:

1. Na preparação, vá ao depósito. Para acelerar o teste, teleporte cada personagem
   pelo servidor para posições livres próximas ao estoque, mantendo-os separados.
2. Dois humanos tentam selecionar o mesmo objeto: somente um deve conseguir.
3. Posicione armários na porta do corredor, deixando a sala vizinha acessível.
4. Tente colocar dentro de parede, jogador, outro objeto, no ar ou sobre caixa.
   Todos devem ser rejeitados; tente também atravessar uma parede ao mover/girar.
5. Após a infecção inicial, zumbi tenta golpear de longe ou através da parede:
   não deve causar dano. Perto e com visão livre, destrua uma caixa com quatro golpes.
6. Confirme que o humano perde a seleção ao ser infectado e que não consegue
   atirar durante a seleção. Confira libertação ao morrer e desconectar.
7. Quebre uma defesa, atravesse a entrada e teste infecção dos sobreviventes.
8. Termine a rodada. Na preparação seguinte, confira posições, vida, colisões e
   disponibilidade restauradas, repetindo por pelo menos duas rodadas.

Envie os erros do Output e as linhas `[BARRICADE AUDIT]` para investigar problemas.

## Fontes

- `src/maps/k17/barricades/Server.server.luau`: autoridade, seleção, dano e reset.
- `Client.client.luau`: controles, prévia, destaque e interface.
- `Config.luau`: catálogo, vida, área permitida e parâmetros.
- `Rules.luau`: regras puras, exercitadas pelo Luau CLI.
- `Placement.luau`: consultas de colisão, apoio e deslocamento.
- `Stockroom.rbxmx`: modelos persistentes, editáveis no Studio fora de Play.
- `scripts/build_k17_barricades.py`: construção dos modelos; não reescreve o mapa.
- `tests/k17/BarricadeAudit.luau`: auditoria e treino Studio.

Ao alterar as dimensões ou posições iniciais, atualize também o catálogo e o
gerador. O servidor interrompe a inicialização se as medidas divergirem.

```sh
python scripts/build_k17_barricades.py
python scripts/build_k17_barricades.py --check
python -m unittest discover -s tests -p 'test_*.py'
luau tests/barricades/rules.spec.luau
rojo build default.project.json --output builds/ZombieOutbreakReborn_K17.rbxl
```

Backup anterior à mudança: commit `352ce55`, branch
`backup/before-barricades-352ce55`. Santa Aurora mantém seu perfil e sua construção;
o rifle compartilhado recebeu apenas a proteção de seleção e o ajuste de câmera
condicionado ao K-17. O combate compartilhado bloqueia disparos durante seleção.
