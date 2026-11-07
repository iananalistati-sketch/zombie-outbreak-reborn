# 0.3 — Zombie Escape e Zombie Survival/Mod

O usuário informou a validação da 0.2 e reafirmou a base Counter-Strike Zombie.
A entrega acrescenta Escape ao mesmo projeto, preservando combate e Survival.
Backup: `backup/before-escape-v03-de643db`.

## Regras e conteúdo

- Rodadas alternam **Escape → Survival**; a primeira é Escape para avaliação.
  Dois jogadores são o mínimo. Play solo continua sendo treino de armas/física.
- Escape: preparação, primeira infecção, gerador (defender 12 segundos), bombas
  subterrâneas (15 segundos) e portão (20 segundos). Painéis precisam ser
  acionados na ordem. A infecção continua durante todo o trajeto.
- O portão abre uma janela de 18 segundos. Ao final, humanos vivos, participantes
  e dentro do terminal são extraídos. Zumbis podem persegui-los e entrar até o
  final. Quem não foi resgatado é eliminado na descontaminação. O limite geral
  de 360 segundos sem extração dá vitória aos zumbis.
- Survival mantém a vitória humana por resistir ao relógio. Infecção de todos
  dá vitória aos zumbis em ambos os modos. Falta de participantes cancela.
- Apenas extraídos recebem a recompensa de Escape. **B → Munição** permite
  repor reservas pagando créditos durante a fuga. Armas novas ficam na preparação.
- HUD e marcador mostram objetivo/tempo e depois a entrada do terminal. M
  mostra os objetivos e a área de extração. Tab mantém o placar da sessão.
- Terminal 50: cobertura, retorno interno, portão, janelas, instalações e seis
  objetos físicos, dentro e fora da entrada. Total: 35 refúgios e 170 objetos.
  As rotas conectam energia, escadas, anel subterrâneo e pátio existentes.

## Referência e limites

Referências: [Zombie:Reloaded e outros núcleos examinados](CS_ZOMBIE_OPEN_SOURCE.md)
e [CS2Fixes](https://github.com/Source2ZE/CS2Fixes), cujo README foi consultado
novamente e declara Zombie Escape como foco. São referências de comportamento;
os controles de mapa são Luau original. Nenhum mapa/asset de CS foi importado.

O K-17 mantém planta aberta, com sequência obrigatória e portão final. Esta
entrega não transforma todos os seus acessos em um corredor linear nem comprova
equivalência exata à física Source. O treino de ondas não é o modo multiplayer.

## Validar em uma sessão

Atualize **zombie-outbreak-reborn → main**, feche o place aberto e execute
**ABRIR_JOGO.cmd**. Confira **v0.3.0**. Inicie **Server & Clients, dois clientes**.

1. Siga o marcador, acione os três painéis (E/interação padrão do Roblox), defenda
   os tempos e entre no terminal. Confira portão, extração e recompensa.
2. Pelo lado zumbi, confira perseguição, infecção e barricadas no trajeto. Um
   humano dentro do terminal ainda pode ser infectado antes do fim da janela.
3. Confira a próxima rodada em Survival. Em outra tentativa Escape, deixe o
   tempo acabar sem extrair: a vitória deve ser dos zumbis.

## Verificações

Round é a única autoridade. EscapeSession valida equipe, vida, participação,
distância e linha de visão; rejeita objetivos fora de ordem/repetidos. Resultado
e cancelamento limpam prompts, atributos e colisão do portão. Não há dependência
de HTTP, DataStores ou listas de autorização para entrar.

Os testes executam Round, Combat, Startup e EscapeSession juntos com APIs
simuladas, além de conferir HUD, timers, extração, crédito e limpeza. As três
rotas conectadas, alcance/visibilidade dos painéis e volume do portão são
verificados contra a geometria e as posições iniciais dos objetos. O orçamento
revisto acomoda o terminal funcional: 5.556 peças e 95 luzes, oito com sombras.
Isso não é uma medição de FPS. A entrega inclui build nativo/checksum atualizados.

Não há conexão com o Studio local. Navegação real, colisões dinâmicas, prompts,
legibilidade e balanceamento precisam da execução acima no motor.
