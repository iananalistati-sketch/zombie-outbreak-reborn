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
- Exigência reafirmada pelo usuário após validar a 0.2: o produto deve se
  basear nos modos Zombie Escape e Zombie Survival/Mod do Counter-Strike.
  Decidir combate, infecção, barricadas e objetivos a partir desse núcleo.
  Survival vence por resistir; Escape exige percurso/objetivos e extração.
  NPCs e ondas pertencem ao treino solo, não definem os modos multiplayer.
- O usuário exige entregas grandes e coerentes, reunindo várias melhorias
  perceptíveis. Agrupar trabalho de gameplay, mapa e apresentação por objetivo
  jogável; não pedir nova validação a cada objeto ou ajuste mínimo. Correções
  isoladas cabem quando desbloqueiam uma falha que impede jogar.
- Na resposta de 07/11/2026, identificou "Combate, armas e sensação de FPS"
  como principal problema. Priorizar essa experiência, com resultado percebido
  ao atirar e mirar, antes de novas expansões periféricas do mapa.

## Arquitetura e entrega

- Runtime próprio controlável, reaproveitando assets/componentes revisados.
  Sem DataStores, HTTP ou bans como dependências para a primeira sessão.
- Dano, munição, créditos, infecção e rodadas pertencem ao servidor. O treino
  é uma fase própria, limitada a um jogador; a segunda conexão a desabilita.
- O solo padrão é exercício Escape, não três ondas no corredor. TrainingDirector
  reutiliza EscapeSession exclusivamente na fase Training, com até quatro NPCs
  e vitória por extração. Usa ZO_TrainingMode e não muda ZO_RoundMode/roundId.
  Destruir sessão/portões/atores no handoff antes da preparação multiplayer.
- Resumos contam disparos aceitos e dano efetivo do servidor, por rodada;
  treino não entra nas estatísticas multiplayer. Impactos e recarga visual
  são cosméticos, com orçamento/expiração e sem alterar física do personagem.
- ShotPrediction só mantém contador visual local. Nunca escrever ZO_Ammo ou
  ZO_Reserve no cliente; FireAck confirma o snapshot real. IDs antigos, troca,
  recarga e reset precisam limpar/rejeitar predições de outra janela.
- Preservar arquivos originais de armas. Áudio público usado no derivado é
  documentado em third_party/creator-store-audio/SOURCE.json; metadados públicos
  não comprovam reprodução na experiência. Manter limites de vozes/clarão.
- Round é a única autoridade de modo multiplayer e da fase Training. EscapeSession
  é subordinada ao controlador da fase, sem loop próprio: limpa prompts/portão na saída e confirma
  extração por posição, vida, equipe e participação no servidor.
- Retornos ZE avançam somente após objetivo concluído e travessia de humano
  vivo participante. Nunca teleportar perseguidores vivos para acompanhar o
  grupo. Consultar distância de humanos e volume de corpo, recuar para postos
  anteriores ou aguardar protegido. Round retenta a cada 0,5s e limpa sua
  âncora/ForceField; espera não pode disparar, infectar ou golpear barricadas.
- HoldGates só fecha uma passagem livre de personagens e barricadas. Tocar uma
  porta já fechada não a reabre; sair do hold/cancelar libera todas as portas.
- Espectador usa zumbis vivos em Active para impedir exposição de refúgios dos
  humanos, devolve câmera/zoom ao renascer e respeita controle externo de câmera.
  Lobby durante Preparation/Active tem movimento bloqueado pelo servidor;
  limpeza libera também os espectadores que não estavam entre participantes.
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
- Após a crítica à pouca evolução visível na 0.4–0.6, priorizar alterações que
  o usuário encontre ao abrir/jogar. Não usar volume de testes como substituto
  de experiência; não declarar aprovação sem relato explícito do usuário.
- Corrigir falhas concretas na mesma arquitetura. Não trocar novamente de base
  só porque outra parece pronta. Priorizar uma sessão completa por entrega.

Histórico anterior preservado em docs/history/AGENTS-before-autonomous.md.
