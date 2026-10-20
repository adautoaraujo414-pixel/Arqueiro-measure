package br.com.arque.measure.ui

import android.graphics.Path as APath
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
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
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
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.BluetoothConnected
import androidx.compose.material.icons.filled.ChangeHistory
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.CropSquare
import androidx.compose.material.icons.filled.Create
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.FitScreen
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.NearMe
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.RoundedCorner
import androidx.compose.material.icons.filled.ShapeLine
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
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
import androidx.compose.ui.graphics.Brush
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
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.Screen
import br.com.arque.measure.ble.BleState
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.Template
import br.com.arque.measure.model.TextObj
import java.util.Locale
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

private fun Tool.icon(): ImageVector = when (this) {
    Tool.NAVIGATE -> Icons.Filled.NearMe
    Tool.SELECT -> Icons.Filled.NearMe
    Tool.PEN -> Icons.Filled.Edit
    Tool.PENCIL -> Icons.Filled.Create
    Tool.HIGHLIGHTER -> Icons.Filled.Edit
    Tool.ERASER -> Icons.AutoMirrored.Filled.Backspace
    Tool.LINE -> Icons.Filled.Remove
    Tool.DASHED -> Icons.Filled.ShapeLine
    Tool.ARROW -> Icons.AutoMirrored.Filled.ArrowRightAlt
    Tool.DIM -> Icons.Filled.Straighten
    Tool.RECT -> Icons.Filled.CropSquare
    Tool.RRECT -> Icons.Filled.RoundedCorner
    Tool.ELLIPSE -> Icons.Filled.RadioButtonUnchecked
    Tool.TRIANGLE -> Icons.Filled.ChangeHistory
    Tool.TEXT -> Icons.Filled.TextFields
}

private val shapeTools = listOf(Tool.LINE, Tool.DASHED, Tool.ARROW, Tool.DIM, Tool.RECT, Tool.RRECT, Tool.ELLIPSE, Tool.TRIANGLE)

private fun mmText(units: Float): String = String.format(Locale("pt", "BR"), "%.2f mm", units * MM_PER_UNIT)

private fun nextUnit(u: LengthUnit) = when (u) {
    LengthUnit.M -> LengthUnit.MM
    LengthUnit.MM -> LengthUnit.CM
    LengthUnit.CM -> LengthUnit.M
}

// ------------------------------------------------------------------ Cena (todas as folhas)

private fun drawScene(
    nc: android.graphics.Canvas,
    session: EditorSession,
    renderer: SheetRenderer,
    scale: Float,
    selected: Boolean,
) {
    val st = session.state
    val step = Sheet.H + Sheet.GAP
    st.note.pages.forEachIndexed { i, page ->
        nc.save()
        nc.translate(0f, i * step)
        renderer.draw(nc, page, st.unit, if (selected && i == st.pageIdx) st.selectedId else null, scale)
        nc.restore()
    }
}

@Composable
fun SheetCanvas(vm: AppViewModel, session: EditorSession, modifier: Modifier = Modifier) {
    val density = LocalDensity.current.density
    session.density = density
    val renderer = remember { vm.renderer() }
    val controller = remember(session) { GestureController(session, density) }
    val loupePath = remember { APath() }

    Canvas(
        modifier = modifier
            .onSizeChanged { session.onCanvasSize(it.width.toFloat(), it.height.toFloat()) }
            .pointerInput(session) {
                awaitEachGesture {
                    val down = awaitFirstDown(requireUnconsumed = false)
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
                        session.settle()
                    } else {
                        when (val a = controller.up(last)) {
                            is GestureAction.TapDim -> vm.onDimTap(a.id)
                            is GestureAction.EditText -> session.textEdit = TextEdit(a.id, a.at)
                            null -> {}
                        }
                    }
                }
            },
    ) {
        @Suppress("UNUSED_VARIABLE")
        val trigger = session.rev + vm.images.version
        drawRect(Ui.paperBg)
        val v = session.view
        drawIntoCanvas { c ->
            val nc = c.nativeCanvas
            nc.save()
            nc.translate(v.ox, v.oy)
            nc.scale(v.scale, v.scale)
            drawScene(nc, session, renderer, v.scale, selected = true)
            nc.restore()

            // lupa circular com mira, ≈124 dp, zoom 3,4×
            val f = session.loupe
            if (f != null) {
                val size = 124f * density
                val r = size / 2f
                val margin = 12f * density
                val left = f.x > session.canvasW * 0.55f && f.y < 300f * density
                val lcx = if (left) margin + r else session.canvasW - margin - r
                val lcy = 150f * density + r
                val fw = v.toWorld(f)
                nc.save()
                loupePath.reset()
                loupePath.addCircle(lcx, lcy, r, APath.Direction.CW)
                nc.clipPath(loupePath)
                nc.drawColor(0xFFFFFFFF.toInt())
                nc.translate(lcx, lcy)
                nc.scale(v.scale * 3.4f, v.scale * 3.4f)
                nc.translate(-fw.x, -fw.y)
                drawScene(nc, session, renderer, v.scale * 3.4f, selected = false)
                nc.restore()
                val p = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
                p.style = android.graphics.Paint.Style.STROKE
                p.color = 0xFF222222.toInt(); p.strokeWidth = 1f * density
                nc.drawLine(lcx - r * 0.35f, lcy, lcx + r * 0.35f, lcy, p)
                nc.drawLine(lcx, lcy - r * 0.35f, lcx, lcy + r * 0.35f, p)
                p.color = 0xFFFFFFFF.toInt(); p.strokeWidth = 3f * density
                nc.drawCircle(lcx, lcy, r, p)
                p.color = 0x66000000; p.strokeWidth = 1f * density
                nc.drawCircle(lcx, lcy, r + 1.5f * density, p)
            }
        }
    }
}

// ------------------------------------------------------------------ Editor

@Composable
fun EditorScreen(vm: AppViewModel, session: EditorSession) {
    @Suppress("UNUSED_VARIABLE")
    val rev = session.rev
    val st = session.state
    val note = st.note
    val selected = st.selected
    val bleState by vm.ble.state.collectAsStateWithLifecycle()
    val density = LocalDensity.current

    var btOpen by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }
    var pageMenu by remember { mutableStateOf(false) }
    var shapesMenu by remember { mutableStateOf(false) }
    var imageMenu by remember { mutableStateOf(false) }
    var overview by remember { mutableStateOf(false) }
    var tpl by remember { mutableStateOf(Template.ARAUJO) }
    var miniOpen by remember { mutableStateOf(true) }

    val pickPhotos = rememberLauncherForActivityResult(ActivityResultContracts.GetMultipleContents()) { uris ->
        if (uris.isEmpty()) vm.photoToNewPage = false
        uris.forEach { vm.addPhotoFromUri(it) }
    }
    val camera = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok -> vm.onCameraResult(ok) }
    val pdfOut = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/pdf")) { it?.let(vm::exportPdf) }
    val pngOut = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("image/png")) { it?.let(vm::exportPng) }
    val csvOut = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("text/csv")) { it?.let(vm::exportCsv) }

    LaunchedEffect(vm.pendingImport, vm.screen) {
        if (vm.screen == Screen.Editor) {
            when (vm.pendingImport) {
                "gallery" -> { vm.pendingImport = null; pickPhotos.launch("image/*") }
                "camera" -> { vm.pendingImport = null; camera.launch(vm.newCameraUri()) }
            }
        }
    }

    fun addPage(pos: Int) {
        pageMenu = false
        if (st.addPage(pos, tpl)) session.goToPage(st.pageIdx) else vm.toast = "Limite de ${Sheet.MAX_PAGES} folhas"
    }

    Box(Modifier.fillMaxSize()) {
        SheetCanvas(vm, session, Modifier.fillMaxSize())

        // dica de puxar para criar folha
        if (session.pull > 20f) {
            val ready = session.pull >= 80f * density.density
            Text(
                if (ready) "Solte para adicionar uma folha" else "Continue a deslizar para adicionar uma folha",
                color = Color.White, fontSize = 13.sp,
                modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 24.dp)
                    .clip(RoundedCornerShape(16.dp)).background(Color(0xCC000000)).padding(horizontal = 14.dp, vertical = 8.dp),
            )
        }

        if (session.fullscreen) {
            IconButton(
                onClick = { session.fullscreen = false },
                modifier = Modifier.align(Alignment.TopEnd).statusBarsPadding().padding(8.dp).clip(CircleShape).background(Color(0x99000000)),
            ) { Icon(Icons.Filled.Close, "Sair da tela cheia", tint = Color.White) }
        } else {
            Column(Modifier.align(Alignment.TopCenter).statusBarsPadding().fillMaxWidth().background(Ui.panel)) {
                // ---- abas das notas abertas ----
                Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 6.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    vm.tabs.forEach { id ->
                        val on = id == note.id
                        Row(
                            Modifier.clip(RoundedCornerShape(10.dp)).background(if (on) Ui.panel2 else Color.Transparent)
                                .clickable { if (!on) { vm.flush(); vm.openNote(id) } }.padding(start = 12.dp, end = 4.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(if (on) note.name else vm.tabName(id), color = if (on) Ui.text else Ui.dim, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.widthIn(max = 140.dp))
                            IconButton(onClick = { vm.closeTab(id) }, modifier = Modifier.size(28.dp)) { Icon(Icons.Filled.Close, "Fechar aba", tint = Ui.dim, modifier = Modifier.size(14.dp)) }
                        }
                    }
                }
                // ---- linha 1 ----
                Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = { vm.closeEditor() }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar", tint = Ui.text) }
                    IconButton(onClick = { vm.photoToNewPage = false; camera.launch(vm.newCameraUri()) }) { Icon(Icons.Filled.PhotoCamera, "Câmera", tint = Ui.text) }
                    IconButton(onClick = { st.undo() }, enabled = st.canUndo) { Icon(Icons.AutoMirrored.Filled.Undo, "Desfazer", tint = if (st.canUndo) Ui.text else Ui.line) }
                    IconButton(onClick = { st.redo() }, enabled = st.canRedo) { Icon(Icons.AutoMirrored.Filled.Redo, "Refazer", tint = if (st.canRedo) Ui.text else Ui.line) }
                    val vp = session.visiblePage()
                    IconButton(onClick = { session.goToPage(vp - 1) }, enabled = vp > 0) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Folha anterior", tint = Ui.text) }
                    Text("${vp + 1}/${note.pages.size}", color = Ui.text, fontSize = 14.sp, modifier = Modifier.clickable { overview = true }.padding(4.dp))
                    IconButton(onClick = { session.goToPage(vp + 1) }, enabled = vp < note.pages.lastIndex) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, "Próxima folha", tint = Ui.text) }
                    Box {
                        TextButton(onClick = { pageMenu = true }) { Icon(Icons.Filled.Add, null, Modifier.size(16.dp)); Text(" Folha") }
                        DropdownMenu(expanded = pageMenu, onDismissRequest = { pageMenu = false }) {
                            DropdownMenuItem(text = { Text("Antes da folha atual") }, onClick = { addPage(st.pageIdx) })
                            DropdownMenuItem(text = { Text("Após a folha atual") }, onClick = { addPage(st.pageIdx + 1) })
                            DropdownMenuItem(text = { Text("Última página") }, onClick = { addPage(note.pages.size) })
                            HorizontalDivider()
                            Template.entries.forEach { t ->
                                DropdownMenuItem(
                                    text = { Text((if (tpl == t) "● " else "○ ") + t.label) },
                                    onClick = { tpl = t },
                                )
                            }
                            HorizontalDivider()
                            DropdownMenuItem(text = { Text("Adicionar outras páginas de nota (em breve)") }, enabled = false, onClick = {})
                            DropdownMenuItem(text = { Text("Importar ficheiros (em breve)") }, enabled = false, onClick = {})
                            DropdownMenuItem(text = { Text("Importar imagem") }, onClick = { pageMenu = false; vm.photoToNewPage = true; pickPhotos.launch("image/*") })
                            DropdownMenuItem(text = { Text("Tirar fotografia") }, onClick = { pageMenu = false; vm.photoToNewPage = true; camera.launch(vm.newCameraUri()) })
                        }
                    }
                    TextButton(onClick = { st.setUnit(nextUnit(note.unit)) }) { Text(note.unit.label, color = Ui.text) }
                    val connected = bleState == BleState.CONNECTED
                    TextButton(onClick = { btOpen = true }) {
                        Icon(if (connected) Icons.Filled.BluetoothConnected else Icons.Filled.Bluetooth, null, Modifier.size(18.dp), tint = if (connected) Ui.accent else Ui.text)
                        Text(if (connected) " Bosch conectada" else " Conectar trena", color = if (connected) Ui.accent else Ui.text)
                    }
                    Box {
                        IconButton(onClick = { menuOpen = true }) { Icon(Icons.Filled.MoreVert, "Mais opções", tint = Ui.text) }
                        DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                            DropdownMenuItem(text = { Text("Zoom em tela cheia") }, onClick = { menuOpen = false; session.fullscreen = true })
                            DropdownMenuItem(text = { Text("Visão geral da nota") }, onClick = { menuOpen = false; overview = true })
                            DropdownMenuItem(
                                text = { Text(if (note.locked) "Remover bloqueio" else "Adicionar bloqueio") },
                                onClick = { menuOpen = false; st.setNoteLocked(!note.locked); vm.toast = if (!note.locked) "Nota bloqueada: abrirá só após remover o bloqueio" else "Bloqueio removido" },
                            )
                            HorizontalDivider()
                            DropdownMenuItem(text = { Text("Exportar PDF") }, onClick = { menuOpen = false; pdfOut.launch("${note.name}.pdf") })
                            DropdownMenuItem(text = { Text("Exportar folha (PNG)") }, onClick = { menuOpen = false; pngOut.launch("${note.name}.png") })
                            DropdownMenuItem(text = { Text("Exportar medidas (CSV)") }, onClick = { menuOpen = false; csvOut.launch("${note.name}-medidas.csv") })
                            HorizontalDivider()
                            DropdownMenuItem(
                                text = { Text(if (session.stylusOnly) "Desenhar só com S Pen: ligado" else "Desenhar só com S Pen: desligado") },
                                onClick = { menuOpen = false; session.stylusOnly = !session.stylusOnly },
                            )
                        }
                    }
                }
                HorizontalDivider(color = Ui.line)
                // ---- linha 2: ferramentas ----
                Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                    ToolBtn(Tool.PEN, session)
                    ToolBtn(Tool.PENCIL, session)
                    ToolBtn(Tool.ERASER, session)
                    ToolBtn(Tool.SELECT, session)
                    Box {
                        IconButton(onClick = { imageMenu = true }) { Icon(Icons.Filled.Image, "Imagem", tint = Ui.text) }
                        DropdownMenu(expanded = imageMenu, onDismissRequest = { imageMenu = false }) {
                            DropdownMenuItem(text = { Text("Álbum") }, onClick = { imageMenu = false; vm.photoToNewPage = false; pickPhotos.launch("image/*") })
                            DropdownMenuItem(text = { Text("Câmera") }, onClick = { imageMenu = false; vm.photoToNewPage = false; camera.launch(vm.newCameraUri()) })
                        }
                    }
                    ToolBtn(Tool.TEXT, session)
                    Box {
                        val inShapes = session.tool in shapeTools
                        IconButton(
                            onClick = { shapesMenu = true },
                            modifier = Modifier.clip(CircleShape).background(if (inShapes) Ui.accent.copy(alpha = 0.3f) else Color.Transparent),
                        ) { Icon(if (inShapes) session.tool.icon() else Icons.Filled.CropSquare, "Formas", tint = Ui.text) }
                        DropdownMenu(expanded = shapesMenu, onDismissRequest = { shapesMenu = false }) {
                            Column(Modifier.padding(horizontal = 12.dp).widthIn(min = 250.dp)) {
                                Row(Modifier.horizontalScroll(rememberScrollState())) {
                                    shapeTools.forEach { t ->
                                        IconButton(
                                            onClick = { session.chooseTool(t); shapesMenu = false },
                                            modifier = Modifier.clip(CircleShape).background(if (session.tool == t) Ui.accent.copy(alpha = 0.3f) else Color.Transparent),
                                        ) { Icon(t.icon(), t.label) }
                                    }
                                }
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text("Espessura", modifier = Modifier.weight(1f), fontSize = 13.sp)
                                    IconButton(onClick = { applyWidth(session, -0.1f) }) { Icon(Icons.Filled.Remove, "Mais fino") }
                                    Text(mmText(session.width), fontSize = 13.sp)
                                    IconButton(onClick = { applyWidth(session, 0.1f) }) { Icon(Icons.Filled.Add, "Mais grosso") }
                                }
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                    PALETTE.forEach { c -> ColorDot(c, session.color == c) { applyColor(session, c) } }
                                }
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Text("Preenchimento", modifier = Modifier.weight(1f), fontSize = 13.sp)
                                    Switch(checked = session.fill, onCheckedChange = { session.fill = it })
                                }
                            }
                        }
                    }
                    Spacer(Modifier.width(8.dp))
                    PALETTE.forEach { c -> ColorDot(c, session.color == c) { applyColor(session, c) }; Spacer(Modifier.width(6.dp)) }
                    Text(mmText(session.width), color = Ui.dim, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 8.dp))
                }
            }

            // ---- menu de contexto acima do objeto selecionado ----
            if (selected != null && selected !is DimObj) {
                val ptsSheet = if (selected is PhotoObj) Geo.corners(selected)
                else Geo.annPoints(st.sheet.photos(), selected as br.com.arque.measure.model.Ann)
                if (ptsSheet.isNotEmpty()) {
                    val screenPts = ptsSheet.map { session.view.toScreen(it) }
                    val topY = screenPts.minOf { it.y }
                    val cx = screenPts.map { it.x }.average().toFloat()
                    val dx = with(density) { 160.dp.toPx() }
                    val minY = with(density) { 190.dp.toPx() }
                    val py = with(density) { 56.dp.toPx() }
                    ContextBar(
                        session = session,
                        modifier = Modifier.offset { IntOffset((cx - dx).roundToInt().coerceAtLeast(8), (topY - py).roundToInt().coerceAtLeast(minY.roundToInt())) },
                    )
                }
            }

            // ---- zoom ----
            Row(
                Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(10.dp).clip(RoundedCornerShape(20.dp)).background(Color(0xCC000000)),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("${session.zoomPercent}%", color = Color.White, fontSize = 12.sp, modifier = Modifier.padding(start = 12.dp))
                IconButton(onClick = { session.fitButton() }, modifier = Modifier.size(36.dp)) { Icon(Icons.Filled.FitScreen, "Ajustar à largura", tint = Color.White, modifier = Modifier.size(18.dp)) }
            }

            // ---- painel inferior: Distância, Telémetro, leituras ----
            Column(
                Modifier.align(Alignment.BottomStart).navigationBarsPadding().padding(10.dp).widthIn(max = 440.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                (selected as? DimObj)?.let { DistancePanel(vm, session, it) }
                if (bleState == BleState.CONNECTED) MiniTelemeter(vm, miniOpen, { miniOpen = !miniOpen })
                ChipsBar(vm, bleState == BleState.CONNECTED) { btOpen = true }
            }
        }

        // ---- campo de texto flutuante ----
        session.textEdit?.let { edit ->
            val existing = edit.id?.let { st.sheet.obj(it) as? TextObj }
            val at = if (existing != null) {
                session.view.toScreen(Geo.annPoints(st.sheet.photos(), existing)[0])
            } else {
                session.view.toScreen(edit.at)
            }
            FloatingField(
                initial = existing?.text ?: "", width = 280.dp,
                at = at, canvasW = session.canvasW, canvasH = session.canvasH,
            ) { text -> session.commitText(edit, text) }
        }
    }

    if (btOpen) BluetoothScreen(vm) { btOpen = false }
    if (overview) OverviewDialog(session, vm, onDismiss = { overview = false })
}

private fun applyColor(session: EditorSession, c: Int) {
    session.color = c
    session.state.selected?.let { if (it !is PhotoObj) session.state.setStyle(it.id, color = c) }
}

private fun applyWidth(session: EditorSession, deltaMm: Float) {
    val w = (session.width + deltaMm * UNITS_PER_MM).coerceIn(0.1f * UNITS_PER_MM, 6f * UNITS_PER_MM)
    session.width = w
    session.state.selected?.let { if (it !is PhotoObj && it !is TextObj) session.state.setStyle(it.id, width = w) }
}

@Composable
private fun ToolBtn(t: Tool, session: EditorSession) {
    val on = session.tool == t
    IconButton(
        onClick = { session.chooseTool(t) },
        modifier = Modifier.clip(CircleShape).background(if (on) Ui.accent.copy(alpha = 0.3f) else Color.Transparent),
    ) { Icon(t.icon(), t.label, tint = if (on) Ui.accent else Ui.text) }
}

@Composable
private fun ColorDot(c: Int, on: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.size(24.dp).clip(CircleShape).background(Color(c))
            .border(if (on) 3.dp else 1.dp, if (on) Ui.accent else Color(0xFF777777), CircleShape).clickable(onClick = onClick),
    )
}

// ------------------------------------------------------------------ Menu de contexto da seleção

@Composable
private fun ContextBar(session: EditorSession, modifier: Modifier) {
    val st = session.state
    val o = st.selected ?: return
    Surface(modifier = modifier, shape = RoundedCornerShape(12.dp), color = Color(0xEE111111)) {
        Row(Modifier.padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            CtxBtn("Eliminar", !o.locked) { st.delete(o.id) }
            CtxBtn("Copiar") { st.duplicate(o.id) }
            if (o is PhotoObj) CtxBtn("Girar 90°", !o.locked) { st.rotatePhoto90(o.id) }
            CtxBtn(if (o.locked) "Desbloquear" else "Bloqueio") { st.setLocked(o.id, !o.locked) }
            CtxBtn("Para frente") { st.reorder(o.id, up = true) }
            CtxBtn("Para trás") { st.reorder(o.id, up = false) }
        }
    }
}

@Composable
private fun CtxBtn(label: String, enabled: Boolean = true, onClick: () -> Unit) {
    Text(
        label, color = if (enabled) Color.White else Color(0xFF777777), fontSize = 13.sp,
        modifier = Modifier.clickable(enabled = enabled, onClick = onClick).padding(horizontal = 10.dp, vertical = 10.dp),
    )
}

// ------------------------------------------------------------------ Distância (estilo Bosch, só leitura)

@Composable
private fun DistancePanel(vm: AppViewModel, session: EditorSession, d: DimObj) {
    val st = session.state
    val connected = vm.ble.state.collectAsStateWithLifecycle().value == BleState.CONNECTED
    val status = when {
        d.valueMm != null && connected -> "Meça de novo para substituir"
        d.valueMm != null -> "Medido pela trena Bosch"
        !connected -> "Conecte a trena Bosch (botão no topo)"
        else -> "Aguardando a medida da trena…"
    }
    Surface(shape = RoundedCornerShape(14.dp), color = Color.White) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Distância", color = Color(0xFF111111), fontSize = 16.sp)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier.weight(1f).clip(RoundedCornerShape(8.dp)).background(Color(0xFFE6EEFF)).padding(horizontal = 12.dp, vertical = 10.dp),
                ) {
                    Text(
                        d.valueMm?.let { Units.formatNumber(it, st.unit) } ?: "–",
                        color = Ui.distBlue, fontSize = 22.sp,
                    )
                }
                TextButton(onClick = { st.setUnit(nextUnit(st.unit)) }) { Text(st.unit.label, fontSize = 18.sp) }
            }
            Text(status, color = Color(0xFF555555), fontSize = 13.sp)
            HorizontalDivider(color = Color(0xFFDDDDDD))
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Cor", color = Color(0xFF111111), fontSize = 13.sp)
                PALETTE.forEach { c -> ColorDot(c, d.color == c) { applyColor(session, c) } }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Espessura da linha", color = Color(0xFF111111), fontSize = 13.sp, modifier = Modifier.weight(1f))
                IconButton(onClick = { applyWidth(session, -0.1f) }, modifier = Modifier.size(36.dp)) { Icon(Icons.Filled.Remove, "Mais fina", tint = Color(0xFF111111)) }
                Text(mmText(d.width), color = Color(0xFF111111), fontSize = 13.sp)
                IconButton(onClick = { applyWidth(session, 0.1f) }, modifier = Modifier.size(36.dp)) { Icon(Icons.Filled.Add, "Mais grossa", tint = Color(0xFF111111)) }
            }
            TextButton(onClick = { st.delete(d.id) }, enabled = !d.locked) { Text("Excluir", color = Color(0xFFD32F2F)) }
        }
    }
}

// ------------------------------------------------------------------ Telémetro e leituras

@Composable
private fun MiniTelemeter(vm: AppViewModel, open: Boolean, toggle: () -> Unit) {
    val name by vm.ble.deviceName.collectAsStateWithLifecycle()
    Surface(shape = RoundedCornerShape(14.dp), color = Ui.panel) {
        Column(Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Telémetro laser", color = Ui.text, fontSize = 14.sp, modifier = Modifier.weight(1f))
                Text(if (open) "Pronto ▾" else "Pronto ▸", color = Ui.accent, fontSize = 13.sp, modifier = Modifier.clickable(onClick = toggle))
            }
            if (open) {
                Text(name ?: "Bosch", color = Ui.dim, fontSize = 13.sp, modifier = Modifier.padding(top = 4.dp))
                TextButton(onClick = { vm.ble.disconnect() }) { Text("Desconectar") }
            }
        }
    }
}

@Composable
private fun ChipsBar(vm: AppViewModel, connected: Boolean, onBt: () -> Unit) {
    if (!connected && vm.recent.isEmpty()) return
    val unit = vm.session?.state?.unit ?: LengthUnit.M
    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(44.dp).clip(CircleShape).background(Ui.distBlue).clickable(onClick = onBt), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.Bluetooth, "Bluetooth", tint = Color.White)
        }
        vm.recent.forEach { r ->
            Row(
                Modifier.clip(RoundedCornerShape(22.dp)).background(Ui.panel2).clickable { vm.applyRecent(r) }.padding(start = 14.dp, end = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(Units.format(r.mm, unit), color = Ui.text, fontSize = 15.sp)
                IconButton(onClick = { vm.discardRecent(r) }, modifier = Modifier.size(32.dp)) { Icon(Icons.Filled.Close, "Descartar", tint = Ui.dim, modifier = Modifier.size(14.dp)) }
            }
        }
    }
}

// ------------------------------------------------------------------ Visão geral

@Composable
private fun OverviewDialog(session: EditorSession, vm: AppViewModel, onDismiss: () -> Unit) {
    val st = session.state
    val renderer = remember { vm.renderer() }
    var confirmDel by remember { mutableStateOf<Int?>(null) }
    var menuFor by remember { mutableStateOf<Int?>(null) }
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(Modifier.fillMaxSize(), color = Ui.bg) {
            Column(Modifier.statusBarsPadding().navigationBarsPadding()) {
                Row(Modifier.fillMaxWidth().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, "Fechar", tint = Ui.text) }
                    Text("Visão geral do documento", color = Ui.text, fontSize = 17.sp, modifier = Modifier.weight(1f))
                    Text("${st.note.pages.size} folhas", color = Ui.dim, fontSize = 13.sp, modifier = Modifier.padding(end = 12.dp))
                }
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(150.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    itemsIndexed(st.note.pages, key = { _, p -> p.id }) { i, page ->
                        Column {
                            Box(
                                Modifier.fillMaxWidth().clip(RoundedCornerShape(6.dp))
                                    .border(if (i == st.pageIdx) 2.dp else 1.dp, if (i == st.pageIdx) Ui.accent else Ui.line, RoundedCornerShape(6.dp))
                                    .clickable { onDismiss(); session.goToPage(i) },
                            ) {
                                val img = vm.images.version
                                Canvas(Modifier.fillMaxWidth().height(200.dp)) {
                                    @Suppress("UNUSED_VARIABLE") val t = img + session.rev
                                    drawIntoCanvas { c ->
                                        val nc = c.nativeCanvas
                                        val k = min(size.width / Sheet.W, size.height / Sheet.H)
                                        nc.save()
                                        nc.translate((size.width - Sheet.W * k) / 2f, 0f)
                                        nc.scale(k, k)
                                        renderer.draw(nc, page, st.unit, null, k, withPaper = false)
                                        nc.restore()
                                    }
                                }
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("${i + 1}", color = Ui.text, fontSize = 14.sp, modifier = Modifier.weight(1f).padding(start = 4.dp))
                                Box {
                                    IconButton(onClick = { menuFor = i; confirmDel = null }) { Icon(Icons.Filled.MoreVert, "Mais", tint = Ui.text) }
                                    DropdownMenu(expanded = menuFor == i, onDismissRequest = { menuFor = null; confirmDel = null }) {
                                        DropdownMenuItem(text = { Text("Duplicar folha") }, onClick = {
                                            menuFor = null
                                            if (!st.duplicatePage(i)) vm.toast = "Limite de ${Sheet.MAX_PAGES} folhas"
                                        })
                                        DropdownMenuItem(
                                            text = { Text(if (confirmDel == i) "Confirmar exclusão" else "Excluir folha", color = Color(0xFFE53935)) },
                                            enabled = st.note.pages.size > 1,
                                            onClick = {
                                                if (confirmDel == i) { menuFor = null; confirmDel = null; st.deletePage(i); session.updateActivePage(); session.clampView() }
                                                else confirmDel = i
                                            },
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// ------------------------------------------------------------------ Campo flutuante (texto)

@Composable
private fun FloatingField(
    initial: String,
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
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Text, imeAction = ImeAction.Done),
                keyboardActions = KeyboardActions(onDone = { onConfirm(tfv.text) }),
            )
            IconButton(onClick = { onConfirm(tfv.text) }) { Icon(Icons.Filled.Check, "Confirmar") }
        }
    }
    LaunchedEffect(Unit) { focus.requestFocus() }
}

// ------------------------------------------------------------------ Tela Bluetooth ("Ferramentas Bluetooth®")

@Composable
private fun BluetoothScreen(vm: AppViewModel, onDismiss: () -> Unit) {
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
    LaunchedEffect(Unit) { if (state != BleState.CONNECTED && state != BleState.CONNECTING) search() }

    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(Modifier.fillMaxSize(), color = Color.White) {
            Column(Modifier.statusBarsPadding().navigationBarsPadding().verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onDismiss) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar", tint = Color(0xFF111111)) }
                    Text("Ferramentas Bluetooth®", color = Color(0xFF111111), fontSize = 20.sp)
                }
                val ready = state == BleState.CONNECTED
                val status = when (state) {
                    BleState.CONNECTED -> "Pronto"
                    BleState.CONNECTING -> "Conectando…"
                    BleState.SCANNING -> "A pesquisar ferramentas."
                    BleState.IDLE -> "Pronto"
                    BleState.OFF -> "Bluetooth desligado"
                    BleState.NO_PERMISSION -> "Falta permissão de Bluetooth"
                    BleState.UNAVAILABLE -> "Bluetooth LE indisponível"
                    BleState.ERROR -> "Erro"
                }
                Text(status, color = Color(0xFF111111), fontSize = 16.sp)
                Box(
                    Modifier.fillMaxWidth().height(4.dp).clip(RoundedCornerShape(2.dp)).background(
                        Brush.horizontalGradient(listOf(Color(0xFFE53935), Color(0xFFF5B400), Color(0xFF2E9E57), Color(0xFF1E5BD8), Color(0xFF8E24AA))),
                    ),
                )
                if (message.isNotBlank()) Text(message, color = Color(0xFF555555), fontSize = 13.sp)
                Text(
                    "Aviso: o protocolo Bluetooth ainda não foi validado com uma trena real. Confira cada valor recebido com o visor da trena.",
                    color = Color(0xFFB3261E), fontSize = 13.sp,
                )
                if (ready) {
                    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(name ?: "Bosch", color = Color(0xFF111111), fontSize = 16.sp, modifier = Modifier.weight(1f))
                        TextButton(onClick = { ble.disconnect() }) { Text("Desconectar") }
                    }
                } else {
                    Text("Outras ferramentas", color = Color(0xFF555555), fontSize = 14.sp)
                    found.forEach { d ->
                        Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Bluetooth, null, tint = Ui.distBlue, modifier = Modifier.size(20.dp))
                            Text(d.name, color = Color(0xFF111111), fontSize = 16.sp, modifier = Modifier.padding(start = 10.dp).weight(1f))
                            TextButton(onClick = { ble.connect(d.address, d.name) }) { Text("Conectar") }
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(onClick = { search() }) { Text("Procurar de novo") }
                        if (ble.lastAddress != null) {
                            TextButton(onClick = { if (ble.hasPermissions()) ble.reconnectLast() else permLauncher.launch(ble.requiredPermissions()) }) { Text("Última trena") }
                        }
                    }
                }
                if (log.isNotEmpty()) {
                    HorizontalDivider()
                    Text("Diagnóstico: últimos quadros recebidos", color = Color(0xFF555555), fontSize = 13.sp)
                    log.forEach { Text(it, color = Color(0xFF333333), fontFamily = FontFamily.Monospace, fontSize = 11.sp) }
                }
            }
        }
    }
}
