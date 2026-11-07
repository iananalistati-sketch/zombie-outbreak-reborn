# 0.8 — Combate, armas e sensação de FPS

Foco indicado pelo usuário: resposta ao tiro, arma na tela, mira e áudio.
Backup: `backup/before-fps-v08-c5372fa`.

## O pacote

- Enquadramento próprio para carabina, SMG, pistola e escopeta; recuo de câmera
  e deslocamento da arma revistos. Reutiliza os componentes ACS/Extract/spr já
  integrados, preservando as licenças e o controlador atual.
- Sensibilidade do mouse acompanha o FOV durante a mira. Usa a precisão real
  da propriedade para não confundir arredondamento com mudança externa. Menus,
  foco, cancelamento e destruição restauram o valor que o sistema possui;
  alterações feitas por outro controlador são respeitadas.
- Cliques de pistola/escopeta até 120ms antes do fim do intervalo podem gerar
  um disparo ao liberar a cadência. É um clique, não um modo automático. Foco,
  menu, troca e recarga cancelam a espera. A cadência do servidor continua valendo.
- O contador visual reduz imediatamente. Cada tentativa tem ID e recebe
  FireAck com arma, munição real e aceitação. Respostas antigas não repõem
  balas após troca/recarga/reset. Sem confirmação por 1,5s, para novas predições
  e informa espera. Acertos e dano continuam sendo confirmados pelo servidor.
- Evita repetir efeitos com a última bala só porque a atualização da munição
  ainda não chegou. Efeitos locais já previstos podem ter ocorrido antes de uma
  rejeição; a reconciliação corrige o contador, não desfaz som já ouvido.
- Clarão de 35ms no ponto real do cano, alcance oito studs, sem sombras.
  Limpeza e sequência impedem flashes antigos de reaparecer ao trocar/parar.
- Os feixes coloridos longos foram substituídos por um rastro curto e discreto,
  de cor neutra, no fim do raio confirmado pelo servidor. A escopeta não cria
  um feixe para cada pellet visual. Impactos por material foram preservados.
- A bomba da escopeta agora recua no eixo da empunhadura. O mesh original tem
  Z local invertido; a movimentação anterior a empurrava no sentido oposto.

## Áudio aplicado

A API de detalhes da Creator Store retornou os oito áudios antigos como
`published=false` e `isFree=false`. Foram escolhidas referências listadas como
publicadas e gratuitas, registradas com autores e metadados em
[SOURCE.json](../third_party/creator-store-audio/SOURCE.json).

| Classe | Tiro | Recarga |
| --- | --- | --- |
| Carabina | 18835647605 / CBE_Simon | 139048584127232 / kaizz93 |
| SMG | 18835775932 / CBE_Simon | 139644400203673 / jiggy519 |
| Escopeta | 71816202649396 / CBE_Simon | 145081845 / nettimato |
| Pistola | 92967624763578 / Dodfoz | 119970005937974 / abirr3935 |

As referências estão no Arsenal.rbxmx derivado, incluindo os seis acabamentos.
Os arquivos originais revisados permanecem intactos. Não há download/execução
de controladores externos. A sobreposição dos tiros tem limite de seis vozes;
som anterior não é interrompido a cada disparo automático. Recarga usa a
duração real do clip para ajustar velocidade/posição ao prazo autorizado,
preservando seu começo e cancelando ao interromper a recarga.

O endpoint de entrega anônima respondeu 401 para sons antigos e candidatos
públicos. Logo, **listagem pública não é uma confirmação de reprodução** nesta
experiência. O teste de áudio precisa ocorrer no Studio; não foram inventados
resultados de escuta, volume ou autorização.

## Teste curto no Studio

Atualize **zombie-outbreak-reborn → main → Fetch/Pull origin**, feche o cenário
anterior e abra **ABRIR_JOGO.cmd**. Confira **v0.8.0**.

1. No treino, atire em rajadas e esvazie a carabina. Confira contador imediato,
   som, clarão e recuperação da mira. Recarregue e repita com a SMG.
2. Mire e solte; abra/feche arsenal/mapa durante a mira. Confira que o mouse
   recupera o controle normal. Repita usando Alt+Tab e retorno à janela.
3. Com pistola e escopeta, clique em sequência, confira recarga e o sentido da
   bomba. Troque de arma durante a recarga. Teste também um acabamento.
4. Com dois clientes, confira tiros/recarga vistos e ouvidos pelo outro jogador.
   Em emulação de rede do Studio, compare o contador com o consumo real após
   atrasos; a última bala não deve sustentar uma rajada visual sem munição.

## Verificação e limites

Testes executam controle de armas e combate reais com APIs simuladas. Cobrem
última bala, rejeição, confirmação antiga, recarga, troca/reset, espera, clique
antecipado, sensibilidade float32 e alterações externas. O adaptador real é
exercitado para sobreposição/limpeza de áudio, clarão e eixos invertidos da bomba.
Geometria, modelos, conteúdo nativo e procedência dos áudios também são conferidos.

Não houve execução no Roblox Studio. Enquadramento final, aparência, latência
real, áudio/permissões e qualidade percebida precisam dessa validação. A
entrega trabalha as quatro classes atuais; não adiciona um novo arsenal nem
substitui a física do motor Roblox pela de Counter-Strike.
