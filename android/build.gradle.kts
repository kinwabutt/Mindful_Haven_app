buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
        // Naye Android versions ke liye ye zaroori hai
        classpath("com.android.tools.build:gradle:8.1.0") 
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
    
    // TELEPHONY NAMESPACE FIX (New Logic)
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.shounakmulay.telephony") {
                // Force a specific version if needed
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// --- NAMESPACE FIX START ---
// Ye block bina 'afterEvaluate' ke kaam karega
subprojects {
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        extensions.configure<com.android.build.gradle.BaseExtension> {
            if (namespace == null) {
                namespace = "com.shounakmulay.telephony"
            }
        }
    }
}
// --- NAMESPACE FIX END ---

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}