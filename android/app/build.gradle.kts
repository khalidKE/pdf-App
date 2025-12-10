plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pdf_tools.pdf_utility_pro"
    compileSdk = flutter.compileSdkVersion
    // Use installed stable NDK to ensure 16 KB page-size support and satisfy plugins
    ndkVersion = "27.1.12297006"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pdf_tools.pdf_utility_pro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

 signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "123khabu45"
            storeFile = file("../app/upload-keystore.jks")
            storePassword = "123khabu45"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        jniLibs {
            // Explicitly disable legacy packaging; required for modern page-size support
            useLegacyPackaging = false
        }
    }
}

flutter {
    source = "../.."
}
