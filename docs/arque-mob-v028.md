# Arque Mob v0.28 — Folha de desenho com abas e foto
Versão experimental isolada na branch feature/arque-mob-folhas-fotos-v028; ramo v0.27 mantido.

## Comportamento implementado
- Ferramentas reunidas no cabeçalho, com menu contextual por Linha, Selecionar, Mão Livre, Nota e Mover Foto. Faixa lateral e barra de ações antiga ocultadas.
- Linha exige pressionar e arrastar antes de soltar. Toque único no fundo não cria linha. Etiqueta horizontal acompanha o segmento e mostra comprimento provisório em centímetros após soltar.
- O comprimento inicial é estimado pela escala gráfica, **não é uma medição de ambiente**. Ao tocar na linha, usuário pode substituí-lo por medida conferida.
- Largura do traço ajustável na barra (de 0,7 a 6 px para Linha; até 9 para Mão Livre); paleta, setas nas pontas, cantos 90°, Fundir/Encostar preservados.
- Folhas independentes, abas visíveis, botão Nova Folha, renomear ou excluir a folha atual; restauração após salvar e reabrir a obra.
- Importar imagem local JPG/PNG (convertida para JPEG compactado), usar como plano de fundo, redimensionar, ajustar opacidade, mover e desenhar/colocar medidas por cima. Não extrai medidas físicas automaticamente.
- Anotações, escrita livre, calculadora móvel, desfazer/refazer, zoom ancorado com dois dedos e código 3D oculto continuam disponíveis.

## Validação
Chromium headless simulado em 1180×780, 820×1180 e 390×844: clique sem traçar, arraste para criar linha, folhas independentes, importar imagem, mão livre, nota, barra de espessura, sem overflow JS. Teste adicional: mover foto, desfazer movimento, restaurar sem foto e trocar folhas. CI compila APK e executa verificações de integridade do projeto.

**Limitações:** fotos e medidas anotadas devem ser conferidas manualmente; não usar para CNC sem revisão. O teste na S Pen/Tab S9 físico ainda é necessário. Faça backup antes de instalar outra assinatura Android.
