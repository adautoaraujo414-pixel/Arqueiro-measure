package br.com.arque.measure.ble

import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.roundToLong

/**
 * Protocolo BLE das trenas Bosch com Bluetooth (GLM 50 C, GLM 100 C, GLM 50-27 CG etc.).
 *
 * ATENÇÃO — NÃO VALIDADO COM A NOSSA TRENA.
 * Bosch não publica a especificação. O que está aqui vem de engenharia reversa da comunidade
 * (CaveSurvey #150, Nordic DevZone, EEVblog) e as fontes divergem entre modelos:
 *  - serviço anunciado 0xFDE8 ("Robert Bosch GmbH"), característica 02a6c0d2-0451-4000-b000-fb3210111989;
 *  - serviço 02a6c0d0-0451-4000-b000-fb3210111989, característica 02a6c0d1-…;
 * Por isso o app NÃO fixa um único UUID: procura qualquer serviço/característica Bosch,
 * liga indicações em todas que permitem e escreve o comando "autosync" na que aceita escrita.
 * Tudo que a trena expõe e todo quadro recebido aparecem na tela de diagnóstico.
 *
 * Quadro de medida visto pela comunidade: C0 55 10 06 .. .. .. [float32 LE metros] 00.. CRC
 *  (byte 3 = 0x06 leitura válida, 0x02 inválida; bytes 7..10 = distância em metros).
 */
object BoschProtocol {
    /** Serviço anunciado pelas trenas Bosch (UUID 16 bits 0xFDE8). */
    const val SERVICE_FDE8 = "0000fde8-0000-1000-8000-00805f9b34fb"
    const val SERVICE_MT = "02a6c0d0-0451-4000-b000-fb3210111989"
    /** UUIDs antigos usados na primeira versão do app (mantidos só como candidato extra). */
    const val SERVICE_LEGACY = "00005301-0000-0041-4c50-574953450000"
    const val CHARACTERISTIC_LEGACY = "00005302-0000-0041-4c50-574953450000"
    const val CCCD_UUID = "00002902-0000-1000-8000-00805f9b34fb"
    private const val VENDOR_SUFFIX = "-0451-4000-b000-fb3210111989"

    val KNOWN_SERVICES = setOf(SERVICE_FDE8, SERVICE_MT, SERVICE_LEGACY)

    fun isBoschService(uuid: String): Boolean {
        val u = uuid.lowercase()
        return u in KNOWN_SERVICES || u.endsWith(VENDOR_SUFFIX)
    }

    fun isBoschCharacteristic(uuid: String): Boolean {
        val u = uuid.lowercase()
        return u.endsWith(VENDOR_SUFFIX) || u == CHARACTERISTIC_LEGACY
    }

    /** Pede à trena que envie cada medida automaticamente (comando "autosync"). */
    val ENABLE_AUTOSYNC: ByteArray =
        byteArrayOf(0xC0.toByte(), 0x55, 0x02, 0x01, 0x00, 0x1A)

    /** Nomes anunciados por trenas Bosch (a confirmação final é o serviço GATT). */
    val NAME_REGEX = Regex("(?i)(GLM|PLR|GCL|GRL|GIM|GTL|BLAZE|BOSCH|AD ?50)")

    const val MIN_METERS = 0.005f
    const val MAX_METERS = 300f

    private fun plausible(f: Float) = f.isFinite() && f in MIN_METERS..MAX_METERS

    /**
     * Metros do quadro. Formato conhecido primeiro (C0 55 10 06 …, float LE no byte 7).
     * Depois, para outros quadros C0, procura um float32 LE plausível no restante.
     */
    fun parseMeasurementMeters(frame: ByteArray): Float? {
        if (frame.size < 8 || frame[0] != 0xC0.toByte()) return null
        if (frame[1] == 0x55.toByte() && frame.size >= 11 && frame[2] == 0x10.toByte()) {
            if (frame[3] != 0x06.toByte()) return null // leitura inválida
            val f = ByteBuffer.wrap(frame, 7, 4).order(ByteOrder.LITTLE_ENDIAN).float
            return f.takeIf(::plausible)
        }
        val payload = frame.copyOfRange(3, frame.size)
        if (payload.size < 4) return null
        val bb = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN)
        for (off in 0..payload.size - 4) {
            val f = bb.getFloat(off)
            if (plausible(f)) return f
        }
        return null
    }

    /** Converte para milímetros inteiros (resolução de exibição da trena é 1 mm). */
    /** Medida real da trena, sem arredondar pro milímetro: guarda até 0,1 mm (só limpa o ruído do float). */
    fun metersToMm(m: Float): Double = (m.toDouble() * 10000.0).roundToLong() / 10.0

    /** Retorna a medida em mm se o quadro parecer uma leitura, senão null. */
    fun parseMm(frame: ByteArray): Double? = parseMeasurementMeters(frame)?.let(::metersToMm)

    fun toHex(bytes: ByteArray): String = bytes.joinToString(" ") { "%02X".format(it) }
}
