// Creates and configures the android/ and ios/ folders. Safe to run again.
//
//   dart run tool/setup_platforms.dart
//
// What it does:
//   1. flutter create (android + ios) if the folders are missing
//   2. Android: INTERNET permission, localized app name, applicationId, release signing from key.properties
//   3. iOS: camera / photo library usage texts, display name, localizations
//   4. app icons (flutter_launcher_icons) and splash screen (flutter_native_splash)
import 'dart:io';

const appId = 'com.koreec.whattobuild';
const names = {'en': 'What to build?', 'uk': 'Що зібрати?', 'pl': 'Co zbudować?'};

Future<void> main(List<String> args) async {
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final dart = Platform.isWindows ? 'dart.bat' : 'dart';

  if (!Directory('android').existsSync() || !Directory('ios').existsSync()) {
    await _run(flutter, ['create', '--org', 'com.koreec', '--project-name', 'what_to_build', '--platforms', 'android,ios', '.']);
  }
  // flutter create adds a counter-app test that does not compile against this app.
  final sample = File('test/widget_test.dart');
  if (sample.existsSync() && sample.readAsStringSync().contains('MyApp')) sample.deleteSync();

  _android();
  _ios();

  await _run(flutter, ['pub', 'get']);
  await _run(dart, ['run', 'flutter_launcher_icons']);
  await _run(dart, ['run', 'flutter_native_splash:create']);
  stdout.writeln('\n✓ Platforms are ready. Next: flutter run');
}

void _android() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  var m = manifest.readAsStringSync();
  if (!m.contains('android.permission.INTERNET')) {
    m = m.replaceFirst('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application');
  }
  m = m.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="@string/app_name"');
  manifest.writeAsStringSync(m);

  // Debug builds only: allow plain HTTP to the local dev server (10.0.2.2). Release stays HTTPS-only.
  final debug = File('android/app/src/debug/AndroidManifest.xml');
  if (debug.existsSync()) {
    var d = debug.readAsStringSync();
    if (!d.contains('usesCleartextTraffic')) {
      d = d.replaceFirst('</manifest>', '    <application android:usesCleartextTraffic="true"/>\n</manifest>');
      debug.writeAsStringSync(d);
    }
  }

  for (final e in names.entries) {
    final dir = Directory('android/app/src/main/res/values${e.key == 'en' ? '' : '-${e.key}'}')..createSync(recursive: true);
    File('${dir.path}/strings.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <string name="app_name">${e.value.replaceAll("'", r"\'")}</string>\n</resources>\n',
    );
  }

  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) {
    var g = kts.readAsStringSync();
    g = g.replaceFirst(RegExp(r'applicationId = "[^"]*"'), 'applicationId = "$appId"');
    if (!g.contains('keystoreProperties')) {
      g = g.replaceFirst('android {', '''
val keystoreProperties = java.util.Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {''');
      g = g.replaceFirst(RegExp(r' *buildTypes \{'), '''    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {''');
      g = g.replaceFirst(
        'signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = if (keystoreProperties.isNotEmpty()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
      );
    }
    kts.writeAsStringSync(g);
  } else if (groovy.existsSync()) {
    groovy.writeAsStringSync(groovy.readAsStringSync().replaceFirst(RegExp(r'applicationId "[^"]*"'), 'applicationId "$appId"'));
    stdout.writeln('! Old Groovy build.gradle: add release signing by hand (see docs/RELEASE.md).');
  }
}

void _ios() {
  final plist = File('ios/Runner/Info.plist');
  if (!plist.existsSync()) return;
  var p = plist.readAsStringSync();
  void put(String key, String value) {
    final re = RegExp('<key>$key</key>\\s*<string>[^<]*</string>');
    final entry = '<key>$key</key>\n\t<string>$value</string>';
    p = re.hasMatch(p) ? p.replaceFirst(re, entry) : p.replaceFirst('<dict>', '<dict>\n\t$entry');
  }

  put('CFBundleDisplayName', names['uk']!);
  put('NSCameraUsageDescription', 'Камера потрібна, щоб сфотографувати деталі конструктора. / The camera is used to photograph your bricks.');
  put('NSPhotoLibraryUsageDescription', 'Доступ до фото потрібен, щоб вибрати знімок деталей. / Photo access lets you pick a picture of your bricks.');
  if (!p.contains('CFBundleLocalizations')) {
    p = p.replaceFirst('<dict>', '<dict>\n\t<key>CFBundleLocalizations</key>\n\t<array>\n\t\t<string>uk</string>\n\t\t<string>pl</string>\n\t\t<string>en</string>\n\t</array>');
  }
  plist.writeAsStringSync(p);
}

Future<void> _run(String cmd, List<String> args) async {
  stdout.writeln('\$ $cmd ${args.join(' ')}');
  final r = await Process.start(cmd, args, mode: ProcessStartMode.inheritStdio, runInShell: Platform.isWindows);
  final code = await r.exitCode;
  if (code != 0) {
    stderr.writeln('✗ "$cmd ${args.join(' ')}" failed with code $code');
    exit(code);
  }
}
