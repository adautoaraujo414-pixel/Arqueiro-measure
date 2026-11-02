package br.com.arque.measure.i18n

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import org.json.JSONObject
import java.util.Locale

/**
 * Idioma do app. O texto original (português) é a chave; os outros idiomas vêm de
 * assets/i18n/<código>.json (o mesmo arquivo é usado pelo iOS e pelo editor de móveis).
 * Texto sem tradução continua em português (nunca some nada da tela).
 */
enum class AppLang(val code: String, val label: String) {
    AUTO("auto", ""),
    PT("pt", "Português"),
    EN("en", "English"),
    ES("es", "Español"),
}

object I18n {
    private const val PREFS = "arque.lang"
    private const val KEY = "lang"

    /** Idioma escolhido (AUTO = segue o telefone). */
    var choice by mutableStateOf(AppLang.AUTO)
        private set

    /** Idioma em uso ("pt", "en" ou "es"). Lido pela tela: trocar redesenha tudo. */
    var lang by mutableStateOf("pt")
        private set

    @Volatile private var dict: Map<String, String> = emptyMap()
    private var appCtx: Context? = null

    fun init(ctx: Context) {
        val c = ctx.applicationContext ?: ctx
        if (appCtx != null) return
        appCtx = c
        val saved = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, AppLang.AUTO.code)
        choice = AppLang.entries.firstOrNull { it.code == saved } ?: AppLang.AUTO
        apply(c)
    }

    fun set(ctx: Context, l: AppLang) {
        val c = ctx.applicationContext ?: ctx
        appCtx = c
        c.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, l.code).apply()
        choice = l
        apply(c)
    }

    /** Idioma do telefone: português e espanhol têm tradução; qualquer outro vira inglês. */
    fun deviceLang(): String {
        val sys = runCatching { android.content.res.Resources.getSystem().configuration.locales[0] }.getOrNull() ?: Locale.getDefault()
        return when (sys.language) {
            "pt" -> "pt"
            "es" -> "es"
            else -> "en"
        }
    }

    private fun apply(c: Context) {
        val code = if (choice == AppLang.AUTO) deviceLang() else choice.code
        dict = if (code == "pt") emptyMap() else load(c, code)
        lang = code
    }

    private fun load(c: Context, code: String): Map<String, String> = runCatching {
        val txt = c.assets.open("i18n/$code.json").bufferedReader(Charsets.UTF_8).use { it.readText() }
        val o = JSONObject(txt)
        val m = HashMap<String, String>(o.length() * 2)
        val it = o.keys()
        while (it.hasNext()) {
            val k = it.next()
            val v = o.optString(k)
            if (v.isNotEmpty()) m[k] = v
        }
        m as Map<String, String>
    }.getOrDefault(emptyMap())

    fun t(s: String): String {
        if (dict.isEmpty() || s.isEmpty()) return s
        dict[s]?.let { return it }
        // espaços nas pontas (ex.: "  Calculadora") ficam como estão
        val core = s.trim()
        if (core.length != s.length) dict[core]?.let { return s.replace(core, it) }
        return s
    }

    /** Datas no formato do idioma (EUA: mês/dia; 12 h). */
    fun dateFormat() = java.text.SimpleDateFormat(if (lang == "en") "MM/dd/yyyy" else "dd/MM/yyyy", locale)
    fun hourFormat() = java.text.SimpleDateFormat(if (lang == "en") "h:mm a" else "HH:mm", locale)
    fun dayFormat() = java.text.SimpleDateFormat(
        when (lang) { "en" -> "EEEE, MMMM d"; "es" -> "EEEE, d 'de' MMMM"; else -> "EEEE, dd 'de' MMMM" }, locale,
    )
    fun monthFormat() = java.text.SimpleDateFormat(if (lang == "en") "MMMM yyyy" else "MMMM 'de' yyyy", locale)
    fun shortDayFormat() = java.text.SimpleDateFormat(if (lang == "en") "EEE MM/dd" else "EEE dd/MM", locale)

    private fun deviceLocale(): Locale =
        runCatching { android.content.res.Resources.getSystem().configuration.locales[0] }.getOrNull() ?: Locale.getDefault()

    /**
     * Dinheiro na moeda do país do telefone (Brasil: "R$ 1.234,50"; EUA: "$1,234.50"; Espanha: "1.234,50 €").
     * Sem país definido, segue o idioma.
     */
    fun money(v: Double): String {
        val dev = deviceLocale()
        if (appCtx == null || dev.country == "BR" || (dev.country.isEmpty() && lang == "pt")) {
            return "R$ " + String.format(Locale("pt", "BR"), "%,.2f", v)
        }
        val loc = if (dev.country.isEmpty()) (if (lang == "es") Locale("es", "MX") else Locale.US) else dev
        return runCatching { java.text.NumberFormat.getCurrencyInstance(loc).format(v) }
            .getOrElse { "$" + String.format(Locale.US, "%,.2f", v) }
    }

    /** Símbolo da moeda usada em [money] ("R$", "$", "€"...). */
    fun currencySymbol(): String {
        val dev = deviceLocale()
        if (appCtx == null || dev.country == "BR" || (dev.country.isEmpty() && lang == "pt")) return "R$"
        val loc = if (dev.country.isEmpty()) (if (lang == "es") Locale("es", "MX") else Locale.US) else dev
        return runCatching { java.util.Currency.getInstance(loc).getSymbol(loc) }.getOrDefault("$")
    }

    /** Locale para datas e números no idioma em uso. */
    val locale: Locale
        get() = when (lang) {
            "en" -> Locale.US
            "es" -> Locale("es")
            else -> Locale("pt", "BR")
        }
}

/** Traduz um texto do app (a chave é o texto em português). */
fun tr(s: String): String = I18n.t(s)

/** Traduz com valores: tr("Folha {0} de {1}", 2, 5). */
fun tr(s: String, vararg a: Any?): String {
    var r = I18n.t(s)
    a.forEachIndexed { i, v -> r = r.replace("{$i}", v?.toString() ?: "") }
    return r
}
