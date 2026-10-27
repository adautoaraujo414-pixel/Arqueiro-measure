package br.com.arque.measure.model

import br.com.arque.measure.i18n.tr

/** Tipo do compromisso. */
enum class ApptKind(private val ptLabel: String, val icon: String, val argb: Long) {
    ENTREGA("Entrega", "🚚", 0xFF22A06B),
    VISITA("Visita", "🏠", 0xFF3B82F6),
    MEDICAO("Medição", "📏", 0xFFF5B400),
    INSTALACAO("Instalação", "🔧", 0xFFB35AE8),
    OUTRO("Outro", "📌", 0xFF9AA0A8);
    val label: String get() = tr(ptLabel)
}

/**
 * Compromisso da agenda. Pode apontar para um cliente (projeto salvo no editor de móveis), para uma nota
 * e para um orçamento. [remindMin] = quantos minutos antes avisar (0 = na hora).
 */
data class Appointment(
    val id: String = newId(),
    val kind: ApptKind = ApptKind.VISITA,
    val title: String = "",
    val startMs: Long = System.currentTimeMillis() + 3600_000L,
    val address: String = "",
    val notes: String = "",
    val clientName: String = "",
    val clientPhone: String = "",
    /** Id do projeto do cliente no editor de móveis (projects.json). */
    val projectId: String? = null,
    val noteId: String? = null,
    val quoteId: String? = null,
    val remindMin: List<Int> = listOf(60, 1440),
    val done: Boolean = false,
)

/** Opções de aviso oferecidas na tela (minutos antes). */
val REMIND_OPTIONS: List<Pair<Int, String>> get() = listOf(
    0 to tr("Na hora"), 15 to tr("15 min antes"), 30 to tr("30 min antes"), 60 to tr("1 h antes"),
    120 to tr("2 h antes"), 1440 to tr("1 dia antes"), 2880 to tr("2 dias antes"),
)

/** Cliente conhecido (projeto do editor, orçamento ou digitado). */
data class ClientRef(val name: String, val phone: String = "", val projectId: String? = null, val address: String = "")
