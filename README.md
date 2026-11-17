# «Що приготувати» на двигуні PhotoAI: покрокова інструкція

**Одна кодова база — дві платформи: Android і iPhone (iOS).** Апка написана на Flutter: той самий код збирається в APK/AAB для Google Play і в iOS-версію для App Store.

```
photoai/
├── backend/        сервер (Python, FastAPI) — один на всі майбутні фото-апки
└── recipes_app/    апка для телефона (Flutter)
```

**Що вміє апка:**
- **Фото:** до 3 фото за раз, наприклад холодильник, морозилка й полиця. AI об'єднує продукти з усіх фото.
- **Рецепти:** 6 різних страв (різні типи, кухні, способи готування), фільтр за типом і кнопка «ще рецепти».
- **Детальний рецепт:** грами, вогонь, час і ознаки готовності. Кнопки −/+ змінюють кількість порцій, і всі кількості перераховуються.
- **Режим «Готую»:** один крок на екран, таймери, екран не гасне. Кнопка **«Готувати голосом»** вмикає читання кроків уголос і команди «далі», «назад», «повтори», «таймер» (польською: «dalej», «wstecz», «powtórz», «minutnik»).
- **Поділитися:** рецепт або список покупок одним дотиком у Viber, Telegram чи WhatsApp.
- **Покупки:** спільний список того, що треба докупити, з усіх рецептів. Однакові продукти зливаються в один пункт.
- **Збережені:** рецепти зберігаються разом з детальним текстом і відкриваються без інтернету.
- **Дві мови:** українська і польська (інтерфейс і рецепти). За замовчуванням мова телефона, змінюється в «Налаштуваннях».

**Як це працює.** Телефон надсилає фото на твій сервер. Сервер з твоїм ключем звертається до Claude і повертає продукти й рецепти. Ключ лежить тільки на сервері, в апці його немає. Користувачам не потрібен ні акаунт, ні підписка.

| Крок | Модель | Навіщо |
|---|---|---|
| Фото → продукти + 6 страв | `claude-haiku-5-5` | швидко й дешево |
| «Ще рецепти», перерахунок | `claude-haiku-5-5` | швидко й дешево |
| Детальний рецепт (грами, вогонь, час) | `claude-sonnet-5-5` | якість тексту; та сама страва вдруге береться з кешу безкоштовно |

---

## Крок 1. Ключ Anthropic (10 хвилин)

1. Зайди на https://console.anthropic.com і зареєструйся. Це окремо від підписки Claude.
2. **Billing** → додай картку й поповни баланс. Списується тільки за реальні запити.
3. **Limits** → постав місячний ліміт витрат, щоб рахунок ніколи не вийшов за суму, яку ти задав.
4. **API Keys** → **Create Key** → назви `photoai` → скопіюй ключ `sk-ant-...`. Він показується тільки один раз.

## Крок 2. Запуск сервера на своєму ПК (Windows)

Потрібен Python 3.12: https://www.python.org/downloads/ (під час встановлення постав галочку **Add Python to PATH**).

Відкрий **PowerShell** у папці `photoai\backend` і виконай:

```powershell
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1
# якщо помилка «running scripts is disabled»:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned   (і повтори рядок вище)
pip install -r requirements-dev.txt
pytest
copy .env.example .env
py -c "import secrets;print(secrets.token_urlsafe(32))"
notepad .env
```

`pytest` має показати `22 passed`. Останній `py -c ...` друкує випадковий ключ апки: скопіюй його.

У `.env` зміни три рядки:

```
PHOTOAI_AI_PROVIDER=anthropic
PHOTOAI_ANTHROPIC_API_KEY=sk-ant-...твій ключ з кроку 1...
PHOTOAI_API_KEYS=...ключ апки, який щойно згенерував...
```

Запусти сервер:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Перевірка:**
- http://localhost:8000/health має повернути `{"status":"ok"}`.
- http://localhost:8000/docs → `POST /v1/{profile_id}/analyze` → **Try it out**. Заповни поля:
  - `profile_id`: `recipes`;
  - `x-api-key`: ключ апки;
  - `image`: фото холодильника.

  Натисни **Execute**. Має прийти JSON із продуктами й 6 рецептами.

Щоб телефон у тій самій Wi-Fi бачив сервер, відкрий порт (PowerShell **від адміністратора**):

```powershell
New-NetFirewallRule -DisplayName "PhotoAI 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow
ipconfig
```

У виводі `ipconfig` знайди **IPv4 Address** (наприклад `192.168.0.105`). Це адреса твого ПК.

## Крок 3A. Апка на Android-телефоні

1. Встанови Flutter **3.27 або новіший**: https://docs.flutter.dev/get-started/install/windows/mobile (разом з Android Studio). Потім виконай `flutter doctor`: усі пункти для Android мають бути з галочкою.
2. На телефоні: **Налаштування → Про телефон** → 7 разів натисни «Номер збірки» → **Для розробників** → увімкни **Налагодження USB**. Підключи телефон кабелем.
3. У PowerShell у папці `photoai\recipes_app` виконай:

```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
flutter analyze
flutter test
flutter run --dart-define=API_URL=http://192.168.0.105:8000 --dart-define=API_KEY=ключ_апки
```

`setup.ps1` запускається один раз: він створює папки android/ios, дозволи й назву. Замість `192.168.0.105` впиши свій IPv4, замість `ключ_апки` — той самий ключ, що в `PHOTOAI_API_KEYS`.

Якщо `flutter analyze` знайде помилку, надішли мені її текст, і я поправлю.

## Крок 3B. Апка на iPhone

Для iPhone Apple дозволяє збирати апки тільки на Mac із Xcode. Є два шляхи.

**Якщо є Mac:**
1. Встанови Xcode з App Store і Flutter: https://docs.flutter.dev/get-started/install/macos/mobile-ios.
2. Виконай у терміналі в папці `photoai/recipes_app`:
   ```bash
   bash setup.sh
   open ios/Runner.xcworkspace
   ```
3. У Xcode: **Runner → Signing & Capabilities → Team** → вибери свій Apple ID. Він безкоштовний для тесту на власному iPhone.
4. Підключи iPhone кабелем і виконай:
   ```bash
   flutter run --dart-define=API_URL=http://IP_ТВОГО_ПК:8000 --dart-define=API_KEY=ключ_апки
   ```
   Першого разу на iPhone треба підтвердити розробника: **Налаштування → Основні → VPN і керування пристроєм**.

**Якщо Mac немає:** збирай у хмарі через Codemagic (https://codemagic.io). У нього є безкоштовні хвилини збірки на Mac.
1. Зареєструйся в **Apple Developer Program** (https://developer.apple.com/programs/). Він платний, оплата щороку, і без нього на чужі iPhone апку не встановити.
2. В **App Store Connect** → Users and Access → **Integrations → App Store Connect API** створи ключ з роллю **App Manager**.
3. Завантаж проєкт на GitHub (див. розділ «Збірка без ПК») і підключи репозиторій у Codemagic.
4. У Codemagic → **Flutter workflow** зроби таке:
   - **Project path:** `recipes_app`;
   - **Pre-build script:** `bash setup.sh`;
   - **Build for platforms:** iOS (можна разом з Android);
   - **Build arguments:** `--dart-define=API_URL=https://api.твійдомен.com --dart-define=API_KEY=ключ_апки`.
5. У **iOS code signing** вибери **Automatic** і вкажи ключ App Store Connect з пункту 2.
6. У **Distribution → App Store Connect** увімкни **Submit to TestFlight**.
7. Натисни **Start new build**. Через 15–25 хвилин збірка з'явиться в **TestFlight** на твоєму iPhone.

Важливо: на iPhone через інтернет апка працює тільки з `https://` сервером (крок 4). Звичайний `http://` дозволений лише для сервера на твоєму ПК у тій самій Wi-Fi.

## Крок 4 (найпростіше). Сервер на Render.com, без власного сервера й домену

1. Відкрий **https://render.com** → **Get Started** → увійди через **GitHub**.
2. **New → Blueprint** → вибери репозиторій **holodylnyk**. Render прочитає файл `render.yaml`.
3. Render попросить вписати:
   - `PHOTOAI_ANTHROPIC_API_KEY` — ключ з кроку 1;
   - `PHOTOAI_CONTACT_EMAIL` — твій email для політики конфіденційності.
4. Натисни **Apply**. Збірка йде 5–10 хвилин. Потім з'явиться адреса на кшталт `https://holodylnyk-api.onrender.com`. Перевір `.../health`: має повернути `{"status":"ok"}`.
5. На Render відкрий сервіс → **Environment** → скопіюй значення `PHOTOAI_API_KEYS`. Render згенерував його сам.
6. На GitHub відкрий **Settings → Secrets and variables → Actions** і додай два секрети:
   - `API_URL` — адреса з пункту 4;
   - `API_KEY` — значення з пункту 5.
7. **Actions → build → Run workflow**. Новий APK з розділу **Artifacts** уже працює з твоїм сервером.

На безкоштовному плані сервер засинає після 15 хвилин без запитів, і перший запит після цього чекає близько хвилини. Денні ліміти й кеш рецептів обнуляються при перезапуску. Щоб сервер не засинав, у Render → Settings → Instance Type вибери **Starter**.

## Крок 4 (свій сервер). VPS з доменом (щоб апка працювала не тільки вдома)

Потрібні VPS з Ubuntu 24.04 (вистачить 1–2 ГБ RAM) і домен.

1. У DNS домену створи **A-запис** `api.твійдомен.com` з IP сервера.
2. Підключись до сервера через `ssh root@IP` і виконай:

```bash
curl -fsSL https://get.docker.com | sh
mkdir -p /opt/photoai && cd /opt/photoai
# скопіюй сюди вміст папки backend (наприклад, з ПК: scp -r backend/* root@IP:/opt/photoai/)
cp .env.example .env && nano .env        # ті самі три рядки, що в кроці 2
nano Caddyfile                           # api.example.com → api.твійдомен.com
docker compose up -d --build
```

3. Перевір https://api.твійдомен.com/health. HTTPS-сертифікат Caddy отримує сам.
4. Логи: `docker compose logs -f api`. Оновлення: скопіюй нові файли і знову виконай `docker compose up -d --build`.

## Крок 5. Публікація

**Google Play (Android):** усі тексти магазину українською й польською, анкета безпеки даних і список графіки лежать у файлі **`store/STORE_LISTING.md`**. Іконку й заставку `setup.ps1`/`setup.sh` створюють самі з `recipes_app/assets/icon`. Посилання на політику конфіденційності: `https://api.твійдомен.com/privacy`. Сервер віддає цю сторінку сам, тобі треба лише вказати свій email у `.env` (`PHOTOAI_CONTACT_EMAIL`).


```powershell
flutter build appbundle --dart-define=API_URL=https://api.твійдомен.com --dart-define=API_KEY=ключ_апки
```

Готовий файл: `build\app\outputs\bundle\release\app-release.aab`.
Перед першою публікацією налаштуй підпис за офіційною інструкцією: https://docs.flutter.dev/deployment/android. Потім у Google Play Console створи апку й завантаж `.aab`.

**App Store (iPhone):** коли збірка з'явиться в TestFlight (крок 3B), в App Store Connect заповни опис і скріншоти, вибери цю збірку і надішли на перевірку. Інструкція: https://docs.flutter.dev/deployment/ios.

## Збірка без ПК: GitHub Actions

У проєкті вже лежить файл `.github/workflows/build.yml`. Після кожного завантаження коду на GitHub він сам:
- тестує бекенд;
- збирає **APK для Android**, який можна завантажити й встановити на телефон;
- перевіряє, що **iOS-версія** компілюється (на Mac від GitHub).

Як увімкнути:
1. Створи приватний репозиторій на https://github.com/new і завантаж туди вміст папки `photoai` (кнопка **uploading an existing file** або GitHub Desktop).
2. **Settings → Secrets and variables → Actions → New repository secret** і додай два секрети:
   - `API_URL` — адреса сервера, наприклад `https://api.твійдомен.com`;
   - `API_KEY` — ключ апки, той самий, що в `PHOTOAI_API_KEYS`.
3. Відкрий вкладку **Actions**: збірка запуститься сама. Коли всі три пункти стануть зеленими, відкрий збірку → **Artifacts** → `shcho-pryhotuvaty-android` → завантаж і встанови APK на телефон. Android попросить дозволити встановлення з цього джерела.
4. Якщо якийсь пункт червоний, відкрий його, скопіюй текст помилки й надішли мені.

---

## Що де змінювати

| Що | Де |
|---|---|
| Ліміти на телефон за добу (фото / перерахунки / детальні рецепти) | `.env`: `PHOTOAI_DAILY_PHOTO_LIMIT=10`, `..._REFINE_LIMIT=40`, `..._DETAIL_LIMIT=30` |
| Яка модель на якому кроці | `.env`: `PHOTOAI_MODEL_ANALYZE`, `..._REFINE`, `..._DETAIL` |
| Промпти, правила різноманітності, формат детального рецепта | `backend/app/profiles/recipes.py` |
| Кольори й шрифти апки | `recipes_app/lib/theme.dart` |
| Тексти екранів (обидві мови) | `recipes_app/lib/l10n.dart`. Нова мова — ще один клас `Strings` |
| Скільки фото за раз | `.env`: `PHOTOAI_MAX_PHOTOS=3` і `PhotosScreen.maxPhotos` в апці |

**Як працюють ліміти.** Апка створює випадковий id телефона, і сервер рахує за ним запити за добу (UTC). З однієї IP-адреси дозволено в 5 разів більше, бо в одній Wi-Fi буває кілька телефонів. Якщо AI не відповів, запит у ліміт не зараховується. Детальний рецепт, узятий з кешу, теж не зараховується.

**Як стежити за витратами.** На console.anthropic.com → **Usage** видно витрати по днях і моделях. Там же, у **Limits**, стоїть верхня межа на місяць.

## Як додати наступну апку на цей двигун

1. Скопіюй `backend/app/profiles/recipes.py` → `parts.py` (або іншу нішу). Зміни в ньому моделі даних і промпти.
2. Додай рядок `engine.register(PartsProfile())` у `build_engine()` у файлі `backend/app/main.py`.
3. Скопіюй `recipes_app`. У `lib/config.dart` зміни `profileId`, далі онови моделі та екрани.

© by Greater Koreec Project Group
