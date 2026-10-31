# Reutilizar sistemas existentes

Estado atual: [pacote FPS e dependências dos modelos oficiais](FPS_COMBAT_PACKAGE.md).

**Pistola recebida e integrada:** `Pistolas_Oficiais.rbxl` forneceu as variantes
oficiais. A preta `Workspace/Pistol2` foi revisada e incluída com a carabina,
mantendo meshes, texturas, áudio e attachments reais. O runtime exclui o sistema
de combate aninhado. Play usa esses dois modelos sem importação automática.
SMG e Shotgun continuam pendentes; as tentativas e ferramentas abaixo documentam
o processo anterior e opções para obter os modelos restantes.
Os blocos de armas anteriores e o importador de mera revisão foram substituídos.
Os demais prefabs oficiais ainda não foram baixados na nuvem.

A preferência do usuário está registrada em [AGENTS.md](../AGENTS.md) para os
próximos trabalhos: reaproveitar componentes reais antes de desenvolver sistemas
equivalentes. A carabina inicial agora usa a AR, sons, animações e trechos de
apresentação do Roblox Weapons Kit; veja a [integração entregue](REUSED_WEAPON_KIT.md).
Os controladores de combate permanecem próprios. O pacote FPS remove os modelos
procedurais anteriores e prepara três outros prefabs oficiais; esses arquivos
ainda não foram obtidos e não são anunciados como modelos embutidos.

## Base concreta para armas

A documentação oficial da Roblox fornece o
[Weapons Kit](https://create.roblox.com/docs/resources/weapons-kit), incluindo
prefabs de pistola, escopeta, rifle automático e submetralhadora com um sistema
de armas associado. A documentação descreve câmera sobre o ombro e projéteis;
a integração atual adapta sua apresentação à primeira pessoa do K-17.

Os IDs abaixo foram lidos na documentação oficial, não inferidos de modelos
aleatórios da Toolbox:

| Prefab | Asset ID |
| --- | --- |
| Pistol | 118912302094201 |
| Shotgun | 104068096273092 |
| Auto Rifle | 96131146947811 |
| Submachine Gun | 119916677125479 |

O kit usa a [Roblox Limited Use License](https://create.roblox.com/docs/resources/limited-use-license),
não MIT. A licença permite incorporar e modificar o material para aplicações
na plataforma Roblox, com suas condições e atribuições.

## Download direto e fonte alternativa obtida

Nesta nuvem, os pedidos de download dos prefabs a
`assetdelivery.roblox.com` retornaram `Tunnel connection failed: 403 Forbidden`.
Esse caminho direto permanece bloqueado. Entretanto, foi obtido pelo GitHub o
[Roblox Weapon Kit Fix](https://github.com/JustAT0rtoise/Roblox-Weapon-Kit-Fix/tree/72229de581a9c38272b10e4353804c80ac0c6379),
que contém um kit nativo completo com uma AR. O arquivo original e as fontes
foram examinados; a AR e seus componentes de apresentação já estão no perfil
ativo. Origem, hash e as duas licenças estão na
[atribuição](../third_party/roblox-weapon-kit/ATTRIBUTION.md).

Não foram obtidos os outros três prefabs da tabela acima. A apresentação da AR
ainda precisa de validação no Studio; não há conexão com o computador do usuário.

A tentativa seguinte no place salvo passou da autorização e falhou na validação
de Tool/Handle. Para esse caso, **`INSPECIONAR_ARMAS.cmd`** captura a estrutura
real e fontes como texto inerte, sem depender dos ModuleScripts salvos. Exporte a
pasta de revisão como `.rbxm`/`.rbxmx` para adaptação e incorporação dos modelos.

O [importador de prefabs](../tools/studio/ImportOfficialWeapons.luau) usa o novo
`WeaponAssetImport`, após abrir o arquivo da branch FPS. A AR embutida continua
independente dessa operação.
Ele precisa ser executado no Studio, em modo de edição, usando a conta local:

1. Execute `IMPORTAR_ARMAS.cmd` na raiz do repositório para copiar o comando e
   cole na Command Bar fora de Play. Também é possível copiar o arquivo inteiro.
2. O importador faz backup em `ServerStorage`, tenta os quatro prefabs e remove
   seus scripts/remotes antes de publicar os templates em `ZO_WeaponAssets`.
   Confira o Output: a tentativa local de 31/10 negou os quatro modelos por
   autorização; o usuário confirmou a opção de terceiros desativada.
3. O carregador usa `AssetService:LoadAssetAsync`, conforme a
   [documentação oficial fixada](https://github.com/Roblox/creator-docs/blob/c8f5276703948ef4868c9b9fd44fae619dbe2f11/content/en-us/reference/engine/classes/AssetService.yaml).
   Em erro de permissão, confira **Experience Settings → Allow Loading Third
   Party Assets**, quando o modelo gratuito não atender às regras de propriedade
   ou compartilhamento da experiência. O script não lê nem altera essa opção.
4. Salve o place como uma cópia fora de `builds`. Exporte a pasta selecionada
   como `ZO_WeaponAssets_Official.rbxmx` e sincronize pelo GitHub Desktop para
   que os modelos realmente obtidos possam ser incorporados ao repositório.

O importador foi compilado em Luau; a execução local já foi tentada, mas carregar
os assets ainda depende de autorização no Studio. Uma falha individual é informada no Output.
Se todas as importações falharem, ele não deixa uma pasta vazia no projeto.

## Componentes pequenos verificados

- [Spring / NevermoreEngine](https://github.com/Quenty/NevermoreEngine/tree/a3fb9df22d983f4e1b8164e2a5f252620f215caa/src/spring),
  revisão `a3fb9df22d983f4e1b8164e2a5f252620f215caa`: MIT, arquivo independente
  sem dependências, apropriado para recuperação de recoil e sway.
- [RbxCameraShaker](https://github.com/Sleitnick/RbxCameraShaker/tree/15412099389d746af13a2a661ec1196f980d726b),
  revisão `15412099389d746af13a2a661ec1196f980d726b`: MIT, três módulos para
  tremor de câmera, sem dependências externas às APIs Roblox.

As fontes e licenças desses dois componentes foram lidas. Eles não são sistemas
de armas completos. Não foram adicionados como dependências sem uso nem
apresentados como uma solução para os modelos e animações do jogo.
