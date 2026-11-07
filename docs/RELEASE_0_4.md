# 0.4 — Retenção, orientação e espectador

Próximo pacote autorizado após a 0.3. A referência permanece Counter-Strike
Zombie Escape/Survival, no mesmo projeto/main e arquivo de abertura.
Backup anterior: `backup/before-defense-v04-1fe0863`.

## Comportamento

- Na defesa do gerador, a saída frontal da estação elétrica entra em retenção.
  Na defesa das bombas, a retenção é na subida leste de manutenção. Os flancos
  e rotas alternativas existentes continuam fazendo parte do confronto.
- Antes de fechar, o servidor consulta o volume da porta, incluindo personagens
  e a pasta de objetos físicos. Se estiver ocupado, adia o fechamento; o tempo
  de defesa continua. Uma porta já fechada permanece até acabar a retenção.
  Resultado/cancelamento restaura colisão, avisos e transparência.
- A posição 51, junto ao gerador, acrescenta recuo protegido e cinco objetos
  móveis. O mapa passa a ter 36 refúgios e 175 props. Placas indicam descida,
  anel de manutenção, bombas e subida leste. O marcador usa o próximo trecho
  da rota medida, incluindo subidas/descidas; perto do objetivo volta ao painel.
- Espectador: durante Active, mortos e espectadores tardios observam apenas
  zumbis vivos. Isso evita revelar refúgios humanos, inclusive antes da equipe
  do morto terminar de replicar. Na preparação, a observação é dos humanos.
  Sem alvo elegível, mostra espera. Setas, L1/R1 e botões alternam alvos quando
  existem vários. A previsão de retorno vem do relógio do servidor.
- Câmera e zoom voltam ao personagem ao renascer/entrar no jogo/encerrar a
  rodada. Troca de câmera e controle por cutscene são respeitados. Jogadores
  no Lobby durante Active/Preparation têm caminhada/salto bloqueados pelo
  servidor; os valores são restaurados na limpeza ou entrada em equipe jogável.

## Validar o pacote

Atualize **zombie-outbreak-reborn → main**, feche o place aberto e execute
**ABRIR_JOGO.cmd**. Confira **v0.4.0**.

1. Com dois clientes, complete Escape. Confira retenções nos dois primeiros
   objetivos, liberação nos tempos previstos, orientação no subterrâneo e
   cobertura do gerador. Deixe um objeto/personagem na passagem antes de
   acionar: o fechamento deve aguardar sem prender ou esmagar.
2. Com três clientes, infecte um segundo jogador mantendo um humano vivo.
   Derrube um dos zumbis: ele deve observar o zumbi vivo e recuperar a própria
   câmera ao renascer. Para alternar entre dois alvos vivos, use quatro clientes.
3. Confira resultado, rodada Survival e nova preparação: portas abertas,
   controle normal e objetos restaurados. Um espectador que entrou tarde não
   deve continuar travado quando for admitido na próxima rodada.

## Verificações e limites

Testes executam os controladores reais de portas, Escape, combate, rodadas,
HUD e espectador com APIs simuladas. Cobrem ocupação, temporização, limpeza,
filtro de alvos, morte/respawn, câmera externa e retorno de controle. A geometria
confere portas abertas/fechadas nos percursos, apoio, sobreposição e refúgios.
O cenário tem 5.573 peças estáticas e 95 luzes (oito com sombras), mantendo o
orçamento revisto da 0.3. Isso não mede FPS nem resolve contatos físicos no motor.

Não houve execução no Studio local. Física real das portas/props, câmera em
rede, escala visual, legibilidade e balanceamento precisam do teste acima.
