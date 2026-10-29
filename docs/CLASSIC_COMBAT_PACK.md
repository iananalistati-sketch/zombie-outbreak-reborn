# Pacote de combate clássico — K-17

> Registro da entrega anterior. O pacote FPS substitui a apresentação e reduz o
> catálogo para quatro armas; veja [estado atual e modelos pendentes](FPS_COMBAT_PACKAGE.md).

Esta entrega conecta arsenal, compras, inventário, munição, contenção por tiros e
barricadas ao ciclo existente de Zombie Survival. O mapa original K-17 mantém os
34 refúgios, quatro dutos e 164 objetos móveis. A partida continua com todos
humanos na preparação, primeiros infectados transformados no local, infecção
por golpe e vitória humana por sobreviver ao tempo.

## Jogar e conferir a entrega

1. Atualize **main** no GitHub Desktop, salve o place atual e abra
   **ABRIR_K17.cmd**. O Pull não troca um place já aberto no Studio.
2. Na preparação, pressione **B** para abrir o arsenal. Escolha a arma primária
   e compre munição de reserva quando necessário. A interface mostra o preço,
   créditos disponíveis, equipamento atual e motivos de compra indisponível.
3. Use **1** para a primária, **2** para a pistola e **Q** para alternar. **R**
   recarrega. Há botões de toque e comandos de gamepad na interface.
4. Segure o gatilho nas armas automáticas. Pistola e escopeta exigem um novo
   acionamento por disparo. Abrir a loja ou o mapa tático suspende os disparos.
5. Use **M** para localizar um refúgio. Posicione as barricadas com tiros e
   organize a defesa dos acessos antes da primeira infecção.

## Arsenal com funções distintas

A carabina inicial agora usa a [AR do Roblox Weapons Kit](REUSED_WEAPON_KIT.md),
com mesh, sons, flash, ferrolho e animações R15. As outras quatro armas mantêm
os modelos procedurais provisórios. Nenhum desses assets veio de Counter-Strike.

| Arma | Papel | Carregador / reserva | Intervalo | Recarga | Dano base | Preço |
| --- | --- | --- | --- | --- | --- | --- |
| Carabina | Precisão e defesa de corredores | 30 / 120 | 0,105 s | 2,4 s | 22 | 1.500 |
| Submetralhadora | Cadência alta a curta distância | 32 / 160 | 0,075 s | 2 s | 14 | 1.000 |
| Escopeta | Contenção de entradas próximas | 8 / 48 | 0,85 s | 2,9 s | 10 × até 7 projéteis | 2.200 |
| Metralhadora | Defesa sustentada; recarga longa | 80 / 240 | 0,11 s | 4,8 s | 20 | 3.200 |
| Pistola | Secundária para emergência | 12 / 72 | 0,23 s | 1,6 s | 18 | Inicial |

Todo humano recebe carabina e pistola no início da rodada. Há apenas um slot
primário e um secundário. Comprar outra primária substitui a anterior e não
reembolsa seu preço. A pistola permanece disponível. As armas têm dispersão,
recuo visual e força sobre barricadas próprios; movimentar-se aumenta a dispersão.
A escopeta consome **uma** unidade de munição por disparo, não sete.

Trocar de arma preserva seu carregador e sua reserva. A troca cancela a recarga
em andamento e exige um pequeno intervalo para equipar. Não é possível usar a
troca para criar munição ou disparar além da cadência aceita pelo servidor.

## Compra e créditos

O saldo inicial da sessão é **3.500**, com teto **12.000**. O início de uma nova
rodada concede **500** uma vez. Há **350** por matar um jogador zumbi, **200** por
uma infecção aceita e **800** por sobreviver como humano numa vitória humana.
Alvos do treino solo não geram esses prêmios.

Compras são permitidas a humanos vivos na preparação, em qualquer local; não
há zona física de compra nesta versão. Zumbis e espectadores não podem comprar,
equipar ou disparar armas humanas. Os créditos ficam na sessão do servidor;
não existe persistência entre servidores nem integração com Robux.

A compra de munição custa **180** e completa somente as reservas das armas
possuídas. Ela não completa instantaneamente o carregador. Se as reservas já
estiverem cheias, a compra é rejeitada sem cobrança. Recomprar a mesma arma não
repõe munição. Preços, saldo, posse e fase são verificados no servidor.

## Conter o avanço e defender a barricada

O tiro continua aplicando knockback proporcional a dano, arma, região atingida,
classe e estado no ar, conforme as referências já verificadas. A velocidade
horizontal acumulada tem limite de **48 studs/s**, e o impulso positivo vertical
é limitado para reduzir lançamentos extremos. A velocidade de queda não é zerada.

Um acerto válido reduz temporariamente o avanço do zumbi para **55%** da sua
velocidade base por **0,18 s**. Novos acertos renovam essa janela a partir do
momento do acerto, sem somar segundos de imobilização. Uma pausa no fogo permite
recuperar o avanço. O estado é limpo ao morrer, trocar de papel ou encerrar a
rodada; ele não deve alterar a velocidade humana depois da conversão.

A escopeta calcula seus projéteis no servidor e agrega o dano por alvo. Uma
barricada recebe uma ação de empurrão por objeto atingido na rajada, ponderada
pelos projéteis que acertaram. Cada raio para no primeiro obstáculo: os projéteis
não atravessam uma barricada para atingir quem estiver atrás dela.

A [correção de barricadas](BARRICADE_GAMEPLAY.md) integra o pacote: tiro base com
impulso 660, golpe de zumbi com 90 e resistência horizontal finita ao contato
corporal enquanto houver apoio. Cada arma multiplica o impulso base. O golpe
continua desgastando a vida do objeto. Gravidade, colisão e autoridade física do
servidor permanecem ativas; não existe trava invulnerável ou ancoragem de objeto vivo.

## Teste de uma defesa completa

No Studio, inicie **Server & Clients** com três jogadores:

1. Na preparação, dois humanos escolhem armas diferentes, como metralhadora e
   escopeta. Todos continuam sujeitos à seleção aleatória do primeiro infectado.
2. Os dois humanos restantes ocupam um refúgio, bloqueiam uma entrada com caixas
   e verificam a segunda aproximação, caso exista.
3. Um zumbi tenta avançar. Compare o avanço sob tiros, durante uma recarga e
   durante uma pausa no fogo. Confirme que a barricada interrompe o disparo.
4. Alterne primária e pistola com carregadores parcialmente gastos e confira
   que os valores permanecem. Compre reservas somente na preparação seguinte.
5. O zumbi golpeia e destrói um objeto, acerta um humano e infecta. Confira
   mudança de papel, remoção do acesso às armas humanas, cronômetro e vitória.
6. A rodada seguinte precisa restaurar objetos e equipamento inicial, conceder
   o crédito de rodada somente uma vez e manter o saldo dentro do teto.

Para explorar o arsenal sozinho, em **Play**, contexto **Server**:

```lua
require(game.ServerStorage.ZO_Validation.GameplayAudit).practice("Humans")
```

Esse treino explícito libera compras na loja apenas no Studio com um jogador e
rodada em espera. As compras continuam custando créditos. Repetir o comando
restaura os alvos e as armas iniciais sem conceder créditos. Pare e reinicie
Play para reiniciar a sessão e testar outra combinação de compras.

## Validação e limites

Na nuvem passaram 215 asserções de inventário/economia, 96 de contenção, as 160
regras anteriores de combate/rodada e 100 verificações do controlador real de
combate com APIs simuladas. O cliente real do arsenal passou 50 verificações
de compras assíncronas, respostas, timeout e atualização do equipamento; restaurar
o receptor incorreto faz esse teste falhar. O controlador de rodada passou 27 verificações,
incluindo a captura dos sobreviventes antes de mover os jogadores ao Lobby.
O controlador de barricadas passou 7.554 verificações, com multiplicadores
específicos de arma e cenários de 164 e 180 objetos. A política física passou
202 verificações e as regras de barricada preservadas, 85.

Na entrega original deste pacote também passaram os 17 testes Python de geometria, a compilação Luau, o build
Rojo XML/binário e a identidade de 21 fontes ativas. O arquivo nativo contém
7.700 instâncias, incluindo os módulos e a interface do novo arsenal. Esses
números descrevem verificações daquela entrega, não partidas reais. A AR
reutilizada foi adicionada posteriormente; sua origem, integração e roteiro
de validação estão em [REUSED_WEAPON_KIT.md](REUSED_WEAPON_KIT.md).

O backup antes da correção de barricadas está em
`backup/before-barricade-resistance-6d13145`; antes do arsenal, em
`backup/before-combat-pack`. Ambos também foram preservados em arquivos tar na nuvem.

Os testes da nuvem executam as políticas reais de inventário, munição, créditos,
cadência e contenção, além de controladores com APIs Roblox simuladas. A
compilação Rojo verifica as fontes ativas no place XML e no binário entregue.
Isso não executa a física, o Humanoid, a interface, os controles de toque/gamepad
nem a replicação entre clientes no motor Roblox.

Dano, duração de contenção, dispersão, economia e forças são parâmetros iniciais
Roblox. Não se afirma equilíbrio ou equivalência física com CS:GO/CS2. Os
[projetos públicos examinados](CS_ZOMBIE_OPEN_SOURCE.md) orientam as mecânicas;
nenhum código de plugin nem mapa externo foi incorporado a este pacote.
