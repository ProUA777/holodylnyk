#!/usr/bin/env bash
# Генерує платформні папки (android/ios) і прописує потрібні дозволи.
# Запуск один раз з папки recipes_app:  bash setup.sh
set -euo pipefail

flutter create --org com.koreec --project-name shcho_pryhotuvaty --platforms=android,ios .

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  # Без цього дозволу release-збірка Android не матиме доступу до мережі
  perl -0pi -e 's|(<manifest[^>]*>)|$1\n    <uses-permission android:name="android.permission.INTERNET"/>|' "$MANIFEST"
fi
# Мікрофон для «Готувати голосом» + доступ до сервісів розпізнавання й озвучки (Android 11+)
if ! grep -q 'android.permission.RECORD_AUDIO' "$MANIFEST"; then
  perl -0pi -e 's|(<uses-permission android:name="android.permission.INTERNET"/>)|$1\n    <uses-permission android:name="android.permission.RECORD_AUDIO"/>\n    <queries>\n        <intent><action android:name="android.speech.RecognitionService"/></intent>\n        <intent><action android:name="android.intent.action.TTS_SERVICE"/></intent>\n    </queries>|' "$MANIFEST"
fi
# Назва апки мовою телефона: українська за замовчуванням, польська для pl
perl -pi -e 's|android:label="[^"]*"|android:label="\@string/app_name"|' "$MANIFEST"
mkdir -p android/app/src/main/res/values android/app/src/main/res/values-pl
printf '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <string name="app_name">Що приготувати</string>\n</resources>\n' > android/app/src/main/res/values/strings.xml
printf '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <string name="app_name">Co ugotować</string>\n</resources>\n' > android/app/src/main/res/values-pl/strings.xml

# Тільки для debug-збірки: дозволяємо http до сервера на твоєму ПК (release працює лише з https)
DEBUG_MANIFEST=android/app/src/debug/AndroidManifest.xml
if [ -f "$DEBUG_MANIFEST" ] && ! grep -q usesCleartextTraffic "$DEBUG_MANIFEST"; then
  perl -0pi -e 's|</manifest>|    <application android:usesCleartextTraffic="true"/>\n</manifest>|' "$DEBUG_MANIFEST"
fi

PLIST=ios/Runner/Info.plist
if [ -f "$PLIST" ] && ! grep -q NSCameraUsageDescription "$PLIST"; then
  perl -0pi -e 's|</dict>\s*</plist>|\t<key>NSCameraUsageDescription</key>\n\t<string>Щоб сфотографувати продукти і підібрати рецепти</string>\n\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>Щоб вибрати фото продуктів з галереї</string>\n</dict>\n</plist>|' "$PLIST"
fi
if [ -f "$PLIST" ] && ! grep -q NSMicrophoneUsageDescription "$PLIST"; then
  perl -0pi -e 's|</dict>\s*</plist>|\t<key>NSMicrophoneUsageDescription</key>\n\t<string>Щоб керувати рецептом голосом: «далі», «назад», «таймер»</string>\n\t<key>NSSpeechRecognitionUsageDescription</key>\n\t<string>Щоб розпізнавати голосові команди під час готування</string>\n</dict>\n</plist>|' "$PLIST"
fi
if [ -f "$PLIST" ] && ! grep -q NSAllowsLocalNetworking "$PLIST"; then
  perl -0pi -e 's|</dict>\s*</plist>|\t<key>NSAppTransportSecurity</key>\n\t<dict>\n\t\t<key>NSAllowsLocalNetworking</key>\n\t\t<true/>\n\t</dict>\n</dict>\n</plist>|' "$PLIST"
fi
if [ -f "$PLIST" ]; then
  perl -0pi -e 's|(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)|${1}Що приготувати${2}|' "$PLIST"
fi

flutter pub get
dart run flutter_launcher_icons        # іконка апки з assets/icon
dart run flutter_native_splash:create  # заставка при запуску
echo "Готово. Запуск: flutter run --dart-define=API_URL=http://IP_ТВОГО_ПК:8000 --dart-define=API_KEY=КЛЮЧ_АПКИ"
