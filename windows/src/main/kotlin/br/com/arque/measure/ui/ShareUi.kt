package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import br.com.arque.measure.AppViewModel

/** Bluetooth entre celulares não existe no Windows: explica e sugere o caminho que funciona. */
@Composable
fun ShareViewPicker(@Suppress("UNUSED_PARAMETER") vm: AppViewModel, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("Ver projeto de outro celular")) },
        text = { Text(tr("No Windows não dá pra ver ao vivo por Bluetooth. Peça o backup ou o link do plano de corte (📤 Enviar projeto) e abra aqui.")) },
        confirmButton = { TextButton(onClick = onDismiss) { Text(tr("Entendi")) } },
    )
}

@Composable
fun ShareHostDialog(@Suppress("UNUSED_PARAMETER") company: String = "", @Suppress("UNUSED_PARAMETER") onPush: () -> Unit, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("Compartilhar ao vivo")) },
        text = { Text(tr("No Windows o compartilhamento ao vivo por Bluetooth não está disponível. Use 📤 Enviar projeto no plano de corte (link) ou o backup completo.")) },
        confirmButton = { TextButton(onClick = onDismiss) { Text(tr("Entendi")) } },
    )
}
