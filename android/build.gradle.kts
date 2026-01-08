allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// --- ส่วนแก้ปัญหา Namespace สำหรับ flutter_tflite ---
subprojects {
    plugins.withId("com.android.library") {
        if (project.name == "flutter_tflite") {
            project.extensions.configure<com.android.build.gradle.BaseExtension> {
                namespace = "sq.flutter.tflite"
            }
        }
    }
}