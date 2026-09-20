import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. The key and its passwords live in the git-ignored
// `android_release_key_private/` folder at the project root (see docs/setup_manual.md,
// "Release signing key"). If that folder is missing, release builds fall
// back to the debug key so `flutter run --release` still works.
val signingDir = rootProject.file("../android_release_key_private")
val keyPropertiesFile = File(signingDir, "key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    FileInputStream(keyPropertiesFile).use { keyProperties.load(it) }
}
val hasReleaseKey = keyPropertiesFile.exists()
if (!hasReleaseKey) {
    println(
        "WARNING: android_release_key_private/key.properties not found. Release builds will be " +
            "signed with the DEBUG key and can't update a properly signed install."
    )
}

// Android needs a whole number (versionCode) that goes up with every
// release, or it refuses to install the update. Instead of writing "+N" in
// pubspec.yaml, it's calculated from the version name:
//   MAJOR * 10000 + MINOR * 100 + PATCH   e.g. 1.0.0 -> 10000, 1.2.3 -> 10203
// So MINOR and PATCH must stay below 100.
fun versionCodeFrom(versionName: String?): Int {
    val parts = Regex("^(\\d+)\\.(\\d+)\\.(\\d+)").find(versionName ?: "")
        ?: error("Version '$versionName' in pubspec.yaml must look like 1.2.3")
    val (major, minor, patch) = parts.destructured
    require(minor.toInt() < 100 && patch.toInt() < 100) {
        "Minor and patch numbers must be below 100 (got $versionName)"
    }
    return major.toInt() * 10000 + minor.toInt() * 100 + patch.toInt()
}

android {
    namespace = "com.cantonesedictionary.cantonese_dictionary"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cantonesedictionary.cantonese_dictionary"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = versionCodeFrom(flutter.versionName)
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = File(signingDir, keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
