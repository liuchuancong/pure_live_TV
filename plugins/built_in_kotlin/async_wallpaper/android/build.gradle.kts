plugins {
    id("com.android.library")
}

group = "com.codenameakshay.async_wallpaper"
version = "3.3.0"

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

android {
    namespace = "com.codenameakshay.async_wallpaper"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // AGP 9 内建 Kotlin：不再应用 kotlin-android / KGP classpath
    // （上游同时带 AGP 8.11.1 + KGP 2.2.20 classpath，会在本工程重复注册
    // kotlin 扩展并导致配置阶段直接失败）。JVM 目标改由这里声明。
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }
}

dependencies {
    implementation("androidx.work:work-runtime-ktx:2.10.2")
    testImplementation("junit:junit:4.13.2")
}
