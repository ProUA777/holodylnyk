import 'app.dart';

/// Interface strings. Model names and descriptions live in assets/catalog.json.
String t(String key) => _s[app.lang]?[key] ?? _s['en']![key] ?? key;

/// "103 моделі", "22 деталі", "5 klocków" — number followed by the correctly declined noun.
String count(int n, String key) {
  final forms = _plural[app.lang]?[key] ?? _plural['en']![key];
  if (forms == null) return '$n ${t(key)}';
  final m10 = n % 10, m100 = n % 100;
  final String word;
  if (app.lang == 'en') {
    word = n == 1 ? forms[0] : forms[1];
  } else if (n == 1) {
    word = forms[0];
  } else if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) {
    word = forms[1];
  } else if (app.lang == 'uk' && m10 == 1 && m100 != 11) {
    word = forms[0];
  } else {
    word = forms[2];
  }
  return '$n $word';
}

/// Only the declined noun, for layouts that show the number separately.
String noun(int n, String key) => count(n, key).substring('$n '.length);

const _plural = <String, Map<String, List<String>>>{
  'uk': {'models': ['модель', 'моделі', 'моделей'], 'pieces': ['деталь', 'деталі', 'деталей'], 'ideasN': ['ідея', 'ідеї', 'ідей']},
  'pl': {'models': ['model', 'modele', 'modeli'], 'pieces': ['klocek', 'klocki', 'klocków'], 'ideasN': ['pomysł', 'pomysły', 'pomysłów']},
  'en': {'models': ['model', 'models'], 'pieces': ['piece', 'pieces'], 'ideasN': ['idea', 'ideas']},
};

const langNames = {'uk': 'Українська', 'pl': 'Polski', 'en': 'English'};

const _s = <String, Map<String, String>>{
  'uk': {
    'inYourColors': 'Моделі в кольорах твоїх деталей', 'moreIdeas': 'Ще ідеї від AI', 'fromInstr': 'Схоже, на фото інструкція або коробка набору{d}. Ми підібрали схожі моделі в його кольорах. Щоб порахувати саме твої деталі, сфотографуй їх купкою.', 'fromBuilt': 'Схоже, на фото вже зібрана модель{d}. Ось моделі в тих самих кольорах.', 'recolored': 'У твоїх кольорах',
    'continue': 'Продовжити збірку',
    'fullscreen': 'На весь екран', 'buildMode': 'Режим збірки', 'rotate': 'Повернути модель', 'exit': 'Вийти', 'highlightNew': 'Підсвічувати нові деталі', 'resumed': 'Продовжуєш з кроку {k}', 'favorites': 'Улюблені', 'addFav': 'Додати в улюблені', 'removeFav': 'Прибрати з улюблених', 'random': 'Випадкова', 'noFav': 'Тут з\'являться моделі, які ти позначиш сердечком ❤', 'startOver': 'Почати спочатку',
    'tapHint': 'Торкнись праворуч — далі, ліворуч — назад. Можна й свайпати.', 'stageA11y': 'Тривимірна модель. Торкніться правої частини, щоб перейти до наступного кроку, лівої — щоб повернутися.', 'lastStep': 'Це останній крок — натисни «Зібрав!»',
    'expert': 'Експерт', 'b10': 'Геній', 'b10d': 'Збери експертну', 'b11': 'Мандрівник', 'b11d': '3 пам\'ятки', 'b12': 'Король', 'b12d': 'Усі категорії',
    'from': 'ВІД', 'splashTag': 'Купка деталей → нова модель',
    'report': 'Поскаржитися на відповідь', 'reportTitle': 'Що не так з відповіддю?', 'rOffensive': 'Неприйнятний або образливий вміст',
    'rWrong': 'Неправильно розпізнано деталі', 'rOther': 'Інша проблема', 'reportThanks': 'Дякуємо! Ми перевіримо цю відповідь.',
    'reportFail': 'Не вдалося надіслати. Перевір інтернет.',
    'appName': 'Що зібрати?',
    'tScan': 'Сканувати', 'tIdeas': 'Ідеї', 'tMine': 'Мої збірки', 'settings': 'Налаштування',
    'back': 'Назад', 'cancel': 'Скасувати', 'close': 'Закрити', 'ok': 'Гаразд',
    'hint': 'Сфотографуй купку деталей конструктора — покажу, що з них зібрати, крок за кроком.',
    'camera': 'Сфотографувати деталі', 'gallery': 'Вибрати з галереї',
    'how1': 'Розклади деталі', 'how2': 'Сфотографуй', 'how3': 'Збирай по кроках',
    'piles': 'Приклади купок', 'pilesSub': 'Подивись, як виглядає результат', 'popular': 'Популярні моделі', 'all': 'Усі',
    'pieces': 'деталей', 'ideasN': 'ідей',
    'ob1t': 'Купка деталей — це скарб', 'ob1d': 'Сфотографуй деталі конструктора, і застосунок підкаже, що з них можна зібрати саме зараз.',
    'ob2t': 'Збирай у 3D по кроках', 'ob2d': 'Кожен крок показує, які деталі взяти й куди їх поставити. Нові цеглинки падають просто на модель.',
    'ob3t': 'Колекція й досягнення', 'ob3d': 'Зібрані моделі потрапляють у «Мої збірки». Отримуй зірки й нагороди за кожну.',
    'next': 'Далі', 'start': 'Почати', 'skip': 'Пропустити', 'chooseLang': 'Мова',
    'analyzing': 'Рахую деталі й вигадую моделі…', 'wait': 'Зазвичай 20–60 секунд',
    'tipsTitle': 'Як зробити гарне фото',
    'tip1': 'Розклади деталі одним шаром, щоб вони не лежали одна на одній.',
    'tip2': 'Фон — рівний і однотонний: стіл, підлога або аркуш паперу.',
    'tip3': 'Фотографуй згори при денному світлі, без різких тіней.',
    'eLimit': 'Ліміт сканувань на сьогодні вичерпано. Повертайся завтра, а поки — обери модель у каталозі!',
    'eBadPhoto': 'Це фото не вдалося відкрити. Спробуй інше (JPG або PNG).',
    'eNetwork': 'Немає з\'єднання з інтернетом. Перевір мережу й спробуй ще раз.',
    'eServer': 'Сервер зараз не відповідає. Спробуй трохи пізніше.',
    'eGeneric': 'Не вийшло проаналізувати фото. Спробуй ще раз.',
    'inventory': 'Що є в купці', 'special': 'Особливі деталі', 'ideasFound': 'Що можна зібрати',
    'unreadable': 'Не вдалося розгледіти деталі', 'example': 'Приклад', 'again': 'Нове фото',
    'catalogH': 'Каталог моделей', 'catalogP': 'Обери модель і збирай з 3D-підказками', 'search': 'Пошук моделі…',
    'models': 'моделей', 'anyDiff': 'Будь-яка', 'noFound': 'Нічого не знайшлося. Спробуй інше слово або категорію.',
    'easy': 'Легко', 'medium': 'Середньо', 'hard': 'Складно', 'min': 'хв', 'partsN': 'деталей', 'builtFlag': 'Зібрано',
    'step': 'Крок', 'of': 'з', 'prev': 'Назад', 'finish': 'Зібрав!', 'addNow': 'Додай зараз', 'allParts': 'Усі деталі',
    'stepHint': 'Додай {n} дет. · рівень {l}', 'steps': 'Кроки', 'plate': 'пластина', 'uses': 'Знадобиться',
    'doneTitle': 'Чудова робота!', 'doneText': 'Модель збережено в «Мої збірки».', 'alreadyBuilt': 'Ця модель уже є у твоїй колекції.',
    'toMine': 'До моїх збірок', 'another': 'Ще одну модель',
    'mineH': 'Мої збірки', 'built': 'зібрано', 'minutes': 'хвилин', 'stars': 'зірок', 'badges': 'Досягнення', 'history': 'Зібрані моделі',
    'emptyMine': 'Тут з\'являться моделі, які ти збереш. Почни з легкої!', 'pickModel': 'Обрати модель',
    'clear': 'Очистити історію', 'clearQ': 'Видалити всі зібрані моделі та досягнення?', 'clearYes': 'Видалити',
    'b1': 'Перша збірка', 'b1d': 'Збери 1 модель', 'b2': 'Майстер', 'b2d': 'Збери 10 моделей', 'b3': 'Сміливець', 'b3d': 'Збери складну',
    'b4': 'Космонавт', 'b4d': '2 космічні', 'b5': 'Зоопарк', 'b5d': '3 тварини', 'b6': 'Будівельник', 'b6d': '2 будівлі',
    'b7': 'Ласунчик', 'b7d': '2 смаколики', 'b8': 'Святковий', 'b8d': '2 святкові', 'b9': 'Колекціонер', 'b9d': '25 моделей',
    'language': 'Мова', 'theme': 'Тема', 'themeSystem': 'Як у системі', 'themeLight': 'Світла', 'themeDark': 'Темна',
    'privacy': 'Політика конфіденційності', 'about': 'Про застосунок', 'version': 'Версія', 'showIntro': 'Показати вступ ще раз',
    'aiNote': 'Фото надсилається на наш сервер лише для аналізу і не зберігається.',
    'forParents': 'Для батьків',
    'forParentsText': 'Застосунок не має реклами, покупок і реєстрації. Фото купки деталей надсилається на сервер тільки для аналізу й одразу видаляється. Радимо фотографувати лише деталі, без людей.',
  },
  'pl': {
    'inYourColors': 'Modele w kolorach twoich klocków', 'moreIdeas': 'Więcej pomysłów od AI', 'fromInstr': 'Wygląda na to, że na zdjęciu jest instrukcja lub pudełko zestawu{d}. Dobraliśmy podobne modele w jego kolorach. Aby policzyć twoje klocki, sfotografuj je na stosie.', 'fromBuilt': 'Wygląda na to, że na zdjęciu jest już zbudowany model{d}. Oto modele w tych samych kolorach.', 'recolored': 'W twoich kolorach',
    'continue': 'Dokończ budowę',
    'fullscreen': 'Pełny ekran', 'buildMode': 'Tryb budowania', 'rotate': 'Obróć model', 'exit': 'Wyjdź', 'highlightNew': 'Podświetlaj nowe klocki', 'resumed': 'Kontynuujesz od kroku {k}', 'favorites': 'Ulubione', 'addFav': 'Dodaj do ulubionych', 'removeFav': 'Usuń z ulubionych', 'random': 'Losowy', 'noFav': 'Tu pojawią się modele oznaczone serduszkiem ❤', 'startOver': 'Zacznij od nowa',
    'tapHint': 'Dotknij po prawej — dalej, po lewej — wstecz. Możesz też przesuwać.', 'stageA11y': 'Model 3D. Dotknij prawej części, aby przejść do następnego kroku, lewej — aby wrócić.', 'lastStep': 'To ostatni krok — naciśnij „Gotowe!”',
    'expert': 'Ekspert', 'b10': 'Geniusz', 'b10d': 'Zbuduj eksperta', 'b11': 'Podróżnik', 'b11d': '3 zabytki', 'b12': 'Król', 'b12d': 'Wszystkie kategorie',
    'from': 'OD', 'splashTag': 'Stos klocków → nowy model',
    'report': 'Zgłoś odpowiedź', 'reportTitle': 'Co jest nie tak z odpowiedzią?', 'rOffensive': 'Nieodpowiednie lub obraźliwe treści',
    'rWrong': 'Źle rozpoznane klocki', 'rOther': 'Inny problem', 'reportThanks': 'Dziękujemy! Sprawdzimy tę odpowiedź.',
    'reportFail': 'Nie udało się wysłać. Sprawdź internet.',
    'appName': 'Co zbudować?',
    'tScan': 'Skanuj', 'tIdeas': 'Pomysły', 'tMine': 'Moje budowle', 'settings': 'Ustawienia',
    'back': 'Wstecz', 'cancel': 'Anuluj', 'close': 'Zamknij', 'ok': 'OK',
    'hint': 'Zrób zdjęcie stosu klocków — pokażę, co z nich zbudować, krok po kroku.',
    'camera': 'Sfotografuj klocki', 'gallery': 'Wybierz z galerii',
    'how1': 'Rozłóż klocki', 'how2': 'Zrób zdjęcie', 'how3': 'Buduj krok po kroku',
    'piles': 'Przykładowe stosy', 'pilesSub': 'Zobacz, jak wygląda wynik', 'popular': 'Popularne modele', 'all': 'Wszystkie',
    'pieces': 'klocków', 'ideasN': 'pomysłów',
    'ob1t': 'Stos klocków to skarb', 'ob1d': 'Zrób zdjęcie klocków, a aplikacja podpowie, co możesz z nich zbudować już teraz.',
    'ob2t': 'Buduj w 3D krok po kroku', 'ob2d': 'Każdy krok pokazuje, które klocki wziąć i gdzie je położyć. Nowe klocki spadają prosto na model.',
    'ob3t': 'Kolekcja i osiągnięcia', 'ob3d': 'Zbudowane modele trafiają do „Moich budowli”. Zdobywaj gwiazdki i odznaki.',
    'next': 'Dalej', 'start': 'Zaczynamy', 'skip': 'Pomiń', 'chooseLang': 'Język',
    'analyzing': 'Liczę klocki i wymyślam modele…', 'wait': 'Zwykle 20–60 sekund',
    'tipsTitle': 'Jak zrobić dobre zdjęcie',
    'tip1': 'Rozłóż klocki jedną warstwą, żeby nie leżały na sobie.',
    'tip2': 'Tło gładkie i jednolite: stół, podłoga lub kartka papieru.',
    'tip3': 'Fotografuj z góry przy dziennym świetle, bez ostrych cieni.',
    'eLimit': 'Dzienny limit skanów wyczerpany. Wróć jutro, a na razie wybierz model z katalogu!',
    'eBadPhoto': 'Nie udało się otworzyć zdjęcia. Spróbuj innego (JPG lub PNG).',
    'eNetwork': 'Brak połączenia z internetem. Sprawdź sieć i spróbuj ponownie.',
    'eServer': 'Serwer nie odpowiada. Spróbuj za chwilę.',
    'eGeneric': 'Nie udało się przeanalizować zdjęcia. Spróbuj ponownie.',
    'inventory': 'Co jest w stosie', 'special': 'Specjalne elementy', 'ideasFound': 'Co można zbudować',
    'unreadable': 'Nie udało się rozpoznać klocków', 'example': 'Przykład', 'again': 'Nowe zdjęcie',
    'catalogH': 'Katalog modeli', 'catalogP': 'Wybierz model i buduj z podpowiedziami 3D', 'search': 'Szukaj modelu…',
    'models': 'modeli', 'anyDiff': 'Każdy poziom', 'noFound': 'Nic nie znaleziono. Spróbuj innego słowa lub kategorii.',
    'easy': 'Łatwe', 'medium': 'Średnie', 'hard': 'Trudne', 'min': 'min', 'partsN': 'klocków', 'builtFlag': 'Zbudowano',
    'step': 'Krok', 'of': 'z', 'prev': 'Wstecz', 'finish': 'Gotowe!', 'addNow': 'Dodaj teraz', 'allParts': 'Wszystkie klocki',
    'stepHint': 'Dodaj {n} el. · poziom {l}', 'steps': 'Kroki', 'plate': 'płytka', 'uses': 'Potrzebne',
    'doneTitle': 'Świetna robota!', 'doneText': 'Model zapisano w „Moich budowlach”.', 'alreadyBuilt': 'Ten model jest już w twojej kolekcji.',
    'toMine': 'Do moich budowli', 'another': 'Kolejny model',
    'mineH': 'Moje budowle', 'built': 'zbudowano', 'minutes': 'minut', 'stars': 'gwiazdek', 'badges': 'Osiągnięcia', 'history': 'Zbudowane modele',
    'emptyMine': 'Tu pojawią się zbudowane modele. Zacznij od łatwego!', 'pickModel': 'Wybierz model',
    'clear': 'Wyczyść historię', 'clearQ': 'Usunąć wszystkie zbudowane modele i osiągnięcia?', 'clearYes': 'Usuń',
    'b1': 'Pierwsza budowla', 'b1d': 'Zbuduj 1 model', 'b2': 'Mistrz', 'b2d': 'Zbuduj 10 modeli', 'b3': 'Odważny', 'b3d': 'Zbuduj trudny',
    'b4': 'Kosmonauta', 'b4d': '2 kosmiczne', 'b5': 'Zoo', 'b5d': '3 zwierzęta', 'b6': 'Budowniczy', 'b6d': '2 budynki',
    'b7': 'Łasuch', 'b7d': '2 smakołyki', 'b8': 'Świąteczny', 'b8d': '2 świąteczne', 'b9': 'Kolekcjoner', 'b9d': '25 modeli',
    'language': 'Język', 'theme': 'Motyw', 'themeSystem': 'Systemowy', 'themeLight': 'Jasny', 'themeDark': 'Ciemny',
    'privacy': 'Polityka prywatności', 'about': 'O aplikacji', 'version': 'Wersja', 'showIntro': 'Pokaż wprowadzenie ponownie',
    'aiNote': 'Zdjęcie trafia na nasz serwer tylko do analizy i nie jest przechowywane.',
    'forParents': 'Dla rodziców',
    'forParentsText': 'Aplikacja nie ma reklam, zakupów ani rejestracji. Zdjęcie klocków jest wysyłane na serwer tylko do analizy i od razu usuwane. Zalecamy fotografowanie samych klocków, bez ludzi.',
  },
  'en': {
    'inYourColors': 'Models in your brick colours', 'moreIdeas': 'More ideas from AI', 'fromInstr': 'Looks like this is a set\'s instructions or box{d}. We picked similar models in its colours. To count your own bricks, photograph them in a pile.', 'fromBuilt': 'Looks like this is an already built model{d}. Here are models in the same colours.', 'recolored': 'In your colours',
    'continue': 'Continue building',
    'fullscreen': 'Full screen', 'buildMode': 'Build mode', 'rotate': 'Rotate model', 'exit': 'Exit', 'highlightNew': 'Highlight new pieces', 'resumed': 'Picking up at step {k}', 'favorites': 'Favourites', 'addFav': 'Add to favourites', 'removeFav': 'Remove from favourites', 'random': 'Random', 'noFav': 'Models you mark with a heart ❤ will show up here', 'startOver': 'Start over',
    'tapHint': 'Tap the right side for next, the left side to go back. Swiping works too.', 'stageA11y': '3D model. Tap the right side for the next step, the left side to go back.', 'lastStep': 'This is the last step — tap “Built it!”',
    'expert': 'Expert', 'b10': 'Genius', 'b10d': 'Build an expert one', 'b11': 'Traveller', 'b11d': '3 landmarks', 'b12': 'King', 'b12d': 'Every category',
    'from': 'FROM', 'splashTag': 'A pile of bricks → a new model',
    'report': 'Report this answer', 'reportTitle': 'What\'s wrong with the answer?', 'rOffensive': 'Inappropriate or offensive content',
    'rWrong': 'Bricks recognised incorrectly', 'rOther': 'Something else', 'reportThanks': 'Thanks! We\'ll review this answer.',
    'reportFail': 'Couldn\'t send. Check your internet.',
    'appName': 'What to build?',
    'tScan': 'Scan', 'tIdeas': 'Ideas', 'tMine': 'My builds', 'settings': 'Settings',
    'back': 'Back', 'cancel': 'Cancel', 'close': 'Close', 'ok': 'OK',
    'hint': 'Snap a pile of building bricks — I\'ll show what you can build, step by step.',
    'camera': 'Photograph bricks', 'gallery': 'Choose from gallery',
    'how1': 'Spread bricks', 'how2': 'Take a photo', 'how3': 'Build step by step',
    'piles': 'Example piles', 'pilesSub': 'See what a result looks like', 'popular': 'Popular models', 'all': 'All',
    'pieces': 'pieces', 'ideasN': 'ideas',
    'ob1t': 'A pile of bricks is a treasure', 'ob1d': 'Take a photo of your bricks and the app suggests what you can build right now.',
    'ob2t': 'Build in 3D, step by step', 'ob2d': 'Each step shows which pieces to take and where they go. New bricks drop right onto the model.',
    'ob3t': 'Collection and achievements', 'ob3d': 'Finished models go to My builds. Earn stars and badges for each one.',
    'next': 'Next', 'start': 'Let\'s go', 'skip': 'Skip', 'chooseLang': 'Language',
    'analyzing': 'Counting bricks and dreaming up models…', 'wait': 'Usually 20–60 seconds',
    'tipsTitle': 'How to take a good photo',
    'tip1': 'Spread the bricks in one layer so they don\'t overlap.',
    'tip2': 'Use a plain, single-colour surface: a table, the floor or a sheet of paper.',
    'tip3': 'Shoot from above in daylight, without harsh shadows.',
    'eLimit': 'You\'ve used today\'s scans. Come back tomorrow — meanwhile, pick a model from the catalog!',
    'eBadPhoto': 'That photo couldn\'t be opened. Try another one (JPG or PNG).',
    'eNetwork': 'No internet connection. Check your network and try again.',
    'eServer': 'The server isn\'t responding. Please try again later.',
    'eGeneric': 'Couldn\'t analyse the photo. Please try again.',
    'inventory': 'What\'s in the pile', 'special': 'Special pieces', 'ideasFound': 'What you can build',
    'unreadable': 'Couldn\'t make out the bricks', 'example': 'Example', 'again': 'New photo',
    'catalogH': 'Model catalog', 'catalogP': 'Pick a model and build with 3D hints', 'search': 'Search models…',
    'models': 'models', 'anyDiff': 'Any level', 'noFound': 'Nothing found. Try another word or category.',
    'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard', 'min': 'min', 'partsN': 'pieces', 'builtFlag': 'Built',
    'step': 'Step', 'of': 'of', 'prev': 'Back', 'finish': 'Built it!', 'addNow': 'Add now', 'allParts': 'All pieces',
    'stepHint': 'Add {n} pieces · level {l}', 'steps': 'Steps', 'plate': 'plate', 'uses': 'You\'ll need',
    'doneTitle': 'Great job!', 'doneText': 'The model is saved to My builds.', 'alreadyBuilt': 'This model is already in your collection.',
    'toMine': 'Go to My builds', 'another': 'Another model',
    'mineH': 'My builds', 'built': 'built', 'minutes': 'minutes', 'stars': 'stars', 'badges': 'Achievements', 'history': 'Built models',
    'emptyMine': 'Models you build will show up here. Start with an easy one!', 'pickModel': 'Pick a model',
    'clear': 'Clear history', 'clearQ': 'Delete all built models and achievements?', 'clearYes': 'Delete',
    'b1': 'First build', 'b1d': 'Build 1 model', 'b2': 'Master', 'b2d': 'Build 10 models', 'b3': 'Daredevil', 'b3d': 'Build a hard one',
    'b4': 'Astronaut', 'b4d': '2 space models', 'b5': 'Zoo keeper', 'b5d': '3 animals', 'b6': 'Builder', 'b6d': '2 buildings',
    'b7': 'Sweet tooth', 'b7d': '2 treats', 'b8': 'Festive', 'b8d': '2 holiday models', 'b9': 'Collector', 'b9d': '25 models',
    'language': 'Language', 'theme': 'Theme', 'themeSystem': 'System', 'themeLight': 'Light', 'themeDark': 'Dark',
    'privacy': 'Privacy policy', 'about': 'About', 'version': 'Version', 'showIntro': 'Show the intro again',
    'aiNote': 'Your photo is sent to our server only for analysis and is not stored.',
    'forParents': 'For parents',
    'forParentsText': 'No ads, no purchases, no sign-up. The photo of the bricks is sent to the server only for analysis and deleted straight away. We recommend photographing just the bricks, without people.',
  },
};

/// Privacy policy shown in the app. Keep in sync with backend/app/static/privacy.html.
const privacyText = {
  'uk': '''Ця політика описує, як застосунок «Що зібрати?» (Greater Koreec Project Group) працює з даними.

Що ми обробляємо
• Фото, яке ви робите або вибираєте для аналізу. Воно передається на наш сервер через захищене з'єднання (HTTPS), аналізується штучним інтелектом і не зберігається: після відповіді фото видаляється з пам'яті сервера.
• Випадковий ідентифікатор пристрою, створений застосунком (не пов'язаний з вашим обліковим записом чи рекламним ID). Він потрібен лише для денного ліміту сканувань.

Чого ми не робимо
• Не збираємо імена, email, контакти, геолокацію.
• Не показуємо рекламу й не використовуємо рекламні чи аналітичні SDK.
• Не продаємо й не передаємо дані третім особам, окрім постачальника AI-аналізу, який обробляє фото тільки для формування відповіді.

На пристрої
Мова, тема та список зібраних моделей зберігаються лише у вашому телефоні. Їх можна видалити в «Мої збірки» → «Очистити історію» або видаливши застосунок.

Діти
Застосунок розрахований на дітей разом із батьками. Радимо фотографувати лише деталі конструктора, без людей.

Контакти
Питання щодо конфіденційності: через сторінку застосунку в Google Play.''',
  'pl': '''Niniejsza polityka opisuje, jak aplikacja „Co zbudować?” (Greater Koreec Project Group) przetwarza dane.

Co przetwarzamy
• Zdjęcie, które robisz lub wybierasz do analizy. Jest wysyłane na nasz serwer bezpiecznym połączeniem (HTTPS), analizowane przez sztuczną inteligencję i nie jest przechowywane: po udzieleniu odpowiedzi zdjęcie jest usuwane z pamięci serwera.
• Losowy identyfikator urządzenia utworzony przez aplikację (niepowiązany z kontem ani identyfikatorem reklamowym). Służy tylko do dziennego limitu skanów.

Czego nie robimy
• Nie zbieramy imion, adresów e-mail, kontaktów ani lokalizacji.
• Nie wyświetlamy reklam i nie używamy reklamowych ani analitycznych SDK.
• Nie sprzedajemy ani nie przekazujemy danych osobom trzecim, poza dostawcą analizy AI, który przetwarza zdjęcie wyłącznie w celu przygotowania odpowiedzi.

Na urządzeniu
Język, motyw i lista zbudowanych modeli są przechowywane tylko w telefonie. Można je usunąć w „Moje budowle” → „Wyczyść historię” lub odinstalowując aplikację.

Dzieci
Aplikacja jest przeznaczona dla dzieci wraz z rodzicami. Zalecamy fotografowanie wyłącznie klocków, bez ludzi.

Kontakt
Pytania dotyczące prywatności: przez stronę aplikacji w Google Play.''',
  'en': '''This policy describes how the “What to build?” app (Greater Koreec Project Group) handles data.

What we process
• The photo you take or choose for analysis. It is sent to our server over a secure connection (HTTPS), analysed by artificial intelligence and not stored: once the answer is ready, the photo is removed from the server's memory.
• A random device identifier created by the app (not linked to any account or advertising ID). It is used only for the daily scan limit.

What we don't do
• We don't collect names, emails, contacts or location.
• We don't show ads and don't use advertising or analytics SDKs.
• We don't sell or share data with third parties, except the AI analysis provider, which processes the photo only to produce the answer.

On your device
Language, theme and your list of built models are stored only on your phone. You can delete them in My builds → Clear history, or by uninstalling the app.

Children
The app is designed for children together with their parents. We recommend photographing only the bricks, without people.

Contact
Privacy questions: via the app's Google Play page.''',
};
