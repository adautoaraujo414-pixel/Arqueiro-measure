// Arquemestre para Windows: projeto separado do Android e do iOS (não entra no build deles).
pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "ArquemestreWindows"
