package br.com.arque.measure

import br.com.arque.measure.data.DataBackup
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * N06 (auditoria geral de 17/11): o backup de referência no formato do Android (tests/backup-referencia, gerado por
 * tools/gerar_backup_referencia.py) é aceito pela conferência do backup completo, com os 2 projetos e as fotos (inclusive foto..jpg).
 * O mesmo arquivo é restaurado nos testes do iOS (BackupSafetyTests) e do Windows (DesktopCompatTest).
 */
class BackupReferenciaTest {
    private val zip = File("../tests/backup-referencia/android-backup-referencia.zip")

    @Test fun backupDeReferenciaEAceitoComOsDoisProjetos() {
        assertTrue("arquivo de referência existe", zip.isFile)
        val c = DataBackup.check(zip)
        assertTrue("conferência aceitou: ${c.reason}", c.ok)
        assertEquals(2, c.projects)
    }
}
