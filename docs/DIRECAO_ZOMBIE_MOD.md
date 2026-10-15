# Correção de direção — Zombie do Counter-Strike

O usuário rejeitou a direção da jogabilidade após a entrega `65fad8b`.
O objetivo continua sendo reproduzir a experiência de **Zombie Survival / Zombie
Mod do Counter-Strike**, com cenário original. A implementação atual é um
protótipo e não foi aprovada como reprodução dessa experiência.

O pedido original cita CS 1.6, Source e CS2; a conversa mais recente destaca
CS2. Há variantes por servidor. O usuário orientou a pesquisar vídeos públicos
no YouTube e escolher as referências, sem transferir essa busca a ele.

As tentativas de acessar a busca e a página inicial do YouTube retornaram
`Tunnel connection failed: 403 Forbidden`. A configuração consultada confirma
rede restrita ao preset de gerenciadores de pacotes, sem domínios customizados.
Foi salva no rascunho a liberação de `www.youtube.com`, `youtube.com`, `youtu.be`,
`i.ytimg.com` e `*.googlevideo.com`. A ferramenta retornou `requires_publish: true`:
o usuário precisa revisar/salvar as configurações e publicar o ambiente para
aplicar a alteração. Nenhum vídeo foi assistido nesta revisão.

O usuário posteriormente solicitou verificar projetos públicos de Zombie Survival
de CS2 **ou CS:GO**. O GitHub está acessível e permitiu examinar sete repositórios,
licenças e módulos concretos. As conclusões e os commits estão em
[Projetos abertos de Zombie Mod](CS_ZOMBIE_OPEN_SOURCE.md). Essa análise permite
corrigir infecção e knockback sem depender da pesquisa de vídeo bloqueada.

## Diferenças verificadas no código atual

> Revisão original do protótipo `65fad8b`. A etapa seguinte já implementa ajustes
> específicos de infecção, rodada, rifle e HUD: veja o
> [estado atual e roteiro de validação](CLASSIC_GAMEPLAY.md). As pendências de
> física de barricadas e identidade visual continuam abertas.

| Área | Comportamento implementado | O que falta estabelecer |
| --- | --- | --- |
| Infecção | Automática por distância e linha de visão, verificada a cada 0,15 s | Ação de ataque, alcance, ritmo e transformação conforme a referência |
| Barricadas | Cinco objetos ancorados; selecionar, girar e confirmar prévia | Interação física e controles equivalentes aos do servidor de referência |
| Limites dos objetos | Movimentação restrita a uma sala, sem empilhar | Regras de movimento, empilhamento e quantidade realmente usadas |
| Resistência | Vida e número de golpes definidos para este protótipo | Quais objetos quebram, quais apenas se deslocam e por quais ataques |
| Armas | Um rifle provisório, cinco peças locais, tiro por clique e recarga instantânea | Arsenal, aparência, cadência, recuo, recarga e munição |
| Primeiro infectado | Seleção aleatória e teleporte para o spawn dos zumbis | Transformação no local ou reposicionamento, quantidade e contagem |
| Identidade visual | Partes e materiais nativos; HUD próprio e destaques de equipe | Comparação visual do cenário, armas, personagens e interface com a referência |
| Esconderijos | Quinze posições autorais, com aproximações testadas estaticamente | Comportamento tático, saltos, gargalos e defesa em grupo no motor |

Esses pontos são observações do repositório. Não constituem afirmações de que
todos os servidores de CS usam as mesmas regras, nem resultados de playtest.

## Critérios já definidos pelo usuário

- Survival / Zombie Mod: humanos se defendem e zumbis invadem e infectam.
- Não implementar Zombie Escape.
- Cenário urbano-industrial original, com identidade próxima dos mapas citados.
- Interiores, corredores, salas defensáveis, túneis, posições elevadas e rotas
  coerentes; nenhuma posição impossível de alcançar pelos zumbis.
- Priorizar defesa em grupo e a experiência reconhecível para quem joga Zombie
  Mod. Novas mecânicas próprias precisam ser justificadas pela referência.
- Não tratar compilação, contagem de peças ou testes geométricos como prova
  de fidelidade visual ou de jogabilidade.

## Próxima implementação

Usar Zombie:Reloaded Franug Edition como referência principal recomendada das
regras clássicas e ZombieSharp como comparação de CS2. Os módulos de
ZombieModSharp/CS2Fixes servem de referência técnica; seus projetos enfatizam
Escape e suas opções de spawn não devem ser adotadas automaticamente no Survival.

Priorizar as diferenças confirmadas no código externo: ataque que acerta para
infectar, transformação no local como padrão configurável e knockback por dano,
arma, hitgroup e classe. Corrigir e testar esse ciclo antes de expandir o mapa.
A interação de barricadas ainda precisa de referência específica: esses núcleos
não validam o sistema de prévia nem um comportamento universal de todos os props.

Quando o acesso a vídeo for aplicado, complementar com situações de início da
rodada, primeira infecção, uso de objetos e defesa de um esconderijo. Selecionar
vídeos de Survival e registrar o que foi observado; títulos ou miniaturas não
constituem evidência de mecânicas vistas em vídeo.

A arquitetura existente foi elogiada pelo usuário antes dessa correção.
Preservá-la enquanto se estabelece se a rejeição também exige mudanças visuais
ou de layout. Não demolir ou substituir setores por suposição.

Não há conexão com o Roblox Studio do usuário nesta sessão. Testes de física,
controles, aparência e multiplayer precisam ocorrer no Studio.

Backup local do estado anterior à revisão: branch
`backup/before-cs-alignment-65fad8b`, base `65fad8b`.
Este documento registra a revisão; não altera a jogabilidade nem representa
uma nova versão do place jogável.
