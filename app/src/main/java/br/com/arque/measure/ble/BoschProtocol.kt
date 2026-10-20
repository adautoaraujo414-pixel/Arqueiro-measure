package br.com.arque.measure.ble

import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.roundToLong

/**
 * Protocolo BLE das trenas Bosch com Bluetooth (GLM 50 C, GLM 100 C, GLM 50-27 CG etc.).
 *
 * ATENÇÃO — NÃO VALIDADO COM EQUIPAMENTO REAL.
 * Bosch não publica a especificação. Os UUIDs e o comando de "autosync" abaixo vêm de
 * engenharia reversa da comunidade e precisam ser confirmados com uma trena física.
 * O formato do quadro de medida (float32 little-endian em metros dentro de um quadro que
 * começa com 0xC0) é tratado por heurística em [parseMeasurementMeters]. Por isso o app:
 *  - mostra todo quadro bruto em hexadecimal na tela de diagnóstico;
 *  - marca toda leitura com o hexadecimal original;
 *  - exibe um aviso de "protocolo não verificado".
 * Se a trena real enviar outro formato, só este arquivo precisa mudar.
 */
object BoschProtocol {
    const val SERVICE_UUID = "00005301-0000-0041-4c50-574953450000"
    const val CHARACTERISTIC_UUID = "00005302-0000-0041-4c50-574953450000"
    const val CCCD_UUID = "00002902-0000-1000-8000-00805f9b34fb"

    /** Pede à trena que envie cada medida automaticamente (comando "autosync"). */
    val ENABLE_AUTOSYNC: ByteArray =
        byteArrayOf(0xC0.toByte(), 0x55, 0x02, 0x01, 0x00, 0x1A)

    /** Nomes anunciados por trenas Bosch (filtro de varredura; a confirmação final é o serviço GATT). */
    val NAME_REGEX = Regex("(?i)(GLM|PLR|GCL|GRL|GIM|GTL|BLAZE|BOSCH)")

    const val MIN_METERS = 0.005f
    const val MAX_METERS = 300f

    /**
     * Procura, em um quadro [0xC0, cmd, len, payload...], um float32 little-endian
     * que seja uma distância plausível em metros. Retorna null se não houver.
     */
    fun parseMeasurementMeters(frame: ByteArray): Float? {
        if (frame.size < 8) return null
        if (frame[0] != 0xC0.toByte()) return null
        val payload = frame.copyOfRange(3, frame.size)
        if (payload.size < 4) return null
        val bb = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN)
        for (off in 0..payload.size - 4) {
            val f = bb.getFloat(off)
            if (f.isFinite() && f in MIN_METERS..MAX_METERS) return f
        }
        return null
    }

    /** Converte para milímetros inteiros (resolução de exibição da trena é 1 mm). */
    fun metersToMm(m: Float): Double = (m.toDouble() * 1000.0).roundToLong().toDouble()

    /** Retorna a medida em mm se o quadro parecer uma leitura, senão null. */
    fun parseMm(frame: ByteArray): Double? = parseMeasurementMeters(frame)?.let(::metersToMm)

    fun toHex(bytes: ByteArray): String = bytes.joinToString(" ") { "%02X".format(it) }
}
