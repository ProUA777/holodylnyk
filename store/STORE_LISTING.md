# Публікація в Google Play: усе, що треба вставити

Тексти нижче готові до копіювання у **Google Play Console → Grow → Store presence → Main store listing**. Українська — мова за замовчуванням, польську додай через **Manage translations → Add your own translation → Polish**.

## Назва та описи

| Поле (ліміт) | Українська | Polski |
|---|---|---|
| Назва (30) | Що приготувати: рецепти з фото | Co ugotować: przepisy ze zdjęć |
| Короткий опис (80) | Сфотографуй холодильник — отримай 6 рецептів із того, що вже є вдома | Zrób zdjęcie lodówki i dostań 6 przepisów z tego, co masz w domu |

### Повний опис — українська

```
Не знаєш, що приготувати? Сфотографуй холодильник — і за пів хвилини отримаєш 6 різних страв саме з тих продуктів, що в тебе є.

📸 ДО 3 ФОТО ЗА РАЗ
Холодильник, морозилка, полиця з крупами — AI побачить усі продукти й об'єднає їх в один список. Щось не розпізнало? Прибери зайве або допиши вручну.

🍳 ШІСТЬ РІЗНИХ СТРАВ
Сніданок, суп, основна страва, салат, випічка чи десерт — різні кухні світу й різні способи приготування. Першими йдуть рецепти, для яких нічого не треба докупити. Хочеш ще — один дотик, і будуть інші кухні.

📖 ДЕТАЛЬНІ РЕЦЕПТИ
Точні грами, вогонь, час і як зрозуміти, що страва готова. Змінюй кількість порцій — усі кількості перерахуються самі.

🎙 ГОТУВАННЯ БЕЗ РУК
Режим «Готую»: один крок на весь екран, великий шрифт, таймери з сигналом. Увімкни голос — застосунок читає кроки вголос і слухає команди «далі», «назад», «повтори», «таймер». Екран не гасне.

🛒 СПИСОК ПОКУПОК
Усе, чого бракує, — в одному списку з усіх рецептів. Однакові продукти зливаються в один пункт. Поділися списком у Viber чи Telegram.

❤️ ЗБЕРЕЖЕНІ РЕЦЕПТИ
Зберігаються разом із детальними кроками й відкриваються без інтернету.

⚙️ ПІД ТЕБЕ
Вегетаріанське, веганське, без свинини, без глютену чи лактози. Обмеження за часом: 15, 30, 60 хвилин.

🇺🇦 🇵🇱 Українською та польською.

Без реєстрації. Без реклами.
```

### Pełny opis — polski

```
Nie wiesz, co ugotować? Zrób zdjęcie lodówki — w pół minuty dostaniesz 6 różnych dań właśnie z produktów, które masz.

📸 DO 3 ZDJĘĆ NARAZ
Lodówka, zamrażarka, półka z kaszami — AI zobaczy wszystkie produkty i połączy je w jedną listę. Coś się nie rozpoznało? Usuń zbędne albo dopisz ręcznie.

🍳 SZEŚĆ RÓŻNYCH DAŃ
Śniadanie, zupa, danie główne, sałatka, wypieki lub deser — różne kuchnie świata i różne sposoby przyrządzania. Najpierw przepisy, do których niczego nie trzeba dokupić. Chcesz więcej — jedno dotknięcie i pojawią się inne kuchnie.

📖 SZCZEGÓŁOWE PRZEPISY
Dokładne gramy, ogień, czas i jak poznać, że danie jest gotowe. Zmień liczbę porcji — wszystkie ilości przeliczą się same.

🎙 GOTOWANIE BEZ RĄK
Tryb „Gotuję”: jeden krok na cały ekran, duża czcionka, minutniki z sygnałem. Włącz głos — aplikacja czyta kroki na głos i słucha poleceń „dalej”, „wstecz”, „powtórz”, „minutnik”. Ekran nie gaśnie.

🛒 LISTA ZAKUPÓW
Wszystko, czego brakuje, w jednej liście ze wszystkich przepisów. Te same produkty łączą się w jedną pozycję. Udostępnij listę w Messengerze czy WhatsAppie.

❤️ ZAPISANE PRZEPISY
Zapisują się razem ze szczegółowymi krokami i działają bez internetu.

⚙️ DLA CIEBIE
Wegetariańska, wegańska, bez wieprzowiny, bez glutenu lub laktozy. Limit czasu: 15, 30, 60 minut.

🇵🇱 🇺🇦 Po polsku i po ukraińsku.

Bez rejestracji. Bez reklam.
```

## Графіка

| Що | Розмір | Де взяти |
|---|---|---|
| Іконка застосунку | 512 × 512 PNG | `recipes_app/assets/icon/icon.png`, зменшена до 512 (будь-який редактор) |
| Feature graphic | 1024 × 500 | зроби в Canva: лаймовий фон `#C8F135`, іконка + назва |
| Скріншоти телефона | мін. 2, краще 6–8 | зніми з телефона: головний екран → фото → список страв → рецепт → «Готую» → покупки |

## Політика конфіденційності

У полі **Privacy policy** вкажи посилання: `https://api.твійдомен.com/privacy` (польська версія — `?lang=pl`).
Сервер віддає її сам. Перед публікацією вкажи свій email у `.env`: `PHOTOAI_CONTACT_EMAIL=...`.

## App content → Data safety (анкета безпеки даних)

| Питання | Відповідь |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS) |
| Do you provide a way for users to request that their data is deleted? | **No** — дані не зберігаються (фото не зберігаються, лічильники видаляються за 3 дні). Поясни це в полі опису |

Типи даних:

| Тип | Collected | Shared | Обов'язково | Мета |
|---|---|---|---|---|
| **Photos and videos → Photos** | Yes, processed ephemerally (тимчасово) | No* | Yes | App functionality |
| **Device or other IDs** | Yes | No | Yes | App functionality, Fraud prevention, security |
| **Audio → Voice or sound recordings** | No — розпізнає сервіс мовлення телефона, на сервер не надсилається | — | — | — |

\* Передача постачальнику послуг (Anthropic), який обробляє дані від твого імені, за правилами Google Play не вважається «sharing».

## App content: інші пункти

- **Ads:** No.
- **App access:** All functionality is available without special access.
- **Target audience:** 18+. Можна 13+, але тоді будуть додаткові вимоги для дітей.
- **Content rating:** заповни анкету IARC. Насильства, азартних ігор чи контенту для дорослих немає, тож рейтинг буде «3+ / Everyone».
- **Category:** Food & Drink.

## Перед завантаженням `.aab`

1. Створи ключ підпису й налаштуй його за https://docs.flutter.dev/deployment/android#sign-the-app. Файл ключа (`.jks`) збережи в надійному місці: без нього не вийде оновлювати апку.
2. Зміни версію в `recipes_app/pubspec.yaml` (`version: 1.3.0+4`). Число після `+` має рости з кожним завантаженням.
3. Збери: `flutter build appbundle --dart-define=API_URL=https://api.твійдомен.com --dart-define=API_KEY=...`
4. Почни з **Testing → Internal testing**: це до 100 тестувальників за посиланням і без перевірки Google. Потім переходь до **Production**.
