# Diretrizes permanentes — Zombie Outbreak Reborn

## Integração aplicada — 06/11/2026

- O usuário pediu aplicação imediata dos fontes já pesquisados. O pacote ativo
  adapta fricção/aceleração do UnitySourceMovement (MIT), recuo da câmera do
  CIA-SAC-ACS (Apache-2.0) e a mola explicitamente MIT vendorizada no Evostrike.
  Fontes exatos/licenças/hashes: `third_party/tactical-fps-sources`.
- `SourceMotor` usa entrada analógica `Humanoid:Move` para humanos no PC,
  consumindo o WalkSpeed final de MovementState. Não escreve velocidade física,
  pose, colisão ou WalkSpeed; o controlador nativo mantém salto e contatos.
  Zumbis, toque e gamepad mantêm o controle nativo. Chat/menu/falta de foco
  interrompem o drive. Não anunciar um motor Source completo ou migração ACS.
- `Weapons` consome TacticalRecoil e WeaponMotion consome TacticalSpring de
  fato no perfil Rojo e nos places entregues. Os padrões por arma são ajustes
  próprios do K-17; nenhum padrão GPL-only do Evostrike foi copiado.
- A licença global não mudou. Evostrike completo continua apenas referência;
  o uso MIT se baseia no aviso explícito do arquivo de terceiro. Não importar
  o motor GPL inteiro sobre os componentes Limited Use do Roblox sem análise.
- Backup anterior: `backup/before-fps-adoption-aeb098a`. Detalhes e validação:
  `docs/TACTICAL_FPS_ADOPTION_2026-11-06.md`. Código compilado e testes simulados
  não comprovam sensação do Humanoid, câmera ou multiplayer no Studio.

## Referência CS encontrada com web funcional

- Fonte principal para comportamento e código tático: `beters02/Evostrike`,
  commit221a3a2f67451145b94836b794c0df072c6a28ee, GPLv2. Já foi clonado em
  `/workspace/reference-study/beters02--Evostrike`; buildRojo de revisão passou.
  Não repetir a conclusão antiga de que nenhuma base CS foi localizada.
- Há309arquivosLua, mas zeroModels/MeshParts/Tools/Animations/Sounds no build.
  Reutilização exige adaptar nossos assets; compilar não comprova startup/play.
- `beters02/source-rbx` é o release de movimento do mesmo autor comRBXL nativo;
  repo semLICENSE identificado. Não inferir autorização irrestrita para seus
  assets só pelo título open-source. Os arquivos correspondentes licenciados
  podem ser estudados no EvostrikeGPL.
- Ler `docs/CS_FPS_BASES_VERIFIED.md` antes de propor outra base. Preservar
  servidor autoritativo: a entrada AddWeapon da referência tem middleware
  pendente; não copiar esse acesso direto sobre nossa economia/infecção.
- Preservar GPL/notices e considerar compatibilidade do conjunto ao integrar
  código derivado. A pesquisa não incorporou fontes GPL ao runtime nem alterou
  a licença do projeto. Não afirmar que uma pasta separada evita copyleft.

## Estado atual — SMG e escopeta aplicadas

- Após a rede funcionar, os dois modelos oficiais foram baixados comHTTP200,
  origem Roblox Resources verificada e binários/hash preservados em
  `third_party/roblox-weapon-kit/official-prefabs`. O erro do proxy registrado
  abaixo é histórico, não um bloqueio atual confirmado.
- Quatro classes têm templates nativos: Rifle, Pistol, SMG, Shotgun. Há seis
  skins adicionais, dez templates visuais no total. Não contar skins como
  armas distintas nem anunciar faca/sniper ou arsenal CS inteiro concluído.
- Novos acabamentos reais: SMG Bronze/White; Shotgun Sand/Silver. Não renomear
  esses materiais para Gold sem corresponder à fonte. Pistol mantémClassic/Gold.
- Todos os controladores originais dos prefabs ficam arquivados fora do jogo.
  O runtime usa o único núcleo existente; dano, preço, munição e dispersão
  continuam emConfig/Combat. Fonte Shotgun5projéteis não substitui oK-17 com7.
- Para regenerar assets: build do kit upstream, depois
  `scripts/build_official_weapon_review.py --rojo PATH --output /tmp/prefabs.rbxlx`,
  e extrator com `--prefabs /tmp/prefabs.rbxlx`. O wrapper temporário resolve
  três raízes noRBXM para revisão; originais permanecem byte-exact e nenhumLua
  baixado é executado. CI reproduz esse processo.
- Visual, áudio e multiplayer continuam pendentes no motor. Não confundir
  inspeção/compilação/APIs simuladas com execução noStudio.

## Arsenal completo e acesso à loja — 05/11/2026

- O usuário exige um pacote com várias armas reais da Creator Store. Skins
  das duas armas atuais são complemento; não satisfazem esse objetivo.
- Variantes oficiais da pistola já fornecida: Black/base, Classic e Gold. São
  cosméticas, gratuitas e selecionadas pelo servidor, sem alterar atributos de
  combate, munição ou créditos. Não contar essas variantes como armas distintas.
- O rascunho de ambiente foi lido com `network_policy.type=disabled`; consultas
  Roblox e GitHub falharam no CONNECT do proxy, inclusive fora do sandbox.
  Foi salvo um rascunho restricted com domínios Roblox/CDN/GitHub. A ferramenta
  retornou `requires_publish=true`. O usuário informou rede liberada, mas a
  primeira repetição ainda retornou403 no túnel: nenhuma origem foi alcançada.
- Não interpretar erro do proxy como recusa do asset pelo Roblox. Não repetir
  buscas/downloads até publicação/atualização observável da configuração. Não
  contornar a política com outros proxies ou solicitar cookies/tokens em chat.
- Retomar a busca do arsenal completo assim que o acesso real funcionar. Não
  anunciar novos arquivos baixados, modelos aprovados ou arsenal completo sem
  obter e inspecionar os arquivos correspondentes.

## Missão de jogabilidade FPS — novo pedido de 05/11/2026

- O prompt anexado autoriza decisões técnicas e implementação direta de
  movimentação/armas na base real, reaproveitando componentes gratuitos com
  permissão e preservando mapas, defesas, rodadas e integração Rojo.
- Essa autorização atual substitui a exigência antiga de nova aprovação antes
  de implementar melhorias FPS compatíveis. Não aguardar acesso local para
  concluir o trabalho possível na nuvem; não afirmar importações ou testes de
  Studio inexistentes. Uma migração exige fontes reais auditáveis.
- O novo requisito de Shift é **corrida**: Shift/Sprint, Alt/Walk, Ctrl/C/Crouch.
  Não voltar a anunciar Shift como caminhada para a versão atual. Corrida
  compõe a velocidade e a contenção no mesmo MovementState.
- Não desbloquear modelos ausentes nem declarar o arsenal completo apenas
  porque as estatísticas e categorias existem. Não usar assets extraídos de
  jogos proprietários por estarem num repositório público com licença de código.

## Continuidade sem Studio — 05/11/2026

- O usuário autorizou continuar editando o projeto agora e deixar as ações que
  dependem dele/Roblox Studio para mais tarde. Não parar novamente para pedir o
  template ou execução local antes de concluir melhorias compatíveis autorizadas.
- Esta entrega integra movimentação tática e categorias da loja à base atual.
  Não equivale à migração para o FPS System oficial: o arquivo e a auditoria
  dessa base continuam pendentes. Manter a distinção nos relatos de entrega.
- A composição de velocidade pertence a `MovementState`: base da equipe ×
  postura × contenção temporária por tiro. Round, Combat e Movement usam essa
  autoridade; não adicionar outro escritor concorrente de WalkSpeed.
- As adaptações de movimentação de `voximity/extract` têm licença MIT e fontes
  originais arquivados em `third_party/extract-movement`, fora do perfil ativo.

## Missão de FPS completo — 31/10

- O novo pedido exige primeiro pesquisa/auditoria/comparação de bases reais,
  com licenças e assets verificáveis, antes de integrar outra infraestrutura.
- Counter Blox é referência de jogabilidade. Não usar fontes vazadas,
  descompiladas ou scripts de exploração como base do jogo.
- Nenhuma reconstrução estrutural da camada FPS está autorizada até aprovação
  explícita após uma proposta concreta. Preservar mapas ativos/inativos,
  barricadas, rotas, infecção, knockback, rodada e multiplayer.
- O relatório da Etapa 1 está em `docs/FPS_BASE_AUDIT_2026-10-31.md`.
  FPS System oficial é candidato para qualificação; arquivo nativo e avisos
  de licença completos ainda não foram examinados. Não afirmar base completa
  aprovada nem inferir MIT para todos os assets pela licença da documentação.
- Receber um template para auditoria não equivale a aprovar a migração.

## Reutilização primeiro

O usuário pediu repetidamente para reaproveitar sistemas e partes prontas de
outros projetos. Essa é a abordagem padrão deste projeto, inclusive em sessões
futuras. Não voltar a desenvolver cada sistema do zero por conveniência.

- Antes de substituir ou ampliar um sistema, procurar uma base existente que
  resolva o problema. Priorizar componentes Roblox/Luau e exemplos oficiais.
- Reutilizar o código existente de fato, com origem, revisão e licença
  verificadas e atribuições preservadas. Só citar um projeto como inspiração
  não é reutilização. Pequenos componentes também são bem-vindos quando úteis.
- Preferir adaptar a integração ao componente pronto. Código próprio deve
  preencher lacunas concretas, não reconstruir o componente escolhido.
- Limitar a pesquisa a poucos candidatos relevantes. Evitar ciclos de buscas,
  reescritas, documentação e testes que não produzam avanço para o jogador.
- Escolher componentes pela utilidade para o jogo. Uma biblioteca de câmera
  não equivale a um sistema completo de armas, animações e modelos.
- Manter o modo Zombie Survival/Zombie Mod como referência funcional.
  Não importar mapas de Counter-Strike sem autorização correspondente.
- Trabalhar por entregas integradas e respeitar a prioridade atual do usuário;
  não ampliar o escopo com novos sistemas por iniciativa própria.

## Preservação e evidências

- Fazer backup antes de alterar arquivos importantes. Preservar o histórico Git.
- Não afirmar acesso ao Studio local sem uma conexão realmente verificada.
- Compilação e testes com APIs simuladas não comprovam aparência, controles,
  física ou multiplayer no Roblox Studio. Descrever o que foi executado.
- Se um componente depender de assets, permissões ou importação local, confirmar
  essa dependência antes de anunciar integração concluída.
- Não introduzir código baixado na execução do jogo sem revisar suas fontes.
  Guardar importações externas desativadas e separadas até a revisão.

## Ordem de desenvolvimento e aceitação

- Pedido de 28/10/2026: auditar e estabilizar primeiro o ciclo completo de Zombie
  Survival; depois aprimorar mapa, armas/sons/interface e, então, Zombie Escape.
  Os dois modos fazem parte do projeto, mas Escape ainda não está implementado.
- Preservar sistemas que passam nas verificações; corrigir falhas reproduzidas
  antes de considerar substituições. Não executar todas as fases simultaneamente.
- Validação visual e multiplayer no motor Roblox permanece pendente até execução
  real. Testes com APIs simuladas e arquivos compilados não satisfazem essa etapa.
- Os drivers em `tests/studio` pertencem somente ao place de validação separado.
  Nunca incluir automação, posições fixas ou rodadas curtas no perfil jogável.

## Pacote FPS e limpeza

- O usuário autorizou remover armas e objetos anteriores que perderem seu uso.
  Preservar backup e conferir dependências antes de excluir; não manter dois
  controladores ou dois catálogos visuais ativos.
- O pacote FPS na branch `feat/fps-combat-package` tem dependências de prefabs
  oficiais ainda não baixadas. Carabina e pistola preta estão embutidas. Não anunciar
  quatro modelos prontos nem misturar esse pacote incompleto à main estável antes
  de resolver os assets ou receber autorização explícita para essa limitação.
- `WeaponAssetImport` só aceita IDs oficiais fixos e remove código externo antes
  de publicar templates. Compra/equipamento de modelos ausentes fica bloqueada.
  Scripts legados removidos permanecem recuperáveis pelo backup Git.
- O usuário executou a importação no Studio em 31/10: os quatro IDs retornaram
  `User is not authorized to access Asset`; confirmou que **Allow Loading Third
  Party Assets** estava desligada. Não tratar essa tentativa como importação
  bem-sucedida, nem afirmar que o comando nunca foi executado localmente.
- O mesmo Output confirmou que o HitSound `1489924400` está arquivado. Removê-lo
  da extração ativa preserva as partículas e os sons originais de tiro/recarga.
  O ID `203785492`, com erro de tipo, não foi localizado nos fontes/binários;
  não inventar sua origem ou substituir IDs por suposição.
- Nova tentativa de 31/10 às 07:54 na experiência salva no Roblox passou do
  carregamento e falhou na nossa validação `Prefab must contain exactly one
  complete weapon Tool` para os quatro assets. Às 08:18, a captura voltou a
  retornar recusa de autorização e zero modelos. Não presumir que o acesso das
  APIs ficou resolvido. A pistola foi recebida depois por Toolbox/arquivo;
  os outros dois modelos continuam pendentes.
- `CaptureOfficialWeapons` é uma captura independente em modo de edição:
  preserva modelos em ServerStorage e fontes como texto inerte para revisão.
  Não altera o catálogo ativo nem depende da versão dos ModuleScripts salvos.
  Um Pull do Git não sincroniza a experiência salva/Team Create automaticamente.
- O usuário forneceu `Pistolas_Oficiais.rbxl`, SHA-256
  `49edede93e584f648a9006a196cbff4af5c4e5cde1e8186fad04493cdfcfa038`.
  O arquivo contém nove Tools (três variantes com cópias em StarterPack), todas
  com Handle; o problema comprovado era a multiplicidade, não Handle ausente.
  A variante preta Workspace/Pistol2 é a única incluída. Fonte completa revisada
  em `third_party/roblox-weapon-kit/pistol/OriginalPistol2.rbxmx`, fora do runtime.
  Somente apresentação é extraída: código/câmera/remotes/efeitos globais do kit
  não são ativados. Os novos assets usam Roblox Limited Use License, não MIT.
- Play usa os templates incluídos sem chamar LoadAssetAsync. As importações
  restantes são ações explícitas de edição; não reintroduzir downloads como
  dependência para equipar rifle/pistola já embutidos.
