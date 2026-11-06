# 0.2 — Defesa tática e leitura do combate

O usuário informou a validação da 0.1 e autorizou prosseguir com entregas grandes.
Este pacote reúne apresentação, informação de combate, pressão sobre barricadas
e orientação no cenário. A base de Survival, servidor e arquivo de abertura
continuam no mesmo projeto/main. Backup: `backup/before-defense-v02-023a08d`.

## Alterações visíveis

- HUD com cabeçalho compacto, relógio, objetivos por fase/equipe, vida, munição,
  progresso de recarga, créditos e localização no mapa. Indica dano recebido e
  vida crítica. O painel anterior de vida/munição serve de fallback até o novo
  HUD iniciar; não há dois conjuntos de números sobrepostos.
- Abate confirmado tem marcador dourado. Registro temporário mostra arma,
  acerto na cabeça no golpe final, infecções e barricadas rompidas por jogadores.
  Os eventos são emitidos depois da confirmação do servidor.
- Placar em Tab, botão na tela ou D-pad esquerdo: equipe, abates de jogadores,
  infecções, quedas e abates de treino. O resumo mostra defesas vencidas e
  créditos. Tudo é de sessão; não há ranking persistente. Loja e mapa têm
  prioridade sobre o placar, que suspende disparo e mira enquanto está aberto.
- Barricada próxima na mira mostra nome e resistência replicados pelo servidor.
  O treinamento usa a mesma autoridade de dano/impulso para golpear obstáculos.
  Isso não equivale a garantir que o pathfinding escolha sempre a melhor rota.
- Sinalização de refúgios aproveita os lintéis existentes. O térreo da
  administração recebe faixas de circulação, placas de saída, armários de
  serviço, conduítes, calha de cabos e acabamentos de janelas. Nenhuma dessas
  adições fecha portas ou acrescenta colisões às rotas medidas.

## Abrir e validar em uma sessão

GitHub Desktop: **zombie-outbreak-reborn → main → Fetch/Pull**. Salve e feche o
place aberto; execute **ABRIR_JOGO.cmd**. Confira **v0.2.0** no canto inferior
direito. Pull não altera um place já aberto no Studio.

1. No treino, avance pela administração e siga as placas. Atire, recarregue,
   elimine um infectado, receba dano e abra o placar. Confira recarga, confirmação,
   contagem de treino e ausência de painéis duplicados.
2. Forme uma defesa com objetos. Mire em um deles para conferir a resistência;
   observe um infectado aproximar-se de uma barricada no caminho. O golpe deve
   reduzir a resistência, respeitando um intervalo, e permitir romper o objeto.
3. Com dois clientes, complete uma rodada: preparação, infecção, ataque e
   resultado. Confira feed/placar dos dois lados e ausência de bots remanescentes.

Em caso de falha, informar ação, local e resultado observado, com captura e
primeiro erro vermelho do Output quando houver. A simulação na nuvem não
substitui essa execução do Studio.

## Verificação técnica

Os testes executam os controladores reais de combate, barricadas, treino e HUD
com APIs simuladas. Exercitam autoridade, intervalo dos golpes, transição para
multiplayer, estatísticas separadas, expiração do feed, respawn, foco de janela,
precedência da loja e limpeza do placar. Os testes de geometria verificam as
rotas, refúgios e o orçamento existente de peças/luzes. A entrega inclui o
place nativo recompilado, fontes conferidos e checksum atualizado.

Sem conexão com o Studio local nesta etapa. Renderização, colisões dinâmicas,
navegação real, legibilidade por resolução e áudio permanecem testes no motor.
