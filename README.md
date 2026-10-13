# Zombie Outbreak Reborn

FPS multiplayer survival/escape em Luau no Roblox Studio, sincronizado pelo Rojo 7.

## Mapa Survival — Harbor Locks (arquitetura de código aberto)

Substituímos o mapa antigo de blocos por um **modelo 3D importável**, montado a partir do layout industrial MIT de *Operation Steel Tide* e edifícios Kenney CC0 com interiores acessíveis.

O arquivo real já foi gerado pelo GitHub Actions:

`assets/maps/HarborLocks_Survival_Visual.glb` — aprox. 848 KB, 19 edifícios, 29 malhas, 116×84 m no GLB.

O Rojo controla apenas os scripts e colisões auxiliares. **Para ver as malhas 3D é necessária uma importação pelo Studio uma vez**, pois Rojo não publica meshes automaticamente.

### Instalar versão nova sem reconfigurar o Rojo

1. No GitHub Desktop faça **Fetch origin → Pull origin**.
2. Com o jogo parado, reinicie o Rojo no VS Code; a antiga cena `ZO_Survival` deve ser substituída por `ZO_HarborCollision`.
3. No Roblox Studio, vá a **Arquivo → Importar (File → Import)**.
4. Selecione no repositório: `assets/maps/HarborLocks_Survival_Visual.glb`.
5. Importe como **Model**, mantenha a hierarquia de meshes e confira a escala no preview. Se aparecer um aviso de limite de textura, prossiga sem forçar a importação.
6. Insira o modelo em `Workspace` e renomeie **exatamente** `HarborLocks_Survival_Visual`. Salve seu place.
7. Selecione o Model e pressione **F**. Com dois jogadores em Test, valide entrada e rotas. O Output mostra `[ZO HARBOR]`.

O MapDiagnostics ancora partes importadas na execução e avisa se o modelo estiver ausente. **Os spawns foram atualizados ao layout original**. Os meshes e suas colisões ainda precisam de teste. O resultado não é visualmente idêntico ao CS2, pois os modelos de origem são de um pacote estilizado CC0.

**Backup do projeto anterior:** branch `backup/riverside-before-harbor-import`.

## Organização

- `default.project.json`: Rojo, serviços e colisão auxiliar Harbor Locks
- `assets/maps`: GLB final e relatório de construção/escala
- `third_party/harbor-locks`: modelos originais CC0 com licença e proveniência
- `scripts/assemble_harbor_locks.py`: monta a cena a partir da planta aberta
- `src/server`, `src/shared`, `src/client`: sistemas de jogo Luau
- `docs/HARBOR_LOCKS_SOURCES.md`: fontes, licenças e fluxo de importação

A próxima etapa, **após a importação real**, é validar rotas e criar pontos defensáveis com colisão correta, sem acrescentar obstáculos aleatórios.
