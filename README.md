# Zombie Outbreak Reborn

Jogo Roblox Studio com Luau e Rojo 7. Equipes, rodada, infecção e protótipo FPS.
Survival e Escape serão modos distintos. Sem arquivos proprietários do CS2.

## Atualização do mapa Survival (2026-10)

**Mapa declarado diretamente no `default.project.json`**, usando instâncias e propriedades no formato oficial de projeto Rojo. O projeto inclui seis modelos com 382 peças estáticas e uma coluna laranja de teste chamada `ZO_Survival_Probe`.

**Como receber a geometria no editor:**
1. Roblox Studio: clique em Stop.
2. GitHub Desktop: Fetch origin e Pull origin.
3. VS Code: pare e reinicie o servidor Rojo para recarregar o `default.project.json` (a extensão já está instalada).
4. Roblox Studio: no plugin Rojo, Disconnect e Connect novamente ao projeto correto.
5. Confira `Workspace → ZO_Survival` e `ZO_Survival_Probe` **antes de Play**.

Se **nenhum dos dois** aparecer: confira `View → Output → Rojo` no VS Code e envie o primeiro erro. Não reinstale extensões.
Se **somente a coluna** aparecer: verifique erros de propriedade/filhos durante a sincronização.
Se **ambos aparecerem**: selecione `ZO_Survival` e use a tecla **F** para centralizar a câmera.

## Fontes
- `default.project.json`: estrutura Rojo e geometria declarada
- `src/maps`: dados de referência do desenho, não importados
- `src/server`: rodadas, infecção, combate e diagnóstico
- `src/client`: HUD e câmera FPS
- `src/shared`: parâmetros
- `docs/SURVIVAL_LAYOUT.md`: planta e rotas táticas

## Limitações

A estrutura foi validada como JSON, com partes, cores, materiais e CFrames formatados conforme a documentação Rojo. **Ainda falta confirmar um build real com Rojo 7.7.1 e a importação no Roblox Studio.** O cenário é um blockout arquitetônico, sem arte 3D realista.
