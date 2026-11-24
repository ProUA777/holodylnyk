"""Політика конфіденційності для Google Play / App Store: GET /privacy?lang=uk|pl.

Текст описує те, що реально робить цей сервер і апка. Якщо міняєш обробку даних — онови текст.
Контактний email задається в .env: PHOTOAI_CONTACT_EMAIL.
"""
from html import escape

UPDATED = "25.11.2026"

# Що саме обробляє кожна апка родини — підставляється в загальний текст політики
APPS = {
    "uk": {
        "recipes": {"name": "Що приготувати", "purpose": "допомагає підібрати рецепти за фото продуктів",
                    "photo": "розпізнавання продуктів", "params": "Список продуктів і параметри (дієта, час, порції, мова)",
                    "params_why": "підібрати рецепти", "local": "Збережені рецепти й список покупок",
                    "voice": "«Готувати голосом»"},
        "plants": {"name": "Що з рослиною?", "purpose": "визначає рослину за фото, її стан і як доглядати",
                   "photo": "визначення рослини та її стану", "params": "Назва рослини, ознаки й умови (де стоїть, чи є тварини)",
                   "params_why": "дати поради з догляду й лікування", "local": "Мої рослини, журнал поливу й перевірки лікування",
                   "voice": None},
        "outfits": {"name": "Що вдягнути?", "purpose": "підбирає образи з речей на фото",
                    "photo": "розпізнавання одягу (застосунок не оцінює зовнішність і не визначає людей)",
                    "params": "Список речей і параметри (подія, погода, стиль)", "params_why": "скласти образи",
                    "local": "Гардероб, збережені образи й лічильник «одягаю сьогодні»", "voice": None},
        "repair": {"name": "Що зламалось?", "purpose": "за фото поломки підказує причину, безпеку й кроки ремонту",
                   "photo": "розпізнавання речі та поломки", "params": "Опис речі, ознаки й досвід",
                   "params_why": "скласти план ремонту", "local": "Мої ремонти, відмітки покупок і нагадування про обслуговування",
                   "voice": "«Ремонтую» (керування голосом)"},
        "homework": {"name": "Як розв’язати?", "purpose": "пояснює, як розв’язати завдання з фото, і перевіряє розв’язок",
                     "photo": "розпізнавання тексту завдання. Не фотографуй обкладинку зошита з ім’ям чи інші особисті дані",
                     "params": "Текст завдання, клас і режим", "params_why": "пояснити розв’язання",
                     "local": "Історія завдань", "voice": None},
    },
    "pl": {
        "recipes": {"name": "Co ugotować", "purpose": "pomaga dobrać przepisy na podstawie zdjęcia produktów",
                    "photo": "rozpoznania produktów", "params": "Lista produktów i ustawienia (dieta, czas, porcje, język)",
                    "params_why": "dobrać przepisy", "local": "Zapisane przepisy i lista zakupów", "voice": "„Gotuj głosem”"},
        "plants": {"name": "Co z roślinką?", "purpose": "rozpoznaje roślinę na zdjęciu, jej stan i sposób pielęgnacji",
                   "photo": "rozpoznania rośliny i jej stanu", "params": "Nazwa rośliny, objawy i warunki (miejsce, zwierzęta)",
                   "params_why": "doradzić pielęgnację i leczenie", "local": "Moje rośliny, dziennik podlewania i kontrole leczenia",
                   "voice": None},
        "outfits": {"name": "Co założyć?", "purpose": "dobiera stylizacje z rzeczy na zdjęciu",
                    "photo": "rozpoznania ubrań (aplikacja nie ocenia wyglądu i nie identyfikuje osób)",
                    "params": "Lista rzeczy i ustawienia (okazja, pogoda, styl)", "params_why": "ułożyć stylizacje",
                    "local": "Szafa, zapisane stylizacje i licznik noszenia", "voice": None},
        "repair": {"name": "Co się zepsuło?", "purpose": "na podstawie zdjęcia usterki podpowiada przyczynę, bezpieczeństwo i kroki naprawy",
                   "photo": "rozpoznania rzeczy i usterki", "params": "Opis rzeczy, objawy i doświadczenie",
                   "params_why": "ułożyć plan naprawy", "local": "Moje naprawy, zakupy i przypomnienia o serwisie",
                   "voice": "„Naprawiam” (sterowanie głosem)"},
        "homework": {"name": "Jak rozwiązać?", "purpose": "wyjaśnia, jak rozwiązać zadanie ze zdjęcia, i sprawdza rozwiązanie",
                     "photo": "rozpoznania treści zadania. Nie fotografuj okładki zeszytu z imieniem ani innych danych osobowych",
                     "params": "Treść zadania, klasa i tryb", "params_why": "wyjaśnić rozwiązanie",
                     "local": "Historia zadań", "voice": None},
    },
}

TEXT = {
    "uk": {
        "title": "Політика конфіденційності — «{app}»",
        "who": ("Хто ми", "Застосунок «{app}» (Android та iOS) розробляє {owner}. Застосунок {purpose}."),
        "data": "Які дані обробляються і навіщо",
        "not": ("Що ми НЕ робимо", "Немає реєстрації й акаунтів. Немає реклами, аналітики й відстеження. "
                                   "Ми не продаємо і не передаємо дані для маркетингу. Фото не зберігаються."),
        "kids": ("Діти", "Застосунок не призначений для дітей до 13 років і свідомо не збирає їхніх даних."),
        "kids_homework": ("Діти", "Застосунок призначений для батьків і учнів від 13 років. Він не просить імені, "
                                  "школи чи інших особистих даних і свідомо не збирає даних дітей до 13 років."),
        "rights": ("Ваші права", "Фото й тексти запитів не зберігаються на сервері. Лічильники лімітів видаляються "
                                 "автоматично через 3 дні, скарги на відповіді — через 90 днів. Збережене на телефоні "
                                 "видаляється в самому застосунку або разом із ним. З питань пишіть: {email}."),
        "changes": ("Зміни", "Якщо ця політика зміниться, оновлена версія з'явиться за цим самим посиланням."),
        "photo": ("Фото, які ви робите або вибираєте", "надсилаються на наш сервер лише для: {photo}. "
                  "Перед цим із фото видаляються метадані (зокрема геолокація). Сервер передає фото AI-сервісу "
                  "{vendor} для аналізу й не зберігає їх після відповіді."),
        "params": "надсилаються на сервер і AI-сервісу, щоб {params_why}. Тексти детальних інструкцій кешуються на сервері без прив'язки до людини.",
        "device": ("Випадковий ідентифікатор пристрою", "створюється застосунком (не рекламний ID і не номер телефону) і "
                   "разом з IP-адресою використовується лише для денних лімітів і захисту від зловживань. "
                   "Лічильники зберігаються не довше 3 днів."),
        "voice": "голосові команди розпізнає сервіс мовлення вашого телефона (Google або Apple). На наш сервер голос не надсилається.",
        "voice_title": "Мікрофон (лише в режимі {voice})",
        "local": "зберігаються тільки на вашому телефоні.",
        "report": ("Скарга на відповідь AI", "якщо ви натиснете «Поскаржитися», на сервер надсилається текст цієї відповіді, "
                   "причина і ваш коментар (без фото). Ми використовуємо це лише щоб виправляти помилки й зберігаємо до 90 днів."),
        "shops": ("Посилання на магазини", "кнопка «Де купити» відкриває сторінку пошуку магазину у вашому браузері й передає "
                  "лише назву товару. Ми не отримуємо комісій і не бачимо, що ви купуєте."),
        "transfer": ("Передача даних", "лише через зашифроване з'єднання (HTTPS). AI-сервіс обробляє дані як постачальник "
                     "послуг відповідно до своїх умов: {links}.{free_note}"),
        "updated": "Оновлено",
        "contact": "Контакт",
    },
    "pl": {
        "title": "Polityka prywatności — „{app}”",
        "who": ("Kim jesteśmy", "Aplikację „{app}” (Android i iOS) rozwija {owner}. Aplikacja {purpose}."),
        "data": "Jakie dane są przetwarzane i po co",
        "not": ("Czego NIE robimy", "Brak rejestracji i kont. Brak reklam, analityki i śledzenia. "
                                    "Nie sprzedajemy ani nie przekazujemy danych w celach marketingowych. Zdjęcia nie są przechowywane."),
        "kids": ("Dzieci", "Aplikacja nie jest przeznaczona dla dzieci poniżej 13 lat i świadomie nie zbiera ich danych."),
        "kids_homework": ("Dzieci", "Aplikacja jest przeznaczona dla rodziców i uczniów od 13 lat. Nie prosi o imię, szkołę "
                                    "ani inne dane osobowe i świadomie nie zbiera danych dzieci poniżej 13 lat."),
        "rights": ("Twoje prawa", "Zdjęcia i treści zapytań nie są przechowywane na serwerze. Liczniki limitów są usuwane "
                                  "automatycznie po 3 dniach, zgłoszenia odpowiedzi — po 90 dniach. Dane zapisane w telefonie "
                                  "usuwasz w aplikacji lub razem z nią. Kontakt: {email}."),
        "changes": ("Zmiany", "Jeśli polityka się zmieni, nowa wersja pojawi się pod tym samym adresem."),
        "photo": ("Zdjęcia, które robisz lub wybierasz", "są wysyłane na nasz serwer wyłącznie w celu: {photo}. "
                  "Wcześniej usuwane są z nich metadane (w tym lokalizacja). Serwer przekazuje zdjęcia usłudze AI "
                  "{vendor} do analizy i nie przechowuje ich po odpowiedzi."),
        "params": "są wysyłane na serwer i do usługi AI, aby {params_why}. Teksty szczegółowych instrukcji są buforowane na serwerze bez powiązania z osobą.",
        "device": ("Losowy identyfikator urządzenia", "tworzony przez aplikację (nie jest to identyfikator reklamowy ani numer "
                   "telefonu); razem z adresem IP służy wyłącznie do dziennych limitów i ochrony przed nadużyciami. "
                   "Liczniki są przechowywane nie dłużej niż 3 dni."),
        "voice": "polecenia głosowe rozpoznaje usługa mowy Twojego telefonu (Google lub Apple). Głos nie jest wysyłany na nasz serwer.",
        "voice_title": "Mikrofon (tylko w trybie {voice})",
        "local": "są przechowywane wyłącznie w Twoim telefonie.",
        "report": ("Zgłoszenie odpowiedzi AI", "jeśli naciśniesz „Zgłoś”, na serwer trafia tekst tej odpowiedzi, powód i Twój "
                   "komentarz (bez zdjęć). Używamy tego tylko do poprawiania błędów i przechowujemy do 90 dni."),
        "shops": ("Linki do sklepów", "przycisk „Gdzie kupić” otwiera stronę wyszukiwania sklepu w przeglądarce i przekazuje "
                  "tylko nazwę produktu. Nie pobieramy prowizji i nie widzimy, co kupujesz."),
        "transfer": ("Przesyłanie danych", "wyłącznie szyfrowanym połączeniem (HTTPS). Usługa AI przetwarza dane jako dostawca "
                     "usług zgodnie ze swoimi warunkami: {links}.{free_note}"),
        "updated": "Aktualizacja",
        "contact": "Kontakt",
    },
}

SHOP_APPS = {"plants", "outfits", "repair"}


VENDORS = {
    "uk": {"gemini": "Google (Gemini)", "anthropic": "Anthropic (Claude)",
           "both": "Google (Gemini), а якщо він недоступний — Anthropic (Claude)",
           "free": " На безкоштовному рівні Gemini API Google може використовувати надіслані запити для покращення "
                   "своїх продуктів — тому не фотографуй документи та інші особисті речі."},
    "pl": {"gemini": "Google (Gemini)", "anthropic": "Anthropic (Claude)",
           "both": "Google (Gemini), a gdy jest niedostępna — Anthropic (Claude)",
           "free": " W bezpłatnym planie Gemini API Google może wykorzystywać przesłane zapytania do ulepszania "
                   "swoich produktów — dlatego nie fotografuj dokumentów ani innych rzeczy osobistych."},
}
LINKS = {"gemini": "https://ai.google.dev/gemini-api/terms, https://policies.google.com/privacy",
         "anthropic": "https://www.anthropic.com/legal/privacy"}


def privacy_html(lang: str, owner: str, email: str, ai: str = "anthropic", app: str = "recipes") -> str:
    t = TEXT.get(lang, TEXT["uk"])
    a = APPS.get(lang, APPS["uk"]).get(app) or APPS.get(lang, APPS["uk"])["recipes"]
    if app not in APPS["uk"]:
        app = "recipes"
    v = VENDORS.get(lang, VENDORS["uk"])
    uses_gemini, uses_claude = "gemini" in ai, ("anthropic" in ai or ai == "mock")
    vendor = v["both"] if uses_gemini and "anthropic" in ai else v["gemini"] if uses_gemini else v["anthropic"]
    links = ", ".join(LINKS[k] for k, on in (("gemini", uses_gemini), ("anthropic", uses_claude)) if on)
    fmt = {"vendor": vendor, "links": links, "free_note": v["free"] if uses_gemini else "", "photo": a["photo"],
           "params_why": a["params_why"], "app": a["name"], "purpose": a["purpose"]}

    items = [t["photo"], (a["params"], t["params"]), t["device"]]
    if a["voice"]:
        items.append((t["voice_title"].format(voice=a["voice"]), t["voice"]))
    items.append((a["local"], t["local"]))
    items.append(t["report"])
    if app in SHOP_APPS:
        items.append(t["shops"])
    items.append(t["transfer"])

    mail = f'<a href="mailto:{escape(email)}">{escape(email)}</a>'

    def para(text: str) -> str:
        return escape(text.format(**fmt, owner="\x00", email="\x01")).replace("\x00", escape(owner)).replace("\x01", mail)

    title = t["title"].format(app=a["name"])
    kids = t["kids_homework"] if app == "homework" else t["kids"]
    body = []
    for head, text in (t["who"],):
        body.append(f"<h2>{escape(head)}</h2><p>{para(text)}</p>")
    body.append(f"<h2>{escape(t['data'])}</h2><ul>" + "".join(
        f"<li><b>{escape(k)}</b> — {escape(val.format(**fmt))}</li>" for k, val in items) + "</ul>")
    for head, text in (t["not"], kids, t["rights"], t["changes"]):
        body.append(f"<h2>{escape(head)}</h2><p>{para(text)}</p>")
    other = "pl" if lang == "uk" else "uk"
    return f"""<!DOCTYPE html><html lang="{lang}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>{escape(title)}</title>
<style>body{{font:16px/1.6 system-ui,sans-serif;max-width:720px;margin:0 auto;padding:24px 20px;color:#1C1238}}
h1{{font-size:26px;line-height:1.2}}h2{{font-size:18px;margin-top:28px}}li{{margin:8px 0}}a{{color:#5B3DF5}}
.lang{{float:right;font-weight:700}}</style></head><body>
<a class="lang" href="?app={app}&amp;lang={other}">{other.upper()}</a>
<h1>{escape(title)}</h1><p>{t['updated']}: {UPDATED}</p>
{''.join(body)}
<p>{t['contact']}: {mail}</p></body></html>"""
