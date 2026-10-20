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
import androidx.compose.foundation.layout.heightIn
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
import androidx.compose.material.icons.filled.Home
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
    Tool.ROOM -> Icons.Filled.Home
    Tool.RECT -> Icons.Filled.CropSquare
    Tool.RRECT -> Icons.Filled.RoundedCorner
    Tool.ELLIPSE -> Icons.Filled.RadioButtonUnchecked
    Tool.TRIANGLE -> Icons.Filled.ChangeHistory
    Tool.TEXT -> Icons.Filled.TextFields
    else -> Icons.Filled.CropSquare
}

private val shapeTools = listOf(
    Tool.LINE, Tool.DASHED, Tool.ARROW, Tool.DARROW, Tool.CURVE,
    Tool.ELBOW, Tool.DIM, Tool.ROOM, Tool.RECT, Tool.RRECT,
    Tool.ELLIPSE, Tool.TRIANGLE, Tool.RTRI, Tool.DIAMOND, Tool.TRAP,
)

private fun mmText(units: Float): String = String.format(Locale("pt", "BR"), "%.2f mm", units * MM_PER_UNIT)

private fun nextUnit(u: LengthUnit) = when (u) {
    LengthUnit.M -> LengthUnit.MM
    LengthUnit.MM -> LengthUnit.CM
    LengthUnit.CM -> LengthUnit.M
}

// ------------------------------------------------------------------ Cena (todas as folhas)

private val overlayPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
    style = android.graphics.Paint.Style.STROKE
    color = 0xFF2F80ED.toInt()
}
private val overlayPath = android.graphics.Path()

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
        renderer.draw(nc, page, st.unit, if (selected && i == st.pageIdx) st.selectedId else null, scale, selectedSeg = st.selectedSeg)
        if (i == st.pageIdx) {
            overlayPaint.strokeWidth = 2f / scale
            overlayPaint.pathEffect = android.graphics.DashPathEffect(floatArrayOf(8f / scale, 6f / scale), 0f)
            for (o in st.groupObjs()) {
                val b = Geo.bounds(page, o)
                val pad = 4f / scale
                nc.drawRect(b.l - pad, b.t - pad, b.r + pad, b.b + pad, overlayPaint)
            }
            val lp = session.lasso
            if (lp.size > 1) {
                overlayPath.reset()
                overlayPath.moveTo(lp[0].x, lp[0].y)
                for (k in 1 until lp.size) overlayPath.lineTo(lp[k].x, lp[k].y)
                nc.drawPath(overlayPath, overlayPaint)
            }
            overlayPaint.pathEffect = null
        }
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
                            is GestureAction.TapSeg -> vm.onSegTap(a.id, a.seg)
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
            Surface(
                modifier = Modifier.align(Alignment.TopCenter).fillMaxWidth(),
                color = Ui.panel, shadowElevation = 6.dp,
                shape = RoundedCornerShape(bottomStart = 18.dp, bottomEnd = 18.dp),
            ) {
            Column(Modifier.statusBarsPadding().padding(bottom = 6.dp)) {
                // ---- abas (só aparecem com mais de uma nota aberta) ----
                if (vm.tabs.size > 1) {
                    Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
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
                }
                // ---- linha 1: nota · folhas · medida ----
                Row(
                    Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    BarPill {
                        BarIcon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar") { vm.closeEditor() }
                        BarIcon(Icons.AutoMirrored.Filled.Undo, "Desfazer", st.canUndo) { st.undo() }
                        BarIcon(Icons.AutoMirrored.Filled.Redo, "Refazer", st.canRedo) { st.redo() }
                    }
                    val vp = session.visiblePage()
                    BarPill {
                        BarIcon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Folha anterior", vp > 0) { session.goToPage(vp - 1) }
                        Text("${vp + 1}/${note.pages.size}", color = Ui.text, fontSize = 14.sp, modifier = Modifier.clickable { overview = true }.padding(horizontal = 2.dp, vertical = 8.dp))
                        BarIcon(Icons.AutoMirrored.Filled.KeyboardArrowRight, "Próxima folha", vp < note.pages.lastIndex) { session.goToPage(vp + 1) }
                        Box {
                            Row(
                                Modifier.clip(RoundedCornerShape(16.dp)).clickable { pageMenu = true }.padding(horizontal = 10.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Icon(Icons.Filled.Add, null, Modifier.size(16.dp), tint = Ui.accent)
                                Text(" Folha", color = Ui.accent, fontSize = 14.sp)
                            }
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
                    }
                    val connected = bleState == BleState.CONNECTED
                    BarPill {
                        Text(
                            note.unit.label, color = Ui.text, fontSize = 14.sp,
                            modifier = Modifier.clip(RoundedCornerShape(16.dp)).clickable { st.setUnit(nextUnit(note.unit)) }.padding(horizontal = 12.dp, vertical = 8.dp),
                        )
                        Row(
                            Modifier.clip(RoundedCornerShape(16.dp)).clickable { btOpen = true }.padding(horizontal = 10.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(if (connected) Icons.Filled.BluetoothConnected else Icons.Filled.Bluetooth, "Trena", Modifier.size(18.dp), tint = if (connected) Ui.accent else Ui.text)
                            Text(if (connected) " Bosch" else " Conectar", color = if (connected) Ui.accent else Ui.text, fontSize = 14.sp)
                        }
                    }
                    Box {
                        BarPill { BarIcon(Icons.Filled.MoreVert, "Mais opções") { menuOpen = true } }
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
                Spacer(Modifier.height(6.dp))
                // ---- linha 2: desenho · objetos · cor e espessura ----
                Row(
                    Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 8.dp),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    BarPill {
                        ToolBtn(Tool.PEN, session)
                        ToolBtn(Tool.PENCIL, session)
                        ToolBtn(Tool.ERASER, session)
                    }
                    BarPill {
                        ToolBtn(Tool.SELECT, session)
                        IconButton(
                            onClick = { session.chooseTool(Tool.LASSO) },
                            modifier = Modifier.size(40.dp).clip(CircleShape).background(if (session.tool == Tool.LASSO) Ui.accent.copy(alpha = 0.3f) else Color.Transparent),
                        ) { ShapeGlyph(Tool.LASSO, if (session.tool == Tool.LASSO) Ui.accent else Ui.text, 22.dp) }
                        Box {
                            BarIcon(Icons.Filled.Image, "Imagem") { imageMenu = true }
                            DropdownMenu(expanded = imageMenu, onDismissRequest = { imageMenu = false }) {
                                DropdownMenuItem(text = { Text("Álbum") }, leadingIcon = { Icon(Icons.Filled.Image, null) }, onClick = { imageMenu = false; vm.photoToNewPage = false; pickPhotos.launch("image/*") })
                                DropdownMenuItem(text = { Text("Câmera") }, leadingIcon = { Icon(Icons.Filled.PhotoCamera, null) }, onClick = { imageMenu = false; vm.photoToNewPage = false; camera.launch(vm.newCameraUri()) })
                            }
                        }
                        ToolBtn(Tool.TEXT, session)
                        Box {
                            val inShapes = session.tool in shapeTools
                            Box(Modifier.clip(CircleShape).background(if (inShapes) Ui.accent.copy(alpha = 0.3f) else Color.Transparent)) {
                                IconButton(onClick = { shapesMenu = true }, modifier = Modifier.size(40.dp)) {
                                    ShapeGlyph(if (inShapes) session.tool else Tool.RECT, if (inShapes) Ui.accent else Ui.text, 22.dp)
                                }
                            }
                            DropdownMenu(expanded = shapesMenu, onDismissRequest = { shapesMenu = false }) {
                                Column(Modifier.padding(horizontal = 12.dp).widthIn(min = 250.dp)) {
                                    shapeTools.chunked(5).forEach { rowTools ->
                                        Row {
                                            rowTools.forEach { t ->
                                                IconButton(
                                                    onClick = { session.chooseTool(t); shapesMenu = false },
                                                    modifier = Modifier.size(48.dp).clip(CircleShape).background(if (session.tool == t) Ui.accent.copy(alpha = 0.3f) else Color.Transparent),
                                                ) { ShapeGlyph(t, if (session.tool == t) Ui.accent else Ui.text, 24.dp) }
                                            }
                                        }
                                    }
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text("Espessura", modifier = Modifier.weight(1f), fontSize = 13.sp)
                                        IconButton(onClick = { applyWidth(session, -0.1f) }) { Icon(Icons.Filled.Remove, "Mais fino") }
                                        Text(mmText(session.width), fontSize = 13.sp)
                                        IconButton(onClick = { applyWidth(session, 0.1f) }) { Icon(Icons.Filled.Add, "Mais grosso") }
                                    }
                                    ColorRow(session.color) { applyColor(session, it) }
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text("Preenchimento", modifier = Modifier.weight(1f), fontSize = 13.sp)
                                        Switch(checked = session.fill, onCheckedChange = { session.fill = it })
                                    }
                                }
                            }
                        }
                    }
                    BarPill {
                        Box(Modifier.padding(start = 10.dp)) { ColorRow(session.color) { applyColor(session, it) } }
                        Text(mmText(session.width), color = Ui.dim, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 10.dp))
                    }
                }
            }
            }

            // ---- barra do grupo (laço) ----
            if (st.groupIds.isNotEmpty()) {
                val boxes = st.groupObjs().map { Geo.bounds(st.sheet, it) }
                if (boxes.isNotEmpty()) {
                    val tl = session.view.toScreen(br.com.arque.measure.model.Pt(boxes.minOf { it.l }, boxes.minOf { it.t }))
                    val br2 = session.view.toScreen(br.com.arque.measure.model.Pt(boxes.maxOf { it.r }, boxes.minOf { it.t }))
                    val cx = (tl.x + br2.x) / 2f
                    val dx = with(density) { 130.dp.toPx() }
                    val minY = with(density) { 190.dp.toPx() }
                    val py = with(density) { 56.dp.toPx() }
                    Surface(
                        modifier = Modifier.offset { IntOffset((cx - dx).roundToInt().coerceAtLeast(8), (tl.y - py).roundToInt().coerceAtLeast(minY.roundToInt())) },
                        shape = RoundedCornerShape(12.dp), color = Color(0xEE111111),
                    ) {
                        Row(Modifier.padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text("${st.groupIds.size} itens", color = Color(0xFFAAAAAA), fontSize = 12.sp, modifier = Modifier.padding(start = 10.dp))
                            CtxBtn("Eliminar") { st.deleteGroup() }
                            CtxBtn("Cortar") { session.copyGroup(cut = true) }
                            CtxBtn("Copiar") { session.copyGroup() }
                            CtxBtn("Duplicar") { st.pasteObjs(st.groupWithLinked()) }
                            CtxBtn("Colar", session.clipboard.isNotEmpty()) { session.paste() }
                        }
                    }
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
                (selected as? br.com.arque.measure.model.RoomObj)?.let { RoomPanel(vm, session, it) }
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

/** Ícone desenhado de cada forma (grade do painel de Formas). */
@Composable
private fun ShapeGlyph(t: Tool, tint: Color, size: androidx.compose.ui.unit.Dp) {
    Canvas(Modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height
        val sw = 2.2f * density
        val st = androidx.compose.ui.graphics.drawscope.Stroke(width = sw, cap = androidx.compose.ui.graphics.StrokeCap.Round, join = androidx.compose.ui.graphics.StrokeJoin.Round)
        fun P(x: Float, y: Float) = androidx.compose.ui.geometry.Offset(x * w, y * h)
        fun poly(p: List<androidx.compose.ui.geometry.Offset>, close: Boolean) {
            val path = androidx.compose.ui.graphics.Path()
            path.moveTo(p[0].x, p[0].y)
            for (i in 1 until p.size) path.lineTo(p[i].x, p[i].y)
            if (close) path.close()
            drawPath(path, tint, style = st)
        }
        fun head(tip: androidx.compose.ui.geometry.Offset, from: androidx.compose.ui.geometry.Offset) {
            val ang = Math.atan2((tip.y - from.y).toDouble(), (tip.x - from.x).toDouble())
            val s = 0.26f * w
            fun q(d: Double) = androidx.compose.ui.geometry.Offset(tip.x - s * Math.cos(ang + d).toFloat(), tip.y - s * Math.sin(ang + d).toFloat())
            poly(listOf(q(-0.45), tip, q(0.45)), false)
        }
        when (t) {
            Tool.LINE -> drawLine(tint, P(0.12f, 0.88f), P(0.88f, 0.12f), sw, androidx.compose.ui.graphics.StrokeCap.Round)
            Tool.DASHED -> drawLine(tint, P(0.12f, 0.88f), P(0.88f, 0.12f), sw, androidx.compose.ui.graphics.StrokeCap.Round, androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(5f * density, 4f * density)))
            Tool.ARROW -> { drawLine(tint, P(0.12f, 0.88f), P(0.88f, 0.12f), sw, androidx.compose.ui.graphics.StrokeCap.Round); head(P(0.88f, 0.12f), P(0.12f, 0.88f)) }
            Tool.DARROW -> { drawLine(tint, P(0.12f, 0.88f), P(0.88f, 0.12f), sw, androidx.compose.ui.graphics.StrokeCap.Round); head(P(0.88f, 0.12f), P(0.12f, 0.88f)); head(P(0.12f, 0.88f), P(0.88f, 0.12f)) }
            Tool.DIM -> { drawLine(tint, P(0.1f, 0.5f), P(0.9f, 0.5f), sw, androidx.compose.ui.graphics.StrokeCap.Round); head(P(0.9f, 0.5f), P(0.1f, 0.5f)); head(P(0.1f, 0.5f), P(0.9f, 0.5f)); drawLine(tint, P(0.1f, 0.25f), P(0.1f, 0.75f), sw); drawLine(tint, P(0.9f, 0.25f), P(0.9f, 0.75f), sw) }
            Tool.CURVE -> {
                val path = androidx.compose.ui.graphics.Path()
                path.moveTo(0.12f * w, 0.85f * h); path.quadraticBezierTo(0.15f * w, 0.1f * h, 0.88f * w, 0.15f * h)
                drawPath(path, tint, style = st)
            }
            Tool.ELBOW -> poly(listOf(P(0.12f, 0.85f), P(0.12f, 0.15f), P(0.88f, 0.15f)), false)
            Tool.LASSO -> {
                drawOval(tint, P(0.1f, 0.14f), androidx.compose.ui.geometry.Size(0.8f * w, 0.55f * h), style = androidx.compose.ui.graphics.drawscope.Stroke(width = sw, pathEffect = androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(4f * density, 3f * density))))
                drawLine(tint, P(0.4f, 0.69f), P(0.3f, 0.9f), sw, androidx.compose.ui.graphics.StrokeCap.Round)
            }
            Tool.ROOM -> poly(listOf(P(0.12f, 0.2f), P(0.6f, 0.2f), P(0.6f, 0.5f), P(0.88f, 0.5f), P(0.88f, 0.85f), P(0.12f, 0.85f)), true)
            Tool.RECT -> drawRect(tint, P(0.14f, 0.2f), androidx.compose.ui.geometry.Size(0.72f * w, 0.6f * h), style = st)
            Tool.RRECT -> drawRoundRect(tint, P(0.14f, 0.2f), androidx.compose.ui.geometry.Size(0.72f * w, 0.6f * h), androidx.compose.ui.geometry.CornerRadius(0.16f * w), style = st)
            Tool.ELLIPSE -> drawOval(tint, P(0.12f, 0.2f), androidx.compose.ui.geometry.Size(0.76f * w, 0.6f * h), style = st)
            Tool.TRIANGLE -> poly(listOf(P(0.5f, 0.14f), P(0.88f, 0.84f), P(0.12f, 0.84f)), true)
            Tool.RTRI -> poly(listOf(P(0.16f, 0.14f), P(0.86f, 0.84f), P(0.16f, 0.84f)), true)
            Tool.DIAMOND -> poly(listOf(P(0.5f, 0.1f), P(0.9f, 0.5f), P(0.5f, 0.9f), P(0.1f, 0.5f)), true)
            Tool.TRAP -> poly(listOf(P(0.3f, 0.2f), P(0.7f, 0.2f), P(0.9f, 0.8f), P(0.1f, 0.8f)), true)
            else -> drawRect(tint, P(0.14f, 0.2f), androidx.compose.ui.geometry.Size(0.72f * w, 0.6f * h), style = st)
        }
    }
}

/** Grupo de botões da barra, em cápsula. */
@Composable
private fun BarPill(content: @Composable () -> Unit) {
    Row(
        Modifier.clip(RoundedCornerShape(20.dp)).background(Ui.panel2).padding(horizontal = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) { content() }
}

@Composable
private fun BarIcon(icon: ImageVector, desc: String, enabled: Boolean = true, tint: Color = Ui.text, onClick: () -> Unit) {
    IconButton(onClick = onClick, enabled = enabled, modifier = Modifier.size(40.dp)) {
        Icon(icon, desc, tint = if (enabled) tint else Ui.line, modifier = Modifier.size(22.dp))
    }
}

@Composable
private fun ToolBtn(t: Tool, session: EditorSession) {
    val on = session.tool == t
    IconButton(
        onClick = { session.chooseTool(t) },
        modifier = Modifier.size(40.dp).clip(CircleShape).background(if (on) Ui.accent.copy(alpha = 0.3f) else Color.Transparent),
    ) { Icon(t.icon(), t.label, tint = if (on) Ui.accent else Ui.text, modifier = Modifier.size(22.dp)) }
}

@Composable
private fun ColorDot(c: Int, on: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.size(24.dp).clip(CircleShape).background(Color(c))
            .border(if (on) 3.dp else 1.dp, if (on) Ui.accent else Color(0xFF777777), CircleShape).clickable(onClick = onClick),
    )
}

@Composable
private fun ColorRow(current: Int, onPick: (Int) -> Unit) {
    var more by remember { mutableStateOf(false) }
    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
        PALETTE.forEach { c -> ColorDot(c, current == c) { onPick(c) } }
        if (current !in PALETTE) ColorDot(current, true) { more = true }
        Box(
            Modifier.size(24.dp).clip(CircleShape).clickable { more = true }.background(
                Brush.sweepGradient(listOf(Color.Red, Color.Yellow, Color.Green, Color.Cyan, Color.Blue, Color.Magenta, Color.Red)),
            ),
        )
    }
    if (more) {
        Dialog(onDismissRequest = { more = false }) {
            Surface(shape = RoundedCornerShape(16.dp), color = Ui.panel) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("Cores", color = Ui.text, fontSize = 16.sp)
                    EXTRA_COLORS.chunked(7).forEach { row ->
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            row.forEach { c -> Box(Modifier.size(32.dp)) { ColorDot(c, current == c) { onPick(c); more = false } } }
                        }
                    }
                    TextButton(onClick = { more = false }) { Text("Fechar") }
                }
            }
        }
    }
}

// ------------------------------------------------------------------ Menu de contexto da seleção

@Composable
private fun ContextBar(session: EditorSession, modifier: Modifier) {
    val st = session.state
    val o = st.selected ?: return
    Surface(modifier = modifier, shape = RoundedCornerShape(12.dp), color = Color(0xEE111111)) {
        Row(Modifier.padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            CtxBtn("Eliminar", !o.locked) { st.delete(o.id) }
            CtxBtn("Cortar", !o.locked) { session.copySelection(cut = true) }
            CtxBtn("Copiar") { session.copySelection() }
            CtxBtn("Colar", session.clipboard.isNotEmpty()) { session.paste() }
            CtxBtn("Duplicar") { st.duplicate(o.id) }
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

// ------------------------------------------------------------------ Cômodo

@Composable
private fun RoomPanel(vm: AppViewModel, session: EditorSession, r: br.com.arque.measure.model.RoomObj) {
    val st = session.state
    val connected = vm.ble.state.collectAsStateWithLifecycle().value == BleState.CONNECTED
    val k = st.selectedSeg
    val seg = r.segs.getOrNull(k)
    val kinds = br.com.arque.measure.model.SegKind.values()
    val dark = Color(0xFF111111)
    Surface(shape = RoundedCornerShape(14.dp), color = Color.White) {
        Column(
            Modifier.heightIn(max = 380.dp).verticalScroll(rememberScrollState()).padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    if (seg != null) "Cômodo · segmento ${k + 1} de ${r.segCount()}" else "Cômodo · toque num segmento",
                    color = dark, fontSize = 16.sp, modifier = Modifier.weight(1f),
                )
                TextButton(onClick = { st.stepSeg(-1) }) { Text("‹") }
                TextButton(onClick = { st.stepSeg(1) }) { Text("›") }
            }
            if (seg != null) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.horizontalScroll(rememberScrollState())) {
                    kinds.forEach { kd ->
                        val on = seg.kind == kd
                        val col = Color(roomSegColor(r, kd))
                        Box(
                            Modifier.clip(RoundedCornerShape(16.dp))
                                .background(if (on) col else Color(0xFFEFEFEF))
                                .clickable(enabled = !r.locked) { st.setSegKind(r.id, k, kd) }
                                .padding(horizontal = 14.dp, vertical = 8.dp),
                        ) { Text(kd.label, color = if (on) Color.White else dark, fontSize = 14.sp) }
                    }
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.weight(1f).clip(RoundedCornerShape(8.dp)).background(Color(0xFFE6EEFF)).padding(horizontal = 12.dp, vertical = 10.dp)) {
                        Text(seg.valueMm?.let { Units.formatNumber(it, st.unit) } ?: "–", color = Ui.distBlue, fontSize = 22.sp)
                    }
                    TextButton(onClick = { st.setUnit(nextUnit(st.unit)) }) { Text(st.unit.label, fontSize = 18.sp) }
                }
                Text(
                    when {
                        seg.valueMm != null && connected -> "Meça de novo para substituir"
                        seg.valueMm != null -> "Medido pela trena Bosch"
                        !connected -> "Conecte a trena Bosch (botão no topo)"
                        else -> "Aguardando a medida da trena…"
                    },
                    color = Color(0xFF555555), fontSize = 13.sp,
                )
                if (seg.valueMm != null) TextButton(onClick = { st.clearValue(r.id) }) { Text("Limpar medida") }
            }
            if (r.pts.size >= 3) {
                TextButton(onClick = { st.setRoomClosed(r.id, !r.closed) }) { Text(if (r.closed) "Abrir contorno" else "Fechar contorno") }
            }
            HorizontalDivider(color = Color(0xFFDDDDDD))
            LabelSlider("Quadradinho", r.labelScale, 0.1f, 3f, "${(r.labelScale * 100).roundToInt()}%", !r.locked, st) { v -> st.setRoomLabelScale(r.id, v, live = true) }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Cor da parede", color = dark, fontSize = 13.sp)
                ColorRow(r.color) { applyColor(session, it) }
            }
        }
    }
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
        Column(
            Modifier.heightIn(max = 380.dp).verticalScroll(rememberScrollState()).padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
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
                ColorRow(d.color) { applyColor(session, it) }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Espessura da linha", color = Color(0xFF111111), fontSize = 13.sp, modifier = Modifier.weight(1f))
                IconButton(onClick = { applyWidth(session, -0.1f) }, modifier = Modifier.size(36.dp)) { Icon(Icons.Filled.Remove, "Mais fina", tint = Color(0xFF111111)) }
                Text(mmText(d.width), color = Color(0xFF111111), fontSize = 13.sp)
                IconButton(onClick = { applyWidth(session, 0.1f) }, modifier = Modifier.size(36.dp)) { Icon(Icons.Filled.Add, "Mais grossa", tint = Color(0xFF111111)) }
            }
            HorizontalDivider(color = Color(0xFFDDDDDD))
            Text("Quadradinho da medida", color = Color(0xFF111111), fontSize = 14.sp)
            LabelSlider("Tamanho", d.labelScale, 0.1f, 3f, "${(d.labelScale * 100).roundToInt()}%", !d.locked, st) { v -> st.setDimLabel(d.id, scale = v, live = true) }
            LabelSlider("Opacidade", d.labelAlpha, 0.1f, 1f, "${(d.labelAlpha * 100).roundToInt()}%", !d.locked, st) { v -> st.setDimLabel(d.id, alpha = v, live = true) }
            LabelSlider("Intensidade da cor", d.labelIntensity, 0.15f, 1f, "${(d.labelIntensity * 100).roundToInt()}%", !d.locked, st) { v -> st.setDimLabel(d.id, intensity = v, live = true) }
            Text(
                "O quadradinho acompanha o tamanho da foto e da seta automaticamente.",
                color = Color(0xFF777777), fontSize = 11.sp,
            )
            Row {
                TextButton(onClick = { st.applyDimLabelToAll(d.id) }, enabled = !d.locked) { Text("Aplicar a todas as cotas") }
                Spacer(Modifier.weight(1f))
                TextButton(onClick = { st.delete(d.id) }, enabled = !d.locked) { Text("Excluir", color = Color(0xFFD32F2F)) }
            }
        }
    }
}

// ------------------------------------------------------------------ Telémetro e leituras

@Composable
private fun LabelSlider(
    label: String,
    value: Float,
    min: Float,
    max: Float,
    shown: String,
    enabled: Boolean,
    st: br.com.arque.measure.logic.EditorState,
    onChange: (Float) -> Unit,
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label, color = Color(0xFF111111), fontSize = 13.sp, modifier = Modifier.width(120.dp))
        androidx.compose.material3.Slider(
            value = value.coerceIn(min, max),
            onValueChange = { st.beginGesture(); onChange(it) },
            onValueChangeFinished = { st.endGesture() },
            valueRange = min..max,
            enabled = enabled,
            modifier = Modifier.weight(1f).height(32.dp),
        )
        Text(shown, color = Color(0xFF555555), fontSize = 12.sp, modifier = Modifier.width(44.dp))
    }
}

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
        Surface(Modifier.fillMaxSize(), color = Ui.bg) {
            Column(Modifier.statusBarsPadding().navigationBarsPadding().verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onDismiss) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar", tint = Ui.text) }
                    Text("Ferramentas Bluetooth®", color = Ui.text, fontSize = 20.sp)
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
                Text(status, color = Ui.text, fontSize = 16.sp)
                Box(
                    Modifier.fillMaxWidth().height(4.dp).clip(RoundedCornerShape(2.dp)).background(
                        Brush.horizontalGradient(listOf(Color(0xFFE53935), Color(0xFFF5B400), Color(0xFF2E9E57), Color(0xFF1E5BD8), Color(0xFF8E24AA))),
                    ),
                )
                if (message.isNotBlank()) Text(message, color = Ui.dim, fontSize = 13.sp)
                Text(
                    "Aviso: o protocolo Bluetooth ainda não foi validado com uma trena real. Confira cada valor recebido com o visor da trena.",
                    color = Color(0xFFFF8A80), fontSize = 13.sp,
                )
                if (ready) {
                    Row(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(name ?: "Bosch", color = Ui.text, fontSize = 16.sp, modifier = Modifier.weight(1f))
                        TextButton(onClick = { ble.disconnect() }) { Text("Desconectar") }
                    }
                } else {
                    Text("Outras ferramentas", color = Ui.dim, fontSize = 14.sp)
                    found.forEach { d ->
                        Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel).padding(horizontal = 12.dp, vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Bluetooth, null, tint = Ui.distBlue, modifier = Modifier.size(20.dp))
                            Text(d.name, color = Ui.text, fontSize = 16.sp, modifier = Modifier.padding(start = 10.dp).weight(1f))
                            TextButton(onClick = { ble.connect(d.address, d.name) }) { Text("Conectar") }
                        }
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(onClick = { search() }) { Text("Procurar de novo") }
                        TextButton(onClick = { if (ble.hasPermissions()) ble.startScan(all = true) else permLauncher.launch(ble.requiredPermissions()) }) { Text("Mostrar todos") }
                        if (ble.lastAddress != null) {
                            TextButton(onClick = { if (ble.hasPermissions()) ble.reconnectLast() else permLauncher.launch(ble.requiredPermissions()) }) { Text("Última trena") }
                        }
                    }
                }
                if (log.isNotEmpty()) {
                    HorizontalDivider()
                    Text("Diagnóstico: últimos quadros recebidos", color = Ui.dim, fontSize = 13.sp)
                    log.forEach { Text(it, color = Ui.dim, fontFamily = FontFamily.Monospace, fontSize = 11.sp) }
                }
            }
        }
    }
}
