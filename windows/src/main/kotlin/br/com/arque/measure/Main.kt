package br.com.arque.measure

import androidx.compose.material3.Text
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application

// esqueleto provisório: o app completo entra nos próximos commits
fun main() = application {
    Window(onCloseRequest = ::exitApplication, title = "Arquemestre") {
        Text("Arquemestre " + org.cef.CefApp::class.java.simpleName + " " + org.apache.pdfbox.pdmodel.PDDocument::class.java.simpleName + " " + org.json.JSONObject().toString())
    }
}
