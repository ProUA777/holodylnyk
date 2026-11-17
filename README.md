# Що зібрати? · What to build? · Co zbudować?

Застосунок для дітей і батьків: фото купки деталей конструктора → AI пропонує моделі з тих деталей, що є → покрокова 3D-збірка. Плюс каталог із 103 моделей (4 рівні складності, 11 категорій) і колекція з досягненнями.

© by Greater Koreec Project Group

## Структура

```
mobile/                     Flutter-застосунок (Android + iOS)
  lib/main.dart             запуск, тема, мова, онбординг ↔ головна
  lib/screens/              онбординг, головна, каталог, деталь (3D-кроки), сканування, результат, мої збірки, налаштування
  lib/render/iso.dart       ізометричний 3D-рендер цеглинок з анімацією
  lib/data/                 каталог (assets/catalog.json) і клієнт API
  lib/state/app_state.dart  мова, тема, збірки — зберігаються на пристрої
  lib/i18n.dart             тексти uk / pl / en і політика конфіденційності
  assets/                   catalog.json, шрифти Fredoka і Nunito (OFL), іконка, заставка
  tool/setup_platforms.dart створює й налаштовує android/ та ios/
  test/                     тести каталогу й розбору AI-відповідей
backend/                    FastAPI: AI-аналіз фото, денні ліміти (SQLite), скарги, /privacy
  docker-compose.yml        API + автоматичний HTTPS (Caddy)
prototype/                  веб-прототип з тим самим дизайном
  models/build_models.py    генератор каталогу: моделі пошарово + more_models.py з геометричними помічниками (103 моделі)
store/                      тексти для Google Play (3 мови), графіка, відповіді для Data safety
docs/RELEASE.md             покрокова інструкція релізу
.github/workflows/          CI: тести бекенду, flutter analyze/test, збірка APK + AAB
```

## Швидкий старт

```bash
# сервер (тестовий режим без ключа AI)
cd backend && pip install -r requirements.txt && cp .env.example .env
pytest -q && uvicorn app.main:app --host 0.0.0.0 --port 8000

# застосунок
cd mobile && flutter pub get
dart run tool/setup_platforms.dart
flutter run
```

Повний шлях до Google Play описано в [docs/RELEASE.md](docs/RELEASE.md).

## Як перевірено
- Бекенд: 13 тестів pytest (ліміти, скарги, політика, обробка помилок, тестові AI-відповіді з 3D-кроками).
- Flutter: увесь код проходить `dart analyze` без жодного зауваження. Аналіз запускався на Flutter 3.47.9 із правилами `flutter_lints`. Самого запуску на пристрої ще не було, тож перший `flutter run` — за тобою.
- Каталог: 103 моделі пройшли візуальну перевірку. Генератор перевіряє кольори, розміри шарів і посилання з прикладів купок.

## Додати нову модель
1. Намалюй шари в `prototype/models/build_models.py` (функція `M(...)`).
2. `python3 prototype/models/build_models.py` оновить `mobile/assets/catalog.json` і прототип.
3. `flutter test` перевірить, що все на місці.
