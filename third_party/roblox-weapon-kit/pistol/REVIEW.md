# Pistola oficial fornecida pelo usuário

Origem: [Roblox Resources / Pistol](https://create.roblox.com/store/asset/118912302094201/Pistol),
sob a Roblox Limited Use License preservada na pasta superior.

Arquivo recebido: `Pistolas_Oficiais.rbxl`, 181456 bytes, SHA-256
`49edede93e584f648a9006a196cbff4af5c4e5cde1e8186fad04493cdfcfa038`.
O original fica preservado nos anexos da sessão. O arquivo nativo usa ZSTD;
foi convertido offline para XML, sem executar seus scripts.

Há três variantes e cópias em StarterPack: nove Tools, contendo 144 instâncias
de scripts, equivalentes a 16 fontes únicas. Todas possuem Handle direto. Foi
selecionada apenas a variante preta `Workspace/Pistol2`, cujo SourceAssetId é
`118912302094201`. A Tool completa está em `OriginalPistol2.rbxmx`, SHA-256
`704f204cd3eb51a361c449f8718dd30b10869e7dcc823a1d186598176f89993e`.

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

Não se afirma execução da integração no Studio, reprodução auditiva ou aprovação
de controles multiplayer. Essas verificações continuam no roteiro do pacote FPS.
