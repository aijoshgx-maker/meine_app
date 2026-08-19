import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signaturdaten aus android/key.properties. Die Datei enthaelt Passwoerter
// und ist per .gitignore ausgeschlossen; im CI wird sie aus Secrets
// wiederhergestellt (siehe .github/workflows/android-play-aab.yml).
//
// Fehlt sie, faellt der Release-Build bewusst auf den Debug-Key zurueck,
// damit "flutter run --release" lokal weiter funktioniert. Ein so gebautes
// Paket ist NICHT store-tauglich - die Pruefung dafuer steht in
// docs/release-checklist.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hatSignaturDaten = keystorePropertiesFile.exists()
if (hatSignaturDaten) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "joshai.meine_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Von flutter_local_notifications benötigt (Java 8+ API-Backport).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "joshai.meine_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hatSignaturDaten) {
            create("upload") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hatSignaturDaten) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }

            // R8: verkleinert das Paket und entfernt ungenutzten Code.
            // Die Regeln in proguard-rules.pro schuetzen die Stellen, an
            // denen Plugins per Reflexion arbeiten.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
