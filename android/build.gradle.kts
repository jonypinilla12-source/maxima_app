buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Esta línea le dice a Gradle qué versión exacta de Firebase descargar
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    // 1. PRIMERO le decimos a Gradle: "Cuando evalúes un plugin, ponle SDK 36"
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(androidExt, 36)
            } catch (e: Exception) {
                // Lo ignoramos si el plugin no tiene esta propiedad
            }
        }
    }
    
    // 2. DESPUÉS disparamos la evaluación (El orden aquí es la clave para que no falle)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}