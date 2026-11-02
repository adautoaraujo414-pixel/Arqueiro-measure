package br.com.arque.measure.desktop

import java.awt.SystemTray
import java.awt.TrayIcon
import java.awt.event.ActionListener

/** Notificações do Windows (ícone do Arquemestre na bandeja, perto do relógio). */
object Notifier {
    private var icon: TrayIcon? = null
    @Volatile private var onClick: (() -> Unit)? = null

    private fun tray(): TrayIcon? {
        icon?.let { return it }
        if (System.getProperty("arque.test") != null) return null
        if (!SystemTray.isSupported()) return null
        return runCatching {
            val img = java.awt.Toolkit.getDefaultToolkit().getImage(Notifier::class.java.getResource("/arquemestre.png"))
            val t = TrayIcon(img, "Arquemestre").apply {
                isImageAutoSize = true
                addActionListener(ActionListener { onClick?.invoke(); DesktopApp.bringToFront?.invoke() })
            }
            SystemTray.getSystemTray().add(t)
            icon = t
            t
        }.getOrNull()
    }

    fun show(title: String, body: String, click: (() -> Unit)? = null) {
        java.awt.EventQueue.invokeLater {
            onClick = click
            val t = tray()
            if (t != null) t.displayMessage(title, body, TrayIcon.MessageType.INFO)
            else DesktopApp.toast("$title\n$body")
        }
    }

    fun dispose() {
        icon?.let { i -> runCatching { SystemTray.getSystemTray().remove(i) } }
        icon = null
    }
}
