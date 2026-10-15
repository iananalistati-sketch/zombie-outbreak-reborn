> Registro dos primeiros refúgios. O mapa atual e seu roteiro de validação estão
> em [densidade de refúgios e barricadas](K17_DEFENSE_DENSITY.md). As descrições e
> contagens abaixo registram a etapa anterior. Santa Aurora foi removida dos
> arquivos atuais, com backup na branch `backup/before-remove-santa-5b9ac4d`.

# K-17 — refúgios e barricadas

Cinco posições foram reconstruídas na arquitetura persistente, com cobertura,
espaço para quatro defensores e duas aproximações verificadas. O mapa continua
sendo Zombie Survival / Zombie Mod: as posições não têm invulnerabilidade.

![Cortes dos modelos reais, com tetos removidos para inspeção](K17_REFUGES.png)

Esta imagem é uma prévia geométrica do XML, sem a iluminação do Studio.

## Ver as mudanças no Windows

1. No GitHub Desktop, selecione **main → Fetch origin → Pull origin**.
2. Salve seu place atual como backup e abra novamente
   **`builds/ZombieOutbreakReborn_K17.rbxl`**, em **File → Open from File**.
   O Pull não atualiza um place que já está aberto.
3. Use **Play**, com um jogador. Na **Command Bar, contexto Server**, execute:

```lua
require(game.ServerStorage.ZO_Validation.RefugeAudit).visit(7)
```

Você aparece dentro do estoque, olhando para a entrada. Troque o número por
**2, 10, 14 ou 15** para visitar as outras posições. O treino solo permite usar
o rifle; segure o clique para atirar, **R** para recarregar. Repetir a visita
repõe munição. **Stop e Play** restauram o cenário e os objetos.

| ID | Mudança arquitetônica | Objetos móveis | O que observar |
| --- | --- | --- | --- |
| 07 — Estoque | Duas portas internas, bancada, pallets, recuo e duto com curva | 3 armários, 1 mesa, 4 caixas | Entrada pelo corredor e flanco pela sala vizinha; os armários ficam próximos da entrada |
| 02 — Arquivo, andar 2 | Divisórias com duas portas, arquivos metálicos na parede e balcão de triagem | 2 armários, 1 mesa, 3 caixas | Linha de tiro comprida até o corredor; um defensor precisa vigiar a porta de serviço |
| 10 — Expedição | Posto de alvenaria com teto, duas portas, mesa de conferência e balcão com abertura real de tiro | 2 armários, 1 mesa, 3 caixas | Porta de carga, flanco da produção e exposição pela abertura do balcão |
| 14 — Contêiner elevado | Dois módulos superiores contínuos, divisória interna de 6 studs e escadas nas duas extremidades | 1 armário, 3 caixas | Ambos os acessos chegam ao piso superior sem exigir salto; nenhum lado é seguro por altura |
| 15 — Bombas | Duas entradas estreitas, três conjuntos de bombas, plataforma elevada com dois acessos e guarda-corpo | 1 armário, 4 caixas | Passagem central permanece livre; é preciso defender os dois túneis |

No modo de edição, os interiores novos estão em `Workspace.ZO_K17Foundry`,
nos modelos `R07_Stockroom`, `R02_Archive`, `R10_ReceivingOffice`,
`R14_ContainerPost` e `R15_PumpBay`. Os 40 objetos estão em `Workspace.ZO_Barricades`.

## Barricadas físicas

Os objetos ficam ancorados no arquivo para edição e são liberados pelo servidor
ao iniciar Play. Cada um tem uma única caixa de colisão; as peças visuais são
soldadas a ela e não acrescentam massa. O servidor mantém a propriedade da física.

- Humanos podem deslocá-los por contato e por tiros que atinjam o objeto.
  Armários têm mais massa que mesas e caixas. Mire no objeto, inclusive abaixo
  da altura da cabeça, quando necessário.
- Tiros acertam o primeiro obstáculo: empurram a barricada e não atingem quem
  estiver atrás dela. Tiros humanos não retiram a vida da barricada.
- Golpes de zumbi empurram e danificam os objetos; destruídos, perdem colisão.
- A preparação da próxima rodada restaura os objetos nas posições originais.
  Um objeto que caia fora dos limites do mapa também é restaurado.
- Há limites de velocidade e rotação. Não existe inventário de construção,
  prévia de posicionamento ou seleção por E neste perfil.

Massas, atrito e impulsos são parâmetros iniciais Roblox, **ainda sem teste de
contato no motor**. Não se afirma equivalência à física Source nem balanceamento
multiplayer. Não há mecanismo de agarrar objetos nesta entrega.

## Validação executada na nuvem

- 189 percursos / 34.927 amostras de apoio e espaço livre.
- 16 aproximações, 32 posições de defensores, 16 linhas de tiro e quatro dutos verificadas
  contra paredes e os 40 objetos na disposição inicial.
- 15 testes Python, incluindo controles negativos: fechar uma porta, remover
  o patamar do contêiner e bloquear a abertura do balcão.
- 198 asserções da política de impulso: direção, massa, disparos repetidos e
  limite de velocidade. Mais 160 do combate/rodada e 85 das regras preservadas.
- Compilação Luau e build Rojo XML/binário; integração de módulos e funções
  privadas no perfil K-17.
- 5.415 peças estáticas de arquitetura, 94 luzes, apenas 8 com sombras;
  40 conjuntos físicos móveis separados. Não há medição de FPS nesta nuvem.

## Validar no Studio

Antes de mover objetos, durante Play em contexto **Server**:

```lua
require(game.ServerStorage.ZO_Validation.RefugeAudit).run()
require(game.ServerStorage.ZO_Validation.BarricadeAudit).run()
```

As auditorias estão preparadas, **não executadas aqui**. Em cada visita, caminhe
pelas duas entradas, empurre uma caixa até uma porta e teste se é possível
recuar. Confira tiros empurrando caixas/armários sem atravessar paredes. Depois,
com dois clientes, confira golpes destruindo objetos, bloqueio de passagem,
movimento visto pelo outro cliente e reposição na preparação seguinte.

O volume da física, a estabilidade ao encostar, a força dos tiros, saltos sobre
coberturas, iluminação e FPS dependem desses testes no Roblox. A nuvem não tem
conexão com o Studio do usuário.

## Manutenção e backup

Arquitetura: `scripts/k17_refuges.py`, chamado por `scripts/build_k17.py`.
Catálogo único de objetos: `src/maps/k17/barricades/catalog.json`, que gera
`Config.luau` e `Stockroom.rbxmx` com `scripts/build_k17_barricades.py`.
Física: `Server.server.luau` e `Physics.luau` na mesma pasta.

```sh
python scripts/build_k17.py
python scripts/build_k17_barricades.py
python scripts/validate_k17.py --quiet
python scripts/validate_refuges.py
python -m unittest discover -s tests -p 'test_*.py'
rojo build default.project.json --output builds/ZombieOutbreakReborn_K17.rbxl
python scripts/check_studio_file.py --write
```

Prévia opcional: `python scripts/render_k17_refuges.py` (NumPy e Pillow).
A versão anterior está preservada no commit `13bf19f`, na branch
`backup/before-refuges-13bf19f` e em um arquivo tar verificado no ambiente da nuvem.
