# Relatório de testes e limitações

Data: 19/10/2026. Estado: **código escrito, ainda não compilado nem executado.**

## O que foi (e o que não foi) verificado

| Item | Estado |
|---|---|
| Código-fonte completo | Escrito |
| Compilação do APK | **Não feita.** O ambiente onde o código foi escrito não consegue baixar o Android SDK nem as dependências Maven (acesso bloqueado). Só o GitHub Actions compilará. |
| Testes automatizados JVM (`app/src/test`, 5 arquivos, 35 casos) | **Escritos, não executados.** Os resultados virão da primeira execução do workflow. |
| Testes em emulador/tablet | **Nenhum.** Gestos, desenho, câmera, galeria e exportação ainda não foram vistos funcionando. |
| Testes físicos com trena Bosch | **Nenhum.** |

Como o código nunca passou por um compilador, **a primeira execução do CI provavelmente apontará erros de compilação** (imports, nomes de ícones, tipos). Eles são esperados e corrigíveis; o log do Actions mostra cada um.

## Bluetooth Bosch: o que NÃO está confirmado

- Os UUIDs do serviço/característica e o comando de "autosync" (`C0 55 02 01 00 1A`) vêm de engenharia reversa da comunidade, **não de documentação da Bosch**.
- O decodificador de medida é uma heurística (procura um float32 little-endian plausível, em metros, num quadro que começa com `C0`). **O formato real pode ser diferente.**
- Por isso o app mostra um aviso de "protocolo não validado", exibe o quadro bruto em hexadecimal (Trena → Diagnóstico) e grava o hexadecimal de cada leitura no histórico da cota.
- **Compatibilidade com qualquer modelo e precisão metrológica: não declaradas.** Só passam a valer depois de teste com a trena real (comparar o valor do app com o visor, em várias distâncias).
- Se o formato for outro, só `ble/BoschProtocol.kt` precisa mudar. Com 3 ou 4 linhas do diagnóstico (hex + valor do visor) é possível ajustar.
- O app não gera leituras falsas em nenhuma situação.

## Decisões e limitações conhecidas

- Apagar uma foto apaga as anotações e cotas vinculadas a ela (dá para desfazer). Duplicar uma foto duplica as anotações.
- Fotos movidas ficam com o centro dentro da folha (não somem para fora). O conteúdo é recortado nas bordas da folha, na tela e na exportação.
- Largura de traço de anotações não escala com a foto; só as posições escalam.
- Texto: uma caixa de linha única editável (sem formatação).
- Sem pressão de caneta nem botão da S Pen (usa só posição). "Desenhar só com S Pen" evita toque de palma.
- Cota mede só a distância em linha reta entre dois pontos; sem cálculo de área.
- Apenas tema claro. Apenas português.
- Build debug (assinatura de depuração): instalável, mas não é um APK de loja.
- O inventário de referências está pendente (ver `INVENTARIO.md`).

## Próximos passos

1. Subir o projeto no GitHub e rodar o workflow; corrigir o que o compilador apontar.
2. Instalar o APK no tablet e testar os gestos; ajustar o que não ficar natural.
3. Enviar capturas/vídeos do Star Note e do MeasureOn para alinhar a aparência.
4. Testar com a trena Bosch e validar/ajustar o decodificador.
