plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "br.com.arque.measure"
    compileSdk = 36

    defaultConfig {
        applicationId = "br.com.arque.measure"
        minSdk = 26
        targetSdk = 36
        versionCode = (System.getenv("GITHUB_RUN_NUMBER")?.toIntOrNull() ?: 1)
        versionName = "1.0." + (System.getenv("GITHUB_RUN_NUMBER") ?: "0")
    }

    // site = APK do GitHub (atualiza sozinho, desbloqueio por senha)
    // play = Google Play (sem atualizador próprio, desbloqueio pela compra no Google Play)
    flavorDimensions += "loja"
    productFlavors {
        create("site") {
            dimension = "loja"
            buildConfigField("boolean", "PLAY", "false")
            buildConfigField("int", "TRIAL_DAYS", "2")
        }
        create("play") {
            dimension = "loja"
            buildConfigField("boolean", "PLAY", "true")
            // no Google Play o teste grátis é o da assinatura (oferta de 3 dias no Play Console), não um teste do app
            buildConfigField("int", "TRIAL_DAYS", "0")
        }
    }

    // Chave FIXA do APK de teste: sem ela cada build sai com uma assinatura diferente e o Android
    // obriga a desinstalar (apagando os dados). Com ela, a versão nova instala por cima e mantém tudo.
    signingConfigs {
        getByName("debug") {
            storeFile = file("arque-debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    buildFeatures {
        compose = true
        buildConfig = true
    }

    lint {
        // O relatório de lint é publicado como artefato; avisos não bloqueiam o APK.
        abortOnError = false
        checkReleaseBuilds = false
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.10.01")
    implementation(composeBom)

    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.exifinterface:exifinterface:1.3.7")
    implementation("androidx.webkit:webkit:1.12.1")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    "playImplementation"("com.android.billingclient:billing-ktx:8.3.0")

    testImplementation("junit:junit:4.13.2")
    // org.json do android.jar é só um stub nos testes de JVM.
    testImplementation("org.json:json:20240303")
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
