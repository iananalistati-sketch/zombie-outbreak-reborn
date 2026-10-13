# Zombie Outbreak Reborn

Jogo Roblox Studio com Luau e Rojo 7. Equipes, rodada, infecção e protótipo FPS.
Survival e Escape serão modos distintos. Sem arquivos proprietários do CS2.

## Mapa Survival atual: Riverside Transit

Projeto modificado para **um mapa de estação/garagem**, não mais o Foundry improvisado.
A arquitetura usa sete setores em `Workspace → ZO_Survival` e fica visível no editor antes de Play.
Consulte `docs/SURVIVAL_LAYOUT.md` para rotas, esconderijos e entradas dos zumbis.

### Atualizar via Rojo
1. Stop no Roblox Studio.
2. GitHub Desktop → Fetch origin → Pull origin.
3. Se o projeto não atualizar, reinicie o Rojo no VS Code e reconecte o plugin.
4. Selecione `Workspace → ZO_Survival`, pressione **F** para enquadrar.
5. Teste com dois jogadores e envie **Saída** (Output) se houver erro.

Esta é uma revisão arquitetônica própria inspirada em Zombie Mod (CS:S/CS2). **Os gráficos ainda usam materiais nativos; arte 3D e PBR customizados não estão instalados.**

## Fontes
- `default.project.json`: projeto Rojo, materiais e modelos persistentes
- `src/server`: rodadas, infecção, combate e diagnóstico
- `src/client`: HUD e rifle FPS
- `src/shared`: parâmetros
- `docs/SURVIVAL_LAYOUT.md`: planta e rotas de defesa
