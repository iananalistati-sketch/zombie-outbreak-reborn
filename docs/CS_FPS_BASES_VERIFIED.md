# Bases FPS verificadas com acesso real à web

**Evostrike é a referência principal recomendada para as mecânicas de CS.**
Os fontes foram baixados e inspecionados; o projeto Rojo foi compilado fora do
jogo. Esta auditoria não troca os controladores ou o mapa do K-17.

## Comparação com arquivos recebidos

| Projeto | Material verificado | Licença/estado | Decisão |
| --- | --- | --- | --- |
| [beters02/Evostrike](https://github.com/beters02/Evostrike/tree/221a3a2f67451145b94836b794c0df072c6a28ee) | 309 arquivos Lua; controlador de armas, movimento/fricção/aceleração, padrões de spray, inventário, compra, skins, facas e modos. Rojo compilou. | GPLv2 em LICENSE.txt. O checkout compila262 ModuleScripts,24 Scripts e34 LocalScripts, mas zero Models/MeshParts/Tools/Animations/Sounds: assets/viewmodels não vêm nesse checkout. | Melhor fonte de comportamento e código tático entre os candidatos examinados; integrar componentes com adaptação, não substituir tudo cegamente. |
| [beters02/source-rbx](https://github.com/beters02/source-rbx/tree/ed5d76edcf7d7a9fdbc3f0021fc8e18410073232) | Release de movimento extraído do Evostrike, com collide-and-slide/fricção. Inclui source-rbx.rbxl:3 Models,16 MeshParts e11 fontes; Rojo compilou. | Publicação do próprio autor no DevForum; repositório sem arquivo LICENSE identificado. O post declara PC apenas. | Excelente demonstração física para estudar. Não inferir licença de código/mesh ausente nem cobertura de toque/gamepad. Para código GPL licenciado, usar os arquivos correspondentes do Evostrike. |
| [jasonconba/CIA-SAC-ACS](https://github.com/jasonconba/CIA-SAC-ACS/tree/678d94f104f06589c652b5b6b62020837b5ea74c) | Fork ACS R15 com módulos de armas/personagem, animação e recoil; dependências Knit/Roact presentes; Rojo compilou. | Apache2.0 na raiz, com licenças próprias das dependências. README declara refatoração ainda não pronta para produção. Build sem Models/Tools/MeshParts. | Fonte secundária para estudar ACS; não promover essa versão incompleta a substituição pronta. |
| [Exypson/Tactical-Arms-Framework](https://github.com/Exypson/Tactical-Arms-Framework/tree/cba513b50589477f453a4abd5d99fc12c8a6bda8) | Arquitetura WeaponsSystem/BaseWeapon/BulletWeapon/ShoulderCamera e HUD; câmera sobre o ombro descrita no README. | MIT na raiz; direitos/notices dos componentes herdados ainda precisam ser qualificados separadamente. | Não resolve a base CS completa e se sobrepõe à família Weapons Kit que já usamos. |

Evostrike se apresenta como jogo inspirado em Source e Counter-Strike no README.
O autor atribui programação/animações a si e assets ao irmão. Isso não significa
que os assets ausentes passaram a fazer parte do checkout baixado.

## Código concreto para aproveitar do Evostrike

- `src/client/character/movementScript/Physics.lua`: fricção, aceleração no chão
  e no ar; a velocidade passa por um controlador próprio.
- `src/client/character/movementScript/Functions.lua` e `init.client.lua`:
  entrada e aplicação do movimento. O servidor tem `src/server/MovementScript`.
- `service/WeaponService/WeaponController/init.lua`: slots, troca e controles.
- `service/WeaponService/Weapon/init.lua`: viewmodel/câmera, disparo e estado.
- `service/WeaponService/Weapon/ak47/spraypattern.lua` e os equivalentes MP5:
  padrões por disparo; parser em `src/shared/weapon/fc_initSprayPattern.lua`.
- `service/GamemodeService2/.../BuyMenu`: fluxos de compra; `module/Shop` e
  `module/States`: interfaces de loja e estados compartilhados.

São arquivos de implementação examinados, não funcionalidades inferidas apenas
pelo título de uma página. Não se afirma execução do gameplay no motor.

## Adaptação necessária ao Zombie Outbreak

1. Reaproveitar recuo/spray, apresentação e comportamento tático sobre as quatro
   armas licenciadas que já incluímos. O código espera ClientModelObject,
   ServerModel, viewModel e HUD que precisam de adaptadores reais para nossos
   templates; não basta copiar a pasta e iniciar Play.
2. Preservar a autoridade atual de compra/munição/dano/infecção/knockback. Em
   `WeaponService/init.lua`, o RemoteEvent aceita AddWeapon/RemoveWeapon sem
   a validação de economia/papel que temos. O trecho contém o próprio comentário
   de middleware pendente. Essa entrada não deve substituir nossos remotes.
3. O movimento próprio escreve velocidade física, em vez de depender só de
   Humanoid.WalkSpeed. Deve receber a composição equipe × postura × efeito de
   tiro de MovementState e respeitar colisões/barricadas. Ativar ambos os
   controladores juntos anularia a contenção ou produziria conflitos.
4. Manter Foundry, refúgios, dutos, barricadas, rodada e modo Survival. Nenhum
   mapa de referência é necessário para reaproveitar os sistemas.

GPLv2 permite reutilização, mas impõe obrigações sobre distribuição de código
derivado e preservação de licença/notices. A integração precisa considerar a
licença do conjunto resultante; não é correto marcar arquivos copiados como
MIT ou afirmar que separar uma pasta elimina essas obrigações. Esta pesquisa
não altera a licença do Zombie Outbreak nem incorpora esse código ao runtime.

## Creator Store e arquivos que exigem autorização

A busca oficial e os metadados retornaramHTTP200 para ACS2.0.1, FE Gun Kit e
FPS systems. Exemplos encontrados: ACS8979699478 e FPS Gun System12681445932
(a API declara10 e25 Tools, respectivamente). Os downloads desses dois modelos
retornaramHTTP401. A referência ACS R15 original7118097999 retornouHTTP403.
Não foram tratados como binários recebidos, revisados ou autorizados para uso.

Isso é diferente do antigo erro de túnel: agora a resposta vem do Roblox. O
download da experiência Evostrike11287185880 também retornou401; os fontes
GitHub são acessíveis. Não foram solicitados cookies ou credenciais do usuário.

## Evidências reproduzíveis

Os quatro checkouts estão em `/workspace/reference-study`; os hashes estão nos
links da tabela. Builds de revisão: `/tmp/evostrike-audit.rbxlx`,
`/tmp/source-rbx-audit.rbxlx` e `/tmp/acs-fork-audit.rbxlx`.
O compilador Luau0.742 também aprovou os fontes examinados do Evostrike
(46 mil linhas) e source-rbx (cerca de mil linhas). Isso verifica sintaxe e
bytecode, sem executar APIs do Roblox ou comprovar funcionamento do gameplay.
O [post original do autor](https://devforum.roblox.com/t/source-engine-movement-open-sourced/3008646)
retornou200 e aponta para source-rbx. A inspeção do RBXL foi somente leitura;
nenhum script baixado foi executado, nenhum mapa foi copiado para o projeto.

O próximo trabalho concreto é adaptar um conjunto coerente de controles,
recuo/apresentação e movimento dessa referência, preservando os contratos do
servidor. A pesquisa anterior, feita com web bloqueada, não deve mais ser usada
para concluir que nenhuma base CS com código foi localizada.
