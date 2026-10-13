# Zombie Outbreak Reborn — Riverside Transit (Survival v0.2)

## Conceito: referências e adaptação
A organização do mapa inspira-se na lógica dos Zombie Mod clássicos do Counter-Strike: Source, principalmente `zm_panic` (pátio aberto e acesso estreito ao metrô) e a importância de esconderijos defensáveis documentada nas variantes de `zm_lila_panic`. **Não é cópia nem conversão de geometria, textura ou código desses mapas.**

## Estrutura conectada
```
                 NORTE
          [PLATAFORMAS SUBTERRÂNEAS]
                    ↑
       [HALL/TICKET] ← [TÚNEL DE SERVIÇO]
                    ↑                ↑
            [ESCADA PRINCIPAL]  [ESCADA EMERGÊNCIA]
                    ↑                ↑
[ESTACIONAMENTO] ← PÁTIO → [ESCRITÓRIO SEGURANÇA]
   ↕ ↕                          ↕         ↕
  ESCADAS                      RECEPÇÃO / SAÍDA TRASEIRA
                 SUL
```

## Função arquitetônica e posicionamento tático

| Zona | Funcionalidade do edifício | Posição de defesa | Como os zumbis invadem |
|---|---|---|---|
| Pátio e rua | acesso principal e estacionamento descoberto | movimentação, agrupamento e retirada | aberto, poucos obstáculos fixos |
| Garagem dois pavimentos | estacionamento com vagas, pilares e duas escadas | pavimento superior com visão do pátio | duas escadas distintas nas extremidades |
| Escritório de segurança | recepção, guarita, mesas, corredores e duas saídas | sala interna e porta frontal estreita | entrada frontal ou passagem posterior |
| Entrada do metrô | portal, canopy e escada abaixo do nível da rua | topo/rodapé da escada (gargalo) | escada principal + ligação de emergência |
| Hall subterrâneo | bilheteria, espera, luzes de plataforma | balcão de bilheteria com duas aberturas | via escada principal ou corredor de serviço |
| Plataforma | bancos, linha de segurança e trilhos rebaixados | plataformas laterais com deslocamento e tiro | dois acessos ao hall e ao serviço |
| Saída de emergência | escada lateral, corredor utilitário e iluminação | ponto de retirada do hall | ligação pelo escritório ou área lateral |

## Validações efetuadas
- O mapa é uma instância persistente em `default.project.json`: aparece no Workspace fora de Play.
- Layout novo substitui os sete grupos de geometria inconsistentes do Foundry.
- Inspeção estática de colisões nos pontos centrais de circulação: pátio, acesso principal, degraus, bilheteria, duas plataformas, escritório, serviço e garagem.
- Uma parede obstruindo a saída de emergência e uma mesa bloqueando a circulação foram corrigidas.
- Ainda não foi possível testar escadas, pulo, collision box e equilíbrio humano/zumbi diretamente no Roblox Studio. Não tratar mapa como aprovado até testes com jogadores.

## Pendências de arte e gameplay
- Geometria é um **blockout coerente**, não arte final CS2. Para qualidade visual realista, usar assets 3D próprios/licenciados, texturas/material variants PBR, melhor iluminação e efeitos.
- Respawn em pontos opostos do pátio é provisório para teste.
- Defesa com knockback deve ser balanceada para largura das passagens e tamanho de servidor.
- Testar também a rota alternativa pelo posto de segurança, sem criar posições invulneráveis.
- Zombie Escape será um mapa e regras independentes.

## Critério de aceite do mapa
1. Humano alcança garagem superior, sala de segurança, bilheteria e plataformas sem ficar preso.
2. Zumbi tem rota real para cada posição defensiva; duas para garagem e estação.
3. Nenhuma sala ou escada termina em barreira arbitrária.
4. O ambiente se lê como uma estação, um pátio e prédios adjacentes — não como módulos aleatórios.
5. Colisão e escala testadas com ao menos dois clientes.
