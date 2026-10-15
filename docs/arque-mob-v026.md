# Arque Mob 0.26 — Folha de medidas, ferramentas e fechamento lógico

A nova versão conserva o código 3D anterior, mas mantém o 3D oculto e a Folha 2D ativa.

## Ferramentas mantidas e adicionadas
- Pontas quadradas; alinhamento em 90°; contatos em T e modos **Fundir** ligado/desligado.
- **Desfazer / Refazer**, prévia de comprimento durante o arraste, cores padronizadas, mão livre, notas com mover/ajustar tamanho, espessura quadrada visual e setas nas pontas.
- Calculadora flutuante e salvamento por obra/ambiente.

## Medição deduzida do fechamento
- O último segmento de um caminho **único e ortogonal** pode receber uma medida calculada a partir de lados já medidos.
- Para fechamento horizontal, todos os trechos horizontais do caminho que contribuem para o resultado precisam de medidas conhecidas. Para fechamento vertical, idem verticais.
- Para fechamento diagonal de um triângulo retângulo com componentes horizontal e vertical conhecidos, aplica Pitágoras.
- Em caso de medidas insuficientes, ligações múltiplas/ambíguas ou modo Fundir desligado, não é atribuída medida automática.
- Medidas automáticas aparecem como **calc**, são diferenciadas das medidas digitadas e continuam sujeitas a conferência antes da produção. O app **não usa o tamanho da imagem ou os pixels como medição física**.

## Testes
Sintaxe do JavaScript, fechamento retangular, Pitágoras, ausência de medidas, ambiguidades, Fundir desligado, compatibilidade do motor 3D e recursos da folha. Compilação do APK pelo GitHub Actions.

**Pendente:** testar no Samsung Tab S9 com S Pen, validar medidas e tolerâncias em obra real e não usar plano de corte sem revisão técnica.
