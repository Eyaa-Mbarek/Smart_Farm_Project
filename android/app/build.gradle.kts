plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_farm_test"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8 // Changed to Java 8
        targetCompatibility = JavaVersion.VERSION_1_8 // Changed to Java 8
        isCoreLibraryDesugaringEnabled = true // Added desugaring flag
    }

    kotlinOptions {
        jvmTarget = "1.8" // Changed to Java 8
    }

    defaultConfig {
        applicationId = "com.example.smart_farm_test"
        minSdk = 26 // Override Flutter's default if needed (ensure ≥21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // Added desugaring dependency
}

flutter {
    source = "../.."
}