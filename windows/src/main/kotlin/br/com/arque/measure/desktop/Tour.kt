package br.com.arque.measure.desktop

import android.net.Uri
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.Screen
import br.com.arque.measure.data.DataBackup
import br.com.arque.measure.i18n.AppLang
import br.com.arque.measure.i18n.I18n
import br.com.arque.measure.model.Appointment
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteItem
import br.com.arque.measure.model.TextObj
import kotlinx.coroutines.delay
import org.json.JSONArray
import org.json.JSONObject
import java.awt.Rectangle
import java.awt.Robot
import java.io.File
import javax.imageio.ImageIO

/**
 * Teste de ponta a ponta do app instalado (ARQUE_TOUR=pasta): passa por todas as telas e funções
 * com dados de verdade, tira print de cada tela e grava report.json. Usado no GitHub Actions (Windows).
 */
object Tour {
    @Volatile var editorResult: String? = null

    private val steps = JSONArray()
    private var fails = 0

    private fun step(name: String, ok: Boolean, detail: Any? = null) {
        steps.put(JSONObject().put("passo", name).put("ok", ok).put("detalhe", detail?.toString() ?: ""))
        if (!ok) fails++
        println((if (ok) "OK  " else "FALHA ") + name + (detail?.let { " · $it" } ?: ""))
    }

    private fun shot(dir: File, name: String) {
        runCatching {
            val f = DesktopApp.frame ?: return
            val b = f.bounds
            val img = Robot().createScreenCapture(Rectangle(b.x, b.y, b.width, b.height))
            ImageIO.write(img, "png", File(dir, "$name.png"))
        }.onFailure { step("print $name", false, it.message) }
    }

    private suspend fun waitFor(ms: Long, cond: () -> Boolean): Boolean {
        val t0 = System.currentTimeMillis()
        while (System.currentTimeMillis() - t0 < ms) { if (runCatching(cond).getOrDefault(false)) return true; delay(200) }
        return false
    }

    suspend fun run(vm: AppViewModel, dir: File) {
        dir.mkdirs()
        val out = File(dir, "arquivos").apply { mkdirs() }
        try {
            delay(2500)
            vm.showWelcome = false
            delay(500)
            step("abre na biblioteca", vm.screen == Screen.Library)
            step("pastas de dados", Paths.data.isDirectory, Paths.data.path)
            shot(dir, "01-biblioteca")

            // ---- caderno: nota com cota, texto e exportações ----
            val id = vm.createNote()
            vm.openNote(id)
            step("cria e abre nota", waitFor(5000) { vm.screen == Screen.Editor && vm.session != null })
            val s = vm.session!!
            s.state.addObj(DimObj(photoId = null, a = Pt(120f, 300f), b = Pt(620f, 300f), valueMm = 2450.0, color = 0xFFE53935.toInt(), width = 4f))
            s.state.addObj(TextObj(photoId = null, at = Pt(140f, 220f), text = "Cozinha do cliente · teste Windows", size = 34f, color = 0xFF1B1B1B.toInt()))
            delay(1200)
            shot(dir, "02-nota")
            val pdf = File(out, "nota.pdf"); val png = File(out, "nota.png"); val csv = File(out, "nota.csv")
            vm.exportPdf(Uri.fromFile(pdf)); vm.exportPng(Uri.fromFile(png)); vm.exportCsv(Uri.fromFile(csv))
            step("exporta PDF da nota", waitFor(15000) { pdf.length() > 1000 }, pdf.length())
            step("exporta PNG da folha", waitFor(15000) { png.length() > 1000 }, png.length())
            step("exporta CSV das medidas", waitFor(10000) { csv.exists() && csv.readText().contains("2450") }, csv.takeIf { it.exists() }?.readText()?.take(200))
            runCatching {
                org.apache.pdfbox.Loader.loadPDF(pdf).use { d -> step("PDF da nota abre (páginas)", d.numberOfPages >= 1, d.numberOfPages) }
            }.onFailure { step("PDF da nota abre", false, it.message) }
            runCatching {
                val im = ImageIO.read(png)
                var dark = 0
                for (x in 0 until im.width step 7) for (y in 0 until im.height step 7) if ((im.getRGB(x, y) and 0xFF) < 128) dark++
                step("PNG tem o desenho (pixels escuros)", dark > 30, "${im.width}x${im.height} escuros=$dark")
            }.onFailure { step("PNG legível", false, it.message) }
            vm.closeEditor()
            delay(800)

            // ---- orçamento em PDF ----
            vm.screen = Screen.Quotes
            delay(800)
            val q = Quote(clientName = "Cliente Teste", city = "Uberlândia", items = listOf(QuoteItem(desc = "Armário de cozinha", qty = 1.0, unitValue = 3500.0), QuoteItem(desc = "Painel ripado", qty = 2.0, unit = "m²", unitValue = 480.0)))
            vm.saveQuote(q)
            var qUri: Uri? = null
            vm.buildQuotePdf(q) { qUri = it }
            step("gera PDF do orçamento", waitFor(15000) { qUri?.file()?.let { it.length() > 1000 } == true }, qUri)
            delay(600)
            shot(dir, "03-orcamentos")

            // ---- agenda e aviso do Windows ----
            vm.screen = Screen.Agenda
            val a = Appointment(title = "Entrega teste", startMs = System.currentTimeMillis() + 3 * 3600_000L, clientName = "Cliente Teste")
            vm.saveAppt(a)
            delay(800)
            step("agenda salva o compromisso", vm.appointments.any { it.id == a.id })
            runCatching { br.com.arque.measure.agenda.AgendaReminders.show(DesktopApp.context, a, 60) }
                .onSuccess { step("aviso da agenda (notificação do Windows)", br.com.arque.measure.agenda.AgendaReminders.shown.isNotEmpty()) }
                .onFailure { step("aviso da agenda", false, it.message) }
            delay(1500)
            shot(dir, "04-agenda")

            // ---- editor de móveis (navegador embutido) ----
            editorResult = null
            vm.newMoveisProject()
            step("abre o editor de móveis", waitFor(240000) { Browser.ready }, Browser.error ?: "")
            step("editor carregou a página", waitFor(90000) { Browser.pageReady && Browser.url().contains("editor.html") }, Browser.url())
            delay(2500)
            Browser.js(
                """
                (function go(n){if(typeof S==='undefined'||typeof newTpl!=='function'){if(n<150)return setTimeout(function(){go(n+1)},200)}var r={};try{
                  r.app=!!(window.ArqueApp&&ArqueApp.isApp());r.win=!!ArqueApp.isWindows;
                  r.notas=JSON.parse(ArqueApp.listNotes()||'[]').length;
                  S.mods=[];newTpl(CATS[0].it[0]);draw();panel();r.mods=S.mods.length;
                  catLevel('inf');r.inf=[].filter.call(document.querySelectorAll('#catm [data-cati]'),function(b){return b.offsetParent!==null}).length;
                  r.infAereo=[].some.call(document.querySelectorAll('#catm [data-cati]'),function(b){return b.offsetParent!==null&&/Aéreo/.test(b.textContent)});
                  document.querySelector('#catm [data-catx]').click();
                  ArqueApp.putFile('tour.json',btoa('ok-windows'));r.arq=atob(ArqueApp.getFile('tour.json'));
                  r.lista=JSON.parse(ArqueApp.listFiles()).indexOf('tour.json')>=0;
                  try{if(typeof pSaveAll==='function'&&typeof pLoadAll==='function'){var all=pLoadAll();all.push({id:'tour'+Date.now(),name:'Projeto teste Windows',S:JSON.parse(JSON.stringify(S))});pSaveAll(all)}}catch(e){r.salvarErr=String(e)}
                }catch(e){r.err=String(e)}
                ArqueApp.tourResult(JSON.stringify(r))})(0)
                """.trimIndent(),
            )
            step("editor responde pela ponte", waitFor(20000) { editorResult != null }, editorResult ?: ("url=" + Browser.url() + " loads=" + Browser.loads + " console=" + Browser.console.toList().takeLast(12).joinToString(" | ")))
            val r = runCatching { JSONObject(editorResult ?: "{}") }.getOrDefault(JSONObject())
            step("editor: ponte ArqueApp", r.optBoolean("app") && r.optBoolean("win"), r)
            step("editor: módulo adicionado", r.optInt("mods") == 1)
            step("editor: botão Inferior só com módulos de baixo", r.optInt("inf") > 3 && !r.optBoolean("infAereo"), "${r.optInt("inf")} itens")
            step("editor: arquivos pela ponte", r.optString("arq") == "ok-windows" && r.optBoolean("lista"))
            val pj = File(DesktopApp.context.filesDir, "moveis/projects.json")
            step("editor: projeto salvo em arquivo", waitFor(8000) { pj.length() > 10 }, pj.length())
            delay(1500)
            shot(dir, "05-editor-moveis")
            vm.screen = Screen.Library
            delay(1500)

            // ---- backup completo ----
            val zip = File(out, "backup.zip")
            vm.backup(Uri.fromFile(zip))
            step("backup completo (zip)", waitFor(20000) { zip.length() > 1000 && DataBackup.isFull(zip) }, zip.length())

            // ---- idiomas ----
            I18n.set(DesktopApp.context, AppLang.EN)
            delay(1500)
            step("troca para inglês", I18n.lang == "en")
            shot(dir, "06-ingles")
            I18n.set(DesktopApp.context, AppLang.PT)
            delay(800)
            vm.projVersion++
            delay(800)
            shot(dir, "07-biblioteca-final")
        } catch (t: Throwable) {
            step("tour interrompido", false, t.stackTraceToString().take(1500))
        } finally {
            File(dir, "report.json").writeText(JSONObject().put("falhas", fails).put("passos", steps).toString(2))
            delay(500)
            DesktopApp.requestExit?.invoke()
        }
    }
}
