# Adaptação do Zombie Mod de Counter-Strike para Roblox

## O que pode ser adaptado

Podemos implementar em Luau as regras observadas nos plugins públicos: espera
por jogadores, preparação, escolha do primeiro infectado, ataque que infecta,
armas restritas por papel, knockback, respawn e vitória por sobrevivência.
SourcePawn, C#, C++ e as APIs Source/Source 2 não executam no Roblox. Copiar um
plugin para o projeto não fornece os mapas, armas, animações ou a física do CS.

Este documento compara a base Roblox `0a38374` com evidências de referência.
Não declara que as recomendações abaixo já foram implementadas ou testadas no
Studio. O relato de dois jogadores sem progressão exige corrigir a inicialização
antes de considerar o ciclo multiplayer validado.

## Cinco ações concretas

1. **Tornar a partida de dois jogadores observável.** O segundo jogador deve
   disparar uma sequência clara: espera → intervalo → preparação de todos como
   humanos → um infectado → rodada ativa. O HUD deve mostrar contagem, papel e
   cronômetro desde o carregamento. Dependências ausentes precisam gerar um erro
   identificável de inicialização, em vez de uma espera indefinida. Testar também
   dois avatares ainda carregando, reconexão e queda para um participante.

2. **Conferir cada transição contra o modelo clássico.** O Franug inicia a
   contagem de infecção ao terminar o freeze time e escolhe jogadores elegíveis.
   ZombieSharp configura `FirstInfectionTimer: 15`, razão `7`, transformação no
   local, vitória humana por tempo e respawn de cinco segundos. São referências
   explícitas, não valores obrigatórios. Na base Roblox examinada há intervalo
   de 12 s e preparação de 35 s: seriam cerca de 47 s até a primeira infecção
   após a entrada do segundo jogador, se a inicialização estiver funcionando.
   Não se deve apresentar a demora como diagnóstico confirmado da falha.

3. **Validar uma defesa completa com dois jogadores.** Um humano contém um
   zumbi com fogo; o obstáculo interrompe o disparo; o zumbi aproxima, acerta o
   golpe e infecta; a vitória encerra e restaura a próxima rodada. O Franug exige
   arma `knife`/`bayonet` no evento de dano para infectar. Seu knockback multiplica
   classe, arma, hitgroup e dano e diferencia o alvo no ar. Em Roblox isso exige
   raycasts e autoridade do servidor; as forças precisam de calibração própria.

4. **Fechar interiores e adicionar rotas de manutenção úteis.** Criar dutos,
   corredores protegidos e salas com poucas entradas como geometria original,
   com dimensões conferidas contra o avatar real. Cada posição precisa de piso,
   teto, proteção lateral, linha de tiro e uma rota de pressão dos zumbis. Duto
   baixo exige movimento agachado funcional e teste de colisão do rig; apenas
   baixar a câmera não permite atravessar um volume menor. Nenhuma evidência
   examinada estabelece dutos ou agachamento como recurso desses plugins.

5. **Distribuir barricadas em conjuntos utilizáveis.** Colocar objetos próximos
   de portas e gargalos, com área para girar e recuar. Validar massas, atrito,
   impulso por tiros, empilhamento, reposição e custo de rede no motor Roblox.
   Os núcleos examinados não especificam a mecânica de barricada do servidor
   desejado: física Source, entidades do mapa e plugins adicionais podem defini-la.
   Mais objetos sem esses testes não comprovam uma barricada melhor.

## Mapeamento de evidências

| Fonte verificada | Comportamento | Destino Roblox |
| --- | --- | --- |
| [Franug `infect.inc`, início da contagem](https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition/blob/b930d379e7d1f26d139f89ff9c0c1853d531a632/src/zr/infect.inc#L370) | Freeze termina, temporizador escolhe mães entre elegíveis | `Round.server.luau` e `RoundRules.luau`, com fases visíveis e personagens prontos |
| [Franug `InfectOnClientHurt`](https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition/blob/b930d379e7d1f26d139f89ff9c0c1853d531a632/src/zr/infect.inc#L311) | Humano atingido por faca de zumbi é convertido | Golpe e raycast do servidor em `Combat.server.luau`; mudança de papel em `Round.server.luau` |
| [Franug `knockback.inc`](https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition/blob/b930d379e7d1f26d139f89ff9c0c1853d531a632/src/zr/knockback.inc#L67) | Contenção relacionada ao dano, arma, hitgroup e classe | `Rules.luau` e impulso no servidor, calibrado em studs e massa Roblox |
| [ZombieSharp `gamesettings.jsonc`](https://github.com/oylsister/ZombieSharp/blob/1d3b7c4481044cec5b730af0f0903b1632bdeb97/ZombieSharp/build/addons/counterstrikesharp/configs/zombiesharp/gamesettings.jsonc) | Primeiro infectado, teleporte opcional, vitória e respawn configuráveis | `src/maps/k17/RoundConfig.luau`, sem assumir equivalência de todos os parâmetros |
| Arquitetura e objetos dos mapas | Não são definidos pelos núcleos de infecção acima | Geometria K-17 original e objetos físicos; teste separado de jogabilidade e desempenho |

## Disponibilidade e licenças

Na inspeção atual, `/workspace/reference-study/zombie-survival` contém somente
quatro snapshots de README: ZombieSharp, CS2Fixes, srcdslab e ReclaimCS. As cópias
completas dos sete projetos da [pesquisa anterior](CS_ZOMBIE_OPEN_SOURCE.md) não
estão presentes nessa pasta. Nesta revisão foram consultados novamente, nas
revisões fixadas acima, `infect.inc`, `knockback.inc`, `gamesettings.jsonc` e os
arquivos `LICENSE` de Franug e ZombieSharp. Ambos declaram GPLv3. Código desses
plugins não foi incorporado ao jogo por este documento. Uma tradução derivada de
código continua exigindo análise e cumprimento da licença; trocar a linguagem
não elimina essas obrigações.

Os BSPs `zm_ice_attack.bsp` e `zm_lila_panic_173.bsp` estão presentes em
`/workspace/reference-study/k17`, mas são mapas compilados. Não foi encontrado
nessas cópias nenhum projeto editável `.vmf`/`.vmap`, nem licença permissiva que
autorize sua adaptação e distribuição. Não são base licenciada confirmada para
importação. A licença de um plugin não licencia mapas, sons, texturas ou modelos
de Valve/Workshop. ReclaimCS permanece excluído como base reutilizável porque a
licença examinada exige autorização escrita.

A abordagem executável é usar as regras verificadas como referência para os
sistemas originais em Luau e construir um mapa original adequado à defesa. A
validação final exige servidor e dois clientes no Studio; a nuvem desta sessão
não fornece execução do motor Roblox nem acesso ao computador do usuário.
