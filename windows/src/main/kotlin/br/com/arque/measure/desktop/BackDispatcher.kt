package br.com.arque.measure.desktop

/** Pilha dos "Voltar": o último registrado e ativo responde à tecla Esc. */
object BackDispatcher {
    class Handler(val enabled: () -> Boolean, val onBack: () -> Unit)

    private val list = ArrayList<Handler>()

    fun add(h: Handler) = synchronized(list) { list.add(h) }
    fun remove(h: Handler) = synchronized(list) { list.remove(h) }

    /** true se alguma tela tratou o Voltar. */
    fun dispatch(): Boolean {
        val h = synchronized(list) { list.lastOrNull { runCatching { it.enabled() }.getOrDefault(false) } } ?: return false
        h.onBack()
        return true
    }

    fun hasHandler(): Boolean = synchronized(list) { list.any { runCatching { it.enabled() }.getOrDefault(false) } }
}
