"""Bigger and more advanced models, drawn with small geometry helpers instead of raw ASCII.

Every layer is a grid seen from above: x → right (front), y → down (front). Helpers return
"B|..." (brick layer) or "P|..." (plate layer) strings that build_models.py turns into real parts.
"""
import math

NEW_LABELS = {
    "dome": ("Бані", "Kopuły", "Domes"), "tier": ("Ярус", "Kondygnacja", "Tier"), "arches": ("Арки", "Łuki", "Arches"),
    "boom": ("Стріла крана", "Wysięgnik", "Crane boom"), "containers": ("Контейнери", "Kontenery", "Containers"),
    "lava": ("Лава", "Lawa", "Lava"), "basket": ("Кошик", "Kosz", "Basket"), "envelope": ("Купол кулі", "Czasza", "Balloon"),
    "spikes": ("Шипи", "Kolce", "Spikes"), "claws": ("Клешні", "Szczypce", "Claws"), "periscope": ("Перископ", "Peryskop", "Periscope"),
    "clock": ("Годинник", "Zegar", "Clock"), "spire": ("Шпиль", "Iglica", "Spire"), "platform": ("Платформа", "Platforma", "Platform"),
    "engines": ("Двигуни", "Silniki", "Engines"), "stage": ("Ступінь ракети", "Stopień rakiety", "Rocket stage"),
    "keys": ("Клавіші", "Klawisze", "Keys"), "glass": ("Скло й вода", "Szkło i woda", "Glass and water"),
    "icing": ("Глазур", "Lukier", "Icing"), "stripes": ("Смужки", "Paski", "Stripes"), "bunk": ("Ліжко", "Łóżko", "Bunk"),
    "garage": ("Гараж", "Garaż", "Garage"), "awning": ("Маркіза", "Markiza", "Awning"), "silo": ("Силос", "Silos", "Silo"),
    "gripper": ("Захват", "Chwytak", "Gripper"), "shoulders": ("Плечі", "Barki", "Shoulders"), "torso": ("Тулуб", "Tułów", "Torso"),
    "hips": ("Стегна", "Biodra", "Hips"), "visor": ("Візор", "Wizjer", "Visor"), "sensor": ("Сенсор", "Czujnik", "Sensor"),
    "cockpit": ("Кабіна пілота", "Kokpit", "Cockpit"), "habitat": ("Житловий модуль", "Moduł mieszkalny", "Habitat"),
    "truss": ("Ферма", "Kratownica", "Truss"), "capsule": ("Капсула", "Kapsuła", "Capsule"), "bridgeh": ("Місток", "Mostek", "Bridge"),
    "keep": ("Донжон", "Donżon", "Keep"), "tray": ("Тарілка", "Taca", "Tray"), "rolls": ("Роли", "Rolki", "Rolls"),
    "toppings": ("Начинка зверху", "Dodatki", "Toppings"), "rails2": ("Бортики", "Barierki", "Side rails"),
    "candy": ("Цукерки", "Cukierki", "Candy"), "ornaments": ("Іграшки", "Bombki", "Baubles"), "drum": ("Барабан", "Bęben", "Drum"),
    "entrance": ("Вхід", "Wejście", "Entrance"), "eaves": ("Карнизи", "Okapy", "Eaves"), "pillars2": ("Опори вежі", "Nogi wieży", "Tower legs"),
    "ground": ("Земля", "Ziemia", "Ground"), "bench": ("Банкетка", "Ławka", "Bench"),
}
NEW_CATEGORIES = {"landmarks": ("Пам'ятки", "Zabytki", "Landmarks")}


# ───────────── geometry helpers ─────────────
def L(w, d, *ops, kind="B"):
    g = [["."] * w for _ in range(d)]
    for op in ops:
        op(g)
    return kind + "|" + "/".join("".join(r) for r in g)


def P(w, d, *ops):
    return L(w, d, *ops, kind="P")


def R(x0, y0, x1, y1, c):  # filled rectangle, inclusive
    def op(g):
        for y in range(max(0, y0), min(len(g), y1 + 1)):
            for x in range(max(0, x0), min(len(g[0]), x1 + 1)):
                g[y][x] = c
    return op


def F(x0, y0, x1, y1, c):  # rectangle outline (walls)
    def op(g):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if x in (x0, x1) or y in (y0, y1):
                    g[y][x] = c
    return op


def D(cx, cy, r, c, inner=None):  # disk (or ring when inner is given)
    def op(g):
        for y in range(len(g)):
            for x in range(len(g[0])):
                dd = math.hypot(x - cx, y - cy)
                if dd <= r + .25 and (inner is None or dd > inner + .25):
                    g[y][x] = c
    return op


def E(cx, cy, a, b, c, ia=None, ib=None):  # ellipse (or elliptic ring)
    def op(g):
        for y in range(len(g)):
            for x in range(len(g[0])):
                if ((x - cx) / a) ** 2 + ((y - cy) / b) ** 2 <= 1.02:
                    if ia is None or ((x - cx) / ia) ** 2 + ((y - cy) / ib) ** 2 > 1.0:
                        g[y][x] = c
    return op


def Pt(pts, c):
    def op(g):
        for x, y in pts:
            g[y][x] = c
    return op


def Row(y, x0, pattern):  # write a string of colours along a row ("." keeps what is there)
    def op(g):
        for i, ch in enumerate(pattern):
            if ch != ".":
                g[y][x0 + i] = ch
    return op


def Edge(c, every=3, start=0, palette=None):
    """Recolour every n-th outer cell of what is already drawn (ornaments, arches)."""
    def op(g):
        h, w = len(g), len(g[0])
        cells = [(x, y) for y in range(h) for x in range(w) if g[y][x] != "." and any(
            not (0 <= x + dx < w and 0 <= y + dy < h) or g[y + dy][x + dx] == "." for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
        cells.sort(key=lambda p: math.atan2(p[1] - h / 2, p[0] - w / 2))
        for i, (x, y) in enumerate(cells):
            if (i + start) % every == 0:
                g[y][x] = palette[(i // every) % len(palette)] if palette else c
    return op


def add_more(M, tr):
    # ───────────── TRANSPORT ─────────────
    W4 = Pt([(1, 0), (6, 0), (1, 3), (6, 3)], "K")
    M("ambulance", "transport", "🚑", "medium", 25, tr("Швидка допомога", "Karetka", "Ambulance"),
      tr("Біла швидка з червоними смугами, мигалками й хрестом.", "Biała karetka z czerwonymi pasami, kogutami i krzyżem.", "A white ambulance with red stripes, flashing lights and a cross."),
      [("wheels", L(9, 4, W4)), ("chassis", P(9, 4, R(0, 0, 8, 3, "K"))),
       ("body", L(9, 4, R(0, 0, 8, 3, "W"), Pt([(8, 0), (8, 3)], "O"), Row(3, 2, "RRR"))),
       ("windows", L(9, 4, R(0, 0, 6, 3, "W"), R(0, 3, 6, 3, "R"), R(3, 3, 3, 3, "W"), R(7, 0, 7, 3, "T"))),
       ("roof", P(9, 4, R(0, 0, 7, 3, "W"))), ("lights", L(9, 4, Pt([(3, 1)], "B"), Pt([(3, 2)], "R")))])
    M("police", "transport", "🚓", "medium", 20, tr("Поліцейське авто", "Radiowóz", "Police car"),
      tr("Біло-синя патрульна машина з мигалкою на даху.", "Biało-niebieski radiowóz z kogutem na dachu.", "A white-and-blue patrol car with a light bar."),
      [("wheels", L(7, 4, Pt([(1, 0), (5, 0), (1, 3), (5, 3)], "K"))), ("chassis", P(7, 4, R(0, 0, 6, 3, "K"))),
       ("body", L(7, 4, R(0, 0, 6, 3, "W"), R(1, 0, 5, 0, "A"), R(1, 3, 5, 3, "A"), Pt([(6, 0), (6, 3)], "Y"))),
       ("cabin", L(7, 4, R(2, 0, 4, 3, "W"), R(5, 0, 5, 3, "T"))), ("roof", P(7, 4, R(2, 0, 5, 3, "W"))),
       ("lights", L(7, 4, Pt([(3, 1)], "B"), Pt([(3, 2)], "R")))])
    WH = [R(0, 0, 1, 1, "K"), R(6, 0, 7, 1, "K"), R(0, 4, 1, 5, "K"), R(6, 4, 7, 5, "K")]
    M("monstertruck", "transport", "🛻", "hard", 35, tr("Монстр-трак", "Monster truck", "Monster truck"),
      tr("Зелений позашляховик на величезних колесах з полум'ям на боці.", "Zielony pojazd na ogromnych kołach z płomieniami na boku.", "A green truck on giant wheels with flames on the side."),
      [("wheels", L(8, 6, *WH), L(8, 6, *WH)), ("chassis", P(8, 6, R(0, 0, 7, 5, "Q"))),
       ("body", L(8, 6, R(0, 1, 7, 4, "G"), Pt([(7, 1), (7, 4)], "Y"), Row(4, 1, "ORO"))),
       ("cabin", L(8, 6, R(1, 1, 4, 4, "G"), R(5, 1, 5, 4, "T"))), ("roof", P(8, 6, R(1, 1, 5, 4, "G"))),
       ("lights", L(8, 6, Pt([(3, 1), (3, 4)], "Y")))])
    M("crane", "transport", "🏗️", "expert", 45, tr("Автокран", "Dźwig samochodowy", "Mobile crane"),
      tr("Жовтий автокран з поворотною платформою і довгою стрілою.", "Żółty dźwig z obrotową platformą i długim wysięgnikiem.", "A yellow crane truck with a turntable and a long boom."),
      [("wheels", L(10, 4, Pt([(1, 0), (4, 0), (8, 0), (1, 3), (4, 3), (8, 3)], "K"))), ("chassis", P(10, 4, R(0, 0, 9, 3, "K"))),
       ("body", L(10, 4, R(0, 0, 9, 3, "Y"), Pt([(9, 0), (9, 3)], "O"))),
       ("cabin", L(10, 4, R(1, 0, 5, 3, "Q"), R(7, 0, 8, 3, "Y"), R(9, 0, 9, 3, "T"))),
       ("boom", L(10, 4, R(7, 0, 9, 3, "Y"), R(2, 1, 4, 2, "Y")), L(10, 4, R(3, 1, 5, 2, "Y")), L(10, 4, R(4, 1, 6, 2, "Y"))),
       ("top", L(10, 4, R(5, 1, 7, 2, "Y")), L(10, 4, R(6, 1, 8, 2, "Y")), L(10, 4, R(7, 1, 8, 2, "Y"), R(9, 1, 9, 2, "K")))])
    HULL = lambda c: [R(1, 0, 10, 4, c), R(11, 1, 11, 3, c), R(0, 1, 0, 3, c)]
    M("cargoship", "transport", "🚢", "expert", 50, tr("Контейнеровоз", "Kontenerowiec", "Container ship"),
      tr("Великий корабель з різнокольоровими контейнерами й містком.", "Duży statek z kolorowymi kontenerami i mostkiem.", "A big ship with colourful containers and a bridge."),
      [("hull", L(12, 5, *HULL("R")), L(12, 5, *HULL("A"))), ("deck", P(12, 5, *HULL("Q"))),
       ("containers", L(12, 5, R(0, 1, 1, 3, "W"), R(3, 0, 4, 1, "O"), R(3, 3, 4, 4, "B"), R(5, 0, 6, 1, "G"), R(5, 3, 6, 4, "Y"),
                        R(7, 0, 8, 1, "B"), R(7, 3, 8, 4, "R"), R(3, 2, 8, 2, "S")),
                      L(12, 5, R(0, 1, 1, 3, "W"), R(3, 0, 4, 1, "Y"), R(5, 0, 6, 1, "R"), R(5, 3, 6, 4, "B"), R(7, 3, 8, 4, "G"), R(3, 3, 4, 4, "O"))),
       ("bridgeh", L(12, 5, R(0, 1, 1, 3, "T")), P(12, 5, R(0, 1, 1, 3, "W"))), ("chimney", L(12, 5, Pt([(0, 2)], "R")))])
    M("airliner", "transport", "🛫", "expert", 45, tr("Пасажирський лайнер", "Samolot pasażerski", "Airliner"),
      tr("Довгий лайнер з двигунами під крилами й синім хвостом.", "Długi samolot z silnikami pod skrzydłami i niebieskim ogonem.", "A long airliner with engines under the wings and a blue tail."),
      [("engines", L(12, 10, R(5, 1, 6, 1, "Q"), R(5, 8, 6, 8, "Q"), R(0, 4, 11, 5, "W"))),
       ("wings", L(12, 10, R(0, 4, 11, 5, "W"), R(1, 5, 9, 5, "C"), R(3, 0, 6, 3, "S"), R(3, 6, 6, 9, "S"), Pt([(6, 0), (6, 9)], "R"))),
       ("cockpit", L(12, 10, R(0, 4, 10, 5, "W"), R(11, 4, 11, 5, "T"), R(0, 2, 1, 3, "S"), R(0, 6, 1, 7, "S"))),
       ("tail", L(12, 10, R(0, 4, 1, 5, "B")), L(12, 10, R(0, 4, 0, 5, "B")))])
    M("submarine", "transport", "🌊", "medium", 22, tr("Жовтий підводний човен", "Żółta łódź podwodna", "Yellow submarine"),
      tr("Підводний човен з ілюмінаторами, гвинтом і перископом.", "Łódź podwodna z iluminatorami, śrubą i peryskopem.", "A submarine with portholes, a propeller and a periscope."),
      [("hull", L(9, 2, R(1, 0, 7, 1, "Y")), L(9, 2, R(1, 0, 8, 1, "Y"), R(0, 0, 0, 1, "K"), Pt([(2, 1), (4, 1), (6, 1)], "T"))),
       ("top", L(9, 2, R(1, 0, 7, 1, "Y")), L(9, 2, R(3, 0, 5, 1, "Y"))),
       ("periscope", L(9, 2, Pt([(4, 0)], "K")), P(9, 2, R(4, 0, 5, 0, "K")))])
    M("balloon", "transport", "🎈", "hard", 30, tr("Повітряна куля", "Balon", "Hot-air balloon"),
      tr("Смугаста повітряна куля з плетеним кошиком.", "Pasiasty balon z wiklinowym koszem.", "A striped hot-air balloon with a wicker basket."),
      [("basket", L(7, 7, R(2, 2, 4, 4, "N"))), ("details", L(7, 7, Pt([(2, 2), (4, 2), (2, 4), (4, 4)], "K")), L(7, 7, Pt([(2, 2), (4, 2), (2, 4), (4, 4)], "K"))),
       ("envelope", L(7, 7, D(3, 3, 2, "R")), L(7, 7, D(3, 3, 3, "Y")), L(7, 7, D(3, 3, 3, "R"))),
       ("top", L(7, 7, D(3, 3, 3, "Y")), L(7, 7, D(3, 3, 2, "R")), L(7, 7, D(3, 3, 1, "Y")), P(7, 7, Pt([(3, 3)], "R")))])

    # ───────────── ANIMALS ─────────────
    M("trex", "animals", "🦖", "hard", 40, tr("Тиранозавр", "Tyranozaur", "T-rex"),
      tr("Зелений тиранозавр з шипами на спині й гострими зубами.", "Zielony tyranozaur z kolcami na grzbiecie i ostrymi zębami.", "A green T-rex with spikes on its back and sharp teeth."),
      [("legs", L(10, 3, R(3, 0, 4, 0, "D"), R(3, 2, 4, 2, "D")), L(10, 3, R(3, 0, 4, 0, "D"), R(3, 2, 4, 2, "D"))),
       ("body", L(10, 3, R(1, 0, 6, 2, "D"), Pt([(0, 1)], "D")), L(10, 3, R(2, 0, 7, 2, "D"), Pt([(1, 1)], "D"), R(3, 2, 6, 2, "L"))),
       ("spikes", L(10, 3, R(5, 0, 7, 2, "D"), R(2, 1, 4, 1, "L"), Pt([(8, 0)], "D"))),
       ("head", L(10, 3, R(6, 0, 9, 2, "D"), Pt([(9, 1)], "W")), L(10, 3, R(6, 0, 8, 2, "D"), Pt([(7, 2)], "Y")))])
    M("horse", "animals", "🐴", "hard", 30, tr("Кінь", "Koń", "Horse"),
      tr("Гнідий кінь з чорною гривою і хвостом.", "Gniady koń z czarną grzywą i ogonem.", "A bay horse with a black mane and tail."),
      [("legs", L(7, 2, Pt([(1, 0), (1, 1), (4, 0), (4, 1)], "N")), L(7, 2, Pt([(1, 0), (1, 1), (4, 0), (4, 1)], "N"))),
       ("body", L(7, 2, R(1, 0, 5, 1, "N")), L(7, 2, R(1, 0, 5, 1, "N"), R(0, 0, 0, 1, "K"))),
       ("neck", L(7, 2, R(4, 0, 4, 1, "K"), R(5, 0, 5, 1, "N"))), ("head", L(7, 2, R(4, 0, 4, 1, "K"), R(5, 0, 6, 1, "N"))),
       ("ears", P(7, 2, Pt([(5, 0), (5, 1)], "N")))])
    M("crab", "animals", "🦀", "medium", 15, tr("Краб", "Krab", "Crab"),
      tr("Червоний краб з великими клешнями й очима на стебельцях.", "Czerwony krab z dużymi szczypcami i oczami na słupkach.", "A red crab with big claws and eyes on stalks."),
      [("legs", L(6, 4, R(1, 0, 4, 3, "R"), Pt([(0, 0), (0, 3), (5, 0), (5, 3)], "R"))),
       ("claws", L(6, 4, R(1, 0, 4, 3, "R"), Pt([(5, 0), (5, 3)], "M"))),
       ("eyes", L(6, 4, R(1, 1, 3, 2, "R"), Pt([(4, 1), (4, 2)], "W")), P(6, 4, Pt([(4, 1), (4, 2)], "K")))])
    M("parrot", "animals", "🦜", "medium", 15, tr("Папуга на гілці", "Papuga na gałęzi", "Parrot on a branch"),
      tr("Яскрава червона папуга з синім крилом.", "Jaskrawa czerwona papuga z niebieskim skrzydłem.", "A bright red parrot with a blue wing."),
      [("base", L(5, 2, R(0, 0, 4, 1, "N"))), ("body", L(5, 2, R(1, 0, 2, 1, "R"), R(0, 0, 0, 1, "B")), L(5, 2, R(1, 0, 2, 1, "R"), R(1, 0, 1, 1, "B"))),
       ("head", L(5, 2, R(1, 0, 2, 1, "R"), Pt([(3, 1)], "E")), P(5, 2, R(1, 0, 2, 1, "Y")))])

    # ───────────── NATURE ─────────────
    M("volcano", "nature", "🌋", "hard", 30, tr("Вулкан", "Wulkan", "Volcano"),
      tr("Вулкан, з кратера якого стікає гаряча лава.", "Wulkan, z którego krateru spływa gorąca lawa.", "A volcano with hot lava flowing from its crater."),
      [("base", L(9, 9, D(4, 4, 4.3, "Q"), Pt([(4, 8)], "O")), L(9, 9, D(4, 4, 3.6, "N"), Pt([(4, 7)], "O"))),
       ("walls", L(9, 9, D(4, 4, 3.0, "Q"), Pt([(4, 7), (5, 6)], "O")), L(9, 9, D(4, 4, 2.3, "N"), Pt([(4, 6)], "O"))),
       ("lava", L(9, 9, D(4, 4, 1.6, "Q"), D(4, 4, .8, "O")), P(9, 9, D(4, 4, .8, "R")))])
    TRUNK = R(3, 3, 4, 4, "N")
    M("treehouse", "nature", "🏡", "expert", 50, tr("Будиночок на дереві", "Domek na drzewie", "Treehouse"),
      tr("Дерев'яний будиночок на великому дубі з драбиною та червоним дахом.", "Drewniany domek na dużym dębie z drabinką i czerwonym dachem.", "A wooden house on a big oak, with a ladder and a red roof."),
      [("ground", P(8, 8, R(0, 0, 7, 7, "G"))),
       ("trunk", L(8, 8, TRUNK, Pt([(3, 5)], "E")), L(8, 8, TRUNK, Pt([(3, 5)], "E")), L(8, 8, TRUNK, Pt([(3, 5)], "E"))),
       ("platform", P(8, 8, R(1, 1, 6, 6, "N"))),
       ("walls", L(8, 8, F(1, 1, 6, 6, "E"), TRUNK, Pt([(3, 6)], "N"), Pt([(6, 3)], "T")), L(8, 8, F(1, 1, 6, 6, "E"), TRUNK, Pt([(4, 6)], "T"), Pt([(6, 4)], "T"))),
       ("roof", L(8, 8, R(1, 1, 6, 6, "M")), L(8, 8, R(2, 1, 5, 6, "M"))),
       ("crown", L(8, 8, R(0, 0, 7, 3, "L"), R(0, 0, 2, 7, "L")), L(8, 8, R(0, 0, 4, 2, "G"), R(0, 0, 1, 4, "G")), L(8, 8, R(0, 0, 2, 1, "L")))])
    M("flowerbed", "nature", "🌷", "medium", 15, tr("Клумба", "Rabatka", "Flower bed"),
      tr("Дерев'яна клумба з чотирма різнокольоровими квітами.", "Drewniana rabatka z czterema kolorowymi kwiatami.", "A wooden planter with four colourful flowers."),
      [("pot", L(6, 4, R(0, 0, 5, 3, "N")), P(6, 4, R(0, 0, 5, 3, "N"))), ("stem", L(6, 4, Pt([(1, 1), (3, 1), (2, 2), (4, 2)], "G"))),
       ("petals", L(6, 4, Pt([(1, 1)], "R"), Pt([(3, 1)], "Y"), Pt([(2, 2)], "P"), Pt([(4, 2)], "V"))),
       ("top", P(6, 4, Pt([(1, 1), (2, 2), (4, 2)], "Y"), Pt([(3, 1)], "O")))])

    # ───────────── SPACE ─────────────
    M("spacestation", "space", "🛰️", "expert", 50, tr("Космічна станція", "Stacja kosmiczna", "Space station"),
      tr("Орбітальна станція з модулями, фермою і сонячними панелями.", "Stacja orbitalna z modułami, kratownicą i panelami słonecznymi.", "An orbital station with modules, a truss and solar panels."),
      [("truss", L(12, 7, R(0, 3, 11, 3, "S"), R(4, 2, 7, 4, "W"))),
       ("panels", P(12, 7, R(0, 0, 2, 6, "A"), R(9, 0, 11, 6, "A"), R(0, 3, 2, 3, "S"), R(9, 3, 11, 3, "S"), R(3, 3, 8, 3, "S"), R(4, 2, 7, 4, "S"))),
       ("habitat", L(12, 7, R(5, 2, 6, 4, "W"), Pt([(7, 3)], "T"))), ("dome", P(12, 7, R(5, 2, 6, 4, "T")))])
    M("shuttle", "space", "🚀", "hard", 35, tr("Космічний шатл", "Wahadłowiec", "Space shuttle"),
      tr("Білий шатл з чорним носом, трикутними крилами і хвостом.", "Biały wahadłowiec z czarnym nosem, trójkątnymi skrzydłami i statecznikiem.", "A white shuttle with a black nose, delta wings and a tail fin."),
      [("wings", L(10, 7, R(0, 2, 9, 4, "W"), R(2, 0, 6, 1, "W"), R(2, 5, 6, 6, "W"), R(6, 0, 6, 1, "K"), R(6, 5, 6, 6, "K"), R(9, 2, 9, 4, "K"), R(0, 2, 0, 4, "Q"))),
       ("body", L(10, 7, R(0, 2, 7, 4, "W"), R(8, 2, 8, 4, "T"))), ("tail", L(10, 7, R(0, 3, 1, 3, "W")), L(10, 7, Pt([(0, 3)], "W")))])
    M("marsbase", "space", "🔴", "hard", 35, tr("База на Марсі", "Baza na Marsie", "Mars base"),
      tr("Житловий купол, модуль із сонячними панелями й антена на червоній планеті.", "Kopuła mieszkalna, moduł z panelami i antena na czerwonej planecie.", "A habitat dome, a module with solar panels and an antenna on the red planet."),
      [("ground", P(10, 8, R(0, 0, 9, 7, "M"))),
       ("habitat", L(10, 8, D(3, 3, 2.4, "W"), R(6, 2, 8, 4, "S"), R(6, 6, 8, 7, "A")), L(10, 8, D(3, 3, 2.4, "W"), R(6, 2, 8, 4, "S"), Pt([(8, 2)], "K"))),
       ("dome", L(10, 8, D(3, 3, 1.8, "T"), Pt([(8, 2)], "K")), L(10, 8, D(3, 3, .9, "T"), Pt([(8, 2)], "W")))])
    Q4 = lambda a, b, c, d: [R(1, 1, 2, 2, a), R(3, 1, 4, 2, b), R(1, 3, 2, 4, c), R(3, 3, 4, 4, d)]
    M("megarocket", "space", "🌕", "expert", 55, tr("Місячна ракета", "Rakieta księżycowa", "Moon rocket"),
      tr("Висока триступенева ракета з капсулою і рятувальною вежею.", "Wysoka trzystopniowa rakieta z kapsułą i wieżą ratunkową.", "A tall three-stage rocket with a capsule and an escape tower."),
      [("engines", L(6, 6, Pt([(1, 1), (4, 1), (1, 4), (4, 4)], "Q"), R(2, 2, 3, 3, "K"))),
       ("stage", L(6, 6, R(1, 1, 4, 4, "W"), R(0, 2, 0, 3, "R"), R(5, 2, 5, 3, "R")), L(6, 6, *Q4("W", "K", "K", "W")), L(6, 6, R(1, 1, 4, 4, "W")), L(6, 6, R(1, 1, 4, 4, "W"))),
       ("tier", L(6, 6, R(1, 1, 4, 4, "Q")), L(6, 6, R(2, 2, 3, 3, "W")), L(6, 6, R(2, 2, 3, 3, "W")), L(6, 6, R(2, 2, 3, 3, "K"))),
       ("capsule", L(6, 6, R(2, 2, 3, 3, "W")), L(6, 6, R(2, 2, 3, 3, "S"))), ("top", L(6, 6, Pt([(2, 2)], "R")), L(6, 6, Pt([(2, 2)], "R")))])

    # ───────────── BUILDINGS ─────────────
    def house_walls(fr):
        return [F(0, 0, 5, 4, "W"), F(6, 0, 9, 3, "E")] + fr
    M("bighouse", "buildings", "🏘️", "expert", 55, tr("Двоповерховий будинок", "Dom piętrowy", "Two-storey house"),
      tr("Великий будинок з гаражем, вікнами на двох поверхах і димарем.", "Duży dom z garażem, oknami na dwóch piętrach i kominem.", "A big house with a garage, windows on two floors and a chimney."),
      [("ground", P(10, 6, R(0, 0, 9, 5, "G"), R(7, 4, 9, 5, "S"))),
       ("walls", L(10, 6, *house_walls([Pt([(2, 4)], "N"), R(7, 3, 8, 3, "S")])), L(10, 6, *house_walls([Pt([(2, 4)], "N"), Pt([(4, 4), (5, 2)], "T"), R(7, 3, 8, 3, "S")]))),
       ("garage", L(10, 6, F(0, 0, 5, 4, "W"), R(6, 0, 9, 3, "M"))),
       ("floor", L(10, 6, F(0, 0, 5, 4, "W"), Pt([(1, 4), (3, 4), (5, 2)], "T")), L(10, 6, F(0, 0, 5, 4, "W"), Pt([(1, 4), (3, 4), (5, 2)], "T"))),
       ("roof", L(10, 6, R(0, 0, 5, 4, "M")), L(10, 6, R(0, 1, 5, 3, "M"), Pt([(4, 1)], "S")), L(10, 6, R(0, 2, 5, 2, "M"), Pt([(4, 1)], "S")))])
    FS = lambda front: [F(0, 0, 9, 4, "R"), Row(4, 0, front)]
    M("firestation", "buildings", "🚒", "expert", 50, tr("Пожежна частина", "Remiza strażacka", "Fire station"),
      tr("Червона пожежна частина з двома воротами й оглядовою вежею.", "Czerwona remiza z dwiema bramami i wieżą obserwacyjną.", "A red fire station with two garage doors and a lookout tower."),
      [("base", P(10, 5, R(0, 0, 9, 4, "S"))),
       ("walls", L(10, 5, *FS("RRWWRWWRRR")), L(10, 5, *FS("RRWWRWWRRR")), L(10, 5, *FS("RRTTRTTRYR"))),
       ("roof", L(10, 5, R(0, 0, 9, 4, "Q"), R(8, 0, 9, 1, "R"))),
       ("tower", L(10, 5, R(8, 0, 9, 1, "R"), Pt([(9, 1)], "T"), Pt([(4, 2)], "B")), L(10, 5, R(8, 0, 9, 1, "R"), Pt([(9, 1)], "T")), L(10, 5, R(8, 0, 9, 1, "Q"))),
       ("details", P(10, 5, Pt([(8, 0)], "Y")))])
    AW = "".join("R" if x % 2 == 0 else "W" for x in range(7))
    M("cafe", "buildings", "☕", "hard", 30, tr("Кав'ярня", "Kawiarnia", "Café"),
      tr("Затишна кав'ярня зі смугастою маркізою та столиком на терасі.", "Przytulna kawiarnia z pasiastą markizą i stolikiem na tarasie.", "A cosy café with a striped awning and a table outside."),
      [("base", P(7, 5, R(0, 0, 6, 4, "S"), R(0, 4, 6, 4, "E"))),
       ("walls", L(7, 5, F(0, 0, 6, 3, "E"), Pt([(1, 3)], "N"), R(3, 3, 5, 3, "T"), Pt([(3, 4)], "W")), L(7, 5, F(0, 0, 6, 3, "E"), R(3, 3, 5, 3, "T"))),
       ("awning", L(7, 5, R(0, 0, 6, 2, "E"), Row(3, 0, AW), Row(4, 0, AW))), ("details", L(7, 5, R(0, 0, 6, 2, "E"), R(2, 2, 4, 2, "Y"))),
       ("roof", P(7, 5, R(0, 0, 6, 2, "Q")))])
    SC = lambda front: [F(0, 0, 9, 3, "Y"), Row(3, 0, front)]
    M("school", "buildings", "🏫", "hard", 40, tr("Школа", "Szkoła", "School"),
      tr("Жовта двоповерхова школа з годинником і синьо-жовтим прапором.", "Żółta dwupiętrowa szkoła z zegarem i niebiesko-żółtą flagą.", "A yellow two-storey school with a clock and a blue-and-yellow flag."),
      [("base", P(10, 5, R(0, 0, 9, 4, "G"))),
       ("walls", L(10, 5, *SC("YTTYNNYTTY")), L(10, 5, *SC("YTTYNNYTTY"))),
       ("floor", L(10, 5, *SC("YTTYYYYTTY")), L(10, 5, *SC("YTTYTTYTTY"))),
       ("roof", L(10, 5, R(0, 0, 9, 3, "M")), L(10, 5, R(3, 0, 6, 3, "M"), R(4, 3, 5, 3, "W"), Pt([(0, 0)], "K")), L(10, 5, R(4, 1, 5, 2, "M"), Pt([(0, 0)], "K"), Pt([(1, 0)], "Y"))),
       ("flag", L(10, 5, Pt([(0, 0)], "K"), Pt([(1, 0)], "B")))])
    SILO = R(6, 0, 7, 1, "S")
    M("barn", "buildings", "🐄", "hard", 35, tr("Ферма з силосом", "Stodoła z silosem", "Barn with a silo"),
      tr("Червоний хлів з горищем, сіра силосна вежа і тюк сіна.", "Czerwona stodoła ze strychem, szary silos i bela siana.", "A red barn with a loft, a grey silo and a hay bale."),
      [("ground", P(8, 6, R(0, 0, 7, 5, "G"))),
       ("walls", L(8, 6, F(0, 0, 5, 4, "R"), R(2, 4, 3, 4, "W"), SILO, R(6, 3, 7, 4, "Y")), L(8, 6, F(0, 0, 5, 4, "R"), R(2, 4, 3, 4, "W"), SILO)),
       ("silo", L(8, 6, F(0, 0, 5, 4, "R"), R(2, 4, 3, 4, "N"), SILO)),
       ("roof", L(8, 6, R(0, 0, 5, 4, "Q"), SILO), L(8, 6, R(0, 1, 5, 3, "Q"), SILO), L(8, 6, R(0, 2, 5, 2, "Q"), SILO), L(8, 6, R(6, 0, 7, 1, "Q")))])

    # ───────────── ROBOTS ─────────────
    M("robotarm", "robots", "🦾", "medium", 20, tr("Маніпулятор", "Ramię robota", "Robot arm"),
      tr("Помаранчевий промисловий маніпулятор із захватом.", "Pomarańczowe ramię przemysłowe z chwytakiem.", "An orange factory robot arm with a gripper."),
      [("base", L(6, 4, R(0, 0, 3, 3, "Q"))), ("body", L(6, 4, R(1, 1, 2, 2, "O")), L(6, 4, R(1, 1, 2, 2, "O"))),
       ("arms", L(6, 4, R(1, 1, 3, 2, "Y")), L(6, 4, R(2, 1, 4, 2, "Y"), Pt([(5, 1), (5, 2)], "K")), L(6, 4, R(3, 1, 5, 2, "Y")))])
    ARM = lambda c: [R(0, 0, 0, 1, c), R(7, 0, 7, 1, c)]
    M("megarobot", "robots", "🤖", "expert", 55, tr("Гігантський робот", "Gigantyczny robot", "Giant robot"),
      tr("Великий робот-охоронець із сяючим ядром і візором.", "Wielki robot-strażnik ze świecącym rdzeniem i wizjerem.", "A huge guardian robot with a glowing core and a visor."),
      [("feet", L(8, 3, R(1, 0, 2, 2, "Q"), R(5, 0, 6, 2, "Q"))),
       ("legs", L(8, 2, R(1, 0, 2, 1, "B"), R(5, 0, 6, 1, "B")), L(8, 2, R(1, 0, 2, 1, "S"), R(5, 0, 6, 1, "S")), L(8, 2, R(1, 0, 2, 1, "B"), R(5, 0, 6, 1, "B"), *ARM("Q"))),
       ("hips", L(8, 2, R(1, 0, 6, 1, "Q"), *ARM("S"))),
       ("torso", L(8, 2, R(1, 0, 6, 1, "W"), Pt([(3, 1), (4, 1)], "C"), *ARM("S")), L(8, 2, R(0, 0, 7, 1, "W"), Pt([(3, 1), (4, 1)], "R"))),
       ("shoulders", L(8, 2, R(0, 0, 7, 1, "W"), R(0, 0, 1, 1, "R"), R(6, 0, 7, 1, "R"))),
       ("head", L(8, 2, R(3, 0, 4, 1, "W")), L(8, 2, R(3, 0, 4, 0, "W"), R(3, 1, 4, 1, "C")), P(8, 2, R(3, 0, 4, 1, "R"))),
       ("antenna", L(8, 2, Pt([(3, 0)], "K")))])
    M("spiderbot", "robots", "🕷️", "hard", 30, tr("Робот-павук", "Robot-pająk", "Spider robot"),
      tr("Вісьмилапий робот-розвідник з червоними сенсорами.", "Ośmionożny robot zwiadowczy z czerwonymi czujnikami.", "An eight-legged scout robot with red sensors."),
      [("feet", L(9, 7, Pt([(0, 0), (0, 2), (0, 4), (0, 6), (8, 0), (8, 2), (8, 4), (8, 6)], "Q"))),
       ("legs", L(9, 7, Pt([(1, 0), (1, 2), (1, 4), (1, 6), (7, 0), (7, 2), (7, 4), (7, 6)], "Q")),
                L(9, 7, Pt([(2, 1), (2, 3), (2, 5), (6, 1), (6, 3), (6, 5)], "S"), R(3, 1, 5, 5, "S"))),
       ("body", L(9, 7, R(3, 1, 5, 5, "Q"), Pt([(3, 5), (5, 5)], "R"))), ("sensor", P(9, 7, R(3, 2, 5, 4, "S"), Pt([(4, 3)], "R")))])

    # ───────────── FANTASY ─────────────
    MA = lambda: Pt([(4, 1), (8, 1)], "N")
    SAIL = lambda r0=0, r1=3: [R(5, r0, 5, r1, "W"), R(9, r0, 9, r1, "W")]
    M("pirateship", "fantasy", "🏴‍☠️", "expert", 60, tr("Піратський корабель", "Statek piracki", "Pirate ship"),
      tr("Дерев'яний корабель з гарматами, двома щоглами й чорним прапором.", "Drewniany statek z armatami, dwoma masztami i czarną flagą.", "A wooden ship with cannons, two masts and a black flag."),
      [("hull", L(12, 4, R(2, 1, 9, 2, "N")), L(12, 4, R(1, 0, 10, 3, "N"), Pt([(3, 3), (6, 3), (9, 3)], "K")), L(12, 4, R(0, 0, 11, 3, "N"), R(1, 3, 10, 3, "Y"))),
       ("deck", P(12, 4, R(0, 0, 11, 3, "E"))),
       ("cabin", L(12, 4, R(0, 0, 2, 3, "N"), MA()), L(12, 4, R(0, 0, 2, 3, "N"), Pt([(2, 3)], "Y"), MA(), *SAIL())),
       ("sail", L(12, 4, MA(), *SAIL(), Pt([(5, 2)], "K")), L(12, 4, MA(), *SAIL(1, 2)), L(12, 4, MA())),
       ("flag", P(12, 4, Pt([(4, 1), (5, 1)], "K")))])
    TW = [R(0, 0, 1, 1, "Q"), R(8, 0, 9, 1, "Q"), R(0, 8, 1, 9, "Q"), R(8, 8, 9, 9, "Q")]
    KEEP = R(3, 3, 6, 6, "S")

    def merlons(x0, y0, x1, y1, c):
        def op(g):
            for y in range(y0, y1 + 1):
                for x in range(x0, x1 + 1):
                    if (x in (x0, x1) or y in (y0, y1)) and (x + y) % 2 == 0:
                        g[y][x] = c
        return op
    M("fortress", "fantasy", "🏰", "expert", 60, tr("Фортеця", "Twierdza", "Fortress"),
      tr("Мурована фортеця з чотирма вежами, брамою й донжоном у центрі.", "Murowana twierdza z czterema wieżami, bramą i donżonem pośrodku.", "A stone fortress with four towers, a gate and a keep in the middle."),
      [("ground", P(10, 10, R(0, 0, 9, 9, "G"))),
       ("walls", L(10, 10, F(1, 1, 8, 8, "S"), R(4, 8, 5, 8, "N"), *TW, KEEP), L(10, 10, F(1, 1, 8, 8, "S"), R(4, 8, 5, 8, "N"), *TW, KEEP)),
       ("gate", L(10, 10, F(1, 1, 8, 8, "S"), *TW, KEEP, Pt([(6, 4)], "K"))),
       ("battlements", L(10, 10, merlons(1, 1, 8, 8, "S"), *TW, KEEP)),
       ("keep", L(10, 10, *TW, KEEP), L(10, 10, Pt([(0, 0), (1, 1), (9, 0), (8, 1), (0, 9), (1, 8), (9, 9), (8, 8)], "M"), merlons(3, 3, 6, 6, "S"), Pt([(4, 4)], "K"))),
       ("flag", P(10, 10, Pt([(4, 4), (5, 4)], "R")))])

    # ───────────── FOOD ─────────────
    def frosted(r, body, rim, cx=4, cy=4):
        return [D(cx, cy, r, rim), D(cx, cy, r - .9, body)]
    M("tiercake", "food", "🎂", "hard", 30, tr("Триярусний торт", "Tort trzypiętrowy", "Three-tier cake"),
      tr("Святковий торт з трьох ярусів зі свічками.", "Świąteczny tort z trzech pięter ze świeczkami.", "A celebration cake with three tiers and candles."),
      [("base", P(9, 9, D(4, 4, 4.4, "S"))), ("layer", L(9, 9, D(4, 4, 4, "P")), L(9, 9, *frosted(4, "P", "W"))),
       ("tier", L(9, 9, D(4, 4, 3, "W")), L(9, 9, *frosted(3, "W", "V"))), ("top", L(9, 9, D(4, 4, 2, "P")), P(9, 9, D(4, 4, 2, "W"))),
       ("candle", L(9, 9, Pt([(3, 3), (5, 5)], "W")), P(9, 9, Pt([(3, 3), (5, 5)], "O")))])
    M("sushi", "food", "🍣", "easy", 10, tr("Набір суші", "Zestaw sushi", "Sushi set"),
      tr("Роли й нігірі на чорній таці з васабі.", "Rolki i nigiri na czarnej tacy z wasabi.", "Rolls and nigiri on a black tray with wasabi."),
      [("tray", P(6, 3, R(0, 0, 5, 2, "K"))), ("rolls", L(6, 3, R(1, 0, 3, 0, "K"), R(1, 2, 2, 2, "W"), Pt([(4, 2)], "W"), Pt([(5, 0)], "L"))),
       ("toppings", P(6, 3, Pt([(1, 0)], "O"), Pt([(2, 0)], "R"), Pt([(3, 0)], "L"), R(1, 2, 2, 2, "O"), Pt([(4, 2)], "R")))])

    # ───────────── HOME ─────────────
    M("aquarium", "home", "🐟", "medium", 20, tr("Акваріум", "Akwarium", "Aquarium"),
      tr("Скляний акваріум на тумбі з водоростями й рибками.", "Szklane akwarium na szafce z roślinami i rybkami.", "A glass aquarium on a stand with plants and fish."),
      [("stand", L(6, 3, R(0, 0, 5, 2, "N")), P(6, 3, R(0, 0, 5, 2, "K"))),
       ("glass", L(6, 3, R(0, 0, 5, 2, "T"), Row(2, 0, "TGTOTT")), L(6, 3, R(0, 0, 5, 2, "T"), Row(2, 0, "TGTTYT"))),
       ("lid", P(6, 3, R(0, 0, 5, 2, "K")))])
    M("piano", "home", "🎹", "medium", 20, tr("Піаніно з банкеткою", "Pianino z ławką", "Piano with a bench"),
      tr("Чорне піаніно з клавішами й дерев'яна банкетка.", "Czarne pianino z klawiszami i drewniana ławka.", "A black upright piano with keys and a wooden bench."),
      [("legs", L(6, 5, R(0, 0, 5, 1, "K"), Pt([(0, 2), (5, 2)], "K"), Pt([(2, 4), (3, 4)], "N"))),
       ("keys", L(6, 5, R(0, 0, 5, 1, "K"), Row(2, 0, "WWWWWW"), R(2, 4, 3, 4, "N"))),
       ("body", L(6, 5, R(0, 0, 5, 1, "K")), L(6, 5, R(0, 0, 5, 0, "K"))), ("top", P(6, 5, R(0, 0, 5, 0, "K")))])
    POSTS = Pt([(0, 0), (5, 0), (0, 2), (5, 2)], "N")
    M("bunkbed", "home", "🛏️", "medium", 22, tr("Двоповерхове ліжко", "Łóżko piętrowe", "Bunk bed"),
      tr("Двоярусне ліжко з драбинкою, синьою й червоною ковдрами.", "Łóżko piętrowe z drabinką, niebieską i czerwoną kołdrą.", "A bunk bed with a ladder and blue and red blankets."),
      [("legs", L(6, 3, POSTS)), ("bunk", L(6, 3, R(0, 0, 5, 2, "N")), L(6, 3, *[Row(y, 0, "NWBBBN") for y in range(3)])),
       ("ladder", L(6, 3, POSTS, Pt([(5, 1)], "E")), L(6, 3, POSTS, Pt([(5, 1)], "E"))),
       ("bed" if False else "bunk", L(6, 3, R(0, 0, 5, 2, "N")), L(6, 3, *[Row(y, 0, "NWRRRN") for y in range(3)])),
       ("rails2", L(6, 3, R(0, 0, 5, 0, "N"), Pt([(0, 2), (5, 2)], "N")))])

    # ───────────── HOLIDAYS ─────────────
    M("gingerbread", "holidays", "🍪", "hard", 30, tr("Пряниковий будиночок", "Domek z piernika", "Gingerbread house"),
      tr("Пряниковий будиночок з глазур'ю, цукерками й сніжним дахом.", "Piernikowy domek z lukrem, cukierkami i śnieżnym dachem.", "A gingerbread house with icing, candy and a snowy roof."),
      [("base", P(6, 5, R(0, 0, 5, 4, "W"))),
       ("walls", L(6, 5, F(0, 0, 5, 3, "N"), Row(3, 0, "NNRNPN")), L(6, 5, F(0, 0, 5, 3, "N"), Row(3, 0, "NTRNTN"))),
       ("icing", L(6, 5, R(0, 0, 5, 3, "N"), R(0, 3, 5, 3, "W"))),
       ("roof", L(6, 5, R(0, 0, 5, 3, "W"), Pt([(1, 3)], "R"), Pt([(4, 3)], "L")), L(6, 5, R(0, 1, 5, 2, "W"), Pt([(4, 1)], "R"))),
       ("candy", P(6, 5, R(0, 1, 5, 2, "P"), Pt([(4, 1)], "R")))])
    ORN = ["R", "Y", "B", "W"]
    M("bigtree", "holidays", "🎄", "expert", 45, tr("Велика ялинка з подарунками", "Duża choinka z prezentami", "Big tree with gifts"),
      tr("Висока ялинка з кульками, зіркою й подарунками під нею.", "Wysoka choinka z bombkami, gwiazdą i prezentami pod spodem.", "A tall tree with baubles, a star and gifts underneath."),
      [("base", P(9, 9, D(4, 4, 4.4, "W"))), ("gifts", L(9, 9, Pt([(4, 4)], "N"), R(1, 6, 2, 7, "R"), R(6, 6, 7, 7, "B"), R(6, 1, 7, 2, "Y"))),
       ("crown", L(9, 9, D(4, 4, 4, "D"), Edge("R", 3, 0, ORN)), L(9, 9, D(4, 4, 3.4, "D"), Edge("Y", 4, 1, ORN)), L(9, 9, D(4, 4, 3.4, "G"))),
       ("ornaments", L(9, 9, D(4, 4, 2.6, "D"), Edge("R", 3, 2, ORN)), L(9, 9, D(4, 4, 2.2, "G")), L(9, 9, D(4, 4, 1.6, "D"), Edge("Y", 3, 0, ORN))),
       ("top", L(9, 9, D(4, 4, 1, "G")), L(9, 9, Pt([(4, 4)], "D"))), ("star", P(9, 9, Pt([(4, 4)], "Y")))])
    M("easteregg", "holidays", "🥚", "medium", 18, tr("Писанка", "Pisanka", "Painted egg"),
      tr("Велике яйце з кольоровими смужками на підставці.", "Duże jajko w kolorowe paski na podstawce.", "A big egg with colourful stripes on a stand."),
      [("stand", P(5, 5, D(2, 2, 2.2, "E"))), ("stripes", L(5, 5, D(2, 2, 1.5, "C")), L(5, 5, D(2, 2, 2.2, "P")), L(5, 5, D(2, 2, 2.2, "Y"))),
       ("top", L(5, 5, D(2, 2, 2.2, "L")), L(5, 5, D(2, 2, 1.6, "C")), L(5, 5, D(2, 2, 1.1, "P")), P(5, 5, Pt([(2, 2)], "Y")))])

    # ───────────── LANDMARKS ─────────────
    M("pyramid", "landmarks", "🔺", "hard", 35, tr("Піраміда", "Piramida", "Pyramid"),
      tr("Давня кам'яна піраміда серед піску з темним входом.", "Starożytna kamienna piramida na piasku z ciemnym wejściem.", "An ancient stone pyramid in the sand with a dark entrance."),
      [("ground", P(9, 9, R(0, 0, 8, 8, "Y"))), ("entrance", L(9, 9, R(0, 0, 8, 8, "E"), Pt([(4, 8)], "K")), L(9, 9, R(1, 1, 7, 7, "E"))),
       ("walls", L(9, 9, R(2, 2, 6, 6, "E")), L(9, 9, R(3, 3, 5, 5, "E"))), ("top", L(9, 9, Pt([(4, 4)], "E")), P(9, 9, Pt([(4, 4)], "Y")))])
    M("pagoda", "landmarks", "🏯", "expert", 50, tr("Пагода", "Pagoda", "Pagoda"),
      tr("Східна пагода з трьома ярусами вигнутих карнизів і золотим шпилем.", "Wschodnia pagoda z trzema piętrami okapów i złotą iglicą.", "An eastern pagoda with three tiers of eaves and a golden spire."),
      [("base", P(9, 9, R(0, 0, 8, 8, "S"))),
       ("walls", L(9, 9, R(2, 2, 6, 6, "M"), Pt([(4, 6)], "N")), L(9, 9, R(2, 2, 6, 6, "M"), Pt([(6, 4)], "Y"))),
       ("eaves", L(9, 9, R(1, 1, 7, 7, "D"))), ("tier", L(9, 9, R(3, 3, 5, 5, "M")), L(9, 9, R(2, 2, 6, 6, "D"))),
       ("top", L(9, 9, Pt([(4, 4)], "M")), L(9, 9, R(3, 3, 5, 5, "D"))), ("spire", L(9, 9, Pt([(4, 4)], "Y")), P(9, 9, Pt([(4, 4)], "Y")))])
    TWR = R(1, 1, 3, 3, "E")
    M("clocktower", "landmarks", "🕰️", "expert", 45, tr("Годинникова вежа", "Wieża zegarowa", "Clock tower"),
      tr("Висока кам'яна вежа з циферблатами й гострим синім шпилем.", "Wysoka kamienna wieża z tarczami zegara i spiczastą niebieską iglicą.", "A tall stone tower with clock faces and a pointed blue spire."),
      [("base", P(5, 5, R(0, 0, 4, 4, "S"))),
       ("tower", L(5, 5, TWR, Pt([(2, 3)], "N")), L(5, 5, TWR, Pt([(2, 3)], "N")), L(5, 5, TWR, Pt([(2, 3), (3, 2)], "T")),
                 L(5, 5, TWR), L(5, 5, TWR, Pt([(2, 3), (3, 2)], "T")), L(5, 5, TWR)),
       ("clock", L(5, 5, TWR, Pt([(2, 3), (3, 2)], "W")), L(5, 5, TWR, Pt([(2, 3), (3, 2)], "W"))),
       ("roof", L(5, 5, R(1, 1, 3, 3, "Q")), L(5, 5, R(1, 1, 3, 3, "A"))),
       ("spire", L(5, 5, Pt([(2, 2)], "A")), L(5, 5, Pt([(2, 2)], "A")), P(5, 5, Pt([(2, 2)], "Y")))])
    CORN = lambda d: Pt([(d, d), (8 - d, d), (d, 8 - d), (8 - d, 8 - d)], "Q")
    M("latticetower", "landmarks", "🗼", "expert", 50, tr("Ажурна вежа", "Ażurowa wieża", "Lattice tower"),
      tr("Металева вежа на чотирьох опорах із двома оглядовими майданчиками.", "Metalowa wieża na czterech nogach z dwoma tarasami widokowymi.", "A metal tower on four legs with two viewing decks."),
      [("pillars2", L(9, 9, R(0, 0, 1, 1, "Q"), R(7, 0, 8, 1, "Q"), R(0, 7, 1, 8, "Q"), R(7, 7, 8, 8, "Q")),
                    L(9, 9, R(1, 1, 2, 2, "Q"), R(6, 1, 7, 2, "Q"), R(1, 6, 2, 7, "Q"), R(6, 6, 7, 7, "Q"))),
       ("platform", P(9, 9, F(1, 1, 7, 7, "Q"))),
       ("tower", L(9, 9, CORN(2)), L(9, 9, CORN(3))), ("platform", P(9, 9, F(3, 3, 5, 5, "Q"))),
       ("top", L(9, 9, CORN(3)), L(9, 9, R(4, 3, 4, 5, "Q"), R(3, 4, 5, 4, "Q")), L(9, 9, Pt([(4, 4)], "Q")), L(9, 9, Pt([(4, 4)], "Q"))),
       ("antenna", L(9, 9, Pt([(4, 4)], "Q")), P(9, 9, Pt([(4, 4)], "S")))])
    CROSS = lambda c: [R(2, 0, 6, 8, c), R(0, 2, 8, 6, c)]
    ARMS = [(4, 1), (4, 7), (1, 4), (7, 4)]
    M("cathedral", "landmarks", "⛪", "expert", 60, tr("Собор із банями", "Sobór z kopułami", "Domed cathedral"),
      tr("Білий хрестовий собор із зеленим дахом і золотими банями.", "Biały sobór na planie krzyża z zielonym dachem i złotymi kopułami.", "A white cross-shaped cathedral with a green roof and golden domes."),
      [("base", P(9, 9, R(0, 0, 8, 8, "S"))),
       ("walls", L(9, 9, *CROSS("W"), Pt([(4, 8)], "N")), L(9, 9, *CROSS("W"), Pt([(4, 8)], "N"), Pt([(8, 4)], "T")), L(9, 9, *CROSS("W"), Pt([(4, 8), (8, 4)], "T"))),
       ("roof", L(9, 9, *CROSS("D"))),
       ("drum", L(9, 9, R(3, 3, 5, 5, "W"), Pt(ARMS, "W")), L(9, 9, R(3, 3, 5, 5, "W"), Pt([(5, 4), (4, 5)], "T"), Pt(ARMS, "Y"))),
       ("dome", L(9, 9, R(3, 3, 5, 5, "Y")), L(9, 9, R(4, 3, 4, 5, "Y"), R(3, 4, 5, 4, "Y")), L(9, 9, Pt([(4, 4)], "Y"))),
       ("spire", L(9, 9, Pt([(4, 4)], "Y")), P(9, 9, Pt([(4, 4)], "Y")))])

    def arch_row(offset):
        """Dark arches on the outer wall only, every other cell."""
        def op(g):
            for y in range(len(g)):
                for x in range(len(g[0])):
                    if g[y][x] != "." and ((x - 5.5) / 5.8) ** 2 + ((y - 4.5) / 4.8) ** 2 > .62 and (x + y + offset) % 2 == 0:
                        g[y][x] = "Q"
        return op

    def arena_ring(arches, half=False):
        ops = [E(5.5, 4.5, 5.8, 4.8, "E", 4.0, 3.0)]
        if arches:
            ops.append(arch_row(arches))
        if half:
            ops.append(R(6, 0, 11, 9, "."))
        return ops
    M("arena", "landmarks", "🏟️", "expert", 55, tr("Античний амфітеатр", "Antyczny amfiteatr", "Ancient arena"),
      tr("Овальний амфітеатр з рядами арок і напівзруйнованою стіною.", "Owalny amfiteatr z rzędami łuków i częściowo zburzonym murem.", "An oval amphitheatre with rows of arches and a half-ruined wall."),
      [("ground", P(12, 10, E(5.5, 4.5, 5.8, 4.8, "E"), E(5.5, 4.5, 4.0, 3.0, "Y"))),
       ("arches", L(12, 10, *arena_ring(1)), L(12, 10, *arena_ring(0))),
       ("walls", L(12, 10, *arena_ring(2)), L(12, 10, *arena_ring(0))), ("top", L(12, 10, *arena_ring(1, half=True)))])
