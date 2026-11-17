# Windows-версія setup.sh. Запуск один раз з папки recipes_app:
#   powershell -ExecutionPolicy Bypass -File setup.ps1
$ErrorActionPreference = "Stop"

flutter create --org com.koreec --project-name shcho_pryhotuvaty --platforms=android,ios .

function Edit-File($path, [scriptblock]$change) {
  if (-not (Test-Path $path)) { return }
  $text = [IO.File]::ReadAllText($path)
  $new = & $change $text
  if ($new -ne $text) { [IO.File]::WriteAllText($path, $new, (New-Object Text.UTF8Encoding $false)) }
}

# Дозвіл на інтернет і назва апки
Edit-File "android/app/src/main/AndroidManifest.xml" {
  param($t)
  if ($t -notmatch "android.permission.INTERNET") {
    $t = [regex]::Replace($t, '(<manifest[^>]*>)', "`$1`n    <uses-permission android:name=`"android.permission.INTERNET`"/>")
  }
  if ($t -notmatch "android.permission.RECORD_AUDIO") {
    $t = $t.Replace('<uses-permission android:name="android.permission.INTERNET"/>', "<uses-permission android:name=`"android.permission.INTERNET`"/>`n    <uses-permission android:name=`"android.permission.RECORD_AUDIO`"/>`n    <queries>`n        <intent><action android:name=`"android.speech.RecognitionService`"/></intent>`n        <intent><action android:name=`"android.intent.action.TTS_SERVICE`"/></intent>`n    </queries>")
  }
  [regex]::Replace($t, 'android:label="[^"]*"', 'android:label="@string/app_name"')
}

# Назва апки мовою телефона
$utf8 = New-Object Text.UTF8Encoding $false
New-Item -ItemType Directory -Force -Path "android/app/src/main/res/values", "android/app/src/main/res/values-pl" | Out-Null
[IO.File]::WriteAllText("android/app/src/main/res/values/strings.xml", "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n<resources>`n    <string name=`"app_name`">Що приготувати</string>`n</resources>`n", $utf8)
[IO.File]::WriteAllText("android/app/src/main/res/values-pl/strings.xml", "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n<resources>`n    <string name=`"app_name`">Co ugotować</string>`n</resources>`n", $utf8)

# Тільки debug: http до сервера на ПК (release — лише https)
Edit-File "android/app/src/debug/AndroidManifest.xml" {
  param($t)
  if ($t -match "usesCleartextTraffic") { return $t }
  $t.Replace("</manifest>", "    <application android:usesCleartextTraffic=`"true`"/>`n</manifest>")
}

# iOS: тексти дозволів камери й галереї
Edit-File "ios/Runner/Info.plist" {
  param($t)
  if ($t -notmatch "NSCameraUsageDescription") {
    $t = [regex]::Replace($t, '</dict>\s*</plist>', "`t<key>NSCameraUsageDescription</key>`n`t<string>Щоб сфотографувати продукти і підібрати рецепти</string>`n`t<key>NSPhotoLibraryUsageDescription</key>`n`t<string>Щоб вибрати фото продуктів з галереї</string>`n</dict>`n</plist>")
  }
  if ($t -notmatch "NSMicrophoneUsageDescription") {
    $t = [regex]::Replace($t, '</dict>\s*</plist>', "`t<key>NSMicrophoneUsageDescription</key>`n`t<string>Щоб керувати рецептом голосом: «далі», «назад», «таймер»</string>`n`t<key>NSSpeechRecognitionUsageDescription</key>`n`t<string>Щоб розпізнавати голосові команди під час готування</string>`n</dict>`n</plist>")
  }
  if ($t -notmatch "NSAllowsLocalNetworking") {
    $t = [regex]::Replace($t, '</dict>\s*</plist>', "`t<key>NSAppTransportSecurity</key>`n`t<dict>`n`t`t<key>NSAllowsLocalNetworking</key>`n`t`t<true/>`n`t</dict>`n</dict>`n</plist>")
  }
  [regex]::Replace($t, '(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', '${1}Що приготувати${2}')
}

flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
Write-Host "Готово. Запуск: flutter run --dart-define=API_URL=http://IP_ТВОГО_ПК:8000 --dart-define=API_KEY=КЛЮЧ_АПКИ"
