import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
    kotlin("jvm") version "2.2.21"
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.21"
    id("org.jetbrains.compose") version "1.9.0"
}

group = "br.com.arque.measure"
val runNumber = System.getenv("GITHUB_RUN_NUMBER") ?: "0"
version = "1.0.$runNumber"

// natives do navegador embutido (editor de móveis): Windows no instalador; Linux só pros testes locais
val hostOs = System.getProperty("os.name").lowercase()
val jcefNatives = when {
    hostOs.contains("win") -> "windows-amd64"
    hostOs.contains("mac") -> "macosx-amd64"
    else -> "linux-amd64"
}
val jcefVersion = "135.0.20"
val jcefNativesVersion = providers.gradleProperty("jcefNativesVersion").orNull

dependencies {
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation(compose.materialIconsExtended)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-swing:1.10.2")
    implementation("org.json:json:20240303")
    implementation("org.apache.pdfbox:pdfbox:3.0.3")
    implementation("me.friwi:jcefmaven:$jcefVersion")
    if (jcefNativesVersion != null) runtimeOnly("me.friwi:jcef-natives-$jcefNatives:$jcefNativesVersion")

    testImplementation(kotlin("test"))
    testImplementation("junit:junit:4.13.2")
    testImplementation(compose.desktop.uiTestJUnit4)
}

kotlin { jvmToolchain(21) }

// o editor de móveis e as traduções vêm direto do app Android: o Windows usa sempre a versão mais nova
val sharedAssets = layout.buildDirectory.dir("generated/arqueAssets")
val copySharedAssets by tasks.registering(Sync::class) {
    from("../app/src/main/assets") { include("editor.html", "i18n/**") }
    into(sharedAssets.map { it.dir("assets") })
}
// número desta versão (o mesmo do release win-N): o app usa pra saber se há versão nova
val buildInfo = layout.buildDirectory.dir("generated/arqueBuild")
val writeBuildInfo by tasks.registering {
    val n = runNumber
    outputs.dir(buildInfo)
    doLast { buildInfo.get().file("build-number.txt").asFile.apply { parentFile.mkdirs() }.writeText(n) }
}
sourceSets.main { resources.srcDir(sharedAssets); resources.srcDir(buildInfo) }
tasks.named("processResources") { dependsOn(copySharedAssets, writeBuildInfo) }

tasks.test {
    useJUnit()
    systemProperty("arque.test", "1")
    val td = layout.buildDirectory.dir("testdata").get().asFile
    systemProperty("arque.data", File(td, "dados").path)
    systemProperty("arque.docs", File(td, "documentos").path)
    systemProperty("arque.pics", File(td, "imagens").path)
    systemProperty("arque.multi", "1")
    doFirst { td.deleteRecursively() }
    testLogging { events("passed", "failed", "skipped"); showStandardStreams = true; exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL }
}

/** Baixa tudo que o build usa (cache offline pra compilar e testar fora do GitHub). */
tasks.register("resolveAll") {
    doLast {
        configurations.filter { it.isCanBeResolved }.forEach { c ->
            runCatching { c.resolve() }.onFailure { println("não resolveu ${c.name}: ${it.message}") }
        }
    }
}

compose.desktop {
    application {
        mainClass = "br.com.arque.measure.MainKt"
        jvmArgs += listOf("-Dfile.encoding=UTF-8", "-Xmx1g")
        nativeDistributions {
            targetFormats(TargetFormat.Msi, TargetFormat.Exe)
            packageName = "Arquemestre"
            packageVersion = "1.0.${runNumber.toIntOrNull()?.coerceAtMost(65535) ?: 0}"
            description = "Arquemestre - medição, projeto de móveis, corte, orçamento e agenda"
            vendor = "Arque"
            copyright = "Arque"
            includeAllModules = true
            // o pacote MSI/EXE usa o número do build; o nome da pasta instalada fica "Arquemestre"
            windows {
                menu = true
                menuGroup = "Arquemestre"
                shortcut = true
                dirChooser = true
                perUserInstall = true
                upgradeUuid = "5d7c2f8e-3b1a-4c6e-9f2d-a1b8c4e7d903"
                iconFile.set(project.file("icons/arquemestre.ico"))
            }
        }
    }
}
