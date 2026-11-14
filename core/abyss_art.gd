class_name AbyssArt
# ---------- Фоны последних земель Арены (волны 91–100) ----------
#   hills_backdrop   — Ветряные холмы (91–95): тёплый вечер, поля пшеницы, мельницы,
#                      фермы — обычный мирный край, но небо уже треснуло: над холмами
#                      разрыв, к нему поднимаются комья земли, обломки изгородей и стог,
#                      поля под ним поседели и пошли фиолетовыми пятнами.
#   palace_backdrop  — Дворец Бездны (96–100): фиолетовое зловещее небо, чёрный дворец
#                      со шпилями и светящимися окнами. level 0 — стоит; 1 — по стенам
#                      бегут трещины света, шпили кренятся; 2 — дворец отрывается от
#                      земли, шпили парят, над ним раскрывается око разлома.
#   hall_backdrop    — Зал Бездны (Странник, третья фаза): готический зал, витражи
#                      с видом на разлом, колонны, цепи, парящие свечи.
#   abyss_backdrop   — Изнанка (Странник, четвёртая и пятая фазы): чёрно-фиолетовая
#                      пустота со звёздами, в ней плавают обломки мира — мельницы, дома,
#                      куски дворца; в середине — огромное око бездны.
# Рисуется маленькая картинка (в SCALE раз меньше карты) и растягивается без сглаживания.

const SCALE := PixelArt.SCALE
const RIFT := RiftArt.RIFT
const CORE := RiftArt.RIFT_CORE

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		if c.a >= 0.999:
			img.set_pixel(x, y, c)
		else:
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), c.a))

static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	if w <= 0 or h <= 0:
		return
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x <= 0 or r.size.y <= 0:
		return
	if c.a >= 0.999:
		img.fill_rect(r, c)
	else:
		for yy in range(r.position.y, r.end.y):
			for xx in range(r.position.x, r.end.x):
				_px(img, xx, yy, c)

static func _disc(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for y in range(-ry, ry + 1):
		var hw := int(rx * sqrt(maxf(0.0, 1.0 - float(y * y) / float(maxi(ry * ry, 1)))))
		for x in range(-hw, hw + 1):
			_px(img, cx + x, cy + y, c)

# Нити силы, тянущиеся к разлому
static func _threads(img: Image, at: Vector2, n: int, len: int, rng: RandomNumberGenerator, a0 := 0.25) -> void:
	for k in n:
		var a := rng.randf() * TAU
		var p := at
		for s in len:
			p += Vector2.from_angle(a + sin(s * 0.45 + k) * 0.5) * 1.6
			_px(img, int(p.x), int(p.y), Color(RIFT.r, RIFT.g, RIFT.b, maxf(0.0, a0 - s * a0 / len)))

# Мельница: башня, шапка, четыре крыла (twist — крылья перекошены силой разлома)
static func _windmill(img: Image, x: int, base: int, h: int, haze: float, sky: Color, twist := 0.0, ang := 0.3) -> void:
	var wall := Color(0.86, 0.80, 0.68).lerp(sky, haze)
	var wall_d := wall.darkened(0.2)
	var roof := Color(0.55, 0.28, 0.20).lerp(sky, haze)
	var wood := Color(0.42, 0.30, 0.20).lerp(sky, haze)
	for i in h:
		var hw := int(lerpf(h * 0.22, h * 0.13, float(i) / h))
		_rect(img, x - hw, base - i, hw * 2 + 1, 1, wall)
		_rect(img, x + hw - maxi(1, hw / 3), base - i, maxi(1, hw / 3), 1, wall_d)
	_rect(img, x - 1, base - int(h * 0.35), 3, int(h * 0.35), wood)               # дверь
	_px(img, x, base - int(h * 0.62), Color(1.0, 0.86, 0.5).lerp(sky, haze))       # окошко
	var top := base - h
	for i in int(h * 0.22) + 1:                                                    # шапка
		var hw2 := int(h * 0.18) - i
		_rect(img, x - hw2, top - i, hw2 * 2 + 1, 1, roof if i % 2 == 0 else roof.lightened(0.1))
	var hub := Vector2(x + 1, top - 1)
	for b in 4:
		var a := ang + b * PI / 2 + (twist * sin(b * 1.7) if twist > 0.0 else 0.0)
		var l := h * 0.85 * (1.0 - twist * 0.25 * float(b % 2))
		for r in int(l):
			var q := hub + Vector2.from_angle(a) * r
			_px(img, int(q.x), int(q.y), wood)
			if r > l * 0.25:                                                       # полотно крыла
				var side := Vector2.from_angle(a + PI / 2)
				for s in 3:
					var q2 := q + side * (s + 1)
					_px(img, int(q2.x), int(q2.y), Color(0.90, 0.86, 0.76, 0.85).lerp(sky, haze))
	_px(img, int(hub.x), int(hub.y), wood.darkened(0.3))

static func _farmhouse(img: Image, x: int, base: int, s: int, haze: float, sky: Color) -> void:
	var wall := Color(0.88, 0.82, 0.70).lerp(sky, haze)
	var roof := Color(0.62, 0.24, 0.18).lerp(sky, haze)
	_rect(img, x - s, base - s, s * 2, s, wall)
	_rect(img, x + s - 2, base - s, 2, s, wall.darkened(0.18))
	_px(img, x - s + 2, base - s + 2, Color(1.0, 0.85, 0.5).lerp(sky, haze))
	_rect(img, x - 1, base - s / 2, 2, s / 2, Color(0.40, 0.28, 0.18).lerp(sky, haze))
	for i in s + 2:
		_rect(img, x - i - 1, base - s - s + i - 1, i * 2 + 2, 1, roof if i % 3 else roof.lightened(0.12))

static func _haystack(img: Image, x: int, base: int, r: int, c: Color) -> void:
	for y in r + 1:
		var hw := int(r * sqrt(maxf(0.0, 1.0 - float(y * y) / float(r * r))))
		_rect(img, x - hw, base - y, hw * 2 + 1, 1, c if y % 2 == 0 else c.darkened(0.08))

# Ком земли, оторванный от поля: травяная шапка, земля, корни
static func _clod(img: Image, cx: int, cy: int, hw: int, sky: Color, haze: float, rng: RandomNumberGenerator) -> void:
	var grass := Color(0.52, 0.66, 0.30).lerp(sky, haze)
	var dirt := Color(0.46, 0.33, 0.24).lerp(sky, haze)
	for i in hw * 2 + 1:
		var x := i - hw
		var k := 1.0 - absf(float(x)) / (hw + 1)
		var d := int(round(k * hw * 0.9)) + rng.randi_range(0, 1)
		_rect(img, cx + x, cy, 1, 2, grass)
		_rect(img, cx + x, cy + 2, 1, d, dirt if (x + d) % 5 else dirt.darkened(0.15))
	for k2 in 3:
		var rx := cx + rng.randi_range(-hw / 2, hw / 2)
		for s in rng.randi_range(2, 5):
			_px(img, rx + (s % 2), cy + hw + s, dirt.darkened(0.25))

# Пятно порчи: поле седеет, по нему фиолетовые прожилки
static func _blight(img: Image, cx: int, cy: int, rx: int, ry: int, rng: RandomNumberGenerator) -> void:
	for y in range(-ry, ry + 1):
		for x in range(-rx, rx + 1):
			var d := Vector2(float(x) / rx, float(y) / ry).length()
			if d < 1.0 and rng.randf() < 1.0 - d * 0.7:
				var px := cx + x
				var py := cy + y
				if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
					continue
				var c := img.get_pixel(px, py)
				var grey := Color(c.r * 0.5 + 0.2, c.g * 0.4 + 0.18, c.b * 0.5 + 0.28)
				img.set_pixel(px, py, c.lerp(grey, 0.7 * (1.0 - d)))
	for k in 5:
		var p := Vector2(cx, cy)
		var a := rng.randf() * TAU
		for s in rng.randi_range(4, 10):
			p += Vector2.from_angle(a + rng.randf_range(-0.6, 0.6)) * 1.2
			_px(img, int(p.x), int(p.y), Color(RIFT.r, RIFT.g, RIFT.b, 0.6))

# ===================== Ветряные холмы (91–95) =====================
# level 0..4 — волны 91..95: с каждой волной бездны всё больше — небо мрачнеет
# и лиловеет, солнце гаснет, в небе открываются новые разрезы, порча ползёт по полям.
static func hills_backdrop(map_w: float, floor_y: float, level := 0) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9151
	var k := clampf(level / 4.0, 0.0, 1.0)
	var sky := Color(0.94, 0.78, 0.60).lerp(Color(0.52, 0.34, 0.58), k * 0.8)
	var sky_top := Color(0.34, 0.44, 0.78).lerp(Color(0.12, 0.05, 0.20), k)
	var mid_c := Color(0.98, 0.80, 0.58).lerp(Color(0.56, 0.26, 0.60), k)
	PixelArt._vgrad(img, 0, w, 0, int(h * 0.72), sky_top, mid_c, 16)
	PixelArt._vgrad(img, 0, w, int(h * 0.72), h, mid_c, Color(0.92, 0.70, 0.50).lerp(Color(0.40, 0.22, 0.42), k), 6)
	# небо над разломом лиловеет — с каждой волной сильнее и шире
	var rx := int(w * 0.30)
	var ry := int(h * 0.24)
	PixelArt._halo(img, rx, ry, 95 + level * 30, Color(0.55, 0.30, 0.75, 0.32 + 0.08 * level))
	# низкое солнце справа: тускнеет, а к последней волне — затмение с лиловой каймой
	var sx := int(w * 0.84)
	var sy := int(h * 0.50)
	if level < 3:
		PixelArt._halo(img, sx, sy, 46, Color(1.0, 0.86, 0.55, 0.6 - 0.2 * level))
		PixelArt._circle(img, sx, sy, 11, Color(1.0, 0.94, 0.75).lerp(Color(0.85, 0.70, 0.85), 0.4 * level))
	else:
		PixelArt._halo(img, sx, sy, 40, Color(0.75, 0.40, 1.0, 0.5))
		PixelArt._circle(img, sx, sy, 12, Color(0.85, 0.60, 1.0))
		PixelArt._circle(img, sx - 1, sy, 10, Color(0.08, 0.03, 0.12))
	# облака: тёплые светлые отступают, рваные тёмные расползаются
	var dark_n := 8 + level * 5
	for i in maxi(2, 10 - level * 2):
		var cx := rng.randi_range(int(w * (0.5 + 0.08 * level)), w)
		RiftArt._cloud(img, cx, rng.randi_range(int(h * 0.12), int(h * 0.42)), rng.randi_range(4, 8), Color(1.0, 0.92, 0.84, 0.75).lerp(Color(0.70, 0.55, 0.75, 0.7), k), rng)
	for i in dark_n:
		var cx2 := rng.randi_range(0, int(w * (0.55 + 0.1 * level)))
		RiftArt._cloud(img, cx2, rng.randi_range(int(h * 0.06), int(h * 0.40)), rng.randi_range(3, 7), Color(0.30, 0.16, 0.40, 0.55 + 0.08 * level), rng)
	# разлом и нити; с каждой волной — новые разрезы в небе
	RiftArt.rift_tear(img, rx, ry, 64 + level * 8, rng, 1.0)
	RiftArt.rift_tear(img, int(w * 0.55), int(h * 0.12), 22, rng, 0.7)
	RiftArt.rift_tear(img, int(w * 0.08), int(h * 0.30), 18, rng, 0.6)
	var extra := [[0.70, 0.20, 26], [0.45, 0.34, 18], [0.90, 0.12, 30], [0.18, 0.12, 22], [0.62, 0.40, 16], [0.80, 0.30, 24], [0.38, 0.08, 20], [0.97, 0.36, 14]]
	for i in mini(level * 2, extra.size()):
		var e: Array = extra[i]
		RiftArt.rift_tear(img, int(w * float(e[0])), int(h * float(e[1])), int(e[2]), rng, 0.8)
		_threads(img, Vector2(w * float(e[0]), h * float(e[1])), 4 + level, 14, rng, 0.3)
	_threads(img, Vector2(rx, ry), 16 + level * 6, 26 + level * 4, rng, 0.3)
	# дальние холмы
	var far := PixelArt._ridge(w, h * 0.62, [[int(w * 0.12), 18, 90], [int(w * 0.45), 12, 120], [int(w * 0.8), 20, 110]], rng, 0.5)
	for x in w:
		_rect(img, x, int(far[x]), 1, h - int(far[x]), Color(0.50, 0.58, 0.62).lerp(sky, 0.35))
	for i in 5:
		_windmill(img, rng.randi_range(20, w - 20), int(far[clampi(rng.randi_range(20, w - 20), 0, w - 1)]) + 1, rng.randi_range(9, 12), 0.55, sky, 0.0, rng.randf() * TAU)
	# средние холмы — поля полосами
	var mid := PixelArt._ridge(w, h * 0.74, [[int(w * 0.22), 26, 150], [int(w * 0.62), 20, 170], [int(w * 0.95), 16, 90]], rng, 0.4)
	for x in w:
		var top := int(mid[x])
		for y in range(top, h):
			var band := int((y - top) / 3 + x / 22) % 3
			var c: Color = [Color(0.86, 0.72, 0.36), Color(0.60, 0.70, 0.34), Color(0.92, 0.80, 0.42)][band]
			_px(img, x, y, c.lerp(sky, 0.18 + 0.3 * k))
		_px(img, x, top, Color(0.70, 0.78, 0.40).lerp(sky, 0.1))
	# фермы, стога, изгороди, дорога
	for f in [[0.62, 6], [0.70, 5], [0.88, 7], [0.10, 5]]:
		var fx := int(w * float(f[0]))
		_farmhouse(img, fx, int(mid[clampi(fx, 0, w - 1)]) + 2, f[1], 0.2, sky)
	for i in 9:
		var hx := rng.randi_range(10, w - 10)
		_haystack(img, hx, int(mid[hx]) + 3 + rng.randi_range(0, 5), rng.randi_range(2, 4), Color(0.90, 0.76, 0.38).lerp(sky, 0.15))
	for x in range(0, w, 3):
		var fy := int(mid[x]) + 6
		_px(img, x, fy, Color(0.48, 0.34, 0.22, 0.8))
		if x % 9 == 0:
			_rect(img, x, fy - 2, 1, 3, Color(0.42, 0.30, 0.20, 0.9))
	# большие мельницы на ближнем холме: у разлома крылья перекошены и замерли
	_windmill(img, int(w * 0.66), int(mid[int(w * 0.66)]) + 1, 30, 0.05, sky, 0.0, 0.5)
	_windmill(img, int(w * 0.36), int(mid[int(w * 0.36)]) + 1, 26, 0.08, sky, 0.9, 1.1)
	# порча на полях: сначала под разломом, потом по всей долине
	for i in 7 + level * 6:
		var spread := 70 + level * 80
		_blight(img, clampi(rx + rng.randi_range(-spread, spread), 0, w - 1), int(h * 0.8) + rng.randi_range(-6, 10), rng.randi_range(10, 22), rng.randi_range(3, 6), rng)
	# комья земли, обломки изгороди и стог тянутся вверх, к разлому
	for i in 9:
		var t := rng.randf_range(0.2, 0.95)
		var cx3 := int(lerpf(rx + rng.randi_range(-110, 110), rx, t * 0.6))
		var cy3 := int(lerpf(h * 0.78, ry + 20, t))
		_clod(img, cx3, cy3, rng.randi_range(2, 6), sky, 0.15 + t * 0.2, rng)
		for s in 6:
			_px(img, cx3, cy3 + 8 + s * 2, Color(RIFT.r, RIFT.g, RIFT.b, 0.35 - s * 0.05))
	for i in 3:
		var bx := rx + rng.randi_range(-60, 60)
		var by := rng.randi_range(int(h * 0.42), int(h * 0.62))
		for s in 7:
			_px(img, bx + s, by + int(sin(s) * 1.0), Color(0.48, 0.34, 0.22))
		_rect(img, bx + 1, by - 1, 1, 3, Color(0.42, 0.30, 0.20))
		_rect(img, bx + 5, by - 1, 1, 3, Color(0.42, 0.30, 0.20))
	_haystack(img, rx + 40, int(h * 0.48), 4, Color(0.88, 0.74, 0.40))
	# сухие деревья у разлома, живые — подальше
	for i in 12:
		var tx := rng.randi_range(0, w)
		var base := int(mid[clampi(tx, 0, w - 1)]) + rng.randi_range(4, 14)
		if absi(tx - rx) < 90:
			_rect(img, tx, base - 7, 1, 7, Color(0.28, 0.22, 0.26))
			_px(img, tx - 1, base - 6, Color(0.28, 0.22, 0.26))
			_px(img, tx + 1, base - 5, Color(0.28, 0.22, 0.26))
		else:
			_rect(img, tx, base - 4, 1, 4, Color(0.40, 0.28, 0.18))
			PixelArt._bush(img, tx, base - 7, rng.randi_range(3, 4), Color(0.36, 0.56, 0.26))
	PixelArt._birds(img, 7, int(h * 0.15), int(h * 0.4), rng, Color(0.32, 0.26, 0.36))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.02, 0.05, rng)
	return img

# ===================== Дворец Бездны (96–100) =====================
const PAL_SKY := [Color(0.08, 0.03, 0.14), Color(0.46, 0.20, 0.56)]

static func palace_backdrop(map_w: float, floor_y: float, level: int) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9601
	var top_c: Color = PAL_SKY[0]
	var bot_c: Color = PAL_SKY[1]
	if level >= 1:
		top_c = top_c.lerp(Color(0.05, 0.01, 0.10), 0.5)
		bot_c = bot_c.lerp(Color(0.62, 0.22, 0.70), 0.35 * level)
	PixelArt._vgrad(img, 0, w, 0, h, top_c, bot_c, 18)
	# звёзды сквозь тучи
	for i in 70:
		_px(img, rng.randi_range(0, w), rng.randi_range(0, int(h * 0.5)), Color(0.95, 0.85, 1.0, rng.randf_range(0.3, 0.8)))
	# закрученные тучи вокруг ока
	var cx := int(w * 0.5)
	var cy := int(h * 0.20)
	for ring in 5:
		var rr := 40 + ring * 22
		for a in 90:
			var ang := a * TAU / 90.0 + ring * 0.6
			var q := Vector2(cx, cy) + Vector2(cos(ang) * rr * 1.6, sin(ang) * rr * 0.45)
			if rng.randf() < 0.55:
				RiftArt._cloud(img, int(q.x), int(q.y), rng.randi_range(2, 4), Color(0.22, 0.10, 0.30, 0.55), rng)
	# око разлома: на 2-м уровне раскрыто
	var eye_r: int = [10, 18, 34][level]
	PixelArt._halo(img, cx, cy, eye_r * 4, Color(RIFT.r, RIFT.g, RIFT.b, 0.45 + 0.1 * level))
	_disc(img, cx, cy, eye_r * 2, eye_r, Color(0.06, 0.01, 0.10))
	_disc(img, cx, cy, int(eye_r * 0.9), int(eye_r * 0.7), Color(0.70, 0.30, 0.95))
	_disc(img, cx, cy, int(eye_r * 0.35), int(eye_r * 0.6), Color(0.05, 0.0, 0.08))
	_px(img, cx - 1, cy - 1, CORE)
	_threads(img, Vector2(cx, cy), 18 + level * 8, 30 + level * 10, rng, 0.3)
	# дальние скалы
	var far := PixelArt._ridge(w, h * 0.70, [[int(w * 0.1), 40, 80], [int(w * 0.9), 46, 90], [int(w * 0.3), 18, 60], [int(w * 0.72), 22, 70]], rng, 0.8)
	for x in w:
		_rect(img, x, int(far[x]), 1, h - int(far[x]), Color(0.16, 0.08, 0.22))
	# дворец стоит на месте; пробуждаясь, он вспыхивает светом бездны
	var base := int(h * 0.92)
	var pal := Color(0.07, 0.05, 0.10)
	var pal_l := Color(0.16, 0.11, 0.20)
	var win := Color(0.82, 0.42, 1.0)
	# главный корпус
	_rect(img, cx - 70, base - 60, 140, 60, pal)
	_rect(img, cx - 70, base - 60, 140, 2, pal_l)
	# ворота
	PixelArt._arch(img, cx - 12, base - 34, 24, 34, Color(0.02, 0.0, 0.04))
	PixelArt._halo(img, cx, base - 14, 24, Color(RIFT.r, RIFT.g, RIFT.b, 0.6))
	# башни и шпили
	var towers := [[-62, 36, 8], [-40, 58, 10], [-18, 74, 9], [0, 96, 12], [18, 74, 9], [40, 58, 10], [62, 36, 8]]
	for t in towers:
		var tx := cx + int(t[0])
		var th := int(t[1])
		var tw := int(t[2])
		var tilt := 0.0
		var up := 0
		for i in th:
			var ox := int(tilt * i)
			_rect(img, tx - tw / 2 + ox, base - 60 - i - up, tw, 1, pal if i % 7 else pal_l)
		for k in 3:
			_px(img, tx + int(tilt * (12 + k * 14)), base - 72 - k * 14 - up, win)
		for i in tw + 4:                                         # шпиль
			var hw := maxi(0, (tw / 2) - i / 2)
			_rect(img, tx - hw + int(tilt * (th + i)), base - 60 - th - i - up, hw * 2 + 1, 1, pal)
		if level >= 1:
			# на шпилях загорается пламя бездны, от них к оку тянутся лучи
			var tip := Vector2(tx, base - 60 - th - tw - 3)
			PixelArt._halo(img, int(tip.x), int(tip.y), 6 + level * 2, Color(RIFT.r, RIFT.g, RIFT.b, 0.5))
			_disc(img, int(tip.x), int(tip.y) + 1, 1, 2, CORE)
			var steps := int(tip.distance_to(Vector2(cx, cy)))
			for s in steps:
				if s % 2 == 0 or level >= 2:
					var q := tip.lerp(Vector2(cx, cy), float(s) / steps)
					_px(img, int(q.x), int(q.y), Color(RIFT.r, RIFT.g, RIFT.b, 0.18 + 0.12 * level))
	# окна корпуса
	for r in 3:
		for c2 in 9:
			var wx := cx - 56 + c2 * 14
			var wy := base - 52 + r * 14
			if absi(wx - cx) < 14 and r == 2:
				continue
			_rect(img, wx, wy, 3, 5, win if rng.randf() < 0.8 else win.darkened(0.5))
	# трещины света по стенам
	if level >= 1:
		for k in 8 + level * 6:
			var p := Vector2(cx + rng.randi_range(-66, 66), base - rng.randi_range(4, 56))
			for s in rng.randi_range(5, 14):
				p += Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.0, 0.4))
				_px(img, int(p.x), int(p.y), CORE if s % 4 == 0 else RIFT)
	# пробудился: ворота — открытый разлом, по стенам ползёт лиловое пламя
	if level >= 1:
		PixelArt._halo(img, cx, base - 16, 30 + level * 14, Color(RIFT.r, RIFT.g, RIFT.b, 0.35 + 0.15 * level))
		_disc(img, cx, base - 16, 7 + level * 2, 14 + level * 2, Color(0.70, 0.30, 0.95))
		_disc(img, cx, base - 16, 3 + level, 10 + level * 2, Color(0.05, 0.0, 0.08))
		for i in 140:
			var fx := cx + rng.randi_range(-72, 72)
			var fh := rng.randi_range(2, 6 + level * 5)
			for j in fh:
				_px(img, fx, base - j, Color(RIFT.r, RIFT.g, RIFT.b, 0.6 - j * 0.6 / fh) if j > 1 else CORE)
	# второе пробуждение: око раскрыто, земля перед дворцом раскалывается до свечения
	if level >= 2:
		for ring in 3:
			var rr2 := 110 + ring * 26
			for a in 140:
				var ang2 := a * TAU / 140.0 - ring * 0.5
				if rng.randf() < 0.5:
					_px(img, cx + int(cos(ang2) * rr2 * 1.5), cy + int(sin(ang2) * rr2 * 0.42), Color(0.75, 0.40, 1.0, 0.35))
		var cp := Vector2(rng.randi_range(10, 40), base + 3)
		while cp.x < w - 10:
			cp += Vector2(rng.randf_range(2, 5), rng.randf_range(-1.0, 1.0))
			cp.y = clampf(cp.y, base + 1, h - 4)
			_px(img, int(cp.x), int(cp.y), CORE)
			_px(img, int(cp.x), int(cp.y) + 1, RIFT)
	# кристаллы бездны на переднем плане
	for i in 16:
		var kx := rng.randi_range(0, w)
		var kh := rng.randi_range(5, 14) + level * 3
		for j in kh:
			var hw2 := maxi(0, 2 - j / 4)
			_rect(img, kx - hw2, h - 2 - j, hw2 * 2 + 1, 1, Color(0.50, 0.22, 0.70) if j % 3 else Color(0.70, 0.40, 0.95))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.03, 0.05, rng)
	return img

# ===================== Зал Бездны (Странник, третья фаза) =====================
static func hall_backdrop(map_w: float, floor_y: float) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9702
	var stone := Color(0.14, 0.11, 0.17)
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.06, 0.04, 0.09), stone, 10)
	PixelArt._masonry(img, Rect2i(0, 0, w, h), 12, 6, stone, rng)
	# огромное круглое окно-роза посредине: за ним — разлом
	var cx := int(w * 0.5)
	var cy := int(h * 0.36)
	PixelArt._circle(img, cx, cy, 44, Color(0.05, 0.02, 0.08))
	PixelArt._circle(img, cx, cy, 40, Color(0.30, 0.10, 0.40))
	PixelArt._halo(img, cx, cy, 40, Color(RIFT.r, RIFT.g, RIFT.b, 0.7))
	RiftArt.rift_tear(img, cx, cy, 56, rng, 1.0)
	for k in 12:                                                     # переплёт окна
		var a := k * TAU / 12.0
		for r in 40:
			_px(img, cx + int(cos(a) * r), cy + int(sin(a) * r), Color(0.10, 0.06, 0.12))
	for rr in [14, 28, 40]:
		for a2 in 160:
			var an := a2 * TAU / 160.0
			_px(img, cx + int(cos(an) * rr), cy + int(sin(an) * rr), Color(0.10, 0.06, 0.12))
	# высокие стрельчатые витражи по бокам
	for side in [-1, 1]:
		for k in 3:
			var wx: int = cx + side * (110 + k * 80)
			PixelArt._arch(img, wx - 9, int(h * 0.18), 18, 70, Color(0.06, 0.03, 0.09))
			PixelArt._arch(img, wx - 7, int(h * 0.18) + 2, 14, 66, Color(0.42, 0.18, 0.55))
			for s in 66:
				if s % 8 == 0:
					_rect(img, wx - 7, int(h * 0.18) + 2 + s, 14, 1, Color(0.10, 0.05, 0.14))
			_rect(img, wx, int(h * 0.18) + 4, 1, 64, Color(0.10, 0.05, 0.14))
			PixelArt._halo(img, wx, int(h * 0.18) + 36, 18, Color(0.75, 0.40, 1.0, 0.25))
	# колонны
	for k in 8:
		var px := int(w * (0.06 + k * 0.125))
		if absi(px - cx) < 60:
			continue
		_rect(img, px - 6, 0, 12, h, Color(0.10, 0.08, 0.13))
		_rect(img, px - 6, 0, 2, h, Color(0.20, 0.15, 0.24))
		_rect(img, px - 8, int(h * 0.12), 16, 4, Color(0.18, 0.13, 0.22))
		_rect(img, px - 8, h - 14, 16, 4, Color(0.18, 0.13, 0.22))
	# цепи с потолка
	for k in 7:
		var chx := rng.randi_range(20, w - 20)
		var ln := rng.randi_range(20, 60)
		for s in ln:
			_px(img, chx + (s % 2), s, Color(0.30, 0.26, 0.34))
	# парящие свечи
	for k in 26:
		var fx := rng.randi_range(0, w)
		var fy := rng.randi_range(int(h * 0.15), int(h * 0.75))
		_rect(img, fx, fy, 1, 3, Color(0.85, 0.80, 0.75))
		_px(img, fx, fy - 1, Color(0.85, 0.55, 1.0))
		PixelArt._halo(img, fx, fy - 1, 4, Color(0.8, 0.5, 1.0, 0.4))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.03, 0.06, rng)
	return img

# ===================== Изнанка (Странник, четвёртая и пятая фазы) =====================
# below — сколько ещё рисовать ниже пола (в просветах между островами видна пустота)
static func abyss_backdrop(map_w: float, floor_y: float, below: float) -> Image:
	var w := int(map_w / SCALE)
	var h := int((floor_y + below) / SCALE) + 2
	var fy := int(floor_y / SCALE)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9803
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.02, 0.0, 0.05), Color(0.16, 0.04, 0.22), 14)
	# туманность
	for k in 40:
		RiftArt._cloud(img, rng.randi_range(0, w), rng.randi_range(0, h), rng.randi_range(3, 8),
				Color(0.40, 0.12, 0.55, rng.randf_range(0.10, 0.25)), rng)
	for i in 160:
		var sc := Color(0.95, 0.88, 1.0, rng.randf_range(0.3, 1.0))
		_px(img, rng.randi_range(0, w), rng.randi_range(0, h), sc)
	# око бездны
	var cx := int(w * 0.5)
	var cy := int(fy * 0.34)
	PixelArt._halo(img, cx, cy, 110, Color(0.55, 0.20, 0.75, 0.55))
	_disc(img, cx, cy, 70, 30, Color(0.04, 0.0, 0.07))
	_disc(img, cx, cy, 52, 26, Color(0.62, 0.24, 0.85))
	_disc(img, cx, cy, 40, 22, Color(0.80, 0.42, 1.0))
	_disc(img, cx, cy, 12, 20, Color(0.03, 0.0, 0.06))
	_px(img, cx - 4, cy - 6, CORE)
	_px(img, cx - 3, cy - 6, CORE)
	_threads(img, Vector2(cx, cy), 30, 60, rng, 0.35)
	# обломки мира, втянутые в пустоту: дома, мельницы, куски дворца, камни
	var sky := Color(0.30, 0.12, 0.40)
	for i in 14:
		var ox := rng.randi_range(10, w - 10)
		var oy := rng.randi_range(int(fy * 0.08), int(fy * 0.85))
		if Vector2(ox - cx, (oy - cy) * 2).length() < 90:
			continue
		match i % 4:
			0: _windmill(img, ox, oy, rng.randi_range(8, 14), 0.45, sky, 1.2, rng.randf() * TAU)
			1: _farmhouse(img, ox, oy, rng.randi_range(3, 6), 0.45, sky)
			2:
				for j in rng.randi_range(10, 18):
					_rect(img, ox - 3, oy - j, 6, 1, Color(0.10, 0.06, 0.14))
				_px(img, ox, oy - 8, Color(0.80, 0.42, 1.0))
			3: _clod(img, ox, oy, rng.randi_range(3, 7), sky, 0.4, rng)
		for s in 5:
			_px(img, ox, oy + 4 + s * 2, Color(RIFT.r, RIFT.g, RIFT.b, 0.3 - s * 0.05))
	# внизу — бездонная пустота
	PixelArt._vgrad(img, 0, w, fy + 4, h, Color(0.10, 0.02, 0.15), Color(0.0, 0.0, 0.0), 8)
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.03, 0.05, rng)
	return img

# ===================== Сердце Бездны (101–103, только сложная Арена) =====================
# Бескрайняя тьма, в небе — огромное бьющееся сердце бездны, от него во все стороны
# тянутся светящиеся жилы; внизу — обломки миров, уносимые в пустоту.
# level: 0 — Совет, 1 — Лорд Бездны, 2 — Странник (сердце треснуло и кровоточит светом)
static func heart_backdrop(map_w: float, floor_y: float, level := 0) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 10301 + level
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.03, 0.01, 0.05), Color(0.20, 0.06, 0.26).lerp(Color(0.34, 0.06, 0.20), 0.3 * level), 20)
	for i in 120:
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color(0.95, 0.85, 1.0, rng.randf_range(0.2, 0.8)))
	var cx := int(w * 0.5)
	var cy := int(h * 0.30)
	# жилы
	for k in 22 + level * 6:
		var a := rng.randf() * TAU
		var q := Vector2(cx, cy)
		var len := rng.randi_range(40, 160)
		for s in len:
			a += rng.randf_range(-0.25, 0.25)
			q += Vector2.from_angle(a)
			if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
				break
			_px(img, int(q.x), int(q.y), Color(RIFT.r, RIFT.g, RIFT.b, 0.55 - 0.5 * s / len))
	# сердце: две доли и острие вниз
	PixelArt._halo(img, cx, cy, 70 + level * 12, Color(RIFT.r, RIFT.g, RIFT.b, 0.45))
	var r := 18 + level * 2
	_disc(img, cx - r / 2, cy - 4, r, r, Color(0.32, 0.06, 0.40))
	_disc(img, cx + r / 2, cy - 4, r, r, Color(0.32, 0.06, 0.40))
	for y in r + 14:
		var hw := int((r + 6) * (1.0 - float(y) / (r + 14)))
		_rect(img, cx - hw, cy + y - 4, hw * 2 + 1, 1, Color(0.32, 0.06, 0.40))
	_disc(img, cx - r / 2 + 2, cy - 7, r / 3, r / 4, Color(0.70, 0.30, 0.95))
	_disc(img, cx, cy + 4, r / 2, r / 2, Color(0.55, 0.15, 0.75))
	if level >= 1:
		var p := Vector2(cx - 2, cy - r)
		for s in r * 2 + 6:
			p += Vector2(rng.randf_range(-1.0, 1.0), 1.0)
			_px(img, int(p.x), int(p.y), CORE)
	if level >= 2:
		for k in 40:
			var d := Vector2(cx + rng.randi_range(-r, r), cy + r + rng.randi_range(0, 80))
			_px(img, int(d.x), int(d.y), Color(0.95, 0.80, 1.0, rng.randf_range(0.3, 0.9)))
	# обломки миров
	for i in 14:
		RiftArt._cloud(img, rng.randi_range(0, w), rng.randi_range(int(h * 0.55), h - 6), rng.randi_range(2, 5), Color(0.10, 0.05, 0.14), rng)
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.03, 0.05, rng)
	return img
