package br.com.arque.measure.desktop

import java.io.File

/**
 * Pastas do Arquemestre no Windows.
 * Dados do app: %LOCALAPPDATA%\Arque\Arquemestre (notas, fotos, projetos, agenda, editor de móveis).
 * O que o usuário vê: Documentos\Arquemestre (backups automáticos) e Imagens\Arquemestre.
 */
object Paths {
    private fun home() = File(System.getProperty("user.home"))

    val data: File by lazy {
        System.getProperty("arque.data")?.let { return@lazy File(it).apply { mkdirs() } }
        val win = System.getenv("LOCALAPPDATA")
        // pasta separada da do programa instalado (%LOCALAPPDATA%\Arquemestre): desinstalar não apaga os dados
        val base = if (!win.isNullOrBlank()) File(win, "Arque\\Arquemestre") else File(home(), ".arquemestre")
        base.apply { mkdirs() }
    }

    val documents: File by lazy {
        System.getProperty("arque.docs")?.let { return@lazy File(it).apply { mkdirs() } }
        File(knownFolder("Personal") ?: File(home(), "Documents"), "Arquemestre")
    }

    val pictures: File by lazy {
        System.getProperty("arque.pics")?.let { return@lazy File(it).apply { mkdirs() } }
        File(knownFolder("My Pictures") ?: File(home(), "Pictures"), "Arquemestre")
    }

    val downloads: File by lazy { File(home(), "Downloads").takeIf { it.isDirectory } ?: home() }

    /** Pasta "Documentos"/"Imagens" de verdade (pode estar no OneDrive ou em outro disco). */
    private fun knownFolder(name: String): File? = runCatching {
        if (!System.getProperty("os.name").lowercase().contains("win")) return null
        val p = ProcessBuilder("reg", "query", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders", "/v", name)
            .redirectErrorStream(true).start()
        val out = p.inputStream.bufferedReader().readText()
        p.waitFor()
        val line = out.lines().firstOrNull { it.trim().startsWith(name) } ?: return null
        val path = line.substringAfter("REG_SZ").trim()
        File(path).takeIf { it.isDirectory }
    }.getOrNull()
}
