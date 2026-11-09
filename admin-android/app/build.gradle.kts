plugins {
    id("com.android.application")
}

android {
    namespace = "com.nhomnoname.ecotouradmin"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.nhomnoname.ecotouradmin"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    
    // Retrofit 2 & Gson & OkHttp Logging
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")

    // MPAndroidChart cho bieu do bao cao
    implementation("com.github.PhilJay:MPAndroidChart:v3.1.0")

    // ZXing Android Embedded cho quet QR diem danh
    implementation("com.journeyapps:zxing-android-embedded:4.3.0")
}
