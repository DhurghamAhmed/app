plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin must be applied after Android and Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
    // Google services Gradle plugin for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.idisr.cityvape"
    
    // تم التحديث إلى 36 لحل مشكلة تعارض المكتبات مثل camera و mobile_scanner
    compileSdk = 36 

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.idisr.cityvape"
        
        // الحد الأدنى للتشغيل
        minSdk = flutter.minSdkVersion
        
        // تم التحديث إلى 36 ليتوافق مع compileSdk
        targetSdk = 36
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // تفعيل MultiDex ضروري جداً لمشاريع Firebase و ML Kit
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // يستخدم حالياً مفتاح التصحيح للتشغيل التجريبي
            signingConfig = signingConfigs.getByName("debug")
            
            // تحسينات اختيارية للنسخة النهائية
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // دعم الأجهزة التي تستخدم إصدارات أندرويد قديمة مع مكتبات ضخمة
    implementation("androidx.multidex:multidex:2.0.1")

    // Firebase BoM - إصدار حديث ومستقر
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))

    // مكتبات Firebase الأساسية لمشروعك
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
