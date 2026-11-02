package br.com.arque.measure

/** Versão Windows: mesma regra do APK do site (3 dias de teste e desbloqueio por senha). */
object BuildConfig {
    const val PLAY = false
    const val TRIAL_DAYS = 3
    val VERSION_NAME: String = System.getProperty("arque.version") ?: (BuildConfig::class.java.`package`?.implementationVersion ?: "1.0")
    const val WINDOWS = true
}
