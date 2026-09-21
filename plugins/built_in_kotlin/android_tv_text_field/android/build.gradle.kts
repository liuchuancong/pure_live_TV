plugins {
    id("com.android.library")
}

group = "com.example.native_textfield_tv"
version = "1.0.0"

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

android {
    namespace = "com.example.native_textfield_tv"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // AGP 9 内建 Kotlin：不再应用 kotlin-android / KGP classpath
    // （上游同时带 AGP 7.3 + KGP 1.7 classpath，会在本工程重复注册
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
        minSdk = 21
    }
}
