"""Політика конфіденційності для Google Play / App Store: GET /privacy?lang=uk|pl.

Текст описує те, що реально робить цей сервер і апка. Якщо міняєш обробку даних — онови текст.
Контактний email задається в .env: PHOTOAI_CONTACT_EMAIL.
"""
from html import escape

UPDATED = "16.11.2026"

TEXT = {
    "uk": {
        "title": "Політика конфіденційності — «Що приготувати»",
        "sections": [
            ("Хто ми", "Застосунок «Що приготувати» (Android та iOS) розробляє {owner}. "
                       "Застосунок допомагає підібрати рецепти за фото продуктів."),
            ("Які дані обробляються і навіщо", None),
            ("Що ми НЕ робимо", "Немає реєстрації й акаунтів. Немає реклами, аналітики й відстеження. "
                                "Ми не продаємо і не передаємо дані для маркетингу. Фото не зберігаються."),
            ("Діти", "Застосунок не призначений для дітей до 13 років і свідомо не збирає їхніх даних."),
            ("Ваші права", "Фото й списки продуктів не зберігаються на сервері, тому видаляти нічого не потрібно. "
                           "Лічильники лімітів видаляються автоматично через 3 дні. Збережене на телефоні видаляється "
                           "в самому застосунку або разом із ним. З питань пишіть: {email}."),
            ("Зміни", "Якщо ця політика зміниться, оновлена версія з'явиться за цим самим посиланням."),
        ],
        "items": [
            ("Фото, які ви робите або вибираєте", "надсилаються на наш сервер лише для розпізнавання продуктів. "
             "Перед цим із фото видаляються метадані (зокрема геолокація). Сервер передає фото AI-сервісу "
             "Anthropic (Claude) для аналізу й не зберігає їх після відповіді."),
            ("Список продуктів і параметри (дієта, час, порції, мова)", "надсилаються на сервер і в Anthropic, щоб "
             "підібрати рецепти. Тексти детальних рецептів кешуються на сервері без прив'язки до людини."),
            ("Випадковий ідентифікатор пристрою", "створюється застосунком (не рекламний ID і не номер телефону) і "
             "разом з IP-адресою використовується лише для денних лімітів і захисту від зловживань. "
             "Лічильники зберігаються не довше 3 днів."),
            ("Мікрофон (лише в режимі «Готувати голосом»)", "голосові команди розпізнає сервіс мовлення вашого "
             "телефона (Google або Apple). На наш сервер голос не надсилається."),
            ("Збережені рецепти й список покупок", "зберігаються тільки на вашому телефоні."),
            ("Передача даних", "лише через зашифроване з'єднання (HTTPS). Anthropic обробляє дані як постачальник "
             "послуг відповідно до своїх умов: https://www.anthropic.com/legal/privacy"),
        ],
        "updated": "Оновлено",
        "contact": "Контакт",
    },
    "pl": {
        "title": "Polityka prywatności — „Co ugotować”",
        "sections": [
            ("Kim jesteśmy", "Aplikację „Co ugotować” (Android i iOS) rozwija {owner}. "
                             "Aplikacja pomaga dobrać przepisy na podstawie zdjęcia produktów."),
            ("Jakie dane są przetwarzane i po co", None),
            ("Czego NIE robimy", "Brak rejestracji i kont. Brak reklam, analityki i śledzenia. "
                                 "Nie sprzedajemy ani nie przekazujemy danych w celach marketingowych. Zdjęcia nie są przechowywane."),
            ("Dzieci", "Aplikacja nie jest przeznaczona dla dzieci poniżej 13 lat i świadomie nie zbiera ich danych."),
            ("Twoje prawa", "Zdjęcia i listy produktów nie są przechowywane na serwerze, więc nie ma czego usuwać. "
                            "Liczniki limitów są usuwane automatycznie po 3 dniach. Dane zapisane w telefonie usuwasz "
                            "w aplikacji lub razem z nią. Kontakt: {email}."),
            ("Zmiany", "Jeśli polityka się zmieni, nowa wersja pojawi się pod tym samym adresem."),
        ],
        "items": [
            ("Zdjęcia, które robisz lub wybierasz", "są wysyłane na nasz serwer wyłącznie w celu rozpoznania produktów. "
             "Wcześniej usuwane są z nich metadane (w tym lokalizacja). Serwer przekazuje zdjęcia usłudze AI "
             "Anthropic (Claude) do analizy i nie przechowuje ich po odpowiedzi."),
            ("Lista produktów i ustawienia (dieta, czas, porcje, język)", "są wysyłane na serwer i do Anthropic, aby "
             "dobrać przepisy. Teksty szczegółowych przepisów są buforowane na serwerze bez powiązania z osobą."),
            ("Losowy identyfikator urządzenia", "tworzony przez aplikację (nie jest to identyfikator reklamowy ani numer "
             "telefonu); razem z adresem IP służy wyłącznie do dziennych limitów i ochrony przed nadużyciami. "
             "Liczniki są przechowywane nie dłużej niż 3 dni."),
            ("Mikrofon (tylko w trybie „Gotuj głosem”)", "polecenia głosowe rozpoznaje usługa mowy Twojego telefonu "
             "(Google lub Apple). Głos nie jest wysyłany na nasz serwer."),
            ("Zapisane przepisy i lista zakupów", "są przechowywane wyłącznie w Twoim telefonie."),
            ("Przesyłanie danych", "wyłącznie szyfrowanym połączeniem (HTTPS). Anthropic przetwarza dane jako dostawca "
             "usług zgodnie ze swoimi warunkami: https://www.anthropic.com/legal/privacy"),
        ],
        "updated": "Aktualizacja",
        "contact": "Kontakt",
    },
}


def privacy_html(lang: str, owner: str, email: str) -> str:
    t = TEXT.get(lang, TEXT["uk"])
    other = "pl" if lang == "uk" else "uk"
    fmt = {"owner": escape(owner), "email": f'<a href="mailto:{escape(email)}">{escape(email)}</a>'}
    body = []
    for title, text in t["sections"]:
        body.append(f"<h2>{escape(title)}</h2>")
        if text is None:
            body.append("<ul>" + "".join(
                f"<li><b>{escape(k)}</b> — {escape(v)}</li>" for k, v in t["items"]) + "</ul>")
        else:
            body.append(f"<p>{escape(text).replace('{owner}', fmt['owner']).replace('{email}', fmt['email'])}</p>")
    return f"""<!DOCTYPE html><html lang="{lang}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>{escape(t['title'])}</title>
<style>body{{font:16px/1.6 system-ui,sans-serif;max-width:720px;margin:0 auto;padding:24px 20px;color:#1C1238}}
h1{{font-size:26px;line-height:1.2}}h2{{font-size:18px;margin-top:28px}}li{{margin:8px 0}}a{{color:#5B3DF5}}
.lang{{float:right;font-weight:700}}</style></head><body>
<a class="lang" href="?lang={other}">{other.upper()}</a>
<h1>{escape(t['title'])}</h1><p>{t['updated']}: {UPDATED}</p>
{''.join(body)}
<p>{t['contact']}: {fmt['email']}</p></body></html>"""
