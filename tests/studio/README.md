# Validação de Survival no motor Roblox

**Preparado e compilado na nuvem. Ainda não executado no Roblox Studio.**

O arquivo já compilado acompanha o repositório. Após atualizar a branch em teste
(`feat/fps-combat-package` para esta correção), abra
`builds/ZombieOutbreakReborn_SurvivalTest.rbxl` no Studio. Em **Server &
Clients**, selecione **2** clientes e inicie. Aguarde a execução automática sem
comandar os personagens. No Output do servidor, procure:

```text
[SURVIVAL STUDIO] COMPLETE: 16 checks passed in the Roblox engine.
```

Um erro gera `[SURVIVAL STUDIO] FAIL at ...`, com a etapa e o motivo. No servidor,
`ServerScriptService.ZO_StudioSurvivalScenario` também registra `Status`, `Stage`,
`Checks` e, se houver falha, `Failure`.

O teste preserva os fontes de produção de rodada e combate. Somente nesse
place, as rodadas duram 30 segundos e dois drivers dirigem pedidos reais de
disparo, recarga e ataque corpo a corpo pelos remotes de produção. Confere dano,
munição, transferência de reserva, infecção, vitória zumbi, vitória humana pelo
tempo e início automático da rodada seguinte. Também confere a velocidade
configurada do zumbi, a lentidão temporária de um tiro, recuperação após o tiro,
uma sequência de seis acertos sem acumular lentidão e recuperação após o último.
A observação usa o `Humanoid.WalkSpeed` real, incluindo o arredondamento da
propriedade que os testes anteriores com APIs simuladas não representavam.

Os personagens são posicionados e ancorados para tornar os raios repetíveis;
ForceFields de nascimento são removidos. As novas verificações conferem a
propriedade de velocidade; não medem deslocamento nem resolvem contatos físicos.
Isso não aprova navegação, knockback,
controles de teclado/toque, armas visuais, sons, animações, equilíbrio ou latência.
O resultado só pode ser chamado de aprovado depois de executar esse place no
Studio e obter a saída de conclusão.

Os drivers não entram em `default.project.json`. Esse place é uma ferramenta de
teste e não deve ser publicado como o jogo.

Após editar os fontes, recompile o arquivo de teste pela raiz do repositório:

```sh
python scripts/build_studio_survival_test.py --rojo CAMINHO_DO_ROJO
```
