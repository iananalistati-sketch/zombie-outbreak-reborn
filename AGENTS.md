# Zombie Outbreak Reborn — direção autônoma

## Autorização e objetivo

- Em 06/11/2026, o usuário delegou direção, planejamento, implementação e
  escolhas técnicas. Ele quer receber builds e um roteiro curto de validação.
  Não pedir aprovação para escolhas rotineiras já dentro dessa autorização.
- A autorização atual substitui as exigências antigas de copiar um CS inteiro
  ou de aguardar nova aprovação para adaptar o FPS. Preservar a ideia: Zombie
  Survival/Mod, infecção, posições defensivas, barricadas e ambiente detalhado.
- Plano ativo: docs/PROJECT_DIRECTION.md. Projeto principal: este repositório,
  main. fps-lab é arquivo de pesquisa, sem desenvolvimento de produto paralelo.
- O usuário exige entregas grandes e coerentes, reunindo várias melhorias
  perceptíveis. Agrupar trabalho de gameplay, mapa e apresentação por objetivo
  jogável; não pedir nova validação a cada objeto ou ajuste mínimo. Correções
  isoladas cabem quando desbloqueiam uma falha que impede jogar.

## Arquitetura e entrega

- Runtime próprio controlável, reaproveitando assets/componentes revisados.
  Sem DataStores, HTTP ou bans como dependências para a primeira sessão.
- Dano, munição, créditos, infecção e rodadas pertencem ao servidor. O treino
  é uma fase própria, limitada a um jogador; a segunda conexão a desabilita.
- Movimento inicial nativo Humanoid. SourceMotor experimental fora do perfil.
  MovementState compõe postura e efeito temporário dos tiros sem acumulação.
- K-17 e quatro armas reais são o conteúdo inicial, sem contar skins como armas.
  Não substituir arma real por blocos. Não importar mapas CS para o produto.
- Respeitar MIT/Apache e Roblox Limited Use dos componentes; preservar origem.
- Fazer backup Git antes de mudanças importantes. Não apagar pesquisa/versões
  antigas sem preservação. Main recebe a entrega depois das verificações.
- Recompilar o place nativo e seu checksum depois de editar fontes. O usuário
  abre ABRIR_JOGO.cmd; não depender de Command Bar ou instalações manuais.
- Compilação e APIs simuladas não comprovam renderização, áudio, física ou
  multiplayer real. Nunca declarar acesso ao Studio local sem conexão.
- Corrigir falhas concretas na mesma arquitetura. Não trocar novamente de base
  só porque outra parece pronta. Priorizar uma sessão completa por entrega.

Histórico anterior preservado em docs/history/AGENTS-before-autonomous.md.
