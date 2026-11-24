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
  String get navHome => tr('navHome');
  String get navHistory => tr('navHistory');
  String get homeTitle => tr('homeTitle');
  String get homeSubtitle => tr('homeSubtitle');
  String get takePhoto => tr('takePhoto');
  String get takePhotoHint => tr('takePhotoHint');
  String get takePhotoCheckHint => tr('takePhotoCheckHint');
  String get gallery => tr('gallery');
  String get typeIn => tr('typeIn');
  String get settings => tr('settings');
  String get noCamera => tr('noCamera');
  String get language => tr('language');
  String get grade => tr('grade');
  String get done => tr('done');
  String get modeLearn => tr('modeLearn');
  String get modeCheck => tr('modeCheck');
  String get typeTitle => tr('typeTitle');
  String get typeHint => tr('typeHint');
  String get typeWorkHint => tr('typeWorkHint');
  String get cancel => tr('cancel');
  String get solve => tr('solve');
  String get photosTitle => tr('photosTitle');
  String get photosHint => tr('photosHint');
  String get addPhoto => tr('addPhoto');
  String get camera => tr('camera');
  String get check => tr('check');
  String get remove => tr('remove');
  String get loadingTitle => tr('loadingTitle');
  String get retry => tr('retry');
  String get otherPhoto => tr('otherPhoto');
  String get unreadable => tr('unreadable');
  String get editTask => tr('editTask');
  String get idea => tr('idea');
  String get hintsTitle => tr('hintsTitle');
  String get nextHint => tr('nextHint');
  String get showSteps => tr('showSteps');
  String get showAnswer => tr('showAnswer');
  String get answer => tr('answer');
  String get howToCheck => tr('howToCheck');
  String get similar => tr('similar');
  String get showSimilarAnswer => tr('showSimilarAnswer');
  String get topicBtn => tr('topicBtn');
  String get askStep => tr('askStep');
  String get askHint => tr('askHint');
  String get ask => tr('ask');
  String get correct => tr('correct');
  String get incorrect => tr('incorrect');
  String get praise => tr('praise');
  String get mistakes => tr('mistakes');
  String get historyTitle => tr('historyTitle');
  String get historyEmpty => tr('historyEmpty');
  String get delete => tr('delete');
  String get star => tr('star');
  String get topicLoading => tr('topicLoading');
  String get student => tr('student');
  List<String> get loadingSteps => tr('loadingSteps').split('|');
  Map<Mode, String> get modeLabels => {Mode.learn: modeLearn, Mode.check: modeCheck};

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
  String gradeLabel(int g);
  String hintN(int i, int of);
  String tasksN(int n);
  String dateLabel(DateTime d);

  String settingsSummary(HomeworkParams p) => '${gradeLabel(p.grade)}, $languageName';
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
    'appName': 'Як розв’язати?',
    'splashTitle': 'Як розв’язати?',
    'splashTag': 'Фото завдання → зрозуміло, крок за кроком',
    'splashFrom': 'ВІД',
    'navHome': 'Головна',
    'navHistory': 'Мої завдання',
    'homeTitle': 'Як розв’язати?',
    'homeSubtitle': 'Сфотографуй завдання — дам підказки й поясню по кроках, щоб ти розв’язав сам. Або перевірю твій розв’язок.',
    'takePhoto': 'Сфотографувати',
    'takePhotoHint': 'Сторінку рівно, при світлі, щоб текст було видно',
    'takePhotoCheckHint': 'Завдання разом із твоїм розв’язком у зошиті',
    'gallery': 'Галерея',
    'typeIn': 'Вписати',
    'settings': 'Налаштування',
    'noCamera': 'Не вдалося відкрити камеру чи галерею. Перевір дозволи в налаштуваннях телефона.',
    'language': 'Мова',
    'grade': 'Клас',
    'done': 'Готово',
    'modeLearn': 'Пояснити',
    'modeCheck': 'Перевірити мій розв’язок',
    'typeTitle': 'Умова завдання',
    'typeHint': 'Напр.: «Розв’яжіть рівняння 2x + 3 = 11»',
    'typeWorkHint': 'Твій розв’язок (для перевірки)',
    'cancel': 'Скасувати',
    'solve': 'Пояснити',
    'photosTitle': 'Ще фото?',
    'photosHint': 'Якщо завдання на двох сторінках чи є рисунок — додай ще фото.',
    'addPhoto': 'Додати фото',
    'camera': 'Камера',
    'check': 'Розібрати завдання',
    'remove': 'Прибрати',
    'loadingTitle': 'Читаю завдання…',
    'loadingSteps': 'Переписую умову|Шукаю, як розв’язати|Готую підказки й пояснення',
    'retry': 'Спробувати ще',
    'otherPhoto': 'Інше фото',
    'unreadable': 'Частину тексту погано видно. Перевір умову — її можна виправити.',
    'editTask': 'Виправити умову',
    'idea': '💡 Головна ідея',
    'hintsTitle': 'Підказки',
    'nextHint': 'Ще підказка',
    'showSteps': 'Показати розв’язання по кроках',
    'showAnswer': 'Показати відповідь',
    'answer': 'Відповідь',
    'howToCheck': 'Як перевірити',
    'similar': '🏋️ Спробуй сам',
    'showSimilarAnswer': 'Перевірити себе',
    'topicBtn': 'Пояснити тему',
    'askStep': 'Не розумію крок',
    'askHint': 'Напр.: «Чому знак змінився?»',
    'ask': 'Запитати',
    'correct': '✅ Правильно!',
    'incorrect': '✏️ Є помилки',
    'praise': '👍 Що вдалося',
    'mistakes': 'Де помилка',
    'historyTitle': 'Мої завдання',
    'historyEmpty': 'Тут з’являться розібрані завдання — щоб повторити перед контрольною.',
    'delete': 'Видалити',
    'star': 'Важливе',
    'topicLoading': 'Готую пояснення теми…',
    'student': 'Студент',
    'errNetwork': 'Немає з’єднання з інтернетом.',
    'errTimeout': 'Сервер довго не відповідає. Спробуй ще раз.',
    'errRateLimited': 'Забагато запитів. Зачекай хвилинку.',
    'errTooLarge': 'Фото завелике.',
    'errBadImage': 'Не вдалося відкрити фото. Спробуй інше.',
    'errUnauthorized': 'Апка не має доступу до сервера.',
    'errDailyLimit': 'На сьогодні ліміт вичерпано. Повертайся завтра.',
    'errTooManyPhotos': 'Можна до 3 фото за раз.',
    'errNothing': 'Не видно завдання. Сфотографуй сторінку рівно, при світлі.',
    'errGeneric': 'Щось пішло не так. Спробуй ще раз.',
  };

  @override
  String maxPhotos(int n) => 'До $n фото одного завдання';
  @override
  String gradeLabel(int g) => g >= 12 ? student : '$g клас';
  @override
  String hintN(int i, int of) => 'Підказка $i з $of';
  @override
  String tasksN(int n) => '$n ${_ukPlural(n, 'завдання', 'завдання', 'завдань')}';
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
    'appName': 'Jak to rozwiązać?',
    'splashTitle': 'Jak to rozwiązać?',
    'splashTag': 'Zdjęcie zadania → zrozumiale, krok po kroku',
    'splashFrom': 'OD',
    'navHome': 'Start',
    'navHistory': 'Moje zadania',
    'homeTitle': 'Jak to rozwiązać?',
    'homeSubtitle': 'Zrób zdjęcie zadania — dam wskazówki i wyjaśnię krok po kroku, żebyś rozwiązał sam. Albo sprawdzę twoje rozwiązanie.',
    'takePhoto': 'Zrób zdjęcie',
    'takePhotoHint': 'Stronę prosto, przy świetle, żeby tekst był widoczny',
    'takePhotoCheckHint': 'Zadanie razem z twoim rozwiązaniem w zeszycie',
    'gallery': 'Galeria',
    'typeIn': 'Wpisz',
    'settings': 'Ustawienia',
    'noCamera': 'Nie udało się otworzyć aparatu ani galerii. Sprawdź uprawnienia w ustawieniach telefonu.',
    'language': 'Język',
    'grade': 'Klasa',
    'done': 'Gotowe',
    'modeLearn': 'Wyjaśnij',
    'modeCheck': 'Sprawdź moje rozwiązanie',
    'typeTitle': 'Treść zadania',
    'typeHint': 'Np.: „Rozwiąż równanie 2x + 3 = 11”',
    'typeWorkHint': 'Twoje rozwiązanie (do sprawdzenia)',
    'cancel': 'Anuluj',
    'solve': 'Wyjaśnij',
    'photosTitle': 'Więcej zdjęć?',
    'photosHint': 'Jeśli zadanie jest na dwóch stronach albo ma rysunek — dodaj zdjęcie.',
    'addPhoto': 'Dodaj zdjęcie',
    'camera': 'Aparat',
    'check': 'Rozbierz zadanie',
    'remove': 'Usuń',
    'loadingTitle': 'Czytam zadanie…',
    'loadingSteps': 'Przepisuję treść|Szukam sposobu rozwiązania|Przygotowuję wskazówki i wyjaśnienie',
    'retry': 'Spróbuj ponownie',
    'otherPhoto': 'Inne zdjęcie',
    'unreadable': 'Część tekstu jest słabo widoczna. Sprawdź treść — możesz ją poprawić.',
    'editTask': 'Popraw treść',
    'idea': '💡 Główna idea',
    'hintsTitle': 'Wskazówki',
    'nextHint': 'Kolejna wskazówka',
    'showSteps': 'Pokaż rozwiązanie krok po kroku',
    'showAnswer': 'Pokaż odpowiedź',
    'answer': 'Odpowiedź',
    'howToCheck': 'Jak sprawdzić',
    'similar': '🏋️ Spróbuj sam',
    'showSimilarAnswer': 'Sprawdź się',
    'topicBtn': 'Wyjaśnij temat',
    'askStep': 'Nie rozumiem kroku',
    'askHint': 'Np.: „Dlaczego zmienił się znak?”',
    'ask': 'Zapytaj',
    'correct': '✅ Dobrze!',
    'incorrect': '✏️ Są błędy',
    'praise': '👍 Co się udało',
    'mistakes': 'Gdzie jest błąd',
    'historyTitle': 'Moje zadania',
    'historyEmpty': 'Tu pojawią się rozebrane zadania — do powtórki przed sprawdzianem.',
    'delete': 'Usuń',
    'star': 'Ważne',
    'topicLoading': 'Przygotowuję wyjaśnienie tematu…',
    'student': 'Student',
    'errNetwork': 'Brak połączenia z internetem.',
    'errTimeout': 'Serwer długo nie odpowiada. Spróbuj ponownie.',
    'errRateLimited': 'Za dużo zapytań. Odczekaj chwilę.',
    'errTooLarge': 'Zdjęcie jest za duże.',
    'errBadImage': 'Nie udało się otworzyć zdjęcia. Spróbuj innego.',
    'errUnauthorized': 'Aplikacja nie ma dostępu do serwera.',
    'errDailyLimit': 'Dzisiejszy limit wyczerpany. Wróć jutro.',
    'errTooManyPhotos': 'Maksymalnie 3 zdjęcia naraz.',
    'errNothing': 'Nie widać zadania. Sfotografuj stronę prosto, przy świetle.',
    'errGeneric': 'Coś poszło nie tak. Spróbuj ponownie.',
  };

  @override
  String maxPhotos(int n) => 'Do $n zdjęć jednego zadania';
  @override
  String gradeLabel(int g) => g >= 12 ? student : '$g klasa';
  @override
  String hintN(int i, int of) => 'Wskazówka $i z $of';
  @override
  String tasksN(int n) => '$n ${_plPlural(n, 'zadanie', 'zadania', 'zadań')}';
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
