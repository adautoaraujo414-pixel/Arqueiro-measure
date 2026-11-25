package br.com.arque.measure

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.UiSelector
import androidx.test.uiautomator.UiScrollable
import br.com.arque.measure.demo.DemoActivity
import br.com.arque.measure.demo.DemoSpace
import br.com.arque.measure.data.DataBackup
import br.com.arque.measure.data.Store
import br.com.arque.measure.model.Index
import br.com.arque.measure.model.Note
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.zip.ZipInputStream

/** Executado apenas no pacote descartável .teste do emulador; nunca no app dos usuários. */
@RunWith(AndroidJUnit4::class)
class DemoIsolationTest {
    private val context get() = ApplicationProvider.getApplicationContext<Context>()
    private fun verifyTestPackage() { assertTrue("Não executar em dados reais", BuildConfig.TESTE) }

    @Test fun gravarExportarERestaurarDemonstracaoNaoAlteraProjetoNemLicencaNormal() {
        verifyTestPackage()
        val normal = File(context.filesDir, "moveis/projects.json").apply { parentFile!!.mkdirs(); writeText("[{\"id\":\"cliente-real-teste\"}]") }
        val before = normal.readBytes()
        val normalPrefs = context.getSharedPreferences("arque.lic", 0)
        normalPrefs.edit().clear().putString("sentinel", "assinatura-normal").commit()
        val demo = DemoSpace.application(context)
        assertNotEquals(context.filesDir.canonicalPath, demo.filesDir.canonicalPath)
        val store = Store(File(demo.filesDir, "projects"))
        val note = Note(name = "Exemplo de teste")
        store.saveNote(note); store.saveIndex(Index(notes = listOf(note.meta())))
        demo.getSharedPreferences("arque.lic", 0).edit().putBoolean("ok", true).commit()
        assertFalse(normalPrefs.getBoolean("ok", false))
        assertEquals("assinatura-normal", normalPrefs.getString("sentinel", ""))
        val bytes = ByteArrayOutputStream().also { DataBackup.fullBackup(demo, it) }.toByteArray()
        assertTrue(DataBackup.stage(demo, bytes.inputStream()))
        DataBackup.applyPending(demo)
        assertEquals("Exemplo de teste", Store(File(demo.filesDir, "projects")).loadNote(note.id)?.name)
        assertArrayEquals(before, normal.readBytes())
        assertEquals("assinatura-normal", normalPrefs.getString("sentinel", ""))
        assertFalse(DataBackup.autoBackup(demo, true))
    }

    @Test fun copiaNormalNaoIncluiProjetosNemPreferenciasDaDemonstracao() {
        verifyTestPackage()
        val demo = DemoSpace.application(context)
        File(demo.filesDir, "segredo-demo.txt").writeText("exemplo")
        demo.getSharedPreferences("sample", 0).edit().putBoolean("created", true).commit()
        val bytes = ByteArrayOutputStream().also { DataBackup.fullBackup(context, it) }.toByteArray()
        ZipInputStream(bytes.inputStream()).use { zip ->
            var item = zip.nextEntry
            while (item != null) {
                assertFalse(item.name, item.name.contains(DemoSpace.DIRECTORY))
                item = zip.nextEntry
            }
        }
    }

    @Test fun entradaPublicaAbreDemonstracaoSemCompraENaoLiberaUsoNormal() {
        verifyTestPackage()
        br.com.arque.measure.i18n.I18n.set(context, br.com.arque.measure.i18n.AppLang.PT)
        context.getSharedPreferences("arque.lic", 0).edit().clear().commit()
        DemoSpace.application(context).getSharedPreferences("sample", 0).edit().clear().commit()
        val device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
        ActivityScenario.launch(MainActivity::class.java).use {
            val label = "Explorar demonstração com dados separados"
            // O ambiente de CI tem idioma pt-BR definido no workflow.
            UiScrollable(UiSelector().scrollable(true)).scrollTextIntoView(label)
            assertTrue(device.findObject(UiSelector().text(label)).waitForExists(10000))
            device.findObject(UiSelector().text(label)).click()
            assertTrue(device.findObject(UiSelector().text("Demonstração · dados separados")).waitForExists(15000))
            assertFalse(context.getSharedPreferences("arque.lic", 0).getBoolean("ok", false))
            val client = device.findObject(UiSelector().text("Cliente de exemplo — demonstração"))
            assertTrue("Cliente fictício deve aparecer", client.waitForExists(10000))
            client.click()
            // O fluxo existente abre primeiro a ficha do cliente; o projeto fica dentro dela.
            val project = device.findObject(UiSelector().text("2 módulos"))
            assertTrue("Projeto de exemplo na ficha do cliente", project.waitForExists(10000))
            project.click()
            val opened = device.findObject(UiSelector().className("android.webkit.WebView")).waitForExists(15000)
            device.dumpWindowHierarchy(File(context.getExternalFilesDir(null), "demonstracao-ui.xml"))
            device.takeScreenshot(File(context.getExternalFilesDir(null), "demonstracao.png"))
            assertTrue("Editor deve abrir", opened)
            device.waitForIdle()
            device.takeScreenshot(File(context.getExternalFilesDir(null), "demonstracao.png"))
            device.findObject(UiSelector().text("Sair")).click()
            assertTrue(device.findObject(UiSelector().text(label)).waitForExists(10000))
        }
    }
}
