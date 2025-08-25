plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kinomotomio.moodiary"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.kinomotomio.moodiary"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0-beta.1"
        
        // 多语言支持
        resConfigs("zh", "en")
        
        // ProGuard优化
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            // 启用代码混淆和压缩
            isMinifyEnabled = true
            isShrinkResources = true
            
            // ProGuard规则
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // 签名配置 - 生产环境需要配置真实签名
            signingConfig = signingConfigs.getByName("debug")
            
            // 构建配置
            isDebuggable = false
            isJniDebuggable = false
            isPseudoLocalesEnabled = false
            
            // 性能优化
            renderscriptOptimLevel = 3
        }
        
        debug {
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }
    
    // APK分包配置
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}
