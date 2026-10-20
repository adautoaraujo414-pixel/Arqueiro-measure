package br.com.arque.measure.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.logic.CabinetMath
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.CabObj
import br.com.arque.measure.model.Cabinet
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.PartKind
import br.com.arque.measure.model.Vao
import br.com.arque.measure.model.VaoKind

private val Gold = Color(0xFFF2C230)
private val Wood = Color(0xFFCDB98F)
private val WoodFront = Color(0xFFE6D9BE)
private val WoodDark = Color(0xFF8B7B5C)

private fun mmStr(v: Double) = Units.formatNumber(v, LengthUnit.MM) + " mm"

/** Editor do móvel: vista frontal paramétrica, na medida real. */
@Composable
fun CabinetScreen(vm: AppViewModel, session: EditorSession, id: String, onClose: () -> Unit) {
    @Suppress("UNUSED_VARIABLE")
    val rev = session.rev
    val st = session.state
    val obj = st.sheet.obj(id) as? CabObj
    if (obj == null) { onClose(); return }
    val cab = CabinetMath.normalized(obj.cab)
    var selDivider by remember { mutableIntStateOf(-1) }
    var selVao by remember { mutableIntStateOf(0) }
    var listOpen by remember { mutableStateOf(false) }
    var renameOpen by remember { mutableStateOf(false) }
    val wide = LocalConfiguration.current.screenWidthDp >= 720
    if (selVao > cab.vaos.lastIndex) selVao = cab.vaos.lastIndex
    if (selDivider > cab.dividers.lastIndex) selDivider = -1

    fun edit(f: (Cabinet) -> Cabinet) = st.updateCab(id, f)

    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(Modifier.fillMaxSize(), color = Ui.bg) {
            Column(Modifier.statusBarsPadding().navigationBarsPadding()) {
                // barra superior
                Row(
                    Modifier.fillMaxWidth().background(Ui.panel).padding(horizontal = 8.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    TextButton(onClick = onClose) { Text("‹ Folha", color = Ui.text) }
                    Column(Modifier.weight(1f).clickable { renameOpen = true }) {
                        Text(obj.name, color = Ui.text, fontSize = 16.sp)
                        Text("Vista frontal · ${mmStr(cab.wMm)} × ${mmStr(cab.hMm)} × ${mmStr(cab.dMm)}", color = Ui.dim, fontSize = 12.sp)
                    }
                    TextButton(onClick = { st.undo() }, enabled = st.canUndo) { Text("Desfazer") }
                    TextButton(onClick = { st.redo() }, enabled = st.canRedo) { Text("Refazer") }
                    TextButton(onClick = { listOpen = true }) { Text("Lista de peças", color = Ui.accent) }
                }
                val canvasPart: @Composable (Modifier) -> Unit = { mod ->
                    CabinetCanvas(
                        cab = cab, selDivider = selDivider, selVao = selVao, modifier = mod,
                        onPickDivider = { selDivider = it },
                        onPickVao = { selVao = it; selDivider = -1 },
                        onBegin = { st.beginGesture() },
                        onLive = { f -> st.liveCab(id, f) },
                        onEnd = { st.endGesture() },
                    )
                }
                val panelPart: @Composable (Modifier) -> Unit = { mod ->
                    CabinetPanel(
                        vm = vm, cab = cab, selDivider = selDivider, selVao = selVao, modifier = mod,
                        edit = ::edit,
                        pickVao = { selVao = it; selDivider = -1 },
                        pickDivider = { selDivider = it },
                    )
                }
                if (wide) {
                    Row(Modifier.fillMaxSize()) {
                        canvasPart(Modifier.weight(1f).fillMaxSize())
                        panelPart(Modifier.width(360.dp).fillMaxSize())
                    }
                } else {
                    Column(Modifier.fillMaxSize()) {
                        canvasPart(Modifier.weight(1f).fillMaxWidth())
                        panelPart(Modifier.height(300.dp).fillMaxWidth())
                    }
                }
            }
        }
    }

    if (renameOpen) {
        var text by remember { mutableStateOf(obj.name) }
        AlertDialog(
            onDismissRequest = { renameOpen = false },
            title = { Text("Nome do móvel") },
            text = { OutlinedTextField(value = text, onValueChange = { text = it }, singleLine = true) },
            confirmButton = { TextButton(onClick = { st.renameCab(id, text); renameOpen = false }) { Text("OK") } },
            dismissButton = { TextButton(onClick = { renameOpen = false }) { Text("Cancelar") } },
        )
    }
    if (listOpen) CutListDialog(cab, obj.name) { listOpen = false }
}

// ---------------------------------------------------------------- desenho

@Composable
private fun CabinetCanvas(
    cab: Cabinet,
    selDivider: Int,
    selVao: Int,
    modifier: Modifier,
    onPickDivider: (Int) -> Unit,
    onPickVao: (Int) -> Unit,
    onBegin: () -> Unit,
    onLive: ((Cabinet) -> Cabinet) -> Unit,
    onEnd: () -> Unit,
) {
    val cabNow by rememberUpdatedState(cab)
    var dragging by remember { mutableIntStateOf(-2) } // -2 nada, -1 lateral dir., 0.. divisória
    val e = cab.espMm
    val parts = CabinetMath.parts(cab)
    val ranges = CabinetMath.vaoRanges(cab)
    val dx = CabinetMath.dividerX(cab)
    fun fit(sz: Size) = fitOf(cab, sz)
    Canvas(
        modifier = modifier.background(Color(0xFF17181B)).pointerInput(Unit) {
            detectDragGestures(
                onDragStart = { pos ->
                    val c = cabNow
                    val (k, ox, oy) = fitOf(c, Size(size.width.toFloat(), size.height.toFloat()))
                    val mx = (pos.x - ox) / k
                    val my = (pos.y - oy) / k
                    val tol = 22f / k
                    val ee = c.espMm
                    val d = CabinetMath.dividerX(c)
                    val vt = CabinetMath.vaoTop(c)
                    val vb = CabinetMath.vaoBottom(c)
                    val di = d.indexOfFirst { mx >= it - tol && mx <= it + ee + tol && my in vt..vb }
                    dragging = when {
                        di >= 0 -> di
                        mx >= c.wMm - ee - tol && mx <= c.wMm + tol -> -1
                        else -> -2
                    }
                    if (dragging != -2) { onBegin(); if (dragging >= 0) onPickDivider(dragging) }
                },
                onDrag = { change, _ ->
                    val c = cabNow
                    val (k, ox, _) = fitOf(c, Size(size.width.toFloat(), size.height.toFloat()))
                    val mx = ((change.position.x - ox) / k).toDouble()
                    val ee = c.espMm
                    if (dragging >= 0) {
                        change.consume()
                        val i = dragging
                        val d = CabinetMath.dividerX(c)
                        val lo = (if (i == 0) ee else d[i - 1] + ee) + 10.0
                        val hi = (if (i == d.lastIndex) c.wMm - ee else d[i + 1]) - ee - 10.0
                        val x = Math.round(mx - ee / 2).toDouble().coerceIn(lo, hi.coerceAtLeast(lo))
                        val iwn = CabinetMath.innerW(c)
                        val r = ((x + ee / 2 - ee) / iwn).toFloat().coerceIn(0.01f, 0.99f)
                        onLive { cc -> cc.copy(dividers = cc.dividers.sorted().mapIndexed { j, o -> if (j == i) r else o }) }
                    } else if (dragging == -1) {
                        change.consume()
                        val nw = Math.round(mx).toDouble().coerceIn(150.0, 6000.0)
                        // mantém a posição absoluta das divisórias (mm) ao mexer na largura
                        onLive { cc ->
                            val dxs = CabinetMath.dividerX(cc)
                            val iwn = (nw - 2 * ee).coerceAtLeast(10.0)
                            cc.copy(wMm = nw, dividers = dxs.map { x -> ((x + ee / 2 - ee) / iwn).toFloat().coerceIn(0.01f, 0.99f) })
                        }
                    }
                },
                onDragEnd = { if (dragging != -2) onEnd(); dragging = -2 },
                onDragCancel = { if (dragging != -2) onEnd(); dragging = -2 },
            )
        }.pointerInput(Unit) {
            detectTapGestures { pos ->
                val cab = cabNow
                val ranges = CabinetMath.vaoRanges(cab)
                val dx = CabinetMath.dividerX(cab)
                val e = cab.espMm
                val (k, ox, oy) = fitOf(cab, Size(size.width.toFloat(), size.height.toFloat()))
                val mx = (pos.x - ox) / k
                val my = (pos.y - oy) / k
                val tol = 14f / k
                val vTop = CabinetMath.vaoTop(cab)
                val vBot = CabinetMath.vaoBottom(cab)
                val di = dx.indexOfFirst { mx >= it - tol / 2 && mx <= it + e + tol / 2 && my in vTop..vBot }
                if (di >= 0) { onPickDivider(di); return@detectTapGestures }
                val vi = ranges.indexOfFirst { mx >= it.first && mx <= it.second }
                if (vi >= 0 && my in vTop..vBot) onPickVao(vi)
            }
        },
    ) {
        val (k, ox, oy) = fit(size)
        fun X(mm: Double) = ox + mm.toFloat() * k
        fun Y(mm: Double) = oy + mm.toFloat() * k
        // grade de 50 mm
        var gx = 0.0
        val gridColor = Color(0xFF212329)
        while (gx <= cab.wMm + 200) {
            drawLine(gridColor, Offset(X(gx), 0f), Offset(X(gx), size.height), 1f); gx += 50.0
        }
        var gy = 0.0
        while (gy <= cab.hMm + 200) {
            drawLine(gridColor, Offset(0f, Y(gy)), Offset(size.width, Y(gy)), 1f); gy += 50.0
        }
        // seleção de vão (fundo azul claro)
        ranges.getOrNull(selVao)?.let { (x0, x1) ->
            if (selDivider < 0) drawRect(Color(0x333B82F6), Offset(X(x0), Y(CabinetMath.vaoTop(cab))), Size(((x1 - x0) * k).toFloat(), (CabinetMath.vaoH(cab) * k).toFloat()))
        }
        // peças
        for (p in parts) {
            val col = when {
                p.kind == PartKind.RODAPE -> WoodDark
                p.kind == PartKind.MOLDURA -> WoodFront
                p.kind == PartKind.FRENTE_GAVETA || p.kind == PartKind.PORTA -> WoodFront
                else -> Wood
            }
            val tl = Offset(X(p.x), Y(p.y))
            val sz = Size((p.w * k).toFloat(), (p.h * k).toFloat())
            drawRect(col, tl, sz)
            drawRect(Color(0x66000000), tl, sz, style = Stroke(1f))
            if (p.kind == PartKind.FRENTE_GAVETA) {
                val cx = tl.x + sz.width / 2
                drawLine(WoodDark, Offset(cx - 30f * 0.5f * k * 2, tl.y + 12f), Offset(cx + 30f * 0.5f * k * 2, tl.y + 12f), 4f)
            }
            if (p.kind == PartKind.PORTA) {
                drawLine(WoodDark, Offset(tl.x + sz.width - 12f, tl.y + sz.height * 0.4f), Offset(tl.x + sz.width - 12f, tl.y + sz.height * 0.6f), 4f)
            }
        }
        // divisória selecionada
        if (selDivider in dx.indices) {
            val x = dx[selDivider]
            drawRect(
                Color(0xFF3B82F6), Offset(X(x) - 3f, Y(CabinetMath.vaoTop(cab)) - 3f),
                Size((e * k).toFloat() + 6f, (CabinetMath.vaoH(cab) * k).toFloat() + 6f), style = Stroke(3f),
            )
        }
        // pedra (referência): acima do móvel
        drawRect(Color(0xFF3A3D44), Offset(X(-20.0), Y(-14.0)), Size(((cab.wMm + 40) * k).toFloat(), (14 * k).toFloat().coerceAtLeast(6f)))
        // cotas
        val nc = drawContext.canvas.nativeCanvas
        val chipPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply { color = Gold.toArgb() }
        val txtPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFF111111.toInt(); textSize = 28f; typeface = android.graphics.Typeface.MONOSPACE; textAlign = android.graphics.Paint.Align.CENTER
        }
        val line = android.graphics.Paint().apply { color = Gold.toArgb(); strokeWidth = 2f }
        fun chip(text: String, cx: Float, cy: Float) {
            val w = txtPaint.measureText(text) + 24f
            nc.drawRoundRect(cx - w / 2, cy - 20f, cx + w / 2, cy + 20f, 8f, 8f, chipPaint)
            nc.drawText(text, cx, cy + 9f, txtPaint)
        }
        val top = Y(0.0) - 44f
        nc.drawLine(X(0.0), top, X(cab.wMm), top, line)
        chip(mmStr(cab.wMm), (X(0.0) + X(cab.wMm)) / 2, top)
        val left = X(0.0) - 44f
        nc.drawLine(left, Y(0.0), left, Y(cab.hMm), line)
        chip(Units.formatNumber(cab.hMm, LengthUnit.MM), left, (Y(0.0) + Y(cab.hMm)) / 2)
        val vl = X(cab.wMm) + 44f
        nc.drawLine(vl, Y(CabinetMath.vaoTop(cab)), vl, Y(CabinetMath.vaoBottom(cab)), line)
        chip(Units.formatNumber(CabinetMath.vaoH(cab), LengthUnit.MM), vl, (Y(CabinetMath.vaoTop(cab)) + Y(CabinetMath.vaoBottom(cab))) / 2)
        val bottom = Y(cab.hMm) + 44f
        ranges.forEach { (x0, x1) -> chip(Units.formatNumber(x1 - x0, LengthUnit.MM), (X(x0) + X(x1)) / 2, bottom) }
    }
}

/** Transformação mm → tela (escala, origem x, origem y), recalculada com o tamanho atual do canvas. */
private fun fitOf(cab: Cabinet, sz: Size): Triple<Float, Float, Float> {
    val m = 90f
    val k = minOf((sz.width - 2 * m) / cab.wMm.toFloat(), (sz.height - 2 * m) / cab.hMm.toFloat()).coerceAtLeast(0.01f)
    val ox = (sz.width - cab.wMm.toFloat() * k) / 2f
    val oy = (sz.height - cab.hMm.toFloat() * k) / 2f
    return Triple(k, ox, oy)
}

private fun Color.toArgb(): Int = android.graphics.Color.argb((alpha * 255).toInt(), (red * 255).toInt(), (green * 255).toInt(), (blue * 255).toInt())

// ---------------------------------------------------------------- painel

@Composable
private fun CabinetPanel(
    vm: AppViewModel,
    cab: Cabinet,
    selDivider: Int,
    selVao: Int,
    modifier: Modifier,
    edit: ((Cabinet) -> Cabinet) -> Unit,
    pickVao: (Int) -> Unit,
    pickDivider: (Int) -> Unit,
) {
    val e = cab.espMm
    val iw = CabinetMath.innerW(cab)
    val ranges = CabinetMath.vaoRanges(cab)
    val dx = CabinetMath.dividerX(cab)
    Column(
        modifier.background(Ui.panel).verticalScroll(rememberScrollState()).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Label("Módulo")
        NumField("Largura da pedra", cab.pedraWMm ?: (cab.wMm + CabinetMath.DESCONTO_PEDRA_MM), vm) { v ->
            edit { it.copy(pedraWMm = v, wMm = (v - CabinetMath.DESCONTO_PEDRA_MM).coerceIn(150.0, 6000.0)) }
        }
        NumField("Profundidade da pedra", cab.pedraDMm ?: (cab.dMm + CabinetMath.DESCONTO_PEDRA_MM), vm) { v ->
            edit { it.copy(pedraDMm = v, dMm = (v - CabinetMath.DESCONTO_PEDRA_MM).coerceIn(100.0, 1500.0)) }
        }
        NumField("Largura do módulo", cab.wMm, vm) { v -> edit { it.copy(wMm = v.coerceIn(150.0, 6000.0), pedraWMm = null) } }
        NumField("Profundidade do módulo", cab.dMm, vm) { v -> edit { it.copy(dMm = v.coerceIn(100.0, 1500.0), pedraDMm = null) } }
        NumField("Altura (chão até a pedra)", cab.hMm, vm) { v -> edit { it.copy(hMm = v.coerceIn(300.0, 3000.0)) } }
        Text("A pedra manda: o módulo fica 40 mm menor na largura e na profundidade. Arraste as divisórias e a lateral direita no desenho; as medidas dos vãos mudam na hora.", color = Ui.dim, fontSize = 12.sp)
        HorizontalDivider(color = Ui.line)

        if (selDivider in dx.indices) {
            Label("Divisória ${selDivider + 1} · MDF ${Units.formatNumber(e, LengthUnit.MM)} mm")
            NumField("Distância da lateral esq.", dx[selDivider] - e, vm) { d ->
                edit { c -> c.copy(dividers = c.dividers.sorted().mapIndexed { i, r -> if (i == selDivider) (((d + e / 2) / iw).toFloat()).coerceIn(0.02f, 0.98f) else r }) }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                PillBtn("Centralizar no vão") {
                    val left = if (selDivider == 0) e else dx[selDivider - 1] + e
                    val right = if (selDivider + 1 < dx.size) dx[selDivider + 1] else cab.wMm - e
                    val center = (left + right) / 2
                    edit { c -> c.copy(dividers = c.dividers.sorted().mapIndexed { i, r -> if (i == selDivider) ((center - e) / iw).toFloat() else r }) }
                }
                PillBtn("Remover", danger = true) {
                    val j = selDivider
                    edit { c -> c.copy(dividers = c.dividers.sorted().filterIndexed { i, _ -> i != j }, vaos = c.vaos.filterIndexed { i, _ -> i != j + 1 }) }
                    pickDivider(-1)
                }
            }
        } else if (selVao in ranges.indices) {
            val v = cab.vaos[selVao]
            val vw = ranges[selVao].second - ranges[selVao].first
            Label("Vão ${selVao + 1} · ${mmStr(vw)}")
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.horizontalScroll(rememberScrollState())) {
                VaoKind.values().forEach { kd ->
                    Chip(kd.label, v.kind == kd) { edit { c -> c.copy(vaos = c.vaos.mapIndexed { i, o -> if (i == selVao) o.copy(kind = kd) else o }) } }
                }
            }
            fun setVao(f: (Vao) -> Vao) = edit { c -> c.copy(vaos = c.vaos.mapIndexed { i, o -> if (i == selVao) f(o) else o }) }
            when (v.kind) {
                VaoKind.SHELVES -> Stepper("Prateleiras", v.shelves, 1, 8) { n -> setVao { it.copy(shelves = n) } }
                VaoKind.DRAWERS -> {
                    Stepper("Quantidade de gavetas", v.drawers, 1, 8) { n -> setVao { it.copy(drawers = n) } }
                    NumField("Borda superior", cab.bordaSupMm, vm) { x -> edit { it.copy(bordaSupMm = x.coerceIn(0.0, 50.0)) } }
                    NumField("Borda inferior", cab.bordaInfMm, vm) { x -> edit { it.copy(bordaInfMm = x.coerceIn(0.0, 50.0)) } }
                    NumField("Folga entre frentes", cab.folgaGavetaMm, vm) { x -> edit { it.copy(folgaGavetaMm = x.coerceIn(0.0, 30.0)) } }
                    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Color(0xFF16273F)).padding(12.dp)) {
                        Text("Altura de cada frente", color = Ui.dim, fontSize = 12.sp)
                        Text(Units.format(CabinetMath.drawerFrontH(cab, v.drawers), LengthUnit.MM), color = Color.White, fontSize = 22.sp, fontFamily = FontFamily.Monospace)
                        Text("(vão − bordas − folgas) ÷ ${v.drawers}", color = Color(0xFFBFD6FF), fontSize = 12.sp, fontFamily = FontFamily.Monospace)
                    }
                }
                VaoKind.DOOR -> {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Chip("1 folha", v.doors < 2) { setVao { it.copy(doors = 1) } }
                        Chip("2 folhas", v.doors >= 2) { setVao { it.copy(doors = 2) } }
                    }
                    NumField("Folga da porta", cab.folgaMm, vm) { x -> edit { it.copy(folgaMm = x.coerceIn(0.0, 10.0)) } }
                }
                VaoKind.FREE -> Text("Vão livre. Escolha prateleiras, gavetas ou porta.", color = Ui.dim, fontSize = 12.sp)
            }
            PillBtn("+ Divisória no meio deste vão") {
                val mid = (ranges[selVao].first + ranges[selVao].second) / 2
                val r = ((mid - e) / iw).toFloat()
                edit { c ->
                    val i = selVao
                    c.copy(dividers = (c.dividers.sorted().take(i) + r + c.dividers.sorted().drop(i)), vaos = c.vaos.take(i + 1) + Vao() + c.vaos.drop(i + 1))
                }
            }
        }
        HorizontalDivider(color = Ui.line)
        Label("Regras do módulo")
        NumField("Espessura das chapas", cab.espMm, vm) { x -> edit { it.copy(espMm = x.coerceIn(3.0, 40.0)) } }
        NumField("Altura do pedestal (rodapé)", cab.rodapeMm, vm) { x -> edit { it.copy(rodapeMm = x.coerceIn(0.0, 300.0)) } }
        NumField("Folga do topo (sob a pedra)", cab.folgaTopoMm, vm) { x -> edit { it.copy(folgaTopoMm = x.coerceIn(0.0, 60.0)) } }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Moldura de acabamento (${Units.formatNumber(cab.molduraMm, LengthUnit.MM)} mm)", color = Ui.text, fontSize = 14.sp, modifier = Modifier.weight(1f))
            Switch(checked = cab.hasMoldura, onCheckedChange = { b -> edit { it.copy(hasMoldura = b) } })
        }
        NumField("Altura da travessa frontal", cab.travessaMm, vm) { x -> edit { it.copy(travessaMm = x.coerceIn(20.0, 300.0)) } }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Fundo (3 mm)", color = Ui.text, fontSize = 14.sp, modifier = Modifier.weight(1f))
            Switch(checked = cab.hasBack, onCheckedChange = { b -> edit { it.copy(hasBack = b) } })
        }
    }
}

@Composable private fun Label(t: String) = Text(t.uppercase(), color = Ui.dim, fontSize = 11.sp, letterSpacing = 1.sp)

@Composable
private fun PillBtn(text: String, danger: Boolean = false, onClick: () -> Unit) {
    Box(
        Modifier.clip(RoundedCornerShape(10.dp)).background(Ui.panel2).clickable(onClick = onClick).padding(horizontal = 14.dp, vertical = 10.dp),
    ) { Text(text, color = if (danger) Color(0xFFFF7A7A) else Ui.text, fontSize = 13.sp) }
}

@Composable
private fun Chip(text: String, on: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.clip(RoundedCornerShape(16.dp)).background(if (on) Ui.accent else Ui.panel2).clickable(onClick = onClick).padding(horizontal = 14.dp, vertical = 8.dp),
    ) { Text(text, color = if (on) Color.White else Ui.text, fontSize = 13.sp) }
}

@Composable
private fun Stepper(label: String, value: Int, min: Int, max: Int, onSet: (Int) -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).background(Ui.panel2).padding(horizontal = 12.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, color = Ui.text, fontSize = 13.sp, modifier = Modifier.weight(1f))
        Text("−", color = Color.White, fontSize = 22.sp, modifier = Modifier.clickable { onSet((value - 1).coerceAtLeast(min)) }.padding(horizontal = 14.dp))
        Text("$value", color = Color.White, fontSize = 16.sp, fontFamily = FontFamily.Monospace)
        Text("+", color = Color.White, fontSize = 22.sp, modifier = Modifier.clickable { onSet((value + 1).coerceAtMost(max)) }.padding(horizontal = 14.dp))
    }
}

/** Campo numérico em mm: toque para digitar; o botão da régua pega a medida da trena. */
@Composable
private fun NumField(label: String, mm: Double, vm: AppViewModel, onSet: (Double) -> Unit) {
    var dialog by remember { mutableStateOf(false) }
    val armed = vm.measureArmed == label
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).background(if (armed) Color(0xFF16273F) else Ui.panel2)
            .clickable { dialog = true }.padding(start = 12.dp, top = 4.dp, bottom = 4.dp, end = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, color = Ui.text, fontSize = 13.sp, modifier = Modifier.weight(1f))
        Text(if (armed) "aguardando a trena…" else mmStr(mm), color = if (armed) Color(0xFF7FB0FF) else Color.White, fontSize = 14.sp, fontFamily = FontFamily.Monospace)
        Box(
            Modifier.padding(start = 8.dp).size(36.dp).clip(RoundedCornerShape(8.dp)).background(Color(0xFF1E3A6B))
                .clickable { if (armed) vm.cancelMeasure() else vm.armMeasure(label) { v -> onSet(Math.round(v * 10.0) / 10.0) } },
            contentAlignment = Alignment.Center,
        ) { Text("⟷", color = Color(0xFFBFD6FF), fontSize = 18.sp) }
    }
    if (dialog) {
        var text by remember { mutableStateOf(Units.formatNumber(mm, LengthUnit.MM)) }
        AlertDialog(
            onDismissRequest = { dialog = false },
            title = { Text(label) },
            text = {
                OutlinedTextField(
                    value = text, onValueChange = { text = it }, singleLine = true,
                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    suffix = { Text("mm") },
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    Units.parseToMm(text, LengthUnit.MM)?.let(onSet)
                    dialog = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { dialog = false }) { Text("Cancelar") } },
        )
    }
}

// ---------------------------------------------------------------- lista de peças

@Composable
private fun CutListDialog(cab: Cabinet, name: String, onDismiss: () -> Unit) {
    val lines = CabinetMath.cutList(cab)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Lista de peças · $name") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                lines.forEach { l ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("${l.qty}×", fontFamily = FontFamily.Monospace, modifier = Modifier.width(36.dp))
                        Text(l.kind.label, modifier = Modifier.weight(1f), fontSize = 14.sp)
                        Text(
                            "${Units.formatNumber(l.cutL, LengthUnit.MM)} × ${Units.formatNumber(l.cutW, LengthUnit.MM)} × ${Units.formatNumber(l.esp, LengthUnit.MM)}",
                            fontFamily = FontFamily.Monospace, fontSize = 13.sp,
                        )
                    }
                }
                Text(
                    "${lines.sumOf { it.qty }} peças · medidas em mm (comprimento × largura × espessura). Sem plano de corte.",
                    fontSize = 12.sp, modifier = Modifier.padding(top = 8.dp),
                )
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Fechar") } },
    )
}
