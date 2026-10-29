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

`WeaponAssets.server` tenta carregar os prefabs por `InsertService:LoadAsset`.
A operação depende das permissões da experiência/conta Roblox e ainda não foi
executada no motor. O importador elimina scripts, remotes e PackageLinks no
container desconectado, valida Tool/meshes/grip/áudio e só então publica a cópia.
Uma falha fica em `ReplicatedStorage.ZO_WeaponAssets`, atributos `Status_<id>` e
`Error_<id>`, sem paralisar as rodadas. O rifle embutido continua disponível.

No Studio, é possível tentar a importação em modo de edição executando o arquivo
inteiro [ImportOfficialWeapons.luau](../tools/studio/ImportOfficialWeapons.luau)
na Command Bar. Ele faz backup antes de substituir templates. Depois, confira o
Output e os modelos selecionados; salve/exporte `ZO_WeaponAssets` como RBXMX para
que os prefabs efetivamente obtidos possam ser incorporados ao Git. Essa execução
local também permanece pendente e pode exigir obter os assets oficiais na conta.

## Testes e limites

Foram executados testes dos controladores reais de combate, loja e armas, com
APIs substitutas; o teste de armas usa um spy para apresentação. O importador foi
exercitado com árvore/InsertService simulados: remoção de scripts, falhas parciais,
rejeição de modelo sem mesh e recuperação posterior. Isso não comprova permissões
nem compatibilidade dos prefabs que não foram baixados.

Resultados nesta execução: 119 verificações de combate, 63 do cliente de armas,
52 da loja, 13 do importador, 41 de rodada e 39 do ciclo integrado passaram.
Também passaram os 23 testes Python, a compilação Luau e os builds Rojo. O arquivo
compilado confere 27 fontes ativas e rejeita os controladores/templates antigos.

O arquivo de validação Survival separado foi mantido. Antes de aprovar o pacote,
testar dois clientes, quatro templates carregados, mira/recarga/troca/compra,
áudio ouvido pelo outro jogador, infecção e reinício. Executar também
`require(game.ServerStorage.ZO_Validation.GameplayAudit).run()` no servidor; ele
agora falha explicitamente quando algum template do catálogo está ausente.
