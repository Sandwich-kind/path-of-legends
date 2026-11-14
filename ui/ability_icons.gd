class_name AbilityIcons
# ---------- Значки способностей на экранных кнопках ----------
# Каждый значок — маленькая пиксельная картинка 32×32, нарисованная кодом,
# с тёмным контуром и светом сверху. Для тестовых героев значков нет —
# у них остаются цифры.

static var _cache := {}

const OUT := Color(0.06, 0.05, 0.07)

# Значок оружия (для кнопки стрельбы) по набору героя
const WEAPONS := {"hunter": "w_bow", "smith": "w_hammer", "champion": "w_javelin", "ternovnik": "w_seed",
		"mortis": "w_soul", "soldier": "w_rifle", "samurai": "w_katana",
		"prism": "w_light", "assassin": "w_kunai", "osoka": "w_tina", "zarnitsa": "w_spark", "rassvet": "w_dawn", "pivozavr": "w_caps", "gatekeeper": "w_key", "echo": "w_lamp", "seam": "w_needle", "glav": "w_soda", "genius": "w_usb", "scribe": "w_quill", "dj": "w_vinyl", "almost": "w_fist"}

static func has(id: String) -> bool:
	return texture(id) != null

# Готовый узел со значком, вписанным в квадрат size
static func make(id: String, size: float) -> Sprite2D:
	var tex := texture(id)
	if tex == null:
		return null
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * (size / 32.0)
	return s

static func texture(id: String) -> ImageTexture:
	if _cache.has(id):
		return _cache[id]
	var im = _draw(id, false)
	if im == null:
		return null
	_outline(im)
	var t := ImageTexture.create_from_image(im)
	_cache[id] = t
	return t

# ---------- Рисование ----------
static func _img() -> Image:
	return Image.create(32, 32, false, Image.FORMAT_RGBA8)

static func _px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < 32 and y < 32:
		im.set_pixel(x, y, c)

static func _rect(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(im, xx, yy, c)

static func _line(im: Image, a: Vector2, b: Vector2, c: Color, t := 1) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		for dy in t:
			for dx in t:
				_px(im, int(p.x) + dx, int(p.y) + dy, c)

static func _disc(im: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				_px(im, x, y, c)

static func _ring(im: Image, cx: float, cy: float, r: float, c: Color, t := 1.5) -> void:
	for y in 32:
		for x in 32:
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if absf(d - r) <= t / 2.0:
				_px(im, x, y, c)

static func _poly(im: Image, pts: PackedVector2Array, c: Color) -> void:
	for y in 32:
		for x in 32:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				_px(im, x, y, c)

# Тёмный контур вокруг рисунка и блик сверху — значок читается на любом фоне
static func _outline(im: Image) -> void:
	var src := im.duplicate() as Image
	for y in 32:
		for x in 32:
			var p := src.get_pixel(x, y)
			if p.a > 0.0:
				if y > 0 and src.get_pixel(x, y - 1).a <= 0.0:
					im.set_pixel(x, y, p.lightened(0.25))
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < 32 and q.y < 32 and src.get_pixel(q.x, q.y).a > 0.0:
					im.set_pixel(x, y, OUT)
					break

# Возвращает Image или null (нет значка). probe — только проверить наличие.
static func _draw(id: String, probe: bool):
	var im := _img()
	var gold := Color(1.0, 0.8, 0.3)
	var steel := Color(0.78, 0.8, 0.86)
	var wood := Color(0.58, 0.38, 0.2)
	match id:
		# ---------- Охотница ----------
		"roll":
			_ring(im, 16, 16, 10, Color(0.55, 1.0, 0.7), 3.0)
			_poly(im, PackedVector2Array([Vector2(4, 12), Vector2(10, 6), Vector2(11, 14)]), Color(0.55, 1.0, 0.7))
			_line(im, Vector2(10, 22), Vector2(24, 9), steel, 2)                 # зачарованная стрела
			_poly(im, PackedVector2Array([Vector2(22, 7), Vector2(27, 5), Vector2(25, 11)]), Color(0.7, 1.0, 0.8))
		"trap":
			_rect(im, 5, 22, 22, 4, Color(0.4, 0.38, 0.38))
			for k in 5:
				_poly(im, PackedVector2Array([Vector2(5 + k * 4, 22), Vector2(7 + k * 4, 13), Vector2(9 + k * 4, 22)]), steel)
			_disc(im, 16, 24, 3, gold)
		"hook":
			_line(im, Vector2(5, 27), Vector2(22, 9), Color(0.85, 0.78, 0.6), 1)
			_poly(im, PackedVector2Array([Vector2(20, 6), Vector2(28, 4), Vector2(26, 12)]), steel)
			_line(im, Vector2(24, 8), Vector2(29, 12), steel, 2)
			_disc(im, 8, 9, 4, Color(1.0, 0.55, 0.15))                          # взрывная стрела
			_disc(im, 8, 9, 2, Color(1.0, 0.9, 0.4))
		"arrow_sky":
			for k in 5:
				var x := 5 + k * 5
				_line(im, Vector2(x, 4 + (k % 2) * 4), Vector2(x, 20 + (k % 2) * 4), wood, 1)
				_poly(im, PackedVector2Array([Vector2(x - 2, 20 + (k % 2) * 4), Vector2(x + 2, 20 + (k % 2) * 4), Vector2(x, 25 + (k % 2) * 4)]), steel)
			_ring(im, 16, 28, 8, gold, 1.5)
		"w_bow":
			for y in range(3, 29):
				var bx := 9 + int(7.0 * sin(PI * (y - 3) / 25.0))
				_rect(im, bx, y, 2, 1, wood)
			_line(im, Vector2(9, 3), Vector2(9, 28), Color(0.95, 0.93, 0.85), 1)
			_line(im, Vector2(6, 16), Vector2(28, 16), wood.lightened(0.2), 1)
			_poly(im, PackedVector2Array([Vector2(26, 13), Vector2(31, 16), Vector2(26, 19)]), steel)
		# ---------- Кузнец ----------
		"hammer_leap":
			_line(im, Vector2(9, 25), Vector2(19, 9), wood, 3)
			_rect(im, 14, 3, 12, 8, steel.darkened(0.2))
			_rect(im, 15, 4, 10, 2, steel)
			_line(im, Vector2(3, 29), Vector2(29, 29), Color(0.9, 0.85, 0.7), 1)
			for k in [-1, 1]:
				_line(im, Vector2(16 + k * 4, 28), Vector2(16 + k * 13, 22), Color(0.95, 0.9, 0.75), 1)
		"anvil":
			_poly(im, PackedVector2Array([Vector2(3, 9), Vector2(29, 9), Vector2(29, 14), Vector2(22, 14), Vector2(20, 20),
					Vector2(25, 26), Vector2(7, 26), Vector2(12, 20), Vector2(10, 14), Vector2(3, 13)]), Color(0.32, 0.32, 0.38))
			_rect(im, 4, 9, 25, 2, Color(0.75, 0.75, 0.82))
			_line(im, Vector2(16, 1), Vector2(16, 6), gold, 2)
		"hammer_throw":
			_ring(im, 16, 16, 12, Color(1, 1, 1, 0.6), 1.0)
			_line(im, Vector2(8, 24), Vector2(18, 12), wood, 3)
			_poly(im, PackedVector2Array([Vector2(14, 6), Vector2(24, 4), Vector2(27, 13), Vector2(17, 15)]), steel.darkened(0.15))
			_line(im, Vector2(16, 7), Vector2(24, 6), steel, 1)
		"forge":
			_disc(im, 16, 18, 11, Color(1.0, 0.45, 0.1))
			_disc(im, 16, 19, 7, Color(1.0, 0.75, 0.25))
			_line(im, Vector2(11, 26), Vector2(18, 12), wood, 3)
			_rect(im, 14, 5, 11, 8, Color(1.0, 0.4, 0.15))
			_rect(im, 15, 6, 9, 2, Color(1.0, 0.85, 0.5))
		"w_hammer":
			_line(im, Vector2(8, 28), Vector2(18, 12), wood, 3)
			_rect(im, 12, 4, 16, 10, steel.darkened(0.25))
			_rect(im, 13, 5, 14, 3, steel)
		# ---------- Чемпион ----------
		"bash":
			_disc(im, 14, 16, 11, Color(0.7, 0.15, 0.12))
			_ring(im, 14, 16, 11, gold, 2.0)
			_rect(im, 12, 11, 4, 10, gold)
			for k in 3:
				_line(im, Vector2(26, 9 + k * 6), Vector2(31, 9 + k * 6), Color(1, 1, 1, 0.8), 1)
		"net":
			for k in 5:
				_line(im, Vector2(4 + k * 6, 4), Vector2(4 + k * 6, 28), Color(0.9, 0.88, 0.75), 1)
				_line(im, Vector2(4, 4 + k * 6), Vector2(28, 4 + k * 6), Color(0.9, 0.88, 0.75), 1)
			_ring(im, 16, 16, 13, Color(0.8, 0.7, 0.5), 1.5)
		"roar":
			_poly(im, PackedVector2Array([Vector2(4, 12), Vector2(10, 12), Vector2(18, 5), Vector2(18, 27), Vector2(10, 20), Vector2(4, 20)]), gold)
			for k in 3:
				_ring(im, 16, 16, 9 + k * 4, Color(1, 0.9, 0.5, 0.9 - k * 0.2), 1.0)
		"light_spears":
			for k in 3:
				_line(im, Vector2(6 + k * 9, 30), Vector2(6 + k * 9, 0), Color(1.0, 0.95, 0.6, 0.55), 3)
				_line(im, Vector2(4 + k * 9, 24), Vector2(10 + k * 9, 8), wood, 1)
				_poly(im, PackedVector2Array([Vector2(9 + k * 9, 5), Vector2(13 + k * 9, 4), Vector2(11 + k * 9, 10)]), gold)
		"w_javelin":
			_line(im, Vector2(3, 28), Vector2(24, 7), wood, 2)
			_poly(im, PackedVector2Array([Vector2(21, 7), Vector2(30, 2), Vector2(25, 11)]), steel)
		# ---------- Терновник ----------
		"roots":
			_rect(im, 2, 26, 28, 4, Color(0.4, 0.28, 0.16))
			for k in 4:
				_poly(im, PackedVector2Array([Vector2(3 + k * 7, 27), Vector2(6 + k * 7, 8 + (k % 2) * 5), Vector2(9 + k * 7, 27)]), Color(0.5, 0.34, 0.18))
				_px(im, 6 + k * 7, 9 + (k % 2) * 5, Color(0.6, 1.0, 0.4))
		"totem":
			_rect(im, 11, 6, 10, 23, Color(0.5, 0.36, 0.2))
			_rect(im, 13, 9, 2, 2, Color(0.6, 1.0, 0.35))
			_rect(im, 17, 9, 2, 2, Color(0.6, 1.0, 0.35))
			_rect(im, 7, 14, 4, 4, Color(0.3, 0.6, 0.25))
			_rect(im, 21, 14, 4, 4, Color(0.3, 0.6, 0.25))
			_disc(im, 16, 4, 4, Color(0.35, 0.7, 0.3))
			_poly(im, PackedVector2Array([Vector2(24, 22), Vector2(28, 22), Vector2(28, 18), Vector2(30, 18), Vector2(30, 22),
					Vector2(32, 22), Vector2(32, 24), Vector2(30, 24), Vector2(30, 28), Vector2(28, 28), Vector2(28, 24), Vector2(24, 24)]), Color(0.5, 1.0, 0.5))
		"vine":
			for y in 26:
				_rect(im, 6 + int(4 * sin(y * 0.4)) + y / 2, 28 - y, 2, 1, Color(0.3, 0.62, 0.22))
			_poly(im, PackedVector2Array([Vector2(20, 22), Vector2(26, 22), Vector2(27, 30), Vector2(19, 30)]), Color(0.4, 0.95, 0.35))
			_rect(im, 21, 19, 4, 3, Color(0.75, 0.6, 0.4))
		"ent":
			_rect(im, 11, 10, 10, 20, Color(0.48, 0.34, 0.2))
			_disc(im, 16, 9, 9, Color(0.28, 0.58, 0.22))
			_disc(im, 12, 7, 4, Color(0.38, 0.7, 0.3))
			_rect(im, 13, 15, 2, 2, Color(0.6, 1.0, 0.35))
			_rect(im, 17, 15, 2, 2, Color(0.6, 1.0, 0.35))
			_line(im, Vector2(11, 18), Vector2(4, 12), Color(0.48, 0.34, 0.2), 2)
			_line(im, Vector2(20, 18), Vector2(28, 12), Color(0.48, 0.34, 0.2), 2)
		"w_seed":
			_disc(im, 16, 16, 7, Color(0.45, 0.68, 0.25))
			for k in 8:
				var a := TAU * k / 8.0
				_line(im, Vector2(16, 16) + Vector2.from_angle(a) * 6, Vector2(16, 16) + Vector2.from_angle(a) * 12, Color(0.55, 0.4, 0.2), 1)
		# ---------- Мортис ----------
		"summon":
			_disc(im, 16, 12, 7, Color(0.9, 0.88, 0.8))
			_rect(im, 12, 10, 3, 3, OUT)
			_rect(im, 17, 10, 3, 3, OUT)
			_rect(im, 12, 17, 8, 3, Color(0.9, 0.88, 0.8))
			for k in 3:
				_px(im, 13 + k * 2, 18, OUT)
			_ring(im, 16, 27, 10, Color(0.75, 0.45, 1.0), 1.5)
		"bones":
			_ring(im, 16, 16, 11, Color(0.75, 0.45, 1.0, 0.8), 1.0)
			for a in [0.0, 2.1, 4.2]:
				var c2 := Vector2(16, 16) + Vector2.from_angle(a) * 10
				_line(im, c2 - Vector2(3, 0), c2 + Vector2(3, 0), Color(0.92, 0.9, 0.82), 2)
				_disc(im, c2.x - 3, c2.y, 1.5, Color(0.92, 0.9, 0.82))
				_disc(im, c2.x + 4, c2.y, 1.5, Color(0.92, 0.9, 0.82))
		"ghost":
			_poly(im, PackedVector2Array([Vector2(8, 28), Vector2(8, 12), Vector2(12, 6), Vector2(20, 6), Vector2(24, 12),
					Vector2(24, 28), Vector2(20, 24), Vector2(16, 28), Vector2(12, 24)]), Color(0.8, 0.75, 1.0, 0.9))
			_rect(im, 12, 13, 3, 3, Color(0.3, 0.1, 0.5))
			_rect(im, 18, 13, 3, 3, Color(0.3, 0.1, 0.5))
		"king_sword":
			_rect(im, 14, 2, 5, 22, Color(0.75, 0.6, 1.0))
			_rect(im, 15, 3, 2, 20, Color(0.95, 0.9, 1.0))
			_poly(im, PackedVector2Array([Vector2(14, 24), Vector2(19, 24), Vector2(16, 30)]), Color(0.75, 0.6, 1.0))
			_rect(im, 9, 5, 15, 3, Color(0.6, 0.45, 0.9))
			_poly(im, PackedVector2Array([Vector2(3, 6), Vector2(6, 2), Vector2(8, 6), Vector2(10, 2), Vector2(12, 6)]), gold)
		"w_soul":
			_disc(im, 18, 14, 8, Color(0.7, 0.45, 1.0))
			_disc(im, 16, 12, 4, Color(0.95, 0.85, 1.0))
			_poly(im, PackedVector2Array([Vector2(12, 18), Vector2(3, 28), Vector2(8, 20)]), Color(0.6, 0.4, 0.9, 0.8))
		# ---------- Солдат ----------
		"pistol":
			_rect(im, 6, 10, 18, 6, Color(0.25, 0.25, 0.28))
			_rect(im, 7, 11, 16, 1, Color(0.5, 0.5, 0.55))
			_rect(im, 8, 16, 6, 10, Color(0.3, 0.22, 0.15))
			for k in 3:
				_line(im, Vector2(25, 13), Vector2(31, 7 + k * 6), Color(0.55, 0.85, 1.0), 1)
		"roll_grenade":
			_ring(im, 13, 16, 10, Color(1, 1, 1, 0.7), 2.0)
			_poly(im, PackedVector2Array([Vector2(22, 8), Vector2(28, 12), Vector2(21, 15)]), Color(1, 1, 1, 0.7))
			_disc(im, 23, 22, 6, Color(0.3, 0.42, 0.22))
			_rect(im, 21, 14, 4, 3, Color(0.5, 0.5, 0.5))
			_px(im, 25, 13, Color(1.0, 0.4, 0.2))
		"knife":
			_poly(im, PackedVector2Array([Vector2(4, 20), Vector2(20, 14), Vector2(30, 14), Vector2(20, 18)]), steel)
			_line(im, Vector2(20, 15), Vector2(29, 15), Color(1, 1, 1), 1)
			_rect(im, 2, 18, 8, 5, Color(0.15, 0.13, 0.12))
			_rect(im, 9, 15, 2, 9, Color(0.45, 0.45, 0.48))
		"airstrike":
			_poly(im, PackedVector2Array([Vector2(2, 8), Vector2(24, 7), Vector2(30, 9), Vector2(24, 11), Vector2(2, 10)]), Color(0.36, 0.42, 0.32))
			_poly(im, PackedVector2Array([Vector2(10, 9), Vector2(16, 9), Vector2(8, 17), Vector2(4, 17)]), Color(0.3, 0.35, 0.27))
			_ring(im, 20, 25, 6, Color(1.0, 0.25, 0.2), 1.5)
			_line(im, Vector2(20, 18), Vector2(20, 31), Color(1.0, 0.25, 0.2), 1)
			_line(im, Vector2(13, 25), Vector2(27, 25), Color(1.0, 0.25, 0.2), 1)
		"w_rifle":
			_rect(im, 2, 13, 26, 5, Color(0.22, 0.22, 0.24))
			_rect(im, 2, 14, 7, 6, Color(0.18, 0.18, 0.2))
			_rect(im, 14, 18, 4, 7, Color(0.28, 0.24, 0.16))
			_rect(im, 10, 11, 6, 2, Color(0.12, 0.12, 0.14))
			_rect(im, 28, 14, 3, 2, Color(1.0, 0.8, 0.3))
		# ---------- Самурай ----------
		"wave":
			_poly(im, PackedVector2Array([Vector2(4, 28), Vector2(10, 10), Vector2(24, 3), Vector2(16, 12), Vector2(10, 28)]), Color(1, 1, 1, 0.9))
			_line(im, Vector2(8, 26), Vector2(28, 6), steel, 2)
			_rect(im, 5, 25, 4, 4, Color(0.85, 0.7, 0.25))
		"shuriken":
			for c3 in [Vector2(10, 11), Vector2(22, 9), Vector2(16, 23)]:
				_poly(im, PackedVector2Array([c3 + Vector2(0, -6), c3 + Vector2(1.5, -1.5), c3 + Vector2(6, 0), c3 + Vector2(1.5, 1.5),
						c3 + Vector2(0, 6), c3 + Vector2(-1.5, 1.5), c3 + Vector2(-6, 0), c3 + Vector2(-1.5, -1.5)]), steel)
				_px(im, int(c3.x), int(c3.y), OUT)
		"dash":
			for k in 3:
				_line(im, Vector2(4 + k * 3, 28 - k), Vector2(22, 8), Color(1, 1, 1, 0.35 + k * 0.2), 1)
			_poly(im, PackedVector2Array([Vector2(18, 4), Vector2(29, 3), Vector2(25, 13)]), Color(0.9, 0.95, 1.0))
		"flame_blade":
			_poly(im, PackedVector2Array([Vector2(16, 1), Vector2(25, 14), Vector2(21, 28), Vector2(11, 28), Vector2(7, 14)]), Color(1.0, 0.45, 0.1))
			_poly(im, PackedVector2Array([Vector2(16, 8), Vector2(21, 17), Vector2(18, 27), Vector2(14, 27), Vector2(11, 17)]), Color(1.0, 0.85, 0.35))
			_rect(im, 15, 6, 3, 24, steel)
			_rect(im, 11, 25, 11, 2, gold)
		# ---------- Призма ----------
		"w_light":
			for k in 3:
				var cl: Color = [Color(1.0, 0.6, 0.7), Color(0.7, 1.0, 0.8), Color(0.7, 0.85, 1.0)][k]
				_line(im, Vector2(3, 26 - k * 7), Vector2(14, 20 - k * 7), Color(cl, 0.5), 1)
				_poly(im, PackedVector2Array([Vector2(13, 18 - k * 7), Vector2(24, 20 - k * 7), Vector2(13, 22 - k * 7)]), cl)
				_px(im, 22, 20 - k * 7, Color(1, 1, 1))
			_line(im, Vector2(24, 4), Vector2(29, 9), Color(1, 1, 1), 1)
		"mirror_wall":
			_poly(im, PackedVector2Array([Vector2(11, 2), Vector2(20, 5), Vector2(21, 29), Vector2(10, 29)]), Color(0.45, 0.55, 0.95))
			_poly(im, PackedVector2Array([Vector2(13, 5), Vector2(18, 7), Vector2(19, 27), Vector2(12, 27)]), Color(0.82, 0.92, 1.0))
			_line(im, Vector2(14, 9), Vector2(17, 13), Color(1, 1, 1), 1)
			_line(im, Vector2(1, 10), Vector2(11, 15), Color(1.0, 0.45, 0.4), 2)          # снаряд прилетел...
			_line(im, Vector2(11, 15), Vector2(2, 22), Color(0.6, 0.9, 1.0), 2)           # ...и отлетел
			_poly(im, PackedVector2Array([Vector2(1, 20), Vector2(5, 25), Vector2(0, 25)]), Color(0.6, 0.9, 1.0))
		"crystal_pillar":
			_rect(im, 3, 27, 26, 3, Color(0.42, 0.36, 0.4))
			_poly(im, PackedVector2Array([Vector2(11, 27), Vector2(12, 8), Vector2(16, 2), Vector2(20, 8), Vector2(21, 27)]), Color(0.55, 0.72, 1.0))
			_poly(im, PackedVector2Array([Vector2(14, 26), Vector2(14, 9), Vector2(16, 5), Vector2(17, 26)]), Color(0.85, 0.93, 1.0))
			_poly(im, PackedVector2Array([Vector2(4, 27), Vector2(7, 18), Vector2(10, 27)]), Color(0.75, 0.5, 1.0))
			_poly(im, PackedVector2Array([Vector2(22, 27), Vector2(25, 20), Vector2(28, 27)]), Color(0.5, 0.9, 1.0))
		"refract":
			_poly(im, PackedVector2Array([Vector2(4, 28), Vector2(6, 14), Vector2(10, 10), Vector2(14, 14), Vector2(15, 28)]), Color(0.65, 0.8, 1.0, 0.7))
			_disc(im, 10, 7, 3, Color(0.8, 0.9, 1.0, 0.7))
			for k in 3:
				var c4: Color = [Color(1.0, 0.4, 0.45), Color(0.45, 1.0, 0.55), Color(0.45, 0.6, 1.0)][k]
				_line(im, Vector2(15, 14 + k * 4), Vector2(28, 10 + k * 6), c4, 1)
			_poly(im, PackedVector2Array([Vector2(24, 4), Vector2(29, 8), Vector2(26, 13), Vector2(21, 9)]), Color(1, 1, 1))
		"prism_ray":
			var rb := [Color(1.0, 0.25, 0.3), Color(1.0, 0.6, 0.2), Color(1.0, 0.95, 0.3), Color(0.35, 1.0, 0.45),
					Color(0.3, 0.85, 1.0), Color(0.35, 0.45, 1.0), Color(0.8, 0.4, 1.0)]
			for k in 7:
				var cy := 4.0 + k * 4.0
				_poly(im, PackedVector2Array([Vector2(3, cy - 2), Vector2(6, cy), Vector2(3, cy + 2), Vector2(1, cy)]), rb[k])
				_line(im, Vector2(5, cy), Vector2(14, 16), Color(rb[k], 0.8), 1)
			_rect(im, 14, 13, 18, 7, Color(1, 1, 1, 0.45))
			_rect(im, 14, 15, 18, 3, Color(1, 1, 1))
			_disc(im, 14, 16, 3, Color(1, 1, 1))
		# ---------- Ассасин ----------
		"w_kunai":
			for k in 2:
				var oy := k * 9
				_line(im, Vector2(4, 22 - oy), Vector2(12, 18 - oy), Color(0.45, 0.25, 0.15), 2)
				_poly(im, PackedVector2Array([Vector2(12, 15 - oy), Vector2(26, 13 - oy), Vector2(13, 21 - oy)]), steel)
				_line(im, Vector2(13, 18 - oy), Vector2(25, 13 - oy), Color(1, 1, 1), 1)
				_ring(im, 3, 23 - oy, 2, steel, 1.0)
		"blade_storm":
			_ring(im, 16, 17, 11, Color(0.5, 0.9, 0.6, 0.7), 2.0)
			for k in 4:
				var a := TAU * k / 4.0 + 0.4
				var c5 := Vector2(16, 17) + Vector2.from_angle(a) * 9.0
				_poly(im, PackedVector2Array([c5 + Vector2.from_angle(a + 1.6) * 6.0, c5 + Vector2.from_angle(a) * 3.0, c5 + Vector2.from_angle(a - 0.4) * 2.0]), steel)
			_disc(im, 16, 17, 4, Color(0.15, 0.3, 0.25))
			_px(im, 17, 16, Color(0.8, 0.15, 0.15))
		"stun_bomb":
			_disc(im, 15, 19, 9, Color(0.22, 0.2, 0.24))
			_rect(im, 6, 18, 18, 3, Color(0.55, 0.35, 0.75))
			_line(im, Vector2(16, 10), Vector2(20, 4), Color(0.75, 0.65, 0.45), 1)
			_disc(im, 21, 3, 2, Color(1.0, 0.85, 0.3))
			for c6 in [Vector2(4, 8), Vector2(27, 10), Vector2(27, 26)]:
				_poly(im, PackedVector2Array([c6 + Vector2(0, -3), c6 + Vector2(1, -1), c6 + Vector2(3, 0), c6 + Vector2(1, 1), c6 + Vector2(0, 3), c6 + Vector2(-1, 1), c6 + Vector2(-3, 0), c6 + Vector2(-1, -1)]), Color(1.0, 0.9, 0.4))
		"kunai_leap":
			_line(im, Vector2(4, 28), Vector2(14, 6), Color(0.6, 1.0, 0.75, 0.6), 2)
			_disc(im, 16, 6, 3, Color(0.15, 0.3, 0.25))
			for k in 5:
				var a2 := deg_to_rad(55.0 + k * 17.5)
				var s2 := Vector2(16, 9) + Vector2.from_angle(a2) * 6.0
				_line(im, s2, s2 + Vector2.from_angle(a2) * 12.0, steel, 1)
		"shadow_strike":
			_line(im, Vector2(18, 31), Vector2(20, 0), Color(0.65, 0.4, 0.95), 3)
			_line(im, Vector2(18, 31), Vector2(20, 0), Color(1, 1, 1), 1)
			var star2 := PackedVector2Array()
			for i in 8:
				star2.append(Vector2(9, 20) + Vector2.from_angle(TAU * i / 8.0) * (7.0 if i % 2 == 0 else 2.5))
			_poly(im, star2, steel)
			_poly(im, PackedVector2Array([Vector2(22, 14), Vector2(28, 12), Vector2(29, 28), Vector2(23, 30)]), Color(0.1, 0.08, 0.14))
		"w_katana":
			_line(im, Vector2(6, 27), Vector2(27, 4), steel, 2)
			_line(im, Vector2(7, 27), Vector2(27, 5), Color(1, 1, 1), 1)
			_rect(im, 5, 23, 6, 2, gold)
			_line(im, Vector2(2, 30), Vector2(7, 25), Color(0.15, 0.12, 0.15), 2)
		# ---------- Осока ----------
		"w_tina":
			var mud := Color(0.36, 0.40, 0.22)
			_disc(im, 18, 14, 8, mud)
			_disc(im, 15, 11, 3, mud.lightened(0.2))
			for k in 4:
				_px(im, 12 + k * 3, 21 + k % 2, Color(0.45, 0.62, 0.26))
			_line(im, Vector2(4, 28), Vector2(10, 20), Color(0.36, 0.40, 0.22, 0.7), 2)     # след полёта
			_disc(im, 6, 27, 2, mud.darkened(0.2))
		"mud_dive":
			var mud2 := Color(0.32, 0.38, 0.20)
			_rect(im, 1, 24, 30, 7, Color(0.20, 0.26, 0.12))
			_poly(im, PackedVector2Array([Vector2(6, 25), Vector2(10, 16), Vector2(16, 13), Vector2(22, 16), Vector2(26, 25)]), mud2)
			_line(im, Vector2(16, 12), Vector2(16, 2), Color(0.55, 0.75, 0.35), 2)        # гейзер вверх
			_poly(im, PackedVector2Array([Vector2(11, 6), Vector2(16, 0), Vector2(21, 6)]), Color(0.6, 0.85, 0.4))
			for c7 in [Vector2(6, 18), Vector2(26, 17), Vector2(9, 9), Vector2(24, 8)]:
				_ring(im, c7.x, c7.y, 2, Color(0.7, 0.95, 0.55), 1.0)
		"gas_bubble":
			_disc(im, 16, 16, 12, Color(0.55, 0.85, 0.35, 0.45))
			_ring(im, 16, 16, 12, Color(0.75, 1.0, 0.5), 2.0)
			_disc(im, 11, 10, 3, Color(1, 1, 1, 0.8))
			for c8 in [Vector2(19, 19), Vector2(14, 21), Vector2(21, 13)]:
				_disc(im, c8.x, c8.y, 1.5, Color(0.4, 0.65, 0.25))
		"frog_tongue":
			var frog := Color(0.40, 0.68, 0.28)
			_poly(im, PackedVector2Array([Vector2(2, 28), Vector2(3, 19), Vector2(9, 15), Vector2(15, 19), Vector2(16, 28)]), frog)
			_disc(im, 5, 15, 3, frog.lightened(0.15))
			_disc(im, 12, 15, 3, frog.lightened(0.15))
			_px(im, 5, 15, Color(0.05, 0.05, 0.05))
			_px(im, 12, 15, Color(0.05, 0.05, 0.05))
			_line(im, Vector2(15, 22), Vector2(28, 12), Color(0.92, 0.45, 0.52), 2)        # язык
			_disc(im, 28, 11, 3, Color(0.95, 0.5, 0.55))
		"swamp_wake":
			_rect(im, 0, 22, 32, 10, Color(0.18, 0.26, 0.12))
			_line(im, Vector2(16, 30), Vector2(16, 6), Color(0.45, 0.32, 0.18), 2)        # посох
			_disc(im, 16, 5, 3, Color(0.65, 1.0, 0.6))
			for hx in [5.0, 26.0]:                                                        # руки из грязи
				_poly(im, PackedVector2Array([Vector2(hx - 3, 24), Vector2(hx - 4, 15), Vector2(hx - 2, 11), Vector2(hx, 15), Vector2(hx + 2, 10), Vector2(hx + 3, 15), Vector2(hx + 3, 24)]), Color(0.36, 0.46, 0.26))
			for k in 6:
				_px(im, 3 + k * 5, 23, Color(0.45, 0.62, 0.3))
		# ---------- Зарница ----------
		"w_spark":
			var fan := Color(0.30, 0.42, 0.78)
			_poly(im, PackedVector2Array([Vector2(4, 28), Vector2(3, 14), Vector2(8, 7), Vector2(15, 5), Vector2(17, 10), Vector2(6, 28)]), fan)
			_line(im, Vector2(4, 28), Vector2(9, 7), Color(0.95, 0.8, 0.35), 1)
			_line(im, Vector2(4, 28), Vector2(15, 6), Color(0.95, 0.8, 0.35), 1)
			_disc(im, 23, 14, 5, Color(0.55, 0.75, 1.0))
			_disc(im, 23, 14, 3, Color(0.9, 0.96, 1.0))
			_line(im, Vector2(26, 9), Vector2(30, 4), Color(0.9, 0.96, 1.0), 1)
			_line(im, Vector2(27, 17), Vector2(31, 20), Color(0.9, 0.96, 1.0), 1)
		"gale":
			for k in 3:
				var y0 := 8.0 + k * 8.0
				for x in 22:
					_px(im, 3 + x, int(y0 + sin(x * 0.35 + k) * 2.0), Color(0.85, 0.93, 1.0, 1.0 - k * 0.2))
			_poly(im, PackedVector2Array([Vector2(24, 4), Vector2(30, 16), Vector2(24, 28), Vector2(27, 16)]), Color(0.7, 0.85, 1.0))
		"copper_rod":
			_rect(im, 3, 27, 26, 3, Color(0.4, 0.38, 0.42))
			_rect(im, 14, 8, 4, 20, Color(0.78, 0.46, 0.22))
			_rect(im, 15, 8, 1, 19, Color(1.0, 0.75, 0.45))
			_poly(im, PackedVector2Array([Vector2(13, 9), Vector2(16, 1), Vector2(19, 9)]), Color(0.95, 0.7, 0.4))
			_line(im, Vector2(18, 5), Vector2(24, 10), Color(0.9, 0.96, 1.0), 1)
			_line(im, Vector2(24, 10), Vector2(21, 14), Color(0.9, 0.96, 1.0), 1)
			_line(im, Vector2(21, 14), Vector2(28, 21), Color(0.9, 0.96, 1.0), 1)
			_line(im, Vector2(13, 6), Vector2(7, 12), Color(0.6, 0.78, 1.0), 1)
			_line(im, Vector2(7, 12), Vector2(5, 19), Color(0.6, 0.78, 1.0), 1)
		"storm_dash":
			var zz := PackedVector2Array([Vector2(3, 28), Vector2(10, 20), Vector2(8, 18), Vector2(16, 11), Vector2(14, 9), Vector2(21, 4)])
			for i in zz.size() - 1:
				_line(im, zz[i], zz[i + 1], Color(0.55, 0.75, 1.0), 2)
				_line(im, zz[i], zz[i + 1], Color(0.95, 0.98, 1.0), 1)
			_disc(im, 24, 6, 4, Color(0.30, 0.42, 0.78))
			_disc(im, 25, 5, 2, Color(0.92, 0.9, 0.95))
		"storm_eye":
			_disc(im, 16, 9, 9, Color(0.32, 0.36, 0.48))
			_disc(im, 10, 10, 6, Color(0.40, 0.44, 0.56))
			_disc(im, 22, 10, 6, Color(0.40, 0.44, 0.56))
			_ring(im, 16, 9, 4, Color(0.85, 0.92, 1.0), 1.5)
			for bx in [8, 16, 24]:
				_line(im, Vector2(bx, 16), Vector2(bx - 3, 23), Color(1.0, 0.92, 0.45), 1)
				_line(im, Vector2(bx - 3, 23), Vector2(bx + 1, 24), Color(1.0, 0.92, 0.45), 1)
				_line(im, Vector2(bx + 1, 24), Vector2(bx - 2, 31), Color(1.0, 0.92, 0.45), 1)
		# ---------- Пивозавр ----------
		"w_caps":
			var cols := [Color(0.9, 0.22, 0.16), Color(0.3, 0.78, 0.28), Color(1.0, 0.85, 0.2)]
			for k in 3:
				var c2: Vector2 = [Vector2(9, 21), Vector2(19, 13), Vector2(25, 24)][k]
				for i in 12:
					_disc(im, c2.x + cos(TAU * i / 12.0) * 5.5, c2.y + sin(TAU * i / 12.0) * 5.5, 1.2, (cols[k] as Color).darkened(0.3))
				_disc(im, c2.x, c2.y, 4.5, cols[k])
				_px(im, int(c2.x) - 1, int(c2.y) - 2, Color(1, 1, 1, 0.8))
		"sacred_beer":
			_poly(im, PackedVector2Array([Vector2(8, 28), Vector2(8, 15), Vector2(11, 11), Vector2(11, 5), Vector2(15, 5), Vector2(15, 11), Vector2(18, 15), Vector2(18, 28)]), Color(0.2, 0.52, 0.24))
			_rect(im, 8, 17, 10, 6, Color(0.92, 0.86, 0.66))
			_rect(im, 11, 3, 4, 2, Color(0.85, 0.2, 0.15))
			_rect(im, 2, 28, 28, 3, Color(0.95, 0.7, 0.2))
			for k in 4:
				_line(im, Vector2(20 + k * 2, 14 + k * 3), Vector2(24 + k * 2, 11 + k * 3), Color(0.6, 0.9, 0.6), 1)
		"life_drink":
			_poly(im, PackedVector2Array([Vector2(10, 29), Vector2(10, 16), Vector2(13, 12), Vector2(13, 6), Vector2(17, 6), Vector2(17, 12), Vector2(20, 16), Vector2(20, 29)]), Color(0.2, 0.52, 0.24))
			_rect(im, 11, 18, 8, 9, Color(0.95, 0.72, 0.2))
			for k in 4:
				_disc(im, 13 + (k % 2) * 4, 4 - k, 1.5, Color(1, 0.98, 0.9))
			_poly(im, PackedVector2Array([Vector2(24, 10), Vector2(28, 10), Vector2(28, 14), Vector2(32, 14), Vector2(32, 18), Vector2(28, 18), Vector2(28, 22), Vector2(24, 22), Vector2(24, 18), Vector2(20, 18), Vector2(20, 14), Vector2(24, 14)]), Color(1.0, 0.4, 0.45))
		"mammoth_burp":
			for c3 in [Vector2(14, 16), Vector2(22, 12), Vector2(22, 21), Vector2(9, 22)]:
				_disc(im, c3.x, c3.y, 7, Color(0.62, 0.78, 0.28, 0.85))
			_disc(im, 4, 8, 4, Color(0.9, 0.7, 0.55))
			_rect(im, 6, 8, 3, 2, Color(0.4, 0.15, 0.12))
		"cellar_keeper":
			_rect(im, 0, 24, 32, 8, Color(0.30, 0.24, 0.18))
			_rect(im, 3, 25, 12, 4, Color(0.05, 0.04, 0.03))
			for k in 3:
				var kx := 13 + k * 6
				_rect(im, kx, 12 + (k % 2) * 2, 4, 4, Color(0.95, 0.76, 0.62))
				_rect(im, kx, 11 + (k % 2) * 2, 4, 1, [Color(0.35, 0.22, 0.12), Color(0.9, 0.75, 0.35), Color(0.12, 0.1, 0.1)][k])
				_rect(im, kx, 16 + (k % 2) * 2, 4, 4, [Color(0.85, 0.25, 0.2), Color(0.25, 0.5, 0.9), Color(0.95, 0.8, 0.2)][k])
				_rect(im, kx, 20 + (k % 2) * 2, 1, 3, Color(0.95, 0.76, 0.62))
				_rect(im, kx + 3, 20 + (k % 2) * 2, 1, 3, Color(0.95, 0.76, 0.62))
			for k in 3:
				_line(im, Vector2(2, 12 + k * 4), Vector2(8, 12 + k * 4), Color(1, 1, 1, 0.6), 1)
		# ---------- Рассвет ----------
		"w_dawn":
			_line(im, Vector2(5, 28), Vector2(26, 5), Color(0.14, 0.11, 0.17), 3)
			_line(im, Vector2(7, 27), Vector2(27, 6), Color(1.0, 0.84, 0.42), 1)
			_line(im, Vector2(3, 22), Vector2(11, 30), Color(0.6, 0.55, 0.62), 2)
			_disc(im, 4, 29, 2, Color(1.0, 0.84, 0.42))
		"dawn_step":
			_poly(im, PackedVector2Array([Vector2(3, 29), Vector2(4, 13), Vector2(8, 8), Vector2(12, 13), Vector2(13, 29)]), Color(0.45, 0.22, 0.65, 0.8))
			for k in 3:
				_line(im, Vector2(14 + k * 2, 18), Vector2(20 + k * 2, 18), Color(0.8, 0.7, 1.0, 0.6), 1)
			_poly(im, PackedVector2Array([Vector2(20, 29), Vector2(21, 13), Vector2(25, 8), Vector2(29, 13), Vector2(30, 29)]), Color(0.16, 0.12, 0.18))
			_line(im, Vector2(21, 22), Vector2(30, 13), Color(1.0, 0.84, 0.42), 1)
		"dawn_eclipse":
			_disc(im, 16, 16, 13, Color(0.08, 0.03, 0.12))
			_ring(im, 16, 16, 13, Color(0.6, 0.35, 0.95), 2.0)
			_disc(im, 19, 13, 6, Color(0.95, 0.85, 0.55))
			_disc(im, 21, 11, 6, Color(0.08, 0.03, 0.12))
		"black_sun":
			_ring(im, 16, 16, 12, Color(1.0, 0.84, 0.42), 2.0)
			_ring(im, 16, 16, 8, Color(1.0, 0.84, 0.42, 0.6), 1.5)
			_disc(im, 16, 16, 6, Color(0.03, 0.0, 0.05))
			_poly(im, PackedVector2Array([Vector2(16, 12), Vector2(19, 16), Vector2(16, 20), Vector2(13, 16)]), Color(1.0, 0.84, 0.42))
		"dawn_rise":
			_rect(im, 0, 24, 32, 8, Color(0.30, 0.18, 0.22))
			_disc(im, 16, 26, 9, Color(1.0, 0.75, 0.35))
			for s in [-1.0, 1.0]:
				_poly(im, PackedVector2Array([Vector2(16, 14), Vector2(16 + s * 12, 3), Vector2(16 + s * 15, 8), Vector2(16 + s * 11, 13), Vector2(16 + s * 14, 17), Vector2(16, 18)]), Color(1.0, 0.92, 0.65))
			_line(im, Vector2(16, 6), Vector2(16, 22), Color(0.14, 0.11, 0.17), 2)
		# ---------- Привратница ----------
		"w_key":
			_line(im, Vector2(6, 27), Vector2(22, 9), Color(0.55, 0.42, 0.25), 2)       # древко посоха
			_ring(im, 25, 6, 5, Color(1.0, 0.82, 0.38), 2.0)                            # кольцо ключа
			_disc(im, 25, 6, 2, Color(0.70, 0.45, 1.0))
			_rect(im, 9, 21, 4, 2, Color(1.0, 0.82, 0.38))                              # бородка
			_rect(im, 11, 23, 2, 2, Color(1.0, 0.82, 0.38))
			for k in 3:
				_rect(im, 16 + k * 4, 25 - k * 4, 3, 3, Color(0.80, 0.62, 1.0))            # летящие скобы
		# ---------- Отголосок ----------
		"w_lamp":
			_line(im, Vector2(5, 28), Vector2(20, 9), Color(0.40, 0.33, 0.28), 2)       # древко
			_rect(im, 19, 4, 9, 11, Color(0.22, 0.20, 0.28))                          # фонарь
			_rect(im, 21, 6, 5, 7, Color(0.72, 0.48, 1.0))
			_disc(im, 23, 9, 2, Color(0.95, 0.88, 1.0))
			for k in 3:
				_ring(im, 23, 9, 7 + k * 3, Color(0.72, 0.48, 1.0, 0.6 - k * 0.15), 1.0)
		"rift_step":
			for k in 3:
				_rect(im, 4 + k * 7, 9, 6, 15, Color(0.72, 0.48, 1.0, 0.25 + k * 0.25))   # следы рывка
			_disc(im, 26, 10, 3, Color(0.95, 0.88, 1.0))
			_rect(im, 23, 13, 7, 12, Color(0.36, 0.34, 0.44))
			_poly(im, PackedVector2Array([Vector2(3, 27), Vector2(29, 27), Vector2(29, 29), Vector2(3, 29)]), Color(0.72, 0.48, 1.0))
		"edge_line":
			for y in range(2, 30):
				var x := 16 + int(round(sin(y * 1.3) * 2.0))
				_px(im, x, y, Color(0.95, 0.88, 1.0))
				_px(im, x - 1, y, Color(0.72, 0.48, 1.0))
				_px(im, x + 1, y, Color(0.72, 0.48, 1.0))
			_disc(im, 7, 16, 3, Color(0.72, 0.48, 1.0))                               # сгусток до Грани
			_disc(im, 25, 11, 2, Color(0.72, 0.48, 1.0))                              # и два после
			_disc(im, 25, 21, 2, Color(0.72, 0.48, 1.0))
		"abyss_pull":
			_ring(im, 16, 25, 12, Color(0.72, 0.48, 1.0), 1.5)
			_disc(im, 16, 12, 4, Color(0.85, 0.80, 0.70))                             # подброшенный враг
			for k in 3:
				_line(im, Vector2(9 + k * 7, 24), Vector2(12 + k * 4, 17), Color(0.95, 0.88, 1.0), 1)
			_poly(im, PackedVector2Array([Vector2(13, 5), Vector2(16, 1), Vector2(19, 5)]), Color(0.72, 0.48, 1.0))
		"path_echo":
			for k in 3:
				var c := Color(0.72, 0.48, 1.0, 0.3 + k * 0.3)
				_disc(im, 8 + k * 8, 9, 3, c)
				_rect(im, 5 + k * 8, 13, 7, 13, c)
			_ring(im, 24, 18, 11, Color(0.95, 0.88, 1.0, 0.7), 1.0)
		# ---------- Недопонятый гений ----------
		"w_usb":
			_rect(im, 5, 12, 14, 8, Color(0.50, 0.08, 0.14))
			_rect(im, 19, 13, 7, 6, Color(0.82, 0.84, 0.88))
			_rect(im, 21, 14, 1, 1, Color(0.3, 0.3, 0.35))
			_rect(im, 23, 14, 1, 1, Color(0.3, 0.3, 0.35))
			_poly(im, PackedVector2Array([Vector2(9, 19), Vector2(12, 13), Vector2(15, 19)]), Color(0.10, 0.58, 0.85))   # логотип Arch
			_rect(im, 6, 13, 2, 2, Color(0.4, 1.0, 0.45))
		"ether_whip":
			for x in range(3, 25):
				var y := 16 + int(round(sin(x * 0.5) * 5.0 * (25 - x) / 22.0))
				_rect(im, x, y, 1, 2, Color(0.25, 0.55, 0.95))
			_rect(im, 24, 13, 6, 6, Color(0.85, 0.90, 0.95))                           # вилка RJ-45
			_rect(im, 25, 14, 4, 1, Color(0.85, 0.7, 0.2))
			_rect(im, 3, 24, 7, 2, Color(0.40, 1.0, 0.45))                              # ERR
		"penguin_turret":
			_disc(im, 15, 18, 9, Color(0.10, 0.10, 0.14))
			_disc(im, 16, 20, 6, Color(0.95, 0.95, 0.98))
			_rect(im, 11, 8, 10, 3, Color(0.20, 0.22, 0.30))
			_rect(im, 17, 9, 2, 1, Color(1.0, 0.2, 0.25))
			_rect(im, 20, 13, 9, 3, Color(1.0, 0.55, 0.15))                             # клюв-ствол
			_disc(im, 10, 28, 2, Color(0.25, 0.25, 0.30))
			_disc(im, 20, 28, 2, Color(0.25, 0.25, 0.30))
		"overclock":
			_ring(im, 16, 16, 11, Color(0.62, 0.28, 0.82), 2.0)
			for k in 3:
				var a := TAU * k / 3.0
				_line(im, Vector2(16, 16), Vector2(16, 16) + Vector2(cos(a), sin(a)) * 9.0, Color(0.85, 0.85, 0.95), 2)
			_disc(im, 16, 16, 2, Color(0.40, 1.0, 0.45))
		"rack_rebuild":
			_rect(im, 9, 3, 14, 26, Color(0.10, 0.09, 0.12))
			for k in 6:
				_rect(im, 11, 5 + k * 4, 10, 3, Color(0.20, 0.19, 0.24))
				_rect(im, 18, 6 + k * 4, 1, 1, [Color(0.4, 1.0, 0.45), Color(1.0, 0.75, 0.2), Color(0.3, 0.6, 1.0)][k % 3])
			_rect(im, 9, 3, 14, 1, Color(0.55, 0.08, 0.14))
			_poly(im, PackedVector2Array([Vector2(1, 29), Vector2(31, 29), Vector2(31, 31), Vector2(1, 31)]), Color(0.62, 0.28, 0.82))
		# ---------- Почти легенда ----------
		"w_fist":
			_rect(im, 4, 10, 8, 14, Color(0.94, 0.95, 0.98))                              # манжета
			_rect(im, 11, 7, 14, 19, Color(1.0, 0.52, 0.14))                              # кулак
			for k in 4:
				_rect(im, 24, 8 + k * 4, 3, 3, Color(0.18, 0.20, 0.26))                   # костяшки
			_rect(im, 21, 10, 2, 2, Color(0.30, 0.90, 1.0))
			_rect(im, 21, 18, 2, 2, Color(0.30, 0.90, 1.0))
			_line(im, Vector2(28, 4), Vector2(31, 2), Color(1.0, 0.75, 0.4), 1)          # удар
			_line(im, Vector2(29, 16), Vector2(31, 16), Color(1.0, 0.75, 0.4), 1)
			_line(im, Vector2(28, 28), Vector2(31, 30), Color(1.0, 0.75, 0.4), 1)
		"railmotron":
			_rect(im, 2, 13, 20, 6, Color(0.22, 0.24, 0.30))                              # винтовка
			for k in 4:
				_rect(im, 5 + k * 4, 12, 2, 8, Color(0.30, 0.90, 1.0))                     # катушки
			_rect(im, 4, 19, 4, 6, Color(0.22, 0.24, 0.30))                               # рукоять
			_rect(im, 21, 14, 11, 4, Color(0.85, 0.97, 1.0))                              # луч
			_rect(im, 21, 15, 11, 2, Color(1, 1, 1))
		"ice_farewell":
			_ring(im, 16, 22, 13, Color(0.75, 0.93, 1.0), 1.5)                             # ледяная область
			_disc(im, 16, 22, 9, Color(0.55, 0.85, 1.0, 0.5))
			for c in [[6, 16], [16, 12], [26, 16]]:                                         # кристаллы
				_poly(im, PackedVector2Array([Vector2(c[0] - 3, c[1] + 6), Vector2(c[0], c[1] - 6), Vector2(c[0] + 3, c[1] + 6)]), Color(0.80, 0.95, 1.0))
			_line(im, Vector2(9, 4), Vector2(23, 4), Color(1, 1, 1), 1)                    # «пока!» — взмах
			_line(im, Vector2(23, 4), Vector2(20, 1), Color(1, 1, 1), 1)
		"meteor_strike":
			_poly(im, PackedVector2Array([Vector2(2, 2), Vector2(16, 12), Vector2(12, 18)]), Color(1.0, 0.55, 0.2, 0.8))   # хвост
			_disc(im, 19, 19, 9, Color(0.55, 0.48, 0.44))                                 # камень
			_disc(im, 21, 17, 4, Color(1.0, 0.70, 0.35))
			_rect(im, 13, 22, 3, 3, Color(0.40, 0.85, 0.35))                              # разные виды
			_rect(im, 22, 23, 3, 3, Color(0.55, 0.85, 1.0))
			_rect(im, 18, 13, 3, 3, Color(1.0, 0.88, 0.30))
		"titan":
			_rect(im, 9, 4, 14, 10, Color(0.24, 0.26, 0.31))                              # голова робота
			_rect(im, 10, 8, 12, 3, Color(0.12, 0.13, 0.16))
			_rect(im, 12, 9, 2, 1, Color(0.30, 0.90, 1.0))
			_rect(im, 18, 9, 2, 1, Color(0.30, 0.90, 1.0))
			_rect(im, 15, 1, 2, 3, Color(0.12, 0.13, 0.16))
			_rect(im, 5, 15, 22, 15, Color(0.24, 0.26, 0.31))                             # торс
			_rect(im, 2, 14, 6, 6, Color(1.0, 0.52, 0.14))                                # наплечники
			_rect(im, 24, 14, 6, 6, Color(1.0, 0.52, 0.14))
			_disc(im, 16, 22, 4, Color(0.30, 0.90, 1.0))                                  # ядро
		# ---------- DJ Клима ----------
		"w_vinyl":
			_disc(im, 14, 16, 12, Color(0.07, 0.07, 0.09))                                # пластинка
			_ring(im, 14, 16, 9, Color(0.26, 0.26, 0.32), 1.0)
			_ring(im, 14, 16, 6, Color(0.26, 0.26, 0.32), 1.0)
			_disc(im, 14, 16, 4, Color(1.0, 0.36, 0.80))
			_disc(im, 14, 16, 1, Color(0.05, 0.05, 0.06))
			_line(im, Vector2(5, 10), Vector2(9, 5), Color(0.75, 0.75, 0.85), 1)          # блик
			_line(im, Vector2(25, 6), Vector2(30, 3), Color(0.30, 0.90, 1.0), 1)          # «летит»
			_line(im, Vector2(26, 10), Vector2(31, 9), Color(0.30, 0.90, 1.0), 1)
		"mic_drop":
			_rect(im, 6, 17, 5, 13, Color(0.14, 0.14, 0.17))                              # ручка
			_rect(im, 5, 15, 7, 2, Color(0.30, 0.90, 1.0))
			_disc(im, 8.5, 10, 6, Color(0.72, 0.74, 0.80))                                # сетка
			_line(im, Vector2(5, 8), Vector2(12, 8), Color(0.45, 0.46, 0.52), 1)
			_line(im, Vector2(5, 11), Vector2(12, 11), Color(0.45, 0.46, 0.52), 1)
			for k in 3:                                                                    # фонит: волны
				_ring(im, 19, 10, 4 + k * 4, Color(0.30, 0.90, 1.0, 0.95 - k * 0.2), 1.0)
			_rect(im, 15, 0, 17, 3, Color(0, 0, 0, 0))
			_rect(im, 15, 18, 17, 14, Color(0, 0, 0, 0))
			_line(im, Vector2(18, 22), Vector2(28, 30), Color(1.0, 0.30, 0.35), 2)       # перечёркнуто
		"mosh_slam":
			_disc(im, 16, 7, 4, Color(0.92, 0.76, 0.68))                                  # голова с капюшоном
			_ring(im, 16, 7, 5, Color(0.08, 0.08, 0.10), 1.5)
			_rect(im, 12, 12, 9, 10, Color(0.08, 0.08, 0.10))                             # кофта
			_rect(im, 15, 15, 2, 4, Color(0.96, 0.96, 1.0))                               # нота
			_line(im, Vector2(12, 13), Vector2(5, 4), Color(0.08, 0.08, 0.10), 2)        # руки вверх
			_line(im, Vector2(20, 13), Vector2(27, 4), Color(0.08, 0.08, 0.10), 2)
			_rect(im, 13, 22, 3, 6, Color(0.24, 0.40, 0.68))
			_rect(im, 17, 22, 3, 6, Color(0.24, 0.40, 0.68))
			_line(im, Vector2(1, 30), Vector2(9, 27), Color(1.0, 0.36, 0.80), 2)          # волны от пола
			_line(im, Vector2(23, 27), Vector2(31, 30), Color(1.0, 0.36, 0.80), 2)
		"scratch_port":
			_disc(im, 16, 16, 10, Color(0.07, 0.07, 0.09))
			_ring(im, 16, 16, 7, Color(0.26, 0.26, 0.32), 1.0)
			_disc(im, 16, 16, 3, Color(0.30, 0.90, 1.0))
			_line(im, Vector2(3, 8), Vector2(29, 8), Color(1.0, 0.36, 0.80), 1)           # стрелки «поменяться местами»
			_poly(im, PackedVector2Array([Vector2(29, 5), Vector2(32, 8), Vector2(29, 11)]), Color(1.0, 0.36, 0.80))
			_line(im, Vector2(3, 24), Vector2(29, 24), Color(1.0, 0.36, 0.80), 1)
			_poly(im, PackedVector2Array([Vector2(3, 21), Vector2(0, 24), Vector2(3, 27)]), Color(1.0, 0.36, 0.80))
		"rave_party":
			_poly(im, PackedVector2Array([Vector2(4, 0), Vector2(0, 0), Vector2(9, 18), Vector2(13, 18)]), Color(1.0, 0.36, 0.80, 0.7))   # прожекторы
			_poly(im, PackedVector2Array([Vector2(28, 0), Vector2(32, 0), Vector2(23, 18), Vector2(19, 18)]), Color(0.30, 0.90, 1.0, 0.7))
			_rect(im, 3, 20, 26, 9, Color(0.16, 0.16, 0.20))                              # пульт
			_rect(im, 3, 20, 26, 1, Color(0.30, 0.90, 1.0))
			_disc(im, 10, 23, 3, Color(0.05, 0.05, 0.06))
			_disc(im, 22, 23, 3, Color(0.05, 0.05, 0.06))
			for k in 4:
				_rect(im, 6 + k * 6, 27 - k % 2 * 2, 3, 2 + k % 2 * 2, [Color(0.38, 0.58, 1.0), Color(1.0, 0.92, 0.25), Color(1.0, 0.30, 0.25), Color(1.0, 0.48, 0.86)][k])
			_rect(im, 15, 6, 2, 9, Color(1.0, 0.92, 0.25))                                 # нота
			_disc(im, 14, 15, 2, Color(1.0, 0.92, 0.25))
			_rect(im, 17, 6, 3, 2, Color(1.0, 0.92, 0.25))
		# ---------- Летописец ----------
		"w_quill":
			for k in 16:                                                                # перо: опахало и стержень
				var x := 9 + k
				var y := 23 - k
				_line(im, Vector2(x, y), Vector2(x + 3 - k / 6, y - 4 + k / 8), Color(0.96, 0.95, 0.90), 1)
			_line(im, Vector2(6, 26), Vector2(26, 6), Color(0.76, 0.78, 0.86), 1)
			_poly(im, PackedVector2Array([Vector2(3, 29), Vector2(7, 23), Vector2(9, 25)]), Color(1.0, 0.82, 0.38))
			_disc(im, 3, 30, 1, Color(0.16, 0.24, 0.55))
			_rect(im, 18, 24, 11, 6, Color(0.16, 0.24, 0.55))                             # буква-капля
			_rect(im, 20, 25, 1, 4, Color(0.92, 0.95, 1.0))
			_rect(im, 20, 25, 4, 1, Color(0.92, 0.95, 1.0))
			_rect(im, 24, 25, 1, 4, Color(0.92, 0.95, 1.0))
		"footnote":
			_rect(im, 4, 14, 14, 3, Color(0.16, 0.24, 0.55))                             # строка
			_rect(im, 4, 20, 18, 3, Color(0.16, 0.24, 0.55))
			_rect(im, 4, 26, 10, 3, Color(0.16, 0.24, 0.55))
			_rect(im, 21, 3, 3, 9, Color(0.50, 0.68, 1.0))                                # цифра ¹
			_rect(im, 19, 4, 2, 2, Color(0.50, 0.68, 1.0))
			_rect(im, 19, 11, 7, 2, Color(0.50, 0.68, 1.0))
			_ring(im, 25, 22, 5, Color(1.0, 0.82, 0.38), 1.0)                            # метка на враге
		"draft":
			_disc(im, 10, 9, 4, Color(0.16, 0.24, 0.55, 0.6))                             # черновик-силуэт
			_rect(im, 6, 13, 9, 14, Color(0.16, 0.24, 0.55, 0.6))
			_disc(im, 23, 9, 4, Color(0.95, 0.82, 0.70))                                  # сам Летописец
			_rect(im, 19, 13, 9, 14, Color(0.22, 0.30, 0.62))
			_line(im, Vector2(19, 4), Vector2(12, 2), Color(1.0, 0.82, 0.38), 1)          # стрелка «Отменить»
			_poly(im, PackedVector2Array([Vector2(10, 2), Vector2(14, 0), Vector2(14, 4)]), Color(1.0, 0.82, 0.38))
		"paragraph":
			_rect(im, 10, 2, 13, 28, Color(0.96, 0.92, 0.80))                             # страница
			_rect(im, 11, 3, 5, 6, Color(0.80, 0.18, 0.18))                               # буквица
			for k in 8:
				_rect(im, 12, 11 + k * 2, 9 - (k * 3) % 4, 1, Color(0.16, 0.24, 0.55))
			_rect(im, 25, 9, 4, 4, Color(0.16, 0.24, 0.55))                               # буквы слетают
			_rect(im, 26, 17, 4, 4, Color(0.16, 0.24, 0.55))
			_rect(im, 3, 14, 4, 4, Color(0.85, 0.3, 0.3))                                 # пойманный снаряд
		"last_chapter":
			_poly(im, PackedVector2Array([Vector2(16, 9), Vector2(2, 6), Vector2(2, 24), Vector2(16, 27)]), Color(0.96, 0.92, 0.80))
			_poly(im, PackedVector2Array([Vector2(16, 9), Vector2(30, 6), Vector2(30, 24), Vector2(16, 27)]), Color(0.90, 0.86, 0.74))
			_line(im, Vector2(16, 9), Vector2(16, 27), Color(1.0, 0.82, 0.38), 1)
			for k in 4:
				_rect(im, 5, 11 + k * 3, 8, 1, Color(0.16, 0.24, 0.55))
				_rect(im, 19, 11 + k * 3, 8, 1, Color(0.16, 0.24, 0.55))
			_rect(im, 8, 29, 16, 2, Color(0.85, 0.15, 0.15))                              # печать «КОНЕЦ»
		# ---------- Главный ----------
		"w_soda":
			_rect(im, 3, 10, 12, 16, Color(0.70, 0.84, 0.90))                          # бутылка
			_rect(im, 4, 13, 10, 12, Color(0.45, 0.20, 0.08))
			_rect(im, 6, 6, 6, 4, Color(0.70, 0.84, 0.90))
			_rect(im, 6, 3, 6, 3, Color(0.90, 0.20, 0.20))
			_rect(im, 5, 16, 8, 4, Color(0.85, 0.15, 0.15))
			for k in 4:
				_rect(im, 16 + k * 3, 12 + (k % 2) * 3, 3, 3, Color(0.72, 0.93, 1.0) if k % 2 else Color(0.78, 1.0, 0.25))   # луч
		"sandwich":
			_rect(im, 4, 10, 24, 5, Color(0.92, 0.72, 0.42))
			_rect(im, 3, 15, 26, 2, Color(0.40, 0.80, 0.30))
			_rect(im, 4, 17, 24, 2, Color(0.95, 0.40, 0.35))
			_rect(im, 4, 19, 24, 2, Color(1.0, 0.85, 0.30))
			_rect(im, 4, 21, 24, 5, Color(0.88, 0.66, 0.38))
			_disc(im, 26, 6, 3, Color(0.55, 0.85, 0.30))                              # «плохо»
		"shades":
			_rect(im, 2, 12, 28, 3, Color(0.04, 0.04, 0.05))
			_rect(im, 4, 15, 10, 4, Color(0.04, 0.04, 0.05))
			_rect(im, 17, 15, 10, 4, Color(0.04, 0.04, 0.05))
			for k in 3:
				_rect(im, 5 + k * 2, 13 + (k % 2) * 2, 2, 2, Color(1, 1, 1))
				_rect(im, 18 + k * 2, 13 + (k % 2) * 2, 2, 2, Color(1, 1, 1))
			_line(im, Vector2(16, 26), Vector2(16, 30), Color(1.0, 0.92, 0.55), 2)    # луч с неба
		"receipt":
			_rect(im, 8, 3, 16, 26, Color(0.97, 0.96, 0.92))
			for k in 6:
				_rect(im, 10, 6 + k * 3, 8 + (k % 3) * 2, 1, Color(0.35, 0.35, 0.40))
			_rect(im, 10, 25, 12, 2, Color(0.85, 0.15, 0.15))
			for x in range(8, 24, 2):
				_px(im, x, 29, Color(0.97, 0.96, 0.92))
		"hotfix":
			_rect(im, 3, 6, 26, 18, Color(0.35, 0.18, 0.60, 0.8))                      # голографическая консоль
			_ring(im, 16, 15, 13, Color(0.85, 0.65, 1.0, 0.0), 1.0)
			for k in 4:
				_rect(im, 6, 9 + k * 4, 8 + (k * 5) % 12, 2, Color(0.70, 1.0, 0.80) if k % 2 == 0 else Color(0.95, 0.85, 1.0))
			_rect(im, 3, 6, 26, 1, Color(0.85, 0.65, 1.0))
			_rect(im, 3, 23, 26, 1, Color(0.85, 0.65, 1.0))
			_rect(im, 10, 26, 12, 3, Color(0.07, 0.06, 0.09))
		# ---------- Шов ----------
		"w_needle":
			_line(im, Vector2(4, 28), Vector2(27, 5), Color(0.80, 0.80, 0.88), 2)        # игла
			_disc(im, 6, 26, 2, Color(0.62, 0.52, 0.40))
			for k in 6:
				_px(im, 8 + k * 3, 27 - k * 3 + (k % 2) * 2, Color(1.0, 0.82, 0.35))          # нить
			_px(im, 28, 4, Color(1, 1, 1))
		"patch_combo":
			_rect(im, 3, 3, 12, 12, Color(0.36, 0.26, 0.16))                            # лоскут корней
			_rect(im, 17, 3, 12, 12, Color(0.30, 0.40, 0.60))                           # лоскут бури
			_rect(im, 3, 17, 12, 12, Color(0.80, 0.62, 0.36))                           # лоскут колосса
			_rect(im, 17, 17, 12, 12, Color(0.40, 0.70, 0.30))                          # лоскут яда
			_line(im, Vector2(22, 5), Vector2(20, 10), Color(0.9, 0.95, 1.0), 1)
			_line(im, Vector2(20, 10), Vector2(24, 12), Color(0.9, 0.95, 1.0), 1)
			for k in 7:
				_px(im, 15 + (k % 2), 2 + k * 4, Color(1.0, 0.82, 0.35))                   # золотые швы
				_px(im, 2 + k * 4, 15 + (k % 2), Color(1.0, 0.82, 0.35))
		"seam_thread":
			_line(im, Vector2(3, 16), Vector2(29, 16), Color(1.0, 0.90, 0.55), 2)
			for k in 5:
				_line(im, Vector2(5 + k * 5, 13), Vector2(8 + k * 5, 19), Color(1.0, 0.82, 0.35), 1)
			_rect(im, 3, 20, 4, 9, Color(0.42, 0.28, 0.46))                              # союзник скользит
			_poly(im, PackedVector2Array([Vector2(9, 22), Vector2(14, 24), Vector2(9, 26)]), Color(1.0, 0.90, 0.55))
		"abyss_tentacles":
			for cx in [9, 22]:
				for y in range(6, 29):
					var x: int = cx + int(round(sin(y * 0.45 + cx) * 3.0 * (29 - y) / 23.0))
					var hw := 1 + int((y - 6) / 8)
					for d in range(-hw, hw + 1):
						_px(im, x + d, y, Color(0.30, 0.12, 0.42))
					_px(im, x, y, Color(0.62, 0.30, 0.90))
				_disc(im, cx + int(round(sin(6 * 0.45 + cx) * 3.0)), 5, 2, Color(0.80, 0.50, 1.0))
			_poly(im, PackedVector2Array([Vector2(1, 29), Vector2(31, 29), Vector2(31, 31), Vector2(1, 31)]), Color(0.62, 0.30, 0.90))
		"hundred_waves":
			for k in 4:
				var c := Color(0.40, 0.20, 0.60, 0.35 + k * 0.15)
				_disc(im, 5 + k * 7, 8 + (k % 2) * 2, 3, c)
				_rect(im, 2 + k * 7, 12 + (k % 2) * 2, 7, 15, c)
			_disc(im, 16, 14, 5, Color(1.0, 0.82, 0.35))
			_ring(im, 16, 14, 9, Color(1.0, 0.90, 0.55, 0.8), 1.0)
		"gate_pair":
			for cx in [8.0, 24.0]:
				for y in range(4, 29):
					var hw := 6.0 * sqrt(maxf(0.0, 1.0 - pow((y - 16.0) / 12.5, 2.0)))
					for x in range(int(cx - hw), int(cx + hw) + 1):
						var e := absf(x - cx) >= hw - 1.5
						_px(im, x, y, Color(1.0, 0.82, 0.38) if e else (Color(0.06, 0.03, 0.10) if absf(x - cx) < hw * 0.5 else Color(0.45, 0.28, 0.85)))
			_line(im, Vector2(12, 16), Vector2(20, 16), Color(0.85, 0.75, 1.0), 1)
			_poly(im, PackedVector2Array([Vector2(18, 13), Vector2(21, 16), Vector2(18, 19)]), Color(0.85, 0.75, 1.0))
		"lock_chain":
			for k in 5:
				_ring(im, 5 + k * 5.5, 12 + (k % 2) * 4, 3.2, Color(0.85, 0.80, 0.62), 1.5)
			_rect(im, 11, 20, 10, 9, Color(1.0, 0.82, 0.38))                          # замок
			_ring(im, 16, 20, 4, Color(0.85, 0.85, 0.92), 1.5)
			_rect(im, 15, 22, 2, 4, Color(0.16, 0.12, 0.34))
		"collapse":
			_ring(im, 16, 16, 13, Color(0.70, 0.45, 1.0), 1.5)
			_ring(im, 16, 16, 9, Color(1.0, 0.82, 0.38), 1.5)
			_ring(im, 16, 16, 5, Color(0.70, 0.45, 1.0), 1.5)
			_disc(im, 16, 16, 2, Color(1, 1, 1))
			for a in [0.4, 2.0, 3.6, 5.2]:
				_line(im, Vector2(16, 16) + Vector2.from_angle(a) * 15.0, Vector2(16, 16) + Vector2.from_angle(a + 0.5) * 8.0, Color(0.9, 0.85, 1.0), 1)
		"seal":
			for y in range(9, 25):
				for x in range(2, 31):
					var d := pow((x - 16.0) / 14.0, 2.0) + pow((y - 17.0) / 7.0, 2.0)
					if d <= 1.0:
						_px(im, x, y, Color(1.0, 0.82, 0.38) if d > 0.78 else Color(0.20, 0.15, 0.40, 0.9))
			_rect(im, 13, 10, 6, 7, Color(1.0, 0.82, 0.38))                           # замочная скважина
			_disc(im, 16, 12, 2, Color(0.16, 0.12, 0.34))
			_rect(im, 15, 13, 2, 3, Color(0.16, 0.12, 0.34))
			_ring(im, 16, 7, 4, Color(0.85, 0.85, 0.92), 1.5)
		_:
			return StoryIcons.draw(id)        # значки Истории: предметы, свитки, кнопки героя
	return im
