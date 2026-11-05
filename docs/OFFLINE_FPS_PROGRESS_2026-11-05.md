# Movimentação tática e loja — 05/11/2026

**Registro histórico do commit `13603bf`.** A entrega seguinte muda Shift para
corrida e Alt para caminhada, acrescentando integração com armas e precisão.
Consulte o [estado atual](FPS_GAMEPLAY_DELIVERY_2026-11-05.md).

Entrega na branch `feat/fps-combat-package`, preparada sem depender de acesso
local ao Roblox Studio. O mapa e seus objetos não foram reconstruídos nesta etapa.
O FPS System oficial continua candidato aguardando seu arquivo para auditoria;
não está incluído nem foi substituído por uma integração alegadamente completa.

## O que muda para jogar

- Movimento normal mantém a velocidade existente: humanos 16, zumbis 19.
- Shift segurado: caminhada a metade da velocidade; não há aceleração extra.
- Ctrl segurado ou C alternado: agachamento a metade da velocidade, postura
  replicada por juntas existentes e deslocamento suave da câmera.
- Controle: L3 alterna caminhada, B alterna agachamento quando os menus estão
  fechados. Toque: botões Andar e Agachar. Pular solicita sair do agachamento.
- O servidor verifica o volume percorrido pela cabeça antes de permitir levantar.
  Sob uma viga/teto, mantém a postura e mostra “Sem espaço para levantar”.
- A loja B tem filtros Todas, Pistolas, Rifles, SMG e Escopetas. As teclas
  numéricas seguem os cartões visíveis. Fora da loja, 1/2 mantêm os slots.
- Mudar de categoria atualiza seleção/prévia sem descartar compras pendentes.

Não há novos modelos de arma nesta entrega. Carabina e pistola preta continuam
embutidas; SMG e escopeta continuam indisponíveis enquanto faltarem os modelos.
Os filtros não desbloqueiam equipamentos ausentes nem mudam preços/economia.

## Integração e reutilização

`MovementState` compõe velocidade de equipe, postura e efeito de tiro para
Round, Combat e Movement. Nenhum desses controladores escreve WalkSpeed
separadamente. O módulo guarda o valor efetivamente armazenado pelo Humanoid,
evitando tratar arredondamento como nova velocidade base e acumular lentidão.

Exemplo: zumbi em movimento normal tem 19; agachado, 9,5; sob contenção por tiro,
5,225. Ao terminar o efeito, volta a 9,5 enquanto agachado e a 19 ao levantar.
Trocar de postura durante o efeito mantém a duração restante. Infecção atualiza
a base da equipe e respeita o bloqueio de teto ao recuperar a postura.

A seleção de modos/interpolação da câmera e a redução de torso/quadril foram
adaptadas de [voximity/extract](https://github.com/voximity/extract), revisão
`45afa80c93eeb8f4b21a84bab8a4b14a30ff33cc`, sob MIT. Os fontes exatos, hashes e
licença estão em [third_party/extract-movement](../third_party/extract-movement/ATTRIBUTION.md).
O padrão original R6 foi adaptado às juntas Motor6D existentes em R6/R15.
Não se ativam a câmera, o combate, o inventário ou downloads de assets do projeto
original. Validação de intenção, sincronização, espaço livre e composição com
o combate são a integração específica do K-17.

O cliente envia somente Run/Walk/Crouch. O servidor valida personagem vivo,
equipe e fase, mantém a intenção mais recente e atualiza a postura em frequência
limitada. Não recebe velocidade escolhida pelo cliente. A câmera altera apenas
CameraOffset, sem concorrer com mira, recuo ou o controlador padrão do Roblox.
As colisões do mapa e as propriedades físicas das barricadas permanecem intactas.

## Verificações e limite da entrega

Testes dos fontes reais executados com APIs Roblox simuladas:

| Área | Verificações |
| --- | ---: |
| Composição de velocidade | 66 |
| Servidor de postura e juntas | 35 |
| Cliente de movimento | 57 |
| Combate | 156 |
| Rodadas | 41 |
| Ciclo Survival integrado | 39 |
| Loja/categorias | 73 |
| Cliente de armas e feedback | 91 |

Também se recompilam os scripts Luau, o place jogável e o place de validação,
conferindo fontes incorporados e separação dos drivers de teste. O cenário em
`tests/studio` passa a conter 21 etapas, incluindo altura da cabeça, bloqueio sob
teto e recuperação de postura com dois clientes; **não foi executado no motor**.

Ficam para quando houver Studio: aparência R6/R15 em movimento, contatos físicos,
passagem pelos dutos/refúgios, suavidade da câmera, controles em dispositivos e
replicação sob latência. Testes com APIs simuladas não aprovam esses resultados.
Não é necessário interromper a edição para executar essas ações agora.

O place jogável continua `builds/ZombieOutbreakReborn_K17.rbxl`, aberto por
`ABRIR_K17.cmd` após Pull da branch correta e reabertura do arquivo. Atualizar o
Git não altera uma experiência salva já aberta no Studio.

## Backup

Estado anterior preservado na branch `backup/before-offline-fps-work-5273331`,
commit `5273331d59e85a07da484d267dfaec610762d28b`, e em arquivo tar verificado
na nuvem. `main` não recebe este pacote FPS incompleto nesta entrega.
