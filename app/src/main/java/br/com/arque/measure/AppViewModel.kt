package br.com.arque.measure

import android.app.Application
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.FileProvider
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import br.com.arque.measure.ble.BoschBle
import br.com.arque.measure.data.Store
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.Client
import br.com.arque.measure.model.Index
import br.com.arque.measure.model.Paper
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.Room
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.SheetMeta
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
    data object Home : Screen
    data class ClientDetail(val clientId: String) : Screen
    data class RoomDetail(val roomId: String) : Screen
    data class Editor(val sheetId: String) : Screen
}

class AppViewModel(app: Application) : AndroidViewModel(app) {
    val store = Store(File(app.filesDir, "projects"))
    val images = ImageCache(store, viewModelScope)
    val ble = BoschBle(app)

    /** Uma única thread para toda escrita em disco: mantém a ordem dos salvamentos. */
    private val io = Executors.newSingleThreadExecutor().asCoroutineDispatcher()

    var index by mutableStateOf(store.loadIndex())
        private set
    var screen by mutableStateOf<Screen>(Screen.Home)
    var session by mutableStateOf<EditorSession?>(null)
        private set
    var toast by mutableStateOf<String?>(null)

    /** Leituras recebidas da trena que ainda não foram vinculadas a uma cota. */
    val recent = mutableStateListOf<Reading>().also { it.addAll(store.loadReadings()) }

    private var saveJob: Job? = null
    private var pendingCameraFile: File? = null

    init {
        viewModelScope.launch { ble.readings.collect { onReading(it) } }
    }

    // ---------- cadastro ----------

    private fun updateIndex(newIndex: Index) {
        index = newIndex
        viewModelScope.launch(io) { store.saveIndex(newIndex) }
    }

    fun addClient(name: String, city: String, address: String): String? {
        if (name.isBlank()) return null
        val c = Client(name = name.trim(), city = city.trim(), address = address.trim())
        updateIndex(index.copy(clients = index.clients + c))
        return c.id
    }

    fun updateClient(c: Client) {
        updateIndex(index.copy(clients = index.clients.map { if (it.id == c.id) c else it }))
    }

    fun deleteClient(id: String) {
        val roomIds = index.rooms.filter { it.clientId == id }.map { it.id }.toSet()
        val sheetIds = index.sheets.filter { it.roomId in roomIds }.map { it.id }
        updateIndex(
            Index(
                clients = index.clients.filter { it.id != id },
                rooms = index.rooms.filter { it.id !in roomIds },
                sheets = index.sheets.filter { it.roomId !in roomIds },
            ),
        )
        viewModelScope.launch(io) { sheetIds.forEach(store::deleteSheet); cleanupImages() }
    }

    fun addRoom(clientId: String, name: String) {
        if (name.isBlank()) return
        updateIndex(index.copy(rooms = index.rooms + Room(clientId = clientId, name = name.trim())))
    }

    fun deleteRoom(id: String) {
        val sheetIds = index.sheets.filter { it.roomId == id }.map { it.id }
        updateIndex(index.copy(rooms = index.rooms.filter { it.id != id }, sheets = index.sheets.filter { it.roomId != id }))
        viewModelScope.launch(io) { sheetIds.forEach(store::deleteSheet); cleanupImages() }
    }

    fun addSheet(roomId: String, name: String, paper: Paper, landscape: Boolean): Sheet {
        val sheet = Sheet(roomId = roomId, name = name.trim().ifBlank { "Folha" }, paper = paper, landscape = landscape)
        updateIndex(index.copy(sheets = index.sheets + SheetMeta(sheet.id, roomId, sheet.name)))
        viewModelScope.launch(io) { store.saveSheet(sheet) }
        return sheet
    }

    fun renameSheet(id: String, name: String) {
        if (name.isBlank()) return
        updateIndex(index.copy(sheets = index.sheets.map { if (it.id == id) it.copy(name = name.trim()) else it }))
        viewModelScope.launch(io) { store.loadSheet(id)?.let { store.saveSheet(it.copy(name = name.trim())) } }
    }

    fun deleteSheet(id: String) {
        updateIndex(index.copy(sheets = index.sheets.filter { it.id != id }))
        viewModelScope.launch(io) { store.deleteSheet(id); cleanupImages() }
    }

    private fun cleanupImages() {
        val keep = store.referencedImages()
        store.root.resolve("images").listFiles().orEmpty().filter { it.name !in keep }.forEach { it.delete() }
    }

    fun roomName(roomId: String) = index.rooms.firstOrNull { it.id == roomId }?.name ?: ""
    fun clientOfRoom(roomId: String) = index.rooms.firstOrNull { it.id == roomId }?.let { r -> index.clients.firstOrNull { it.id == r.clientId } }
    fun sheetsOfRoom(roomId: String) = index.sheets.filter { it.roomId == roomId }

    // ---------- editor ----------

    fun openSheet(id: String) {
        viewModelScope.launch {
            val sheet = withContext(io) { store.loadSheet(id) }
            if (sheet == null) {
                toast = "Não foi possível abrir a folha"
                return@launch
            }
            flush()
            session = EditorSession(sheet) { scheduleSave(it) }
            screen = Screen.Editor(id)
        }
    }

    fun openRelative(delta: Int) {
        val cur = session?.state?.sheet ?: return
        val list = sheetsOfRoom(cur.roomId)
        val i = list.indexOfFirst { it.id == cur.id }
        val target = list.getOrNull(i + delta) ?: return
        openSheet(target.id)
    }

    fun addSheetAfterCurrent() {
        val cur = session?.state?.sheet ?: return
        val n = sheetsOfRoom(cur.roomId).size + 1
        val s = addSheet(cur.roomId, "Folha $n", cur.paper, cur.landscape)
        openSheet(s.id)
    }

    fun closeEditor() {
        val roomId = session?.state?.sheet?.roomId
        flush()
        session = null
        screen = if (roomId != null) Screen.RoomDetail(roomId) else Screen.Home
    }

    /** Salvamento automático: espera uma pausa nas edições e grava a folha. */
    private fun scheduleSave(sheet: Sheet) {
        saveJob?.cancel()
        saveJob = viewModelScope.launch {
            delay(600)
            withContext(io) { store.saveSheet(sheet) }
        }
    }

    /** Grava agora (ao sair da folha ou do app). */
    fun flush() {
        val s = session ?: return
        saveJob?.cancel()
        store.saveSheet(s.state.sheet)
    }

    fun renderer(): SheetRenderer = SheetRenderer { images.get(it) }

    // ---------- fotos ----------

    private fun extFor(uri: Uri): String {
        val app = getApplication<Application>()
        val mime = app.contentResolver.getType(uri)
        return MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: "jpg"
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
            result.onSuccess { (name, w, h) -> s.addPhoto(name, w, h) }
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
            result.onSuccess { (name, w, h) -> s.addPhoto(name, w, h) }
                .onFailure { toast = "Não foi possível adicionar a foto" }
        }
    }

    // ---------- leituras da trena ----------

    private fun persistRecent() {
        val snapshot = recent.toList()
        viewModelScope.launch(io) { store.saveReadings(snapshot) }
    }

    private fun onReading(r: Reading) {
        val s = session
        if (s != null) {
            val unit = s.state.sheet.unit
            if (s.state.assignReading(r) != null) {
                toast = "Medida ${Units.format(r.mm, unit)} aplicada na cota"
                return
            }
        }
        recent.add(0, r)
        while (recent.size > MAX_RECENT) recent.removeAt(recent.lastIndex)
        persistRecent()
        toast = "Leitura ${Units.format(r.mm, s?.state?.sheet?.unit ?: br.com.arque.measure.model.LengthUnit.MM)} guardada. Selecione uma cota."
    }

    fun applyRecent(r: Reading) {
        val s = session ?: return
        if (s.state.assignReading(r) != null) {
            recent.remove(r)
            persistRecent()
            toast = "Medida ${Units.format(r.mm, s.state.sheet.unit)} aplicada na cota"
        } else {
            toast = "Selecione uma cota primeiro"
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

    private fun contextSheet(): Triple<Sheet, String, String>? {
        val s = session?.state?.sheet ?: return null
        flush()
        return Triple(s, clientOfRoom(s.roomId)?.name ?: "", roomName(s.roomId))
    }

    fun exportPdf(uri: Uri) {
        val (sheet, _, _) = contextSheet() ?: return
        val app = getApplication<Application>()
        val renderer = SheetRenderer { images.getBlocking(it) }
        runIo("PDF exportado") {
            (app.contentResolver.openOutputStream(uri) ?: error("sem acesso ao destino")).use { Export.pdf(sheet, renderer, it) }
        }
    }

    fun exportPng(uri: Uri) {
        val (sheet, _, _) = contextSheet() ?: return
        val app = getApplication<Application>()
        val renderer = SheetRenderer { images.getBlocking(it) }
        runIo("Imagem exportada") {
            (app.contentResolver.openOutputStream(uri) ?: error("sem acesso ao destino")).use { Export.png(sheet, renderer, it) }
        }
    }

    fun exportCsv(uri: Uri) {
        val (sheet, client, room) = contextSheet() ?: return
        val app = getApplication<Application>()
        runIo("Medidas exportadas (CSV)") {
            (app.contentResolver.openOutputStream(uri) ?: error("sem acesso ao destino")).use {
                it.write(Export.csv(client, room, sheet).toByteArray(Charsets.UTF_8))
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
                index = store.loadIndex()
                recent.clear(); recent.addAll(store.loadReadings())
                screen = Screen.Home
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
