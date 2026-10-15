# Referências efetivamente examinadas para K-17

## O que foi possível acessar

YouTube e GameBanana responderam com bloqueio de rede (HTTP 403). A busca pública
no GitHub permitiu localizar duas variantes em repositórios de distribuição.
Os BSPs foram examinados **somente fora do checkout, para estudo**: cabeçalhos,
vértices, faces horizontais, alturas, entidades de spawn e nomes dos materiais.
Também foram vistas projeções medidas dessas faces, geradas para a análise.

Não foram assistidos vídeos nem vistas capturas de gameplay dos jogos originais.
A análise geométrica não comprova iluminação, comportamento de portas,
colisões do motor original ou fidelidade visual ao CS2.

| Referência | Variante analisada | Evidência |
| --- | --- | --- |
| `zm_lila_panic` | `zm_lila_panic_173`, Source BSP v20 | 7.646 vértices; 1.327 faces horizontais superiores após retirar superfícies técnicas; 64 entidades de spawn |
| `zm_ice_attack` | `zm_ice_attack`, GoldSrc BSP v30 | 3.252 vértices; 457 faces horizontais superiores após retirar superfícies técnicas; 40 entidades de spawn |
| `zm_dust2`, `zm_toxic_house`, `zm_office`, `zm_the_deserted_factory` | Sem análise visual/geométrica confirmada | Não usadas como evidência de detalhes arquitetônicos específicos |

### Fontes e revisões

- [Lila Panic 173 — arquivo público no FastDL](https://github.com/David159357/fastdl/blob/cb00697d4ec5cb37a02979c4ff395ccf6cb52582/maps/zm_lila_panic_173.bsp.bz2)
  - Revisão: `cb00697d4ec5cb37a02979c4ff395ccf6cb52582`.
  - SHA-256 do BSP descompactado:
    `c4a2e66cf1a52c56419042572af5049810bfe78514ab339024c74a0d7055e376`.
- [Ice Attack — arquivo público no FastDL](https://github.com/sabemiyadare/HikoZukushiro-FastDL/blob/6cf4e122e3cf12ecf037ab713f5f50f091b4f431/maps/zm_ice_attack.bsp)
  - Revisão: `6cf4e122e3cf12ecf037ab713f5f50f091b4f431`.
  - SHA-256:
    `fdacd7f4797789c535ad91d7c9e7f42d4a4042105949c9358df709b1e3480e6f`.

Esses distribuidores não estabelecem a autoria ou uma licença de reutilização.
Nenhum BSP, textura, mesh, imagem desses mapas ou conversão de sua geometria foi
adicionado ao projeto. Os materiais e as estruturas de K-17 são próprios/nativos.

## Observações e aplicação original

**Lila 173:** as projeções mostram uma área retangular ampla em um nível e uma
rede mais estreita de espaços laterais/inferiores, com degraus e ligações entre
volumes. Os nomes de materiais incluem concreto ferroviário, alvenaria, grades,
caixas metálicas e vidro. São identificadores, não texturas extraídas para uso.

**Ice Attack:** o recorte é mais alongado e apresenta ramificações laterais,
patamares e uma região lateral rebaixada. Os materiais indicam neve, rocha clara,
madeira, vidro e metal. Não foi interpretado como um mapa industrial: a tradução
para K-17 utiliza contraste de altura e passagens, não copia sua aparência de neve.

**K-17:** pátio de distribuição no centro, edifícios com circulação completa no
perímetro, pontos altos com aproximações identificáveis e uma rede de manutenção
abaixo do solo. A planta, as dimensões em studs e as posições são novas. Não foi
feita escala ou conversão das coordenadas de nenhum mapa de referência.

A semelhança de experiência e o equilíbrio ainda precisam de avaliação com
jogadores de Zombie Mod; não se afirma equivalência visual com os originais.
