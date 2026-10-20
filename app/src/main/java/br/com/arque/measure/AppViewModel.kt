package br.com.arque.measure

import android.app.Application
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.core.content.FileProvider
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import br.com.arque.measure.ble.BoschBle
import br.com.arque.measure.data.Store
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.Folder
import br.com.arque.measure.model.Index
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.Template
import br.com.arque.measure.model.newId
import br.com.arque.measure.ui.EditorSession
import br.com.arque.measure.ui.ImageCache
import br.com.arque.measure.ui.SheetRenderer
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.util.concurrent.Executors

sealed interface Screen {
    data object Library : Screen
    data object Editor : Screen
}

/** Filtro da biblioteca: todas, uma pasta ou o lixo. */
sealed interface LibFilter {
    data object All : LibFilter
    data object Trash : LibFilter
    data class InFolder(val id: String) : LibFilter
}

class AppViewModel(app: Application) : AndroidViewModel(app) {
    val store = Store(File(app.filesDir, "projects"))
    val images = ImageCache(store, viewModelScope)
    val ble = BoschBle(app)

    // painel da trena na folha: pode ocultar e mudar o tamanho (guardado no aparelho)
    private val uiPrefs = app.getSharedPreferences("arque_ui", android.content.Context.MODE_PRIVATE)
    var trenaHidden by mutableStateOf(uiPrefs.getBoolean("trenaHidden", false))
        private set
    var trenaScale by mutableStateOf(uiPrefs.getFloat("trenaScale", 0.8f).coerceIn(0.5f, 1.3f))
        private set

    fun setTrenaHidden(v: Boolean) {
        trenaHidden = v
        uiPrefs.edit().putBoolean("trenaHidden", v).apply()
    }

    fun setTrenaScale(s: Float) {
        trenaScale = s.coerceIn(0.5f, 1.3f)
        uiPrefs.edit().putFloat("trenaScale", trenaScale).apply()
    }

    /** Uma única thread para toda escrita em disco: mantém a ordem dos salvamentos. */
    private val io = Executors.newSingleThreadExecutor().asCoroutineDispatcher()

    var index by mutableStateOf(store.loadIndex())
        private set
    var screen by mutableStateOf<Screen>(Screen.Library)
    var filter by mutableStateOf<LibFilter>(LibFilter.All)
    var session by mutableStateOf<EditorSession?>(null)
        private set
    /** Notas abertas (abas do editor), na ordem de abertura. */
    val tabs = mutableStateListOf<String>()
    var toast by mutableStateOf<String?>(null)
    var thumbVersion by mutableIntStateOf(0)

    /** Leituras recebidas da trena que ainda não foram vinculadas a uma cota (mais nova primeiro). */
    val recent = mutableStateListOf<Reading>().also { it.addAll(store.loadReadings()) }

    /** Quando true, a próxima foto adicionada vai para uma folha nova no fim da nota. */
    var photoToNewPage = false

    /** Importação pedida na biblioteca ("gallery" ou "camera"): o editor executa ao abrir. */
    var pendingImport by mutableStateOf<String?>(null)

    private var saveJob: Job? = null
    private var pendingCameraFile: File? = null

    init {
        viewModelScope.launch { ble.readings.collect { onReading(it) } }
    }

    // ---------- biblioteca ----------

    private fun updateIndex(newIndex: Index) {
        index = newIndex
        viewModelScope.launch(io) { store.saveIndex(newIndex) }
    }

    fun addFolder(name: String) {
        if (name.isBlank()) return
        updateIndex(index.copy(folders = index.folders + Folder(name = name.trim())))
    }

    private fun upsertMeta(n: Note) {
        val metas = index.notes
        val m = n.meta()
        updateIndex(index.copy(notes = if (metas.any { it.id == n.id }) metas.map { if (it.id == n.id) m else it } else metas + m))
    }

    fun createNote(): String {
        val folder = (filter as? LibFilter.InFolder)?.id
        val n = Note(name = "Nota ${index.notes.count { !it.trash } + 1}", folderId = folder)
        viewModelScope.launch(io) { store.saveNote(n) }
        upsertMeta(n)
        writeThumb(n)
        return n.id
    }

    /** Fecha a sessão aberta desta nota (se houver) gravando antes. */
    private fun closeIfOpen(id: String) {
        if (session?.state?.note?.id == id) {
            flush()
            session = null
        }
        tabs.remove(id)
    }

    private fun mutateNote(id: String, f: (Note) -> Note) {
        closeIfOpen(id)
        if (tabs.isEmpty() && screen == Screen.Editor) screen = Screen.Library
        viewModelScope.launch {
            val n = withContext(io) { store.loadNote(id)?.also { store.saveNote(f(it)) } }
            if (n != null) upsertMeta(f(n))
        }
    }

    fun renameNote(id: String, name: String) { if (name.isNotBlank()) mutateNote(id) { it.copy(name = name.trim()) } }
    fun pinNote(id: String, v: Boolean) = mutateNote(id) { it.copy(pinned = v) }
    fun lockNote(id: String, v: Boolean) = mutateNote(id) { it.copy(locked = v) }
    fun moveNote(id: String, folderId: String?) = mutateNote(id) { it.copy(folderId = folderId) }
    fun trashNote(id: String, v: Boolean) = mutateNote(id) { it.copy(trash = v) }

    fun copyNote(id: String) {
        viewModelScope.launch {
            val c = withContext(io) {
                store.loadNote(id)?.let { src ->
                    src.copy(id = newId(), name = src.name + " (cópia)", createdMs = System.currentTimeMillis(), pinned = false, trash = false)
                        .also { store.saveNote(it) }
                }
            }
            if (c != null) upsertMeta(c)
        }
    }

    private fun cleanupImages() {
        val keep = store.referencedImages()
        store.root.resolve("images").listFiles().orEmpty().filter { it.name !in keep }.forEach { it.delete() }
    }

    // ---------- editor ----------

    fun openNote(id: String) {
        val meta = index.notes.firstOrNull { it.id == id } ?: return
        if (meta.locked) {
            toast = "Nota bloqueada. Remova o bloqueio no menu da nota."
            return
        }
        if (session?.state?.note?.id == id) { screen = Screen.Editor; return }
        viewModelScope.launch {
            val note = withContext(io) { store.loadNote(id) }
            if (note == null) {
                toast = "Não foi possível abrir a nota"
                return@launch
            }
            flush()
            session = EditorSession(note) { scheduleSave(it) }
            if (id !in tabs) tabs.add(id)
            screen = Screen.Editor
        }
    }

    fun closeTab(id: String) {
        closeIfOpen(id)
        val next = tabs.lastOrNull()
        if (next != null) openNote(next) else screen = Screen.Library
    }

    fun closeEditor() {
        flush()
        screen = Screen.Library
    }

    fun tabName(id: String) = index.notes.firstOrNull { it.id == id }?.name ?: "Nota"

    /** Salvamento automático: espera uma pausa nas edições e grava a nota. */
    private fun scheduleSave(note: Note) {
        saveJob?.cancel()
        saveJob = viewModelScope.launch {
            delay(600)
            withContext(io) { store.saveNote(note) }
            upsertMeta(note)
            writeThumb(note)
        }
    }

    // ---------- miniaturas da biblioteca (primeira folha) ----------

    private val thumbRenderer by lazy { renderer() }
    private fun thumbFile(id: String) = File(store.root, "thumbs/$id.png")

    private fun writeThumb(note: Note) {
        val w = 240
        val h = (w * Sheet.H / Sheet.W).toInt()
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        c.drawColor(Color.WHITE)
        val k = w / Sheet.W
        c.scale(k, k)
        thumbRenderer.draw(c, note.pages.first(), note.unit, null, 1f, withPaper = false)
        viewModelScope.launch(io) {
            runCatching {
                val f = thumbFile(note.id)
                f.parentFile?.mkdirs()
                f.outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 90, it) }
            }
            bmp.recycle()
            withContext(Dispatchers.Main) { thumbVersion++ }
        }
    }

    fun loadThumb(id: String): ImageBitmap? =
        thumbFile(id).takeIf { it.exists() }?.let { BitmapFactory.decodeFile(it.path)?.asImageBitmap() }

    /** Grava agora (ao sair da nota ou do app). */
    fun flush() {
        val s = session ?: return
        saveJob?.cancel()
        val n = s.state.note
        store.saveNote(n)
        upsertMeta(n)
        writeThumb(n)
    }

    fun renderer(): SheetRenderer = SheetRenderer { images.get(it) }

    // ---------- fotos ----------

    private fun extFor(uri: Uri): String {
        val app = getApplication<Application>()
        val mime = app.contentResolver.getType(uri)
        return MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: "jpg"
    }

    private fun placePhoto(s: EditorSession, name: String, w: Int, h: Int) {
        if (photoToNewPage) {
            photoToNewPage = false
            s.state.addPage(s.state.note.pages.size, Template.BLANK)
            s.goToPage(s.state.pageIdx)
        }
        s.addPhoto(name, w, h)
    }

    fun addPhotoFromUri(uri: Uri) {
        val s = session ?: return
        val app = getApplication<Application>()
        viewModelScope.launch {
            val result = withContext(io) {
                runCatching {
                    val input = app.contentResolver.openInputStream(uri) ?: error("sem acesso à foto")
                    val name = store.importImage(input, extFor(uri))
                    val size = ImageCache.orientedSize(store.imageFile(name)) ?: error("imagem inválida")
                    Triple(name, size.first, size.second)
                }
            }
            result.onSuccess { (name, w, h) -> placePhoto(s, name, w, h) }
                .onFailure { toast = "Não foi possível adicionar a foto" }
        }
    }

    fun newCameraUri(): Uri {
        val app = getApplication<Application>()
        val dir = File(app.cacheDir, "camera").apply { mkdirs() }
        val f = File(dir, "IMG_${System.currentTimeMillis()}.jpg")
        pendingCameraFile = f
        return FileProvider.getUriForFile(app, "${app.packageName}.fileprovider", f)
    }

    fun onCameraResult(ok: Boolean) {
        val f = pendingCameraFile ?: return
        pendingCameraFile = null
        if (!ok || !f.exists() || f.length() == 0L) {
            f.delete()
            photoToNewPage = false
            return
        }
        val s = session ?: return
        viewModelScope.launch {
            val result = withContext(io) {
                runCatching {
                    val name = store.importImage(f.inputStream(), "jpg")
                    f.delete()
                    val size = ImageCache.orientedSize(store.imageFile(name)) ?: error("imagem inválida")
                    Triple(name, size.first, size.second)
                }
            }
            result.onSuccess { (name, w, h) -> placePhoto(s, name, w, h) }
                .onFailure { toast = "Não foi possível adicionar a foto" }
        }
    }

    // ---------- leituras da trena (única origem de medidas) ----------

    private fun persistRecent() {
        val snapshot = recent.toList()
        viewModelScope.launch(io) { store.saveReadings(snapshot) }
    }

    /** Leitura nova: se há uma cota selecionada, grava nela e avança; senão vira um "chip" na barra. */
    private fun onReading(r: Reading) {
        val s = session
        if (s != null && screen == Screen.Editor && s.state.assignReading(r) != null) return
        recent.add(0, r)
        while (recent.size > MAX_RECENT) recent.removeAt(recent.lastIndex)
        persistRecent()
    }

    /** Toque num chip: aplica à cota selecionada. */
    fun applyRecent(r: Reading) {
        val s = session ?: return
        if (s.state.assignReading(r) != null) {
            recent.remove(r)
            persistRecent()
        } else {
            toast = "Toque numa seta de cota primeiro"
        }
    }

    /** Toque numa seta de cota sem valor com leituras esperando: recebe a leitura mais nova. */
    fun onDimTap(id: String) {
        val s = session ?: return
        val d = s.state.selected as? br.com.arque.measure.model.DimObj ?: return
        if (d.id != id || d.locked || d.valueMm != null) return
        val r = recent.firstOrNull() ?: return
        if (s.state.assignReading(r) != null) {
            recent.remove(r)
            persistRecent()
        }
    }

    /** Toque num segmento de cômodo sem valor com leituras esperando: recebe a leitura mais nova. */
    fun onSegTap(id: String, seg: Int) {
        val s = session ?: return
        val r = s.state.selected as? br.com.arque.measure.model.RoomObj ?: return
        val sg = r.segs.getOrNull(seg) ?: return
        if (r.id != id || r.locked || sg.valueMm != null) return
        val rd = recent.firstOrNull() ?: return
        if (s.state.assignReading(rd) != null) {
            recent.remove(rd)
            persistRecent()
        }
    }

    fun discardRecent(r: Reading) {
        recent.remove(r)
        persistRecent()
    }

    fun clearRecent() {
        recent.clear()
        persistRecent()
    }

    // ---------- exportação e backup ----------

    private fun runIo(okMsg: String, block: () -> Unit) {
        viewModelScope.launch {
            val r = withContext(io) { runCatching(block) }
            toast = if (r.isSuccess) okMsg else "Falhou: ${r.exceptionOrNull()?.message ?: "erro"}"
        }
    }

    fun exportPdf(uri: Uri) {
        val s = session ?: return
        flush()
        val note = s.state.note
        val app = getApplication<Application>()
        val renderer = SheetRenderer { images.getBlocking(it) }
        runIo("PDF exportado") {
            (app.contentResolver.openOutputStream(uri) ?: error("sem acesso ao destino")).use { Export.pdf(note, renderer, it) }
        }
    }

    fun exportPng(uri: Uri) {
        val s = session ?: return
        flush()
        val note = s.state.note
        val page = s.state.pageIdx
        val app = getApplication<Application>()
        val renderer = SheetRenderer { images.getBlocking(it) }
        runIo("Imagem exportada") {
            (app.contentResolver.openOutputStream(uri) ?: error("sem acesso ao destino")).use { Export.png(note, page, renderer, it) }
        }
    }

    fun exportCsv(uri: Uri) {
        val s = session ?: return
        flush()
        val note = s.state.note
        val app = getApplication<Application>()
        runIo("Medidas exportadas (CSV)") {
            (app.contentResolver.openOutputStream(uri) ?: error("sem acesso ao destino")).use {
                it.write(Export.csv(note).toByteArray(Charsets.UTF_8))
            }
        }
    }

    fun backup(uri: Uri) {
        flush()
        val app = getApplication<Application>()
        runIo("Backup salvo") {
            (app.contentResolver.openOutputStream(uri) ?: error("sem acesso ao destino")).use { store.backupTo(it) }
        }
    }

    fun restore(uri: Uri) {
        val app = getApplication<Application>()
        viewModelScope.launch {
            val ok = withContext(io) {
                val input = app.contentResolver.openInputStream(uri) ?: return@withContext false
                store.restoreFrom(input)
            }
            if (ok) {
                session = null
                tabs.clear()
                index = store.loadIndex()
                recent.clear(); recent.addAll(store.loadReadings())
                screen = Screen.Library
                toast = "Backup restaurado"
            } else {
                toast = "Backup inválido: nada foi alterado"
            }
        }
    }

    override fun onCleared() {
        flush()
        ble.disconnect()
        io.close()
        super.onCleared()
    }

    companion object {
        const val MAX_RECENT = 30
    }
}
