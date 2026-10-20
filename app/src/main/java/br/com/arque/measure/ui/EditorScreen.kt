package br.com.arque.measure.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowRightAlt
import androidx.compose.material.icons.automirrored.filled.Backspace
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Redo
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.BluetoothConnected
import androidx.compose.material.icons.filled.BluetoothDisabled
import androidx.compose.material.icons.filled.BluetoothSearching
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Create
import androidx.compose.material.icons.filled.CropSquare
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Highlight
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.NearMe
import androidx.compose.material.icons.filled.PanTool
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.RotateRight
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.PointerType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.ble.BleState
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.Paper
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.TextObj
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.max
import kotlin.math.roundToInt

private fun Tool.icon(): ImageVector = when (this) {
    Tool.NAVIGATE -> Icons.Filled.PanTool
    Tool.SELECT -> Icons.Filled.NearMe
    Tool.PEN -> Icons.Filled.Edit
    Tool.PENCIL -> Icons.Filled.Create
    Tool.HIGHLIGHTER -> Icons.Filled.Highlight
    Tool.ERASER -> Icons.AutoMirrored.Filled.Backspace
    Tool.LINE -> Icons.Filled.Remove
    Tool.ARROW -> Icons.AutoMirrored.Filled.ArrowRightAlt
    Tool.RECT -> Icons.Filled.CropSquare
    Tool.ELLIPSE -> Icons.Filled.RadioButtonUnchecked
    Tool.TEXT -> Icons.Filled.TextFields
    Tool.DIM -> Icons.Filled.Straighten
}

private val timeFmt = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

// ------------------------------------------------------------------ Canvas

@Composable
fun SheetCanvas(vm: AppViewModel, session: EditorSession, modifier: Modifier = Modifier) {
    val density = LocalDensity.current.density
    val renderer = remember { vm.renderer() }
    val controller = remember(session) { GestureController(session, density) }

    Canvas(
        modifier = modifier
            .onSizeChanged { session.onCanvasSize(it.width.toFloat(), it.height.toFloat()) }
            .pointerInput(session) {
                awaitEachGesture {
                    val down = awaitFirstDown(requireUnconsumed = false)
                    session.dimEditId = null
                    session.textEdit = null
                    controller.down(down.position, down.type == PointerType.Touch)
                    var multi = false
                    var last = down.position
                    do {
                        val ev = awaitPointerEvent()
                        val pressed = ev.changes.filter { it.pressed }
                        if (pressed.size >= 2) {
                            if (!multi) {
                                multi = true
                                controller.cancelSingle()
                                controller.pinchBegin(pressed[0].position, pressed[1].position)
                            }
                            controller.pinch(pressed[0].position, pressed[1].position)
                            ev.changes.forEach { it.consume() }
                        } else if (!multi && pressed.size == 1) {
                            val ch = pressed[0]
                            last = ch.position
                            if (ch.positionChanged()) {
                                controller.move(ch.position)
                                ch.consume()
                            }
                        }
                    } while (ev.changes.any { it.pressed })
                    if (multi) {
                        controller.pinchEnd()
                    } else {
                        when (val a = controller.up(last)) {
                            is GestureAction.EditDim -> session.dimEditId = a.id
                            is GestureAction.EditText -> session.textEdit = TextEdit(a.id, a.at)
                            null -> {}
                        }
                    }
                }
            },
    ) {
        // ler estes estados faz o canvas redesenhar quando algo muda
        @Suppress("UNUSED_VARIABLE")
        val trigger = session.rev + vm.images.version
        drawRect(Color(0xFFE9E7E1))
        drawIntoCanvas { c ->
            val nc = c.nativeCanvas
            nc.save()
            nc.translate(session.view.ox, session.view.oy)
            nc.scale(session.view.scale, session.view.scale)
            renderer.draw(nc, session.state.sheet, session.state.selectedId, session.view.scale)
            nc.restore()
        }
    }
}

// ------------------------------------------------------------------ Editor

@Composable
fun EditorScreen(vm: AppViewModel, session: EditorSession) {
    @Suppress("UNUSED_VARIABLE")
    val rev = session.rev
    val st = session.state
    val sheet = st.sheet
    val selected = st.selected
    val client = vm.clientOfRoom(sheet.roomId)
    val bleState by vm.ble.state.collectAsStateWithLifecycle()
    val bleName by vm.ble.deviceName.collectAsStateWithLifecycle()

    var btOpen by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }
    var paperOpen by remember { mutableStateOf(false) }
    var historyFor by remember { mutableStateOf<String?>(null) }

    val pickPhotos = rememberLauncherForActivityResult(ActivityResultContracts.GetMultipleContents()) { uris ->
        uris.forEach { vm.addPhotoFromUri(it) }
    }
    val camera = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok -> vm.onCameraResult(ok) }
    val pdfOut = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/pdf")) { it?.let(vm::exportPdf) }
    val pngOut = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("image/png")) { it?.let(vm::exportPng) }
    val csvOut = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("text/csv")) { it?.let(vm::exportCsv) }

    Box(Modifier.fillMaxSize()) {
        SheetCanvas(vm, session, Modifier.fillMaxSize())

        // ---- barra superior ----
        Surface(
            modifier = Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(8.dp),
            shape = RoundedCornerShape(28.dp),
            tonalElevation = 3.dp,
            shadowElevation = 6.dp,
        ) {
            Row(Modifier.padding(horizontal = 4.dp).horizontalScroll(rememberScrollState()), verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = { vm.closeEditor() }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar") }
                Column(Modifier.padding(horizontal = 4.dp).widthIn(max = 200.dp)) {
                    Text(sheet.name, style = MaterialTheme.typography.titleSmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    Text(
                        listOfNotNull(client?.name, vm.roomName(sheet.roomId).ifBlank { null }).joinToString(" • "),
                        style = MaterialTheme.typography.labelSmall, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    )
                }
                IconButton(onClick = { st.undo() }, enabled = st.canUndo) { Icon(Icons.AutoMirrored.Filled.Undo, "Desfazer") }
                IconButton(onClick = { st.redo() }, enabled = st.canRedo) { Icon(Icons.AutoMirrored.Filled.Redo, "Refazer") }
                TextButton(onClick = {
                    st.setUnit(
                        when (sheet.unit) {
                            LengthUnit.MM -> LengthUnit.CM
                            LengthUnit.CM -> LengthUnit.M
                            LengthUnit.M -> LengthUnit.MM
                        },
                    )
                }) { Text(sheet.unit.label) }
                val btIcon = when (bleState) {
                    BleState.CONNECTED -> Icons.Filled.BluetoothConnected
                    BleState.SCANNING, BleState.CONNECTING -> Icons.Filled.BluetoothSearching
                    BleState.OFF, BleState.UNAVAILABLE, BleState.NO_PERMISSION, BleState.ERROR -> Icons.Filled.BluetoothDisabled
                    BleState.IDLE -> Icons.Filled.Bluetooth
                }
                val btLabel = when (bleState) {
                    BleState.CONNECTED -> bleName ?: "Trena"
                    BleState.CONNECTING -> "Conectando…"
                    BleState.SCANNING -> "Procurando…"
                    else -> "Trena"
                }
                AssistChip(
                    onClick = { btOpen = true },
                    label = { Text(btLabel, maxLines = 1) },
                    leadingIcon = { Icon(btIcon, null, Modifier.size(18.dp)) },
                    modifier = Modifier.padding(horizontal = 4.dp),
                )
                Box {
                    IconButton(onClick = { menuOpen = true }) { Icon(Icons.Filled.MoreVert, "Mais opções") }
                    DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                        DropdownMenuItem(text = { Text("Exportar PDF") }, onClick = { menuOpen = false; pdfOut.launch("${sheet.name}.pdf") })
                        DropdownMenuItem(text = { Text("Exportar imagem (PNG)") }, onClick = { menuOpen = false; pngOut.launch("${sheet.name}.png") })
                        DropdownMenuItem(text = { Text("Exportar medidas (CSV)") }, onClick = { menuOpen = false; csvOut.launch("${sheet.name}-medidas.csv") })
                        HorizontalDivider()
                        DropdownMenuItem(text = { Text("Papel e orientação") }, onClick = { menuOpen = false; paperOpen = true })
                        DropdownMenuItem(text = { Text("Ajustar folha à tela") }, onClick = { menuOpen = false; session.fitToScreen() })
                        DropdownMenuItem(
                            text = { Text(if (session.stylusOnly) "Desenhar só com S Pen: ligado" else "Desenhar só com S Pen: desligado") },
                            onClick = { menuOpen = false; session.stylusOnly = !session.stylusOnly },
                        )
                    }
                }
            }
        }

        // ---- ferramentas (esquerda) ----
        Surface(
            modifier = Modifier.align(Alignment.CenterStart).padding(start = 8.dp, top = 76.dp, bottom = 76.dp),
            shape = RoundedCornerShape(24.dp),
            tonalElevation = 3.dp,
            shadowElevation = 6.dp,
        ) {
            Column(Modifier.verticalScroll(rememberScrollState()).padding(4.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Tool.entries.forEach { t ->
                    val on = session.tool == t
                    IconButton(
                        onClick = { session.chooseTool(t) },
                        colors = IconButtonDefaults.iconButtonColors(
                            containerColor = if (on) MaterialTheme.colorScheme.primaryContainer else Color.Transparent,
                            contentColor = if (on) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurface,
                        ),
                    ) { Icon(t.icon(), t.label) }
                }
                HorizontalDivider(Modifier.width(32.dp).padding(vertical = 4.dp))
                IconButton(onClick = { camera.launch(vm.newCameraUri()) }) { Icon(Icons.Filled.PhotoCamera, "Tirar foto") }
                IconButton(onClick = { pickPhotos.launch("image/*") }) { Icon(Icons.Filled.PhotoLibrary, "Foto da galeria") }
            }
        }

        // ---- navegação entre folhas (embaixo, esquerda) ----
        val siblings = vm.sheetsOfRoom(sheet.roomId)
        val pos = siblings.indexOfFirst { it.id == sheet.id }
        Surface(
            modifier = Modifier.align(Alignment.BottomStart).navigationBarsPadding().padding(8.dp),
            shape = RoundedCornerShape(24.dp), tonalElevation = 3.dp, shadowElevation = 6.dp,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = { vm.openRelative(-1) }, enabled = pos > 0) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Folha anterior") }
                Text("${pos + 1}/${siblings.size}", style = MaterialTheme.typography.labelLarge)
                IconButton(onClick = { vm.openRelative(1) }, enabled = pos in 0 until siblings.size - 1) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, "Próxima folha") }
                IconButton(onClick = { vm.addSheetAfterCurrent() }) { Icon(Icons.Filled.Add, "Nova folha") }
            }
        }

        // ---- propriedades do objeto selecionado (embaixo, centro) ----
        if (selected != null) {
            PropertyBar(
                session = session,
                modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 8.dp, start = 150.dp, end = 150.dp),
                onHistory = { historyFor = it },
            )
        }

        // ---- leituras recentes (embaixo, direita) ----
        if (vm.recent.isNotEmpty()) {
            RecentPanel(vm, Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(8.dp))
        }

        // ---- campos flutuantes ----
        session.dimEditId?.let { id ->
            val dim = sheet.obj(id) as? DimObj
            if (dim != null) {
                val pts = Geo.annPoints(sheet.photos(), dim)
                val at = session.view.toScreen(Geo.dimLabelCenter(pts[0], pts[1]))
                FloatingField(
                    initial = dim.valueMm?.let { Units.formatNumber(it, sheet.unit) } ?: "",
                    suffix = sheet.unit.label,
                    keyboard = KeyboardType.Decimal,
                    width = 220.dp,
                    at = at, canvasW = session.canvasW, canvasH = session.canvasH,
                ) { text ->
                    val mm = Units.parseToMm(text, sheet.unit)
                    if (mm != null) {
                        st.setManual(id, mm)
                        session.dimEditId = null
                    } else {
                        vm.toast = "Medida inválida"
                    }
                }
            }
        }
        session.textEdit?.let { edit ->
            val existing = edit.id?.let { sheet.obj(it) as? TextObj }
            val at = if (existing != null) {
                session.view.toScreen(Geo.annPoints(sheet.photos(), existing)[0])
            } else {
                session.view.toScreen(edit.at)
            }
            FloatingField(
                initial = existing?.text ?: "",
                suffix = null,
                keyboard = KeyboardType.Text,
                width = 280.dp,
                at = at, canvasW = session.canvasW, canvasH = session.canvasH,
            ) { text -> session.commitText(edit, text) }
        }
    }

    if (btOpen) BluetoothDialog(vm) { btOpen = false }
    if (paperOpen) PaperDialog(sheet.paper, sheet.landscape, { paperOpen = false }) { p, l ->
        paperOpen = false
        st.setPaper(p, l)
        session.fitToScreen()
    }
    historyFor?.let { id ->
        val dim = sheet.obj(id) as? DimObj
        if (dim != null) HistoryDialog(dim, sheet.unit) { historyFor = null }
    }
}

// ------------------------------------------------------------------ Propriedades

@Composable
private fun PropertyBar(session: EditorSession, modifier: Modifier, onHistory: (String) -> Unit) {
    val st = session.state
    val o = st.selected ?: return
    val editable = !o.locked
    Surface(modifier = modifier, shape = RoundedCornerShape(24.dp), tonalElevation = 3.dp, shadowElevation = 6.dp) {
        Row(
            Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp, vertical = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            if (o is DimObj) {
                Text(
                    if (o.valueMm == null) "Aguardando medida…" else "Meça de novo para substituir",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.secondary,
                    modifier = Modifier.padding(horizontal = 8.dp),
                )
            }
            if (o !is PhotoObj) {
                PALETTE.forEach { c ->
                    val cur = when (o) {
                        is StrokeObj -> o.color
                        is ShapeObj -> o.color
                        is DimObj -> o.color
                        is TextObj -> o.color
                        else -> 0
                    }
                    Box(
                        Modifier.padding(4.dp).size(26.dp).clip(CircleShape).background(Color(c))
                            .border(if (cur == c) 3.dp else 1.dp, if (cur == c) MaterialTheme.colorScheme.primary else Color.LightGray, CircleShape)
                            .clickable(enabled = editable) { st.setStyle(o.id, color = c); session.color = c },
                    )
                }
                val w = when (o) {
                    is StrokeObj -> o.width
                    is ShapeObj -> o.width
                    is DimObj -> o.width
                    is TextObj -> o.size / 6f
                    else -> 0f
                }
                IconButton(onClick = { st.setStyle(o.id, width = (w - 1f).coerceAtLeast(1f)) }, enabled = editable) { Icon(Icons.Filled.Remove, "Mais fino") }
                Text("${w.roundToInt()}", style = MaterialTheme.typography.labelLarge)
                IconButton(onClick = { st.setStyle(o.id, width = (w + 1f).coerceAtMost(40f)) }, enabled = editable) { Icon(Icons.Filled.Add, "Mais grosso") }
            } else {
                IconButton(onClick = { st.rotatePhoto90(o.id) }, enabled = editable) { Icon(Icons.Filled.RotateRight, "Girar 90°") }
            }
            if (o is DimObj) {
                IconButton(onClick = { onHistory(o.id) }) { Icon(Icons.Filled.History, "Histórico de leituras") }
                TextButton(onClick = { st.clearValue(o.id) }, enabled = editable && o.valueMm != null) { Text("Limpar") }
            }
            IconButton(onClick = { st.setLocked(o.id, !o.locked) }) {
                Icon(if (o.locked) Icons.Filled.Lock else Icons.Filled.LockOpen, if (o.locked) "Destravar" else "Travar")
            }
            IconButton(onClick = { st.duplicate(o.id) }) { Icon(Icons.Filled.ContentCopy, "Duplicar") }
            IconButton(onClick = { st.reorder(o.id, up = true) }) { Icon(Icons.Filled.ArrowUpward, "Trazer para frente") }
            IconButton(onClick = { st.reorder(o.id, up = false) }) { Icon(Icons.Filled.ArrowDownward, "Enviar para trás") }
            IconButton(onClick = { st.delete(o.id) }, enabled = editable) { Icon(Icons.Filled.Delete, "Apagar") }
        }
    }
}

// ------------------------------------------------------------------ Leituras recentes

@Composable
private fun RecentPanel(vm: AppViewModel, modifier: Modifier) {
    val unit = vm.session?.state?.sheet?.unit ?: LengthUnit.MM
    Surface(modifier = modifier.widthIn(max = 260.dp), shape = RoundedCornerShape(20.dp), tonalElevation = 3.dp, shadowElevation = 6.dp) {
        Column(Modifier.padding(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Leituras da trena", style = MaterialTheme.typography.labelLarge, modifier = Modifier.weight(1f).padding(start = 4.dp))
                TextButton(onClick = { vm.clearRecent() }) { Text("Limpar") }
            }
            Text(
                "Selecione uma cota e toque numa leitura para aplicar.",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 4.dp, bottom = 4.dp),
            )
            Column(Modifier.heightIn(max = 180.dp).verticalScroll(rememberScrollState())) {
                vm.recent.forEach { r ->
                    Row(
                        Modifier.clickable { vm.applyRecent(r) }.padding(vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(Units.format(r.mm, unit), style = MaterialTheme.typography.titleSmall, modifier = Modifier.weight(1f).padding(start = 4.dp))
                        Text(timeFmt.format(Date(r.timeMs)), style = MaterialTheme.typography.labelSmall)
                        IconButton(onClick = { vm.discardRecent(r) }, modifier = Modifier.size(32.dp)) { Icon(Icons.Filled.Close, "Descartar", Modifier.size(16.dp)) }
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------ Campo flutuante (edição rápida)

@Composable
private fun FloatingField(
    initial: String,
    suffix: String?,
    keyboard: KeyboardType,
    width: Dp,
    at: Offset,
    canvasW: Float,
    canvasH: Float,
    onConfirm: (String) -> Unit,
) {
    val density = LocalDensity.current
    val wPx = with(density) { width.toPx() }
    val hPx = with(density) { 76.dp.toPx() }
    val x = (at.x - wPx / 2f).coerceIn(8f, max(8f, canvasW - wPx - 8f))
    val y = (at.y - hPx / 2f).coerceIn(8f, max(8f, canvasH - hPx - 8f))
    var tfv by remember { mutableStateOf(TextFieldValue(initial, TextRange(0, initial.length))) }
    val focus = remember { FocusRequester() }
    Surface(
        modifier = Modifier.offset { IntOffset(x.roundToInt(), y.roundToInt()) }.width(width),
        shape = RoundedCornerShape(14.dp), shadowElevation = 10.dp, tonalElevation = 3.dp,
    ) {
        Row(Modifier.padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
            OutlinedTextField(
                value = tfv,
                onValueChange = { tfv = it },
                singleLine = true,
                modifier = Modifier.weight(1f).focusRequester(focus),
                keyboardOptions = KeyboardOptions(keyboardType = keyboard, imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { onConfirm(tfv.text) }),
                suffix = { if (suffix != null) Text(suffix) },
            )
            IconButton(onClick = { onConfirm(tfv.text) }) { Icon(Icons.Filled.Check, "Confirmar") }
        }
    }
    LaunchedEffect(Unit) { focus.requestFocus() }
}

// ------------------------------------------------------------------ Diálogos

@Composable
private fun HistoryDialog(dim: DimObj, unit: LengthUnit, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Histórico da cota") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                if (dim.history.isEmpty()) Text("Nenhuma leitura ainda.")
                dim.history.asReversed().forEach { r ->
                    val origin = if (r.source == MeasureSource.BLUETOOTH) "Bluetooth" + (r.device?.let { " ($it)" } ?: "") else "Digitada"
                    Column(Modifier.padding(vertical = 4.dp)) {
                        Text(Units.format(r.mm, unit), style = MaterialTheme.typography.titleSmall)
                        Text("$origin • ${timeFmt.format(Date(r.timeMs))}", style = MaterialTheme.typography.labelSmall)
                        r.rawHex?.let { Text(it, style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                    }
                    HorizontalDivider()
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Fechar") } },
    )
}

@Composable
private fun PaperDialog(paper: Paper, landscape: Boolean, onDismiss: () -> Unit, onOk: (Paper, Boolean) -> Unit) {
    var p by remember { mutableStateOf(paper) }
    var l by remember { mutableStateOf(landscape) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Papel e orientação") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Paper.entries.forEach { x -> FilterChip(selected = p == x, onClick = { p = x }, label = { Text(x.label) }) }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(selected = !l, onClick = { l = false }, label = { Text("Retrato") })
                    FilterChip(selected = l, onClick = { l = true }, label = { Text("Paisagem") })
                }
                Text("As fotos e anotações mantêm suas posições.", style = MaterialTheme.typography.labelSmall)
            }
        },
        confirmButton = { TextButton(onClick = { onOk(p, l) }) { Text("Aplicar") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}

@Composable
private fun BluetoothDialog(vm: AppViewModel, onDismiss: () -> Unit) {
    val ble = vm.ble
    val state by ble.state.collectAsStateWithLifecycle()
    val message by ble.message.collectAsStateWithLifecycle()
    val found by ble.found.collectAsStateWithLifecycle()
    val name by ble.deviceName.collectAsStateWithLifecycle()
    val log by ble.log.collectAsStateWithLifecycle()

    val permLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { res ->
        if (res.values.all { it }) ble.startScan() else ble.checkAvailability()
    }
    fun search() {
        if (!ble.hasPermissions()) permLauncher.launch(ble.requiredPermissions()) else ble.startScan()
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Trena Bosch") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                val status = when (state) {
                    BleState.CONNECTED -> "Conectada${name?.let { ": $it" } ?: ""}"
                    BleState.CONNECTING -> "Conectando…"
                    BleState.SCANNING -> "Procurando trena…"
                    BleState.IDLE -> "Desconectada"
                    BleState.OFF -> "Bluetooth desligado"
                    BleState.NO_PERMISSION -> "Falta permissão de Bluetooth"
                    BleState.UNAVAILABLE -> "Bluetooth LE indisponível"
                    BleState.ERROR -> "Erro"
                }
                Text(status, style = MaterialTheme.typography.titleSmall)
                if (message.isNotBlank()) Text(message, style = MaterialTheme.typography.bodySmall)
                Text(
                    "Aviso: o protocolo Bluetooth ainda não foi validado com uma trena real. " +
                        "Confira cada valor recebido com o visor da trena.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = { search() }) { Text("Procurar") }
                    if (ble.lastAddress != null && state != BleState.CONNECTED) {
                        TextButton(onClick = {
                            if (ble.hasPermissions()) ble.reconnectLast() else permLauncher.launch(ble.requiredPermissions())
                        }) { Text("Última trena") }
                    }
                    if (state == BleState.CONNECTED || state == BleState.CONNECTING) {
                        TextButton(onClick = { ble.disconnect() }) { Text("Desconectar") }
                    }
                }
                found.forEach { d ->
                    Row(Modifier.clickable { ble.connect(d.address, d.name) }.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Bluetooth, null, Modifier.size(18.dp))
                        Text(d.name, Modifier.padding(start = 8.dp).weight(1f))
                        Text("${d.rssi} dBm", style = MaterialTheme.typography.labelSmall)
                    }
                }
                if (log.isNotEmpty()) {
                    HorizontalDivider()
                    Text("Diagnóstico: últimos quadros recebidos", style = MaterialTheme.typography.labelMedium)
                    log.forEach { Text(it, style = MaterialTheme.typography.labelSmall, fontFamily = FontFamily.Monospace, fontSize = 11.sp) }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Fechar") } },
    )
}
