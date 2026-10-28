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
