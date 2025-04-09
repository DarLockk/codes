buildscript {
    repositories {
        google()
        jcenter() // jcenter() est en fin de vie, préfère mavenCentral()
    }

    dependencies {
        // Il est important de spécifier une version du plugin
        classpath("com.google.gms:google-services:4.4.2")  // Indiquer la version correcte du plugin
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Définir un nouveau dossier de build
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)  // Utilisation de 'set()' au lieu de 'value'

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)  // Correction de 'set()'
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Tâche de nettoyage
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}