#!/usr/bin/env bash
# Підпис release-збірки ключем завантаження Google Play.
# Якщо є android/key.properties (його створює CI з секретів або ти вручну) — release підписується цим ключем,
# інакше — debug-ключем (для тестових APK). Запускається з папки апки після flutter create.
set -euo pipefail
G=android/app/build.gradle.kts
[ -f "$G" ] || { echo "немає $G — пропускаю підпис"; exit 0; }
grep -q keystorePropertiesFile "$G" && exit 0

# імпорти мають бути на початку Kotlin-скрипта
perl -0pi -e 's|\A|import java.io.FileInputStream\nimport java.util.Properties\n\n|' "$G"
# ключ читаємо після блоку plugins { ... }
perl -0pi -e 's|(plugins\s*\{.*?\n\}\n)|$1\nval keystoreProperties = Properties()\nval keystorePropertiesFile = rootProject.file("key.properties")\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n}\n|s' "$G"
# конфіг підпису — одразу на початку android { }
perl -0pi -e 's|(\nandroid\s*\{\n)|$1    signingConfigs {\n        create("release") {\n            if (keystorePropertiesFile.exists()) {\n                keyAlias = keystoreProperties["keyAlias"] as String\n                keyPassword = keystoreProperties["keyPassword"] as String\n                storeFile = file(keystoreProperties["storeFile"] as String)\n                storePassword = keystoreProperties["storePassword"] as String\n            }\n        }\n    }\n|' "$G"
# release: свій ключ, якщо він є
perl -pi -e 's|signingConfig = signingConfigs.getByName\("debug"\)|signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")|' "$G"
grep -q 'signingConfigs.getByName("release")' "$G" || { echo "Не вдалося налаштувати підпис у $G"; exit 1; }
echo "Підпис release налаштовано (key.properties: $( [ -f android/key.properties ] && echo є || echo немає — debug ))"
