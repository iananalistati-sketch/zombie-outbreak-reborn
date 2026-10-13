# Zombie Outbreak Reborn

Jogo de zumbis em Luau para Roblox Studio, inspirado na jogabilidade de Zombie Survival e Zombie Escape do Counter-Strike. Projeto próprio: não contém código, modelos nem mapas proprietários do CS2.

## Desenvolvimento com GitHub + Rojo 7

1. No GitHub Desktop, use **Fetch origin → Pull origin**.
2. Deixe o **Rojo Server** ligado no VS Code e o plugin conectado no Roblox Studio.
3. Acesse `Workspace → ZO_Survival` no Explorer. O mapa persistente está em 6 modelos, visível **fora do Play**. Selecione a pasta e pressione **F** para enquadrar.
4. Use **Play** para testar HUD, combate e infecção; 2 clientes para validar uma rodada.
5. Se os modelos não aparecerem após o Pull, reconecte o plugin Rojo ao servidor iniciado na pasta correta.

## Pastas

- `src/maps/`: geometria do Survival como arquivos `.model.json` sincronizados com o editor
- `src/shared/`: parâmetros de rodada e jogo
- `src/server/`: rodadas, infecção, combate e diagnóstico estrutural
- `src/client/`: HUD e rifle FPS
- `docs/SURVIVAL_LAYOUT.md`: planta e descrição de cada rota defensiva

## Situação do desenvolvimento

- Fundação multiplayer: equipes, seleção de zumbi, infecção e rodadas em fase de teste.
- Combate FPS: rifle, dano e knockback prototipados.
- **Survival**: mapa arquitetônico persistente com pátio, triagem, segurança, manutenção, galeria e controle. Os acessos e colisões ainda exigem validação no Studio.
- **Escape**: planejado, ainda não implementado nesta reestruturação.
- Direção artística: materiais e peças nativas neste momento. Assets 3D personalizados, acabamentos e texturas PBR ainda não foram incorporados.

**Não edite diretamente e salve como definitivo um objeto controlado pelo Rojo; as mudanças manuais podem ser substituídas pela próxima sincronização.**

Projeto testado por inspeção dos arquivos e verificação de propriedades e dimensões dos modelos. Não foi executado dentro do Roblox Studio pelo desenvolvedor remoto.
