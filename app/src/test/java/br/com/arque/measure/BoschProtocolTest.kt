package br.com.arque.measure

import br.com.arque.measure.ble.BoschProtocol
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Estes testes verificam o NOSSO código de extração (float32 little-endian dentro de um quadro 0xC0),
 * com quadros sintéticos montados aqui. Eles NÃO provam que a trena real envia esse formato:
 * isso só se confirma com uma trena Bosch física (ver RELATORIO.md).
 */
class BoschProtocolTest {
    private fun frame(meters: Float, headerLen: Int = 3, pad: Int = 2): ByteArray {
        val payload = ByteBuffer.allocate(4 + pad).order(ByteOrder.LITTLE_ENDIAN).putFloat(meters).array()
        return byteArrayOf(0xC0.toByte(), 0x55, payload.size.toByte()).copyOf(headerLen) + payload
    }

    @Test fun `extrai metros e converte para mm inteiros`() {
        assertEquals(2345.0, BoschProtocol.parseMm(frame(2.345f))!!, 0.0)
        assertEquals(50.0, BoschProtocol.parseMm(frame(0.05f))!!, 0.0)
        assertEquals(12000.0, BoschProtocol.parseMm(frame(12.0f))!!, 0.0)
    }

    @Test fun `ignora o comando de autosync e quadros curtos`() {
        assertNull(BoschProtocol.parseMm(BoschProtocol.ENABLE_AUTOSYNC))
        assertNull(BoschProtocol.parseMm(byteArrayOf(0xC0.toByte(), 0x55)))
        assertNull(BoschProtocol.parseMm(ByteArray(0)))
    }

    @Test fun `ignora quadro que nao comeca com C0`() {
        val f = frame(2.0f)
        f[0] = 0x00
        assertNull(BoschProtocol.parseMm(f))
    }

    @Test fun `rejeita valores impossiveis`() {
        assertNull(BoschProtocol.parseMm(frame(Float.NaN)))
        assertNull(BoschProtocol.parseMm(frame(-3.0f)))
        assertNull(BoschProtocol.parseMm(frame(5000.0f)))
    }

    @Test fun `comando de autosync e hex`() {
        assertArrayEquals(byteArrayOf(0xC0.toByte(), 0x55, 0x02, 0x01, 0x00, 0x1A), BoschProtocol.ENABLE_AUTOSYNC)
        assertEquals("C0 55 02 01 00 1A", BoschProtocol.toHex(BoschProtocol.ENABLE_AUTOSYNC))
    }

    private fun hex(h: String) = h.split(" ").map { it.toInt(16).toByte() }.toByteArray()

    @Test fun `quadro real da comunidade C0 55 10 06 le o float no byte 7`() {
        val f = hex("c0 55 10 06 08 54 05 6f 81 04 3f 00 00 00 00 00 00 00 00 ec")
        assertEquals(518.0, BoschProtocol.parseMm(f)!!, 1.0)
    }

    @Test fun `leitura invalida byte 3 igual a 02 nao gera medida`() {
        val f = hex("c0 55 10 02 08 54 05 6f 81 04 3f 00 00 00 00 00 00 00 00 ec")
        assertNull(BoschProtocol.parseMm(f))
    }

    @Test fun `reconhece os UUIDs Bosch conhecidos`() {
        assertEquals(true, BoschProtocol.isBoschService("0000FDE8-0000-1000-8000-00805F9B34FB"))
        assertEquals(true, BoschProtocol.isBoschService("02a6c0d0-0451-4000-b000-fb3210111989"))
        assertEquals(true, BoschProtocol.isBoschCharacteristic("02a6c0d2-0451-4000-b000-fb3210111989"))
        assertEquals(false, BoschProtocol.isBoschService("0000180a-0000-1000-8000-00805f9b34fb"))
    }
}
