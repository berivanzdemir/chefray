import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ── Release keystore yapılandırması ───────────────────────────────────────
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.chefray.chefray"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.chefray.chefray"
        minSdk = 29 // Android 10+ : MobSF güvenlik skoru için bilinçli olarak yükseltildi
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── Signing configs ───────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
            // key.properties yoksa placeholder kalır — aşağıdaki validation task
            // release build başlatıldığında açık hata verecek
        }
    }

    buildTypes {
        debug {
            // Debug signing normal kalsın — debug keystore kullanır
        }

        release {
            // Release keystore ZORUNLU — debug fallback yok, imzasız APK üretilmez
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            isJniDebuggable = false
            isPseudoLocalesEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// ── Release build validation ─────────────────────────────────────────────
// key.properties yoksa release build açık hata verir, imzasız APK üretilmez.
// Debug build bu kontrolden etkilenmez.
project.afterEvaluate {
    tasks.matching { task ->
        task.name.contains("Release") && (
            task.name.startsWith("assemble") ||
            task.name.startsWith("bundle") ||
            task.name.startsWith("sign")
        )
    }.configureEach {
        doFirst {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "Release signing requires android/key.properties.\n" +
                    "Do not build release APK without a signing key.\n" +
                    "See android/key.properties.example for the expected format.\n" +
                    "See SECURITY_BUILD_NOTES.md for keystore creation instructions."
                )
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
