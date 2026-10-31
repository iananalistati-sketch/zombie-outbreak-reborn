# Pacote FPS — implementação e pendência de modelos

**Estado: código integrado e compilável; entrega completa ainda pendente.**
Os novos prefabs oficiais não foram obtidos pela nuvem. Só a carabina do kit
anterior está embutida. Não houve execução de Roblox Studio, reprodução de áudio
ou validação de braços/animações nesta máquina.

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

## Dependência de modelos que continua aberta

| Arma | Prefab oficial | Situação nesta nuvem |
| --- | --- | --- |
| Rifle | 96131146947811 | AR anterior embutida; atualização oficial não obtida |
| SMG | 119916677125479 | Prefab não obtido |
| Shotgun | 104068096273092 | Prefab não obtido |
| Pistol | 118912302094201 | Prefab não obtido |

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

`WeaponAssets.server` tenta carregar os prefabs por `AssetService:LoadAssetAsync`,
substituto moderno de `InsertService:LoadAsset` conforme a
[documentação oficial fixada](https://github.com/Roblox/creator-docs/blob/c8f5276703948ef4868c9b9fd44fae619dbe2f11/content/en-us/reference/engine/classes/AssetService.yaml).
A operação depende das permissões da experiência/conta Roblox e ainda não foi
executada no motor. O importador elimina scripts, remotes e PackageLinks no
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

O atalho Windows, as permissões e a importação real ainda precisam ser executados
no computador do usuário. A importação não publica a experiência no Roblox.

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

O arquivo de validação Survival separado foi mantido. Antes de aprovar o pacote,
testar dois clientes, quatro templates carregados, mira/recarga/troca/compra,
áudio ouvido pelo outro jogador, infecção e reinício. Executar também
`require(game.ServerStorage.ZO_Validation.GameplayAudit).run()` no servidor; ele
agora falha explicitamente quando algum template do catálogo está ausente.
