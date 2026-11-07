# 0.6 — Travessia e pressão da infecção

Mesmo projeto/main, modos Counter-Strike Zombie Escape/Survival e abertura por
ABRIR_JOGO.cmd. Backup: `backup/before-traversal-v06-499d4c3`.

## O que muda na partida

Os infectados deixavam de pressionar a fuga porque renasciam sempre na
administração norte. Agora há três grupos de retorno, com três posições cada:

| Retorno | Liberação no Escape |
| --- | --- |
| Administração norte | Início da infecção |
| Descida norte, subterrâneo | Gerador defendido **e** humano vivo alcançou o anel oeste |
| Travessia das bombas | Bombas defendidas **e** humano vivo alcançou o corredor sul rumo à subida leste |

Somente participantes humanos vivos liberam setores. Espectadores, cadáveres
e alguém andando na superfície acima do túnel não contam. Os postos não
regridem dentro da rodada. Quem está vivo continua perseguindo de sua posição;
o avanço afeta apenas seleção inicial/renascimento, sem teleporte de perseguidores.

O servidor procura pontos do grupo mais recente, variando a posição de retorno.
Exige pelo menos 48 studs entre o centro de retorno e a raiz de cada humano
vivo, além de volume livre de corpos/props/arquitetura com colisão. Se necessário,
usa um grupo anterior. Todos bloqueados: o jogador espera no Lobby, ancorado,
protegido por ForceField invisível e sem atacar. Round retenta a cada 0,5s;
ao liberar espaço, remove sua proteção/âncora e devolve o controle. Mortes,
troca de personagem, saída e encerramento limpam a espera. Durante a espera,
o espectador acompanha um zumbi vivo disponível e exibe a situação.

## Mapa e sinalização

- **52 / Oficina do anel oeste:** sala acoplada ao túnel oeste, bancada de
  reparos, ferramentas e tubulação. Dois acessos espaçados no corredor e uma
  parede de retorno protegem o recuo; o segundo acesso permite flanquear.
- **53 / Câmara de válvulas:** sala junto ao corredor sul, entre as bombas e a
  subida leste, com manifold, válvulas e medidores. Dois acessos e abrigo atrás
  de uma parede transversal. O grupo precisa vigiar a entrada oposta.
- Cada sala tem quatro posições medidas para personagens e seis objetos
  móveis. Total: **38 refúgios, 187 props e quatro dutos**.
- O envelope, piso e teto fazem parte da rede subterrânea; não existem paredes
  antigas tapando a ligação. Rotas são verificadas também com os props nos
  pontos de origem, incluindo as alternativas de entrada e linhas de tiro.
- Indicadores: vermelho bloqueado, amarelo disponível, laranja defendendo,
  verde concluído. O painel dentro do terminal mostra o relógio de extração e
  humanos na área. O HUD humano anuncia o avanço da horda; o infectado vê o
  setor disponível. Resultado/Survival restauram sinais e limpam os postos.

O orçamento fica em **5.623 peças estáticas, 97 luzes e oito luzes com sombras**.
São 50 peças e duas luzes a mais que a 0.5. Isso não é uma medição de FPS.

## Validar o pacote

GitHub Desktop → **zombie-outbreak-reborn → main → Fetch/Pull origin**.
Salve/feche o cenário anterior e abra **ABRIR_JOGO.cmd**. Confira **v0.6.0**.

1. **Solo:** M abre o mapa. Selecione piso subterrâneo e refúgios 52/53.
   Entre por ambos os acessos, ocupe o recuo e use os objetos. Confira colisão,
   iluminação, escala e se ainda é possível flanquear após montar a defesa.
2. **Dois clientes, Escape:** defenda o gerador e avance pelo subterrâneo até
   o anel oeste. Veja o aviso e o setor no HUD do zumbi. Derrube-o e confira o
   retorno pela descida norte. Repita depois das bombas, avançando até o
   corredor sul, para conferir o segundo posto. Zumbi vivo não deve teleportar.
3. **Final e próxima rodada:** compare painel do terminal, HUD e extração.
   Na rodada Survival, não deve haver retorno avançado nem personagem preso
   na espera. Confira também câmera e controle após morrer/renascer.

## Verificação e limites

Testes executam a política e os controladores reais de Round, Escape, combate,
HUD, espectador e barricadas com APIs simuladas. Incluem retorno ocupado,
distância, alternativa, bloqueio de ataque, saída da espera e cancelamento.
Geometria valida conexão, apoio e volume de personagem nos nove pontos e nas
rotas dos abrigos, com controles negativos para portas tapadas e cobertura
removida. A build nativa e os fontes ativos são inspecionados por checksum.

Não houve execução no Studio local. Colisões reais, replicação, transição de
streaming entre setores, aparência, iluminação e balanceamento precisam do
teste no motor. Novas salas também funcionam em Survival e no treino solo;
os retornos por setor pertencem somente ao Escape.
