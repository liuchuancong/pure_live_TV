import com.android.build.gradle.BaseExtension
import java.util.Properties
import java.io.File

// The 16 KB page-size fplayer rebuild is not published to any remote repository:
// it ships inside the flv_lzc package, under its own android/libs Maven layout.
// Gradle resolves the *app's* runtime classpath against the repositories of the
// project that owns the configuration, so the plugin's own `repositories {}`
// block cannot help here — the app has to declare that repository itself. The
// path is read from the plugin project instead of a copy inside this repository,
// so a version bump in the package is picked up automatically.
val flvLibs = rootProject.project(":flv_lzc").projectDir.resolve("libs")

allprojects {
    repositories {
        maven(flvLibs) {
            content {
                includeModule("io.github.flutterplayer", "fplayer-core")
            }
        }
        google()
        mavenCentral()
    }
}

val pubspecVersionCode: String by lazy {
    try {
        val pubspecFile = rootProject.file("../pubspec.yaml")
        if (pubspecFile.exists()) {
            val versionLine = pubspecFile.readLines().find { it.trim().startsWith("version:") }
            versionLine?.substringAfterLast("+")?.trim() ?: "1"
        } else {
            "1"
        }
    } catch (e: Exception) {
        "1"
    }
}

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
         if (project.name != "app") {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                if (namespace.isNullOrBlank()) {
                    namespace = project.group.toString()
                }
            }
        }
        tasks.matching { it.name.contains("process", ignoreCase = true) && it.name.contains("Manifest") }.configureEach {
            doLast {
                val targetVersionCode = pubspecVersionCode
                
                outputs.files.forEach { outputDir ->
                    if (outputDir.exists()) {
                        outputDir.walkTopDown().forEach { file ->
                            if (file.name == "AndroidManifest.xml") {
                                try {
                                    val content = file.readText(Charsets.UTF_8)
                                    val pattern = "android:versionCode=\"\\d+\""
                                    val regex = pattern.toRegex()

                                    if (regex.containsMatchIn(content)) {
                                        val replacement = "android:versionCode=\"$targetVersionCode\""
                                        val updatedContent = content.replace(regex, replacement)
                                        file.writeText(updatedContent, Charsets.UTF_8)
                                        println(">>> [PUBSPEC_SYNC] Found: ${file.absolutePath} -> Fixed to $targetVersionCode")
                                    }
                                } catch (e: Exception) { }
                            }
                        }
                    }
                }
            }
        }
    }
}

subprojects {
    if (project.name != "app") {
        evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
