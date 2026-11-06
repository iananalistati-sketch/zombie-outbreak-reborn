# SMG e Shotgun oficiais — revisão dos arquivos recebidos

Fonte: Creator Store, grupo verificado Roblox Resources. IDs, bytes, hashes e
nomes das três variantes de cada modelo estão em SOURCE.json. Os binários são
os downloads originais byte a byte. As respostas oficiais de metadados também
foram preservadas. Licença: Roblox Limited Use License, no diretório superior.

Cada modelo contém três Tools,12 MeshParts e48 instâncias de scripts. São16
corpos únicos por modelo, idênticos aos16 já revisados na pistola fornecida
pelo usuário, após normalizar CRLF para comparação com XML. Não se executam
scripts de origem. Os testes verificam os corpos completos por hash, sem
substituir essa verificação por buscas de nomes de funções.

O conversor acrescenta uma pasta temporária às três raízes do RBXM somente
para permitir revisão no Rojo, preservando nomes/fontes e demais chunks. O
extrator lê esse XML e elimina o framework WeaponsSystem inteiro, executáveis,
remotes, bindables, PackageLinks e tags, remapeando referências e SharedStrings.

| Classe | Tool original | ID de aparência K-17 |
| --- | --- | --- |
| SMG | SMG | Default |
| SMG | SMG2 | Bronze |
| SMG | SMG3 | White |
| Shotgun | Shotgun | Default |
| Shotgun | Shotgun2 | Sand |
| Shotgun | Shotgun3 | Silver |

As cores das variantes correspondem às texturas oficiais: UVBronze2, UVWhite3,
UVSand e UVSilver2. Preservam-se a orientação original do grip e os dois meshes
de cada Tool. Não há BoltMotor nesses modelos. Os sons e três IDs de animação
R15 originais permanecem; são os mesmos clips RifleAim/ADS/Reload do kit.

SourceAssetIds internos legados não são os IDs de download atuais. Ambos são
registrados separadamente, sem alterar a procedência original. Valores de
combate dos prefabs não são usados pelo servidor K-17. A integração conserva
seu próprio dano, munição, cadência, sete projéteis da escopeta e economia.

Fonte revisada, extração e compilação não comprovam permissões de todos os
subassets, reprodução auditiva, braços/visuais nem multiplayer no Roblox Studio.
