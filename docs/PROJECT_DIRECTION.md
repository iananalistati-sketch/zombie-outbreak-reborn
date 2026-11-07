# Direção do Zombie Outbreak Reborn

Decisão de 06/11/2026, após autorização do usuário para assumir direção,
arquitetura e implementação. O usuário participa das validações no Roblox;
decisões técnicas rotineiras pertencem ao desenvolvimento.

## Produto

O usuário reafirmou após a validação da 0.2 que o jogo deve se basear no Zombie
Escape e Zombie Survival/Mod do Counter-Strike. Esse é o núcleo obrigatório:
preparação curta, primeira infecção, humanos armados, zumbis que infectam por
ataque e defesa com contenção e barricadas físicas. Survival vence por resistir
ao relógio; Escape exige objetivos de mapa e extração. Os zumbis precisam criar
pressão real sem perder movimento de forma acumulativa a cada tiro.

Um jogo legível e responsivo vem antes de aumentar o número de armas e mapas.
O conteúdo visual deve ter proporções, função, entradas e rotas coerentes. Não
usar novos placeholders de armas para preencher um catálogo.

## Decisões de arquitetura

- **Projeto principal:** `iananalistati-sketch/zombie-outbreak-reborn`, branch
  main. `zombie-outbreak-fps-lab` fica como arquivo da pesquisa descartada.
- **Base de runtime:** núcleo próprio já disponível com dano/economia/infecção
  no servidor e modelos oficiais revisados. Reutilizar componentes úteis com
  suas licenças; não importar um motor grande apenas por ser anunciado como CS.
- **Primeira execução sem configuração de backend:** sem DataStores, HTTP,
  listas de autorização ou bans automáticos para iniciar uma partida.
  Texturas, meshes e sons continuam sendo conteúdo hospedado no Roblox.
- **Movimento inicial:** Humanoid nativo; somente uma autoridade compõe postura
  e contenção temporária. O controlador Source experimental fica fora do build.
- **Estado multiplayer:** Waiting → Training (um jogador) ou Intermission →
  Preparation → Active → Results. Só o servidor escolhe infectados, aplica
  dano, controla munição/créditos e determina resultados.
- **Treino:** servidor de um jogador oferece três ondas curtas com perseguição,
  ataque, abates e reinício. A segunda conexão revoga o treino imediatamente.
  Seu progresso é de sessão, não ranking ou progressão persistente.
- **Modos:** rotação Escape → Survival. Round controla todo o ciclo e possui
  EscapeSession como sessão subordinada; não há segundo controlador de rodada.
- **Conteúdo atual:** K-17, quatro classes de armas reais, seis acabamentos,
  175 objetos físicos, 36 refúgios e uma rota de evacuação com três objetivos.

## Entregas e aceitação

### 0.1 — Primeira sessão e ciclo completo

Entrar por ABRIR_JOGO.cmd e usar Play. O HUD identifica a versão. Sozinho, o
jogador recebe armas, pode explorar e comprar, enfrenta ondas e recomeça após
vitória/morte. Com dois clientes, ocorre preparação, escolha do infectado,
combate, infecção, resultado e nova rodada. Física, aparência e áudio precisam
ser observados no Studio antes de declarar essa etapa aprovada.

### 0.2 — Combate e apresentação

Pacote implementado: HUD compacto com munição/vida/recarga/localização, placar
de sessão, confirmação de abate, registro de infecção e alerta de dano. Inclui
resistência contextual de barricadas, golpes de NPCs em obstáculos e sinalização
dos refúgios, além do acabamento do térreo da administração. Sem trocar motor,
repositório ou arquivo de abertura. [Entrega e aceite](RELEASE_0_2.md).

Conferir no motor legibilidade, combate durante a defesa, mira/troca/recarga e
movimento visto por observadores. Os contadores são de sessão e os abates do
treino ficam separados dos de jogadores. A revisão visual completa do arsenal
e a expansão de classes continuam nas próximas entregas.

### 0.3 — Zombie Escape e Survival

Pacote implementado: rotação dos modos, três objetivos sequenciais com tempos
de defesa, portão, janela de extração e desfecho de descontaminação. Inclui
marcadores no mundo/mapa, HUD por objetivo, terminal coberto, seis novos objetos
físicos e compra de munição durante Escape com créditos. O treino permanece
separado dos modos multiplayer. [Entrega e aceite](RELEASE_0_3.md).

Conferir no motor perseguição, interação dos painéis, acessos do subterrâneo,
defesa do terminal e o ciclo completo de ambos os modos. A rota desta entrega
aproveita a arquitetura original do K-17; o desenho mais linear de um próximo
mapa ZE deve evoluir a partir dessa validação.

### 0.4 — Defesa e acompanhamento da partida

Pacote implementado: retenções na saída da estação elétrica e subida de
manutenção, fechamento com consulta de ocupação, posição protegida no gerador
com cinco props, placas nos acessos e orientação por trechos do percurso.
Inclui espectador com filtro de equipe, troca de alvo, prazo de retorno e
restauração de câmera/zoom. O servidor bloqueia movimento do Lobby durante a
rodada e limpa a restrição antes de esperar outra partida/treino.
[Entrega e aceite](RELEASE_0_4.md).

### 0.5 — Armas, impactos e resultado

Pacote implementado: braços reais R6/R15 em primeira pessoa, recarga visual por
classe com movimento do carregador e bomba da escopeta, impactos por material
e resumo pessoal da rodada. Corrige apresentação da arma no treino público.
O servidor conta disparos aceitos e vida efetivamente removida; o treino não
contamina o resumo multiplayer. [Entrega e aceite](RELEASE_0_5.md).

Validar aparência e alinhamento R6/R15, cancelamento de recarga, apresentação
vista por outro cliente e os resultados completos de Escape e Survival. Não
houve expansão do catálogo nem substituição do motor nesta entrega.

### Próximas entregas — Conteúdo e desempenho

Evoluir o arsenal revisado, simplificar loja, melhorar navegação e áudio ambiental, medir física e
renderização no motor e só então habilitar persistência de progresso. Integrar
serviços com falha tolerada: uma indisponibilidade não pode impedir jogar.

## Regra de entrega

As entregas ao usuário devem reunir várias melhorias perceptíveis em um pacote
coerente, com objetivo jogável e roteiro curto de validação. As etapas acima
organizam o trabalho interno; não exigem uma interrupção para teste a cada
objeto, arma ou ajuste mínimo. Agrupar combate, cenário e apresentação quando
contribuírem para a mesma experiência. Correções urgentes podem sair isoladas
para desbloquear uma falha que impede jogar.

Cada entrega inclui o arquivo nativo atualizado, checksum, fontes ativos
conferidos e instrução curta de teste. Compilar ou usar APIs simuladas não
equivale a executar Roblox Studio. Backup antes de alterações importantes.
Uma falha no motor volta para correção na mesma arquitetura; não abre outro
ciclo de troca de bases sem diagnóstico concreto.
