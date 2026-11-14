#!/usr/bin/env python3
"""Маски вместо фотографий — для открытой версии игры (GitHub).

В игре у четырёх легенд (Пивозавр, Главный, Недопонятый гений, DJ Клима) лицо — фото
настоящего человека. Фото не распространяются по GPL, поэтому в открытой версии вместо
них — нарисованные маски в том же формате (44×58, PNG в base64 внутри .gd) и с теми же
рамками. Скрипт рисует маски и пишет заготовки tools/public/faces/*_face.gd.txt; ими
подменяет файлы characters/*_face.gd скрипт tools/public/make_github_archive.sh.

Нужен Python 3 с Pillow:  python3 tools/public/make_masks.py [--preview маски.png]
"""
import base64, io, os, sys, textwrap
from PIL import Image

W, H = 22, 29            # рисуем «по клеточкам» вдвое мельче итоговой картинки 44×58


def rgb(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


class Art:
    def __init__(self, bg):
        self.im = Image.new("RGBA", (W, H), rgb(bg))
        self.px = self.im.load()

    def p(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.px[x, y] = rgb(c)

    def box(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.p(x, y, c)

    def blob(self, x0, y0, x1, y1, c, r=2):
        """Прямоугольник со срезанными углами (округлая форма из клеточек)."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                dx = min(x - x0, x1 - x)
                dy = min(y - y0, y1 - y)
                if dx + dy >= r:
                    self.p(x, y, c)

    def finish(self, outer, inner, round_corners=False):
        im = self.im.resize((W * 2, H * 2), Image.NEAREST)
        px = im.load()
        for y in range(H * 2):
            for x in range(W * 2):
                d = min(x, y, W * 2 - 1 - x, H * 2 - 1 - y)
                if d == 0:
                    px[x, y] = rgb(outer)
                elif d == 1:
                    px[x, y] = rgb(inner)
        if round_corners:
            for x, y in ((0, 0), (W * 2 - 1, 0), (0, H * 2 - 1), (W * 2 - 1, H * 2 - 1)):
                px[x, y] = (0, 0, 0, 0)
        return im


def pivo():
    """Пивозавр: маска динозавра — гребень, жёлтые глаза, зубастая пасть, пивная пена на носу."""
    a = Art("6b3a1e")
    for x in (5, 9, 13, 17):                       # гребень
        a.box(x - 1, 4, x, 6, "2e7d32")
        a.p(x - 1, 3, "2e7d32")
    a.blob(3, 6, 18, 25, "1b5e20", 3)              # контур головы
    a.blob(4, 7, 17, 24, "4caf50", 3)
    a.box(4, 7, 17, 8, "66bb6a")                   # блик на лбу
    a.blob(5, 15, 16, 23, "8bd46a", 2)             # морда
    for x0 in (5, 13):                             # глаза с вертикальным зрачком
        a.box(x0, 10, x0 + 3, 13, "ffe04a")
        a.box(x0 + 1, 10, x0 + 2, 13, "1a1a1a")
        a.p(x0, 10, "fff6b0")
    a.box(4, 9, 8, 9, "1b5e20")                    # хмурые надбровья
    a.box(13, 9, 17, 9, "1b5e20")
    a.p(8, 16, "1b5e20")                           # ноздри
    a.p(13, 16, "1b5e20")
    a.box(7, 17, 14, 18, "fff8e1")                 # пена
    a.p(6, 18, "fff8e1"); a.p(15, 18, "fff8e1"); a.p(9, 19, "fff8e1")
    a.box(6, 20, 15, 21, "3b1f10")                 # пасть
    for x in range(6, 16, 2):                      # зубы
        a.p(x, 20, "ffffff")
        a.p(x + 1, 21, "ffffff")
    a.box(16, 22, 19, 26, "3b1f10")                # кружка
    a.box(17, 23, 18, 25, "ffb300")
    a.box(16, 21, 19, 22, "fff8e1")
    a.p(20, 23, "3b1f10"); a.p(20, 24, "3b1f10")
    return a.finish("ff8c14", "ff8c14", True)


def glav():
    """Главный: гладкая золотая маска с тёмными очками «за 23914$», ухмылка, воротник пальто."""
    a = Art("281446")
    a.blob(4, 3, 17, 9, "1b1024", 2)               # тёмные волосы назад
    a.blob(4, 5, 17, 24, "8a5a12", 3)              # контур маски
    a.blob(5, 6, 16, 23, "f5cf58", 3)
    a.box(13, 8, 16, 21, "d8a531")                 # тень справа
    a.box(6, 6, 11, 7, "fff2a8")                   # блик
    a.box(3, 11, 18, 11, "0c0c10")                 # очки: дужка
    a.blob(4, 11, 9, 15, "0c0c10", 1)
    a.blob(12, 11, 17, 15, "0c0c10", 1)
    a.box(10, 12, 11, 12, "0c0c10")
    a.p(5, 12, "9fd8ff"); a.p(6, 12, "ffffff"); a.p(13, 12, "9fd8ff")   # блики на стёклах
    a.p(18, 12, "ffd54a"); a.p(19, 13, "ffd54a"); a.box(19, 14, 20, 15, "ffd54a")   # ценник на дужке
    a.p(10, 17, "b98420")                          # нос
    a.box(8, 20, 12, 20, "6b4410")                 # ухмылка
    a.p(13, 19, "6b4410"); a.p(14, 18, "6b4410")
    a.box(3, 25, 18, 27, "1b1024")                 # воротник пальто со светящимся кантом
    a.box(3, 25, 18, 25, "be6eff")
    a.box(10, 25, 11, 27, "783cc8")
    return a.finish("be6eff", "783cc8")


def genius():
    """Недопонятый гений: голова-монитор с зелёным терминалом вместо лица, фиолетовый «глитч»."""
    a = Art("1c1c17")
    a.blob(2, 4, 19, 22, "55564e", 2)              # корпус монитора
    a.blob(3, 5, 18, 21, "9a9a90", 2)
    a.box(4, 6, 17, 20, "06140b")                  # экран
    for y in range(7, 20, 2):
        a.box(4, y, 17, y, "0a1d10")               # строки развёртки
    for x, y in ((6, 9), (7, 10), (8, 11), (7, 12), (6, 13)):   # глаз «>»
        a.p(x, y, "37f06a")
    a.box(11, 12, 15, 13, "37f06a")                # глаз-курсор «_»
    a.p(16, 12, "b6ffc8")
    for x in (6, 7, 9, 10, 12, 13, 15):            # рот — строка «кода»
        a.p(x, 17, "22b84e")
    a.p(8, 16, "22b84e"); a.p(14, 18, "22b84e")
    a.box(9, 23, 12, 25, "55564e")                 # ножка и подставка
    a.box(6, 26, 15, 26, "9a9a90")
    a.box(1, 8, 6, 8, "9628aa")                    # глитч: сдвинутые цветные полосы
    a.box(14, 15, 20, 15, "9628aa")
    a.box(15, 16, 20, 16, "781424")
    a.box(2, 19, 5, 19, "781424")
    a.p(17, 7, "ff4d6d"); a.p(4, 21, "5a146e")
    a.p(16, 22, "37f06a")                          # лампочка питания
    return a.finish("781424", "9628aa")


def dj():
    """DJ Клима: чёрный капюшон, неоновые глаза и эквалайзер вместо рта, нота на лбу, цепочка."""
    a = Art("2a0b49")
    a.blob(3, 3, 18, 27, "2a2a32", 4)              # капюшон
    a.blob(4, 4, 17, 27, "101014", 4)
    a.blob(5, 8, 16, 23, "05050a", 2)              # лицевая пластина
    a.box(10, 5, 10, 7, "ff46c8")                  # нота
    a.p(11, 5, "ff46c8"); a.box(9, 7, 10, 7, "ff46c8")
    a.box(6, 11, 9, 12, "3ce1ff")                  # глаза
    a.box(12, 11, 15, 12, "3ce1ff")
    a.p(6, 10, "3ce1ff"); a.p(15, 10, "3ce1ff")
    a.p(7, 11, "d8f8ff"); a.p(13, 11, "d8f8ff")
    bars = [(6, 2, "ff46c8"), (8, 4, "e85ad2"), (10, 6, "a98ae6"), (12, 3, "6fbaf4"), (14, 5, "3ce1ff")]
    for x, h, c in bars:                           # эквалайзер
        a.box(x, 21 - h, x + 1, 21, c)
    a.box(5, 22, 16, 22, "1c1c24")
    for x in range(7, 15):                         # цепочка
        a.p(x, 25 + (1 if x in (10, 11) else 0), "ffd54a")
    return a.finish("ff46c8", "3ce1ff")


FACES = {
    "pivo": ("PivoFace", "Маска Пивозавра", pivo),
    "glav": ("GlavFace", "Маска Главного", glav),
    "genius": ("GeniusFace", "Маска Недопонятого гения", genius),
    "dj": ("DjFace", "Маска DJ Климы", dj),
}

TEMPLATE = '''class_name {cls}
# ---------- {title} ----------
# Открытая версия игры: вместо фотографии — нарисованная маска ({doc})
# Картинка 44×58, PNG в base64 прямо в коде. Нарисована скриптом tools/public/make_masks.py
# и распространяется по той же лицензии, что и вся игра (GPL-3.0-or-later).

const PNG := (
{data}
)

static var _tex: ImageTexture

static func image() -> Image:
	var im := Image.new()
	im.load_png_from_buffer(Marshalls.base64_to_raw(PNG))
	return im

static func texture() -> ImageTexture:
	if _tex == null:
		_tex = ImageTexture.create_from_image(image())
	return _tex
'''

if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    sheet = Image.new("RGBA", (44 * 4 * 4 + 50, 58 * 4 + 20), (40, 40, 52, 255))
    for i, (name, (cls, title, fn)) in enumerate(FACES.items()):
        im = fn()
        buf = io.BytesIO()
        im.save(buf, "PNG", optimize=True)
        b64 = base64.b64encode(buf.getvalue()).decode()
        data = " +\n".join('\t"%s"' % chunk for chunk in textwrap.wrap(b64, 104))
        doc = fn.__doc__.strip().split(":", 1)[1].strip()
        # расширение .gd.txt — чтобы Godot не считал заготовку скриптом (иначе два класса с одним именем)
        with open(os.path.join(here, "faces", name + "_face.gd.txt"), "w", encoding="utf-8") as f:
            f.write(TEMPLATE.format(cls=cls, title=title, doc=doc, data=data))
        sheet.alpha_composite(im.resize((44 * 4, 58 * 4), Image.NEAREST), (10 + i * (44 * 4 + 10), 10))
        print(name, len(b64), "символов base64")
    if "--preview" in sys.argv:
        sheet.convert("RGB").save(sys.argv[sys.argv.index("--preview") + 1])
