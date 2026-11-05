# Pistola oficial fornecida pelo usuário

Origem: [Roblox Resources / Pistol](https://create.roblox.com/store/asset/118912302094201/Pistol),
sob a Roblox Limited Use License preservada na pasta superior.

Arquivo recebido: `Pistolas_Oficiais.rbxl`, 181456 bytes, SHA-256
`49edede93e584f648a9006a196cbff4af5c4e5cde1e8186fad04493cdfcfa038`.
O original fica preservado nos anexos da sessão. O arquivo nativo usa ZSTD;
foi convertido offline para XML, sem executar seus scripts.

Há três variantes e cópias em StarterPack: nove Tools, contendo 144 instâncias
de scripts, equivalentes a 16 fontes únicas. Todas possuem Handle direto e
SourceAssetId `118912302094201`. A variante preta `Workspace/Pistol2` permanece
a pistola padrão. As outras duas agora fornecem skins cosméticas do mesmo
equipamento, sem criar armas ou estatísticas diferentes:

| Variante nativa | Uso | Arquivo completo de revisão | SHA-256 |
| --- | --- | --- | --- |
| `Workspace/Pistol2` | Preta padrão | `OriginalPistol2.rbxmx` | `704f204cd3eb51a361c449f8718dd30b10869e7dcc823a1d186598176f89993e` |
| `Workspace/Pistol` | Clássica | `OriginalPistol.rbxmx` | `9a0adb1e26e6fa15f0a46f04e24900b11d3fe9cfdf00e226e766b5e66202a16f` |
| `Workspace/Pistol3` | Dourada | `OriginalPistol3.rbxmx` | `4ed7e278a77756ab82ea0c374f055f12f0cc229cb8b7ed9ff711bc9401c14ad8` |

Os novos arquivos preservam a Tool inteira, seus 16 scripts como dados inertes
e os cinco SharedStrings referenciados. Vieram do XML de revisão convertido do
anexo original; nenhum código foi executado. As 16 fontes de cada variante são
iguais às já auditadas da preta.

As 16 fontes únicas foram revisadas como dados. Não foram encontrados loaders
HTTP, loadstring ou require numérico nas dependências examinadas. O kit contém
sua própria câmera, remotes, dano e alterações de velocidade; esses controladores
ficam arquivados para consulta e não são ativados no K-17.

O extrator conserva os três meshes, suas texturas, joints, attachments, flash,
som de disparo `3806566911` e recarga `3821789416`. Remove WeaponsSystem inteiro,
WeaponType e tags sem consumidor; corrige referências que apontavam para objetos
excluídos e aplica propriedades de apresentação sem colisão ou massa adicional.
As animações originais da pistola são as mesmas três RifleAim/ADS/Reload já
incluídas com a carabina.

As três variantes compartilham os meshes `2492922600`, `2492923497` e
`2492925447`, os sons e o grip. A Clássica usa textura `2492931263` no corpo,
`2492931686` no ferrolho e mantém **sem textura** o carregador, como no original.
A Dourada usa `3361055083` no corpo e `3361057436` no ferrolho/carregador. A preta
continua com `3361038943` no corpo e `3361041283` no ferrolho/carregador.

Na extração ativa, `Weapons/Rifle` e `Weapons/Pistol` permanecem os dois tipos
de arma embutidos. As Tools `Skins/Pistol/Classic` e `Skins/Pistol/Gold` recebem
atributos nativos `ZO_WeaponId=Pistol` e `ZO_SkinId=Classic`/`Gold`. A mesma limpeza
e o mesmo remapeamento de referências são aplicados às três pistolas. O pacote
tem quatro Tools visuais, 12 MeshParts e somente três animações compartilhadas;
não inclui scripts, remotes, o som de impacto arquivado ou outra câmera.

Os testes conferem texturas nativas, meshes, áudio, grip, configurações iguais,
atributos, ausência de código e resolução de referências/SharedStrings. A
serialização dos atributos de string também foi comparada com saída do Rojo.
Esses testes não comprovam aparência ou carregamento dos assets no Roblox.

Não se afirma execução da integração no Studio, reprodução auditiva ou aprovação
de controles multiplayer. Essas verificações continuam no roteiro do pacote FPS.
