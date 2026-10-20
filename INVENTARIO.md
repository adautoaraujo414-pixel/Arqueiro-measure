# Inventário de funções

Formato pedido: referência visual → comportamento observado → implementação → teste.

**Status das referências:** nenhuma captura de tela ou vídeo do Star Note / Bosch MeasureOn foi fornecida até agora.
A coluna "Referência visual" está **pendente** em todas as linhas. O "comportamento" vem do texto do pedido
(e, para o MeasureOn, da descrição oficial do fabricante: Bluetooth, fotos com medidas sobrepostas, projetos e clientes).
Detalhes de aparência e gestos exatos **não foram inventados**: faltam as demonstrações (ver "Pendências de referência").

Legenda de teste: **J** = teste automatizado JVM (escrito; ainda não executado, ver RELATORIO.md) ·
**E** = precisa de emulador/tablet · **F** = precisa de equipamento físico.

## Caderno (Star Note)

| Função | Implementação | Teste |
|---|---|---|
| Folhas A4/A3/A5/Carta, retrato/paisagem | `Paper`, `Sheet.width/height` | J `folha mantem o tamanho do papel` |
| Páginas independentes e navegação | `NewSheetDialog`, barra `n/total` no editor | E |
| Adicionar foto (galeria, câmera) | `GetMultipleContents`, `TakePicture`+FileProvider | E |
| Foto em resolução original | `Store.importImage` (cópia byte a byte) | J `importar foto copia os bytes originais` |
| Mover foto livremente | `GestureController` modo MOVE | E |
| Redimensionar pelos cantos | `Geo.resizeFromCorner` | J `redimensionar pelo canto` |
| Redimensionar por pinça (só a foto) | `GestureController.pinch` | E |
| Zoom/pan da visualização | `ViewState`, modo PAN, pinça sem foto | E |
| Rotação (alça e dois dedos, encaixe a 90°) | `applyHandle` ROTATE, `pinch` | J `local para folha ... girado` · E |
| Duplicar / excluir / travar | `EditorState.duplicate/delete/setLocked` | J `apagar foto apaga ... duplicar` |
| Camadas | `EditorState.reorder` | J `camadas sobem e descem` |
| Seleção | modo SELECT, `Geo.hit` | J `teste de toque` |
| Caneta, lápis, marca-texto | `StrokeKind` | E |
| Borracha (remove traço/forma/texto tocado) | `GestureController.erase` | E |
| Linha, seta, retângulo, círculo | `ShapeKind` | E |
| Texto | `TextObj`, campo flutuante | E |
| Desfazer/refazer (gesto inteiro = 1 passo) | `EditorState` | J `desfazer e refazer`, `um gesto inteiro...` |
| Salvamento automático | `AppViewModel.scheduleSave`, `Store` | J `salvar e carregar folha` · E |
| S Pen: opção "desenhar só com S Pen" | `stylusOnly` | F |

## Medição (Bosch MeasureOn)

| Função | Implementação | Teste |
|---|---|---|
| Criar cota arrastando sobre a foto | ferramenta `DIM` | E |
| Cotas horizontal/vertical/diagonal, alinhamento automático perto do eixo | `Geo.snapAxis` | J `alinha na horizontal e vertical` |
| Arrastar extremidades | alças A/B | E |
| Valor no centro da cota | `SheetRenderer.drawDim` | E |
| mm / cm / m | `Units`, botão na barra superior | J `UnitsTest` |
| Edição rápida ao tocar no número | `GestureAction.EditDim` + `FloatingField` | J `edicao manual marca a origem` · E |
| Receber medida Bluetooth na cota selecionada | `EditorState.assignReading` | J `leitura vai para a cota selecionada` |
| Avançar para a próxima cota sem valor | `nextPendingAfter` | J `depois de medir seleciona a proxima` |
| Leituras sem cota selecionada ficam numa lista | `AppViewModel.recent`, `RecentPanel` | J `sem cota selecionada...` · E |
| Histórico de leituras da cota | `DimObj.history`, `HistoryDialog` | J `nova leitura substitui ... historico` |
| Cota acompanha a foto; valor não muda | coordenadas normalizadas da foto | J `cota vinculada acompanha ...` |
| Origem da medida (Bluetooth/digitada) | `MeasureSource` | J |
| Cor/espessura, duplicar, apagar cota | barra de propriedades | J `EditorStateTest` |
| Buscar/conectar/reconectar trena, estado | `BoschBle` | **F** |
| Decodificar quadro da trena | `BoschProtocol` | J (só o código) · **F** (formato real) |

## Organização e saída

| Função | Implementação | Teste |
|---|---|---|
| Cliente (nome, cidade, endereço opcional; telefone/obs. depois) | `Screens.kt` | E |
| Ambientes (Cozinha, Quarto, Sala, Banheiro, Área gourmet ou outro) | `NewRoomDialog` | E |
| Várias folhas por ambiente | `RoomScreen` | E |
| Recuperação após arquivo corrompido | `Store.readWithRecovery` (.bak) | J `recupera a folha pelo backup` |
| Backup ZIP e restauração (anti zip-slip, valida antes de apagar) | `Store.backupTo/restoreFrom` | J `backup e restauracao`, `restauracao rejeita zip malicioso` |
| Exportar PDF, PNG, CSV de medidas | `Export` | E |
| Compilação Android | GitHub Actions | CI |

## Pendências de referência (preciso ver para não inventar)

1. Star Note: barra de ferramentas (posição, ícones, submenus de espessura/cor), gesto exato de seleção múltipla, como aparece o bloqueio de objeto.
2. Star Note: tamanhos de folha oferecidos e como troca de página (deslizar? miniaturas?).
3. MeasureOn: aparência da seta de cota (pontas, posição do número) e como a trena é pareada na tela.
4. Qual modelo de trena Bosch será usado (GLM 50 C, GLM 100 C, outra).
