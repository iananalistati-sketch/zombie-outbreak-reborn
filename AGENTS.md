# Diretrizes permanentes — Zombie Outbreak Reborn

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
