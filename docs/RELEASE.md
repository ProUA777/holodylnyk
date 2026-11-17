# Реліз «Що зібрати?» у Google Play — покроково

Орієнтовний час: 1–2 дні роботи + **14 днів закритого тестування** (обов'язково для нових особистих акаунтів розробника).

## 0. Що знадобиться
- Flutter **3.35 або новіший** (`flutter --version`), Android Studio або Android SDK, Java 17.
- Акаунт Google Play Console (одноразовий внесок 25 $).
- Сервер з Docker (будь-який VPS на 1 ГБ RAM) і домен, наприклад `api.whattobuild.app`.
- Ключ Anthropic API.

## 1. Сервер (≈ 30 хв)
```bash
cd backend
cp .env.example .env
#  AI_PROVIDER=anthropic
#  ANTHROPIC_API_KEY=sk-ant-...
#  APP_KEYS=<довгий випадковий ключ>      ← згенеруй: python -c "import secrets;print(secrets.token_urlsafe(32))"
#  DOMAIN=api.whattobuild.app
docker compose up -d --build
curl https://api.whattobuild.app/health        # {"ok": true, ...}
```
Перевір, що відкривається `https://api.whattobuild.app/privacy`: це посилання піде в Play Console.

## 2. Перший запуск застосунку (≈ 15 хв)
```bash
cd mobile
flutter pub get
dart run tool/setup_platforms.dart     # створить android/ та ios/, іконки, заставку, дозволи
flutter test                           # тести каталогу й розбору AI-відповідей
flutter run                            # емулятор → локальний бекенд на 10.0.2.2:8000
```
Щоб застосунок на реальному телефоні звертався до бойового сервера:
```bash
flutter run --dart-define=API_BASE=https://api.whattobuild.app --dart-define=APP_KEY=<ключ з APP_KEYS>
```

## 3. Ключ підпису (один раз, бережи як зіницю ока)
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Створи `mobile/android/key.properties`. Він уже в `.gitignore`, не коміть його:
```
storeFile=/повний/шлях/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```
`setup_platforms.dart` уже під'єднав цей файл до `build.gradle.kts`.

## 4. Збірка релізу
```bash
flutter build appbundle --release \
  --dart-define=API_BASE=https://api.whattobuild.app \
  --dart-define=APP_KEY=<ключ>
# результат: build/app/outputs/bundle/release/app-release.aab
```
Або через GitHub Actions (`.github/workflows/android.yml`). Додай у Settings → Secrets репозиторію:
`API_BASE`, `APP_KEY`, `KEYSTORE_BASE64` (`base64 -w0 upload-keystore.jks`), `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
Кожен push у `main` прожене тести й збере `.apk` та `.aab` в Artifacts.

## 5. Play Console
1. **Створити застосунок**. Назва: «Що зібрати? Ідеї з деталей», мова за замовчуванням — українська, тип — застосунок, безкоштовний.
2. **Сторінка в магазині**: тексти з `store/listing.md`, графіка з `store/graphics/`. Додай переклади pl-PL та en-US.
3. **Політика конфіденційності**: `https://<домен>/privacy`.
4. **Безпека даних**, **Цільова аудиторія**, **Рейтинг вмісту**: відповіді в `store/data-safety.md`.
5. **Доступ до застосунку**: «Усі функції доступні без обмежень».
6. **Реклама**: «Ні».

## 6. Тестування → продакшн
- **Внутрішнє тестування**: завантаж `.aab` і встанови на свій телефон через посилання.
- **Закрите тестування**: щонайменше **12 тестувальників** мають бути в тесті **14 днів поспіль**. Це вимога для особистих акаунтів, створених після листопада 2023 року. Познач у формі, що саме перевіряли тестувальники.
- Після цього в Dashboard з'явиться кнопка **Apply for production**. Огляд зазвичай займає від кількох днів до тижня.

## 7. Після релізу
- Раз на тиждень переглядай скарги на AI-відповіді (команда в `store/data-safety.md`).
- Витрати на AI: кожне сканування коштує одного запиту з фото. Денний ліміт `DAILY_LIMIT` захищає бюджет.
- Нова модель у каталозі: намалюй її пошарово в `prototype/models/build_models.py`, запусти скрипт, і `mobile/assets/catalog.json` та прототип оновляться разом. Потім збільш `version:` у `pubspec.yaml`.

## iOS (пізніше)
Код уже кросплатформний. `setup_platforms.dart` налаштовує `Info.plist` (камера, фото, назва). Для App Store потрібні Mac із Xcode й акаунт Apple Developer (99 $/рік): `flutter build ipa`.
