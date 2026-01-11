import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: portakal create <project_name>');
    exit(1);
  }

  String command = args[0];

  if (command != 'create') {
    print('Unknown command: $command');
    exit(1);
  }

  if (args.length < 2) {
    print('Error: Project name is missing.');
    exit(1);
  }

  String projectName = args[1];
  String currentPath = Directory.current.path;
  String projectPath = Directory(
    currentPath + Platform.pathSeparator + projectName,
  ).path;

  print('🍊 [ START ] Starting Portakal Engine...');
  print('🍊 [ 1/6 ] Creating Flutter project: $projectName...');

  var createResult = await Process.run('flutter', [
    'create',
    projectName,
  ], runInShell: true);

  if (createResult.exitCode != 0) {
    print('🧡 [ ERROR ] Failed to create Flutter project.');
    print(createResult.stderr);
    exit(1);
  }

  try {
    await _addDependencies(projectPath);
    await _applyCustomMain(projectPath);
    await _copyCustomLibFolder(projectPath);
    await _configureWindows(projectPath);
    await _configureAndroid(projectPath);
    await _createExtraFiles(projectPath);
    await _configureEnv(projectPath);

    print('🍊 [ SUCCESS ] $projectName is ready! Enjoy your orange juice!');
  } catch (e) {
    print('🧡 [ ERROR ] Something went wrong: $e');
    exit(1);
  }
}

Future<void> _addDependencies(String projectPath) async {
  print('🍊 [ 2/6 ] Fetching latest packages...');

  List<String> packages = [
    'bitsdojo_window',
    'flutter_dotenv',
    'portakal',
    'revani',
  ];

  if (packages.isEmpty) return;

  var result = await Process.run(
    'flutter',
    ['pub', 'add', ...packages],
    workingDirectory: projectPath,
    runInShell: true,
  );

  if (result.exitCode != 0) {
    print('🧡 [ WARN ] Could not add packages.');
    print(result.stderr);
  } else {
    print('    -> Added latest versions of: ${packages.join(", ")}');
  }
}

Future<String> _getExeDirectory() async {
  String exePath = Platform.resolvedExecutable;
  String exeDir = File(exePath).parent.path;

  if (exePath.endsWith('dart.exe') || exePath.endsWith('dart')) {
    String scriptPath = Platform.script.toFilePath();
    return File(scriptPath).parent.path;
  }

  return exeDir;
}

Future<void> _applyCustomMain(String projectPath) async {
  String sourceDir = await _getExeDirectory();
  File templateFile = File(
    sourceDir + Platform.pathSeparator + 'custom_main.dart',
  );

  if (!await templateFile.exists()) {
    print(
      '🧡 [ WARN ] "custom_main.dart" template not found at: ${templateFile.path}',
    );
    return;
  }

  String content = await templateFile.readAsString();
  File projectMain = File(
    projectPath +
        Platform.pathSeparator +
        'lib' +
        Platform.pathSeparator +
        'main.dart',
  );
  await projectMain.writeAsString(content);
  print('    -> Applied custom main.dart template.');
}

Future<void> _copyCustomLibFolder(String projectPath) async {
  String sourceDir = await _getExeDirectory();
  Directory customLibDir = Directory(
    sourceDir + Platform.pathSeparator + 'custom_lib',
  );
  Directory targetLibDir = Directory(
    projectPath + Platform.pathSeparator + 'lib',
  );

  if (!await customLibDir.exists()) {
    print('🧡 [ INFO ] "custom_lib" folder not found.');
    return;
  }

  print('🍊 [ 3/6 ] Injecting custom library files...');
  await _copyDirectory(customLibDir, targetLibDir);
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  if (!await destination.exists()) {
    await destination.create(recursive: true);
  }

  await for (var entity in source.list(recursive: false)) {
    String entityName = entity.path.split(Platform.pathSeparator).last;
    String newPath = destination.path + Platform.pathSeparator + entityName;

    if (entity is Directory) {
      await _copyDirectory(entity, Directory(newPath));
    } else if (entity is File) {
      await entity.copy(newPath);
    }
  }
}

Future<void> _configureWindows(String path) async {
  print('🍊 [ 4/6 ] Configuring Windows...');
  File mainCpp = File(
    path +
        Platform.pathSeparator +
        'windows' +
        Platform.pathSeparator +
        'runner' +
        Platform.pathSeparator +
        'main.cpp',
  );
  if (await mainCpp.exists()) {
    String cppContent = '''
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include "flutter_window.h"
#include "utils.h"
#include <bitsdojo_window_windows/bitsdojo_window_plugin.h>

auto bdw = bitsdojo_window_configure(BDW_CUSTOM_FRAME | BDW_HIDE_ON_STARTUP);

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);

  if (!window.Create(L"App", origin, size)) {
    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
''';
    await mainCpp.writeAsString(cppContent);
  }
}

Future<void> _configureAndroid(String path) async {
  print('🍊 [ 5/6 ] Configuring Android...');
  File gradleFile = File(
    path +
        Platform.pathSeparator +
        'android' +
        Platform.pathSeparator +
        'app' +
        Platform.pathSeparator +
        'build.gradle',
  );
  if (await gradleFile.exists()) {
    String fullGradle = '''
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace "com.example.app"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.app"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    signingConfigs {
        release {
            storeFile file("key.jks")
            storePassword "123456"
            keyAlias "key0"
            keyPassword "123456"
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true 
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

flutter {
    source '../..'
}
''';
    await gradleFile.writeAsString(fullGradle);
  }
}

Future<void> _createExtraFiles(String path) async {
  print('🍊 [ 6/6 ] Finalizing files...');
  await File(
    path + Platform.pathSeparator + 'rules.md',
  ).writeAsString('# Project Rules\n\n1. No comments.\n2. Clean Code.');
  String year = DateTime.now().year.toString();
  String mit = 'MIT License\nCopyright (c) $year\n...';
  await File(path + Platform.pathSeparator + 'LICENSE').writeAsString(mit);
}

Future<void> _configureEnv(String path) async {
  await File(
    path + Platform.pathSeparator + '.env',
  ).writeAsString('APP_NAME=PortakalApp\nAPI_KEY=1234567890\nDEBUG=true\n');

  File gitignore = File(path + Platform.pathSeparator + '.gitignore');
  if (await gitignore.exists()) {
    await gitignore.writeAsString('\n.env\n', mode: FileMode.append);
  }

  File pubspec = File(path + Platform.pathSeparator + 'pubspec.yaml');
  if (await pubspec.exists()) {
    String content = await pubspec.readAsString();
    if (content.contains('uses-material-design: true')) {
      content = content.replaceFirst(
        'uses-material-design: true',
        'uses-material-design: true\n  assets:\n    - .env\n',
      );
      await pubspec.writeAsString(content);
      print('    -> Registered .env in pubspec.yaml assets.');
    }
  }
}
