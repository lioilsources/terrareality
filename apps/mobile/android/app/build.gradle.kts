import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: the Play upload key from the git-ignored android/key.properties
// (template: key.properties.example; steps in docs/runbooks/launch.md section 8).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) FileInputStream(keystorePropertiesFile).use { load(it) }
}
val hasReleaseKey = keystorePropertiesFile.exists()

android {
    namespace = "cz.terrareality.terrareality"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "cz.terrareality.terrareality"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Never the debug key: without key.properties the release build fails below.
            if (hasReleaseKey) signingConfig = signingConfigs.getByName("release")
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

// A release artifact signed with the debug key (or unsigned) must never reach
// Play: fail any release assemble/bundle without the upload key.
gradle.taskGraph.whenReady {
    val releaseTask = allTasks.any { t ->
        t.project == project && (t.name == "assembleRelease" || t.name == "bundleRelease" ||
            t.name == "packageRelease" || t.name == "signReleaseBundle")
    }
    if (releaseTask && !hasReleaseKey) {
        throw GradleException(
            "Release signing is not configured: create android/key.properties " +
                "(see android/key.properties.example and docs/runbooks/launch.md section 8).",
        )
    }
}
