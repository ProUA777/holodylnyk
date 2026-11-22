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
  String get navGarden => tr('navGarden');

  // головна
  String get homeTitle => tr('homeTitle');
  String get homeSubtitle => tr('homeSubtitle');
  String get takePhoto => tr('takePhoto');
  String get takePhotoHint => tr('takePhotoHint');
  String get gallery => tr('gallery');
  String get settings => tr('settings');
  String get noCamera => tr('noCamera');
  String get language => tr('language');
  String get place => tr('place');
  String get pets => tr('pets');
  String get kids => tr('kids');
  String get done => tr('done');
  String get openGarden => tr('openGarden');
  Map<Place, String> get placeLabels => {
        Place.any: tr('placeAny'),
        Place.indoor: tr('placeIndoor'),
        Place.balcony: tr('placeBalcony'),
        Place.garden: tr('placeGarden'),
      };

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
  String get maybeItIs => tr('maybeItIs');
  String get problemsTitle => tr('problemsTitle');
  String get noProblems => tr('noProblems');
  String get todoTitle => tr('todoTitle');
  String get careTitle => tr('careTitle');
  String get careLight => tr('careLight');
  String get careWatering => tr('careWatering');
  String get careHumidity => tr('careHumidity');
  String get careTemperature => tr('careTemperature');
  String get careSoil => tr('careSoil');
  String get careFertilizer => tr('careFertilizer');
  String get careRepotting => tr('careRepotting');
  String get carePruning => tr('carePruning');
  String get toxicTitle => tr('toxicTitle');
  String get toxicPets => tr('toxicPets');
  String get toxicKids => tr('toxicKids');
  String get safeTitle => tr('safeTitle');
  String get funFact => tr('funFact');
  String get addToGarden => tr('addToGarden');
  String get addedToGarden => tr('addedToGarden');
  String get howToFix => tr('howToFix');
  String get fullPlan => tr('fullPlan');
  String get prevention => tr('prevention');
  String get askTitle => tr('askTitle');
  String get askHint => tr('askHint');
  String get ask => tr('ask');
  String get recheck => tr('recheck');
  Map<Health, String> get healthLabels => {
        Health.healthy: tr('healthy'),
        Health.needsAttention: tr('needsAttention'),
        Health.sick: tr('sick'),
      };
  Map<Severity, String> get severityLabels => {
        Severity.low: tr('sevLow'),
        Severity.medium: tr('sevMedium'),
        Severity.high: tr('sevHigh'),
      };

  // план лікування
  String get planLoading => tr('planLoading');

  // мої рослини
  String get gardenTitle => tr('gardenTitle');
  String get gardenEmpty => tr('gardenEmpty');
  String get water => tr('water');
  String get wateredToast => tr('wateredToast');
  String get waterToday => tr('waterToday');
  String get rename => tr('rename');
  String get delete => tr('delete');
  String get deleteQ => tr('deleteQ');
  String get cancel => tr('cancel');
  String get save => tr('save');
  String get changeEvery => tr('changeEvery');

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
  String confidence(double c) => '${(c * 100).round()}%';
  String everyDays(int n);
  String waterIn(int days); // 0 — сьогодні, <0 — прострочено
  String thirsty(int n);
  String plantsN(int n);
  String dateLabel(DateTime d);

  String settingsSummary(PlantParams p) => [
        placeLabels[p.place]!,
        if (p.pets) pets.toLowerCase(),
        if (p.kids) kids.toLowerCase(),
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
    'appName': 'Що з рослиною?',
    'splashTitle': 'Що з рослиною?',
    'splashTag': 'Фото рослини → діагноз і догляд',
    'splashFrom': 'ВІД',
    'navHome': 'Головна',
    'navGarden': 'Мої рослини',
    'homeTitle': 'Що з рослиною?',
    'homeSubtitle': 'Сфотографуй рослину — скажу, що це за вид, чим вона хворіє і як її доглядати.',
    'takePhoto': 'Сфотографувати',
    'takePhotoHint': 'Усю рослину, а потім листок зблизька',
    'gallery': 'Галерея',
    'settings': 'Налаштування',
    'noCamera': 'Не вдалося відкрити камеру чи галерею. Перевір дозволи в налаштуваннях телефона.',
    'language': 'Мова',
    'place': 'Де росте',
    'pets': 'Є коти чи собаки',
    'kids': 'Є малі діти',
    'done': 'Готово',
    'openGarden': 'Відкрити',
    'placeAny': 'Будь-де',
    'placeIndoor': 'У квартирі',
    'placeBalcony': 'На балконі',
    'placeGarden': 'У саду',
    'photosTitle': 'Ще фото?',
    'photosHint': 'Листок зблизька, зворот листка чи ґрунт допоможуть точніше знайти причину.',
    'addPhoto': 'Додати фото',
    'camera': 'Камера',
    'check': 'Перевірити рослину',
    'remove': 'Прибрати',
    'loadingTitle': 'Роздивляюся рослину…',
    'loadingSteps': 'Визначаю вид|Шукаю плями, шкідників, ознаки переливу|Складаю план догляду',
    'retry': 'Спробувати ще',
    'otherPhoto': 'Інше фото',
    'maybeItIs': 'Не впевнений у виді. Може, це:',
    'problemsTitle': 'Що не так',
    'noProblems': 'Помітних проблем не видно — рослина в порядку.',
    'todoTitle': 'Що зробити зараз',
    'careTitle': 'Догляд',
    'careLight': 'Світло',
    'careWatering': 'Полив',
    'careHumidity': 'Вологість',
    'careTemperature': 'Температура',
    'careSoil': 'Ґрунт',
    'careFertilizer': 'Підживлення',
    'careRepotting': 'Пересадка',
    'carePruning': 'Обрізка',
    'toxicTitle': 'Обережно: отруйна',
    'toxicPets': 'для котів і собак',
    'toxicKids': 'для дітей',
    'safeTitle': 'Не отруйна для людей і тварин',
    'funFact': 'Цікаво',
    'addToGarden': 'Додати до моїх рослин',
    'addedToGarden': 'Додано до «Мої рослини». Нагадаю, коли поливати.',
    'howToFix': 'Як виправити',
    'fullPlan': 'Покроковий план лікування',
    'prevention': 'Щоб не повторилось',
    'askTitle': 'Запитати про цю рослину',
    'askHint': 'Напр.: «Чи можна пересадити зараз?»',
    'ask': 'Запитати',
    'recheck': 'Перевірити знову по фото',
    'healthy': 'Здорова',
    'needsAttention': 'Потребує уваги',
    'sick': 'Хворіє',
    'sevLow': 'дрібниця',
    'sevMedium': 'варто зайнятись',
    'sevHigh': 'терміново',
    'planLoading': 'Складаю план лікування…',
    'gardenTitle': 'Мої рослини',
    'gardenEmpty': 'Тут з\'являться рослини, які ти додаси після перевірки. Нагадаю, коли кожну поливати.',
    'water': 'Полити',
    'wateredToast': 'Полито 💧',
    'waterToday': 'Полити сьогодні',
    'rename': 'Назва',
    'delete': 'Видалити',
    'deleteQ': 'Видалити рослину з «Мої рослини»?',
    'cancel': 'Скасувати',
    'save': 'Зберегти',
    'changeEvery': 'Як часто поливати',
    'errNetwork': 'Немає з\'єднання з інтернетом.',
    'errTimeout': 'Сервер довго не відповідає. Спробуй ще раз.',
    'errRateLimited': 'Забагато запитів. Зачекай хвилинку.',
    'errTooLarge': 'Фото завелике.',
    'errBadImage': 'Не вдалося відкрити фото. Спробуй інше.',
    'errUnauthorized': 'Апка не має доступу до сервера.',
    'errDailyLimit': 'На сьогодні ліміт перевірок вичерпано. Повертайся завтра.',
    'errTooManyPhotos': 'Можна до 3 фото за раз.',
    'errNothing': 'На фото не видно рослини. Сфотографуй рослину цілком і листок зблизька.',
    'errGeneric': 'Щось пішло не так. Спробуй ще раз.',
  };

  @override
  String maxPhotos(int n) => 'До $n фото однієї рослини';
  @override
  String everyDays(int n) => n == 1 ? 'щодня' : 'раз на $n ${_ukPlural(n, 'день', 'дні', 'днів')}';
  @override
  String waterIn(int d) => d < 0
      ? 'Полити! Прострочено на ${-d} ${_ukPlural(-d, 'день', 'дні', 'днів')}'
      : d == 0
          ? 'Полити сьогодні'
          : d == 1
              ? 'Полив завтра'
              : 'Полив через $d ${_ukPlural(d, 'день', 'дні', 'днів')}';
  @override
  String thirsty(int n) => 'Сьогодні полити: $n ${_ukPlural(n, 'рослину', 'рослини', 'рослин')}';
  @override
  String plantsN(int n) => '$n ${_ukPlural(n, 'рослина', 'рослини', 'рослин')}';
  @override
  String dateLabel(DateTime d) {
    const months = ['січ', 'лют', 'бер', 'квіт', 'трав', 'черв', 'лип', 'серп', 'вер', 'жовт', 'лист', 'груд'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class StringsPl extends Strings {
  @override
  final code = 'pl';
  @override
  final m = const {
    'languageName': 'Polski',
    'appName': 'Co z roślinką?',
    'splashTitle': 'Co z roślinką?',
    'splashTag': 'Zdjęcie rośliny → diagnoza i pielęgnacja',
    'splashFrom': 'OD',
    'navHome': 'Start',
    'navGarden': 'Moje rośliny',
    'homeTitle': 'Co z roślinką?',
    'homeSubtitle': 'Zrób zdjęcie rośliny — powiem, co to za gatunek, co jej dolega i jak o nią dbać.',
    'takePhoto': 'Zrób zdjęcie',
    'takePhotoHint': 'Całą roślinę, a potem liść z bliska',
    'gallery': 'Galeria',
    'settings': 'Ustawienia',
    'noCamera': 'Nie udało się otworzyć aparatu ani galerii. Sprawdź uprawnienia w ustawieniach telefonu.',
    'language': 'Język',
    'place': 'Gdzie rośnie',
    'pets': 'Są koty lub psy',
    'kids': 'Są małe dzieci',
    'done': 'Gotowe',
    'openGarden': 'Otwórz',
    'placeAny': 'Gdziekolwiek',
    'placeIndoor': 'W mieszkaniu',
    'placeBalcony': 'Na balkonie',
    'placeGarden': 'W ogrodzie',
    'photosTitle': 'Więcej zdjęć?',
    'photosHint': 'Liść z bliska, spód liścia albo ziemia pomogą dokładniej znaleźć przyczynę.',
    'addPhoto': 'Dodaj zdjęcie',
    'camera': 'Aparat',
    'check': 'Sprawdź roślinę',
    'remove': 'Usuń',
    'loadingTitle': 'Oglądam roślinę…',
    'loadingSteps': 'Rozpoznaję gatunek|Szukam plam, szkodników, oznak przelania|Układam plan pielęgnacji',
    'retry': 'Spróbuj ponownie',
    'otherPhoto': 'Inne zdjęcie',
    'maybeItIs': 'Nie jestem pewien gatunku. Może to:',
    'problemsTitle': 'Co jest nie tak',
    'noProblems': 'Nie widać problemów — roślina ma się dobrze.',
    'todoTitle': 'Co zrobić teraz',
    'careTitle': 'Pielęgnacja',
    'careLight': 'Światło',
    'careWatering': 'Podlewanie',
    'careHumidity': 'Wilgotność',
    'careTemperature': 'Temperatura',
    'careSoil': 'Podłoże',
    'careFertilizer': 'Nawożenie',
    'careRepotting': 'Przesadzanie',
    'carePruning': 'Przycinanie',
    'toxicTitle': 'Uwaga: trująca',
    'toxicPets': 'dla kotów i psów',
    'toxicKids': 'dla dzieci',
    'safeTitle': 'Nietrująca dla ludzi i zwierząt',
    'funFact': 'Ciekawostka',
    'addToGarden': 'Dodaj do moich roślin',
    'addedToGarden': 'Dodano do „Moje rośliny”. Przypomnę o podlewaniu.',
    'howToFix': 'Jak naprawić',
    'fullPlan': 'Plan leczenia krok po kroku',
    'prevention': 'Żeby się nie powtórzyło',
    'askTitle': 'Zapytaj o tę roślinę',
    'askHint': 'Np.: „Czy mogę ją teraz przesadzić?”',
    'ask': 'Zapytaj',
    'recheck': 'Sprawdź ponownie ze zdjęcia',
    'healthy': 'Zdrowa',
    'needsAttention': 'Wymaga uwagi',
    'sick': 'Choruje',
    'sevLow': 'drobiazg',
    'sevMedium': 'warto zadziałać',
    'sevHigh': 'pilne',
    'planLoading': 'Układam plan leczenia…',
    'gardenTitle': 'Moje rośliny',
    'gardenEmpty': 'Tu pojawią się rośliny dodane po sprawdzeniu. Przypomnę, kiedy każdą podlać.',
    'water': 'Podlej',
    'wateredToast': 'Podlane 💧',
    'waterToday': 'Podlać dziś',
    'rename': 'Nazwa',
    'delete': 'Usuń',
    'deleteQ': 'Usunąć roślinę z „Moje rośliny”?',
    'cancel': 'Anuluj',
    'save': 'Zapisz',
    'changeEvery': 'Jak często podlewać',
    'errNetwork': 'Brak połączenia z internetem.',
    'errTimeout': 'Serwer długo nie odpowiada. Spróbuj ponownie.',
    'errRateLimited': 'Za dużo zapytań. Odczekaj chwilę.',
    'errTooLarge': 'Zdjęcie jest za duże.',
    'errBadImage': 'Nie udało się otworzyć zdjęcia. Spróbuj innego.',
    'errUnauthorized': 'Aplikacja nie ma dostępu do serwera.',
    'errDailyLimit': 'Dzisiejszy limit sprawdzeń wyczerpany. Wróć jutro.',
    'errTooManyPhotos': 'Maksymalnie 3 zdjęcia naraz.',
    'errNothing': 'Na zdjęciu nie widać rośliny. Sfotografuj całą roślinę i liść z bliska.',
    'errGeneric': 'Coś poszło nie tak. Spróbuj ponownie.',
  };

  @override
  String maxPhotos(int n) => 'Do $n zdjęć jednej rośliny';
  @override
  String everyDays(int n) => n == 1 ? 'codziennie' : 'co $n ${_plPlural(n, 'dzień', 'dni', 'dni')}';
  @override
  String waterIn(int d) => d < 0
      ? 'Podlej! Spóźnione o ${-d} ${_plPlural(-d, 'dzień', 'dni', 'dni')}'
      : d == 0
          ? 'Podlać dziś'
          : d == 1
              ? 'Podlewanie jutro'
              : 'Podlewanie za $d ${_plPlural(d, 'dzień', 'dni', 'dni')}';
  @override
  String thirsty(int n) => 'Dziś podlać: $n ${_plPlural(n, 'roślinę', 'rośliny', 'roślin')}';
  @override
  String plantsN(int n) => '$n ${_plPlural(n, 'roślina', 'rośliny', 'roślin')}';
  @override
  String dateLabel(DateTime d) {
    const months = ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

final Map<String, Strings> supportedStrings = {'uk': StringsUk(), 'pl': StringsPl()};

class L10n extends InheritedWidget {
  const L10n({super.key, required this.strings, required super.child});
  final Strings strings;

  static Strings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<L10n>()!.strings;

  @override
  bool updateShouldNotify(L10n oldWidget) => oldWidget.strings.code != strings.code;
}
