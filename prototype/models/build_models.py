"""Генератор каталогу моделей для «Що зібрати?».

Кожна модель описана пошарово, як піксель-арт (вид згори):
  колонки = x (праворуч — «перед»), рядки = y (нижній рядок — «перед»),
  «B|» — шар цеглинок (висота 1), «P|» — шар пластин (висота 0.4), «.» — порожньо.
Генератор розбиває кожен шар на стандартні деталі (2×4, 2×3, 2×2, 1×6, 1×4 …),
рахує висоту шарів і пише JSON, який вставляється у prototype/index.html.

Запуск:  python3 build_models.py   (перезаписує каталог у index.html)
"""
import json
import re
from pathlib import Path

PLATE = 0.4
BRICK_SIZES = [(4, 2), (2, 4), (3, 2), (2, 3), (2, 2), (8, 1), (1, 8), (6, 1), (1, 6), (4, 1), (1, 4), (3, 1), (1, 3), (2, 1), (1, 2), (1, 1)]
PLATE_SIZES = [(8, 4), (4, 8), (6, 6), (6, 4), (4, 6), (8, 2), (2, 8), (4, 4), (6, 2), (2, 6)] + BRICK_SIZES
COLORS = set("RBYWGLKONTSPDAEMVCQ")

LABELS = {
    "base": ("Основа", "Podstawa", "Base"), "wheels": ("Колеса", "Koła", "Wheels"), "chassis": ("Рама", "Rama", "Chassis"),
    "body": ("Корпус", "Korpus", "Body"), "cabin": ("Кабіна", "Kabina", "Cabin"), "roof": ("Дах", "Dach", "Roof"),
    "windows": ("Вікна", "Okna", "Windows"), "details": ("Деталі", "Detale", "Details"), "legs": ("Ноги", "Nogi", "Legs"),
    "head": ("Голова", "Głowa", "Head"), "wings": ("Крила", "Skrzydła", "Wings"), "tail": ("Хвіст", "Ogon", "Tail"),
    "walls": ("Стіни", "Ściany", "Walls"), "tower": ("Вежа", "Wieża", "Tower"), "top": ("Верхівка", "Szczyt", "Top"),
    "trunk": ("Стовбур", "Pień", "Trunk"), "crown": ("Крона", "Korona", "Treetop"), "neck": ("Шия", "Szyja", "Neck"),
    "deck": ("Палуба", "Pokład", "Deck"), "mast": ("Щогла", "Maszt", "Mast"), "sail": ("Вітрило", "Żagiel", "Sail"),
    "arms": ("Руки", "Ręce", "Arms"), "eyes": ("Очі", "Oczy", "Eyes"), "ears": ("Вуха", "Uszy", "Ears"),
    "shell": ("Панцир", "Skorupa", "Shell"), "seat": ("Сидіння", "Siedzisko", "Seat"), "back": ("Спинка", "Oparcie", "Backrest"),
    "blades": ("Лопаті", "Łopaty", "Blades"), "tracks": ("Гусениці", "Gąsienice", "Tracks"), "bun": ("Булочка", "Bułka", "Bun"),
    "filling": ("Начинка", "Nadzienie", "Filling"), "layer": ("Корж", "Biszkopt", "Sponge layer"), "cream": ("Крем", "Krem", "Cream"),
    "decor": ("Прикраси", "Ozdoby", "Decorations"), "cone": ("Ріжок", "Rożek", "Cone"), "scoop": ("Кулька", "Gałka", "Scoop"),
    "lights": ("Вогники", "Światełka", "Lights"), "star": ("Зірка", "Gwiazda", "Star"), "ribbon": ("Стрічка", "Wstążka", "Ribbon"),
    "bow": ("Бантик", "Kokarda", "Bow"), "flag": ("Прапор", "Flaga", "Flag"), "chimney": ("Димар", "Komin", "Chimney"),
    "antenna": ("Антена", "Antena", "Antenna"), "panels": ("Сонячні панелі", "Panele słoneczne", "Solar panels"),
    "horn": ("Ріг", "Róg", "Horn"), "mane": ("Грива", "Grzywa", "Mane"), "fins": ("Плавці", "Płetwy", "Fins"),
    "stem": ("Стебло", "Łodyga", "Stem"), "cap": ("Капелюшок", "Kapelusz", "Cap"), "petals": ("Пелюстки", "Płatki", "Petals"),
    "screen": ("Екран", "Ekran", "Screen"), "stand": ("Підставка", "Podstawka", "Stand"), "pillow": ("Подушки", "Poduszki", "Pillows"),
    "lamp": ("Лампа", "Lampa", "Lamp"), "rails": ("Поручні", "Poręcze", "Railings"), "pillars": ("Опори", "Filary", "Pillars"),
    "hull": ("Корпус судна", "Kadłub", "Hull"), "rotor": ("Гвинт", "Wirnik", "Rotor"), "boiler": ("Котел", "Kocioł", "Boiler"),
    "ladder": ("Драбина", "Drabina", "Ladder"), "floor": ("Поверх", "Piętro", "Floor"), "gate": ("Ворота", "Brama", "Gate"),
    "battlements": ("Зубці", "Blanki", "Battlements"), "light": ("Ліхтар", "Latarnia", "Lantern"), "dish": ("Антена-тарілка", "Antena talerzowa", "Dish"),
    "camera": ("Камера", "Kamera", "Camera"), "cannon": ("Гармати", "Działa", "Cannons"), "fire": ("Вогонь", "Ogień", "Fire"),
    "lid": ("Кришка", "Wieko", "Lid"), "coins": ("Монети", "Monety", "Coins"), "seeds": ("Кісточки", "Pestki", "Seeds"),
    "rind": ("Шкірка", "Skórka", "Rind"), "candle": ("Свічка", "Świeczka", "Candle"), "hat": ("Капелюх", "Kapelusz", "Hat"),
    "scarf": ("Шарф", "Szalik", "Scarf"), "runners": ("Полозки", "Płozy", "Runners"), "gifts": ("Подарунки", "Prezenty", "Gifts"),
    "pot": ("Вазон", "Doniczka", "Pot"), "water": ("Вода", "Woda", "Water"), "nose": ("Ніс", "Nos", "Nose"),
    "headboard": ("Узголів'я", "Wezgłowie", "Headboard"), "blanket": ("Ковдра", "Kołdra", "Blanket"), "table": ("Стільниця", "Blat", "Tabletop"),
    "spots": ("Плями", "Łaty", "Spots"), "cheese": ("Сир", "Ser", "Cheese"), "belly": ("Животик", "Brzuszek", "Belly"), "feet": ("Лапки", "Łapki", "Feet"),
}

MODELS = []


def M(id_, cat, emoji, diff, minutes, title, desc, steps):
    MODELS.append(dict(id=id_, cat=cat, emoji=emoji, diff=diff, min=minutes, t=title, d=desc, steps=steps))


def tr(uk, pl, en):
    return {"uk": uk, "pl": pl, "en": en}


# ───────────────────────── TRANSPORT ─────────────────────────
M("car", "transport", "🏎️", "easy", 10, tr("Гоночна машинка", "Wyścigówka", "Race car"),
  tr("Червона машинка з фарами, склом і спойлером.", "Czerwona wyścigówka z reflektorami, szybą i spojlerem.", "A red race car with headlights, a windscreen and a spoiler."),
  [("wheels", "B|.K..K./....../....../.K..K."), ("chassis", "P|KKKKKK/KKKKKK/KKKKKK/KKKKKK"),
   ("body", "B|RRRRRY/RRRRRR/RRRRRR/RRRRRY"), ("cabin", "B|K...../K.RRT./K.RRT./K....."), ("roof", "P|....../..RR../..RR../......")])
M("truck", "transport", "🚚", "medium", 25, tr("Вантажівка", "Ciężarówka", "Delivery truck"),
  tr("Синя кабіна, великий жовтий кузов і помаранчеві фари.", "Niebieska kabina, duża żółta skrzynia i pomarańczowe reflektory.", "A blue cab, a big yellow cargo box and orange headlights."),
  [("wheels", "B|.K...K.K./........./........./.K...K.K."), ("chassis", "P|KKKKKKKKK/KKKKKKKKK/KKKKKKKKK/KKKKKKKKK"),
   ("body", "B|YYYYYYBBO/YYYYYYBBB/YYYYYYBBB/YYYYYYBBO"), ("cabin", "B|YYYYYYBT./YYYYYYBT./YYYYYYBT./YYYYYYBT."),
   ("roof", "P|YYYYYYBB./YYYYYYBB./YYYYYYBB./YYYYYYBB.")])
M("bus", "transport", "🚌", "medium", 25, tr("Шкільний автобус", "Autobus szkolny", "School bus"),
  tr("Довгий жовтий автобус з рядом вікон і білим дахом.", "Długi żółty autobus z rzędem okien i białym dachem.", "A long yellow bus with a row of windows and a white roof."),
  [("wheels", "B|.K....K./......../......../.K....K."), ("chassis", "P|QQQQQQQQ/QQQQQQQQ/QQQQQQQQ/QQQQQQQQ"),
   ("body", "B|YYYYYYYW/YYYYYYYY/YYYYYYYY/YYYYYYYW"), ("windows", "B|YTTYTTYT/YYYYYYYT/YYYYYYYT/YTTYTTYT"),
   ("roof", "P|WWWWWWWW/WWWWWWWW/WWWWWWWW/WWWWWWWW")])
M("firetruck", "transport", "🚒", "hard", 35, tr("Пожежна машина", "Wóz strażacki", "Fire engine"),
  tr("Червона пожежна машина з драбиною та мигалками.", "Czerwony wóz strażacki z drabiną i kogutami.", "A red fire engine with a ladder and flashing lights."),
  [("wheels", "B|.K...K.K./........./........./.K...K.K."), ("chassis", "P|KKKKKKKKK/KKKKKKKKK/KKKKKKKKK/KKKKKKKKK"),
   ("body", "B|RRRRRRRRW/RRRRRRRRR/RRRRRRRRR/RRRRRRRRW"), ("cabin", "B|RRRRRRRT./RRRRRRRT./RRRRRRRT./RRRRRRRT."),
   ("ladder", "P|........./SSSSSSR../SSSSSSB../.........")])
M("plane", "transport", "✈️", "medium", 20, tr("Літак", "Samolot", "Airplane"),
  tr("Білий літак з широкими крилами й червоним носом.", "Biały samolot z szerokimi skrzydłami i czerwonym nosem.", "A white plane with wide wings and a red nose."),
  [("body", "B|......../......../WWWWWWWR/WWWWWWWR/......../........"),
   ("wings", "P|...RR.../...WW.../...WW.../...WW.../...WW.../...RR..."),
   ("cabin", "B|......../......../BWWWWWT./BWWWWWT./......../........"),
   ("tail", "B|......../......../B......./B......./......../........")])
M("heli", "transport", "🚁", "medium", 20, tr("Гелікоптер", "Helikopter", "Helicopter"),
  tr("Синій гелікоптер на полозках з великим гвинтом.", "Niebieski helikopter na płozach z dużym wirnikiem.", "A blue helicopter on skids with a big rotor."),
  [("runners", "P|..KKKK./......./......./..KKKK."), ("legs", "B|..K..K./......./......./..K..K."),
   ("body", "B|..BBBBT/BBBBBBT/BBBBBBT/..BBBBT"), ("tail", "B|..BBBT./R.BBBT./R.BBBT./..BBBT."),
   ("rotor", "B|......./...K.../......./.......", "P|...K.../KKKKKKK/...K.../...K...")])
M("boat", "transport", "⛵", "medium", 20, tr("Вітрильник", "Żaglówka", "Sailboat"),
  tr("Дерев'яний човен з каютою, щоглою і білим вітрилом.", "Drewniana łódka z kajutą, masztem i białym żaglem.", "A wooden boat with a cabin, a mast and a white sail."),
  [("hull", "B|.NNNNN./NNNNNNN/NNNNNNN/.NNNNN."), ("deck", "P|.EEEEE./EEEEEEE/EEEEEEE/.EEEEE."),
   ("cabin", "B|......./...N.../.WW..../......."), ("sail", "B|......./...NWW./......./.......", "B|......./...NWW./......./......."),
   ("flag", "B|......./...NW../......./.......", "P|......./...R.../......./.......")])
M("train", "transport", "🚂", "hard", 30, tr("Паровоз", "Lokomotywa", "Steam engine"),
  tr("Паровоз з котлом, кабіною машиніста і трубою.", "Lokomotywa z kotłem, kabiną maszynisty i kominem.", "A steam engine with a boiler, a driver's cab and a funnel."),
  [("wheels", "B|.K.K.K.K/......../......../.K.K.K.K"), ("chassis", "P|KKKKKKKK/KKKKKKKK/KKKKKKKK/KKKKKKKK"),
   ("body", "B|RRRAAAAQ/RRRAAAAQ/RRRAAAAQ/RRRAAAAQ"), ("boiler", "B|RRR...../RRRAAAA./RRRAAAA./RTR....."),
   ("cabin", "B|RRR...../RRR...K./RRR...../RTR....."), ("roof", "P|KKKK..../KKKK..K./KKKK..../KKKK....")])
M("tractor", "transport", "🚜", "medium", 22, tr("Трактор", "Traktor", "Tractor"),
  tr("Зелений трактор з великими задніми колесами.", "Zielony traktor z dużymi tylnymi kołami.", "A green tractor with big rear wheels."),
  [("wheels", "B|.KK..K./......./......./.KK..K."), ("body", "B|.KKGGGG/GGGGGGG/GGGGGGG/.KKGGGG"),
   ("cabin", "B|.GGG.../.GGGGGO/.GGGGGO/.TTT..."), ("windows", "B|.GGG.../.T.T..K/.T.T.../.GGG..."),
   ("roof", "P|.YYY.../.YYY.../.YYY.../.YYY...")])

# ───────────────────────── ANIMALS ─────────────────────────
M("duck", "animals", "🐤", "easy", 8, tr("Каченя", "Kaczuszka", "Duckling"),
  tr("Жовте каченя з помаранчевим дзьобиком.", "Żółta kaczuszka z pomarańczowym dziobem.", "A yellow duckling with an orange beak."),
  [("body", "B|YYYY./YYYY.", "B|YYYY./YYYY."), ("head", "B|Y.YYO/Y.YYO"), ("eyes", "P|..YK./..YK.")])
M("dog", "animals", "🐶", "medium", 15, tr("Цуценя", "Szczeniak", "Puppy"),
  tr("Коричневе цуценя з чорним носиком і вушками.", "Brązowy szczeniak z czarnym noskiem i uszami.", "A brown puppy with a black nose and ears."),
  [("legs", "B|N..N../N..N.."), ("body", "B|NNNN../NNNN.."), ("head", "B|N..NNK/...NNK"), ("ears", "B|...K../...K..")])
M("cat", "animals", "🐱", "easy", 10, tr("Рудий кіт", "Rudy kot", "Ginger cat"),
  tr("Рудий кіт сидить і дивиться на тебе.", "Rudy kot siedzi i patrzy na ciebie.", "A ginger cat sitting and looking at you."),
  [("body", "B|OOOO/OOOO/OOOO"), ("belly", "B|.OO./.OO./.WW."), ("head", "B|OOOO/OOOO/OKKO"), ("ears", "B|O..O/..../....")])
M("giraffe", "animals", "🦒", "medium", 18, tr("Жирафа", "Żyrafa", "Giraffe"),
  tr("Висока жирафа з плямами й довгою шиєю.", "Wysoka żyrafa w łaty z długą szyją.", "A tall spotted giraffe with a long neck."),
  [("legs", "B|Y..Y./Y..Y.", "B|Y..Y./Y..Y."), ("spots", "B|YNYN./NYNY."), ("neck", "B|...Y./...Y.", "B|...N./...N.", "B|...Y./...Y."),
   ("head", "B|...YY/...YY", "P|...K./...K.")])
M("penguin", "animals", "🐧", "easy", 8, tr("Пінгвін", "Pingwin", "Penguin"),
  tr("Пінгвін з білим животиком і помаранчевими лапками.", "Pingwin z białym brzuszkiem i pomarańczowymi łapkami.", "A penguin with a white belly and orange feet."),
  [("feet", "P|KKK/KKK/OKO"), ("belly", "B|KKK/KKK/KWK", "B|KKK/KKK/KWK"), ("head", "B|KKK/KKK/WOW", "P|KKK/KKK/KKK")])
M("elephant", "animals", "🐘", "hard", 30, tr("Слон", "Słoń", "Elephant"),
  tr("Сірий слон з великими вухами та хоботом.", "Szary słoń z dużymi uszami i trąbą.", "A grey elephant with big ears and a trunk."),
  [("legs", "B|....../.S..S./....../.S..S./......", "B|....../.S..S./.....S/.S..S./......"),
   ("body", "B|....../SSSSS./SSSSSS/SSSSS./......"), ("head", "B|....S./SSSSS./SSSSSS/SSSSK./....S."),
   ("ears", "B|....S./.SSSS./.SSSS./.SSSS./....S.")])
M("pig", "animals", "🐷", "easy", 10, tr("Порося", "Świnka", "Piglet"),
  tr("Рожеве порося з п'ятачком і вушками.", "Różowa świnka z ryjkiem i uszkami.", "A pink piglet with a snout and ears."),
  [("legs", "B|P..P./...../P..P."), ("body", "B|PPPP./PPPP./PPPP."), ("head", "B|PPPP./PPPPP/PPPK."), ("ears", "P|...P./...../...P.")])
M("fish", "animals", "🐠", "easy", 10, tr("Рибка", "Rybka", "Fish"),
  tr("Помаранчева рибка з білою смужкою на підставці.", "Pomarańczowa rybka z białym paskiem na podstawce.", "An orange fish with a white stripe on a stand."),
  [("stand", "P|..QQQ../..QQQ..", "B|...Q.../...Q..."), ("body", "B|O.OOO../O.OOO..", "B|OOOWOOO/OOOWOKO"),
   ("fins", "B|O.OWO../O.OWO..", "P|..OO.../..OO...")])
M("turtle", "animals", "🐢", "easy", 12, tr("Черепаха", "Żółw", "Turtle"),
  tr("Черепаха з темно-зеленим панцирем.", "Żółw z ciemnozieloną skorupą.", "A turtle with a dark green shell."),
  [("legs", "B|L..L./...../...../L..L."), ("shell", "B|DDDD./DDDDL/DDDDL/DDDD."), ("head", "B|.DD../DDDDK/DDDDK/.DD.."),
   ("top", "P|...../.GG../.GG../.....")])
M("owl", "animals", "🦉", "medium", 15, tr("Сова", "Sowa", "Owl"),
  tr("Мудра сова з великими жовтими очима.", "Mądra sowa z dużymi żółtymi oczami.", "A wise owl with big yellow eyes."),
  [("feet", "P|NNN/NNN/ONO"), ("body", "B|NNN/NNN/NEN", "B|NNN/NNN/NEN"), ("eyes", "B|NNN/NNN/YOY"), ("ears", "B|N.N/.../...")])

# ───────────────────────── NATURE ─────────────────────────
M("flower", "nature", "🌼", "easy", 8, tr("Ромашка", "Stokrotka", "Daisy"),
  tr("Ромашка з листочком на зеленій галявині.", "Stokrotka z listkiem na zielonej łące.", "A daisy with a leaf on a green meadow."),
  [("base", "P|GGGG/GGGG/GGGG/GGGG"), ("stem", "B|..../.G../..../....", "B|..../.GL./..../...."),
   ("petals", "P|WWW./WYW./WWW./....")])
M("tree", "nature", "🌳", "easy", 10, tr("Яблуня", "Jabłoń", "Apple tree"),
  tr("Дерево з пишною кроною і червоним яблучком.", "Drzewo z bujną koroną i czerwonym jabłkiem.", "A tree with a leafy crown and a red apple."),
  [("base", "P|GGGG/GGGG/GGGG/GGGG"), ("trunk", "B|..../.NN./.NN./....", "B|..../.NN./.NN./...."),
   ("crown", "B|LLLL/LLLL/LLLL/LLLL", "B|..../.LL./.LLR/...."), ("top", "B|..../.GG./.GG./....")])
M("cactus", "nature", "🌵", "easy", 10, tr("Кактус", "Kaktus", "Cactus"),
  tr("Кактус у помаранчевому вазоні з рожевою квіткою.", "Kaktus w pomarańczowej doniczce z różowym kwiatkiem.", "A cactus in an orange pot with a pink flower."),
  [("pot", "B|.OO./OOOO/OOOO/.OO.", "P|..../.NN./.NN./...."), ("stem", "B|..../.GG./.GG./...."),
   ("arms", "B|..../GGGG/.GG./....", "B|..../GGGG/.GG./...."), ("top", "B|..../.GG./.GG./....", "P|..../.P../..../....")])
M("mushroom", "nature", "🍄", "easy", 8, tr("Мухомор", "Muchomor", "Toadstool"),
  tr("Червоний гриб у білий горошок.", "Czerwony grzyb w białe kropki.", "A red mushroom with white spots."),
  [("base", "P|LLLL/LLLL/LLLL/LLLL"), ("stem", "B|..../.WW./.WW./....", "B|..../.WW./.WW./...."),
   ("cap", "B|RRRR/RRRR/RRRR/RRRR", "B|.RR./RRWR/RWRR/.RR."), ("spots", "P|..../.RW./.WR./....")])
M("palm", "nature", "🌴", "medium", 18, tr("Пальма на острові", "Palma na wyspie", "Island palm"),
  tr("Пальма з кокосами на піщаному острівці.", "Palma z kokosami na piaszczystej wysepce.", "A palm tree with coconuts on a sandy island."),
  [("base", "P|EEEEE/EEEEE/EEEEE/EEECC/EECCC"), ("trunk", "B|...../...../..N../...../.....", "B|...../...../..N../...../.....", "B|...../...../..N../...../....."),
   ("top", "B|...../..N../.NNN./..N../....."), ("crown", "P|G.G.G/.GGG./GGGGG/.GGG./G.G.G", "P|...../...../..D../...../.....")])

# ───────────────────────── SPACE ─────────────────────────
M("rocket", "space", "🚀", "medium", 20, tr("Ракета на старті", "Rakieta na starcie", "Rocket on the pad"),
  tr("Біло-червона ракета з крилами та ілюмінатором.", "Biało-czerwona rakieta ze skrzydłami i iluminatorem.", "A red-and-white rocket with fins and a porthole."),
  [("base", "P|AAAA/AAAA/AAAA/AAAA"), ("fins", "B|..../RWWR/RWWR/...."), ("body", "B|..../.WW./.WW./....", "B|..../.WW./.WT./....", "B|..../.WW./.WW./...."),
   ("nose", "B|..../.RR./.RR./....", "B|..../..../..R./....")])
M("ufo", "space", "🛸", "easy", 10, tr("Літаюча тарілка", "Latający talerz", "Flying saucer"),
  tr("Сіра тарілка з прозорим куполом і вогниками.", "Szary talerz z kopułą i światełkami.", "A grey saucer with a clear dome and lights."),
  [("base", "B|..../.SS./.SS./...."), ("body", "P|SSSS/SSSS/SSSS/SSSS"), ("lights", "B|Y..Y/.TT./.TT./Y..Y"), ("top", "P|..../.TT./.TT./....")])
M("satellite", "space", "🛰️", "medium", 15, tr("Супутник", "Satelita", "Satellite"),
  tr("Золотий супутник із сонячними панелями й антеною.", "Złoty satelita z panelami słonecznymi i anteną.", "A golden satellite with solar panels and an antenna."),
  [("base", "B|...QQ.../...QQ..."), ("panels", "P|AAASSAAA/AAASSAAA"), ("body", "B|...YY.../...YY...", "B|...YY.../...YY..."),
   ("dish", "P|....K.../........", "B|....W.../........")])
M("rover", "space", "🛻", "medium", 20, tr("Місяцехід", "Łazik księżycowy", "Moon rover"),
  tr("Білий місяцехід з камерою і сонячною батареєю.", "Biały łazik z kamerą i baterią słoneczną.", "A white moon rover with a camera and a solar panel."),
  [("wheels", "B|.K..K./....../....../.K..K."), ("chassis", "P|SSSSSS/SSSSSS/SSSSSS/SSSSSS"), ("body", "B|.WWWW./.WWWW./.WWWW./.WWWW."),
   ("panels", "P|AAA.../AAA.S./AAA.../AAA..."), ("camera", "B|....../....S./....../......", "B|....../....T./....../......")])
M("astronaut", "space", "👩‍🚀", "medium", 15, tr("Космонавт", "Astronauta", "Astronaut"),
  tr("Космонавт у білому скафандрі з золотим шоломом.", "Astronauta w białym skafandrze ze złotym hełmem.", "An astronaut in a white suit with a golden visor."),
  [("legs", "B|.W.W./.W.W."), ("body", "B|.WWW./.WRW.", "B|WWWWW/WWAWW"), ("head", "B|.WWW./.WYW.", "P|.WWW./.WWW."), ("antenna", "B|.S.../.....")])

# ───────────────────────── BUILDINGS ─────────────────────────
M("house", "buildings", "🏠", "hard", 35, tr("Будиночок", "Domek", "Little house"),
  tr("Білий будинок з дверима, вікнами, червоним дахом і димарем.", "Biały domek z drzwiami, oknami, czerwonym dachem i kominem.", "A white house with a door, windows, a red roof and a chimney."),
  [("base", "P|GGGGGG/GGGGGG/GGGGGG/GEGGGG"), ("walls", "B|WWWWWW/W....W/W....W/WNWWWW"), ("windows", "B|WWWWWW/W....W/W....T/WNWTTW"),
   ("walls", "B|WWWWWW/W....W/W....W/WWWWWW"), ("roof", "B|MMMMMM/MMMMMM/MMMMMM/MMMMMM", "B|....S./MMMMMM/MMMMMM/......"),
   ("chimney", "B|....S./....../....../......")])
M("castle", "buildings", "🏰", "hard", 40, tr("Вежа замку", "Wieża zamku", "Castle tower"),
  tr("Кам'яна вежа з воротами, зубцями та прапором.", "Kamienna wieża z bramą, blankami i flagą.", "A stone tower with a gate, battlements and a flag."),
  [("gate", "B|SSSSS/S...S/S...S/S...S/SSNNS", "B|SSSSS/S...S/S...S/S...S/SSNNS"), ("walls", "B|SSSSS/S...S/S...K/S...S/SSSSS", "B|QSSSQ/S...S/S...S/S...S/QSSSQ"),
   ("floor", "P|SSSSS/SSSSS/SSSSS/SSSSS/SSSSS"), ("battlements", "B|S.S.S/...../S.K.S/...../S.S.S"),
   ("flag", "B|...../...../..K../...../.....", "P|...../...../..RR./...../.....")])
M("lighthouse", "buildings", "🗼", "medium", 25, tr("Маяк", "Latarnia morska", "Lighthouse"),
  tr("Смугастий маяк на скелях з жовтим ліхтарем.", "Pasiasta latarnia na skałach z żółtym światłem.", "A striped lighthouse on rocks with a yellow lamp."),
  [("base", "P|QQQQ/QSQQ/QQSQ/QQQQ"), ("tower", "B|..../.RR./.RR./....", "B|..../.WW./.WW./....", "B|..../.RR./.RR./....", "B|..../.WW./.WW./...."),
   ("rails", "P|KKKK/KKKK/KKKK/KKKK"), ("light", "B|..../.TT./.TY./...."), ("roof", "P|..../.RR./.RR./....", "B|..../..../..R./....")])
M("windmill", "buildings", "🌾", "hard", 35, tr("Вітряк", "Wiatrak", "Windmill"),
  tr("Вітряк з бежевою вежею і великими лопатями.", "Wiatrak z beżową wieżą i dużymi skrzydłami.", "A windmill with a beige tower and big sails."),
  [("walls", "B|.EEE./.EEE./.EEE./.....", "B|.EEE./.EEE./.ENE./....."), ("windows", "B|.EEE./.EEE./.ETE./..W.."),
   ("blades", "B|.EEE./.EEE./.EEE./..W..", "B|.EEE./.EEE./.EEE./WWNWW"), ("roof", "B|.MMM./.MMM./.MMM./..W..", "B|..M../.MMM./..M../..W.."),
   ("top", "P|...../..M../...../.....")])
M("skyscraper", "buildings", "🏙️", "medium", 25, tr("Хмарочос", "Wieżowiec", "Skyscraper"),
  tr("Скляний хмарочос з антеною на даху.", "Szklany wieżowiec z anteną na dachu.", "A glass skyscraper with an antenna on top."),
  [("base", "B|SSS/SSS/STS"), ("floor", "B|CCC/CCC/CCC", "B|AAA/AAA/AAA"), ("floor", "B|CCC/CCC/CCC", "B|AAA/AAA/AAA"),
   ("floor", "B|CCC/CCC/CCC", "B|AAA/AAA/AAA"), ("roof", "P|SSS/SSS/SSS"), ("antenna", "B|.../.K./...", "B|.../.K./...", "P|.../.R./...")])
M("bridge", "buildings", "🌉", "medium", 20, tr("Міст через річку", "Most nad rzeką", "River bridge"),
  tr("Кам'яний міст на опорах над блакитною річкою.", "Kamienny most na filarach nad niebieską rzeką.", "A stone bridge on pillars over a blue river."),
  [("water", "P|CCCCCCCC/CCCCCCCC/CCCCCCCC"), ("pillars", "B|.S....S./.S....S./.S....S.", "B|.S....S./.S....S./.S....S."),
   ("deck", "P|NNNNNNNN/NNNNNNNN/NNNNNNNN"), ("rails", "B|SSSSSSSS/......../SSSSSSSS")])
M("doghouse", "buildings", "🏡", "easy", 12, tr("Будка для собаки", "Buda dla psa", "Dog house"),
  tr("Дерев'яна будка з червоним дахом і мискою.", "Drewniana buda z czerwonym dachem i miską.", "A wooden dog house with a red roof and a bowl."),
  [("base", "P|GGGGG/GGGGG/GGGGG/GGGGG/GGGGB"), ("walls", "B|NNNN./N..N./N..N./NKKN./.....", "B|NNNN./N..N./N..N./NKKN./....."),
   ("roof", "B|RRRR./RRRR./RRRR./RRRR./.....", "B|...../RRRR./RRRR./...../.....")])

# ───────────────────────── ROBOTS ─────────────────────────
M("robot", "robots", "🤖", "medium", 18, tr("Робот-помічник", "Robot-pomocnik", "Helper robot"),
  tr("Робот з панеллю на грудях, руками й антеною.", "Robot z panelem na piersi, rękami i anteną.", "A robot with a chest panel, arms and an antenna."),
  [("legs", "B|.A..A./.A..A."), ("body", "B|.SSSS./.SSSS.", "B|RWWWWR/RWYRWR"), ("arms", "B|RWWWWR/RWWWWR"),
   ("head", "B|..YY../..YY..", "B|..YY../..TT.."), ("antenna", "P|..K.../......", "B|..R.../......")])
M("robodog", "robots", "🐕‍🦺", "medium", 15, tr("Робопес", "Robopies", "Robo-dog"),
  tr("Сірий робот-пес з блакитними вушками-сенсорами.", "Szary robopies z błękitnymi uszami-czujnikami.", "A grey robot dog with blue sensor ears."),
  [("legs", "B|S..S../S..S.."), ("body", "B|SSSS../SSSS.."), ("head", "B|Q..SSR/...SSR"), ("ears", "B|...C../...C..")])
M("mech", "robots", "🦾", "hard", 35, tr("Бойовий мех", "Mech bojowy", "Battle mech"),
  tr("Помаранчевий мех на гусеницях з гарматами.", "Pomarańczowy mech na gąsienicach z działami.", "An orange mech on tracks with cannons."),
  [("tracks", "B|KKKKKK/....../....../KKKKKK", "B|KKKKKK/SSSSSS/SSSSSS/KKKKKK"), ("body", "B|.SSSS./.SSSS./.SSSS./.SSSS.", "B|.OOOO./.OOOO./.OOOO./.OOOO."),
   ("cannon", "B|.OOOO./.OOOOK/.OOOOK/.OOOO."), ("cabin", "B|....../..OT../..OT../......", "P|....../..OO../..OO../......")])
M("droid", "robots", "🔵", "easy", 10, tr("Круглий дроїд", "Okrągły droid", "Round droid"),
  tr("Біло-синій дроїд з куполом і оком-камерою.", "Biało-niebieski droid z kopułą i okiem-kamerą.", "A white-and-blue droid with a dome and a camera eye."),
  [("body", "B|.WW./WWWW/WWWW/.WW.", "B|.BB./BWWB/BWWB/.BB.", "B|.WW./WWWW/WWWW/.WW."), ("head", "B|..../.SS./.SK./....", "P|..../.SS./.SS./....")])

# ───────────────────────── FANTASY ─────────────────────────
M("dragon", "fantasy", "🐉", "hard", 40, tr("Дракон", "Smok", "Dragon"),
  tr("Зелений дракон з крилами, жовтим животиком і вогнем.", "Zielony smok ze skrzydłami, żółtym brzuchem i ogniem.", "A green dragon with wings, a yellow belly and fire."),
  [("legs", "B|......../.D..D.../......../.D..D.../........"), ("body", "B|......../DDDDDD../DDDDDD../DDDDDD../........", "B|......../.DDDDD../.DDDDD../.DYYYD../........"),
   ("wings", "B|..LL..../..DDDD../..DDDD../..DDDD../..LL....", "B|.LLL..../....DD../....DD../....DD../.LLL...."),
   ("head", "B|LLL...../....DDD./....DDDO/....DYD./LLL....."), ("horn", "P|......../....K.../......../....K.../........")])
M("unicorn", "fantasy", "🦄", "hard", 30, tr("Єдиноріг", "Jednorożec", "Unicorn"),
  tr("Білий єдиноріг з рожевою гривою і золотим рогом.", "Biały jednorożec z różową grzywą i złotym rogiem.", "A white unicorn with a pink mane and a golden horn."),
  [("legs", "B|W..W../W..W..", "B|W..W../W..W.."), ("body", "B|WWWW../WWWW.."), ("neck", "B|P..WW./P..WW."),
   ("mane", "B|...PWW/...PWK"), ("horn", "P|....Y./......", "B|....Y./......")])
M("chest", "fantasy", "💰", "easy", 10, tr("Скриня зі скарбом", "Skrzynia skarbów", "Treasure chest"),
  tr("Дерев'яна скриня з золотим замком і монетами.", "Drewniana skrzynia ze złotym zamkiem i monetami.", "A wooden chest with a golden lock and coins."),
  [("body", "B|NNNN/NNNN/NNNN", "B|NNNN/NNNN/NYYN"), ("lid", "P|YYYY/YYYY/YYYY", "B|NNNN/NNNN/NNNN"), ("coins", "P|.YY./Y..Y/.YY.")])
M("wizardtower", "fantasy", "🔮", "medium", 20, tr("Вежа чарівника", "Wieża czarodzieja", "Wizard tower"),
  tr("Фіолетова вежа з гострим дахом і зіркою.", "Fioletowa wieża ze spiczastym dachem i gwiazdą.", "A purple tower with a pointed roof and a star."),
  [("walls", "B|VVV/V.V/VNV", "B|VVV/V.V/VTV", "B|VVV/V.V/VVV"), ("roof", "P|AAA/AAA/AAA", "B|.A./AAA/.A.", "B|.../.A./..."),
   ("star", "P|.../.Y./...")])
M("knight", "fantasy", "🛡️", "medium", 15, tr("Лицар", "Rycerz", "Knight"),
  tr("Лицар у сірих обладунках з червоним щитом.", "Rycerz w szarej zbroi z czerwoną tarczą.", "A knight in grey armour with a red shield."),
  [("legs", "B|.S.S./.S.S."), ("body", "B|.SSS./.SRS.", "B|SSSSS/SSRSS"), ("head", "B|..S.W/..K.W", "P|..S../..S.."), ("details", "B|..R../.....")])

# ───────────────────────── FOOD ─────────────────────────
M("burger", "food", "🍔", "easy", 8, tr("Бургер", "Burger", "Burger"),
  tr("Соковитий бургер з котлетою, сиром, салатом і помідором.", "Soczysty burger z kotletem, serem, sałatą i pomidorem.", "A juicy burger with a patty, cheese, lettuce and tomato."),
  [("bun", "B|EEEE/EEEE/EEEE/EEEE"), ("filling", "B|NNNN/NNNN/NNNN/NNNN", "P|YYYY/YYYY/YYYY/YYYY", "P|LLLL/LLLL/LLLL/LLLL", "P|RRRR/RRRR/RRRR/RRRR"),
   ("bun", "B|EEEE/EEEE/EEEE/EEEE"), ("seeds", "P|.W../...W/W.../..W.")])
M("cake", "food", "🎂", "medium", 20, tr("Святковий торт", "Tort urodzinowy", "Birthday cake"),
  tr("Рожевий торт з кремом, вишеньками і свічкою.", "Różowy tort z kremem, wisienkami i świeczką.", "A pink cake with cream, cherries and a candle."),
  [("base", "P|SSSSS/SSSSS/SSSSS/SSSSS/SSSSS"), ("layer", "B|.PPP./PPPPP/PPPPP/PPPPP/.PPP."), ("cream", "B|.WWW./WWWWW/WWWWW/WWWWW/.WWW."),
   ("layer", "B|.PPP./PPPPP/PPPPP/PPPPP/.PPP."), ("decor", "P|.R.R./R...R/..W../R...R/.R.R."),
   ("candle", "B|...../...../..W../...../.....", "P|...../...../..O../...../.....")])
M("icecream", "food", "🍦", "easy", 8, tr("Морозиво в ріжку", "Lody w rożku", "Ice cream cone"),
  tr("Ріжок з рожевою кулькою і вишенькою.", "Rożek z różową gałką i wisienką.", "A cone with a pink scoop and a cherry."),
  [("cone", "B|..../.EE./.EE./....", "B|..../.EE./.EE./....", "B|.EE./EEEE/EEEE/.EE."),
   ("scoop", "B|.PP./PPPP/PPPP/.PP.", "B|..../.PP./.PW./...."), ("top", "P|..../.R../..../....")])
M("watermelon", "food", "🍉", "easy", 10, tr("Скибка кавуна", "Kawałek arbuza", "Watermelon slice"),
  tr("Соковита скибка кавуна з кісточками.", "Soczysty kawałek arbuza z pestkami.", "A juicy watermelon slice with seeds."),
  [("rind", "B|DDDDDDD/DDDDDDD", "B|LRRRRRL/LRRRRRL"), ("seeds", "B|.RRKRR./.RRKRR.", "B|..RRR../..RKR.."), ("top", "B|...R.../...R...")])
M("pizza", "food", "🍕", "easy", 10, tr("Піца", "Pizza", "Pizza"),
  tr("Кругла піца з сиром, помідорами та оливками.", "Okrągła pizza z serem, pomidorami i oliwkami.", "A round pizza with cheese, tomatoes and olives."),
  [("base", "P|.EEEE./EEEEEE/EEEEEE/EEEEEE/EEEEEE/.EEEE."), ("cheese", "P|.EEEE./EYYYYE/EYYYYE/EYYYYE/EYYYYE/.EEEE."),
   ("decor", "P|....../.R..K./...R../..K.../.R..R./......")])

# ───────────────────────── HOME ─────────────────────────
M("chair", "home", "🪑", "easy", 8, tr("Стілець", "Krzesło", "Chair"),
  tr("Дерев'яний стілець з червоним сидінням.", "Drewniane krzesło z czerwonym siedziskiem.", "A wooden chair with a red seat."),
  [("legs", "B|N.N/.../N.N", "B|N.N/.../N.N"), ("seat", "P|RRR/RRR/RRR"), ("back", "B|NNN/.../...", "B|NNN/.../...", "P|NNN/.../...")])
M("table", "home", "🛋️", "medium", 15, tr("Стіл з лампою", "Stół z lampą", "Table with a lamp"),
  tr("Стіл, на якому стоїть лампа й горнятко.", "Stół, na którym stoi lampa i kubek.", "A table with a lamp and a mug on it."),
  [("legs", "B|N....N/....../....../N....N", "B|N....N/....../....../N....N"), ("table", "P|NNNNNN/NNNNNN/NNNNNN/NNNNNN"),
   ("lamp", "B|....../....S./.W..../......", "B|....../....S./....../......", "B|....../...YY./...YY./......")])
M("sofa", "home", "🛋️", "easy", 10, tr("Диван", "Kanapa", "Sofa"),
  tr("Синій диван з жовтими подушками.", "Niebieska kanapa z żółtymi poduszkami.", "A blue sofa with yellow cushions."),
  [("base", "B|AAAAAA/AAAAAA/AAAAAA"), ("back", "B|AAAAAA/AY..YA/A....A"), ("top", "P|AAAAAA/A....A/A....A")])
M("bed", "home", "🛏️", "medium", 15, tr("Ліжко", "Łóżko", "Bed"),
  tr("Ліжко з узголів'ям, подушкою і синьою ковдрою.", "Łóżko z wezgłowiem, poduszką i niebieską kołdrą.", "A bed with a headboard, a pillow and a blue blanket."),
  [("legs", "B|N....N/....../....../N....N"), ("base", "B|NNNNNN/NNNNNN/NNNNNN/NNNNNN"), ("pillow", "B|NWWWWW/NWWWWW/NWWWWW/NWWWWW"),
   ("blanket", "B|NWWBBB/NWWBBB/NWWBBB/NWWBBB"), ("headboard", "B|N...../N...../N...../N.....")])
M("tv", "home", "📺", "easy", 8, tr("Телевізор", "Telewizor", "TV"),
  tr("Плаский телевізор на підставці з блакитним екраном.", "Płaski telewizor na podstawce z niebieskim ekranem.", "A flat TV on a stand with a blue screen."),
  [("stand", "P|.QQQQ./.QQQQ.", "B|..QQ../..QQ.."), ("screen", "B|KKKKKK/KCCCCK", "B|KKKKKK/KCACCK", "B|KKKKKK/KKKKKK")])

# ───────────────────────── HOLIDAYS ─────────────────────────
M("snowman", "holidays", "⛄", "easy", 10, tr("Сніговик", "Bałwan", "Snowman"),
  tr("Сніговик з морквинкою, шарфом і капелюхом.", "Bałwan z marchewką, szalikiem i kapeluszem.", "A snowman with a carrot nose, a scarf and a hat."),
  [("body", "B|.WW./WWWW/WWWW/.WW.", "B|.WW./WWWW/WWWW/.WW.", "B|..../.WW./.WK./...."), ("scarf", "B|..../.RR./.RR./...."),
   ("head", "B|..../.WW./.WO./...."), ("hat", "P|..../.KK./.KK./....", "B|..../.KK./.KK./....")])
M("xmastree", "holidays", "🎄", "medium", 20, tr("Новорічна ялинка", "Choinka", "Christmas tree"),
  tr("Ялинка з кульками та зіркою на верхівці.", "Choinka z bombkami i gwiazdą na czubku.", "A tree with baubles and a star on top."),
  [("pot", "P|...../.RRR./.RRR./.RRR./.....", "B|...../...../..N../...../....."),
   ("crown", "B|DDDDD/DDDDR/DDDDD/DDDDY/DRDYD", "B|.DDD./DDDDD/DDDDR/DDDDD/.DYD."), ("top", "B|...../.DDD./.DDY./.RDD./.....", "B|...../...../..D../...../....."),
   ("star", "P|...../...../..Y../...../.....")])
M("gift", "holidays", "🎁", "easy", 6, tr("Подарунок", "Prezent", "Gift box"),
  tr("Червона коробка з жовтою стрічкою і бантиком.", "Czerwone pudełko z żółtą wstążką i kokardą.", "A red box with a yellow ribbon and a bow."),
  [("body", "B|RRYR/RRYR/YYYY/RRYR", "B|RRYR/RRYR/YYYY/RRYR"), ("lid", "P|RRYR/RRYR/YYYY/RRYR"), ("bow", "B|..../.Y../..Y./....")])
M("sleigh", "holidays", "🛷", "medium", 20, tr("Сани з подарунками", "Sanie z prezentami", "Gift sleigh"),
  tr("Червоні сани на срібних полозках з подарунками.", "Czerwone sanie na srebrnych płozach z prezentami.", "A red sleigh on silver runners with gifts."),
  [("runners", "P|SSSSSS/....../SSSSSS", "B|.R..RS/....../.R..RS"), ("body", "B|RRRRRS/RRRRR./RRRRRS"),
   ("seat", "B|RY.G../RY.B../RY...."), ("back", "B|R...../R...../R.....")])
M("lantern", "holidays", "🏮", "easy", 8, tr("Святковий ліхтарик", "Świąteczny lampion", "Festive lantern"),
  tr("Червоний ліхтарик з теплим жовтим світлом.", "Czerwony lampion z ciepłym żółtym światłem.", "A red lantern with a warm yellow glow."),
  [("base", "P|KKK/KKK/KKK"), ("light", "B|RRR/RYR/RYR", "B|RRR/RYR/RYR"), ("top", "P|KKK/KKK/KKK", "B|.../.K./...")])



# ───────────────────────── bigger models (geometry helpers) ─────────────────────────
from more_models import NEW_CATEGORIES, NEW_LABELS, add_more  # noqa: E402

LABELS.update(NEW_LABELS)
add_more(M, tr)

# ───────────────────────── shared tables (used by the Flutter app) ─────────────────────────
COLOR_HEX = {"R": "#D7261E", "B": "#1F5FBF", "Y": "#F6C624", "W": "#F2F3F0", "G": "#2E8B57", "L": "#8CC63F", "K": "#2B2F36",
             "O": "#F28C28", "N": "#8B5A2B", "T": "#9FD8F0", "S": "#A3A8AD", "P": "#E86FA8", "D": "#1E6B3F", "A": "#22407E",
             "E": "#E4CD9E", "M": "#A3241E", "V": "#7B4FB0", "C": "#3FB4C9", "Q": "#5B6066"}
COLOR_NAMES = {"R": ("червона", "czerwony", "red"), "B": ("синя", "niebieski", "blue"), "Y": ("жовта", "żółty", "yellow"),
               "W": ("біла", "biały", "white"), "G": ("зелена", "zielony", "green"), "L": ("салатова", "limonkowy", "lime"),
               "K": ("чорна", "czarny", "black"), "O": ("помаранчева", "pomarańczowy", "orange"), "N": ("коричнева", "brązowy", "brown"),
               "T": ("прозора", "przezroczysty", "clear"), "S": ("сіра", "szary", "grey"), "P": ("рожева", "różowy", "pink"),
               "D": ("темно-зелена", "ciemnozielony", "dark green"), "A": ("темно-синя", "granatowy", "navy"), "E": ("бежева", "beżowy", "tan"),
               "M": ("бордова", "bordowy", "dark red"), "V": ("фіолетова", "fioletowy", "purple"), "C": ("блакитна", "błękitny", "azure"),
               "Q": ("темно-сіра", "grafitowy", "dark grey")}
CATEGORIES = {"transport": ("Транспорт", "Pojazdy", "Vehicles"), "animals": ("Тварини", "Zwierzęta", "Animals"),
              "nature": ("Природа", "Przyroda", "Nature"), "space": ("Космос", "Kosmos", "Space"),
              "buildings": ("Будівлі", "Budynki", "Buildings"), "robots": ("Роботи", "Roboty", "Robots"),
              "fantasy": ("Фентезі", "Fantasy", "Fantasy"), "food": ("Їжа", "Jedzenie", "Food"),
              "home": ("Дім", "Dom", "Home"), "holidays": ("Свята", "Święta", "Holidays")}
CATEGORIES.update(NEW_CATEGORIES)
PILES = [
    dict(id="mix", n=tr("Змішана купка", "Mieszany stos", "Mixed pile"), total=86,
         colors=[["R", 24], ["B", 19], ["Y", 16], ["W", 14], ["K", 8], ["T", 5]],
         notable=tr(["4 колеса", "прозорі 1×2", "пластина 4×6"], ["4 koła", "przezroczyste 1×2", "płytka 4×6"], ["4 wheels", "clear 1×2s", "4×6 plate"]),
         ideas=["car", "rocket", "bus", "robot", "plane", "gift"]),
    dict(id="farm", n=tr("Ферма й природа", "Farma i przyroda", "Farm and nature"), total=74,
         colors=[["N", 18], ["G", 15], ["Y", 12], ["L", 11], ["O", 8], ["K", 6]],
         notable=tr(["зелені пластини", "коричневі 1×1", "великі колеса"], ["zielone płytki", "brązowe 1×1", "duże koła"], ["green plates", "brown 1×1s", "big wheels"]),
         ideas=["tractor", "dog", "duck", "tree", "cat", "giraffe"]),
    dict(id="space", n=tr("Космічна місія", "Misja kosmiczna", "Space mission"), total=72,
         colors=[["S", 20], ["W", 17], ["A", 12], ["T", 9], ["Y", 8], ["R", 6]],
         notable=tr(["прозорі купол і скло", "темно-сині панелі"], ["przezroczyste kopuły", "granatowe panele"], ["clear domes", "navy panels"]),
         ideas=["ufo", "satellite", "rover", "astronaut", "rocket", "droid"]),
    dict(id="winter", n=tr("Новорічна", "Świąteczny", "Holiday box"), total=68,
         colors=[["R", 18], ["W", 16], ["D", 14], ["Y", 9], ["S", 6], ["K", 5]],
         notable=tr(["темно-зелені 2×4", "срібні пластини"], ["ciemnozielone 2×4", "srebrne płytki"], ["dark green 2×4s", "silver plates"]),
         ideas=["xmastree", "snowman", "sleigh", "gift", "lantern", "house"]),
    dict(id="sweet", n=tr("Солодка купка", "Słodki stos", "Sweet pile"), total=58,
         colors=[["P", 15], ["E", 13], ["R", 10], ["W", 8], ["Y", 7], ["L", 5]],
         notable=tr(["рожеві 2×2", "бежеві пластини"], ["różowe 2×2", "beżowe płytki"], ["pink 2×2s", "tan plates"]),
         ideas=["cake", "icecream", "burger", "pizza", "watermelon", "pig"]),
]

# ───────────────────────── generator ─────────────────────────
def parse_layer(spec):
    kind, rows = spec.split("|", 1)
    rows = rows.split("/")
    width = len(rows[0])
    assert kind in ("B", "P"), spec
    assert all(len(r) == width for r in rows), f"uneven rows: {spec}"
    for r in rows:
        for ch in r:
            assert ch == "." or ch in COLORS, f"bad colour {ch!r} in {spec}"
    return kind, rows


def decompose(rows, plate, flip):
    """Greedy cover of a layer with standard parts of one colour each."""
    h, w = len(rows), len(rows[0])
    used = [[False] * w for _ in range(h)]
    sizes = PLATE_SIZES if plate else BRICK_SIZES
    if flip:  # alternate orientation on odd layers so bricks overlap like a real build
        sizes = [(d, ww) for ww, d in sizes]
    out = []
    for y in range(h):
        for x in range(w):
            c = rows[y][x]
            if c == "." or used[y][x]:
                continue
            for sw, sd in sizes:
                if x + sw > w or y + sd > h:
                    continue
                if all(rows[y + j][x + i] == c and not used[y + j][x + i] for j in range(sd) for i in range(sw)):
                    for j in range(sd):
                        for i in range(sw):
                            used[y + j][x + i] = True
                    out.append((x, y, sw, sd, c))
                    break
    return out


def build(m):
    z = 0.0
    steps = []
    layer_no = 0
    for step in m["steps"]:
        label, *layers = step
        assert label in LABELS, label
        bricks = []
        for spec in layers:
            kind, rows = parse_layer(spec)
            plate = kind == "P"
            hgt = PLATE if plate else 1
            for x, y, sw, sd, c in decompose(rows, plate, layer_no % 2 == 1):
                bricks.append([x, y, round(z, 2), sw, sd, c, hgt])
            z += hgt
            layer_no += 1
        steps.append({"l": label, "b": bricks})
    total = sum(len(s["b"]) for s in steps)
    return {"id": m["id"], "cat": m["cat"], "emoji": m["emoji"], "diff": m["diff"], "min": m["min"],
            "t": m["t"], "d": m["d"], "s": steps, "n": total}


def main():
    ids = [m["id"] for m in MODELS]
    assert len(ids) == len(set(ids)), "duplicate ids"
    for m in MODELS:
        assert m["diff"] in ("easy", "medium", "hard", "expert"), m["id"]
        assert m["cat"] in CATEGORIES, m["id"]
    cat = [build(m) for m in MODELS]
    labels = {k: {"uk": v[0], "pl": v[1], "en": v[2]} for k, v in LABELS.items()}
    js = ("/* GENERATED by models/build_models.py — edit the layer drawings there */\n"
          f"const STEPL={json.dumps(labels, ensure_ascii=False, separators=(',', ':'))};\n"
          f"const CAT={json.dumps(cat, ensure_ascii=False, separators=(',', ':'))};\n"
          "/* END GENERATED */")
    page = Path(__file__).resolve().parent.parent / "index.html"
    html = page.read_text(encoding="utf-8")
    new, n = re.subn(r"/\* GENERATED by .*?/\* END GENERATED \*/", lambda _: js, html, flags=re.S)
    assert n == 1, "markers not found in index.html"
    page.write_text(new, encoding="utf-8")
    l3 = lambda t: {"uk": t[0], "pl": t[1], "en": t[2]}
    for p in PILES:
        assert all(i in ids for i in p["ideas"]), p["id"]
    bundle = {"version": 1, "colors": COLOR_HEX, "colorNames": {k: l3(v) for k, v in COLOR_NAMES.items()},
              "categories": {k: l3(v) for k, v in CATEGORIES.items()}, "steps": labels, "models": cat, "piles": PILES}
    asset = Path(__file__).resolve().parents[2] / "mobile" / "assets" / "catalog.json"
    asset.parent.mkdir(parents=True, exist_ok=True)
    asset.write_text(json.dumps(bundle, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    # compact list for the AI prompt: the model picks catalog ids that fit the photographed pile
    lines = []
    for c in cat:
        used = {}
        for st in c["s"]:
            for b in st["b"]:
                used[b[5]] = used.get(b[5], 0) + b[3] * b[4]
        top = [COLOR_NAMES[k][2] for k, _ in sorted(used.items(), key=lambda kv: -kv[1])[:3]]
        lines.append(f'{c["id"]} | {c["t"]["en"]} | {c["cat"]} | {c["diff"]} | {c["n"]} pieces | {", ".join(top)}')
    lst = Path(__file__).resolve().parents[2] / "backend" / "app" / "profiles" / "brick_catalog.txt"
    lst.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {lst} ({len(lines)} lines)")
    print(f"wrote {asset} ({asset.stat().st_size // 1024} KB)")
    by_cat = {}
    for c in cat:
        by_cat[c["cat"]] = by_cat.get(c["cat"], 0) + 1
    print(f"{len(cat)} models, {sum(c['n'] for c in cat)} parts total; by category: {by_cat}")


if __name__ == "__main__":
    main()
