
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ai_life_coach"
    compileSdk = flutter.compileSdkVersion
    
    // 👇 (1) تم تثبيت نسخة NDK المطلوبة
    ndkVersion = "27.0.12077973"

    compileOptions {
        // 👇👇👇 (تعديل مهم) تفعيل خاصية Desugaring
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID.
        applicationId = "com.example.ai_life_coach"
        
        // 👇 (2) تم تعديل الحد الأدنى لنسخة الأندرويد ليتوافق مع Firebase
        minSdk = 23
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // 👇👇👇 (تعديل مهم) إضافة مكتبة Desugaring المطلوبة للإشعارات
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // TODO: Add the dependencies for Firebase products you want to use
    implementation("com.google.firebase:firebase-analytics")

    // Add the dependencies for any other desired Firebase products
}