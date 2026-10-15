# Arque Mob 0.21 — prévia integrada ao Arque Measure

Atualização isolada na branch de testes. A versão principal `main` não foi alterada.

## Etapas implementadas
1. Câmera 3D, seleção de peças, movimento e encaixe sem sobreposição entre móveis no eixo X.
2. Regras dimensionais preliminares de MDF, portas, gavetas, cava, porta-temperos, e materiais distintos por módulo (novo padrão MDF 18 mm).
3. Cubas, geladeiras, cooktops, fornos e micro-ondas como referências visuais dimensionáveis, fora do plano de MDF. Não substitui catálogo de medidas dos fabricantes.
4. Prévia de lista de peças com nome, tamanho em mm, material, bordas e alertas, exportável como CSV. Não há otimização de chapas nem plano CNC confiável.

## Validação
Teste de navegador com Chromium headless e 23 verificações: navegação, material, colisões, equipamentos, alterações dimensionais, persistência e abertura de projeto com campos antigos ausentes.
Testes JavaScript de sintaxe e GitHub Actions Android.
**Limites:** não testado fisicamente no Samsung Tab S9, e medidas preliminares não devem ser usadas para corte sem conferência.

## Segurança dos projetos
Arquivos do construtor permanecem vinculados ao projeto e ambiente. Faça backup no Arque Measure antes de atualizar o APK, especialmente se houver mudança na assinatura de teste.
