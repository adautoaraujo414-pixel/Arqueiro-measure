package br.com.arque.measure.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.arque.measure.i18n.AppLang
import br.com.arque.measure.i18n.I18n
import br.com.arque.measure.i18n.tr

/** Nome do item de menu: sempre com "Language" junto, pra quem não lê português achar. */
fun langMenuLabel(): String = "🌐 " + tr("Idioma") + if (I18n.lang == "en") "" else " · Language"

/** Nome do idioma em uso, no próprio idioma ("English", "Español"...). */
fun currentLangName(): String = AppLang.entries.firstOrNull { it.code == I18n.lang }?.label ?: "Português"

/** Escolha do idioma do app. Troca na hora, sem perder nada. */
@Composable
fun LanguageDialog(onDismiss: () -> Unit) {
    val ctx = LocalContext.current
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(langMenuLabel()) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                AppLang.entries.forEach { l ->
                    val name = if (l == AppLang.AUTO) tr("Automático (idioma do telefone)") else l.label
                    Row(
                        Modifier.fillMaxWidth().clickable { I18n.set(ctx, l); onDismiss() }.padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(selected = I18n.choice == l, onClick = { I18n.set(ctx, l); onDismiss() })
                        Text(name, fontSize = 16.sp)
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(tr("Fechar")) } },
    )
}
