package android.content.res

import java.util.Locale

/** Idioma do Windows (o mesmo papel do idioma do telefone). */
class Resources private constructor() {
    class Configuration { val locales = LocaleList() }
    class LocaleList { operator fun get(i: Int): Locale = Locale.getDefault() }
    val configuration = Configuration()
    companion object {
        private val sys = Resources()
        @JvmStatic fun getSystem(): Resources = sys
    }
}
