import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing material lives outside version control. When it is missing the build
// still succeeds and falls back to the debug key, so a checkout without the
// release keystore can be built and run.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use(::load)
    }
}
val releaseStoreFile = keystoreProperties.getProperty("storeFile")?.let(::file)
val hasReleaseSigning = listOf("keyAlias", "keyPassword", "storePassword").all {
    !keystoreProperties.getProperty(it).isNullOrBlank()
} && releaseStoreFile?.isFile == true

android {
    namespace = "com.mystyle.purelive.tv"

    buildFeatures {
        buildConfig = true
    }

    // Pinned rather than inherited so the TV build does not silently shift when
    // the Flutter SDK bumps its defaults.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mystyle.purelive.tv"
        // Flutter's floor stays at its default here on purpose. The phone build
        // raises it to 26 only because its recording engine ships API 26 native
        // binaries, and this build does not include that engine. Keeping the
        // lower floor keeps Android TV 7 boxes installable.
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    // Two renderer variants share one applicationId, so a device treats them
    // as the same app and the user simply picks which APK to install:
    //   impeller — engine default renderer, no manifest override
    //   skia     — legacy renderer for boxes where Impeller misbehaves
    //   (the EnableImpeller opt-out lives in src/skia/AndroidManifest.xml and
    //   only merges into the skia variant)
    flavorDimensions += "renderer"
    productFlavors {
        create("impeller") { dimension = "renderer" }
        create("skia") { dimension = "renderer" }
    }

    buildTypes {
        // Debug builds reuse the release key when it is available, so a debug
        // APK can replace an installed release build without uninstalling first.
        val signing = if (hasReleaseSigning) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
        release {
            signingConfig = signing
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
        }
        debug {
            signingConfig = signing
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
