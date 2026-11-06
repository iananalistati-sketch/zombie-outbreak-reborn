# Direção do Zombie Outbreak Reborn

Decisão de 06/11/2026, após autorização do usuário para assumir direção,
arquitetura e implementação. O usuário participa das validações no Roblox;
decisões técnicas rotineiras pertencem ao desenvolvimento.

## Produto

Zombie Survival inspirado no ritmo de Zombie Mod de CS e na atmosfera de Left
4 Dead: preparação curta, infecção imprevisível, defesa de posições, rotas de
fuga e barricadas físicas. O objetivo é sobreviver ao relógio; o zumbi precisa
criar pressão real sem perder movimento de forma acumulativa a cada tiro.

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
- **Conteúdo inicial:** K-17, quatro classes de armas reais, seis acabamentos,
  164 objetos físicos e 34 refúgios existentes. Expansão só após aceitação.

## Entregas e aceitação

### 0.1 — Primeira sessão e ciclo completo

Entrar por ABRIR_JOGO.cmd e usar Play. O HUD identifica a versão. Sozinho, o
jogador recebe armas, pode explorar e comprar, enfrenta ondas e recomeça após
vitória/morte. Com dois clientes, ocorre preparação, escolha do infectado,
combate, infecção, resultado e nova rodada. Física, aparência e áudio precisam
ser observados no Studio antes de declarar essa etapa aprovada.

### 0.2 — Combate e apresentação

Conferir R6/R15, grip, mira, troca, recarga, sons e observadores. Ajustar recuo,
feedback e contenção com base em testes reais. Corrigir bugs reproduzidos antes
de incluir outra classe de arma. Melhorar o arsenal visual com assets auditados.

### 0.3 — Um setor do mapa em qualidade final

Refinar administração, acessos e posição de defesa como uma fatia completa:
duas aproximações, rota de escape, cobertura útil, objetos móveis, iluminação,
sinalização e ambientação. Testar o confronto humano/zumbi nesse setor antes
de repetir o padrão no restante do complexo.

### 0.4 — Interface, desempenho e progressão

Simplificar loja e HUD, melhorar navegação e áudio ambiental, medir física e
renderização no motor e só então habilitar persistência de progresso. Integrar
serviços com falha tolerada: uma indisponibilidade não pode impedir jogar.

### Posterior — Zombie Escape

Modo separado quando o Survival estiver aprovado. Objetivos, rotas e mapas
próprios; não misturar duas direções de jogo na primeira entrega.

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
