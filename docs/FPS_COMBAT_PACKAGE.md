# Pacote FPS — implementação e pendência de modelos

**Estado: carabina e pistola preta embutidas; SMG e escopeta ainda pendentes.**
A pistola oficial foi extraída do arquivo `Pistolas_Oficiais.rbxl` fornecido pelo
usuário. O pacote é compilável e usa os modelos incluídos sem importação de
prefabs ao iniciar Play. A integração ainda precisa de validação visual, áudio
e multiplayer no Roblox Studio; esta máquina não executou o motor.

## Pistola oficial incluída — 31/10

Foi selecionada a variante preta `Workspace/Pistol2`, com SourceAssetId
`118912302094201`. O arquivo recebido contém três variantes com cópias em
StarterPack: nove Tools e 144 instâncias de scripts, equivalentes a 16 fontes
únicas. Todas têm Handle direto. O problema demonstrado era a multiplicidade de
variantes, não a ausência de Handle. O importador manual agora seleciona Pistol2
de forma determinística e rejeita ambiguidades com contagem e nomes.

A Tool completa revisada está arquivada fora do perfil ativo. A extração mantém
os três meshes, texturas pretas, grip, attachments, flash, ferrolho e sons
originais de tiro `3806566911` e recarga `3821789416`. Remove WeaponsSystem,
controladores, remotes, tags e efeitos globais antigos. Não há um segundo sistema
de combate/câmera rodando. A pistola usa as mesmas animações RifleAim/ADS/Reload
que o próprio kit original especifica, já presentes com a AR.

O runtime contém exatamente duas Tools e seis MeshParts. A carabina foi
preservada. O arranque não chama LoadAssetAsync; publica os estados Bundled/Missing
e a loja informa os modelos ausentes sem fingir download. SMG e Shotgun continuam
indisponíveis, sem cobrança. Backup: `backup/before-pistol-integration-e892a4f` e
tar verificado. Origem, hashes e licença estão no manifesto e na revisão da
[pistola](../third_party/roblox-weapon-kit/pistol/REVIEW.md).

Para testar esta entrega:

1. Atualize `feat/fps-combat-package` no GitHub Desktop. Preserve seu trabalho e
   abra `ABRIR_K17.cmd` para carregar o novo binário. Um Pull não atualiza uma
   experiência já aberta/salva no Roblox.
2. Em Play, humano vivo, **feche a loja e pressione 2**. Confira a pistola preta,
   alinhamento e braços R15. Clique para cada tiro; ela é semiautomática.
3. Dispare, recarregue com **R**, use a mira e volte à carabina com **1**. Confira
   os dois sons originais e a preservação da munição ao trocar.
4. Abra **B** e selecione a pistola: a prévia 3D deve usar o mesmo modelo. As
   teclas numéricas com a loja aberta selecionam linhas do catálogo, não slots.
5. Com dois clientes, confira a pistola nas mãos do outro jogador, áudio de tiro
   e recarga, remoção na infecção e retorno na rodada seguinte.

Passaram 35 verificações do importador, 22 do bootstrap sem rede, 53 da loja,
88 do cliente de armas, 151 de combate e 39 do ciclo integrado, com APIs
simuladas. Os oito testes de assets conferem a origem e conteúdo reais, referências
resolvidas, meshes/áudio preservados e ausência de código na extração. Isso não
comprova aparência, execução auditiva ou comportamento físico no motor.

## Alterações implementadas nos fontes

- Uma apresentação por arma, compartilhando templates entre primeira pessoa,
  modelo corporal e prévia 3D da loja. Braços reutilizam o rig R15 do jogador;
  R6 recebe o modelo da arma sem braços/animações R15.
- Mira no botão direito, L2 e toque; FOV é restaurado ao recarregar, trocar,
  morrer, infectar ou abrir menus. Recuo tem recuperação e o retículo acompanha
  movimento/disparo. A dispersão de mira é decidida pelo catálogo do servidor.
- Reprodução genérica dos sons originais de tiro e recarga; áudio posicional
  para observadores e impactos somente quando o servidor confirma uma superfície.
  Disparos de escopeta não repetem o áudio em cada raio visual.
- Compra com ViewportFrame, seleção rápida, comparações e temporizador. Preços,
  posse, dano, cadência, munição e infecção continuam sob autoridade do servidor.
- Modelos ausentes não são substituídos por blocos nem cobrados na compra.
  A interface informa carregamento/falha e recupera imports tardios.

O catálogo tem **carabina, submetralhadora, escopeta e pistola**. A metralhadora
provisória foi retirada por não haver um modelo licenciado verificado para ela.

## Arquivos e objetos removidos

Foram removidos os controladores legados não mapeados de Rifle/RoundHUD em
`src/client`, Combat/ZombieRound/MapDiagnostics em `src/server`, o helper exclusivo
`ReusedRiflePresentation` e a extração antiga `Presentation.rbxmx`. Os dois
Bootstraps ativos foram preservados.

Os geradores de armas/clarões/garras de blocos saíram de `Weapons.client`.
Templates Bullet/trails/casing sem consumidor foram retirados; apenas o efeito
de impacto original agora usado foi mantido. A limpeza de inicialização remove
HUDs e visuais antigos identificados; não apaga Tools arbitrários do jogador.
O arquivo original do kit e suas licenças permanecem fora do runtime como origem.

Backup: `backup/before-combat-package-9cc13d7` e arquivo local correspondente.

## Correções de lentidão e postura — 29/10

Os testes de combate anteriores guardavam `WalkSpeed` com precisão de Luau e
não representavam o arredondamento da propriedade no motor. Reproduzindo esse
limite em float32, cada impacto confundia a velocidade reduzida com uma nova
velocidade base e aplicava o fator novamente; a comparação na recuperação também
falhava. O controlador agora registra a velocidade lida depois da atribuição.
Acertos renovam a duração do efeito sem multiplicar a redução. Com os parâmetros
atuais, a base 19 vira aproximadamente 10,45 durante a contenção e recupera 19
depois de cessarem os impactos e expirar a janela de 0,18 s mais a manutenção.

A oscilação de postura também tinha uma causa de integração: as faixas originais
`RifleAim` e `RifleAimDownSights` são bancos de poses de mira, mas estavam sendo
reproduzidas em loop. `WeaponAimPose` reutiliza a seleção de pose de
`BulletWeapon:onRenderStepped` do kit arquivado. A pose neutra fica mantida,
inclusive quando a duração da animação chega depois; `Reload` avança normalmente.
A apresentação corporal usa a pose horizontal, sem uma nova rede de inclinação
da câmera. A primeira pessoa acompanha a câmera pelo rig local.

Backup desta correção: `backup/before-hit-tag-fix-8b64304` e tar verificado.
Os parâmetros de contato/impulso das barricadas não foram alterados.

Para conferir no Studio, atualize **`feat/fps-combat-package`**, salve seu trabalho
e reabra **`ABRIR_K17.cmd`**. Com dois clientes:

1. Durante a preparação, observe o outro humano parado por alguns segundos. Ele
   não deve percorrer repetidamente poses de mirar para baixo e para cima.
2. Faça mira e recarga; observe nos dois clientes se postura e animação continuam
   coerentes, sem arma duplicada.
3. Após a infecção, acerte o tronco do zumbi com uma rajada curta. A contenção
   não deve aumentar a cada tiro. Pare de atirar: o zumbi deve recuperar a
   velocidade normal e conseguir avançar novamente. Repita a sequência.

O place separado `builds/ZombieOutbreakReborn_SurvivalTest.rbxl` prepara agora
16 verificações, incluindo recuperação após tiro e rajada. Os personagens desse
cenário são ancorados: ele verifica a propriedade de velocidade, não deslocamento
ou física de contato. As verificações visuais acima precisam dos clientes reais.
**Nenhuma dessas validações no motor foi executada nesta nuvem.**

## Recuo e carregamento oficial — 31/10

O recuo agora compõe o estado completo restante sobre a câmera fornecida pelo
Roblox em cada quadro, como no `ShoulderCamera` do kit reutilizado. Antes da
atualização da câmera, remove apenas o offset que ainda pertence ao pacote.
Isso evita a inversão para baixo na recuperação e a realimentação do recuo na
orientação base. Disparos automáticos usam a direção apresentada naquele quadro.
Menus, infecção, foco, troca de arma e de câmera continuam cancelando o efeito.

O importador passou para a API oficial atual `AssetService:LoadAssetAsync`.
`IMPORTAR_ARMAS.cmd` copia o comando de edição para a área de transferência no
Windows, sem exigir VS Code. Ele não executa comandos remotamente no Studio.
O comando informa importações parciais, pedidos ainda pendentes e erros de
permissão, preserva backup e orienta salvar uma cópia fora de `builds`.

Backup: `backup/before-fps-polish-c1fc793`, tar verificado e cópia das alterações
pendentes antes da retomada. Os três modelos ausentes continuam sem ser obtidos.

## Resultado real do Studio — 31/10

O primeiro Output enviado pelo usuário confirma que o comando foi executado em modo de
edição e preservou o backup. Os quatro prefabs retornaram
`User is not authorized to access Asset.` Nenhum modelo oficial novo foi obtido.
O usuário confirmou que **Allow Loading Third Party Assets** estava desligada.
Habilitar essa opção permite modelos públicos gratuitos de terceiros, mas não
concede acesso a assets privados ou indisponíveis.

Na nova tentativa às 07:54, o usuário abriu a experiência salva no Roblox/Team
Create. Os quatro carregamentos passaram para a validação do importador, que
rejeitou a estrutura com `Prefab must contain exactly one complete weapon Tool`.
O comando e o contador da versão atual aparecem no log. O bloqueio agora é nossa
suposição de uma Tool com Handle direto; a estrutura precisa ser inspecionada.

Às 08:18, a captura independente voltou a receber recusa de autorização para os
quatro IDs e terminou com zero modelos. O usuário então obteve a pistola pelo
Toolbox e enviou o arquivo nativo. Sua integração atual está descrita no início
deste documento; as tentativas anteriores não comprovam acesso estável às APIs.

O mesmo Output confirmou o `HitSound` de impacto `1489924400` arquivado. Esse
Sound foi removido da extração ativa; as partículas e sons de tiro/recarga foram
preservados. O ID `203785492` com erro de tipo não aparece nos fontes ou chunks
descomprimidos dos places e do kit original; sua origem continua não identificada.

O importador agora distingue falha total de importação parcial, informa quantos
modelos foram importados/cacheados/falharam e não orienta exportar modelos novos
quando todas as tentativas falham. O arquivo anterior da carabina permanece.
Backup: `backup/before-asset-errors-5e0227f` e tar verificado.

## Capturar a estrutura real na experiência salva

Salvar e abrir a experiência no Roblox é compatível com a captura. O Pull do Git
atualiza o checkout local, mas não modifica automaticamente os ModuleScripts da
experiência salva/Team Create. Não é necessário trocar esse place para obter os
modelos que agora carregam com sua conta/configuração.

1. Faça Pull de `feat/fps-combat-package` no GitHub Desktop e mantenha aberta a
   experiência salva onde ocorreu a tentativa às 07:54. Pare o Play.
2. Execute **`INSPECIONAR_ARMAS.cmd`** na pasta do repositório. Ele copia o
   comando independente [CaptureOfficialWeapons.luau](../tools/studio/CaptureOfficialWeapons.luau).
3. Cole na **Command Bar** com **Ctrl+V** e execute com **Enter**.
4. Confira `[K17 REVIEW]` no Output. A pasta de revisão será selecionada em
   `ServerStorage.ZO_OfficialWeaponReview_<timestamp>`. Exporte essa pasta como
   **`ZO_OfficialWeaponReview.rbxm`** ou **`.rbxmx`** e envie o arquivo para revisão.

A captura não depende do importador salvo nem altera os templates de combate.
As fontes legíveis são preservadas como StringValues, sem execução. Scripts,
remotes, bindables e PackageLinks são retirados antes de guardar os modelos;
geometria subordinada a esses objetos é preservada, e os sons ficam parados.
`OriginalHierarchy` registra a árvore original e os requisitos de Handle.
O resultado é material para adaptar o importador aos modelos reais, não armas
integradas ou aprovadas para jogo. A estrutura desses quatro modelos ainda não
foi recebida nesta nuvem.

Passaram 75 verificações do comando real com APIs simuladas, incluindo
publicação apenas de conteúdo sanitizado, fontes em texto inerte, preservação
dos templates existentes, falha parcial/total, captura sem Tool e bloqueio em
Play. A captura ainda precisa ser executada no Studio. Backup:
`backup/before-prefab-review-23f703b` e tar verificado.

## Dependência de modelos que continua aberta

| Arma | Prefab oficial | Situação nesta nuvem |
| --- | --- | --- |
| Rifle | 96131146947811 | AR anterior embutida e preservada |
| SMG | 119916677125479 | Prefab não obtido |
| Shotgun | 104068096273092 | Prefab não obtido |
| Pistol | 118912302094201 | Pistol2 preta fornecida pelo usuário, revisada e embutida |

Fonte: documentação oficial do [Roblox Weapons Kit](https://create.roblox.com/docs/resources/weapons-kit),
registrada também em `third_party/roblox-weapon-kit/SOURCE.json` e nas licenças
preservadas. Nenhum modelo ou ID de som novo foi inventado.

As consultas ao AssetDelivery e à documentação falharam com
`Tunnel connection failed: 403 Forbidden`. O proxy bloqueou o destino; não houve
resposta da origem nem teste de autenticação Roblox. A configuração da nuvem
estava restrita a outros domínios. Foi salvo um rascunho acrescentando
`assetdelivery.roblox.com`, `apis.roblox.com`, `create.roblox.com` e `*.rbxcdn.com`.
**Revisar/salvar as configurações e publicar o ambiente é necessário para ativar
a mudança.** Salvar o rascunho não liberou a rede desta execução.

## Importação preparada para o Roblox

`WeaponAssets.server` usa apenas os templates incluídos ao iniciar Play. A
importação por `AssetService:LoadAssetAsync` é uma ação manual opcional de edição,
substituto moderno de `InsertService:LoadAsset` conforme a
[documentação oficial fixada](https://github.com/Roblox/creator-docs/blob/c8f5276703948ef4868c9b9fd44fae619dbe2f11/content/en-us/reference/engine/classes/AssetService.yaml).
A operação depende das permissões da experiência/conta Roblox. A primeira tentativa
falhou por autorização; a mais recente falhou na estrutura esperada. O importador elimina scripts, remotes e PackageLinks no
container desconectado, valida Tool/meshes/grip/áudio e só então publica a cópia.
Uma falha fica em `ReplicatedStorage.ZO_WeaponAssets`, atributos `Status_<id>` e
`Error_<id>`, sem paralisar as rodadas. O rifle embutido continua disponível.

Para tentar a importação local sem VS Code:

1. Atualize `feat/fps-combat-package`, abra `ABRIR_K17.cmd` e pare o teste no
   Studio. Salve uma cópia do seu trabalho antes de continuar.
2. Execute **`IMPORTAR_ARMAS.cmd`** na raiz do repositório. Ele copia o arquivo
   [ImportOfficialWeapons.luau](../tools/studio/ImportOfficialWeapons.luau).
3. No Studio, abra **Command Bar** e **Output**, cole o comando com **Ctrl+V**
   e execute com **Enter**, em modo de edição. Ele faz backup em `ServerStorage`
   antes de substituir templates.
4. Confira os quatro resultados `[K17 ASSETS]` e os modelos selecionados. Se o
   carregamento ainda estiver pendente após 25 segundos, espere e execute o
   comando novamente. Uma falha parcial não equivale a quatro armas prontas.
5. Em erro de propriedade/permissão, revise **Experience Settings → Allow
   Loading Third Party Assets** para permitir modelos públicos gratuitos que
   não atendam às regras de propriedade/compartilhamento. Essa exigência depende
   do asset e da conta; não foi verificada para os quatro prefabs. O script não
   lê nem altera essa opção protegida.
6. Salve o place **como uma cópia fora de `builds`**. Não sobrescreva o arquivo
   verificado: isso faria o checksum do `ABRIR_K17.cmd` divergir. Exporte a pasta
   `ZO_WeaponAssets` selecionada como **`ZO_WeaponAssets_Official.rbxmx`** para
   compartilhar/incorporar os modelos realmente obtidos ao Git.

O comando local já foi executado pelo usuário. A pistola foi finalmente fornecida
como arquivo nativo após inserção pelo Toolbox e agora está incluída no binário.
As instruções de importação/captura acima servem para modelos adicionais.
O atalho Windows não foi executado nesta máquina Linux.
A importação não publica a experiência no Roblox.

## Testes e limites

Foram executados testes dos controladores reais de combate, loja e armas, com
APIs substitutas; o teste de armas usa um spy para apresentação. O importador foi
exercitado com árvore/AssetService simulados: remoção de scripts, falhas parciais,
rejeição de modelo sem mesh e recuperação posterior. Isso não comprova permissões
nem compatibilidade dos prefabs que não foram baixados.

Resultados do pacote inicial: 119 verificações de combate, 63 do cliente de armas,
52 da loja, 13 do importador, 41 de rodada e 39 do ciclo integrado passaram.
Também passaram os 23 testes Python, a compilação Luau e os builds Rojo. O arquivo
compilado agora confere 28 fontes ativas e rejeita os controladores/templates antigos.

Após as correções de 29/10, passaram 151 verificações do controlador de combate,
39 do ciclo integrado, 63 do cliente de armas, 22 do adaptador de poses e 24 do
controlador corporal com o adaptador real. A simulação de combate agora arredonda
`WalkSpeed` em float32; o teste corporal avança o tempo das faixas. Os mesmos
testes falham com os controladores anteriores. Também passaram os 23 testes
Python, a compilação Luau e a conferência dos dois places recompilados. Isso
continua sem executar o Animator, a rede ou os contatos físicos do motor Roblox.

Na revisão de 31/10, passaram 88 verificações do cliente de armas e 18 do
importador com APIs simuladas. O teste de câmera executa quadros em ordem de
prioridade, com reconstrução da base e realimentação da orientação; o controlador
anterior falha no caso de inversão do recuo. Esses testes não aprovam a sensação
de tiro no motor nem comprovam o download dos prefabs.

Após o Output de falha total, passaram 27 verificações do importador, incluindo
quatro recusas de autorização, preservação da carabina e recuperação posterior
com APIs simuladas. A regressão de assets verifica que a referência arquivada
não retorna ao pacote, preservando partículas e áudio original de tiro/recarga.

O arquivo de validação Survival separado foi mantido. Antes de aprovar o pacote,
testar dois clientes, quatro templates carregados, mira/recarga/troca/compra,
áudio ouvido pelo outro jogador, infecção e reinício. Executar também
`require(game.ServerStorage.ZO_Validation.GameplayAudit).run()` no servidor; ele
agora falha explicitamente quando algum template do catálogo está ausente.
