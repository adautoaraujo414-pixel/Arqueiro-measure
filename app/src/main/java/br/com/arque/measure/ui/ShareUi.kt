package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.Screen
import br.com.arque.measure.share.BtShare

private fun btPerms(): Array<String> =
    if (Build.VERSION.SDK_INT >= 31) arrayOf(Manifest.permission.BLUETOOTH_CONNECT, Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_ADVERTISE)
    else arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)

private fun hasBt(ctx: Context) = btPerms().all { ContextCompat.checkSelfPermission(ctx, it) == PackageManager.PERMISSION_GRANTED }

/** Escolher o celular do dono do projeto e ver o projeto ao vivo (só visualização). */
@SuppressLint("MissingPermission")
@Composable
fun ShareViewPicker(vm: AppViewModel, onDismiss: () -> Unit) {
    val ctx = LocalContext.current
    val devs = remember { mutableStateListOf<BluetoothDevice>() }
    var ok by remember { mutableStateOf(hasBt(ctx)) }
    var msg by remember { mutableStateOf("") }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { ok = hasBt(ctx) }
    val enable = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { }
    fun add(d: BluetoothDevice) { if (devs.none { it.address == d.address }) devs.add(d) }
    fun scan() {
        val ad = BtShare.adapter(ctx) ?: run { msg = tr("Este celular não tem Bluetooth."); return }
        if (!ad.isEnabled) { enable.launch(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)); return }
        runCatching { ad.bondedDevices.forEach { add(it) } }
        runCatching { ad.cancelDiscovery(); ad.startDiscovery() }
        msg = tr("Procurando… no celular do dono: Editor de móveis → 📤 Compartilhar.")
    }
    LaunchedEffect(Unit) { if (!ok) perm.launch(btPerms()) }
    LaunchedEffect(ok) { if (ok) scan() }
    DisposableEffect(Unit) {
        val rx = object : BroadcastReceiver() {
            override fun onReceive(c: Context, i: Intent) {
                val d: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33) i.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                else @Suppress("DEPRECATION") i.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                d?.let { add(it) }
            }
        }
        ContextCompat.registerReceiver(ctx, rx, IntentFilter(BluetoothDevice.ACTION_FOUND), ContextCompat.RECEIVER_EXPORTED)
        onDispose { runCatching { ctx.unregisterReceiver(rx) }; runCatching { BtShare.adapter(ctx)?.cancelDiscovery() } }
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("Ver projeto por Bluetooth")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(tr("Escolha o celular de quem está compartilhando. Você vê o projeto ao vivo, com todas as medidas, mas não altera nada."), fontSize = 13.sp)
                if (!ok) TextButton(onClick = { perm.launch(btPerms()) }) { Text(tr("Permitir Bluetooth")) }
                if (msg.isNotEmpty()) Text(msg, fontSize = 12.sp, color = Color(0xFF666666))
                LazyColumn(Modifier.heightIn(max = 320.dp)) {
                    items(devs, key = { it.address }) { d ->
                        val name = runCatching { d.name }.getOrNull() ?: d.address
                        Text(
                            "📱 $name", fontSize = 15.sp,
                            modifier = Modifier.fillMaxWidth().clickable {
                                BtShare.connect(ctx, d); vm.moveisView = true; vm.screen = Screen.Moveis; onDismiss()
                            }.padding(vertical = 12.dp),
                        )
                        HorizontalDivider()
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = { if (ok) scan() else perm.launch(btPerms()) }) { Text(tr("Procurar de novo")) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(tr("Fechar")) } },
    )
}

/** Dono: liga o compartilhamento (fica visível pros outros celulares por 5 min) e mostra quantos estão vendo. */
@Composable
fun ShareHostDialog(onPush: () -> Unit, onDismiss: () -> Unit) {
    val ctx = LocalContext.current
    var ok by remember { mutableStateOf(hasBt(ctx)) }
    var err by remember { mutableStateOf("") }
    val hosting by BtShare.hosting.collectAsStateWithLifecycle()
    val viewers by BtShare.viewers.collectAsStateWithLifecycle()
    val visible = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { }
    val enable = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { start(ctx, onPush, visible) { err = it } }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        ok = hasBt(ctx)
        if (ok) { if (BtShare.adapter(ctx)?.isEnabled == true) start(ctx, onPush, visible) { e -> err = e } else enable.launch(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)) }
    }
    LaunchedEffect(Unit) {
        if (!hosting) {
            if (!ok) perm.launch(btPerms())
            else if (BtShare.adapter(ctx)?.isEnabled != true) enable.launch(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
            else start(ctx, onPush, visible) { err = it }
        }
    }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("Compartilhar projeto")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                if (err.isNotEmpty()) Text(err, color = Color(0xFFE5484D))
                else if (hosting) Text(tr("📡 Compartilhando por Bluetooth · ") + (if (viewers == 0) tr("ninguém vendo ainda") else tr("{0} vendo agora", viewers)))
                else Text(tr("Ligando o Bluetooth…"))
                Text(tr("No outro celular (com o Arquemestre): menu ⋮ → Ver projeto por Bluetooth → escolher este celular. Ele vê tudo ao vivo, com as medidas, mas não altera nada."), fontSize = 13.sp)
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(tr("Continuar editando")) } },
        dismissButton = { TextButton(onClick = { BtShare.stopHost(); onDismiss() }) { Text(tr("Parar de compartilhar")) } },
    )
}

private fun start(ctx: Context, onPush: () -> Unit, visible: androidx.activity.result.ActivityResultLauncher<Intent>, onErr: (String) -> Unit) {
    if (!BtShare.startHost(ctx)) { onErr(tr("Não consegui ligar o compartilhamento. Confira se o Bluetooth está ligado.")); return }
    onPush()
    runCatching { visible.launch(Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)) }
}

