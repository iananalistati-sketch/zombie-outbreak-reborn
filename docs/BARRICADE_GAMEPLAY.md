# Barricadas: montagem por tiros e resistência ao contato

A integração atual adiciona multiplicadores de impulso por arma. Veja o
[pacote de combate com cinco armas e loja](CLASSIC_COMBAT_PACK.md).

## Problema e comportamento pretendido

O relato no Studio foi que um zumbi conseguia arrastar as barricadas mais
facilmente que o humano conseguia movê-las com o rifle. Havia uma inversão
concreta nos parâmetros: cada golpe aplicava impulso `390`, contra `260` por
tiro. Além disso, o contato do `Humanoid` exerce pressão contínua, enquanto um
tiro aplica um impulso instantâneo.

O objetivo deste ajuste é permitir ao humano montar e sustentar uma defesa
com tiros, enquanto o zumbi desgasta os objetos com golpes. O contato corporal
encontra resistência finita: a barricada continua sendo um objeto físico e não
tem imunidade absoluta a empurrões. Esse é um ajuste de gameplay Roblox, cuja
eficácia precisa ser medida no Studio.

## Ajustes implementados

A fonte dos parâmetros é
[`src/maps/k17/barricades/catalog.json`](../src/maps/k17/barricades/catalog.json).
`Config.luau` é gerado a partir desse catálogo.

| Parâmetro | Antes | Agora |
| --- | ---: | ---: |
| Impulso por tiro humano | 260 | 660 |
| Impulso por golpe zumbi | 390 | 90 |
| Limite de velocidade horizontal | 12 | 18 |
| Atrito configurado do objeto | 0,65 | 0,30 |
| Resistência horizontal adicional com apoio | Ausente | Força limitada a massa × 120 por eixo |

As massas permanecem em `55` para armários, `32` para mesas e `24` para caixas.
O dano do golpe continua em `45`, com intervalo mínimo de `0,7 s`.

Partindo do repouso, o cálculo de impulso horizontal produz os valores abaixo,
antes da atuação do atrito, freio e colisões. Eles são incrementos iniciais de
velocidade, **não distâncias garantidas** nem velocidades sustentadas.

| Objeto | Tiro: incremento inicial, limitado a 18 | Golpe: incremento inicial |
| --- | ---: | ---: |
| Armário, massa 55 | 12 | 1,64 |
| Mesa, massa 32 | 18 | 2,81 |
| Caixa, massa 24 | 18 | 3,75 |

O servidor instala um `LinearVelocity` em modo `Plane`, com alvo horizontal
zero e limite de força finito. Ele funciona como freio horizontal quando um
raycast detecta apoio. Não dirige o objeto de volta à posição original e não
exerce força vertical. **Tiros nunca desativam esse freio:** não existe janela
após um disparo em que o contato corporal fica liberado.

A sondagem de apoio ocorre nas passagens de manutenção, até 10 vezes por
segundo com jogadores presentes. Objetos imóveis reutilizam o resultado enquanto
posição, orientação e velocidade permanecem iguais. A sondagem exclui apenas o
próprio modelo: outro objeto pode servir de apoio em uma pilha. Sem apoio, o
freio fica desativado; o objeto continua sujeito à gravidade e às colisões.
As montagens continuam dinâmicas, com autoridade física do servidor. Os limites
anteriores de rotação, segurança e reposição continuam sendo controles separados.

## O que as referências de Counter-Strike comprovam

O knockback do **jogador zumbi** e a física de um **objeto de barricada** são
sistemas diferentes. O primeiro já usa no perfil K-17 dano × arma × região
atingida × classe × fator no ar, com limite. O impulso correspondente compensa
a massa da montagem do personagem para produzir o incremento de velocidade
calculado. Os parâmetros de barricada acima não substituem esse sistema.

| Referência na revisão examinada | Evidência e limite |
| --- | --- |
| [Franug, `knockback.inc`, linhas 42–159](https://github.com/Franc1sco/sm-zombiereloaded-3-Franug-Edition/blob/b930d379e7d1f26d139f89ff9c0c1853d531a632/src/zr/knockback.inc#L42) | Tiro humano adiciona velocidade ao zumbi em função de dano, classe, arma e hitgroup; há fator para alvo no ar. É uma rotina de jogadores, não de props. |
| [CS2Fixes, `ZR_ApplyKnockback`, linhas 997–1014](https://github.com/Source2ZE/CS2Fixes/blob/bb3be3449c122bebf2d74e85b61987de408ac339/src/zombiereborn.cpp#L997) | Adiciona velocidade ao zumbi em função de dano e multiplicadores global, de arma, de hitgroup e de classe. Não define a resistência de uma barricada ao corpo do jogador. |
| [ZombieSharp, `Knockback.cs`, linhas 18–93](https://github.com/oylsister/ZombieSharp/blob/1d3b7c4481044cec5b730af0f0903b1632bdeb97/ZombieSharp/Plugin/Knockback.cs#L18) | Confirma a família de fatores para tiros humanos contra jogadores infectados. |
| [Valve Source SDK 2013, `player.cpp`, linhas 8208–8233](https://github.com/ValveSoftware/source-sdk-2013/blob/be57e3d01ac7d7aa6a2cacbfef187c0b46616db0/src/game/server/player.cpp#L8208) | O controlador físico configura limites próprios de massa e velocidade para empurrar objetos. Isso evidencia a separação do contato corporal; não comprova os parâmetros atuais de CS:GO/CS2. |
| [Valve Source SDK 2013, `takedamageinfo.cpp`, linhas 332–358](https://github.com/ValveSoftware/source-sdk-2013/blob/be57e3d01ac7d7aa6a2cacbfef187c0b46616db0/src/game/shared/takedamageinfo.cpp#L332) | Bala usa força do tipo de munição × escala física × escala do ataque; melee usa dano base. É evidência de Source 1, não uma especificação da física Source 2. |
| [CS2Fixes, `detours.cpp`, linhas 169–172](https://github.com/Source2ZE/CS2Fixes/blob/bb3be3449c122bebf2d74e85b61987de408ac339/src/detours.cpp#L169) | A opção de dano de prop escala dano infligido pelo objeto. Não é uma implementação de antiarrasto nem de impulso por rifle. |

Não foi comprovada nas referências uma regra universal para empilhar, arrastar,
quebrar ou empurrar os props de todo servidor Zombie Survival. Mapas, engine,
configuração e plugins adicionais podem mudar essas interações. Os valores
`660`, `90` e `120` deste ajuste são parâmetros iniciais Roblox. Nenhum código
GPL ou asset dos projetos examinados foi incorporado nesta alteração.

## Validação manual com dois clientes

Os testes de cálculo e compilação não executam o solver físico do Roblox.
O freio, contato, atrito, latência e desempenho precisam da sequência abaixo
em **Test → Server & Clients**, com dois jogadores.

1. Escolha um objeto, por exemplo `Cabinet01`, em
   `Workspace.ZO_Barricades`. Use sempre o mesmo objeto e posição inicial,
   espere ele repousar e mantenha o outro jogador afastado. Confirme o humano
   na preparação/rodada ativa e o zumbi na fase ativa antes de seus ataques.
2. Na Command Bar em contexto **Server**, inicie uma amostra de três segundos:

   ```lua
   require(game.ServerStorage.ZO_Validation.BarricadeAudit).sample("Cabinet01", 3)
   ```

3. Durante a amostra, faça uma única ação: andar encostado no objeto, um tiro,
   uma rajada ou golpes de zumbi. **Pare e inicie Play novamente antes de cada
   comparação**, restaurando a posição e a vida. Use a mesma distância, direção
   e janela de três segundos. Não compare uma tentativa perto da parede com
   outra em piso livre. Anote deslocamento, velocidade e vida registrados pela
   auditoria; confira também o comportamento visível nos dois clientes.
4. Repita com uma mesa e uma caixa, trocando o nome na chamada. A expectativa
   é que os tiros sejam o meio eficaz de posicionamento e sustentação; andar
   encostado deve encontrar resistência, e golpes devem desgastar com pouco
   deslocamento. Esses são critérios a verificar, não resultados já medidos.
5. Depois confira objetos em andares altos, quedas e empilhamento. Eles devem
   continuar caindo sem apoio, colidir e reconhecer outro prop como apoio,
   preservando a autoridade do servidor. Confira FPS e estabilidade com vários
   objetos em movimento e duas perspectivas de cliente.

Se o contato ainda vencer a defesa ou os tiros não produzirem deslocamento
útil, use essas medições para ajustar resistência, atrito e impulso em conjunto.
Compilar ou calcular `impulso / massa` não valida sozinho uma barricada jogável.

## Verificação e preservação

Na nuvem passaram 202 asserções de impulso e 7.551 do controlador real com APIs
simuladas. Os casos incluem configuração do freio, apoio em outra barricada,
tiro e golpe mantendo a resistência, queda preservando a velocidade vertical,
sondagem após rotação, destruição, reposição e isolamento de falha em um objeto.
Esses testes não simulam os contatos do Humanoid nem o solver do constraint.

Os 34 refúgios e 164 objetos foram preservados. O estado anterior está na branch
`backup/before-barricade-resistance-6d13145` e em tar verificado na nuvem.
O place nativo e seu checksum são recompilados na entrega. Depois do Pull, salve
e feche o place anterior e abra `ABRIR_K17.cmd`; a sincronização Git não atualiza
um place que já esteja aberto.
