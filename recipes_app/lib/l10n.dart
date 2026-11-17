import 'package:flutter/widgets.dart';

import 'api.dart';
import 'models.dart';

/// Усі тексти апки двома мовами. Додати мову = ще одна реалізація Strings.
/// Використання: final t = L10n.of(context); Text(t.takePhoto)
abstract class Strings {
  String get code; // 'uk' | 'pl' — і мова інтерфейсу, і мова рецептів
  String get languageName;

  // Головна
  String get appName;
  String get homeTitle;
  String get homeSubtitle;
  String get takePhoto;
  String get takePhotoHint;
  String get gallery;
  String get typeIn;
  String get settings;
  String get noCamera;
  String portions(int n);
  String get anyTime;
  String upToMin(int n);
  String get diet;
  String get timeAvailable;
  String get anyTimeChip;
  String get servings;
  String get done;
  String get language;
  Map<Diet, String> get dietLabels;
  Map<String, String> get mealTypeLabels;
  Map<String, String> get difficultyLabels;

  // Фото
  String get photosTitle;
  String get photosHint;
  String get addPhoto;
  String get camera;
  String get findRecipes;
  String maxPhotos(int n);

  // Результати
  String get scanTitle;
  String get scanText;
  String get pickTitle;
  String get pickText;
  String get otherPhoto;
  String get tryAgain;
  String get myProducts;
  String foundProducts(int n);
  String get addAllYouHave;
  String get removeHint;
  String get add;
  String get remove;
  String get productHint;
  String get pickRecipes;
  String get updateRecipes;
  String get emptyManual;
  String get canCook;
  String dishes(int n);
  String get all;
  String get moreRecipes;
  String get searchingMore;
  String get noMoreIdeas;
  String added(int n);
  String minutes(int n);
  String get allAtHome;
  String toBuy(int n);

  // Рецепт
  String portionsShort(int n);
  String kcal(int n);
  String addToShopping(int n);
  String addedToShopping(int n);
  String get open;
  String get writingDetails;
  String get loadDetails;
  String get ingredientsH;
  String get cookingH;
  String get toBuyMark;
  String get save;
  String get unsave;
  String get saved;
  String get removedFromSaved;
  String get startCooking;

  // Готую
  String stepOf(int i, int n);
  String get startTimer;
  String get stopTimer;
  String timerOfStep(int i, String t);
  String timeUp(int i);
  String get back;
  String get next;
  String get finish;
  String get enjoy;
  String get close;
  String get voiceOn;
  String get voiceOff;
  String get voiceHint;
  String get voiceUnavailable;
  String get ttsLocale; // мова озвучки, напр. uk-UA
  String get sttLocale; // мова розпізнавання, напр. uk_UA
  List<String> get cmdNext;
  List<String> get cmdBack;
  List<String> get cmdRepeat;
  List<String> get cmdTimer;

  // Порції й поділитися
  String get share;
  String get sharedFrom;
  String get forServings;

  // Збережені
  String get savedTitle;
  String get savedEmpty;
  String get swipeToDelete;

  // Покупки
  String get shoppingTitle;
  String get shoppingEmpty;
  String get forRecipes;
  String get copyList;
  String get clearBought;
  String get listCopied;
  String get addOwnItem;
  String get shoppingHeader;
  String leftToBuy(int n);

  // Свіжість, БЖУ, смаки, меню, історія
  String get goal;
  Map<Goal, String> get goalLabels;
  String get useSoonHint;
  String get useSoonMark;
  String saves(String items);
  String macros(int p, int f, int c);
  String get perServing;
  String get likeQuestion;
  String get likedThanks;
  String get dislikedThanks;
  String get weekMenu;
  String get planLoading;
  String day(int n);
  String get mealsPerDay;
  Map<int, String> get mealsOptions;
  String get toBuyWeek;
  String addAllToShopping(int n);
  String get nothingToBuy;
  String get makePlan;
  String get recentScans;
  String productsN(int n);
  String dateLabel(DateTime d);

  // Навігація
  String get navHome;
  String get navSaved;
  String get navShopping;

  // Помилки
  String get errNetwork;
  String get errTimeout;
  String get errRateLimited;
  String get errTooLarge;
  String get errBadImage;
  String get errUnauthorized;
  String get errDailyLimit;
  String get errTooManyPhotos;
  String get errNothing;
  String get errGeneric;

  /// Текст помилки мовою інтерфейсу. «Нічого не видно» пише сам AI — вже потрібною мовою.
  String error(ApiException e) => switch (e.code) {
        'network' => errNetwork,
        'timeout' => errTimeout,
        'rate_limited' => errRateLimited,
        'image_too_large' => errTooLarge,
        'bad_image' => errBadImage,
        'unauthorized' => errUnauthorized,
        'daily_limit' => errDailyLimit,
        'too_many_photos' => errTooManyPhotos,
        'nothing_recognized' => e.serverMessage ?? errNothing,
        _ => errGeneric,
      };

  String prefsSummary(RecipeParams p) => [
        '${p.servings} ${portions(p.servings)}',
        p.maxTimeMinutes == null ? anyTime : upToMin(p.maxTimeMinutes!),
        dietLabels[p.diet]!.toLowerCase(),
      ].join(', ');
}

class StringsUk extends Strings {
  @override
  final code = 'uk';
  @override
  final languageName = 'Українська';

  @override
  final appName = 'Що приготувати';
  @override
  final homeTitle = 'Що приготувати?';
  @override
  final homeSubtitle = 'Сфотографуй холодильник чи продукти на столі, і я запропоную страви саме з них.';
  @override
  final takePhoto = 'Сфотографувати';
  @override
  final takePhotoHint = 'Відкрий холодильник і зніми полиці так, щоб було видно продукти';
  @override
  final gallery = 'Галерея';
  @override
  final typeIn = 'Вписати';
  @override
  final settings = 'Налаштування';
  @override
  final noCamera = 'Немає доступу до камери чи галереї. Дозволь його в налаштуваннях телефона.';
  @override
  String portions(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'порція';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'порції';
    return 'порцій';
  }

  @override
  final anyTime = 'будь-який час';
  @override
  String upToMin(int n) => 'до $n хв';
  @override
  final diet = 'Харчування';
  @override
  final timeAvailable = 'Скільки часу є';
  @override
  final anyTimeChip = 'Будь-скільки';
  @override
  final servings = 'Порцій';
  @override
  final done = 'Готово';
  @override
  final language = 'Мова';
  @override
  final dietLabels = const {
    Diet.any: 'Без обмежень',
    Diet.vegetarian: 'Вегетаріанське',
    Diet.vegan: 'Веганське',
    Diet.noPork: 'Без свинини',
    Diet.glutenFree: 'Без глютену',
    Diet.lactoseFree: 'Без лактози',
  };
  @override
  final mealTypeLabels = const {
    'breakfast': 'Сніданок',
    'soup': 'Суп',
    'main': 'Основна страва',
    'salad': 'Салат',
    'baking': 'Випічка',
    'dessert': 'Десерт',
    'snack': 'Закуска',
    'drink': 'Напій',
  };
  @override
  final difficultyLabels = const {'easy': 'Легко', 'medium': 'Середньо', 'hard': 'Складно'};

  @override
  final photosTitle = 'Твої фото';
  @override
  final photosHint = 'Додай ще морозилку чи полицю з крупами, щоб я побачив більше продуктів.';
  @override
  final addPhoto = 'Додати фото';
  @override
  final camera = 'Камера';
  @override
  final findRecipes = 'Знайти рецепти';
  @override
  String maxPhotos(int n) => 'До $n фото за раз';

  @override
  final scanTitle = 'Роздивляюся продукти';
  @override
  final scanText = 'Шукаю всі продукти на фото й складаю 6 різних страв. Зазвичай 15–40 секунд.';
  @override
  final pickTitle = 'Підбираю страви';
  @override
  final pickText = 'Різні кухні, різні способи приготування. Зазвичай 10–30 секунд.';
  @override
  final otherPhoto = 'Зробити інше фото';
  @override
  final tryAgain = 'Спробувати ще раз';
  @override
  final myProducts = 'Мої продукти';
  @override
  String foundProducts(int n) {
    final m10 = n % 10, m100 = n % 100;
    final w = (m10 == 1 && m100 != 11)
        ? 'продукт'
        : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14))
            ? 'продукти'
            : 'продуктів';
    return 'Знайшов $n $w';
  }

  @override
  final addAllYouHave = 'Додай усе, що маєш';
  @override
  final removeHint = 'Прибери зайве або додай, чого не видно';
  @override
  final add = 'Додати';
  @override
  final remove = 'Прибрати';
  @override
  final productHint = 'напр. картопля';
  @override
  final pickRecipes = 'Підібрати рецепти';
  @override
  final updateRecipes = 'Оновити рецепти';
  @override
  final emptyManual = 'Впиши хоча б кілька продуктів. Наприклад: картопля, яйця, сир.';
  @override
  final canCook = 'Можна приготувати';
  @override
  String dishes(int n) => '$n страв';
  @override
  final all = 'Усі';
  @override
  final moreRecipes = 'Ще рецепти з інших кухонь';
  @override
  final searchingMore = 'Шукаю інші страви…';
  @override
  final noMoreIdeas = 'Більше ідей з цих продуктів немає. Додай ще щось.';
  @override
  String added(int n) => 'Додано страв: $n';
  @override
  String minutes(int n) => '$n хв';
  @override
  final allAtHome = 'Все є вдома';
  @override
  String toBuy(int n) => 'Докупити $n';

  @override
  String portionsShort(int n) => '$n порц.';
  @override
  String kcal(int n) => '≈$n ккал';
  @override
  String addToShopping(int n) => 'Додати в покупки ($n)';
  @override
  String addedToShopping(int n) => 'Додано в покупки: $n';
  @override
  final open = 'Відкрити';
  @override
  final writingDetails = 'Пишу детальний рецепт: грами, вогонь, час і ознаки готовності. 10–30 секунд…';
  @override
  final loadDetails = 'Завантажити детальний рецепт';
  @override
  final ingredientsH = 'Інгредієнти';
  @override
  final cookingH = 'Приготування';
  @override
  final toBuyMark = 'треба докупити';
  @override
  final save = 'Зберегти';
  @override
  final unsave = 'Прибрати зі збережених';
  @override
  final saved = 'Збережено';
  @override
  final removedFromSaved = 'Прибрано зі збережених';
  @override
  final startCooking = 'Почати готувати';

  @override
  String stepOf(int i, int n) => 'Крок $i з $n';
  @override
  final startTimer = 'Запустити таймер';
  @override
  final stopTimer = 'Зупинити таймер';
  @override
  String timerOfStep(int i, String t) => 'Таймер кроку $i: $t';
  @override
  String timeUp(int i) => 'Крок $i: час вийшов';
  @override
  final back = 'Назад';
  @override
  final next = 'Далі';
  @override
  final finish = 'Готово! Смачного';
  @override
  final enjoy = 'Смачного! 🍽';
  @override
  final close = 'Закрити';
  @override
  final voiceOn = 'Голос увімкнено';
  @override
  final voiceOff = 'Готувати голосом';
  @override
  final voiceHint = 'Скажи «далі», «назад», «повтори» або «таймер»';
  @override
  final voiceUnavailable = 'Розпізнавання мови недоступне. Дозволь мікрофон у налаштуваннях телефона.';
  @override
  final ttsLocale = 'uk-UA';
  @override
  final sttLocale = 'uk_UA';
  @override
  final cmdNext = const ['далі', 'дальше', 'наступний', 'вперед', 'готово'];
  @override
  final cmdBack = const ['назад', 'попередній'];
  @override
  final cmdRepeat = const ['повтори', 'ще раз', 'повтор'];
  @override
  final cmdTimer = const ['таймер', 'засічи', 'засікай'];

  @override
  final share = 'Поділитися';
  @override
  final sharedFrom = 'Рецепт з апки «Що приготувати»';
  @override
  final forServings = 'на';

  @override
  final savedTitle = 'Збережені';
  @override
  final savedEmpty = 'Натисни на сердечко в рецепті, і він збережеться тут разом з детальними кроками.';
  @override
  final swipeToDelete = 'Свайп вліво — видалити';

  @override
  final shoppingTitle = 'Покупки';
  @override
  final shoppingEmpty = 'Тут з\'явиться все, що треба докупити. Відкрий рецепт і натисни «Додати в покупки».';
  @override
  final forRecipes = 'для';
  @override
  final copyList = 'Скопіювати список';
  @override
  final clearBought = 'Прибрати куплене';
  @override
  final listCopied = 'Список скопійовано';
  @override
  final addOwnItem = 'Додати свій пункт';
  @override
  final shoppingHeader = 'Купити:';
  @override
  String leftToBuy(int n) => 'Залишилось купити: $n';

  @override
  final goal = 'Ціль';
  @override
  final goalLabels = const {Goal.any: 'Будь-що', Goal.light: 'Легке', Goal.protein: 'Білкове'};
  @override
  final useSoonHint = 'Торкнись продукту, щоб позначити «скоро зіпсується» — страви з нього підуть першими';
  @override
  final useSoonMark = 'скоро зіпсується';
  @override
  String saves(String items) => 'Рятує: $items';
  @override
  String macros(int p, int f, int c) => 'Б $p г · Ж $f г · В $c г';
  @override
  final perServing = 'на порцію';
  @override
  final likeQuestion = 'Сподобалось?';
  @override
  final likedThanks = 'Запам\'ятав: пропонуватиму схоже';
  @override
  final dislikedThanks = 'Запам\'ятав: такого більше не пропонуватиму';
  @override
  final weekMenu = 'Меню на тиждень';
  @override
  final planLoading = 'Складаю меню на тиждень з твоїх продуктів. Зазвичай 20–60 секунд…';
  @override
  String day(int n) => 'День $n';
  @override
  final mealsPerDay = 'Страв на день';
  @override
  final mealsOptions = const {1: 'Обід', 2: 'Сніданок і вечеря', 3: 'Три рази'};
  @override
  final toBuyWeek = 'Докупити на тиждень';
  @override
  String addAllToShopping(int n) => 'Додати все в покупки ($n)';
  @override
  final nothingToBuy = 'Докуповувати нічого не треба';
  @override
  final makePlan = 'Скласти меню';
  @override
  final recentScans = 'Останні сканування';
  @override
  String productsN(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return '$n продукт';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return '$n продукти';
    return '$n продуктів';
  }

  @override
  String dateLabel(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days == 0) return 'сьогодні';
    if (days == 1) return 'вчора';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }

  @override
  final navHome = 'Головна';
  @override
  final navSaved = 'Збережені';
  @override
  final navShopping = 'Покупки';

  @override
  final errNetwork = 'Немає з\'єднання з інтернетом або сервером.';
  @override
  final errTimeout = 'Сервер довго не відповідає. Спробуй ще раз.';
  @override
  final errRateLimited = 'Забагато запитів. Зачекай хвилинку.';
  @override
  final errTooLarge = 'Фото завелике.';
  @override
  final errBadImage = 'Не вдалося прочитати фото. Спробуй інше.';
  @override
  final errUnauthorized = 'Застосунок не авторизований на сервері.';
  @override
  final errDailyLimit = 'На сьогодні ліміт вичерпано. Спробуй завтра. Збережені рецепти працюють як і раніше.';
  @override
  final errTooManyPhotos = 'Забагато фото. Можна до 3 за раз.';
  @override
  final errNothing = 'На фото не видно продуктів. Сфотографуй відкритий холодильник або стіл з продуктами.';
  @override
  final errGeneric = 'Щось пішло не так. Спробуй ще раз.';
}

class StringsPl extends Strings {
  @override
  final code = 'pl';
  @override
  final languageName = 'Polski';

  @override
  final appName = 'Co ugotować';
  @override
  final homeTitle = 'Co ugotować?';
  @override
  final homeSubtitle = 'Zrób zdjęcie lodówki lub produktów na stole, a zaproponuję dania właśnie z nich.';
  @override
  final takePhoto = 'Zrób zdjęcie';
  @override
  final takePhotoHint = 'Otwórz lodówkę i sfotografuj półki tak, żeby było widać produkty';
  @override
  final gallery = 'Galeria';
  @override
  final typeIn = 'Wpisz';
  @override
  final settings = 'Ustawienia';
  @override
  final noCamera = 'Brak dostępu do aparatu lub galerii. Zezwól na niego w ustawieniach telefonu.';
  @override
  String portions(int n) {
    if (n == 1) return 'porcja';
    final m10 = n % 10, m100 = n % 100;
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'porcje';
    return 'porcji';
  }

  @override
  final anyTime = 'dowolny czas';
  @override
  String upToMin(int n) => 'do $n min';
  @override
  final diet = 'Dieta';
  @override
  final timeAvailable = 'Ile masz czasu';
  @override
  final anyTimeChip = 'Bez limitu';
  @override
  final servings = 'Porcje';
  @override
  final done = 'Gotowe';
  @override
  final language = 'Język';
  @override
  final dietLabels = const {
    Diet.any: 'Bez ograniczeń',
    Diet.vegetarian: 'Wegetariańska',
    Diet.vegan: 'Wegańska',
    Diet.noPork: 'Bez wieprzowiny',
    Diet.glutenFree: 'Bez glutenu',
    Diet.lactoseFree: 'Bez laktozy',
  };
  @override
  final mealTypeLabels = const {
    'breakfast': 'Śniadanie',
    'soup': 'Zupa',
    'main': 'Danie główne',
    'salad': 'Sałatka',
    'baking': 'Wypieki',
    'dessert': 'Deser',
    'snack': 'Przekąska',
    'drink': 'Napój',
  };
  @override
  final difficultyLabels = const {'easy': 'Łatwe', 'medium': 'Średnie', 'hard': 'Trudne'};

  @override
  final photosTitle = 'Twoje zdjęcia';
  @override
  final photosHint = 'Dodaj jeszcze zamrażarkę lub półkę z produktami, żebym zobaczył więcej.';
  @override
  final addPhoto = 'Dodaj zdjęcie';
  @override
  final camera = 'Aparat';
  @override
  final findRecipes = 'Znajdź przepisy';
  @override
  String maxPhotos(int n) => 'Do $n zdjęć naraz';

  @override
  final scanTitle = 'Przeglądam produkty';
  @override
  final scanText = 'Szukam wszystkich produktów na zdjęciach i układam 6 różnych dań. Zwykle 15–40 sekund.';
  @override
  final pickTitle = 'Dobieram dania';
  @override
  final pickText = 'Różne kuchnie i sposoby przyrządzania. Zwykle 10–30 sekund.';
  @override
  final otherPhoto = 'Zrób inne zdjęcie';
  @override
  final tryAgain = 'Spróbuj ponownie';
  @override
  final myProducts = 'Moje produkty';
  @override
  String foundProducts(int n) {
    final m10 = n % 10, m100 = n % 100;
    final w = n == 1
        ? 'produkt'
        : (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14))
            ? 'produkty'
            : 'produktów';
    return 'Znalazłem $n $w';
  }

  @override
  final addAllYouHave = 'Dodaj wszystko, co masz';
  @override
  final removeHint = 'Usuń zbędne lub dodaj to, czego nie widać';
  @override
  final add = 'Dodaj';
  @override
  final remove = 'Usuń';
  @override
  final productHint = 'np. ziemniaki';
  @override
  final pickRecipes = 'Dobierz przepisy';
  @override
  final updateRecipes = 'Odśwież przepisy';
  @override
  final emptyManual = 'Wpisz choć kilka produktów. Na przykład: ziemniaki, jajka, ser.';
  @override
  final canCook = 'Możesz ugotować';
  @override
  String dishes(int n) => 'Dań: $n';
  @override
  final all = 'Wszystkie';
  @override
  final moreRecipes = 'Więcej przepisów z innych kuchni';
  @override
  final searchingMore = 'Szukam innych dań…';
  @override
  final noMoreIdeas = 'Brak nowych pomysłów z tych produktów. Dodaj coś jeszcze.';
  @override
  String added(int n) => 'Dodano dań: $n';
  @override
  String minutes(int n) => '$n min';
  @override
  final allAtHome = 'Wszystko jest w domu';
  @override
  String toBuy(int n) => 'Dokupić: $n';

  @override
  String portionsShort(int n) => '$n porc.';
  @override
  String kcal(int n) => '≈$n kcal';
  @override
  String addToShopping(int n) => 'Dodaj do zakupów ($n)';
  @override
  String addedToShopping(int n) => 'Dodano do zakupów: $n';
  @override
  final open = 'Otwórz';
  @override
  final writingDetails = 'Piszę szczegółowy przepis: gramy, ogień, czas i oznaki gotowości. 10–30 sekund…';
  @override
  final loadDetails = 'Pobierz szczegółowy przepis';
  @override
  final ingredientsH = 'Składniki';
  @override
  final cookingH = 'Przyrządzanie';
  @override
  final toBuyMark = 'do kupienia';
  @override
  final save = 'Zapisz';
  @override
  final unsave = 'Usuń z zapisanych';
  @override
  final saved = 'Zapisano';
  @override
  final removedFromSaved = 'Usunięto z zapisanych';
  @override
  final startCooking = 'Zacznij gotować';

  @override
  String stepOf(int i, int n) => 'Krok $i z $n';
  @override
  final startTimer = 'Uruchom minutnik';
  @override
  final stopTimer = 'Zatrzymaj minutnik';
  @override
  String timerOfStep(int i, String t) => 'Minutnik kroku $i: $t';
  @override
  String timeUp(int i) => 'Krok $i: czas minął';
  @override
  final back = 'Wstecz';
  @override
  final next = 'Dalej';
  @override
  final finish = 'Gotowe! Smacznego';
  @override
  final enjoy = 'Smacznego! 🍽';
  @override
  final close = 'Zamknij';
  @override
  final voiceOn = 'Głos włączony';
  @override
  final voiceOff = 'Gotuj głosem';
  @override
  final voiceHint = 'Powiedz „dalej”, „wstecz”, „powtórz” lub „minutnik”';
  @override
  final voiceUnavailable = 'Rozpoznawanie mowy jest niedostępne. Zezwól na mikrofon w ustawieniach telefonu.';
  @override
  final ttsLocale = 'pl-PL';
  @override
  final sttLocale = 'pl_PL';
  @override
  final cmdNext = const ['dalej', 'następny', 'następna', 'gotowe'];
  @override
  final cmdBack = const ['wstecz', 'cofnij', 'poprzedni'];
  @override
  final cmdRepeat = const ['powtórz', 'jeszcze raz'];
  @override
  final cmdTimer = const ['minutnik', 'timer', 'odliczaj'];

  @override
  final share = 'Udostępnij';
  @override
  final sharedFrom = 'Przepis z aplikacji „Co ugotować”';
  @override
  final forServings = 'na';

  @override
  final savedTitle = 'Zapisane';
  @override
  final savedEmpty = 'Dotknij serca w przepisie, a zapisze się tutaj razem ze szczegółowymi krokami.';
  @override
  final swipeToDelete = 'Przesuń w lewo, aby usunąć';

  @override
  final shoppingTitle = 'Zakupy';
  @override
  final shoppingEmpty = 'Tutaj pojawi się wszystko, co trzeba dokupić. Otwórz przepis i dotknij „Dodaj do zakupów”.';
  @override
  final forRecipes = 'do';
  @override
  final copyList = 'Kopiuj listę';
  @override
  final clearBought = 'Usuń kupione';
  @override
  final listCopied = 'Lista skopiowana';
  @override
  final addOwnItem = 'Dodaj własną pozycję';
  @override
  final shoppingHeader = 'Kupić:';
  @override
  String leftToBuy(int n) => 'Zostało do kupienia: $n';

  @override
  final goal = 'Cel';
  @override
  final goalLabels = const {Goal.any: 'Dowolne', Goal.light: 'Lekkie', Goal.protein: 'Białkowe'};
  @override
  final useSoonHint = 'Dotknij produktu, aby oznaczyć „wkrótce się zepsuje” — dania z niego będą pierwsze';
  @override
  final useSoonMark = 'wkrótce się zepsuje';
  @override
  String saves(String items) => 'Ratuje: $items';
  @override
  String macros(int p, int f, int c) => 'B $p g · T $f g · W $c g';
  @override
  final perServing = 'na porcję';
  @override
  final likeQuestion = 'Smakowało?';
  @override
  final likedThanks = 'Zapamiętane: zaproponuję podobne';
  @override
  final dislikedThanks = 'Zapamiętane: nie będę proponować podobnych';
  @override
  final weekMenu = 'Menu na tydzień';
  @override
  final planLoading = 'Układam menu na tydzień z twoich produktów. Zwykle 20–60 sekund…';
  @override
  String day(int n) => 'Dzień $n';
  @override
  final mealsPerDay = 'Posiłków dziennie';
  @override
  final mealsOptions = const {1: 'Obiad', 2: 'Śniadanie i kolacja', 3: 'Trzy posiłki'};
  @override
  final toBuyWeek = 'Dokupić na tydzień';
  @override
  String addAllToShopping(int n) => 'Dodaj wszystko do zakupów ($n)';
  @override
  final nothingToBuy = 'Nic nie trzeba dokupić';
  @override
  final makePlan = 'Ułóż menu';
  @override
  final recentScans = 'Ostatnie skany';
  @override
  String productsN(int n) {
    if (n == 1) return '1 produkt';
    final m10 = n % 10, m100 = n % 100;
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return '$n produkty';
    return '$n produktów';
  }

  @override
  String dateLabel(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days == 0) return 'dziś';
    if (days == 1) return 'wczoraj';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }

  @override
  final navHome = 'Start';
  @override
  final navSaved = 'Zapisane';
  @override
  final navShopping = 'Zakupy';

  @override
  final errNetwork = 'Brak połączenia z internetem lub serwerem.';
  @override
  final errTimeout = 'Serwer długo nie odpowiada. Spróbuj ponownie.';
  @override
  final errRateLimited = 'Za dużo zapytań. Poczekaj chwilę.';
  @override
  final errTooLarge = 'Zdjęcie jest za duże.';
  @override
  final errBadImage = 'Nie udało się odczytać zdjęcia. Spróbuj innego.';
  @override
  final errUnauthorized = 'Aplikacja nie jest autoryzowana na serwerze.';
  @override
  final errDailyLimit = 'Dzisiejszy limit wyczerpany. Spróbuj jutro. Zapisane przepisy działają jak wcześniej.';
  @override
  final errTooManyPhotos = 'Za dużo zdjęć. Można do 3 naraz.';
  @override
  final errNothing = 'Na zdjęciu nie widać produktów. Sfotografuj otwartą lodówkę lub stół z produktami.';
  @override
  final errGeneric = 'Coś poszło nie tak. Spróbuj ponownie.';
}

final supportedStrings = <String, Strings>{'uk': StringsUk(), 'pl': StringsPl()};

/// Поточна мова. Перемикання перебудовує всі екрани, що використовують L10n.of(context).
class L10n extends InheritedWidget {
  const L10n({super.key, required this.strings, required super.child});
  final Strings strings;

  static Strings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<L10n>()!.strings;

  @override
  bool updateShouldNotify(L10n oldWidget) => oldWidget.strings.code != strings.code;
}
