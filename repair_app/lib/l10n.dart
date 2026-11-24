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
  String get navRepairs => tr('navRepairs');
  String get homeTitle => tr('homeTitle');
  String get homeSubtitle => tr('homeSubtitle');
  String get takePhoto => tr('takePhoto');
  String get takePhotoHint => tr('takePhotoHint');
  String get gallery => tr('gallery');
  String get describe => tr('describe');
  String get settings => tr('settings');
  String get noCamera => tr('noCamera');
  String get language => tr('language');
  String get skill => tr('skill');
  String get done => tr('done');
  String get describeTitle => tr('describeTitle');
  String get describeThing => tr('describeThing');
  String get describeSigns => tr('describeSigns');
  String get cancel => tr('cancel');
  String get photosTitle => tr('photosTitle');
  String get photosHint => tr('photosHint');
  String get addPhoto => tr('addPhoto');
  String get camera => tr('camera');
  String get check => tr('check');
  String get remove => tr('remove');
  String get loadingTitle => tr('loadingTitle');
  String get retry => tr('retry');
  String get otherPhoto => tr('otherPhoto');
  String get beforeStart => tr('beforeStart');
  String get causesTitle => tr('causesTitle');
  String get howToCheck => tr('howToCheck');
  String get howToFix => tr('howToFix');
  String get fullGuide => tr('fullGuide');
  String get toolsTitle => tr('toolsTitle');
  String get partsTitle => tr('partsTitle');
  String get proCost => tr('proCost');
  String get save => tr('save');
  String get savedToast => tr('savedToast');
  String get askTitle => tr('askTitle');
  String get askHint => tr('askHint');
  String get ask => tr('ask');
  String get guideLoading => tr('guideLoading');
  String get repairsTitle => tr('repairsTitle');
  String get repairsEmpty => tr('repairsEmpty');
  String get fixed => tr('fixed');
  String get markDone => tr('markDone');
  String get markOpen => tr('markOpen');
  String get delete => tr('delete');
  String get deleteQ => tr('deleteQ');
  String get toBuy => tr('toBuy');
  String get openRepairs => tr('openRepairs');
  List<String> get loadingSteps => tr('loadingSteps').split('|');
  Map<Skill, String> get skillLabels => {for (final v in Skill.values) v: tr('skill_${v.name}')};
  Map<Safety, String> get safetyLabels => {for (final v in Safety.values) v: tr('safety_${v.name}')};
  Map<Difficulty, String> get difficultyLabels => {for (final v in Difficulty.values) v: tr('diff_${v.name}')};

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
  String likely(double p) => '${(p * 100).round()}%';
  String minutes(int n) => n >= 90 ? '~${(n / 60).round()} год' : '~$n хв';
  String inWork(int n);

  String settingsSummary(RepairParams p) => '${skillLabels[p.skill]}, $languageName';
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
    'appName': 'Що зламалось?',
    'splashTitle': 'Що зламалось?',
    'splashTag': 'Фото поломки → як полагодити',
    'splashFrom': 'ВІД',
    'navHome': 'Головна',
    'navRepairs': 'Мої ремонти',
    'homeTitle': 'Що зламалось?',
    'homeSubtitle': 'Сфотографуй поломку — скажу, що сталося, чи безпечно лагодити самому, які кроки, інструменти й деталі.',
    'takePhoto': 'Сфотографувати',
    'takePhotoHint': 'Річ цілком, потім поломку зблизька, табличку з моделлю',
    'gallery': 'Галерея',
    'describe': 'Описати словами',
    'settings': 'Налаштування',
    'noCamera': 'Не вдалося відкрити камеру чи галерею. Перевір дозволи в налаштуваннях телефона.',
    'language': 'Мова',
    'skill': 'Досвід',
    'done': 'Готово',
    'describeTitle': 'Що зламалось?',
    'describeThing': 'Що це: «пральна машина Bosch», «кран у ванній»',
    'describeSigns': 'Що не так: «не зливає воду, на дисплеї E21»',
    'cancel': 'Скасувати',
    'photosTitle': 'Ще фото?',
    'photosHint': 'Поломка зблизька й табличка з моделлю допоможуть точніше знайти причину й деталь.',
    'addPhoto': 'Додати фото',
    'camera': 'Камера',
    'check': 'Знайти причину',
    'remove': 'Прибрати',
    'loadingTitle': 'Роздивляюся поломку…',
    'loadingSteps': 'Визначаю, що це за річ|Шукаю ознаки поломки|Складаю план ремонту',
    'retry': 'Спробувати ще',
    'otherPhoto': 'Інше фото',
    'beforeStart': 'Перед початком',
    'causesTitle': 'Ймовірні причини',
    'howToCheck': 'Як перевірити',
    'howToFix': 'Як полагодити',
    'fullGuide': 'Покрокова інструкція',
    'toolsTitle': 'Інструменти',
    'partsTitle': 'Деталі',
    'proCost': 'Майстер візьме орієнтовно',
    'save': 'Зберегти в «Мої ремонти»',
    'savedToast': 'Збережено в «Мої ремонти»',
    'askTitle': 'Запитати майстра',
    'askHint': 'Напр.: «Яку деталь брати і де?»',
    'ask': 'Запитати',
    'guideLoading': 'Пишу інструкцію…',
    'repairsTitle': 'Мої ремонти',
    'repairsEmpty': 'Тут з’являться ремонти, які ти збережеш. Відмічай, що вже купив, і що вже полагоджено.',
    'fixed': 'Полагоджено',
    'markDone': 'Полагоджено ✓',
    'markOpen': 'Повернути в роботу',
    'delete': 'Видалити',
    'deleteQ': 'Видалити цей ремонт?',
    'toBuy': 'Що потрібно',
    'openRepairs': 'Відкрити',
    'skill_beginner': 'Новачок',
    'skill_handy': 'Щось лагодив',
    'skill_pro': 'Майстер',
    'safety_diy': 'Можна самому',
    'safety_careful': 'Самому, але обережно',
    'safety_pro': 'Краще майстер',
    'diff_easy': 'легко',
    'diff_medium': 'середньо',
    'diff_hard': 'складно',
    'errNetwork': 'Немає з’єднання з інтернетом.',
    'errTimeout': 'Сервер довго не відповідає. Спробуй ще раз.',
    'errRateLimited': 'Забагато запитів. Зачекай хвилинку.',
    'errTooLarge': 'Фото завелике.',
    'errBadImage': 'Не вдалося відкрити фото. Спробуй інше.',
    'errUnauthorized': 'Апка не має доступу до сервера.',
    'errDailyLimit': 'На сьогодні ліміт вичерпано. Повертайся завтра.',
    'errTooManyPhotos': 'Можна до 3 фото за раз.',
    'errNothing': 'Не видно, що зламалось. Сфотографуй річ цілком і поломку зблизька.',
    'errGeneric': 'Щось пішло не так. Спробуй ще раз.',
  };

  @override
  String maxPhotos(int n) => 'До $n фото однієї поломки';
  @override
  String inWork(int n) => 'В роботі: $n ${_ukPlural(n, 'ремонт', 'ремонти', 'ремонтів')}';
}

class StringsPl extends Strings {
  @override
  final code = 'pl';
  @override
  final m = const {
    'languageName': 'Polski',
    'appName': 'Co się zepsuło?',
    'splashTitle': 'Co się zepsuło?',
    'splashTag': 'Zdjęcie usterki → jak naprawić',
    'splashFrom': 'OD',
    'navHome': 'Start',
    'navRepairs': 'Moje naprawy',
    'homeTitle': 'Co się zepsuło?',
    'homeSubtitle': 'Zrób zdjęcie usterki — powiem, co się stało, czy można naprawić samemu, jakie kroki, narzędzia i części.',
    'takePhoto': 'Zrób zdjęcie',
    'takePhotoHint': 'Całą rzecz, potem usterkę z bliska i tabliczkę z modelem',
    'gallery': 'Galeria',
    'describe': 'Opisz słowami',
    'settings': 'Ustawienia',
    'noCamera': 'Nie udało się otworzyć aparatu ani galerii. Sprawdź uprawnienia w ustawieniach telefonu.',
    'language': 'Język',
    'skill': 'Doświadczenie',
    'done': 'Gotowe',
    'describeTitle': 'Co się zepsuło?',
    'describeThing': 'Co to: „pralka Bosch”, „kran w łazience”',
    'describeSigns': 'Co nie działa: „nie odpompowuje wody, błąd E21”',
    'cancel': 'Anuluj',
    'photosTitle': 'Więcej zdjęć?',
    'photosHint': 'Usterka z bliska i tabliczka z modelem pomogą dokładniej znaleźć przyczynę i część.',
    'addPhoto': 'Dodaj zdjęcie',
    'camera': 'Aparat',
    'check': 'Znajdź przyczynę',
    'remove': 'Usuń',
    'loadingTitle': 'Oglądam usterkę…',
    'loadingSteps': 'Rozpoznaję, co to za rzecz|Szukam oznak usterki|Układam plan naprawy',
    'retry': 'Spróbuj ponownie',
    'otherPhoto': 'Inne zdjęcie',
    'beforeStart': 'Zanim zaczniesz',
    'causesTitle': 'Prawdopodobne przyczyny',
    'howToCheck': 'Jak sprawdzić',
    'howToFix': 'Jak naprawić',
    'fullGuide': 'Instrukcja krok po kroku',
    'toolsTitle': 'Narzędzia',
    'partsTitle': 'Części',
    'proCost': 'Fachowiec weźmie około',
    'save': 'Zapisz w „Moje naprawy”',
    'savedToast': 'Zapisano w „Moje naprawy”',
    'askTitle': 'Zapytaj fachowca',
    'askHint': 'Np.: „Jaką część kupić i gdzie?”',
    'ask': 'Zapytaj',
    'guideLoading': 'Piszę instrukcję…',
    'repairsTitle': 'Moje naprawy',
    'repairsEmpty': 'Tu pojawią się zapisane naprawy. Zaznaczaj, co już kupiłeś i co jest naprawione.',
    'fixed': 'Naprawione',
    'markDone': 'Naprawione ✓',
    'markOpen': 'Przywróć do pracy',
    'delete': 'Usuń',
    'deleteQ': 'Usunąć tę naprawę?',
    'toBuy': 'Co potrzebne',
    'openRepairs': 'Otwórz',
    'skill_beginner': 'Początkujący',
    'skill_handy': 'Coś już naprawiałem',
    'skill_pro': 'Fachowiec',
    'safety_diy': 'Można samemu',
    'safety_careful': 'Samemu, ale ostrożnie',
    'safety_pro': 'Lepiej fachowiec',
    'diff_easy': 'łatwe',
    'diff_medium': 'średnie',
    'diff_hard': 'trudne',
    'errNetwork': 'Brak połączenia z internetem.',
    'errTimeout': 'Serwer długo nie odpowiada. Spróbuj ponownie.',
    'errRateLimited': 'Za dużo zapytań. Odczekaj chwilę.',
    'errTooLarge': 'Zdjęcie jest za duże.',
    'errBadImage': 'Nie udało się otworzyć zdjęcia. Spróbuj innego.',
    'errUnauthorized': 'Aplikacja nie ma dostępu do serwera.',
    'errDailyLimit': 'Dzisiejszy limit wyczerpany. Wróć jutro.',
    'errTooManyPhotos': 'Maksymalnie 3 zdjęcia naraz.',
    'errNothing': 'Nie widać, co się zepsuło. Sfotografuj całą rzecz i usterkę z bliska.',
    'errGeneric': 'Coś poszło nie tak. Spróbuj ponownie.',
  };

  @override
  String maxPhotos(int n) => 'Do $n zdjęć jednej usterki';
  @override
  String minutes(int n) => n >= 90 ? '~${(n / 60).round()} godz.' : '~$n min';
  @override
  String inWork(int n) => 'W trakcie: $n ${_plPlural(n, 'naprawa', 'naprawy', 'napraw')}';
}

final Map<String, Strings> supportedStrings = {'uk': StringsUk(), 'pl': StringsPl()};

class L10n extends InheritedWidget {
  const L10n({super.key, required this.strings, required super.child});
  final Strings strings;

  static Strings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<L10n>()!.strings;

  @override
  bool updateShouldNotify(L10n oldWidget) => oldWidget.strings.code != strings.code;
}
