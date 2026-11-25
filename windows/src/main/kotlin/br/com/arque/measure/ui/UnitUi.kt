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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.i18n.tr
import br.com.arque.measure.model.LengthUnit

/** UNIDADE (Adauto 25/11): rótulo do item dos Ajustes, com a unidade atual (sem escolha = mm, o que o editor sempre mostrou). */
fun unitMenuLabel(pref: LengthUnit?): String =
    tr("Unidade de medida") + " (" + (if (pref == LengthUnit.CM) "cm" else "mm") + ")"

/** Ajustes › Unidade de medida: Milímetros (mm) ou Centímetros (cm). Só muda o que aparece; as medidas continuam guardadas em mm. */
@Composable
fun UnitDialog(vm: AppViewModel, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("Unidade de medida")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                listOf(LengthUnit.MM to tr("Milímetros (mm)"), LengthUnit.CM to tr("Centímetros (cm)")).forEach { (u, name) ->
                    val sel = (vm.unitPref ?: LengthUnit.MM) == u
                    Row(
                        Modifier.fillMaxWidth().clickable { vm.changeUnitPref(u); onDismiss() }.padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(selected = sel, onClick = { vm.changeUnitPref(u); onDismiss() })
                        Text(name, fontSize = 16.sp)
                    }
                }
                Text(tr("Vale no editor, nas cotas, na lista de peças, no plano de corte e na nota nova. As medidas continuam guardadas em mm: trocar não muda nenhum projeto."), fontSize = 13.sp)
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(tr("Fechar")) } },
    )
}
