# Componentes FPS aplicados — 06/11/2026

O K-17 agora reutiliza código de movimento, recuo e mola no caminho ativo do
jogo. A entrega continua na branch `feat/fps-combat-package`; o estado anterior
foi preservado em `backup/before-fps-adoption-aeb098a`. A validação visual,
física e multiplayer no Roblox Studio ainda precisa ser executada.

## O que está integrado

| Componente | Fonte e adaptação ativa | Alcance |
| --- | --- | --- |
| Movimento | [SourceMovement.luau](../src/maps/k17/gameplay/SourceMovement.luau) porta fricção, aceleração pela direção desejada e limite de aceleração aérea de Olezen/UnitySourceMovement, MIT. | Cálculo horizontal; coeficientes ajustados para o K-17. |
| Entrada humana no PC | [SourceMotor.client.luau](../src/maps/k17/gameplay/SourceMotor.client.luau) integra o cálculo pelo vetor analógico de `Humanoid:Move`. | Humanos durante preparação/rodada ativa e treino autorizado; toque e gamepad usam PlayerModule. O Humanoid mantém gravidade, salto e colisões. |
| Recuo | [TacticalRecoil.luau](../src/maps/k17/gameplay/TacticalRecoil.luau) adapta o cálculo vertical e da faixa horizontal com divisão por dois de CIA-SAC-ACS, Apache 2.0. [Weapons.client.luau](../src/maps/k17/gameplay/Weapons.client.luau) consome o resultado. | Sequências por arma, recuperação e amostragem determinística pertencem ao K-17. Não são padrões de spray importados de Counter-Strike ou Evostrike. |
| Mola da arma | [TacticalSpring.luau](../src/maps/k17/gameplay/TacticalSpring.luau) adapta o ramo escalar de amortecimento crítico de Fraktality/spr, explicitamente MIT no arquivo `c_spr.lua` do Evostrike. [WeaponMotion.luau](../src/maps/k17/gameplay/WeaponMotion.luau) usa a mola para balanço, reação ao mouse e impulso de tiro. | Deslocamento local da arma; não altera regras de dano nem cria outro controlador de câmera. |

O adaptador de movimento lê a velocidade composta existente de `MovementState`
via `Humanoid.WalkSpeed`, calcula a entrada desejada e a entrega ao Humanoid.
Não escreve velocidade física nem cria outro escritor de `WalkSpeed`. É uma
adaptação ao controlador Roblox; a resposta física real depende do Humanoid e
precisa ser observada no motor. Zumbis, contenção por tiro, barricadas e contatos
continuam nos sistemas existentes.

O disparo usa o recuo vertical/lateral na apresentação da câmera e um impulso
separado na arma. Mirar reduz o efeito; trocar de arma, morrer ou encerrar a
apresentação limpa o estado acumulado. A compra, munição, cadência, dano,
infecção e rodada continuam sob a autoridade atual do servidor.

## Fontes e licenças

Os originais exatos, revisões e licenças integrais ficam em
[third_party/tactical-fps-sources](../third_party/tactical-fps-sources/ATTRIBUTION.md).
O [manifesto](../third_party/tactical-fps-sources/SOURCE.json) registra os hashes
e tamanhos; os arquivos arquivados não são iniciados pelo perfil Rojo.

O Evostrike completo é GPLv2. Desta referência foi reutilizada apenas a
biblioteca de terceiro `spr`, cujo próprio arquivo declara MIT e identifica
Fractality. A licença MIT original e a evidência da API estão preservadas.
Os controladores GPL-only de movimento, armas, inventário e câmera do Evostrike
não foram incorporados. A licença do projeto não foi alterada.

Esta entrega aplica componentes à base atual. A migração para um sistema FPS
completo, os assets ausentes dos projetos auditados e a qualificação do template
oficial FPS System continuam fora deste conjunto limitado. A
[comparação das bases recebidas](CS_FPS_BASES_VERIFIED.md) permanece como registro
da pesquisa.

## Verificação executada e roteiro no Studio

Passaram os testes do núcleo de movimento, do adaptador humano, do movimento da
arma e do cliente de armas com APIs simuladas. Os fontes arquivados foram
comparados aos commits indicados, e os hashes e o blob da licença MIT foram
conferidos. Essas verificações não executam o Humanoid ou a câmera do Roblox e
não aprovam aparência, sensação de controle, colisões ou multiplayer.

Resultado final na nuvem:

- 42 verificações do núcleo de movimento, 89 do adaptador, 29 de mola/recuo,
  19 de movimento da arma e 129 do cliente de armas passaram. Captura de chat,
  menu e foco interrompe a entrada de movimento; teclas equivalentes não somam
  duas vezes. Rajadas testam o recuo lateral e a recuperação sem realimentação.
- Regressões de combate, rodada, ciclo integrado, loja, equipamento, composição
  de velocidade e barricadas passaram; os 30 testes Python e a compilação Luau
  também passaram. Os testes dos controladores usam APIs simuladas.
- Rojo 7.7.1 gerou os dois places nativos. Os perfis jogável e de teste passaram
  a conferência de 39 fontes exatos. O cenário automático separado tem o código
  atual, mas não foi executado no Studio nem comprova a nova locomoção analógica.
- O binário jogável tem 305.069 bytes, 8.082 instâncias e SHA-256
  `9ac22b484f6def092d2eb60329d97134795a48a9f3a073dd88417976b2c1050f`.
  O mapa e os modelos de armas não foram alterados nesta entrega: permanecem
  quatro classes, seis skins adicionais, 164 barricadas e quatro dutos. Os
  215 percursos e 38.374 amostras de circulação passaram novamente.

Após sincronizar ou recompilar os fontes atuais, abra o K-17 em um place de
teste separado. Para uma rodada normal, use dois clientes; mantenha um humano
para observar os controles abaixo.

1. **Shift** corre, **Alt** caminha, **Ctrl** agacha enquanto segura e **C** alterna
   agachamento. Compare as velocidades e confira que soltar os controles restaura
   a postura correta. A corrida abaixa a arma e bloqueia o disparo.
2. Caminhe e corra por piso, rampas e escadas; pare e alterne **A/D** para conferir
   frenagem e inversão lateral. Observe saltos, contato com paredes e barricadas
   sem atravessamentos, aceleração inesperada ou movimento residual.
3. Abra **B** durante a preparação e compre outra classe. Compare tiros isolados
   e rajadas; pause entre rajadas e confira o reinício da sequência de recuo.
   Mire com o **botão direito** (ADS) e compare a redução do efeito.
4. Troque com **1/2**, recarregue com **R** e repita após morte/respawn. Confira
   que câmera e arma retornam à posição normal, sem recuo acumulado. Repita com
   dois clientes para observar dano, munição, infecção e contenção no servidor.

Registre o comportamento observado e os erros do Output. Nenhuma execução real
desse roteiro no Studio é alegada nesta entrega.
