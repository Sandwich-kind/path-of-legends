class_name RiftRig
extends Node2D
# ---------- «Модели» свиты Странника (волны 81–90) ----------
# Все последователи носят бледную маску с вертикальной щелью — знак Странника;
# в щели и в трещинах на теле светится сила разлома (фиолетовая).
#   rift_blade  — Отрёкшийся: капюшон, рваный шарф, два серпа;
#   rift_archer — Стрелок разлома: длинный плащ, арбалет, колчан светящихся болтов;
#   rift_caller — Призывательница: высокий ворот, мантия до земли, посох с осколком;
#   rift_brute  — Разрыватель: горбатый великан, правая рука — огромная латная длань;
#   rift_bearer — Носитель осколка: несёт на спине огромный кристалл разлома в цепях;
#   rift_spawn  — Порождение разлома: четвероногая тварь с шипами и светящейся пастью;
#   rift_eye    — Око разлома: парящий глаз в кольце осколков-зубов, щупальца;
#   voidwing    — Пустокрыл (мини-босс 85): огромный небесный скат с хвостом-кристаллом;
#   harbinger   — Предвестник (босс 90): маска с трещиной, венец осколков, глефа-разрыв.
# Части — маленькие пиксельные картинки (как у других моделей), растянутые без
# сглаживания. Анимации: ходьба, удар, выстрел, каст, рык, удар оземь, «шаг сквозь грань».

const KINDS := ["rift_blade", "rift_archer", "rift_caller", "rift_brute", "rift_bearer", "rift_spawn", "rift_eye",
		"voidwing", "harbinger", "rift_weaver", "wanderer"]
# Дворец Бездны (волны 96–100):
#   rift_weaver — Ткачиха Разлома (мини-босс 99): высокий ворот-рога, мантия до земли,
#                 венец из нитей-осколков, посох; парит над землёй;
#   wanderer    — Странник (босс 100): мечник в длинном чёрном плаще с капюшоном, под
#                 капюшоном — маска с лиловой полосой и прорезями глаз, на груди горит знак
#                 бездны; длинный меч с лиловым лезвием.
#                 awaken(1..4) — сила бездны просыпается: глаза ярче, венец осколков,
#                 светится плащ, в конце он парит. set_wings(true) — в последней фазе за
#                 спиной раскрываются чёрные крылья с лиловым отливом и машут.

const CLOTH := Color(0.17, 0.15, 0.22)
const CLOTH2 := Color(0.28, 0.18, 0.36)
const TRIM := Color(0.56, 0.50, 0.64)
const MASK := Color(0.90, 0.87, 0.81)
const MASK_D := Color(0.66, 0.62, 0.58)
const IRON := Color(0.30, 0.30, 0.36)
const WRAP := Color(0.34, 0.30, 0.32)
const GLOW := Color(0.78, 0.36, 1.0)
const CORE := Color(0.98, 0.86, 1.0)
const VOID := Color(0.07, 0.03, 0.10)

var bot: Player
var kind := "rift_blade"
var size := Vector2(40, 64)
var puppet_vx := 0.0
var puppet_facing := 1
var eyes_lit := true
var levitate := 0.0               # Предвестник во второй фазе парит (0..1)
var cracked := false              # трещина на маске (вторая фаза Предвестника)

var px := 2.0
var _art: Node2D
var _hip: Node2D
var _torso: Node2D
var _head: Node2D
var _arm_f: Node2D
var _arm_b: Node2D
var _leg_f: Node2D
var _leg_b: Node2D
var _cloak: Node2D
var _weapon: Node2D
var _weapon2: Node2D
var _back: Node2D
var _halo: Node2D
var _glows: Array = []            # светящиеся детали — пульсируют
var _slit: Polygon2D              # щель маски (у Предвестника — с трещиной)
var _crack: Line2D
var _legs4: Array = []
var _tendrils: Array = []
var _teeth: Node2D
var _iris: Node2D
var _wing_f: Node2D
var _wing_b: Node2D
var _tail: Line2D
var _tail_tip: Node2D
var _t := 0.0
var _phase := 0.0
var _act := ""
var _act_t := 0.0
var _act_len := 0.0
var _hurt := 0.0
var _arm_len := 11.0
var _shoulder := Vector2.ZERO
var _hip_y := 0.0
var _humanoid := true
var hold_aim := 0.0               # Око / арбалет: держит прицел (0..1)

func _size() -> Vector2:
	return bot.body_size if bot else size

func _vel() -> Vector2:
	return bot.velocity if bot else Vector2(puppet_vx, 0)

func _facing() -> int:
	return bot.facing if bot else puppet_facing

func _floor() -> bool:
	return bot.is_on_floor() if bot else true

# ---------------- рисование ----------------
static func _img(w: int, h: int) -> Image:
	return Image.create(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)

static func _p(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)

static func _rect(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, im.get_width(), im.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		im.fill_rect(r, c)

# Заливка многоугольника (чёт-нечет по строкам)
static func _poly(im: Image, pts: PackedVector2Array, c: Color) -> void:
	var y0 := 99999.0
	var y1 := -99999.0
	for p in pts:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	for y in range(int(floor(y0)), int(ceil(y1)) + 1):
		var yc := y + 0.5
		var xs: Array = []
		for i in pts.size():
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % pts.size()]
			if (a.y <= yc and b.y > yc) or (b.y <= yc and a.y > yc):
				xs.append(a.x + (yc - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			for x in range(int(round(xs[k])), int(round(xs[k + 1]))):
				_p(im, x, y, c)
			k += 2

# Тёмный контур вокруг силуэта (картинка должна иметь запас по краям)
static func _outline(im: Image, c := Color(0.05, 0.03, 0.07)) -> void:
	var src := im.duplicate() as Image
	var w := im.get_width()
	var h := im.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a > 0.5:
					im.set_pixel(x, y, c)
					break

# Часть тела: картинка с объёмом (свет сверху-спереди) вдвое детальнее
func _spr(parent: Node, img: Image, pivot: Vector2, pos: Vector2, shade := true) -> Sprite2D:
	_outline(img)
	var s := Sprite2D.new()
	var hi := img.duplicate() as Image
	hi.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	if shade:
		BotRig._volume(hi)
	s.texture = ImageTexture.create_from_image(hi)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.scale = Vector2(0.5, 0.5)
	s.offset = -pivot * 2.0
	s.position = pos
	parent.add_child(s)
	return s

# Светящаяся деталь (без объёма): пульсирует
func _glow_poly(parent: Node, pts: PackedVector2Array, c: Color, pos := Vector2.ZERO) -> Polygon2D:
	var g := Polygon2D.new()
	g.polygon = pts
	g.color = c
	g.position = pos
	parent.add_child(g)
	_glows.append(g)
	return g

# ---------------- сборка ----------------
func _ready() -> void:
	scale.x = float(_facing())
	_art = Node2D.new()
	add_child(_art)
	match kind:
		"rift_spawn": _build_spawn()
		"rift_eye": _build_eye()
		"voidwing": _build_voidwing()
		_: _build_humanoid()

# Пропорции: [ширина торса, высота торса, высота головы, длина руки, длина ноги] в пикселях рисунка
const BODY := {
	"rift_blade":  [9, 11, 8, 11, 12],
	"rift_archer": [9, 11, 8, 11, 12],
	"rift_caller": [9, 13, 8, 11, 10],
	"rift_brute":  [16, 14, 8, 14, 11],
	"rift_bearer": [14, 13, 8, 13, 11],
	"harbinger":   [12, 18, 10, 17, 17],
	"rift_weaver": [11, 16, 9, 15, 13],
	"wanderer":    [11, 15, 9, 14, 15],
}
var awake := 0                    # Странник: насколько проснулась в нём бездна (0..4)

func _build_humanoid() -> void:
	var b: Array = BODY.get(kind, BODY["rift_blade"])
	var tw: int = b[0]
	var th: int = b[1]
	var hh: int = b[2]
	var al: int = b[3]
	var ll: int = b[4]
	var total := float(th + hh + ll)
	px = _size().y / total
	_art.scale = Vector2(px, px)
	_arm_len = al
	var feet := total / 2.0
	_hip_y = feet - ll
	# всё тело крепится к бёдрам: так проще качать его при ходьбе
	_hip = Node2D.new()
	_hip.position = Vector2(0, _hip_y)
	_art.add_child(_hip)
	_shoulder = Vector2(1, -th + 2)
	# плащ (за спиной)
	if kind in ["rift_blade", "rift_archer", "harbinger", "rift_caller", "rift_weaver", "wanderer"]:
		_cloak = Node2D.new()
		_cloak.position = Vector2(-1, -th + 1)
		_hip.add_child(_cloak)
		_spr(_cloak, _cloak_img(tw, th + ll - 2), Vector2(tw / 2.0 + 1, 0), Vector2.ZERO)
	# предмет за спиной: кристалл, колчан
	if kind == "rift_bearer":
		_back = Node2D.new()
		_back.position = Vector2(-tw / 2.0 - 2, -th + 2)
		_hip.add_child(_back)
		_build_crystal(_back, tw)
	elif kind == "rift_archer":
		_back = Node2D.new()
		_back.position = Vector2(-tw / 2.0, -th + 3)
		_back.rotation = -0.5
		_hip.add_child(_back)
		_spr(_back, _quiver_img(), Vector2(2, 1), Vector2.ZERO)
		for k in 3:
			_glow_poly(_back, PackedVector2Array([Vector2(-0.5, 0), Vector2(0.5, 0), Vector2(0, -2.5)]), GLOW, Vector2(-0.5 + k, -0.5))
	# задние нога и рука
	_leg_b = Node2D.new()
	_hip.add_child(_leg_b)
	_spr(_leg_b, _leg_img(ll, true), Vector2(2, 0), Vector2.ZERO)
	_arm_b = Node2D.new()
	_arm_b.position = _shoulder + Vector2(-2, 0)
	_hip.add_child(_arm_b)
	_spr(_arm_b, _arm_img(al, false), Vector2(1.5, 1), Vector2.ZERO)
	if kind == "rift_blade":
		_weapon2 = Node2D.new()
		_weapon2.position = Vector2(0, al - 1)
		_weapon2.rotation = PI / 2
		_arm_b.add_child(_weapon2)
		_spr(_weapon2, _weapon_img("sickle"), Vector2(1, 3), Vector2.ZERO)
		_glow_poly(_weapon2, PackedVector2Array([Vector2(5, -4), Vector2(9, -3), Vector2(11, 0), Vector2(9, -2)]), GLOW)
	# туловище и голова
	_torso = Node2D.new()
	_hip.add_child(_torso)
	_spr(_torso, _torso_img(tw, th), Vector2(tw / 2.0, th), Vector2.ZERO)
	_torso_glow(tw, th)
	var hw := 8 if not kind in ["harbinger", "rift_weaver", "wanderer"] else 10
	if kind in ["harbinger", "rift_weaver"]:
		_build_halo(hw, hh, Vector2(1, -th))              # венец — за головой, но перед плащом
	if kind == "wanderer":
		_build_halo(hw, hh, Vector2(1, -th))
		_halo.visible = false                             # венец появится, когда проснётся бездна
	_head = Node2D.new()
	_head.position = Vector2(1, -th)
	_hip.add_child(_head)
	if kind == "wanderer":
		_spr(_head, _wanderer_head_img(hw, hh), Vector2(hw / 2.0 + 2.0, hh + 1.0), Vector2.ZERO)
		_wanderer_eyes(hw, hh)
	else:
		_spr(_head, _head_img(hw, hh), Vector2(hw / 2.0 + 2.0, hh + 1.0), Vector2.ZERO)
		_mask_slit(hw, hh)
	# передние нога и рука, оружие
	_leg_f = Node2D.new()
	_hip.add_child(_leg_f)
	_spr(_leg_f, _leg_img(ll, false), Vector2(2, 0), Vector2.ZERO)
	_arm_f = Node2D.new()
	_arm_f.position = _shoulder + Vector2(1, 0)
	_hip.add_child(_arm_f)
	if kind == "rift_brute":
		_spr(_arm_f, _gauntlet_img(al), Vector2(3, 1), Vector2.ZERO)
		for p2 in [Vector2(1, 4), Vector2(3, 8), Vector2(0, 11)]:
			_glow_poly(_arm_f, PackedVector2Array([Vector2(-0.6, -1.2), Vector2(0.6, -0.4), Vector2(0.4, 1.2), Vector2(-0.6, 0.4)]), GLOW, p2)
	else:
		_spr(_arm_f, _arm_img(al, true), Vector2(1.5, 1), Vector2.ZERO)
	var wid: String = {"rift_blade": "sickle", "rift_archer": "crossbow", "rift_caller": "staff", "rift_bearer": "chain_staff",
			"harbinger": "glaive", "rift_weaver": "staff", "wanderer": "void_sword"}.get(kind, "")
	if wid != "":
		_weapon = Node2D.new()
		_weapon.position = Vector2(0, al - 1)
		_weapon.rotation = PI / 2 if wid in ["sickle", "crossbow"] else 0.0
		_arm_f.add_child(_weapon)
		var wimg := _weapon_img(wid)
		var grip: Vector2 = {"sickle": Vector2(1, 3), "crossbow": Vector2(3, 3), "staff": Vector2(2, 12),
				"chain_staff": Vector2(2, 10), "glaive": Vector2(3, 40), "lantern_staff": Vector2(2, 22), "void_sword": Vector2(3, 30)}[wid]
		_spr(_weapon, wimg, grip, Vector2.ZERO)
		_weapon_glow(wid, grip)

# ---------- картинки частей тела ----------
func _cloth() -> Color:
	return {"rift_caller": CLOTH2, "harbinger": Color(0.13, 0.10, 0.17), "rift_bearer": Color(0.24, 0.20, 0.24),
			"rift_weaver": Color(0.30, 0.14, 0.40), "wanderer": Color(0.07, 0.06, 0.09)}.get(kind, CLOTH)

func _leg_img(ll: int, back: bool) -> Image:
	var im := _img(6, ll + 2)
	var c := _cloth().darkened(0.25 if back else 0.0)
	var robe := kind in ["rift_caller", "harbinger", "rift_weaver"]
	if kind == "rift_brute" or kind == "rift_bearer":
		_rect(im, 0, 0, 5, ll - 2, c)
		_rect(im, 0, ll - 2, 6, 2, IRON.darkened(0.2 if back else 0.0))     # тяжёлые сапоги
		_rect(im, 1, ll / 2, 3, 1, IRON)
	else:
		_rect(im, 1, 0, 3, ll - 2, WRAP.darkened(0.2 if back else 0.0) if not robe else c)
		for y in range(2, ll - 2, 3):                                 # обмотки
			_rect(im, 1, y, 3, 1, WRAP.lightened(0.15) if not robe else c.lightened(0.1))
		_rect(im, 1, ll - 2, 5, 2, Color(0.12, 0.10, 0.14))
	return im

func _arm_img(al: int, front: bool) -> Image:
	var im := _img(4, al + 2)
	var c := _cloth().darkened(0.0 if front else 0.2)
	_rect(im, 0, 0, 3, al - 3, c)
	_rect(im, 0, al - 3, 3, 3, WRAP.lightened(0.1) if kind != "harbinger" else IRON)
	if kind == "harbinger":
		_rect(im, 0, 0, 4, 3, IRON.lightened(0.15))                     # наплечник
		_p(im, 1, 1, GLOW)
	return im

func _gauntlet_img(al: int) -> Image:
	var im := _img(9, al + 5)
	_rect(im, 0, 0, 5, al - 5, IRON.darkened(0.15))
	for y in range(1, al - 5, 3):
		_rect(im, 0, y, 5, 1, IRON.lightened(0.1))
	_poly(im, PackedVector2Array([Vector2(-0.5, al - 6), Vector2(7.5, al - 7), Vector2(8.5, al - 1), Vector2(6, al + 3.5), Vector2(0, al + 3)]), IRON)
	for k in 3:                                                     # когти
		_rect(im, 1 + k * 2, al + 2, 1, 2, Color(0.8, 0.78, 0.84))
	_rect(im, 1, al - 5, 6, 1, IRON.lightened(0.2))
	return im

func _torso_img(tw: int, th: int) -> Image:
	var im := _img(tw + 2, th + 3)
	var c := _cloth()
	match kind:
		"rift_brute":
			_poly(im, PackedVector2Array([Vector2(1, th), Vector2(0, 4), Vector2(3, 0), Vector2(tw - 1, 1), Vector2(tw, th)]), c)
			_rect(im, 2, 2, tw - 4, 5, IRON)                           # латы на груди
			_rect(im, 2, 2, tw - 4, 1, IRON.lightened(0.2))
			_rect(im, 0, th - 3, tw, 2, Color(0.22, 0.14, 0.12))        # пояс
			_rect(im, tw / 2 - 1, th - 3, 2, 2, TRIM)
		"rift_bearer":
			_poly(im, PackedVector2Array([Vector2(0, th), Vector2(1, 3), Vector2(4, 0), Vector2(tw - 2, 1), Vector2(tw, th)]), c)
			for k in 3:                                                 # ремни крест-накрест (держат кристалл)
				_p(im, 2 + k * 3, 2 + k * 3, Color(0.35, 0.24, 0.16))
				_p(im, 3 + k * 3, 2 + k * 3, Color(0.35, 0.24, 0.16))
			_rect(im, 0, th - 3, tw, 2, IRON)
		"harbinger":
			_poly(im, PackedVector2Array([Vector2(1, th + 1), Vector2(1, 3), Vector2(3, 0), Vector2(tw - 2, 0), Vector2(tw, 3), Vector2(tw, th + 1)]), c)
			_rect(im, 2, 1, tw - 4, 7, IRON.darkened(0.1))              # кираса под мантией
			_rect(im, 2, 1, tw - 4, 1, IRON.lightened(0.25))
			_rect(im, 3, 9, tw - 6, 1, TRIM)
			for y in range(10, th, 2):                                  # рваные полосы мантии
				_p(im, 2 + (y % 3), y, c.lightened(0.12))
				_p(im, tw - 3 - (y % 2), y, c.lightened(0.08))
		"wanderer":
			# длинный чёрный плащ: широкие плечи-наплечники, глубокий ворот, пояс с пряжкой
			_poly(im, PackedVector2Array([Vector2(0, th + 1), Vector2(0, 2), Vector2(2, 0), Vector2(tw - 1, 0), Vector2(tw + 1, 2), Vector2(tw + 1, th + 1)]), c)
			_rect(im, 0, 0, 3, 4, c.lightened(0.10))                    # наплечники
			_rect(im, tw - 2, 0, 3, 4, c.lightened(0.10))
			_poly(im, PackedVector2Array([Vector2(3, 0), Vector2(tw / 2.0, 6), Vector2(tw - 2, 0)]), Color(0.03, 0.02, 0.05))   # ворот
			_rect(im, 1, th - 4, tw - 1, 2, Color(0.13, 0.12, 0.16))      # пояс
			_rect(im, tw / 2, th - 4, 2, 2, Color(0.70, 0.68, 0.76))     # серебряная пряжка
			for y in range(7, th - 4, 2):                                # складки
				_p(im, 2, y, c.lightened(0.07))
				_p(im, tw - 2, y + 1, c.lightened(0.05))
		"rift_caller", "rift_weaver":
			_poly(im, PackedVector2Array([Vector2(1, th + 2), Vector2(2, 2), Vector2(4, 0), Vector2(tw - 3, 0), Vector2(tw - 1, 2), Vector2(tw + 1, th + 2)]), c)
			_rect(im, 3, 0, tw - 6, th + 1, c.lightened(0.1))
			_rect(im, tw / 2 - 1, 2, 2, th - 1, TRIM)                    # вышитая полоса
			_rect(im, 1, 5, tw - 1, 1, TRIM.darkened(0.2))
		_:
			_poly(im, PackedVector2Array([Vector2(1, th), Vector2(1, 2), Vector2(3, 0), Vector2(tw - 2, 0), Vector2(tw, 2), Vector2(tw, th)]), c)
			_rect(im, 1, th - 4, tw - 1, 2, Color(0.22, 0.16, 0.14))     # пояс
			_rect(im, tw / 2, th - 4, 2, 2, TRIM)
			for y in range(1, th - 5):                                   # шарф наискосок
				_p(im, tw - 3 - y / 3, y, CLOTH2.lightened(0.15))
	return im

func _torso_glow(tw: int, th: int) -> void:
	# трещины силы разлома на теле
	match kind:
		"rift_brute":
			_glow_poly(_torso, PackedVector2Array([Vector2(-2, -10), Vector2(0, -9), Vector2(-1, -6), Vector2(1, -4), Vector2(-1, -5), Vector2(-2, -8)]), GLOW)
		"harbinger":
			_glow_poly(_torso, PackedVector2Array([Vector2(-0.8, -th + 2), Vector2(0.8, -th + 2), Vector2(0.5, -th + 8), Vector2(-0.5, -th + 8)]), GLOW)
			_glow_poly(_torso, PackedVector2Array([Vector2(-1.5, -th + 4), Vector2(0, -th + 3), Vector2(1.5, -th + 4), Vector2(0, -th + 6.5)]), CORE)
		"rift_caller", "rift_weaver":
			_glow_poly(_torso, PackedVector2Array([Vector2(-1, -th + 3), Vector2(1, -th + 3), Vector2(0, -th + 5)]), GLOW)
		"wanderer":
			# знак бездны на груди — лиловая «стрела», горит всегда; с пробуждением — ярче
			var sig := _glow_poly(_torso, PackedVector2Array([Vector2(-3, -th + 4), Vector2(0, -th + 2.5), Vector2(3, -th + 4), Vector2(1.6, -th + 4.4),
					Vector2(0, -th + 3.8), Vector2(-1.6, -th + 4.4)]), GLOW)
			sig.name = "Sigil"
			_glow_poly(_torso, PackedVector2Array([Vector2(-2.4, -th + 6), Vector2(0, -th + 4.6), Vector2(2.4, -th + 6), Vector2(1.2, -th + 6.3),
					Vector2(0, -th + 5.8), Vector2(-1.2, -th + 6.3)]), GLOW)
			_glow_poly(_torso, PackedVector2Array([Vector2(-0.6, -th + 4.6), Vector2(0.6, -th + 4.6), Vector2(0.3, -th + 10), Vector2(-0.3, -th + 10)]), GLOW)
			var shard := _glow_poly(_torso, PackedVector2Array([Vector2(-1, -th + 5), Vector2(0, -th + 3), Vector2(1, -th + 5), Vector2(0, -th + 8)]), CORE)
			shard.name = "Shard"
			shard.visible = false

func _cloak_img(tw: int, h: int) -> Image:
	var im := _img(tw + 4, h + 2)
	var c := _cloth().darkened(0.3)
	var pts := PackedVector2Array([Vector2(1, 0), Vector2(tw + 1, 0), Vector2(tw + 3, h)])
	var x := float(tw + 2)
	while x > 0.0:                                                   # рваный край
		pts.append(Vector2(x, h - (2.0 if int(x) % 3 == 0 else 0.0)))
		x -= 1.5
	pts.append(Vector2(0, h - 1))
	_poly(im, pts, c)
	if kind == "harbinger":
		for y in range(3, h, 4):
			_p(im, 2 + (y % 5), y, GLOW.darkened(0.4))
	return im

# Голова: капюшон с острым хвостом-кончиком назад (у великанов — шлем), в проёме —
# тёмная тень и бледная маска. Картинка с запасом 2 пикселя слева и 1 сверху.
func _head_img(hw: int, hh: int) -> Image:
	var ox := 2.0
	var oy := 1.0
	var im := _img(hw + 6, hh + 4)
	var hood := _cloth().darkened(0.1)
	var helm := kind == "rift_brute" or kind == "rift_bearer"
	if helm:
		# низкий железный шлем-котелок с гребнем
		_poly(im, PackedVector2Array([Vector2(ox, oy + hh), Vector2(ox - 0.5, oy + 3), Vector2(ox + 2, oy), Vector2(ox + hw - 1, oy),
				Vector2(ox + hw + 1, oy + 2), Vector2(ox + hw + 1, oy + hh), Vector2(ox + hw - 2, oy + hh + 1)]), IRON)
		_rect(im, int(ox) + 1, int(oy), hw - 2, 1, IRON.lightened(0.25))
		_rect(im, int(ox) - 1, int(oy) + 3, hw + 3, 1, IRON.darkened(0.25))           # поля шлема
		for k in 3:
			_p(im, int(ox) + 1 + k * 2, int(oy) + 2, IRON.lightened(0.35))               # заклёпки
	else:
		_poly(im, PackedVector2Array([Vector2(ox + 1, oy + hh + 1), Vector2(ox - 1, oy + hh * 0.55), Vector2(ox - 2, oy + 0.5),
				Vector2(ox + 2, oy - 0.5), Vector2(ox + hw - 1, oy), Vector2(ox + hw + 1, oy + 2), Vector2(ox + hw + 1, oy + hh - 1),
				Vector2(ox + hw - 2, oy + hh + 1)]), hood)
		_poly(im, PackedVector2Array([Vector2(ox - 1.5, oy + 1), Vector2(ox + 2, oy + 0.2), Vector2(ox + 1, oy + 2.5)]), hood.lightened(0.12))
	if kind in ["rift_caller", "rift_weaver"]:
		for s2 in [ox + 1.0, ox + hw - 1.0]:                          # высокий ворот-рога
			_poly(im, PackedVector2Array([Vector2(s2 - 1, oy + 3), Vector2(s2, oy - 1), Vector2(s2 + 1, oy + 3)]), hood.lightened(0.18))
	# тень в проёме капюшона
	if not helm:
		_poly(im, PackedVector2Array([Vector2(ox + 3, oy + 2), Vector2(ox + hw + 1, oy + 2), Vector2(ox + hw + 1, oy + hh), Vector2(ox + 3, oy + hh)]),
				Color(0.06, 0.04, 0.08))
	# маска: бледный овал, чуть выступает вперёд
	var mx := ox + 4.0
	_poly(im, PackedVector2Array([Vector2(mx, oy + 3), Vector2(ox + hw, oy + 2.5), Vector2(ox + hw + 1.5, oy + hh * 0.45),
			Vector2(ox + hw + 0.5, oy + hh - 1), Vector2(mx + 1, oy + hh), Vector2(mx - 0.5, oy + hh - 2)]), MASK)
	_rect(im, int(mx), int(oy) + 3, 1, hh - 4, MASK_D)                       # тень по краю маски
	_p(im, int(ox) + hw, int(oy + hh) - 2, MASK_D)
	if kind == "harbinger":                                               # длинный подбородок маски
		_poly(im, PackedVector2Array([Vector2(mx, oy + hh - 1), Vector2(ox + hw + 0.5, oy + hh - 1), Vector2(ox + hw - 1, oy + hh + 2.5),
				Vector2(mx + 1.5, oy + hh + 1.5)]), MASK_D)
	return im

func _mask_slit(hw: int, hh: int) -> void:
	# вертикальная щель — знак Странника (из неё бьёт свет)
	var x := hw / 2.0 - 0.8
	var pts := PackedVector2Array([Vector2(x - 0.5, -hh + 3), Vector2(x + 0.5, -hh + 3), Vector2(x + 0.6, -2), Vector2(x - 0.6, -2)])
	var dark := Polygon2D.new()
	dark.polygon = pts
	dark.color = VOID
	_head.add_child(dark)
	_slit = _glow_poly(_head, PackedVector2Array([Vector2(x - 0.25, -hh + 3.5), Vector2(x + 0.25, -hh + 3.5), Vector2(x + 0.3, -2.5), Vector2(x - 0.3, -2.5)]), CORE)
	var halo := _glow_poly(_head, Util.circle(1.6, 8), Color(GLOW, 0.45), Vector2(x, -hh * 0.55))
	halo.scale = Vector2(0.8, 1.6)
	if kind == "harbinger":
		_crack = Line2D.new()
		_crack.points = PackedVector2Array([Vector2(x + 0.3, -hh + 2), Vector2(x + 2.0, -hh + 4.0), Vector2(x + 1.2, -hh + 5.5), Vector2(x + 3.0, -hh + 7.0)])
		_crack.width = 0.5
		_crack.default_color = CORE
		_crack.visible = false
		_head.add_child(_crack)

# Голова Странника: чёрный капюшон, под ним маска с лиловой полосой и прорезями глаз
func _wanderer_head_img(hw: int, hh: int) -> Image:
	var ox := 2.0
	var oy := 1.0
	var im := _img(hw + 6, hh + 4)
	var hood := Color(0.08, 0.07, 0.10)
	_poly(im, PackedVector2Array([Vector2(ox + 1, oy + hh + 1), Vector2(ox - 1, oy + hh * 0.5), Vector2(ox - 2.5, oy + 1),
			Vector2(ox + 2, oy - 0.5), Vector2(ox + hw - 1, oy - 0.2), Vector2(ox + hw + 1.5, oy + 2.5), Vector2(ox + hw + 1.5, oy + hh),
			Vector2(ox + hw - 2, oy + hh + 1.5)]), hood)
	_poly(im, PackedVector2Array([Vector2(ox - 2, oy + 1), Vector2(ox + 2, oy), Vector2(ox + 0.5, oy + 3)]), hood.lightened(0.15))
	_poly(im, PackedVector2Array([Vector2(ox + 3.5, oy + 2.5), Vector2(ox + hw + 1.5, oy + 2.5), Vector2(ox + hw + 1.5, oy + hh - 0.5),
			Vector2(ox + 4, oy + hh)]), Color(0.05, 0.04, 0.07))                    # тень под капюшоном
	_poly(im, PackedVector2Array([Vector2(ox + 4.5, oy + 3), Vector2(ox + hw + 1, oy + 3), Vector2(ox + hw + 1, oy + hh - 1.5),
			Vector2(ox + hw - 1.5, oy + hh), Vector2(ox + 5, oy + hh - 1)]), Color(0.17, 0.16, 0.20))   # маска
	return im

func _wanderer_eyes(hw: int, hh: int) -> void:
	# лиловая полоса посередине маски
	var stripe := _glow_poly(_head, PackedVector2Array([Vector2(-0.35, -hh + 2.5), Vector2(0.35, -hh + 2.5), Vector2(0.35, -1.5), Vector2(-0.35, -1.5)]),
			GLOW, Vector2(hw / 2.0 + 0.6, 0))
	stripe.name = "Stripe"
	for k in 2:
		var e := _glow_poly(_head, PackedVector2Array([Vector2(-0.5, -0.4), Vector2(0.7, -0.4), Vector2(0.7, 0.4), Vector2(-0.5, 0.4)]),
				CORE, Vector2(hw / 2.0 - 1.5 + k * 2.4, -hh * 0.55))
		e.name = "Eye%d" % k
	var h := _glow_poly(_head, Util.circle(2.5, 8), Color(GLOW, 0.25), Vector2(hw / 2.0 - 0.3, -hh * 0.55))
	h.name = "EyeHalo"
	h.scale = Vector2(1.6, 0.8)

# Странник: бездна просыпается (1 — глаза ярче, 2 — венец осколков, 3 — плащ и осколок
# в груди светятся, 4 — парит)
func awaken(level: int) -> void:
	awake = level
	if _head:
		var eh := _head.get_node_or_null("EyeHalo")
		if eh:
			eh.scale = Vector2(1.6, 0.8) * (1.0 + 0.35 * level)
	if _halo:
		_halo.visible = level >= 2
		_halo.scale = Vector2.ONE * (1.0 + 0.2 * maxi(0, level - 2))
	if _torso:
		var sh := _torso.get_node_or_null("Shard")
		if sh:
			sh.visible = level >= 3
	if _cloak and level >= 3:
		_cloak.modulate = Color(1.0, 0.85, 1.25)
	levitate = 1.0 if level >= 4 else 0.0
	if _torso:
		var sg := _torso.get_node_or_null("Sigil")
		if sg:
			sg.scale = Vector2.ONE * (1.0 + 0.15 * level)

# ---------- Крылья Странника (последняя фаза) ----------
var _wings: Node2D
var _wing_l: Node2D
var _wing_r: Node2D

func set_wings(on: bool) -> void:
	if on and _wings == null:
		_build_wings()
	if _halo:
		_halo.visible = not on and awake >= 2       # с крыльями венец не нужен
	if _wings == null:
		return
	var t := _wings.create_tween()
	if on:
		_wings.visible = true
		_wings.scale = Vector2(0.1, 0.1)
		t.tween_property(_wings, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		t.tween_property(_wings, "scale", Vector2(0.1, 0.1), 0.4)
		t.tween_callback(func(): _wings.visible = false)

func _build_wings() -> void:
	var th: int = BODY["wanderer"][1]
	_wings = Node2D.new()
	_wings.position = Vector2(-1, -th + 3)
	_hip.add_child(_wings)
	_hip.move_child(_wings, 0)                 # за плащом и телом
	_wing_l = _wing(-1.0)
	_wing_r = _wing(1.0)

func _wing(s: float) -> Node2D:
	var w := Node2D.new()
	_wings.add_child(w)
	var dark := Color(0.07, 0.05, 0.10)
	var rim := Color(0.48, 0.24, 0.70)
	var base := PackedVector2Array([Vector2.ZERO])
	var aura := _glow_poly(w, PackedVector2Array([Vector2.ZERO, Vector2(s * 20, -40), Vector2(s * 46, -30), Vector2(s * 50, 2), Vector2(s * 30, 22)]), Color(GLOW, 0.16))
	aura.z_index = -1
	for i in 7:
		var a := s * (0.30 + i * 0.22)
		var dir := Vector2(sin(a), -cos(a))
		var perp := Vector2(-dir.y, dir.x)
		var ln := 44.0 - absf(i - 2.0) * 4.0
		var edge := Polygon2D.new()                   # лиловая кромка — силуэт виден на тёмном небе
		edge.polygon = PackedVector2Array([perp * 3.2, dir * ln * 0.55 + perp * 3.8, dir * (ln + 4.5), dir * ln * 0.55 - perp * 3.8, -perp * 3.2])
		edge.color = rim.lerp(Color(0.75, 0.45, 1.0), i / 7.0)
		w.add_child(edge)
		var f := Polygon2D.new()
		f.polygon = PackedVector2Array([perp * 2.2, dir * ln * 0.55 + perp * 2.6, dir * (ln + 2.5), dir * ln * 0.55 - perp * 2.6, -perp * 2.2])
		f.color = dark.lerp(Color(0.22, 0.10, 0.32), i / 7.0)
		w.add_child(f)
		_glow_poly(w, PackedVector2Array([dir * (ln - 9.0) + perp * 1.3, dir * (ln + 3.0), dir * (ln - 9.0) - perp * 1.3]), Color(0.85, 0.60, 1.0))
		base.append(dir * (16.0 + (i % 2) * 4.0))
	var cov := Polygon2D.new()                      # кроющие перья у основания
	cov.polygon = base
	cov.color = Color(0.10, 0.07, 0.13)
	w.add_child(cov)
	return w

func _quiver_img() -> Image:
	var im := _img(5, 10)
	_rect(im, 0, 1, 4, 8, Color(0.30, 0.20, 0.14))
	_rect(im, 0, 1, 4, 1, TRIM)
	return im

func _build_crystal(parent: Node2D, tw: int) -> void:
	var im := _img(14, 22)
	_poly(im, PackedVector2Array([Vector2(6, 0), Vector2(12, 7), Vector2(11, 17), Vector2(6, 21), Vector2(1, 16), Vector2(0, 6)]), Color(0.42, 0.20, 0.62))
	_poly(im, PackedVector2Array([Vector2(6, 1), Vector2(10, 7), Vector2(6, 19), Vector2(3, 8)]), Color(0.62, 0.34, 0.90))
	for y in range(5, 17, 4):                                        # цепи
		_rect(im, 0, y, 13, 1, IRON.lightened(0.2))
	var s := _spr(parent, im, Vector2(11, 6), Vector2.ZERO, false)
	s.z_index = 0
	_glow_poly(parent, PackedVector2Array([Vector2(-5, -5), Vector2(-3, 1), Vector2(-5, 9), Vector2(-7, 1)]), CORE)
	var g := _glow_poly(parent, Util.circle(10.0, 14), Color(GLOW, 0.22), Vector2(-5, 3))
	g.name = "CrystalGlow"

func _build_halo(hw: int, hh: int, at: Vector2) -> void:
	# венец из осколков за головой — медленно вращается
	_halo = Node2D.new()
	_halo.position = at + Vector2(-1.5, -hh * 0.6)
	_hip.add_child(_halo)
	for k in 9:
		var a := TAU * k / 9.0
		var sh := Polygon2D.new()
		var ln := 3.2 if k % 2 == 0 else 2.2
		sh.polygon = PackedVector2Array([Vector2(-0.6, 0), Vector2(0, -ln), Vector2(0.6, 0), Vector2(0, 0.8)])
		sh.color = Color(0.72, 0.42, 1.0) if k % 3 else CORE
		sh.position = Vector2.from_angle(a) * (hw * 0.75)
		sh.rotation = a + PI / 2
		_halo.add_child(sh)
	var ring := Line2D.new()
	var pts := Util.circle(hw * 0.75, 24)
	pts.append(pts[0])
	ring.points = pts
	ring.width = 0.4
	ring.default_color = Color(GLOW, 0.5)
	_halo.add_child(ring)

func _weapon_img(id: String) -> Image:
	var im: Image
	match id:
		"sickle":                       # серп: рукоять вдоль руки, изогнутое лезвие
			im = _img(13, 8)
			_rect(im, 0, 2, 5, 2, Color(0.30, 0.20, 0.14))
			_poly(im, PackedVector2Array([Vector2(4, 2), Vector2(9, 0), Vector2(12, 3), Vector2(11, 6), Vector2(10, 3), Vector2(7, 2), Vector2(5, 4)]), Color(0.70, 0.70, 0.78))
		"crossbow":
			im = _img(14, 9)
			_rect(im, 0, 3, 11, 2, Color(0.26, 0.18, 0.14))                  # ложе
			_poly(im, PackedVector2Array([Vector2(8, 0), Vector2(10, 0), Vector2(11, 4), Vector2(10, 8), Vector2(8, 8), Vector2(9, 4)]), IRON.lightened(0.1))
			_rect(im, 10, 3, 4, 2, Color(0.60, 0.40, 0.90))                  # болт
		"staff":
			im = _img(5, 28)
			_rect(im, 1, 4, 2, 24, Color(0.24, 0.18, 0.20))
			_poly(im, PackedVector2Array([Vector2(2, -0.5), Vector2(4.5, 3), Vector2(2, 6.5), Vector2(-0.5, 3)]), Color(0.50, 0.24, 0.74))
		"void_sword":                   # длинный меч: светлое лиловое лезвие, крестовина-крылья, тёмная рукоять
			im = _img(7, 36)
			_rect(im, 2, 1, 3, 25, Color(0.86, 0.80, 0.96))
			_rect(im, 2, 1, 1, 25, Color(0.98, 0.95, 1.0))
			_rect(im, 3, 0, 1, 1, Color(0.98, 0.95, 1.0))
			_rect(im, 0, 26, 7, 1, Color(0.20, 0.18, 0.24))                 # крестовина
			_p(im, 0, 25, Color(0.20, 0.18, 0.24))
			_p(im, 6, 25, Color(0.20, 0.18, 0.24))
			_rect(im, 2, 27, 3, 6, Color(0.10, 0.09, 0.12))                 # рукоять
			_rect(im, 2, 33, 3, 2, Color(0.50, 0.30, 0.70))                 # навершие
		"lantern_staff":                # посох путника, на крюке — фонарь с осколком бездны
			im = _img(9, 46)
			_rect(im, 2, 4, 2, 42, Color(0.36, 0.26, 0.18))
			for y in range(8, 46, 6):
				_rect(im, 2, y, 2, 1, Color(0.28, 0.20, 0.14))
			_rect(im, 3, 2, 4, 2, IRON)                                     # крюк
			_rect(im, 6, 3, 1, 3, IRON)
			_rect(im, 5, 6, 4, 6, Color(0.18, 0.14, 0.12))                  # фонарь
			_rect(im, 6, 7, 2, 4, Color(0.62, 0.34, 0.90))
		"chain_staff":
			im = _img(5, 24)
			_rect(im, 1, 0, 2, 24, IRON)
			for y in range(14, 24, 2):
				_p(im, 3, y, IRON.lightened(0.3))
			_rect(im, 0, 0, 4, 2, IRON.lightened(0.15))
		"glaive":                       # глефа: длинное древко, лезвие-полумесяц из разрыва
			im = _img(13, 60)
			_rect(im, 2, 8, 2, 52, Color(0.16, 0.12, 0.18))
			for y in range(10, 60, 5):
				_rect(im, 2, y, 2, 1, TRIM.darkened(0.2))
			_poly(im, PackedVector2Array([Vector2(3, 9), Vector2(1, 4), Vector2(4, 0), Vector2(10, -0.5), Vector2(12.5, 3), Vector2(8, 2), Vector2(6, 5), Vector2(5, 10)]), VOID)
	return im

func _weapon_glow(id: String, grip: Vector2) -> void:
	match id:
		"sickle":
			_glow_poly(_weapon, PackedVector2Array([Vector2(5, -4), Vector2(9, -3), Vector2(11, 0), Vector2(9, -2)]), GLOW)
		"crossbow":
			_glow_poly(_weapon, PackedVector2Array([Vector2(7, -1), Vector2(11, -1), Vector2(11, 1), Vector2(7, 1)]), GLOW)
		"void_sword":
			var bl := _glow_poly(_weapon, PackedVector2Array([Vector2(-0.5, -grip.y + 1), Vector2(2.5, -grip.y + 1), Vector2(2.5, -grip.y + 25), Vector2(-0.5, -grip.y + 25)]), Color(GLOW, 0.45))
			bl.name = "Blade"
			_glow_poly(_weapon, PackedVector2Array([Vector2(0.5, -grip.y), Vector2(1.5, -grip.y + 1), Vector2(1.0, -grip.y + 24), Vector2(0.4, -grip.y + 24)]), CORE)
		"lantern_staff":
			var lg := _glow_poly(_weapon, Util.circle(4.5, 12), Color(GLOW, 0.35), Vector2(5, -grip.y + 9))
			lg.name = "Lantern"
			_glow_poly(_weapon, PackedVector2Array([Vector2(4, -grip.y + 7.5), Vector2(6, -grip.y + 7.5), Vector2(6, -grip.y + 10.5), Vector2(4, -grip.y + 10.5)]), CORE)
		"staff":
			_glow_poly(_weapon, PackedVector2Array([Vector2(0, -grip.y), Vector2(1.6, -grip.y + 3), Vector2(0, -grip.y + 6), Vector2(-1.6, -grip.y + 3)]), CORE)
			_glow_poly(_weapon, Util.circle(4.0, 12), Color(GLOW, 0.3), Vector2(0, -grip.y + 3))
		"glaive":
			# кромка разрыва: светится по краю лезвия
			_glow_poly(_weapon, PackedVector2Array([Vector2(-2, -grip.y + 4), Vector2(1, -grip.y + 0.3), Vector2(7, -grip.y - 0.3),
					Vector2(9.6, -grip.y + 2.8), Vector2(6.5, -grip.y + 1.4), Vector2(2, -grip.y + 1.6), Vector2(-0.5, -grip.y + 5)]), GLOW)
			_glow_poly(_weapon, PackedVector2Array([Vector2(0, -grip.y + 3), Vector2(4, -grip.y + 1), Vector2(6.5, -grip.y + 1.2), Vector2(3, -grip.y + 2.4)]), CORE)

# ---------- Порождение разлома: четвероногая тварь ----------
func _build_spawn() -> void:
	_humanoid = false
	px = _size().x / 24.0
	_art.scale = Vector2(px, px)
	var h := _size().y / px
	_hip = Node2D.new()
	_hip.position = Vector2(0, h / 2.0 - 6)
	_art.add_child(_hip)
	for k in 4:                                                     # тонкие ноги-лезвия
		var leg := Line2D.new()
		leg.width = 1.4
		leg.default_color = Color(0.20, 0.14, 0.24) if k % 2 else Color(0.28, 0.20, 0.32)
		leg.z_index = -1 if k % 2 else 1
		_hip.add_child(leg)
		_legs4.append(leg)
	var im := _img(24, 12)
	var c := Color(0.24, 0.16, 0.30)
	_poly(im, PackedVector2Array([Vector2(1, 8), Vector2(3, 4), Vector2(8, 2), Vector2(16, 2), Vector2(20, 4), Vector2(23, 7), Vector2(20, 10), Vector2(5, 10)]), c)
	for k in 5:                                                     # шипы на спине
		var x := 5 + k * 3
		_poly(im, PackedVector2Array([Vector2(x - 1, 3), Vector2(x + 0.5, -0.5 if k % 2 == 0 else 0.8), Vector2(x + 1.5, 3)]), Color(0.66, 0.62, 0.70))
	_rect(im, 18, 6, 4, 1, VOID)                                    # пасть
	_spr(_hip, im, Vector2(12, 8), Vector2.ZERO)
	_glow_poly(_hip, PackedVector2Array([Vector2(6, -1.8), Vector2(10, -1.2), Vector2(9.5, -0.8), Vector2(6, -1.2)]), CORE)
	for p2 in [Vector2(-5, -3), Vector2(0, -4), Vector2(3, -2)]:
		_glow_poly(_hip, PackedVector2Array([Vector2(-1, 0), Vector2(0, -0.6), Vector2(1, 0), Vector2(0, 0.6)]), GLOW, p2)
	_glow_poly(_hip, Util.circle(1.0, 8), CORE, Vector2(8.5, -3.5))        # глаз-щель

# ---------- Око разлома: парящий глаз ----------
func _build_eye() -> void:
	_humanoid = false
	px = _size().x / 22.0
	_art.scale = Vector2(px, px)
	for k in 5:                                                     # щупальца снизу
		var t := Line2D.new()
		t.width = 1.3
		t.default_color = Color(0.26, 0.16, 0.30)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0.2))
		t.gradient = g
		_art.add_child(t)
		_tendrils.append(t)
	var im := _img(22, 22)
	PixelArt._circle(im, 11, 11, 10, Color(0.24, 0.16, 0.28))
	PixelArt._circle(im, 11, 11, 7, Color(0.86, 0.82, 0.86))
	var s := _spr(_art, im, Vector2(11, 11), Vector2.ZERO)
	s.name = "Ball"
	_iris = Node2D.new()
	_art.add_child(_iris)
	var iris := Polygon2D.new()
	iris.polygon = Util.circle(3.6, 14)
	iris.color = GLOW
	_iris.add_child(iris)
	var pupil := Polygon2D.new()
	pupil.polygon = PackedVector2Array([Vector2(-0.6, -3), Vector2(0.6, -3), Vector2(0.6, 3), Vector2(-0.6, 3)])
	pupil.color = VOID
	_iris.add_child(pupil)
	_glows.append(iris)
	_teeth = Node2D.new()                                           # кольцо осколков-зубов
	_art.add_child(_teeth)
	for k in 10:
		var a := TAU * k / 10.0
		var th := Polygon2D.new()
		th.polygon = PackedVector2Array([Vector2(-1, 0), Vector2(0, -3.2), Vector2(1, 0)])
		th.color = Color(0.82, 0.78, 0.86) if k % 2 else Color(0.62, 0.40, 0.86)
		th.position = Vector2.from_angle(a) * 11.5
		th.rotation = a + PI / 2
		_teeth.add_child(th)

# ---------- Пустокрыл: небесный скат ----------
func _build_voidwing() -> void:
	_humanoid = false
	var sz := _size()
	px = sz.x / 64.0
	_art.scale = Vector2(px, px)
	# Огромный небесный скат, изъеденный разломом: тело-наконечник, два «рога» у пасти,
	# широкие рваные крылья с горящими прожилками и хвост-плеть с кристаллом.
	_tail = Line2D.new()                                            # хвост-плеть
	_tail.width = 2.6
	_tail.default_color = Color(0.16, 0.11, 0.22)
	_tail.width_curve = Curve.new()
	_tail.width_curve.add_point(Vector2(0, 1))
	_tail.width_curve.add_point(Vector2(1, 0.3))
	_art.add_child(_tail)
	_tail_tip = Node2D.new()
	_art.add_child(_tail_tip)
	_glow_poly(_tail_tip, PackedVector2Array([Vector2(0, -3), Vector2(5, 0), Vector2(0, 3), Vector2(-2.5, 0)]), GLOW)
	_glow_poly(_tail_tip, PackedVector2Array([Vector2(0, -1.2), Vector2(2.4, 0), Vector2(0, 1.2), Vector2(-1, 0)]), CORE)
	# дальнее крыло (вниз, темнее и короче — в перспективе)
	_wing_b = Node2D.new()
	_wing_b.position = Vector2(-2, 3)
	_art.add_child(_wing_b)
	var wb := _spr(_wing_b, _wing_img(true), Vector2(34, 29), Vector2.ZERO)
	wb.scale = Vector2(0.5, -0.36)
	# тело
	var im := _img(58, 22)
	var c := Color(0.17, 0.12, 0.25)
	_poly(im, PackedVector2Array([Vector2(1, 11), Vector2(10, 6.5), Vector2(24, 4.5), Vector2(38, 5), Vector2(47, 6.5),
			Vector2(53, 8.5), Vector2(56, 11), Vector2(53, 13.5), Vector2(47, 15.5), Vector2(38, 16.5), Vector2(24, 16.5), Vector2(10, 15)]), c)
	_poly(im, PackedVector2Array([Vector2(12, 13), Vector2(44, 13), Vector2(50, 14), Vector2(38, 16), Vector2(16, 15.5)]), Color(0.52, 0.47, 0.60))  # бледное брюхо
	for k in 9:                                                     # гребень на спине
		_p(im, 14 + k * 3, 5 + (k % 2), Color(0.30, 0.22, 0.42))
		_p(im, 14 + k * 3, 4, Color(0.42, 0.32, 0.56) if k % 2 == 0 else c)
	for k in 4:                                                     # жаберные щели
		for j in 3:
			_p(im, 40 - k * 2, 12 + j, Color(0.06, 0.03, 0.08))
	# «рога» у пасти — загнуты вперёд
	_poly(im, PackedVector2Array([Vector2(44, 7), Vector2(50, 1), Vector2(55, 1.5), Vector2(51, 4), Vector2(49, 8)]), Color(0.24, 0.17, 0.33))
	_poly(im, PackedVector2Array([Vector2(44, 15), Vector2(50, 21), Vector2(55, 20.5), Vector2(51, 18), Vector2(49, 14)]), Color(0.20, 0.14, 0.28))
	# пасть с клыками
	_poly(im, PackedVector2Array([Vector2(47, 11), Vector2(56, 10.5), Vector2(55, 12.5), Vector2(48, 12.5)]), VOID)
	for k in 4:
		_p(im, 49 + k * 2, 11, Color(0.92, 0.88, 0.82))
		_p(im, 50 + k * 2, 12, Color(0.92, 0.88, 0.82))
	_spr(_art, im, Vector2(29, 11), Vector2.ZERO)
	for p2 in [Vector2(-14, -3), Vector2(-7, -4.5), Vector2(0, -4), Vector2(7, -3.5)]:     # трещины разлома на спине
		_glow_poly(_art, PackedVector2Array([Vector2(-1.6, 0), Vector2(0, -0.9), Vector2(1.6, 0), Vector2(0, 0.9)]), GLOW, p2)
	for e in [Vector2(18, -2.6), Vector2(20.5, -2.0)]:                 # глаза
		_glow_poly(_art, Util.circle(1.2, 8), GLOW, e)
		_glow_poly(_art, Util.circle(0.55, 6), CORE, e)
	# ближнее крыло (вверх) — главный силуэт
	_wing_f = Node2D.new()
	_wing_f.position = Vector2(0, -4)
	_art.add_child(_wing_f)
	var wf := _spr(_wing_f, _wing_img(false), Vector2(34, 29), Vector2.ZERO)
	wf.scale = Vector2(0.5, 0.5)
	for g in [[Vector2(-8, -9), Vector2(-17, -20)], [Vector2(-2, -7), Vector2(-9, -19)], [Vector2(4, -5), Vector2(-1, -13)]]:   # горящие прожилки
		var l := Line2D.new()
		l.points = PackedVector2Array([g[0], g[0].lerp(g[1], 0.5) + Vector2(1.2, 0), g[1]])
		l.width = 0.9
		l.default_color = GLOW
		_wing_f.add_child(l)
		_glows.append(l)

# Крыло: широкий рваный парус от плеча (низ картинки) к кончику, отогнутому назад.
# Передний край — толстый и светлый, задний — рваный, с дырами-разрывами.
func _wing_img(back: bool) -> Image:
	var im := _img(48, 32)
	var c := Color(0.24, 0.16, 0.36).darkened(0.35 if back else 0.0)
	var pts := PackedVector2Array([Vector2(44, 30), Vector2(40, 22), Vector2(32, 13), Vector2(20, 5), Vector2(6, 1), Vector2(2, 2)])
	var y := 4.0
	while y < 30.0:                                                 # рваный задний край
		var dx := 2.5 if int(y) % 6 == 0 else (1.0 if int(y) % 3 == 0 else 0.0)
		pts.append(Vector2(5 + y * 0.42 + dx * 2.0, y))
		y += 1.5
	pts.append(Vector2(22, 31))
	_poly(im, pts, c)
	# толстый передний край
	var lead := [Vector2(44, 30), Vector2(40, 22), Vector2(32, 13), Vector2(20, 5), Vector2(6, 1)]
	for i in lead.size() - 1:
		for k in 12:
			var q: Vector2 = lead[i].lerp(lead[i + 1], k / 12.0)
			_p(im, int(q.x), int(q.y), c.lightened(0.28))
			_p(im, int(q.x), int(q.y) + 1, c.lightened(0.14))
	# дыры-разрывы с багровым краем
	if not back:
		for h in [Vector2(14, 16), Vector2(22, 22), Vector2(12, 24)]:
			for dy in range(-1, 2):
				for dx in range(-2, 3):
					if absi(dx) + absi(dy) <= 2:
						_p(im, int(h.x) + dx, int(h.y) + dy, Color(0, 0, 0, 0) if absi(dx) + absi(dy) <= 1 else GLOW.darkened(0.35))
	return im

# ---------------- интерфейс для бойца ----------------
func play(n: String) -> void:
	_act = n
	_act_t = 0.0
	_act_len = {"swing": 0.42, "punch": 0.3, "cast": 0.6, "shoot": 0.25, "throw": 0.35, "roar": 0.9, "slam": 0.7,
			"summon": 0.8, "blink": 0.5, "stomp": 0.6, "pounce": 0.5, "grasp": 0.6, "spin": 0.5, "kneel": 1.2}.get(n, 0.4)

func hurt() -> void:
	_hurt = 0.18

# Откуда вылетает выстрел: кончик оружия или рука
func muzzle() -> Vector2:
	if _weapon and is_instance_valid(_weapon):
		return _weapon.to_global(Vector2(10, 0) if kind == "rift_archer" else Vector2(0, -6))
	if _iris:
		return _iris.global_position
	if _arm_f:
		return _arm_f.to_global(Vector2(0, _arm_len))
	return global_position

func tip() -> Vector2:
	return muzzle()

# Кончик хвоста Пустокрыла / глаз Ока / кристалл Носителя — для эффектов
func point(which: String) -> Vector2:
	match which:
		"tail":
			return _tail_tip.global_position if _tail_tip else global_position
		"head":
			return _head.to_global(Vector2(4, -4)) if _head else global_position
		"crystal":
			return _back.to_global(Vector2(-5, 3)) if _back else global_position
		"blade":
			return _weapon.to_global(Vector2(5, -22)) if _weapon and kind == "harbinger" else muzzle()
	return global_position

func head_points() -> Array:
	return [point("head")]

func crack_mask() -> void:
	cracked = true
	if _crack:
		_crack.visible = true
	if _slit:
		_slit.scale = Vector2(2.2, 1.0)

# ---------------- анимация ----------------
func _process(delta: float) -> void:
	_t += delta
	_hurt = maxf(0.0, _hurt - delta)
	if _act != "":
		_act_t += delta
		if _act_t >= _act_len:
			_act = ""
	var f := _facing()
	scale.x = lerpf(scale.x, float(f), minf(1.0, delta * 16.0))
	if absf(scale.x) < 0.05:
		scale.x = 0.05 * signf(scale.x + 0.001)
	modulate = Color(1.6, 1.3, 1.7) if _hurt > 0.0 else Color.WHITE
	var pulse := 0.75 + 0.25 * sin(_t * 4.0)
	for g in _glows:
		if is_instance_valid(g):
			g.modulate.a = pulse
	if _wings and _wings.visible:
		var flap := sin(_t * 3.2) * 0.22
		_wing_l.rotation = -flap
		_wing_r.rotation = flap
	match kind:
		"rift_spawn": _pose_spawn(delta)
		"rift_eye": _pose_eye(delta)
		"voidwing": _pose_voidwing(delta)
		_: _pose_humanoid(delta)

func _k() -> float:
	return clampf(_act_t / maxf(_act_len, 0.01), 0.0, 1.0)

func _pose_humanoid(delta: float) -> void:
	var v := _vel()
	var moving := absf(v.x) > 30.0 and _floor()
	if moving:
		_phase += delta * clampf(absf(v.x) / 32.0, 4.0, 13.0)
	else:
		_phase = lerpf(_phase, roundf(_phase / PI) * PI, minf(1.0, delta * 8.0))
	var sw := sin(_phase)
	var air := not _floor() and levitate <= 0.0
	var leg_a := sw * 0.55 if moving else 0.0
	if air:
		leg_a = 0.4
	var lev := levitate
	var bob := absf(sin(_phase)) * -0.6 if moving else sin(_t * 2.0) * 0.25
	_hip.position = Vector2(0, _hip_y + bob - lev * 3.0 + sin(_t * 2.2) * lev * 1.2)
	_leg_f.rotation = lerpf(leg_a, 0.25, lev)
	_leg_b.rotation = lerpf(-leg_a if not air else -0.2, 0.45, lev)
	var arm_f := -sw * 0.45 if moving else sin(_t * 1.6) * 0.06
	var arm_b := sw * 0.45 if moving else -sin(_t * 1.6) * 0.06
	var torso_r := 0.08 if moving else 0.0
	var head_r := 0.0
	if kind == "rift_brute" or kind == "rift_bearer":
		torso_r += 0.12                                             # горбится
		head_r = 0.1
	if hold_aim > 0.0:
		arm_f = lerpf(arm_f, -PI / 2, hold_aim)
		arm_b = lerpf(arm_b, -PI / 2 + 0.2, hold_aim * (1.0 if kind == "rift_archer" else 0.0))
	var k := _k()
	match _act:
		"swing", "throw":
			# замах за голову — рубящий удар вперёд-вниз
			var a := lerpf(2.4, -1.3, ease((k - 0.25) / 0.75, 0.35)) if k > 0.25 else lerpf(arm_f, 2.4, k / 0.25)
			arm_f = a
			if kind == "rift_blade":
				arm_b = lerpf(-1.4, 2.0, ease(k, 0.4))               # второй серп — обратным махом
			torso_r = lerpf(-0.15, 0.25, k)
		"punch", "grasp":
			arm_f = lerpf(arm_f, -PI / 2 - 0.1, minf(1.0, k * 3.0))
			torso_r = 0.2
		"shoot":
			arm_f = -PI / 2 + (0.15 if k < 0.3 else 0.0)
			arm_b = -PI / 2 + 0.3
		"cast", "summon":
			var up := sin(k * PI)
			arm_f = lerpf(arm_f, -2.5 if _act == "summon" else -1.4, up)
			arm_b = lerpf(arm_b, -2.6 if _act == "summon" else -1.0, up)
			head_r = -0.15 * up
		"roar":
			var up2 := sin(k * PI)
			arm_f = lerpf(arm_f, -2.2, up2)
			arm_b = lerpf(arm_b, 1.9, up2)
			head_r = -0.35 * up2
			torso_r = -0.12 * up2
		"slam", "stomp":
			if k < 0.55:
				arm_f = lerpf(arm_f, -2.9, k / 0.55)
				arm_b = lerpf(arm_b, -2.7, k / 0.55)
				torso_r = -0.2 * k / 0.55
			else:
				var kk := (k - 0.55) / 0.45
				arm_f = lerpf(-2.9, -0.4, minf(1.0, kk * 3.0))
				arm_b = lerpf(-2.7, -0.2, minf(1.0, kk * 3.0))
				torso_r = 0.35 * (1.0 - kk)
		"blink":
			_art.scale = Vector2(px * (1.0 - 0.85 * sin(k * PI)), px * (1.0 + 0.35 * sin(k * PI)))
		"spin":
			arm_f = -PI / 2
			_hip.rotation = k * TAU
		"kneel":
			_hip.position.y += 3.0 * sin(minf(1.0, k * 2.0) * PI / 2)
			torso_r = 0.35
			head_r = 0.3
			arm_f = 0.3
	if _act != "blink":
		_art.scale = _art.scale.lerp(Vector2(px, px), minf(1.0, delta * 14.0))
	if _act != "spin":
		_hip.rotation = lerpf(_hip.rotation, 0.0, minf(1.0, delta * 10.0))
	_arm_f.rotation = lerp_angle(_arm_f.rotation, arm_f, minf(1.0, delta * 22.0))
	if _weapon and kind in ["harbinger", "rift_bearer", "wanderer"]:
		# древковое оружие: в покое стоит торчком, в ударе — продолжение руки (лезвие вперёд)
		var wr := PI if _act in ["swing", "throw", "slam", "stomp", "punch", "spin"] else 0.0
		_weapon.rotation = lerp_angle(_weapon.rotation, wr, minf(1.0, delta * 18.0))
	_arm_b.rotation = lerp_angle(_arm_b.rotation, arm_b, minf(1.0, delta * 22.0))
	_torso.rotation = lerpf(_torso.rotation, torso_r, minf(1.0, delta * 12.0))
	_head.rotation = lerpf(_head.rotation, head_r, minf(1.0, delta * 10.0))
	if _cloak:
		_cloak.rotation = lerpf(_cloak.rotation, (0.25 if moving else 0.05) + sin(_t * 3.0) * 0.05 + (0.3 if air else 0.0) + lev * 0.25,
				minf(1.0, delta * 6.0))
	if _halo:
		_halo.rotation += delta * 0.4
	if _back and kind == "rift_bearer":
		var cg := _back.get_node_or_null("CrystalGlow")
		if cg:
			cg.scale = Vector2.ONE * (1.0 + 0.15 * sin(_t * 3.0))

func _pose_spawn(delta: float) -> void:
	var v := _vel()
	var moving := absf(v.x) > 30.0
	if moving:
		_phase += delta * clampf(absf(v.x) / 22.0, 6.0, 22.0)
	var hip_y := _hip.position.y
	for i in _legs4.size():
		var leg: Line2D = _legs4[i]
		var ox: float = [-6.0, -3.0, 4.0, 7.0][i]
		var ph := _phase + (PI if i % 2 else 0.0) + i * 0.7
		var lift := maxf(0.0, sin(ph)) * 2.5 if moving else 0.0
		var foot := Vector2(ox + cos(ph) * (2.5 if moving else 0.0), 6.0 - lift)
		leg.points = PackedVector2Array([Vector2(ox * 0.7, -1), Vector2(ox + signf(ox) * 2.5, 2.0 - lift * 0.5), foot])
	_hip.rotation = lerpf(_hip.rotation, (-0.35 if _act == "pounce" else 0.0) + sin(_phase) * 0.04, minf(1.0, delta * 10.0))
	_hip.position.y = hip_y

func _pose_eye(delta: float) -> void:
	var tgt := Vector2(1, 0)
	if bot and is_instance_valid(bot.target):
		tgt = (bot.target.global_position - global_position).normalized()
		tgt.x *= signf(scale.x) if scale.x != 0.0 else 1.0
	_iris.position = _iris.position.lerp(tgt * 3.4, minf(1.0, delta * 8.0))
	_iris.scale = Vector2.ONE * (1.0 + 0.35 * hold_aim)
	_art.position.y = sin(_t * 2.4) * 1.2
	_teeth.rotation += delta * (0.6 + hold_aim * 6.0)
	for i in _tendrils.size():
		var t: Line2D = _tendrils[i]
		var x0 := -6.0 + i * 3.0
		var pts := PackedVector2Array()
		for s in 6:
			pts.append(Vector2(x0 + sin(_t * 3.0 + i + s * 0.8) * s * 0.6, 9.0 + s * 2.2))
		t.points = pts

func _pose_voidwing(delta: float) -> void:
	var spd := 3.0 if _act != "roar" else 6.5
	var flap := sin(_t * spd)
	if _act == "slam" or _act == "stomp":
		flap = -1.0                                         # пикирует — крылья прижаты
	elif _act == "roar":
		flap = sin(_t * spd) * 0.4 + 0.6                    # раскрыл крылья во всю ширь
	_wing_f.scale.y = 0.45 + 0.55 * (0.5 + 0.5 * flap)     # вверх — во всю ширь, вниз — складывается
	_wing_f.rotation = -0.08 * flap
	_wing_b.scale.y = 0.55 + 0.45 * (0.5 - 0.5 * flap)
	_art.position.y = -flap * 1.6
	var v := _vel()
	_art.rotation = lerpf(_art.rotation, clampf(v.y / 900.0, -0.35, 0.35) * signf(scale.x + 0.001), minf(1.0, delta * 4.0))
	var pts := PackedVector2Array()
	var base := Vector2(-28, 0.5)
	for s in 13:
		var w := sin(_t * 3.0 - s * 0.55) * s * 0.5
		pts.append(base + Vector2(-s * 3.0, w))
	_tail.points = pts
	_tail_tip.position = pts[pts.size() - 1]
	_tail_tip.rotation = PI

