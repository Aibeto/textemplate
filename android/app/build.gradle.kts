plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "top.raincrat.textemplate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "top.raincrat.textemplate"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ndk {
        //     abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
        // }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // 动态修改 APK 输出文件名
    applicationVariants.all {
        val variant = this
        variant.outputs.all {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            
            // 获取 pubspec.yaml 中定义的 versionName (例如 "1.2.0")
            val versionName = variant.versionName
            
            // 获取当前的构建类型 (release 或 debug)
            val buildType = variant.buildType.name
            
            // 获取当前的 ABI (armeabi-v7a、arm64-v8a、x86、x86_64)
            val abi = output.filters.find { 
                it.filterType.toString() == "ABI" 
            }?.identifier ?: "universal"

            // 拼接新的文件名
            val newFileName = "apk_${versionName}_${buildType}_${abi}.apk"
            
            output.outputFileName = newFileName
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
