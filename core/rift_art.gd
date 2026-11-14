class_name RiftArt
# ---------- Фоны земель Странника (волны 81–90) ----------
#   sky_backdrop              — Летающие острова: высокое небо, море облаков внизу,
#                               острова с башнями, домами и водопадами, цепи между ними,
#                               а в стороне — фиолетовый разрыв в небе;
#   burning_village_backdrop  — Окраина деревни в огне: багровое небо, столбы дыма,
#                               горящие дома и мельница, колокольня, выжженное поле.
#                               Точки пожаров (для живого огня поверх фона) — в fires.
# Рисуется маленькая картинка (в SCALE раз меньше карты) и растягивается без сглаживания.

const SCALE := PixelArt.SCALE
const RIFT := Color(0.78, 0.36, 1.0)          # свет разлома
const RIFT_CORE := Color(0.98, 0.86, 1.0)

static var fires: Array = []                    # где на фоне горит (координаты карты)

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	FarArt._px(img, x, y, c)

static func _disc(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for y in range(-ry, ry + 1):
		var hw := int(rx * sqrt(maxf(0.0, 1.0 - float(y * y) / float(maxi(ry * ry, 1)))))
		for x in range(-hw, hw + 1):
			_px(img, cx + x, cy + y, c)

# Разрыв в небе: рваная вертикальная щель со светом по краям
static func rift_tear(img: Image, cx: int, cy: int, h: int, rng: RandomNumberGenerator, alpha := 1.0) -> void:
	PixelArt._halo(img, cx, cy, int(h * 0.9), Color(RIFT.r, RIFT.g, RIFT.b, 0.35 * alpha))
	var wob := 0.0
	for i in h:
		var k := sin(PI * float(i) / h)
		var hw := int(round(k * h * 0.09)) + (1 if k > 0.3 else 0)
		wob = clampf(wob + rng.randf_range(-0.8, 0.8), -3.0, 3.0)
		var x := cx + int(wob)
		var y := cy - h / 2 + i
		for dx in range(-hw - 2, hw + 3):
			var edge := absi(dx) > hw
			var c := Color(RIFT.r, RIFT.g, RIFT.b, (0.55 if edge else 1.0) * alpha)
			if not edge and absi(dx) <= maxi(0, hw - 1):
				c = Color(0.08, 0.02, 0.12, alpha)
			if dx == 0 and not edge and k > 0.5:
				c = Color(0.30, 0.10, 0.40, alpha)
			_px(img, x + dx, y, c)
	for i in 10:                                  # искры-осколки вокруг
		var a := rng.randf() * TAU
		var r := rng.randf_range(h * 0.12, h * 0.5)
		_px(img, cx + int(cos(a) * r * 0.6), cy + int(sin(a) * r), Color(RIFT_CORE.r, RIFT_CORE.g, RIFT_CORE.b, 0.8 * alpha))

# Летающий остров: зелёная шапка, скала сужается книзу, корни, водопад и постройки сверху
static func _isle(img: Image, cx: int, top: int, hw: int, depth: int, haze: float, rng: RandomNumberGenerator,
		builds: Array, fall := false) -> void:
	var sky := Color(0.62, 0.78, 0.96)
	var grass := Color(0.42, 0.66, 0.30).lerp(sky, haze)
	var rock := Color(0.52, 0.44, 0.38).lerp(sky, haze)
	var rock_d := Color(0.38, 0.32, 0.30).lerp(sky, haze)
	var w := img.get_width()
	var bottom := PackedInt32Array()
	bottom.resize(hw * 2 + 1)
	for i in hw * 2 + 1:
		var x := i - hw
		var k := 1.0 - absf(float(x)) / hw
		var d := int(depth * pow(k, 0.7)) + rng.randi_range(-2, 2)
		if rng.randf() < 0.12:
			d += rng.randi_range(2, 6)            # каменные сосульки снизу
		bottom[i] = top + 3 + maxi(2, d)
	for i in hw * 2 + 1:
		var x := cx - hw + i
		if x < 0 or x >= w:
			continue
		var b := bottom[i]
		for y in range(top, b):
			var c := rock if (i < hw) else rock_d
			if y < top + 3:
				c = grass if y < top + 2 else grass.darkened(0.25)
			elif (y + i * 3) % 7 == 0:
				c = c.darkened(0.08)
			_px(img, x, y, c)
		if rng.randf() < 0.08:                    # свисающие корни
			for yy in rng.randi_range(3, 9):
				_px(img, x, b + yy, Color(0.35, 0.30, 0.20).lerp(sky, haze + 0.15))
	for i in 3:                                   # кромка травы с кустиками
		var bx := cx + rng.randi_range(-hw + 3, hw - 3)
		PixelArt._bush(img, bx, top - 1, rng.randi_range(2, 3), grass.lightened(0.05))
	if fall:                                      # водопад с края — тает в дымке
		var fx := cx + (hw - 3 if rng.randf() < 0.5 else -hw + 3)
		var fy := top + 2
		for y in range(fy, mini(img.get_height(), fy + depth * 3)):
			var a := 1.0 - float(y - fy) / (depth * 3.0)
			var wc := Color(0.80, 0.90, 1.0, 0.85 * a)
			_px(img, fx + int(sin(y * 0.4) * 0.6), y, wc)
			_px(img, fx + 1, y, Color(0.6, 0.78, 0.96, 0.7 * a))
		PixelArt._halo(img, fx, fy + depth * 3, 6, Color(1, 1, 1, 0.35))
	for bd in builds:
		var kind: String = bd[0]
		var x: int = cx + int(bd[1])
		_building(img, kind, x, top, haze, rng)

static func _building(img: Image, kind: String, x: int, base: int, haze: float, rng: RandomNumberGenerator) -> void:
	var sky := Color(0.62, 0.78, 0.96)
	var wall := Color(0.86, 0.82, 0.74).lerp(sky, haze)
	var wall_d := wall.darkened(0.18)
	var roof := Color(0.30, 0.42, 0.70).lerp(sky, haze)        # синие крыши — небесный город
	var win := Color(1.0, 0.86, 0.50).lerp(sky, haze * 0.6)
	match kind:
		"tower":
			var th := rng.randi_range(18, 26)
			img.fill_rect(Rect2i(x - 3, base - th, 7, th), wall)
			img.fill_rect(Rect2i(x + 2, base - th, 2, th), wall_d)
			for k in 3:
				_px(img, x, base - th + 4 + k * 6, win)
			for i in 10:                                         # конический шпиль
				var hw := int((5 - i * 0.5))
				img.fill_rect(Rect2i(x - hw, base - th - i, hw * 2 + 1, 1), roof if i % 3 else roof.lightened(0.12))
			_px(img, x, base - th - 11, Color(1.0, 0.85, 0.4).lerp(sky, haze))
		"house":
			var hw := rng.randi_range(5, 8)
			var hh := rng.randi_range(5, 7)
			img.fill_rect(Rect2i(x - hw, base - hh, hw * 2, hh), wall)
			img.fill_rect(Rect2i(x + hw - 2, base - hh, 2, hh), wall_d)
			_px(img, x - hw + 2, base - hh + 2, win)
			for i in hw + 1:                                     # двускатная крыша
				img.fill_rect(Rect2i(x - i - 1, base - hh - hw + i - 1, i * 2 + 2, 1), roof if i % 3 else roof.lightened(0.1))
		"dome":
			img.fill_rect(Rect2i(x - 7, base - 7, 14, 7), wall)
			for c2 in [-5, -1, 3]:
				img.fill_rect(Rect2i(x + c2, base - 6, 2, 6), wall_d)
			PixelArt._circle(img, x, base - 8, 5, roof.lightened(0.1))
			img.fill_rect(Rect2i(x - 6, base - 8, 13, 2), wall)
			_px(img, x, base - 14, Color(1.0, 0.85, 0.4).lerp(sky, haze))
		"mill":
			img.fill_rect(Rect2i(x - 2, base - 14, 5, 14), wall)
			for a in 4:
				var ang := 0.3 + a * PI / 2
				for r in 9:
					_px(img, x + int(cos(ang) * r), base - 13 + int(sin(ang) * r), Color(0.55, 0.40, 0.30).lerp(sky, haze))
		"tree":
			img.fill_rect(Rect2i(x, base - 4, 1, 4), Color(0.40, 0.28, 0.18).lerp(sky, haze))
			PixelArt._bush(img, x, base - 6, 3, Color(0.36, 0.60, 0.30).lerp(sky, haze))

# Облачный ком (мягкий, с тенью снизу)
static func _cloud(img: Image, cx: int, cy: int, r: int, c: Color, rng: RandomNumberGenerator) -> void:
	for k in 6:
		var ox := rng.randi_range(-r * 2, r * 2)
		var oy := rng.randi_range(-r / 3, r / 4)
		var rr := rng.randi_range(r / 2, r)
		_disc(img, cx + ox, cy + oy + 1, rr, rr, Color(c.darkened(0.12), c.a))
		_disc(img, cx + ox, cy + oy, rr, rr, c)

# ===================== Летающие острова =====================
# Картинка выше пола карты: в просветах между островами видно небо и облака внизу.
static func sky_backdrop(map_w: float, floor_y: float, below: float) -> Image:
	var w := int(map_w / SCALE)
	var h := int((floor_y + below) / SCALE) + 2
	var fy := int(floor_y / SCALE)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8517
	PixelArt._vgrad(img, 0, w, 0, int(fy * 0.75), Color(0.22, 0.42, 0.82), Color(0.66, 0.82, 0.98), 18)
	PixelArt._vgrad(img, 0, w, int(fy * 0.75), h, Color(0.66, 0.82, 0.98), Color(0.42, 0.52, 0.78), 12)
	# солнце в дымке
	PixelArt._halo(img, int(w * 0.80), int(fy * 0.20), 40, Color(1.0, 0.97, 0.86, 0.55))
	PixelArt._circle(img, int(w * 0.80), int(fy * 0.20), 9, Color(1.0, 0.98, 0.9))
	# разрыв в небе — далеко, но заметно (отсюда пришёл Странник)
	rift_tear(img, int(w * 0.17), int(fy * 0.22), 46, rng, 0.85)
	for k in 14:                                  # фиолетовые нити тянутся от разрыва
		var a2 := rng.randf() * TAU
		var p := Vector2(w * 0.17, fy * 0.22)
		for s in 18:
			p += Vector2.from_angle(a2 + sin(s * 0.5) * 0.4) * 1.6
			_px(img, int(p.x), int(p.y), Color(RIFT.r, RIFT.g, RIFT.b, 0.25 - s * 0.012))
	# тонкие перистые облака
	for i in 12:
		var cy := rng.randi_range(int(fy * 0.06), int(fy * 0.4))
		var cx := rng.randi_range(0, w)
		var ln := rng.randi_range(20, 60)
		for x in ln:
			_px(img, cx + x, cy + int(sin(x * 0.2) * 1.5), Color(1, 1, 1, 0.35))
	# дальние острова — маленькие и в дымке
	var far := [[0.08, 0.50, 16, 10, [["tower", 0]]], [0.30, 0.42, 12, 8, [["house", -3], ["tree", 6]]],
			[0.47, 0.55, 20, 12, [["dome", 0], ["tower", 12]]], [0.63, 0.40, 10, 7, [["tree", 0]]],
			[0.92, 0.48, 18, 11, [["house", -6], ["house", 6]]]]
	for f in far:
		_isle(img, int(w * float(f[0])), int(fy * float(f[1])), f[2], f[3], 0.62, rng, f[4], rng.randf() < 0.5)
	# цепи между двумя дальними островами
	for i in 30:
		var x := int(w * 0.47) + 20 + i
		_px(img, x, int(fy * 0.55) + 4 + int(sin(i / 30.0 * PI) * 6), Color(0.45, 0.48, 0.58, 0.7))
	# облака среднего плана
	for i in 9:
		_cloud(img, rng.randi_range(0, w), rng.randi_range(int(fy * 0.45), int(fy * 0.62)), rng.randi_range(4, 7),
				Color(1, 1, 1, 0.75), rng)
	# средние острова — крупнее, с городом и водопадами
	var mid := [[0.15, 0.60, 50, 30, [["tree", -40], ["tower", -26], ["house", -12], ["house", 2], ["tower", 16], ["tree", 34]]],
			[0.53, 0.65, 58, 34, [["house", -44], ["house", -30], ["dome", -12], ["tower", 4], ["tower", 14], ["house", 28], ["mill", 44]]],
			[0.87, 0.58, 44, 28, [["tree", -32], ["tower", -18], ["dome", 0], ["tower", 16], ["tree", 30]]]]
	for m in mid:
		_isle(img, int(w * float(m[0])), int(fy * float(m[1])), m[2], m[3], 0.32, rng, m[4], true)
	# мост-верёвка между средними
	for i in 60:
		var x := int(w * 0.15) + 50 + i * 2
		var y := int(fy * 0.62) + 2 + int(sin(float(i) / 60.0 * PI) * 12)
		_px(img, x, y, Color(0.45, 0.36, 0.26, 0.8))
		if i % 3 == 0:
			_px(img, x, y + 1, Color(0.35, 0.28, 0.20, 0.8))
	# море облаков внизу — за ним бездонное небо
	var sea := int(fy * 0.80)
	for x in range(-10, w + 10, 7):
		_cloud(img, x, sea + rng.randi_range(-4, 4), rng.randi_range(7, 12), Color(0.96, 0.95, 1.0, 0.95), rng)
	PixelArt._vgrad(img, 0, w, sea + 6, h, Color(0.93, 0.93, 0.99), Color(0.56, 0.62, 0.86), 10)
	for x in range(-10, w + 10, 9):              # нижний ярус облаков (виден в просветах)
		_cloud(img, x, fy + rng.randi_range(18, 40), rng.randi_range(6, 10), Color(0.98, 0.98, 1.0, 0.8), rng)
	PixelArt._birds(img, 9, int(fy * 0.15), int(fy * 0.5), rng, Color(0.25, 0.30, 0.42))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.02, 0.05, rng)
	return img

# ===================== Окраина деревни в огне =====================
static func burning_village_backdrop(map_w: float, floor_y: float) -> Image:
	fires.clear()
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1077                               # та же деревня, что и на волнах 6–10
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.16, 0.03, 0.05), Color(0.86, 0.30, 0.10), 16)
	# огромное багровое солнце за дымом
	PixelArt._halo(img, int(w * 0.2), int(h * 0.30), 34, Color(1.0, 0.45, 0.20, 0.5))
	PixelArt._circle(img, int(w * 0.2), int(h * 0.30), 10, Color(0.95, 0.35, 0.18))
	# тяжёлые тучи дыма
	for i in 30:
		var px := rng.randi_range(-10, w + 10)
		var py := rng.randi_range(2, int(h * 0.38))
		var c2 := Color(0.10, 0.04, 0.05).lerp(Color(0.32, 0.10, 0.08), rng.randf())
		FarArt._puff(img, px, py, rng.randi_range(10, 18), Color(c2.r, c2.g, c2.b, 0.75), rng)
		FarArt._puff(img, px + 2, py + 6, rng.randi_range(4, 8), Color(1.0, 0.42, 0.12, 0.25), rng)
	# разрывы в небе — оттуда пришла свита
	rift_tear(img, int(w * 0.66), int(h * 0.16), 30, rng, 0.9)
	rift_tear(img, int(w * 0.40), int(h * 0.10), 18, rng, 0.6)
	# дальние холмы в зареве
	var hp := []
	for i in 7:
		hp.append([rng.randi_range(0, w), rng.randi_range(18, 40), rng.randi_range(90, 170)])
	var hills := PixelArt._ridge(w, h * 0.72, hp, rng, 0.8)
	PixelArt._mountains(img, hills, h, Color(0.30, 0.10, 0.10), Color(0.22, 0.07, 0.08), -1.0, rng)
	# пригорок с деревней
	var vp := [[int(w * 0.55), 22, 260]]
	var hill := PixelArt._ridge(w, h * 0.80, vp, rng, 0.5)
	PixelArt._mountains(img, hill, h, Color(0.20, 0.12, 0.08), Color(0.16, 0.09, 0.07), -1.0, rng)
	# дома вдоль пригорка — горят
	var x := int(w * 0.30)
	var n := 0
	var smokes: Array = []
	while x < int(w * 0.86):
		var top := int(hill[clampi(x, 0, w - 1)])
		var hw := rng.randi_range(14, 22)
		var hh := rng.randi_range(10, 15)
		var burning := n % 4 != 2
		_burnt_house(img, x, top + 3, hw, hh, rng, burning)
		if burning:
			var fx := x + hw / 2
			var fy := top + 3 - hh - hw / 3
			fires.append(Vector2(fx, fy) * SCALE)
			smokes.append(Vector2(fx, fy - 4))
		x += hw + rng.randi_range(4, 12)
		n += 1
	# колокольня (бьёт набат) и горящая мельница
	var bx := int(w * 0.58)
	var btop := int(hill[bx])
	img.fill_rect(Rect2i(bx, btop - 34, 8, 36), Color(0.34, 0.24, 0.20))
	img.fill_rect(Rect2i(bx + 2, btop - 28, 4, 5), Color(1.0, 0.55, 0.20))
	img.fill_rect(Rect2i(bx + 3, btop - 27, 2, 3), Color(0.55, 0.40, 0.18))           # колокол
	for i in 8:
		img.fill_rect(Rect2i(bx + 4 - i / 2, btop - 42 + i, i + 1, 1), Color(0.16, 0.08, 0.07))
	var mx := int(w * 0.80)
	var mtop := int(hill[mx])
	for i in 22:
		img.fill_rect(Rect2i(mx - 3 - i / 6, mtop - 22 + i, 7 + i / 3, 1), Color(0.26, 0.18, 0.14))
	for a in 3:                                   # одно крыло обломано
		var ang := 0.9 + a * PI / 2
		for r in 16:
			_px(img, mx + int(cos(ang) * r), mtop - 20 + int(sin(ang) * r), Color(0.12, 0.08, 0.06))
	fires.append(Vector2(mx, mtop - 24) * SCALE)
	smokes.append(Vector2(mx, mtop - 30))
	# столбы дыма над пожарами — чёрные, с отсветом снизу
	for f in smokes:
		for k in 22:
			var sy := int(f.y) - k * 4
			var sx := int(f.x) + int(sin(k * 0.45) * 3) + k
			if sy > 0:
				var sc := Color(0.08, 0.04, 0.04).lerp(Color(0.30, 0.12, 0.10), k / 22.0)
				var under := img.get_pixel(clampi(sx, 0, w - 1), clampi(sy, 0, h - 1))
				PixelArt._circle(img, sx, sy, 2 + k / 3, under.lerp(sc, 0.8 - k * 0.025))
	# зарево у земли
	for f in fires:
		PixelArt._halo(img, int(f.x / SCALE), int(f.y / SCALE) + 4, 16, Color(1.0, 0.45, 0.10, 0.45))
	# выжженное поле впереди, сломанный плетень, тлеющие пятна
	var fy2 := int(h * 0.88)
	for x2 in range(0, w, 6):
		if rng.randf() < 0.75:
			img.fill_rect(Rect2i(x2, fy2 - 6 + rng.randi_range(0, 2), 1, 8), Color(0.18, 0.11, 0.08))
	img.fill_rect(Rect2i(0, fy2 - 4, w, 1), Color(0.20, 0.12, 0.08))
	img.fill_rect(Rect2i(0, fy2 + 1, w, h - fy2 - 1), Color(0.26, 0.14, 0.08))
	for x3 in range(0, w, 2):
		var sh := rng.randi_range(1, 4)
		var c3 := Color(0.12, 0.07, 0.05) if x3 % 4 == 0 else Color(0.34, 0.18, 0.08)
		if rng.randf() < 0.06:
			c3 = Color(1.0, 0.45, 0.12)
		img.fill_rect(Rect2i(x3, h - sh - 1, 1, sh), c3)
	# пепел и искры в воздухе
	for i in 380:
		var sx2 := rng.randi_range(0, w - 1)
		var sy2 := rng.randi_range(0, h - 1)
		if rng.randf() < 0.6:
			_px(img, sx2, sy2, Color(0.06, 0.03, 0.03, rng.randf_range(0.3, 0.6)))
		else:
			_px(img, sx2, sy2, Color(1.0, 0.6, 0.25, rng.randf_range(0.4, 0.9)))
	PixelArt._grain(img, Rect2i(0, int(h * 0.6), w, h), 0.05, 0.1, rng)
	return img

# Дом: обугленные стены, светящиеся окна; если горит — крыша в огне
static func _burnt_house(img: Image, x: int, base: int, hw: int, hh: int, rng: RandomNumberGenerator, burning: bool) -> void:
	var wall := Color(0.30, 0.20, 0.16) if burning else Color(0.40, 0.30, 0.24)
	img.fill_rect(Rect2i(x, base - hh, hw, hh), wall)
	img.fill_rect(Rect2i(x, base - hh, 1, hh), Color(0.12, 0.08, 0.06))
	img.fill_rect(Rect2i(x + hw - 1, base - hh, 1, hh), Color(0.12, 0.08, 0.06))
	img.fill_rect(Rect2i(x, base - hh / 2, hw, 1), Color(0.12, 0.08, 0.06))
	var win := Color(1.0, 0.65, 0.20) if burning else Color(0.15, 0.10, 0.10)
	img.fill_rect(Rect2i(x + hw / 3, base - hh + 3, 3, 3), win)
	img.fill_rect(Rect2i(x + hw - 5, base - 5, 3, 5), Color(0.10, 0.06, 0.05))
	var rh := hw / 2 + 2
	for i in rh:
		var row_c := Color(0.20, 0.10, 0.08) if i % 3 else Color(0.14, 0.07, 0.06)
		var gaps := burning and rng.randf() < 0.35
		img.fill_rect(Rect2i(x + hw / 2 - i - 1, base - hh - rh + i, i * 2 + 2, 1), row_c if not gaps else Color(0.9, 0.4, 0.1))
	if burning:                                   # языки пламени над крышей
		for k in 5:
			var fx := x + hw / 2 + rng.randi_range(-hw / 2, hw / 2)
			var fh := rng.randi_range(4, 9)
			for yy in fh:
				var t := float(yy) / fh
				var fc := Color(1.0, 0.85, 0.35).lerp(Color(0.9, 0.25, 0.08), t)
				_px(img, fx + int(sin(yy + k) * 0.8), base - hh - rh + 1 - yy, fc)
				if yy < fh - 2:
					_px(img, fx + 1, base - hh - rh + 1 - yy, fc.darkened(0.1))
