import 'package:flutter/widgets.dart';

import 'api.dart';
import 'models.dart';

/// Усі тексти апки двома мовами. Прості тексти — у словнику [m] кожної мови,
/// тексти з числами (відмінки) — методами. Використання: final t = L10n.of(context); Text(t.takePhoto)
abstract class Strings {
  Map<String, String> get m;
  String get code;

  String tr(String k) => m[k] ?? k;

  String get languageName => tr('languageName');
  String get appName => tr('appName');
  String get splashTitle => tr('splashTitle');
  String get splashTag => tr('splashTag');
  String get splashFrom => tr('splashFrom');

  // навігація
  String get navHome => tr('navHome');
  String get navWardrobe => tr('navWardrobe');
  String get navLooks => tr('navLooks');

  // головна
  String get homeTitle => tr('homeTitle');
  String get homeSubtitle => tr('homeSubtitle');
  String get takePhoto => tr('takePhoto');
  String get takePhotoHint => tr('takePhotoHint');
  String get gallery => tr('gallery');
  String get settings => tr('settings');
  String get noCamera => tr('noCamera');
  String get language => tr('language');
  String get styleFor => tr('styleFor');
  String get occasion => tr('occasion');
  String get weather => tr('weather');
  String get done => tr('done');
  String get fromWardrobe => tr('fromWardrobe');
  Map<StyleFor, String> get styleLabels =>
      {StyleFor.any: tr('styleAny'), StyleFor.women: tr('styleWomen'), StyleFor.men: tr('styleMen')};
  Map<Occasion, String> get occasionLabels => {for (final o in Occasion.values) o: tr('occ_${o.name}')};
  Map<Weather, String> get weatherLabels => {for (final w in Weather.values) w: tr('w_${w.name}')};
  Map<Kind, String> get kindLabels => {for (final k in Kind.values) k: tr('k_${k.name}')};

  // фото
  String get photosTitle => tr('photosTitle');
  String get photosHint => tr('photosHint');
  String get addPhoto => tr('addPhoto');
  String get camera => tr('camera');
  String get check => tr('check');
  String get remove => tr('remove');

  // результат
  String get loadingTitle => tr('loadingTitle');
  List<String> get loadingSteps => tr('loadingSteps').split('|');
  String get retry => tr('retry');
  String get otherPhoto => tr('otherPhoto');
  String get verdictTitle => tr('verdictTitle');
  String get good => tr('good');
  String get change => tr('change');
  String get paletteTitle => tr('paletteTitle');
  String get itemsTitle => tr('itemsTitle');
  String get looksTitle => tr('looksTitle');
  String get addMissing => tr('addMissing');
  String get moreLooks => tr('moreLooks');
  String get shoppingTitle => tr('shoppingTitle');
  String get addToWardrobe => tr('addToWardrobe');
  String get inWardrobe => tr('inWardrobe');
  String get savedLook => tr('savedLook');
  String get askTitle => tr('askTitle');
  String get askHint => tr('askHint');
  String get ask => tr('ask');

  // гардероб і образи
  String get wardrobeTitle => tr('wardrobeTitle');
  String get wardrobeEmpty => tr('wardrobeEmpty');
  String get pickLooks => tr('pickLooks');
  String get addItem => tr('addItem');
  String get itemName => tr('itemName');
  String get cancel => tr('cancel');
  String get save => tr('save');
  String get looksSavedTitle => tr('looksSavedTitle');
  String get looksEmpty => tr('looksEmpty');

  // помилки
  String get errNetwork => tr('errNetwork');
  String get errTimeout => tr('errTimeout');
  String get errRateLimited => tr('errRateLimited');
  String get errTooLarge => tr('errTooLarge');
  String get errBadImage => tr('errBadImage');
  String get errUnauthorized => tr('errUnauthorized');
  String get errDailyLimit => tr('errDailyLimit');
  String get errTooManyPhotos => tr('errTooManyPhotos');
  String get errNothing => tr('errNothing');
  String get errGeneric => tr('errGeneric');

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

  // з числами
  String maxPhotos(int n);
  String itemsN(int n);
  String addedN(int n);
  String score(int n) => '$n/10';

  String settingsSummary(OutfitParams p) => [
        occasionLabels[p.occasion]!,
        if (p.weather != Weather.any) weatherLabels[p.weather]!.toLowerCase(),
        if (p.styleFor != StyleFor.any) styleLabels[p.styleFor]!.toLowerCase(),
        languageName,
      ].join(', ');
}

/// Українські відмінки: 1 день, 2 дні, 5 днів
String _ukPlural(int n, String one, String few, String many) {
  final a = n.abs() % 100, b = a % 10;
  if (a >= 11 && a <= 14) return many;
  if (b == 1) return one;
  if (b >= 2 && b <= 4) return few;
  return many;
}

/// Польські: 1 dzień, 2 dni, 5 dni
String _plPlural(int n, String one, String few, String many) {
  if (n.abs() == 1) return one;
  final a = n.abs() % 100, b = a % 10;
  if (b >= 2 && b <= 4 && !(a >= 12 && a <= 14)) return few;
  return many;
}

class StringsUk extends Strings {
  @override
  final code = 'uk';
  @override
  final m = const {
    'languageName': 'Українська',
    'appName': 'Що вдягнути?',
    'splashTitle': 'Що вдягнути?',
    'splashTag': 'Фото одягу → готові образи',
    'splashFrom': 'ВІД',
    'navHome': 'Головна',
    'navWardrobe': 'Гардероб',
    'navLooks': 'Образи',
    'homeTitle': 'Що вдягнути?',
    'homeSubtitle': 'Сфотографуй шафу чи речі на ліжку — складу образи з того, що є. Або сфотографуй себе в образі — оціню й підкажу, що змінити.',
    'takePhoto': 'Сфотографувати',
    'takePhotoHint': 'Речі на ліжку, полицю шафи або себе в дзеркалі',
    'gallery': 'Галерея',
    'settings': 'Налаштування',
    'noCamera': 'Не вдалося відкрити камеру чи галерею. Перевір дозволи в налаштуваннях телефона.',
    'language': 'Мова',
    'styleFor': 'Образи',
    'occasion': 'Куди',
    'weather': 'Погода',
    'done': 'Готово',
    'fromWardrobe': 'Підібрати з мого гардероба',
    'styleAny': 'Будь-які',
    'styleWomen': 'Жіночі',
    'styleMen': 'Чоловічі',
    'occ_any': 'Будь-куди',
    'occ_casual': 'На щодень',
    'occ_work': 'На роботу',
    'occ_date': 'Побачення',
    'occ_party': 'Вечірка',
    'occ_sport': 'Активний день',
    'occ_formal': 'Урочисто',
    'occ_travel': 'У дорогу',
    'w_any': 'Будь-яка',
    'w_hot': 'Спека',
    'w_warm': 'Тепло',
    'w_cool': 'Прохолодно',
    'w_cold': 'Холодно',
    'w_rain': 'Дощ',
    'k_top': 'Верх',
    'k_bottom': 'Низ',
    'k_dress': 'Сукні й комбінезони',
    'k_outer': 'Верхній одяг',
    'k_shoes': 'Взуття',
    'k_accessory': 'Аксесуари',
    'k_bag': 'Сумки',
    'photosTitle': 'Ще фото?',
    'photosHint': 'Додай іншу полицю, взуття чи верхній одяг — образи будуть повніші.',
    'addPhoto': 'Додати фото',
    'camera': 'Камера',
    'check': 'Підібрати образи',
    'remove': 'Прибрати',
    'loadingTitle': 'Роздивляюся речі…',
    'loadingSteps': 'Шукаю речі на фото|Поєдную кольори й фасони|Складаю образи',
    'retry': 'Спробувати ще',
    'otherPhoto': 'Інше фото',
    'verdictTitle': 'Оцінка образу',
    'good': 'Що вдалося',
    'change': 'Що змінити',
    'paletteTitle': 'Твоя палітра',
    'itemsTitle': 'Речі на фото',
    'looksTitle': 'Образи',
    'addMissing': 'Додати',
    'moreLooks': 'Ще образи',
    'shoppingTitle': 'Що докупити, щоб образів стало більше',
    'addToWardrobe': 'Додати речі до гардероба',
    'inWardrobe': 'Усі речі вже в гардеробі',
    'savedLook': 'Образ збережено ♥',
    'askTitle': 'Запитати стиліста',
    'askHint': 'Напр.: «Чи пасує бежевий тренч до чорних джинсів?»',
    'ask': 'Запитати',
    'wardrobeTitle': 'Мій гардероб',
    'wardrobeEmpty': 'Тут з’являться речі з твоїх фото. Додай їх після підбору образів — і зможеш складати образи без нового фото.',
    'pickLooks': 'Підібрати образи',
    'addItem': 'Додати річ',
    'itemName': 'Напр.: «сірий светр оверсайз»',
    'cancel': 'Скасувати',
    'save': 'Зберегти',
    'looksSavedTitle': 'Збережені образи',
    'looksEmpty': 'Натисни ♥ на образі, щоб зберегти його тут.',
    'errNetwork': 'Немає з’єднання з інтернетом.',
    'errTimeout': 'Сервер довго не відповідає. Спробуй ще раз.',
    'errRateLimited': 'Забагато запитів. Зачекай хвилинку.',
    'errTooLarge': 'Фото завелике.',
    'errBadImage': 'Не вдалося відкрити фото. Спробуй інше.',
    'errUnauthorized': 'Апка не має доступу до сервера.',
    'errDailyLimit': 'На сьогодні ліміт вичерпано. Повертайся завтра.',
    'errTooManyPhotos': 'Можна до 3 фото за раз.',
    'errNothing': 'На фото не видно одягу. Розклади речі на ліжку або відкрий шафу.',
    'errGeneric': 'Щось пішло не так. Спробуй ще раз.',
  };

  @override
  String maxPhotos(int n) => 'До $n фото за раз';
  @override
  String itemsN(int n) => '$n ${_ukPlural(n, 'річ', 'речі', 'речей')}';
  @override
  String addedN(int n) => n == 0 ? inWardrobe : 'Додано до гардероба: $n ${_ukPlural(n, 'річ', 'речі', 'речей')}';
}

class StringsPl extends Strings {
  @override
  final code = 'pl';
  @override
  final m = const {
    'languageName': 'Polski',
    'appName': 'Co założyć?',
    'splashTitle': 'Co założyć?',
    'splashTag': 'Zdjęcie ubrań → gotowe stylizacje',
    'splashFrom': 'OD',
    'navHome': 'Start',
    'navWardrobe': 'Szafa',
    'navLooks': 'Stylizacje',
    'homeTitle': 'Co założyć?',
    'homeSubtitle': 'Zrób zdjęcie szafy albo ubrań na łóżku — ułożę stylizacje z tego, co masz. Albo zrób zdjęcie siebie — ocenię i podpowiem, co zmienić.',
    'takePhoto': 'Zrób zdjęcie',
    'takePhotoHint': 'Ubrania na łóżku, półkę w szafie albo siebie w lustrze',
    'gallery': 'Galeria',
    'settings': 'Ustawienia',
    'noCamera': 'Nie udało się otworzyć aparatu ani galerii. Sprawdź uprawnienia w ustawieniach telefonu.',
    'language': 'Język',
    'styleFor': 'Stylizacje',
    'occasion': 'Dokąd',
    'weather': 'Pogoda',
    'done': 'Gotowe',
    'fromWardrobe': 'Dobierz z mojej szafy',
    'styleAny': 'Dowolne',
    'styleWomen': 'Damskie',
    'styleMen': 'Męskie',
    'occ_any': 'Dokądkolwiek',
    'occ_casual': 'Na co dzień',
    'occ_work': 'Do pracy',
    'occ_date': 'Randka',
    'occ_party': 'Impreza',
    'occ_sport': 'Aktywny dzień',
    'occ_formal': 'Uroczyście',
    'occ_travel': 'W podróż',
    'w_any': 'Dowolna',
    'w_hot': 'Upał',
    'w_warm': 'Ciepło',
    'w_cool': 'Chłodno',
    'w_cold': 'Zimno',
    'w_rain': 'Deszcz',
    'k_top': 'Góra',
    'k_bottom': 'Dół',
    'k_dress': 'Sukienki i kombinezony',
    'k_outer': 'Okrycia wierzchnie',
    'k_shoes': 'Buty',
    'k_accessory': 'Dodatki',
    'k_bag': 'Torebki',
    'photosTitle': 'Więcej zdjęć?',
    'photosHint': 'Dodaj inną półkę, buty albo kurtki — stylizacje będą pełniejsze.',
    'addPhoto': 'Dodaj zdjęcie',
    'camera': 'Aparat',
    'check': 'Dobierz stylizacje',
    'remove': 'Usuń',
    'loadingTitle': 'Oglądam ubrania…',
    'loadingSteps': 'Szukam ubrań na zdjęciu|Łączę kolory i fasony|Układam stylizacje',
    'retry': 'Spróbuj ponownie',
    'otherPhoto': 'Inne zdjęcie',
    'verdictTitle': 'Ocena stylizacji',
    'good': 'Co się udało',
    'change': 'Co zmienić',
    'paletteTitle': 'Twoja paleta',
    'itemsTitle': 'Ubrania na zdjęciu',
    'looksTitle': 'Stylizacje',
    'addMissing': 'Dodaj',
    'moreLooks': 'Więcej stylizacji',
    'shoppingTitle': 'Co dokupić, żeby stylizacji było więcej',
    'addToWardrobe': 'Dodaj ubrania do szafy',
    'inWardrobe': 'Wszystkie ubrania są już w szafie',
    'savedLook': 'Stylizacja zapisana ♥',
    'askTitle': 'Zapytaj stylistę',
    'askHint': 'Np.: „Czy beżowy trencz pasuje do czarnych jeansów?”',
    'ask': 'Zapytaj',
    'wardrobeTitle': 'Moja szafa',
    'wardrobeEmpty': 'Tu pojawią się ubrania z twoich zdjęć. Dodaj je po doborze stylizacji — i układaj stylizacje bez nowego zdjęcia.',
    'pickLooks': 'Dobierz stylizacje',
    'addItem': 'Dodaj ubranie',
    'itemName': 'Np.: „szary sweter oversize”',
    'cancel': 'Anuluj',
    'save': 'Zapisz',
    'looksSavedTitle': 'Zapisane stylizacje',
    'looksEmpty': 'Naciśnij ♥ przy stylizacji, aby ją tu zapisać.',
    'errNetwork': 'Brak połączenia z internetem.',
    'errTimeout': 'Serwer długo nie odpowiada. Spróbuj ponownie.',
    'errRateLimited': 'Za dużo zapytań. Odczekaj chwilę.',
    'errTooLarge': 'Zdjęcie jest za duże.',
    'errBadImage': 'Nie udało się otworzyć zdjęcia. Spróbuj innego.',
    'errUnauthorized': 'Aplikacja nie ma dostępu do serwera.',
    'errDailyLimit': 'Dzisiejszy limit wyczerpany. Wróć jutro.',
    'errTooManyPhotos': 'Maksymalnie 3 zdjęcia naraz.',
    'errNothing': 'Na zdjęciu nie widać ubrań. Rozłóż je na łóżku albo otwórz szafę.',
    'errGeneric': 'Coś poszło nie tak. Spróbuj ponownie.',
  };

  @override
  String maxPhotos(int n) => 'Do $n zdjęć naraz';
  @override
  String itemsN(int n) => '$n ${_plPlural(n, 'rzecz', 'rzeczy', 'rzeczy')}';
  @override
  String addedN(int n) => n == 0 ? inWardrobe : 'Dodano do szafy: $n ${_plPlural(n, 'rzecz', 'rzeczy', 'rzeczy')}';
}

final Map<String, Strings> supportedStrings = {'uk': StringsUk(), 'pl': StringsPl()};

class L10n extends InheritedWidget {
  const L10n({super.key, required this.strings, required super.child});
  final Strings strings;

  static Strings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<L10n>()!.strings;

  @override
  bool updateShouldNotify(L10n oldWidget) => oldWidget.strings.code != strings.code;
}
