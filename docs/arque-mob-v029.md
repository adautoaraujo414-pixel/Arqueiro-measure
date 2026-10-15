# Arque Mob v0.29 — Cotas horizontais sobre a linha

Atualização incremental da folha 2D v0.28, mantendo o restante do Arque Measure.

- A etiqueta da medida (por exemplo **210,7 cm**) agora fica horizontal e centralizada SOBRE a linha horizontal ou vertical, inclusive enquanto se desenha com a S Pen.
- Durante o arraste, a etiqueta muda a cada movimento, ANTES de levantar a caneta; ao soltar, o comprimento mostrado fica salvo na linha como estimativa da escala virtual.
- Tocar na própria etiqueta abre a medida numérica para digitar o valor medido de verdade.
- No modo Selecionar, ao mover a alça do segmento, o número muda na hora e fica salvo na posição final. O ponto de origem não intercepta a alça.
- Todas as ferramentas anteriores (Foto, folhas múltiplas, mão livre, notas, cores, setas, Fundir, calculadora e zoom com dois dedos) ficam inalteradas.
- O 3D permanece oculto, preservado no código.

Testes locais: navegador Chromium 1180x780, 820x1180 e 390x844 para prévia durante o desenho, etiqueta ao centro da linha, clique na cota, e teste vertical com medida editada e alça arrastada em tempo real. Testes GitHub Actions + compilação APK.

**Limite de segurança:** cm gerados no desenho vêm da escala ilustrativa e NÃO são uma medição real; confirmar dimensões antes de produzir ou cortar MDF. Teste físico com a S Pen do Galaxy Tab S9 ainda pendente. Fazer backup dos projetos antes de reinstalar.
