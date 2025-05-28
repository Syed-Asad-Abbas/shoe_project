plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.shoe_ecommerce"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.shoe_ecommerce"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../../."
}

dependencies {
    implementation("androidx.core:core-ktx:1.10.1")
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
}

// Simple task to just print the debug keystore SHA-1
tasks.register("getDebugSha1") {
    doLast {
        val debugKeystorePath = "${System.getProperty("user.home")}/.android/debug.keystore"
        
        if (File(debugKeystorePath).exists()) {
            // Execute keytool command to get SHA-1 fingerprint
            exec {
                commandLine(
                    "keytool", 
                    "-list", 
                    "-v", 
                    "-keystore", debugKeystorePath, 
                    "-alias", "androiddebugkey", 
                    "-storepass", "android", 
                    "-keypass", "android"
                )
            }
        } else {
            println("Debug keystore not found at: $debugKeystorePath")
        }
    }
}
