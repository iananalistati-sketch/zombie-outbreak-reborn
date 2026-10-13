# Foundry Survival — especificação de layout v0.1

## Estado
Primeira revisão arquitetônica sincronizada no **modo de edição** pelo Rojo.
É um **blockout arquitetônico funcional em avaliação**, não um mapa artístico de nível CS2.
Não foram importados mapas, modelos ou texturas do Counter-Strike.

## Planta e lógica arquitetônica
- Complexo industrial de separação de cargas, com entrada no **pátio de recebimento** (sul, z~-130).
- **Galpão de triagem** no centro (x~-92..92, z~-60..128): duas linhas de esteira em paralelo, corredores entre elas, estantes de almoxarifado no fundo e galeria de inspeção com duas escadas.
- **Escritórios e segurança** no anexo oeste (x~-160..-94, z~-11..117): recepção, corredor, salas de operação, arquivos. A saída lateral do galpão conecta ao corredor de serviço.
- **Manutenção e geração** no anexo leste (x~96..160, z~-10..118): geradores, tubulações, quadros técnicos, corredor de serviço e saída leste.
- **Sala de controle** ao norte (x~-47..47, z~149..185): sala elevada, consoles, uma escada de acesso pela frente e uma segunda saída posterior.
- **Galeria técnica elevada** e **duto de cabos** atravessam áreas de transição, em vez de surgirem como plataformas sem contexto.

## Pontos defensáveis de Survival (não são áreas invulneráveis)

| Posição | Vantagem humana | Entrada dos zumbis / risco | Recuo |
|---|---|---|---|
| Galeria de inspeção | Visão do chão do galpão; tiro com knockback | Duas escadas nas extremidades e alcance lateral | Descer para depósito ou correr ao controle |
| Segurança administrativa | Corredores e móveis como cobertura; gargalo no arquivo | Entrada da recepção + duto de cabos pelo galpão | Seguir corredor sul |
| Duto técnico | Acesso estreito que favorece defesa em sequência | Ambas as bocas acessíveis por escadas | Sair pelo galpão ou pelo escritório |
| Sala de controle | Janela de observação e corredor em funil | Portas/frentes sul e norte (via pátio posterior) | Escada posterior |
| Manutenção | Acesso lateral e obstáculo real de geradores | Portas do galpão + saída externa leste | Corredor externo leste |

## Rotas previstas
- **Rota principal**: pátio de recebimento → docas → portão sul → esteiras → portão norte → serviço norte → sala de controle.
- **Flanco oeste**: pátio oeste → recepção → corredores do escritório → abertura lateral do galpão.
- **Flanco leste**: via de serviço leste → sala de geradores → abertura lateral do galpão.
- **Rota elevada**: piso do galpão → escada oeste ou leste → galeria de observação.
- **Duto**: piso do galpão → escada do duto → trecho elevado → escada administrativa.

## Regras para próximos ajustes
1. Não acrescentar coberturas ou caixas aleatórias; todo objeto tem de pertencer a uma função plausível de logística, segurança ou manutenção.
2. Antes de criar uma posição de defesa, identificar pelo menos uma forma de invasão e uma forma de recuo.
3. Manter linhas de visão e largura de circulação compatíveis com personagens Roblox, knockback e partidas de vários jogadores.
4. Validar passagem real e colisões **dentro do Roblox Studio**. O projeto não foi executado remotamente.
5. Acrescentar assets 3D licenciados e materiais personalizados somente depois de validar rotas/escala. Neste commit, as superfícies ainda são materiais nativos.
6. Para mapa definitivo e modo Zombie Escape, criar projeto de mapa separado, não reaproveitar a mesma arena.

## Integração do Rojo
`default.project.json` sincroniza `src/maps` em `Workspace.ZO_Survival`. 
Os modelos `00_...model.json` até `05_...model.json` persistem no **modo de edição**. 
O gerador antigo `FoundryMap.server.luau` foi removido.
Mudanças feitas à mão nos objetos sincronizados no Studio podem ser substituídas pelo próximo Pull/Sync; altere a fonte controlada pelo Rojo.

## Verificação no editor
Após `Fetch origin → Pull origin` no GitHub Desktop, volte ao Studio com o Rojo conectado.
Expanda `Workspace → ZO_Survival`. Devem aparecer 6 modelos.
Selecione `ZO_Survival` e pressione **F** para enquadrar a planta.
Faça testes com dois clientes, verificando portão frontal, dois acessos à galeria, duto com duas saídas e sala de controle.
