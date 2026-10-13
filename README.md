# Zombie Outbreak Reborn

Projeto Roblox Studio com Rojo 7 e Luau.

## Desenvolvimento

1. Clone o repositório: `git clone https://github.com/iananalistati-sketch/zombie-outbreak-reborn.git`
2. Abra a pasta no VS Code.
3. Execute `rojo serve` no terminal.
4. No Roblox Studio, abra uma experiência **Baseplate de testes**, abra o plugin Rojo e conecte em `localhost:34872`.
5. Confirme na janela **Saída (Output)** as mensagens `[Zombie Outbreak] Server bootstrap OK` e `[Zombie Outbreak] Client bootstrap OK`.

**Atenção:** use uma experiência nova ou faça backup antes de sincronizar. Rojo controla os caminhos definidos em `default.project.json`.

## Estrutura

- `src/shared`: configuração e módulos compartilhados
- `src/server`: serviços autoritativos no servidor
- `src/client`: câmera, controles e interface locais

## Direção

Dois modos planejados: Zombie Survival (defesa em esconderijos e pontos estratégicos) e Zombie Escape (progressão, portas e extração). Inspirados em Counter-Strike, mas com sistemas próprios em Luau e assets licenciados. Não incluir arquivos proprietários de CS2.
