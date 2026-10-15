# Projetos públicos examinados — Zombie Mod / Survival de CS2 e CS:GO

> Pesquisa anterior aos [ajustes de combate e rodada do perfil atual](CLASSIC_GAMEPLAY.md).
> A seção de diferenças abaixo registra o protótipo que motivou esses ajustes.

## Resultado

**Zombie:Reloaded Franug Edition (CS:GO/CS:S)** é a referência principal
recomendada para as regras clássicas. **ZombieSharp (CS2)** permite comparar a
mesma família de mecânicas com uma implementação de CS2, mas foi arquivado.
**CS2Fixes / Zombie:Reborn** e **ZombieModSharp** são referências técnicas atuais
de infecção/knockback; seus próprios projetos enfatizam Zombie Escape e não
definem sozinhos o Survival solicitado.

Esta pesquisa examinou arquivos reais e licenças de sete repositórios, em cópias
separadas do jogo. Não foram executados servidores CS, compilados os plugins,
assistidos vídeos nem importados mapas, modelos, sons ou código desses projetos
para o Roblox. A disponibilidade do código não comprova o funcionamento nas
versões atuais dos servidores nem a fidelidade visual do nosso mapa.

## Comparação

| Projeto | Jogo / tecnologia | O que foi confirmado | Situação / utilidade |
| --- | --- | --- | --- |
| [Zombie:Reloaded Franug Edition](https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition) | CS:GO e CS:S; SourcePawn/SourceMod | Infecção por faca, primeiros infectados, remoção de armas ao infectar, knockback por arma/classe/hitgroup, configuração do teleporte inicial | GPLv3 no arquivo de licença. Último commit da cópia examinada: julho de 2022. Principal referência do ciclo clássico; não foi testada compatibilidade atual |
| [ZombieSharp](https://github.com/oylsister/ZombieSharp) | CS2; C#/CounterStrikeSharp | README o apresenta como remake de Zombie:Reloaded; código tem infecção no evento de dano, restrição a faca para zumbis, classes, compra de armas e knockback | GPLv3; arquivado. README anuncia descontinuação em julho de 2025 e arquivamento em novembro de 2025. Referência secundária das regras no CS2 |
| [ZombieModSharp](https://github.com/oylsister/ZombieModSharp) | CS2; C#/ModSharp | Continuação de ZombieSharp; infecção por acerto de faca, contagem inicial, knockback por dano/arma/hitgroup/classe e configurações de respawn | GPLv3; commit examinado de outubro de 2026. README diz foco em Escape, permitindo uso como Zombie Mod. Usar o núcleo técnico, sem adotar progressão de mapa de Escape |
| [Zombie Survival](https://github.com/decode2/Zombie-Survival) | CS:GO; SourcePawn/SourceMod e MySQL | Código de modos de infecção, classes, armas especiais, persistência e progressão; README o identifica como Survival inspirado em Zombie Plague | GPLv3 na raiz; módulos também têm avisos próprios. README informa fim do desenvolvimento ativo de funcionalidades. Variante com muitos sistemas adicionais, que não devem entrar automaticamente no nosso escopo |
| [Zombie:Reloaded — srcdslab](https://github.com/srcdslab/sm-plugin-zombiereloaded) | SourceMod / jogos Source; SourcePawn | README declara infection/survival; módulos de infecção, knockback, armas e classes; comentários e documentação incluem histórico de suporte a CS:GO | Cabeçalhos dos módulos declaram GPLv3 ou posterior. Commit examinado de setembro de 2026. Referência complementar; não foi comprovada compatibilidade CS:GO da revisão atual |
| [CS2Fixes / Zombie:Reborn](https://github.com/Source2ZE/CS2Fixes) | CS2; C++/Metamod | `zombiereborn.cpp` implementa infecção ao acertar faca e knockback multiplicado por dano/arma/hitgroup/classe; opções de primeira infecção e respawn | GPLv3. Projeto orientado principalmente a Escape; útil para conferir o núcleo atual de CS2 |
| [ReclaimCS / CS2-Zombie-Mod](https://github.com/ReclaimCS/CS2-Zombie-Mod) | CS2; C#/CounterStrikeSharp | README descreve classes, habilidades, progressão e rodada de infecção | **Público, mas não open source para reutilização:** a licença diz “All rights reserved” e exige autorização escrita para copiar, modificar, distribuir ou usar. Excluído como base reutilizável |

As licenças acima descrevem o código examinado, não uma autorização geral para
reutilizar assets de Valve, Workshop ou terceiros presentes/referenciados nos
repositórios. Nenhum conteúdo externo foi incorporado ao jogo nesta pesquisa.

## Evidências de comportamento

### 1. Infecção exige ataque que acerta

No Franug, [`InfectOnClientHurt`](https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition/blob/b930d379e7d1f26d139f89ff9c0c1853d531a632/src/zr/infect.inc#L311)
valida humano atingido, atacante zumbi, imunidade e arma `knife`/`bayonet` antes
de converter a vítima.

No ZombieSharp, [`InfectOnPlayerHurt`](https://github.com/oylsister/ZombieSharp/blob/1d3b7c4481044cec5b730af0f0903b1632bdeb97/ZombieSharp/Plugin/Infect.cs#L250)
converte o humano no evento de dano de um zumbi. A
[restrição de aquisição](https://github.com/oylsister/ZombieSharp/blob/1d3b7c4481044cec5b730af0f0903b1632bdeb97/ZombieSharp/Plugin/Hook.cs#L35)
bloqueia armas que não sejam facas para infectados.

O [evento de dano do ZombieModSharp](https://github.com/oylsister/ZombieModSharp/blob/2b724eda5973de63a913081119bba18132fe31ba/ZombieModSharp/Core/HookManager/Events.cs#L76)
também testa `weapon.Contains("knife")`. O
[hook de CS2Fixes](https://github.com/Source2ZE/CS2Fixes/blob/bb3be3449c122bebf2d74e85b61987de408ac339/src/zombiereborn.cpp#L1423)
testa a equipe e a classe da arma `weapon_knife` antes de infectar.

**Diferença no Roblox:** `src/server/ZombieRound.server.luau` faz infecção por
proximidade com raycast, sem exigir o comando de ataque. Deve ser substituída
por ataque corpo a corpo validado no servidor para seguir essa referência.

### 2. Knockback é parte do combate

O [módulo Franug](https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition/blob/b930d379e7d1f26d139f89ff9c0c1853d531a632/src/zr/knockback.inc#L67)
combina a classe do zumbi, multiplicadores da arma e do hitgroup e o dano.
Também diferencia CS:GO e o estado no ar. O
[módulo ZombieSharp](https://github.com/oylsister/ZombieSharp/blob/1d3b7c4481044cec5b730af0f0903b1632bdeb97/ZombieSharp/Plugin/Knockback.cs#L18)
e a [implementação CS2Fixes](https://github.com/Source2ZE/CS2Fixes/blob/bb3be3449c122bebf2d74e85b61987de408ac339/src/zombiereborn.cpp#L997)
têm a mesma família de fatores, com diferenças de direção e escala.

**Diferença no Roblox:** o combate atual usa um único rifle e impulsos fixos de
30/45 para corpo/cabeça. Precisamos de parâmetros de armas e de uma relação
explícita entre dano e contenção dos zumbis. Os valores Source não devem ser
tratados como equivalentes em studs; precisam de testes no motor Roblox.

### 3. Teleporte do primeiro infectado é configurável

As [configurações Franug](https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition/blob/b930d379e7d1f26d139f89ff9c0c1853d531a632/src/zr/cvars.inc#L312)
trazem `zr_infect_mzombie_respawn` com padrão `0`: transformação no local.
As [configurações ZombieSharp](https://github.com/oylsister/ZombieSharp/blob/1d3b7c4481044cec5b730af0f0903b1632bdeb97/ZombieSharp/build/addons/counterstrikesharp/configs/zombiesharp/gamesettings.jsonc#L1)
trazem `MotherZombieTeleport: false`.

CS2Fixes, que enfatiza Escape, tem
[`zr_infect_spawn_type`](https://github.com/Source2ZE/CS2Fixes/blob/bb3be3449c122bebf2d74e85b61987de408ac339/src/zombiereborn.cpp#L69)
com alternativas no local/retorno ao spawn e padrão de retorno ao spawn.
Portanto, teleporte não é uma regra universal de todo Zombie do CS.

**Diferença no Roblox:** o primeiro infectado sempre é enviado ao spawn dos
zumbis. Para o perfil clássico recomendado, usar transformação no local como
padrão e uma configuração explícita para variantes.

### 4. Barricadas não estão definidas por esses núcleos

Os núcleos de infecção/combate examinados não estabelecem o nosso sistema de
seleção com prévia, zona de uma sala e reposicionamento instantâneo. Também não
comprovam que todo objeto do Zombie Mod deve quebrar com um número fixo de golpes.

Mapas, física da engine e plugins adicionais podem definir a interação com
objetos. Não foi verificado um plugin específico de barricadas que permita
afirmar quais controles, forças e tipos de objeto reproduzem o servidor desejado.
Regras de empilhar, puxar, empurrar, destruir e spawnar props precisam ser
estabelecidas por evidência própria. Os núcleos de Zombie:Reloaded não bastam
para validar essas escolhas.

**Diferença no Roblox:** o protótipo ancorado de seleção/confirmar posição não
deve ser apresentado como reprodução comprovada das barricadas do CS.

## Ordem recomendada de correção

1. Reproduzir a sequência clássica: todos humanos, preparação, seleção dos
   primeiros infectados e transformação no local no perfil Survival.
2. Substituir a infecção automática por ataque corpo a corpo. Validar papel,
   rodada, personagem vivo, alcance, cadência e obstáculos no servidor.
3. Ajustar armas e knockback para que defender uma passagem em grupo seja a
   mecânica central. Corrigir a recarga instantânea e a ausência de tiro contínuo
   do rifle provisório antes de apresentar o combate como equivalente ao CS.
4. Definir e testar interação física de barricadas a partir de referência
   específica; preservar o protótipo atual como backup, sem assumir fidelidade.
5. Validar uma situação completa: humanos defendem uma porta, zumbis pressionam,
   o fogo os contém e uma falha na defesa permite ataque e infecção.
6. Só então aplicar os parâmetros aos demais esconderijos. Classes especiais,
   XP, lojas de habilidades e modos de chefes vistos em algumas variantes não
   entram automaticamente no projeto.

Esses passos são uma conclusão da pesquisa. Nenhuma dessas correções de gameplay
foi implementada ou testada no Studio nesta entrega de documentação.

## Revisões examinadas

As conclusões acima estão vinculadas às cópias abaixo; alterações futuras dos
repositórios podem mudar os comportamentos e as licenças.

| Repositório | Commit |
| --- | --- |
| `Franc1sco/sm-zombiereloaded-3-Franug-Edition` | `b930d379e7d1f26d139f89ff9c0c1853d531a632` |
| `oylsister/ZombieSharp` | `1d3b7c4481044cec5b730af0f0903b1632bdeb97` |
| `oylsister/ZombieModSharp` | `2b724eda5973de63a913081119bba18132fe31ba` |
| `decode2/Zombie-Survival` | `e1d99fdd73814c14f10d3a35dbc6c52804fce758` |
| `srcdslab/sm-plugin-zombiereloaded` | `5293ebcc5c4dfd3885d1584f897bfafb88652ac3` |
| `Source2ZE/CS2Fixes` | `bb3be3449c122bebf2d74e85b61987de408ac339` |
| `ReclaimCS/CS2-Zombie-Mod` | `aec6fcbb5f5549b5e125c0c1a4cd216788122997` |

São plugins de servidor para engines Source/Source 2. Não são mapas completos
prontos para abrir no Roblox e não executam diretamente em Luau. A proposta é
implementar o comportamento observado no nosso código e cenário originais;
qualquer port de código ou reutilização de assets exige considerar sua licença.
