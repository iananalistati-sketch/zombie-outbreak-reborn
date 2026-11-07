# 0.7 — Escape no primeiro Play

O solo continuava exibindo as mesmas ondas no corredor; objetivos e retenções
só apareciam com dois clientes. Esta entrega muda o caminho padrão ao dar Play.
Backup anterior: `backup/before-solo-escape-v07-303c4f7`.

## Primeira sessão

O jogador começa dentro da estação elétrica, perto do primeiro objetivo.
Depois da preparação de cinco segundos, ativa o gerador, defende, atravessa o
subterrâneo até as bombas, libera o terminal e entra para extrair. São os
mesmos painéis, tempos de defesa, portões e área de extração de EscapeSession;
não existe um cenário de demonstração vazio ou outro mapa paralelo.

O HUD mostra **ZE / TREINO SOLO**, painéis, abates e NPCs. A orientação por
trechos e o percurso no mapa M funcionam também no exercício. Matar NPCs não
substitui extração. Vitória, morte, timeout ou saída da área de extração no
final produzem resultado e nova tentativa, sem contar como rodada multiplayer.

## Pressão durante a travessia

- Até quatro NPCs simultâneos, com intervalo de três segundos entre criações.
  Vida/velocidade aumentam por setor: 170/13, 220/16 e 260/18.
- Os candidatos vêm dos percursos medidos do mapa, em trechos planos. O
  diretor procura pontos de 28 a 95 studs, no mesmo nível, com volume livre.
  Um candidato na visão frontal sem obstrução é descartado. Sem ponto elegível,
  aguarda; não consome um inimigo de uma onda finita nem força sobreposição.
- Perseguidores a mais de 160 studs são retirados sem dano, prêmio ou abate.
  Isso libera pressão perto do jogador depois da travessia, sem teleportar um
  perseguidor vivo para sua frente. Caminho e contato continuam usando o motor.
- Abates vêm do combate real do servidor e dão o crédito de treino existente.
  Os NPCs usam o rig já carregado, o diretor de navegação e a integração de
  ataques a barricadas já presentes no projeto.

## Apresentação e multiplayer

Iluminação de fim de tarde, preenchimento externo mais frio e interiores
iluminados pelas luminárias existentes. A lanterna local cria um único
SpotLight com alcance de 48 studs. Começa ligada; **F**, D-pad direito ou toque
alternam. Ela acompanha a câmera, suspende em menus, morte e espectador,
recupera a preferência ao voltar e limpa o que criou. Não altera a câmera,
armas ou física. Outros clientes não veem esse facho nesta entrega.

Quando entra o segundo jogador, o treino perde suas permissões, destrói atores
e sessão, restaura as retenções e entrega a partida ao Round. Não consome
roundId, rotação de modos ou bônus de sobrevivência. O primeiro confronto
real continua sendo Escape; depois vem Survival. ZO_TrainingMode identifica
somente o exercício. Round continua escolhendo os modos multiplayer.

O arsenal mantém quatro classes e seis acabamentos. O mapa mantém 38 refúgios,
187 props e quatro dutos; a mudança de conteúdo está no acesso ao percurso e
na pressão durante ele. São 5.624 peças estáticas e 97 PointLights existentes,
mais um SpotLight local quando ligado. Não houve medição de FPS no motor.

## Teste curto

Atualize **zombie-outbreak-reborn → main → Fetch/Pull origin**, feche o place
anterior e abra **ABRIR_JOGO.cmd**. Confira **v0.7.0**.

1. Use Play sozinho. Deve começar perto do gerador, ver **ZE / TREINO SOLO** e
   conseguir seguir os três objetivos. Segure E perto do painel depois da
   preparação; atire, recarregue, use barricadas e extraia de verdade.
2. Compare lanterna ligada/desligada com F no interior e subterrâneo. Confira
   câmera, alinhamento, brilho e menus; o facho deve voltar após fechá-los.
3. Em dois clientes, confira a partida normal: primeira infecção entre jogadores,
   nenhum NPC de treino sobrando e funcionamento de Escape → Survival.

## O que foi verificado

Controladores reais de treino, Escape, Round, combate e HUD foram executados
com APIs simuladas. Os casos incluem extração, saída do terminal, morte,
timeout, reinício, limite de NPCs, ocupação, retirada sem prêmio e entrada do
segundo jogador. A lanterna tem testes de entrada, menus, câmera substituída,
espectador e destruição. Pontos de pressão e chegada têm apoio/circulação
verificados contra a geometria e props embarcados. A build nativa inclui os
fontes atuais e checksum.

Esses testes não executam Roblox Studio. Navegação real da IA, contatos,
replicação, iluminação, áudio e qualidade percebida continuam dependendo do
teste no motor. Não há alegação de que o usuário aprovou esta entrega.
