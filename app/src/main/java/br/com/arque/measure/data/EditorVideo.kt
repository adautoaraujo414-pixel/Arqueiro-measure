package br.com.arque.measure.data

import org.json.JSONObject
import java.io.File

/**
 * N13 (auditoria de 17/11): vídeo do editor gravado em arquivo (video_<id>.json), igual ao iOS (EditorVideoBackup.swift),
 * para entrar no backup completo e passar entre Android, iOS e Windows. Mesma regra de validação do iOS. Arquivo igual no Android e no Windows.
 */
object EditorVideo {
    const val MAX_BYTES = 64 * 1024 * 1024

    /** Grava o registro do vídeo; devolve false (sem gravar nada) se o registro não for um vídeo válido. */
    fun save(json: String, dir: File): Boolean = runCatching {
        if (json.length > MAX_BYTES * 4 / 3 + 1024 * 1024) return false
        val o = JSONObject(json)
        val id = o.optString("id")
        if (id.isEmpty() || id.length > 120 || !id.all { it.code < 128 && (it.isLetterOrDigit() || it == '_' || it == '-') }) return false
        if (o.optString("kind") != "video") return false
        val v = o.optString("videoData"); val comma = v.indexOf(',')
        if (comma < 0 || !v.startsWith("data:") || !v.substring(0, comma).endsWith(";base64")) return false
        val bytes = java.util.Base64.getDecoder().decode(v.substring(comma + 1))
        if (bytes.size > MAX_BYTES) return false
        dir.mkdirs()
        val f = File(dir, "video_$id.json"); val t = File(dir, f.name + ".tmp")
        t.writeText(json, Charsets.UTF_8)
        if (!t.renameTo(f)) { f.writeText(json, Charsets.UTF_8); t.delete() }
        true
    }.getOrDefault(false)
}
