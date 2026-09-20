import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingValue(environmentName: String, propertyName: String): String? =
    System.getenv(environmentName)
        ?: keystoreProperties.getProperty(propertyName)

android {
    namespace = "com.lurc.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.lurc.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePath = signingValue("LURC_KEYSTORE_PATH", "storeFile")
            if (keystorePath != null) {
                storeFile = file(keystorePath)
            }
            storePassword = signingValue("LURC_KEYSTORE_PASSWORD", "storePassword")
            keyAlias = signingValue("LURC_KEY_ALIAS", "keyAlias")
            keyPassword = signingValue("LURC_KEY_PASSWORD", "keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
