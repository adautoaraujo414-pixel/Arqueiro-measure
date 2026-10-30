package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.license.License

private val Gold = Color(0xFFF5B400)

private fun openWhats(ctx: android.content.Context) {
    val msg = tr("Olá! Meu período de teste do Arquemestre terminou e quero prosseguir com o pagamento único de {0}. Pode me passar a senha de desbloqueio?", License.PRICE)
    val uri = Uri.parse("https://wa.me/${License.WHATS}?text=" + Uri.encode(msg))
    runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
}

private fun android.content.Context.activity(): android.app.Activity? {
    var c: android.content.Context? = this
    while (c is android.content.ContextWrapper) { if (c is android.app.Activity) return c; c = c.baseContext }
    return null
}

private fun priceOf(@Suppress("UNUSED_PARAMETER") vm: AppViewModel) = License.PRICE

/** Campo de senha + botão. */
@Composable
private fun UnlockBox(vm: AppViewModel, onDone: () -> Unit = {}) {
    var code by remember { mutableStateOf("") }
    var err by remember { mutableStateOf(false) }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        // teclado do próprio app (o do celular não abre); a senha aparece como •••
        Text(tr("Senha de desbloqueio: ") + "•".repeat(code.length).ifEmpty { "–" }, color = Color(0xFF111111), fontSize = 15.sp)
        AppNumPad("•".repeat(code.length), { t ->
            code = when {
                t.isEmpty() -> ""
                t.length < code.length -> code.dropLast(1)
                else -> (code + t.last().takeIf { it.isDigit() }.let { it?.toString() ?: "" }).take(12)
            }
            err = false
        }, allowOps = false)
        if (err) Text(tr("Senha incorreta. Confira com quem te passou."), color = Color(0xFFE5484D), fontSize = 13.sp)
        Button(onClick = { if (vm.unlock(code)) onDone() else err = true }, enabled = code.isNotEmpty(), modifier = Modifier.fillMaxWidth()) {
            Text(tr("Desbloquear"))
        }
    }
}

/** Endereços públicos (GitHub Pages) no idioma do app. */
object SiteLinks {
    private const val BASE = "https://adautoaraujo414-pixel.github.io/Arqueiro-measure/"
    fun privacy() = BASE + when (br.com.arque.measure.i18n.I18n.lang) { "en" -> "privacy.html"; "es" -> "privacidad.html"; else -> "privacidade.html" }
    fun support() = BASE + when (br.com.arque.measure.i18n.I18n.lang) { "en" -> "support.html"; "es" -> "soporte.html"; else -> "suporte.html" }
    fun open(ctx: android.content.Context, url: String) {
        runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }
}

/**
 * Google Play: tela de assinatura (aparece antes de usar e quando a assinatura acaba).
 * Mostra o preço do Google Play, o teste grátis (se a conta ainda tiver direito) e como cancelar.
 */
@Composable
private fun PlayPaywall(vm: AppViewModel) {
    val ctx = LocalContext.current
    val backup = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/zip")) { uri -> if (uri != null) vm.backup(uri) }
    val price = vm.storePrice
    val trial = vm.storeTrialDays
    val returning = br.com.arque.measure.license.License.hadStore(ctx)
    Box(Modifier.fillMaxSize().background(Color(0xFF14171C)).statusBarsPadding().navigationBarsPadding(), contentAlignment = Alignment.Center) {
        Column(
            Modifier.widthIn(max = 480.dp).fillMaxWidth().verticalScroll(rememberScrollState()).padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp), horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("ARQUEMESTRE", color = Gold, fontSize = 26.sp, fontWeight = FontWeight.Bold)
            Text(
                if (returning) tr("Sua assinatura terminou") else tr("Medição, projeto, corte, orçamento e agenda da sua marcenaria num lugar só."),
                color = Color.White, fontSize = 19.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center,
            )
            if (returning) Text(tr("Seus dados continuam guardados no aparelho. Assine de novo pra continuar usando."), color = Color(0xFFCBD5E1), fontSize = 15.sp, textAlign = TextAlign.Center)
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Color(0xFF1F242C)).padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                listOf(
                    tr("📏 Trena laser Bosch: a medida cai direto na cota"),
                    tr("🪚 Editor de móveis em 3D"),
                    tr("📋 Lista de corte, plano das chapas e orçamento em PDF"),
                    tr("📅 Agenda de entregas, visitas e medições"),
                ).forEach { Text(it, color = Color(0xFFE2E8F0), fontSize = 14.sp) }
            }
            // o preço da assinatura é o destaque (regra das lojas); o teste grátis vem junto
            Text(price?.let { tr("{0} por mês", it) } ?: tr("Carregando o preço…"), color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Bold)
            if (trial > 0 && price != null) Text(tr("{0} dias grátis, depois {1} por mês.", trial, price), color = Gold, fontSize = 15.sp, textAlign = TextAlign.Center)
            Button(
                onClick = { ctx.activity()?.let { vm.buyStore(it) } }, enabled = price != null, modifier = Modifier.fillMaxWidth().height(52.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF01875F), contentColor = Color.White),
            ) { Text(if (trial > 0) tr("Começar {0} dias grátis", trial) else tr("Assinar"), fontSize = 16.sp) }
            Text(
                tr("Assinatura mensal com renovação automática pela Google Play. Cancele quando quiser em Google Play › Pagamentos e assinaturas. Cancelando antes do fim do teste grátis, nada é cobrado."),
                color = Color(0xFF94A3B8), fontSize = 12.sp, textAlign = TextAlign.Center,
            )
            vm.toast?.let { Text(it, color = Gold, fontSize = 14.sp, textAlign = TextAlign.Center) }
            OutlinedButton(onClick = { vm.restoreStore() }, modifier = Modifier.fillMaxWidth()) {
                Text(tr("Já assino · restaurar assinatura"), color = Color(0xFFCBD5E1))
            }
            OutlinedButton(onClick = { backup.launch("arquemestre-backup.zip") }, modifier = Modifier.fillMaxWidth()) {
                Text(tr("Salvar uma cópia dos meus dados (backup)"), color = Color(0xFFCBD5E1))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Text(tr("Privacidade"), color = Color(0xFF94A3B8), fontSize = 13.sp, modifier = Modifier.clickable { SiteLinks.open(ctx, SiteLinks.privacy()) })
                Text(tr("Gerenciar assinatura"), color = Color(0xFF94A3B8), fontSize = 13.sp, modifier = Modifier.clickable { vm.manageStore() })
                Text(tr("Ajuda"), color = Color(0xFF94A3B8), fontSize = 13.sp, modifier = Modifier.clickable { SiteLinks.open(ctx, SiteLinks.support()) })
            }
        }
    }
}

/** Tela de bloqueio depois do teste. Os dados ficam guardados; dá pra fazer backup mesmo bloqueado. */
@Composable
fun LockScreen(vm: AppViewModel) {
    if (br.com.arque.measure.BuildConfig.PLAY) { PlayPaywall(vm); return }
    val ctx = LocalContext.current
    val backup = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/zip")) { uri -> if (uri != null) vm.backup(uri) }
    Box(Modifier.fillMaxSize().background(Color(0xFF14171C)).statusBarsPadding().navigationBarsPadding(), contentAlignment = Alignment.Center) {
        Column(
            Modifier.widthIn(max = 480.dp).fillMaxWidth().verticalScroll(rememberScrollState()).padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp), horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("ARQUEMESTRE", color = Gold, fontSize = 26.sp, fontWeight = FontWeight.Bold)
            Text(tr("Você chegou ao fim do período de teste"), color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            Text(
                tr("Pra continuar usando e não perder nada (notas, agenda, orçamentos e projetos de móveis ficam todos guardados), ") +
                    tr("o acesso completo é por pagamento único de {0}.", priceOf(vm)),
                color = Color(0xFFCBD5E1), fontSize = 15.sp, textAlign = TextAlign.Center,
            )
            Text(tr("Quer prosseguir?"), color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
            run {
                Button(
                    onClick = { openWhats(ctx) }, modifier = Modifier.fillMaxWidth().height(52.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF25D366), contentColor = Color.White),
                ) { Text(tr("Sim, quero prosseguir · falar no WhatsApp"), fontSize = 15.sp) }
                Text(tr("Depois do pagamento você recebe a senha. É só digitar aqui:"), color = Color(0xFF94A3B8), fontSize = 13.sp, textAlign = TextAlign.Center)
                Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Color.White).padding(14.dp)) { UnlockBox(vm) }
            }
            OutlinedButton(onClick = { backup.launch("arquemestre-backup.zip") }, modifier = Modifier.fillMaxWidth()) {
                Text(tr("Salvar uma cópia dos meus dados (backup)"), color = Color(0xFFCBD5E1))
            }
            Text(tr("Atualizações futuras instalam por cima, sem perder nada."), color = Color(0xFF64748B), fontSize = 12.sp)
        }
    }
}

/** Passos do guia (português é a chave da tradução). */
val GUIDE = listOf(
    "1 · Crie a nota do cliente" to "Toque em ＋ Criar nota e dê o nome do cliente. Tire foto do ambiente ou desenhe o croqui com o dedo ou a caneta.",
    "2 · Meça com a trena" to "Ligue a trena Bosch (botão Trena) e toque na cota: a medida cai direto, em milímetro. Sem trena, digite no teclado do app.",
    "3 · Abra o projeto de móveis" to "Na nota, toque em 🪚 Projeto: o projeto já nasce com o nome do cliente e fica ligado à nota, no mesmo quadro da biblioteca. Um cliente pode ter vários projetos (cozinha, suíte…).",
    "4 · Monte os módulos" to "Toque em 📦 Módulos (tem lupa pra procurar), arraste no desenho e ajuste as medidas. Puxadores, tamponamentos, cuba e cooktop ficam no painel do lado.",
    "5 · Veja em 3D" to "Toque em 🧊: um dedo gira, dois dedos dão zoom, toque na porta pra abrir. ↶ desfaz. Em ⋯ Mais ficam as vistas, portas e janelas do ambiente.",
    "6 · Corte e orçamento" to "☰ mostra a lista e o plano de corte das chapas: toque na peça pra ver no 3D e 2 toques marca ✓ cortada. 💰 calcula material e preço e gera o orçamento em PDF.",
    "7 · Agenda e backup" to "Marque entregas e medições na Agenda. No menu ⋮ faça o backup completo (ZIP) de vez em quando. Fotos da câmera também ficam na galeria do celular.",
)

/** Boas-vindas na primeira abertura + guia rápido opcional. */
@Composable
fun WelcomeDialog(vm: AppViewModel) {
    var page by remember { mutableIntStateOf(0) }
    var langOpen by remember { mutableStateOf(false) }
    if (langOpen) LanguageDialog { langOpen = false }
    // guia passo a passo: do primeiro cliente até o corte e o orçamento
    val guide = GUIDE.map { tr(it.first) to tr(it.second) }
    LaunchedEffect(vm.guideFromMenu) { if (vm.guideFromMenu) { page = 1; vm.guideFromMenu = false } }
    AlertDialog(
        onDismissRequest = {},
        title = { Text(if (page == 0) tr("Seja bem-vindo ao Arquemestre!") else guide[page - 1].first) },
        text = {
            Column {
                Text(
                    if (page == 0) {
                    if (br.com.arque.measure.BuildConfig.PLAY) tr("Aqui vamos desenrolar a produção e a organização da sua marcenaria: medição, projeto, corte, orçamento e agenda num lugar só.\n\nQuer ver um guia rápido de como usar?")
                    else tr("Você está na versão de teste por {0} dias. Aqui vamos desenrolar a produção e a organização da sua marcenaria: medição, projeto, corte, orçamento e agenda num lugar só.\n\nQuer ver um guia rápido de como usar?", License.TRIAL_DAYS)
                }
                    else guide[page - 1].second + "\n\n${page}/${guide.size}",
                )
                if (page == 0) TextButton(onClick = { langOpen = true }) { Text(langMenuLabel() + ": " + currentLangName()) }
            }
        },
        confirmButton = {
            TextButton(onClick = { if (page < guide.size) page++ else vm.showWelcome = false }) {
                Text(if (page == 0) tr("Ver o guia") else if (page < guide.size) tr("Próximo") else tr("Começar"))
            }
        },
        dismissButton = { TextButton(onClick = { vm.showWelcome = false }) { Text(if (page == 0) tr("Começar agora") else tr("Pular")) } },
    )
}

/** Selo "Teste · falta X" — toque pra desbloquear antes do fim. */
@Composable
fun TrialChip(vm: AppViewModel, modifier: Modifier = Modifier) {
    // Google Play: o teste é o da assinatura (a loja cuida); sem pagamento único nem senha
    if (br.com.arque.measure.BuildConfig.PLAY) return
    var open by remember { mutableStateOf(false) }
    val ctx = LocalContext.current
    Row(
        modifier.clip(RoundedCornerShape(50)).background(Color(0xCC14171C)).clickable { open = true }.padding(horizontal = 10.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) { Text(tr("Teste · falta {0}", vm.trialLeft), color = Gold, fontSize = 12.sp) }
    if (open) AlertDialog(
        onDismissRequest = { open = false },
        title = { Text(tr("Versão de teste")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(tr("Falta {0} de teste. Acesso completo: pagamento único de {1}.", vm.trialLeft, priceOf(vm)))
                run {
                    Button(onClick = { openWhats(ctx) }, colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF25D366)), modifier = Modifier.fillMaxWidth()) { Text(tr("Falar no WhatsApp")) }
                    Spacer(Modifier.height(2.dp))
                    UnlockBox(vm) { open = false }
                }
            }
        },
        confirmButton = { TextButton(onClick = { open = false }) { Text(tr("Fechar")) } },
    )
}

/** Versão nova encontrada sozinha. */
@Composable
fun UpdateOfferDialog(vm: AppViewModel) {
    val r = vm.updateOffer ?: return
    AlertDialog(
        onDismissRequest = { vm.updateOffer = null },
        title = { Text(tr("Atualização disponível")) },
        text = { Text(tr("Saiu a versão apk-{0}. Quer atualizar agora? O app baixa e instala por cima — nada é perdido (antes ele guarda uma cópia dos dados em Downloads/ArqueMeasure).", r.number)) },
        confirmButton = { TextButton(onClick = { vm.acceptUpdate() }) { Text(tr("Atualizar agora")) } },
        dismissButton = {
            Row {
                TextButton(onClick = { vm.skipUpdate() }) { Text(tr("Pular esta")) }
                TextButton(onClick = { vm.updateOffer = null }) { Text(tr("Depois")) }
            }
        },
    )
}
