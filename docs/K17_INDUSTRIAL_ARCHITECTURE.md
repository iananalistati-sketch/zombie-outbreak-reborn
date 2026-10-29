# K-17 — revisão da arquitetura industrial

Esta revisão altera a geometria ativa do K-17. A aparência, iluminação, controles
e desempenho ainda precisam de inspeção no Roblox Studio. A imagem
[K17_OVERVIEW.png](K17_OVERVIEW.png) é uma projeção do modelo, sem materiais e luz
renderizados pelo motor.

## Construções alteradas

- **Fundição:** as quatro claraboias anteriores estavam sobre uma laje opaca.
  A cobertura agora tem quatro aberturas reais, fechadas acima por monitores
  industriais com vidro vertical, laterais triangulares e teto metálico inclinado.
  Os acessos ao telhado e o posto defensivo existente continuam acessíveis.
- **Recebimento:** marquise em balanço de 64 × 19,5 studs, com apoios na fachada.
  A rota do pátio passa por baixo sem postes atravessando a circulação.
- **Estação de energia:** dois conjuntos de exaustão até Y=66,25, com carenagens,
  dutos cilíndricos, juntas, apoios e conexões à fachada.
- **Torre:** último pavimento com faixa panorâmica, uma porta frontal real e
  passarela externa contínua de seis studs. Duas rotas ligam a passarela às
  escadas existentes; humanos e zumbis usam os mesmos acessos.

Molduras horizontais foram consolidadas em travessas contínuas, interrompidas nas
portas. Postes de guarda-corpo coincidentes foram deduplicados. Com isso, as três
intervenções usam **5.448 peças**, contra 5.431 antes: saldo de 17 peças, mantendo
o limite de 5.500. Há 94 luzes locais, oito com sombras. Isso é um orçamento de
construção, não uma medição de FPS.

## Abrir e encontrar as alterações

1. Atualize a `main` pelo GitHub Desktop e salve o seu place aberto.
2. Execute `ABRIR_K17.cmd` para abrir `builds/ZombieOutbreakReborn_K17.rbxl`.
3. No Explorer, selecione os modelos abaixo e pressione **F**:

| Dentro de `Workspace.ZO_K17Foundry` | Conferir |
| --- | --- |
| `C_FoundryHall` | Quatro monitores inclinados e marquise sobre o recebimento |
| `B_PowerStation_ProcessSystems` | Dois conjuntos de exaustão e dutos |
| `T_ControlTower` | Cabine envidraçada no último andar e passarela externa |

Em Play, caminhe da entrada da torre até o último andar pelas duas escadas,
atravesse a nova porta e percorra a passarela. Na fundição, confira as aberturas
pelo interior e os monitores pelo telhado. Compare luz e legibilidade em qualidade
gráfica baixa e alta. Esses percursos ainda não foram executados por Humanoid aqui.

A auditoria preparada para o Studio ganhou os caminhos da passarela e quatro
testes de raycast para detectar laje fechando as claraboias:

```lua
require(game.ServerStorage.ZO_Validation.K17Audit)()
```

Use Play e a Command Bar em contexto Server. Essa auditoria foi compilada,
mas não executada no motor nesta nuvem.

## Verificações de geometria

Os 215 percursos passaram por 38.374 amostras de apoio/espaço livre. Os 34 refúgios,
132 posições de grupo, 164 objetos e quatro dutos passaram nas verificações
existentes. Dois testes novos verificam os vãos da cobertura e rejeitam uma laje
opaca inserida sob o vidro. Cunhas e cilindros usam AABBs conservadoras no
verificador; nenhum percurso depende de caminhar sobre suas superfícies curvas.

Fontes de arquitetura: `scripts/k17_foundry_architecture.py`,
`k17_power_architecture.py` e `k17_tower_architecture.py`, integrados ao construtor
existente. O cenário é salvo no desenvolvimento; essas funções não rodam na partida.

## Materiais e recursos externos

Esta entrega usa construções originais e os materiais nativos do Roblox.
Não foram instalados meshes externos ou materiais PBR personalizados.

A pesquisa retomou o City Kit Industrial da Kenney, cuja procedência está em
[HARBOR_LOCKS_SOURCES.md](HARBOR_LOCKS_SOURCES.md). O GLB anterior exige importação
e publicação de meshes no Studio e não foi reativado. Nenhum pacote industrial
nativo com licença e dependências verificadas foi obtido. A consulta de material
no ambientCG retornou HTTP 403; ele não foi incorporado como recurso verificado.

Melhoria de texturas, assets detalhados e aprovação visual continuam pendentes.
O backup anterior é `backup/before-industrial-map-a3b0615`.
