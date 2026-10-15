# K-17 — início da partida e refúgios com dutos

> Registro histórico da etapa `576dd80`, com oito refúgios e 40 objetos. O mapa
> atual tem 34 refúgios detalhados e 164 objetos; siga o
> [roteiro atualizado de defesa](K17_DEFENSE_DENSITY.md). As contagens e testes
> abaixo descrevem a entrega daquela etapa.

Esta revisão atende ao relato de dois jogadores sem progressão e de posições
abertas demais. A versão anterior está em `backup/before-ducts-0a38374` e em um
tar verificado no ambiente da nuvem.

## Partida com dois jogadores

Atualize **main** pelo GitHub Desktop e **reabra**
`builds/ZombieOutbreakReborn_K17.rbxl`. O Pull não altera um place já aberto.
No Studio, inicie um servidor local com **dois jogadores**. Depois que os dois
personagens carregarem e o combate iniciar, a sequência esperada é:

1. **Próxima rodada — 5 segundos.**
2. **Prepare sua defesa — 15 segundos**, ambos humanos e armados.
3. **Sobreviva**, com um primeiro infectado transformado onde estiver.
4. Golpe acertando o humano causa infecção; humanos vencem ao sobreviver ao tempo.

O controlador agora exige personagens vivos com raiz carregada antes da
preparação. Dependências ausentes ou falha no combate/rodada deixam erro
persistente na interface, com diagnóstico no Output do servidor. Uma barricada
com falha é isolada e relatada; não interrompe as rodadas ou os outros objetos.

**A causa específica observada no Studio ainda não foi reproduzida aqui.** O
controlador anterior avançou com dois personagens simulados prontos. Os defeitos
reproduzidos foram preparação com avatares ainda carregando e espera indefinida
por dependência ausente; o HUD antigo ocultava startup incompleto como espera
normal. Não se conclui que esses defeitos explicam todo o relato do usuário.
Se a partida ainda parar, copie a mensagem de falha do HUD e o primeiro erro
vermelho do Output do **servidor**. Não remova o erro para forçar a rodada.

## Dutos e novas posições

![Oito exemplos dos 34 refúgios atuais, calculados a partir do XML](K17_REFUGES.png)

Os tetos foram cortados nesta prévia para inspecionar os interiores. No place,
as três salas novas e todos os dutos têm teto e paredes com colisão.

- **16 — Sala de filtros:** sala fechada dentro da fundição, anteparo na entrada,
  bancada, filtros e quatro objetos. O duto sai na área de produção com curva,
  interrompendo a visão direta desde a extremidade.
- **17 — Oficina do pátio:** abrigo novo na área externa, com divisória interna,
  três objetos e duto de serviço em L. Reduz a travessia exposta pelo pátio.
- **18 — Refrigeração:** sala fechada junto à produção, dois tanques, anteparo,
  quatro objetos e duto lateral sob a galeria.
- **Estoque:** ganhou passagem metálica em L e oito objetos ao todo.
- **Arquivo, expedição, contêiner e bombas:** receberam mais objetos; são
  naquela etapa, havia **40 objetos físicos** distribuídos entre **oito refúgios
  detalhados**, com 18 posições de resistência registradas ao todo.

Os dutos têm vãos de **7,2 studs de largura e altura**, próprios para o avatar
de verificação andar sem agachar. Há piso, teto, duas extremidades abertas e uma
curva real. Não são grades decorativas e não exigem atravessar parede. O projeto
ainda não implementa agachamento físico ou dutos baixos de rastejar.

Para visitar rapidamente, com **um jogador em Play**, Command Bar **Server**:

```lua
require(game.ServerStorage.ZO_Validation.RefugeAudit).visit(16)
```

Troque por `17`, `18` ou `7`. O treino habilita o rifle; contato e tiros movem
os objetos, R recarrega. Pare e reinicie Play para restaurar tudo. No teste com
dois jogadores, visite as posições caminhando durante a preparação/rodada.

## Adaptação de Counter-Strike

É possível reimplementar em Luau as regras verificadas de Zombie:Reloaded e
ZombieSharp. A preparação de 15 segundos segue uma configuração pública de
ZombieSharp. Plugins SourcePawn/C#/C++ não executam no Roblox e não fornecem
mapas ou dutos. Não foram copiados código ou assets de CS nesta revisão.
Veja as [fontes verificadas e limites da adaptação](CS_ROBLOX_ADAPTATION.md).

O resultado continua em desenvolvimento. Não se afirma equivalência visual,
física ou de balanceamento ao servidor CS desejado.

## Validação executada na nuvem

- **Controlador Round real**, carregado no Luau com APIs Roblox simuladas:
  24 asserções; duas rodadas, dois participantes, infecção, vitória por tempo,
  personagem atrasado, desconexão e falhas de dependência/inicialização.
- **Controlador de barricadas real**, com APIs simuladas: 1.004 asserções;
  catálogo de 40, falha de ownership, isolamento, dano, destruição e restauração.
- **15 testes Python** de geometria; **189 percursos / 34.927 amostras**,
  oito refúgios, quatro dutos, 32 posições e 16 linhas de tiro. Controles negativos
  fecham uma entrada, removem um patamar e eliminam a curva que quebra a visão.
- Compilação Luau e 160 asserções de combate/rodada, 85 de política preservada
  e 198 de impulso. Rojo XML/binário e 15 fontes ativas verificadas.
- **5.415 peças estáticas**, 94 luzes, 8 com sombras. Molduras repetidas foram
  reduzidas para manter o orçamento de 5.500 peças. Os 40 conjuntos físicos
  são separados desse orçamento; não há medição real de FPS ou rede.

Simulações de APIs não executam Humanoid, física, replicação ou renderização
Roblox. Não substituem o teste do servidor e dos dois clientes no Studio.

Com Luau instalado, os testes de controlador podem ser repetidos:

```sh
python scripts/test_round_controller.py --luau CAMINHO_DO_LUAU
python tests/barricades/run_runtime.py --luau CAMINHO_DO_LUAU
```
