# 0.5 — Armas, impactos e resultado

Pacote no mesmo projeto/main, baseado em Zombie Escape/Survival. Backup antes
das alterações: `backup/before-combat-v05-76e98f1`.

## Comportamento

- Primeira pessoa clona os braços reais do avatar R6 ou R15. O R6 usa poses
  procedurais e o ponto nativo de empunhadura; o R15 conserva as animações
  revisadas. O clone não executa scripts nem altera o personagem original.
- Rifle, SMG e pistola têm movimentos de recarga distintos e movimentam o mesh
  do carregador; a escopeta tem ciclo visual da bomba. Munição e duração vêm
  do servidor. Cancelar/trocar deve restaurar transparência e posição.
- O modelo nas mãos passa a funcionar também na fase pública de treino solo.
  Terceira pessoa R6 mantém a empunhadura nativa; não foram criados clips R6
  de recarga em terceira pessoa. A integração R15 existente foi preservada.
- Impactos distinguem metal, madeira, pedra/concreto, vidro e infectados.
  Reutilizam a textura do kit revisado, com até 24 emissões por segundo por
  cliente e remoção automática. Não há novos IDs de áudio ou de textura.
- Resultado mostra abates, infecções, objetivos aceitos, dano efetivo,
  precisão, headshots fatais, bônus pago e saldo. Precisão conta disparos que
  removeram vida, uma confirmação por disparo, mesmo na escopeta. Dano não
  excede a vida removida; proteção sem perda de vida não produz confirmação.
- O destaque da rodada é calculado no servidor por contribuição. É informativo,
  sem prêmio adicional. Treino e preparação não contam nessas estatísticas;
  os números são de sessão, sem persistência. O × fecha o painel até a próxima
  rodada. Objetivos contam uma vez, após aceitação na sequência de Escape.

As quatro classes e seis acabamentos existentes permanecem; esta entrega
melhora sua apresentação e o encerramento da partida, sem aumentar o arsenal.

## Validar em conjunto

Atualize **zombie-outbreak-reborn → main** pelo GitHub Desktop, salve/feche o
place anterior e abra **ABRIR_JOGO.cmd**. Confira **v0.5.0**.

1. Sozinho, compre e teste as quatro armas: mira, disparo, recarga, troca no
   meio da recarga e retorno. Confira carregadores, bomba e braços; repita com
   avatar R6 e R15. Atire em metal, madeira e concreto para comparar impactos.
2. Com dois clientes, confira a arma do outro jogador, tiros, som e recarga.
   Complete uma rodada Escape e uma Survival. No resultado, compare abates,
   infecções, objetivos, bônus e saldo com o que aconteceu na partida.
3. Feche o resumo e aguarde a rodada seguinte: ele não deve reaparecer com
   números antigos. Confira câmera e armas após morrer/renascer e ao sair do
   espectador. Treino anterior não deve entrar no resumo multiplayer.

## Verificações e limites

Testes executam controladores reais com APIs simuladas e validam políticas de
recarga, transformações dos clones, restauração de modelos, limites de efeitos,
estatísticas, proteção contra dano e publicação dos resultados. A build nativa
é recompilada e inspecionada contra os fontes e checksum.

Não houve execução no Roblox Studio local. Alinhamento visual, reprodução e
permissões de áudio/animações, renderização das partículas, câmera, física e
sincronização em rede dependem do teste no motor. Os testes automatizados não
comprovam aparência final nem FPS.
