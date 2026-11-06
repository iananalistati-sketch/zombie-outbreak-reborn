# Arsenal — modelos recebidos e bloqueio de rede

**Registro histórico.** A rede voltou a responder, os dois modelos oficiais
foram recebidos e a [integração atual](OFFICIAL_ARSENAL_INTEGRATION.md) inclui
as quatro classes configuradas e seus acabamentos. O bloqueio descrito abaixo
não é o estado atual da entrega.

O objetivo desta etapa é obter e integrar um **arsenal completo de modelos
reais da Creator Store**, com várias armas. Esse objetivo permanece pendente.
As skins descritas abaixo não são contadas como novas classes de arma.

## Lote que já pôde ser integrado

O arquivo oficial `Pistolas_Oficiais.rbxl`, fornecido antes pelo usuário, contém
as variantes preta, clássica e dourada do asset `118912302094201`, sob Roblox
Limited Use License. A preta já estava incluída. Agora também são extraídas as
duas outras variantes reais, conservando meshes, texturas, attachments, joints
e áudio do original. Não foram criadas armas de blocos nem texturas substitutas.

Arquivos completos de origem ficam fora do runtime. Seus16 fontes únicos são
os mesmos já examinados na variante preta. A extração exclui scripts, remotes,
WeaponsSystem, WeaponType e referências para objetos removidos, antes de
publicar os templates cosméticos. Hashes e diferenças exatas estão em
`third_party/roblox-weapon-kit/SOURCE.json` e `pistol/REVIEW.md`.

O catálogo base continua com Rifle/Pistol disponíveis e SMG/Shotgun sem modelos.
O pacote nativo tem duas armas base e dois templates de skin,12 MeshParts e três
animações compartilhadas. Faca e novas classes não foram inventadas ou liberadas
na loja apenas por existir uma linha de configuração.

## Integração das skins

- Catálogo único `WeaponSkins`: Black, Classic e Gold para Pistol; Original
  para as demais armas conhecidas, sem anunciar armas inexistentes.
- Menu B com seleção/prévia da skin e aplicação confirmada pelo servidor.
- Servidor valida personagem vivo, equipe humana, fase, posse e modelo real;
  a arma atual não muda de skin no meio de recarga/equipamento.
- Munição, reserva, preços, dano, cadência e tempo de equipamento permanecem
  sob a autoridade existente. A skin é uma apresentação do mesmo `Pistol`.
- A seleção permanece durante rodadas e respawns na sessão; não há persistência
  entre servidores/DataStore nesta etapa.
- Prévia, primeira pessoa e arma corporal usam o mesmo template selecionado.
  Se uma variante selecionada desaparecer, o erro não é escondido por outra cor.

## Rede: resultado observado

Foi tentada a busca pública
`https://apis.roblox.com/toolbox-service/v1/marketplace/10?keyword=weapon%20pack&pageNumber=0`,
o download oficial da SMG e a pesquisa GitHub de pacotes. As chamadas falharam
com `CONNECT tunnel failed, response403`, antes de receber resposta da origem.
A repetição autorizada fora do sandbox teve o mesmo resultado. Isso não prova
que os modelos foram removidos ou que suas permissões no Studio são inválidas.

O rascunho de configuração estava com rede **disabled**. Foi salvo acesso
restricted para Creator Store, APIs Roblox, assetdelivery, CDN Roblox e fontes
GitHub, preservando scripts/repositório. A ferramenta confirmou `status:saved`
e `requires_publish:true`: o rascunho precisa ser revisado/salvo e o ambiente
publicado no Codex. Salvar não prova propagação ao processo em execução.

O usuário informou que liberou a rede. O teste imediatamente posterior ainda
recebeu o mesmo403 do proxy; a leitura confirmou os domínios no rascunho, sem
comprovar acesso de execução. Não foram obtidos novos modelos online.

Não é preciso abrir Roblox Studio para resolver a configuração de rede do
Codex. Após a publicação/atualização da sessão, retestar a busca e o download
antes de afirmar que a rede está funcional e retomar os pacotes completos.

## Validação e continuidade

As verificações possíveis usam os fontes reais com APIs Roblox simuladas,
inspeção dos assets, hashes/licenças e compilação Luau/Rojo. Não comprovam
renderização, áudio, física ou multiplayer no Studio. O cenário separado de
Survival continua separado do jogo normal.

Executado: 28 testes Python; catálogo24, combate215, equipamento38,
cliente de armas114 e loja/prévia114 verificações com APIs simuladas; ciclo
Survival39 e rodada41; compilação Luau/Rojo e conferência de35 vínculos exatos
de fonte no place. Pacote nativo e cenário isolado recompilados, checksum
atualizado. Os percursos e as defesas originais passaram sem mudanças de mapa.

A leitura do GitHub também recebeu403 no CONNECT, incluindo repetição fora do
sandbox. Assim, o trabalho é preservado por commit e backup locais; envio remoto
permanece pendente até o acesso funcionar. Não anunciar que essa entrega subiu.

Mapa K-17, barricadas, refúgios, dutos, rodadas e infecção não são reconstruídos.
Backup anterior: `backup/before-arsenal-skins-c9c5ce0` e tar verificado na nuvem.
O pacote permanece em `feat/fps-combat-package` enquanto faltarem modelos.

Próxima ação: confirmar a conectividade após a configuração publicada, obter
arquivos nativos de um pacote de várias armas com permissão de uso verificável,
examinar scripts e dependências e integrar os modelos ao único núcleo de
combate existente. Não substituir esse trabalho por novas variações das duas
armas atuais nem declarar o objetivo cumprido com as skins.
