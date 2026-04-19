import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Load per-flavor signing properties ────────────────────────────────────────
fun loadProps(fileName: String): Properties {
    val props = Properties()
    val file = rootProject.file("keystores/$fileName")
    if (file.exists()) props.load(file.inputStream())
    return props
}

val jmukhisicsProps   = loadProps("jmukhisics.properties")
val sicschoolProps    = loadProps("sicschool.properties")
val schoolfeeproProps = loadProps("schoolfeepro.properties")
val theshivalikProps  = loadProps("theshivalik.properties")

android {
    namespace  = "in.jmukhisics.mobile_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JvmTarget.JVM_17.target
    }

    defaultConfig {
        applicationId = "in.jmukhisics.mobile_app"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    // ── Signing configs ────────────────────────────────────────────────────────
    signingConfigs {
        create("jmukhisics") {
            storeFile     = rootProject.file(jmukhisicsProps["storeFile"]   as String)
            storePassword = jmukhisicsProps["storePassword"]                as String
            keyAlias      = jmukhisicsProps["keyAlias"]                     as String
            keyPassword   = jmukhisicsProps["keyPassword"]                  as String
        }
        create("sicschool") {
            storeFile     = rootProject.file(sicschoolProps["storeFile"]    as String)
            storePassword = sicschoolProps["storePassword"]                 as String
            keyAlias      = sicschoolProps["keyAlias"]                      as String
            keyPassword   = sicschoolProps["keyPassword"]                   as String
        }
        create("schoolfeepro") {
            storeFile     = rootProject.file(schoolfeeproProps["storeFile"] as String)
            storePassword = schoolfeeproProps["storePassword"]              as String
            keyAlias      = schoolfeeproProps["keyAlias"]                   as String
            keyPassword   = schoolfeeproProps["keyPassword"]                as String
        }
        create("theshivalik") {
            storeFile     = rootProject.file(theshivalikProps["storeFile"] as String)
            storePassword = theshivalikProps["storePassword"]              as String
            keyAlias      = theshivalikProps["keyAlias"]                   as String
            keyPassword   = theshivalikProps["keyPassword"]                as String
        }
    }

    // ── Flavors ────────────────────────────────────────────────────────────────
    flavorDimensions += "app"

    productFlavors {
        create("jmukhisics") {
            dimension     = "app"
            applicationId = "in.jmukhisics.mobile_app"
            versionCode   = 4
            versionName   = "1.0.3"
            resValue("string", "app_name", "JMukhisics")
            signingConfig = signingConfigs.getByName("jmukhisics")
        }
        create("sicschool") {
            dimension     = "app"
            applicationId = "in.sicschool.mobile_app"
            versionCode   = 4
            versionName   = "1.0.3"
            resValue("string", "app_name", "SIC School")
            signingConfig = signingConfigs.getByName("sicschool")
        }
        create("schoolfeepro") {
            dimension     = "app"
            applicationId = "in.schoolfeepro.mobile_app"
            versionCode   = 4
            versionName   = "1.0.3"
            resValue("string", "app_name", "SchoolFeePro")
            signingConfig = signingConfigs.getByName("schoolfeepro")
        }
        create("theshivalik") {
            dimension     = "app"
            applicationId = "in.theshivalik.mobile_app"
            versionCode   = 3
            versionName   = "1.0.2"
            resValue("string", "app_name", "The Shivalik")
            signingConfig = signingConfigs.getByName("theshivalik")
        }
    }

    // ── Build types ────────────────────────────────────────────────────────────
    buildTypes {
        debug {
            isMinifyEnabled = false
        }
        release {
            isMinifyEnabled   = false
            isShrinkResources = false
            // signingConfig is set per-flavor above
        }
    }

    // ── Handle 16 KB page size alignment (Android 15+) ─────────────────────────
    packagingOptions {
        resources {
            excludes += "META-INF/DEPENDENCIES"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// ── Suppress warnings from third-party libraries ──────────────────────────────
tasks.withType<JavaCompile> {
    options.compilerArgs.addAll(listOf(
        "-Xlint:-unchecked",
        "-Xlint:-deprecation",
        "-Xlint:-removal"
    ))
}
