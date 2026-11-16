package br.com.arque.measure.desktop
import java.io.File
object DesktopApp { var requestExit: (() -> Unit)? = null }
object Paths { val documents: File = File(System.getProperty("java.io.tmpdir"), "arque-docs") }
