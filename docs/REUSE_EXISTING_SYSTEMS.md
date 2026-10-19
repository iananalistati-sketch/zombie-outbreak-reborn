# Reutilizar sistemas existentes

A preferência do usuário está registrada em [AGENTS.md](../AGENTS.md) para os
próximos trabalhos: reaproveitar componentes reais antes de desenvolver sistemas
equivalentes. A última entrega de combate ainda é uma implementação própria;
esta alteração não afirma que ela foi substituída por um kit externo.

## Base concreta para armas

A documentação oficial da Roblox fornece o
[Weapons Kit](https://create.roblox.com/docs/resources/weapons-kit), incluindo
prefabs de pistola, escopeta, rifle automático e submetralhadora com um sistema
de armas associado. A documentação descreve câmera sobre o ombro e projéteis;
a compatibilidade com nossa primeira pessoa precisa ser examinada nos fontes.

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

## Dependência que permanece bloqueada

Nesta nuvem, os pedidos de download dos prefabs a
`assetdelivery.roblox.com` retornaram `Tunnel connection failed: 403 Forbidden`.
Os modelos, fontes internos, animações, sons e dependências desses prefabs
**não foram obtidos nem testados aqui**. Não há integração de armas oficiais
concluída, nem conexão desta nuvem com o Studio do usuário.

Foi preparado o [importador para revisão](../tools/studio/ImportOfficialWeapons.luau).
Ele precisa ser executado no Studio, em modo de edição, usando a conta local:

1. Copie o arquivo inteiro para a Command Bar e execute fora de Play.
2. O importador tenta carregar os quatro prefabs, desativa seus scripts antes
   de colocá-los em `ServerStorage` e seleciona a pasta de revisão. Ele não
   substitui arquivos nem conecta o material à partida.
3. Salve a pasta selecionada como `.rbxmx` por **Save to File** no repositório
   e sincronize pelo GitHub Desktop. Os fontes reais poderão então ser
   examinados e adaptados, com atribuições e dependências preservadas.

O importador foi compilado em Luau; sua execução e a autorização para carregar
os assets ainda dependem do Studio. Uma falha individual é informada no Output.
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
