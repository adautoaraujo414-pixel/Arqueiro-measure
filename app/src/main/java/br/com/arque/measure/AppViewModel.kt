package br.com.arque.measure

import br.com.arque.measure.i18n.tr

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
    data object Quotes : Screen
    data object Agenda : Screen
    /** Editor de móveis (ambiente, módulos, pedra, eletrodomésticos, ripado, clientes). */
    data object Moveis : Screen
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

    fun changeTrenaHidden(v: Boolean) {
        trenaHidden = v
        uiPrefs.edit().putBoolean("trenaHidden", v).apply()
    }

    fun changeTrenaScale(s: Float) {
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
        // nota nova ligada a um projeto já nasce com o nome do cliente
        val proj = lastProjectId?.let { pid -> moveisProjects().firstOrNull { it.id == pid } }?.takeIf { !defaultProjName(it) }
        val n = Note(name = proj?.name ?: tr("Nota {0}", index.notes.count { !it.trash } + 1), folderId = folder)
        lastProjectId?.let { pid ->
            links.edit().putString(n.id, pid).apply()
            if (proj != null) linkNames.edit().putString(n.id, proj.name).apply()
            projVersion++
        }
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
                    src.copy(id = newId(), name = src.name + tr(" (cópia)"), createdMs = System.currentTimeMillis(), pinned = false, trash = false)
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
            toast = tr("Nota bloqueada. Remova o bloqueio no menu da nota.")
            return
        }
        if (session?.state?.note?.id == id) { screen = Screen.Editor; return }
        viewModelScope.launch {
            val note = withContext(io) { store.loadNote(id) }
            if (note == null) {
                toast = tr("Não foi possível abrir a nota")
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

    fun tabName(id: String) = index.notes.firstOrNull { it.id == id }?.name ?: tr("Nota")

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

    private val thumbRenderer by lazy { SheetRenderer { images.peek(it) } }
    private fun thumbFile(id: String) = File(store.root, "thumbs/$id.png")

    private fun writeThumb(note: Note) {
        val w = 240
        val h = (w * Sheet.H / Sheet.W).toInt()
        // desenha a miniatura fora da thread principal (não trava a digitação nem o traço)
        viewModelScope.launch(io) {
            val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            runCatching {
                val c = Canvas(bmp)
                c.drawColor(Color.WHITE)
                val k = w / Sheet.W
                c.scale(k, k)
                thumbRenderer.draw(c, note.pages.first(), note.unit, null, 1f, withPaper = false)
            }
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

    /** Miniaturas já lidas (a lista de notas não lê arquivo na thread principal). */
    private val thumbCache = android.util.LruCache<String, Pair<Long, ImageBitmap>>(160)

    fun cachedThumb(id: String): ImageBitmap? = thumbCache.get(id)?.second

    /** Lê a miniatura fora da thread principal; só decodifica de novo se o arquivo mudou. */
    suspend fun loadThumbAsync(id: String): ImageBitmap? = withContext(Dispatchers.IO) {
        val f = thumbFile(id)
        if (!f.exists()) return@withContext null
        val lm = f.lastModified()
        thumbCache.get(id)?.let { if (it.first == lm) return@withContext it.second }
        val b = runCatching { BitmapFactory.decodeFile(f.path)?.asImageBitmap() }.getOrNull() ?: return@withContext null
        thumbCache.put(id, lm to b)
        b
    }

    /** Grava agora (ao sair da nota ou do app). */
    fun flush() {
        val s = session ?: return
        saveJob?.cancel()
        val n = s.state.note
        // grava em segundo plano (fila única: a ordem das gravações é mantida) — fechar a nota não trava
        viewModelScope.launch(io + kotlinx.coroutines.NonCancellable) { runCatching { store.saveNote(n) } }
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
                    val input = app.contentResolver.openInputStream(uri) ?: error(tr("sem acesso à foto"))
                    val name = store.importImage(input, extFor(uri))
                    val size = ImageCache.orientedSize(store.imageFile(name)) ?: error(tr("imagem inválida"))
                    Triple(name, size.first, size.second)
                }
            }
            result.onSuccess { (name, w, h) -> placePhoto(s, name, w, h) }
                .onFailure { toast = tr("Não foi possível adicionar a foto") }
        }
    }

    /** Várias fotos de uma vez: importa todas (uma por vez, sem travar) e distribui 2 por folha. */
    fun addPhotosFromUris(uris: List<Uri>) {
        val s = session ?: return
        if (uris.isEmpty()) { photoToNewPage = false; return }
        if (uris.size == 1) { addPhotoFromUri(uris[0]); return }
        val app = getApplication<Application>()
        val newPage = photoToNewPage
        photoToNewPage = false
        toast = tr("Adicionando {0} fotos…", uris.size)
        viewModelScope.launch {
            val ok = mutableListOf<Triple<String, Int, Int>>()
            var fail = 0
            for (u in uris) {
                val r = withContext(io) {
                    runCatching {
                        val input = app.contentResolver.openInputStream(u) ?: error(tr("sem acesso à foto"))
                        val name = store.importImage(input, extFor(u))
                        val size = ImageCache.orientedSize(store.imageFile(name)) ?: error(tr("imagem inválida"))
                        Triple(name, size.first, size.second)
                    }
                }
                r.onSuccess { ok += it }.onFailure { fail++ }
            }
            val placed = s.addPhotos(ok, newPage)
            toast = tr("{0} fotos adicionadas", placed) + (if (fail > 0) tr(" · {0} não abriram", fail) else "") +
                (if (placed < ok.size) tr(" · limite de folhas atingido") else "")
        }
    }

    /** Pergunta depois de cada foto da câmera: tirar outra ou terminar. */
    var askAnotherPhoto by mutableStateOf(false)

    /** Guarda a foto da câmera também na galeria do telefone (Imagens/ArqueMeasure): não se perde nunca. */
    private fun saveToGallery(f: File) {
        if (android.os.Build.VERSION.SDK_INT < 29) return
        val app = getApplication<Application>()
        runCatching {
            val cv = android.content.ContentValues().apply {
                put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, f.name)
                put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, "Pictures/ArqueMeasure")
            }
            val uri = app.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, cv) ?: return
            app.contentResolver.openOutputStream(uri)?.use { o -> f.inputStream().use { it.copyTo(o) } }
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
                    saveToGallery(f)
                    val name = store.importImage(f.inputStream(), "jpg")
                    f.delete()
                    val size = ImageCache.orientedSize(store.imageFile(name)) ?: error(tr("imagem inválida"))
                    Triple(name, size.first, size.second)
                }
            }
            result.onSuccess { (name, w, h) -> placePhoto(s, name, w, h); askAnotherPhoto = true }
                .onFailure { toast = tr("Não foi possível adicionar a foto") }
        }
    }

    // ---------- leituras da trena (única origem de medidas) ----------

    private fun persistRecent() {
        val snapshot = recent.toList()
        viewModelScope.launch(io) { store.saveReadings(snapshot) }
    }

    /** Leitura nova: se há uma cota selecionada, grava nela e avança; senão vira um "chip" na barra. */
    /** Campo esperando a próxima leitura da trena (editor do móvel). */
    var measureArmed by mutableStateOf<String?>(null)
        private set
    private var measureCb: ((Double) -> Unit)? = null

    /** Preenche o campo com a leitura mais nova da fila; sem leitura, fica esperando a próxima. */
    fun armMeasure(key: String, cb: (Double) -> Unit) {
        val r = recent.firstOrNull()
        if (r != null) {
            recent.remove(r)
            persistRecent()
            cb(r.mm)
            return
        }
        measureArmed = key
        measureCb = cb
    }

    fun cancelMeasure() {
        measureArmed = null
        measureCb = null
    }

    /** Quem recebe as leituras da trena enquanto o editor de móveis está aberto. */
    var moveisSink: ((Double) -> Unit)? = null

    private fun onReading(r: Reading) {
        val sink = moveisSink
        if (sink != null && screen == Screen.Moveis) {
            sink(r.mm)
            return
        }
        val cb = measureCb
        if (cb != null) {
            measureCb = null
            measureArmed = null
            cb(r.mm)
            return
        }
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
            toast = tr("Toque numa seta de cota primeiro")
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
            toast = if (r.isSuccess) okMsg else tr("Falhou: {0}", r.exceptionOrNull()?.message ?: tr("erro"))
        }
    }

    // ---------- agenda ----------

    var appointments by mutableStateOf(store.loadAgenda().sortedBy { it.startMs })
        private set
    /** Compromisso a mostrar aberto ao entrar na tela da agenda (toque na notificação ou no atalho). */
    var agendaOpenId by mutableStateOf<String?>(null)
    /** Projeto de cliente a abrir assim que o editor de móveis carregar. */
    var pendingProject by mutableStateOf<String?>(null)

    fun saveAppt(a: br.com.arque.measure.model.Appointment) {
        appointments = (if (appointments.any { it.id == a.id }) appointments.map { if (it.id == a.id) a else it } else appointments + a).sortedBy { it.startMs }
        val snap = appointments
        viewModelScope.launch(io) { store.saveAgenda(snap) }
        br.com.arque.measure.agenda.AgendaReminders.schedule(getApplication(), a)
    }

    fun deleteAppt(id: String) {
        appointments.firstOrNull { it.id == id }?.let { br.com.arque.measure.agenda.AgendaReminders.cancel(getApplication(), it) }
        appointments = appointments.filter { it.id != id }
        val snap = appointments
        viewModelScope.launch(io) { store.saveAgenda(snap) }
    }

    fun openAppointment(id: String) {
        agendaOpenId = id
        screen = Screen.Agenda
    }

    /** Clientes conhecidos: projetos salvos no editor de móveis + nomes dos orçamentos. */
    fun knownClients(): List<br.com.arque.measure.model.ClientRef> {
        val proj = runCatching {
            val f = File(getApplication<Application>().filesDir, "moveis/projects.json")
            if (f.exists()) br.com.arque.measure.data.AgendaJson.clientsFromProjects(f.readText()) else emptyList()
        }.getOrDefault(emptyList())
        val have = proj.map { it.name.lowercase() }.toSet()
        val fromQuotes = quotes.map { it.clientName.trim() }.filter { it.isNotBlank() && it.lowercase() !in have }.distinct()
            .map { br.com.arque.measure.model.ClientRef(it) }
        return (proj + fromQuotes).sortedBy { it.name.lowercase() }
    }

    // ---------- projetos do editor de móveis (ficam salvos, como as notas) ----------
    var projVersion by mutableIntStateOf(0)
    /** Último projeto aberto no editor nesta sessão (nota nova criada depois se vincula a ele). */
    var lastProjectId: String? = null
    var pendingNewProject by mutableStateOf(false)
    private val links by lazy { getApplication<Application>().getSharedPreferences("arque.links", android.content.Context.MODE_PRIVATE) }

    fun moveisProjects(): List<br.com.arque.measure.data.MoveisProjects.P> = br.com.arque.measure.data.MoveisProjects.list(getApplication())
    fun newMoveisProject() { pendingProject = null; pendingNewProject = true; screen = Screen.Moveis }
    fun deleteMoveisProject(id: String) { br.com.arque.measure.data.MoveisProjects.delete(getApplication(), id); if (lastProjectId == id) lastProjectId = null; projVersion++ }
    fun renameMoveisProject(id: String, name: String) { br.com.arque.measure.data.MoveisProjects.rename(getApplication(), id, name); projVersion++ }
    fun linkedProject(noteId: String): String? = links.getString(noteId, null)
    fun linkProject(noteId: String, projectId: String?) {
        links.edit().apply { if (projectId == null) remove(noteId) else putString(noteId, projectId) }.apply()
        if (projectId == null) linkNames.edit().remove(noteId).apply()
        else syncPair(noteId, projectId, moveisProjects())
        projVersion++
    }

    // ---------- nota e projeto do mesmo cliente ficam com o mesmo nome ----------

    /** Último nome em comum de cada par nota↔projeto (pra saber qual dos dois foi renomeado depois). */
    private val linkNames by lazy { getApplication<Application>().getSharedPreferences("arque.linknames", android.content.Context.MODE_PRIVATE) }
    private val defaultNoteRx = Regex("""^(nota|note)(\s+\d+)?(\s*\((cópia|copia|copy)\))*$""", RegexOption.IGNORE_CASE)
    private val autoProjRx = Regex("""^(projeto|project|proyecto)\s+\d{1,2}/\d{1,2}""", RegexOption.IGNORE_CASE)
    private fun defaultNoteName(s: String) = s.isBlank() || defaultNoteRx.matches(s.trim())
    private fun defaultProjName(p: br.com.arque.measure.data.MoveisProjects.P) =
        p.auto || p.name.isBlank() || p.name == tr("Projeto sem nome") || p.name == "Projeto sem nome" || autoProjRx.containsMatchIn(p.name)

    /**
     * Junta o nome da nota e do projeto ligados: o nome de cliente (o que não é "Nota 3" nem "Projeto 26/10 19:46")
     * vale pros dois. Se os dois têm nome, quem foi renomeado por último manda; na primeira vez, o da nota.
     * Devolve true se mudou algo.
     */
    private fun syncPair(noteId: String, pid: String, projs: List<br.com.arque.measure.data.MoveisProjects.P>): Boolean {
        val n = index.notes.firstOrNull { it.id == noteId && !it.trash } ?: return false
        val p = projs.firstOrNull { it.id == pid } ?: return false
        val nName = n.name.trim(); val pName = p.name.trim()
        val nDef = defaultNoteName(nName); val pDef = defaultProjName(p)
        val last = linkNames.getString(noteId, null)
        val target = when {
            nName == pName -> if (nDef && pDef) null else nName
            last != null && nName == last && !pDef -> pName // o projeto foi renomeado
            last != null && pName == last && !nDef -> nName // a nota foi renomeada
            !nDef -> nName
            !pDef -> pName
            else -> null
        } ?: return false
        var changed = false
        if (nName != target) { renameNoteKeepOpen(noteId, target); changed = true }
        if (pName != target || p.auto) { br.com.arque.measure.data.MoveisProjects.rename(getApplication(), pid, target); changed = true }
        linkNames.edit().putString(noteId, target).apply()
        return changed
    }

    /** Confere todos os pares nota↔projeto (ao abrir a biblioteca, depois de renomear algo). */
    fun syncLinkedNames() {
        val projs = moveisProjects()
        var changed = false
        links.all.forEach { (noteId, v) -> (v as? String)?.let { if (syncPair(noteId, it, projs)) changed = true } }
        if (changed) projVersion++
    }

    /** Renomeia a nota sem fechar o editor se ela estiver aberta. */
    private fun renameNoteKeepOpen(id: String, name: String) {
        val s = session
        if (s != null && s.state.note.id == id) {
            s.state.renameNoteSilently(name)
            upsertMeta(s.state.note)
            return
        }
        // o índice muda na hora (a próxima conferência já vê o nome novo); o arquivo grava em segundo plano
        updateIndex(index.copy(notes = index.notes.map { if (it.id == id) it.copy(name = name) else it }))
        viewModelScope.launch(io) { runCatching { store.loadNote(id)?.copy(name = name)?.let { store.saveNote(it) } } }
    }
    fun notesOfProject(projectId: String): List<String> = links.all.filter { it.value == projectId }.keys.toList()

    /** Abre o projeto do cliente no editor de móveis. */
    fun openProject(projectId: String) {
        pendingProject = projectId
        screen = Screen.Moveis
    }

    init {
        br.com.arque.measure.agenda.AgendaReminders.ensureChannel(app)
        br.com.arque.measure.agenda.AgendaReminders.scheduleAll(app, appointments)
    }

    // ---------- orçamentos ----------

    var company by mutableStateOf(store.loadCompany())
        private set
    var quotes by mutableStateOf(store.loadQuotes())
        private set

    /** Logo da empresa (sai no cabeçalho do orçamento). */
    var logoBmp by mutableStateOf<Bitmap?>(runCatching { BitmapFactory.decodeFile(store.logoFile.path) }.getOrNull())
        private set

    fun setLogo(uri: Uri) {
        val app = getApplication<Application>()
        viewModelScope.launch {
            val bmp = withContext(io) {
                runCatching {
                    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    app.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
                    var sample = 1
                    while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= 800) sample *= 2
                    val raw = app.contentResolver.openInputStream(uri)?.use {
                        BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
                    } ?: error(tr("imagem inválida"))
                    val k = 800f / maxOf(raw.width, raw.height)
                    val b = if (k < 1f) Bitmap.createScaledBitmap(raw, (raw.width * k).toInt().coerceAtLeast(1), (raw.height * k).toInt().coerceAtLeast(1), true) else raw
                    store.logoFile.outputStream().use { b.compress(Bitmap.CompressFormat.PNG, 100, it) }
                    b
                }
            }
            bmp.onSuccess { logoBmp = it }.onFailure { toast = tr("Não consegui abrir a imagem") }
        }
    }

    fun clearLogo() {
        logoBmp = null
        viewModelScope.launch(io) { store.logoFile.delete() }
    }

    fun saveCompany(c: br.com.arque.measure.model.Company) {
        company = c
        viewModelScope.launch(io) { store.saveCompany(c) }
    }

    /** Cria ou atualiza o orçamento (grava na hora). */
    fun saveQuote(q: br.com.arque.measure.model.Quote) {
        quotes = if (quotes.any { it.id == q.id }) quotes.map { if (it.id == q.id) q else it } else listOf(q) + quotes
        val snap = quotes
        viewModelScope.launch(io) { store.saveQuotes(snap) }
    }

    fun deleteQuote(id: String) {
        quotes = quotes.filter { it.id != id }
        val snap = quotes
        viewModelScope.launch(io) { store.saveQuotes(snap) }
    }

    /** Gera o PDF do orçamento na pasta temporária e devolve o Uri para compartilhar. */
    fun buildQuotePdf(q: br.com.arque.measure.model.Quote, onReady: (Uri) -> Unit) {
        if (q.includeDrawing) flush()
        val app = getApplication<Application>()
        val comp = company
        val logo = logoBmp
        val renderer = SheetRenderer { images.getBlocking(it) }
        viewModelScope.launch {
            val r = withContext(io) {
                runCatching {
                    val note = if (q.includeDrawing && q.noteId != null) store.loadNote(q.noteId) else null
                    val dir = File(app.cacheDir, "quotes").apply { mkdirs() }
                    dir.listFiles()?.forEach { it.delete() }
                    val safe = q.clientName.ifBlank { "cliente" }.replace(Regex("[^A-Za-z0-9À-ÿ]+"), "_").take(30)
                    val f = File(dir, "Orcamento_$safe.pdf")
                    f.outputStream().use { QuotePdf.write(comp, q, note, renderer, it, logo) }
                    FileProvider.getUriForFile(app, "${app.packageName}.fileprovider", f)
                }
            }
            r.onSuccess(onReady).onFailure { toast = tr("Falhou: {0}", it.message ?: tr("erro ao gerar o PDF")) }
        }
    }

    fun exportPdf(uri: Uri) {
        val s = session ?: return
        flush()
        val note = s.state.note
        val app = getApplication<Application>()
        val renderer = SheetRenderer { images.getBlocking(it) }
        runIo(tr("PDF exportado")) {
            (app.contentResolver.openOutputStream(uri) ?: error(tr("sem acesso ao destino"))).use { Export.pdf(note, renderer, it) }
        }
    }

    fun exportPng(uri: Uri) {
        val s = session ?: return
        flush()
        val note = s.state.note
        val page = s.state.pageIdx
        val app = getApplication<Application>()
        val renderer = SheetRenderer { images.getBlocking(it) }
        runIo(tr("Imagem exportada")) {
            (app.contentResolver.openOutputStream(uri) ?: error(tr("sem acesso ao destino"))).use { Export.png(note, page, renderer, it) }
        }
    }

    fun exportCsv(uri: Uri) {
        val s = session ?: return
        flush()
        val note = s.state.note
        val app = getApplication<Application>()
        runIo(tr("Medidas exportadas (CSV)")) {
            (app.contentResolver.openOutputStream(uri) ?: error(tr("sem acesso ao destino"))).use {
                it.write(Export.csv(note).toByteArray(Charsets.UTF_8))
            }
        }
    }

    fun backup(uri: Uri) {
        flush()
        val app = getApplication<Application>()
        runIo(tr("Backup salvo")) {
            (app.contentResolver.openOutputStream(uri) ?: error(tr("sem acesso ao destino"))).use { br.com.arque.measure.data.DataBackup.fullBackup(app, it) }
        }
    }

    fun restore(uri: Uri) {
        val app = getApplication<Application>()
        viewModelScope.launch {
            // backup completo (formato novo): aplica no próximo início e reinicia o app
            val full = withContext(io) {
                runCatching {
                    val inp = app.contentResolver.openInputStream(uri) ?: return@runCatching false
                    br.com.arque.measure.data.DataBackup.stage(app, inp)
                }.getOrDefault(false)
            }
            if (full) {
                flush()
                toast = tr("Restaurando… o app vai reiniciar")
                kotlinx.coroutines.delay(600)
                br.com.arque.measure.data.DataBackup.restart(app)
                return@launch
            }
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
                toast = tr("Backup restaurado")
            } else {
                toast = tr("Backup inválido: nada foi alterado")
            }
        }
    }

    // ---- atualização do app sem perder dados ----
    var updateState by mutableStateOf<String?>(null)
    var updateReady by mutableStateOf<java.io.File?>(null)

    /** Versão nova encontrada sozinha (pergunta se quer atualizar). */
    var updateOffer by mutableStateOf<br.com.arque.measure.data.AppUpdater.Release?>(null)
    private var lastAutoCheck = 0L

    /** Verifica em silêncio (ao abrir o app e ao voltar pra ele, no máximo a cada 30 min). */
    fun autoCheckUpdate() {
        if (br.com.arque.measure.BuildConfig.PLAY) return // no Google Play quem atualiza é a loja
        val now = System.currentTimeMillis()
        if (now - lastAutoCheck < 30 * 60_000L || updateState != null) return
        lastAutoCheck = now
        val app = getApplication<Application>()
        viewModelScope.launch {
            val rel = withContext(kotlinx.coroutines.Dispatchers.IO) { runCatching { br.com.arque.measure.data.AppUpdater.latest() }.getOrNull() } ?: return@launch
            val mine = br.com.arque.measure.data.AppUpdater.installedNumber(app)
            val skipped = app.getSharedPreferences("arque.upd", android.content.Context.MODE_PRIVATE).getInt("skip", 0)
            if (rel.number > mine && rel.number != skipped) updateOffer = rel
        }
    }

    fun skipUpdate() {
        val r = updateOffer ?: return
        getApplication<Application>().getSharedPreferences("arque.upd", android.content.Context.MODE_PRIVATE).edit().putInt("skip", r.number).apply()
        updateOffer = null
    }

    /** Aceitou a versão nova: baixa e abre o instalador direto. */
    fun acceptUpdate() { updateOffer = null; checkUpdate(autoInstall = true) }

    fun checkUpdate(autoInstall: Boolean = false) {
        if (br.com.arque.measure.BuildConfig.PLAY) return
        val app = getApplication<Application>()
        updateReady = null
        updateState = tr("Procurando versão nova…")
        viewModelScope.launch {
            val r = withContext(kotlinx.coroutines.Dispatchers.IO) { runCatching { br.com.arque.measure.data.AppUpdater.latest() } }
            val rel = r.getOrNull()
            if (rel == null) { updateState = tr("Não consegui verificar agora (sem internet?)."); return@launch }
            val mine = br.com.arque.measure.data.AppUpdater.installedNumber(app)
            if (rel.number <= mine) { updateState = tr("Você já está na versão mais nova (apk-{0}).", mine); return@launch }
            flush()
            updateState = tr("Salvando seus dados antes de atualizar…")
            withContext(io) { runCatching { br.com.arque.measure.data.DataBackup.autoBackup(app, force = true) } }
            updateState = tr("Baixando apk-{0}…", rel.number)
            val f = withContext(kotlinx.coroutines.Dispatchers.IO) {
                runCatching { br.com.arque.measure.data.AppUpdater.download(app, rel) { p -> viewModelScope.launch(kotlinx.coroutines.Dispatchers.Main) { updateState = tr("Baixando apk-{0}… {1}%", rel.number, p) } } }
            }
            val apk = f.getOrNull()
            if (apk == null) { updateState = tr("Falhou o download: {0}", f.exceptionOrNull()?.message); return@launch }
            updateReady = apk
            updateState = tr("apk-{0} pronto. Toque em Instalar: seus dados continuam (cópia também em Downloads/ArqueMeasure).", rel.number)
            if (autoInstall) installUpdate()
        }
    }

    /** Editor de móveis aberto só pra ver o projeto de outro celular (Bluetooth). */
    var moveisView by mutableStateOf(false)

    // ---- teste de 2 dias / desbloqueio ----
    var licLocked by mutableStateOf(false)
    var showWelcome by mutableStateOf(false)
    var trialLeft by mutableStateOf("")
    var licUnlocked by mutableStateOf(false)

    fun checkLicense() {
        val app = getApplication<Application>()
        if (br.com.arque.measure.license.License.firstRun(app)) showWelcome = true
        licUnlocked = br.com.arque.measure.license.License.isUnlocked(app)
        licLocked = br.com.arque.measure.license.License.isLocked(app)
        trialLeft = if (licUnlocked) "" else br.com.arque.measure.license.License.leftLabel(app)
        if (licLocked) flush()
    }

    /** Preço da compra no Google Play (some até a loja responder). */
    var storePrice by mutableStateOf<String?>(null)
    private var storeStarted = false

    fun startStore() {
        if (!br.com.arque.measure.license.StoreBilling.AVAILABLE || storeStarted) return
        storeStarted = true
        br.com.arque.measure.license.StoreBilling.start(getApplication()) {
            viewModelScope.launch(kotlinx.coroutines.Dispatchers.Main) {
                storePrice = br.com.arque.measure.license.StoreBilling.price()
                checkLicense()
            }
        }
    }

    private val storeMsg: (String) -> Unit = { m -> viewModelScope.launch(kotlinx.coroutines.Dispatchers.Main) { toast = m; checkLicense() } }
    fun buyStore(a: android.app.Activity) = br.com.arque.measure.license.StoreBilling.buy(a, storeMsg)
    fun restoreStore() = br.com.arque.measure.license.StoreBilling.restore(getApplication(), storeMsg)

    fun unlock(code: String): Boolean {
        val ok = br.com.arque.measure.license.License.tryUnlock(getApplication(), code)
        if (ok) { licLocked = false; licUnlocked = true; trialLeft = ""; toast = tr("App desbloqueado. Obrigado!") }
        return ok
    }

    fun installUpdate() {
        val app = getApplication<Application>()
        val apk = updateReady ?: return
        if (!br.com.arque.measure.data.AppUpdater.canInstall(app)) {
            updateState = tr("Libere \"instalar apps desta fonte\" pro Arque Measure e toque em Instalar de novo.")
            br.com.arque.measure.data.AppUpdater.askInstallPermission(app)
            return
        }
        br.com.arque.measure.data.AppUpdater.install(app, apk)
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
