class_name Castles
# ---------- Карта Дуэли «Замки» ----------
# Слева — синий замок (Игрок 1), справа — красный (Игрок 2). Посередине — ров
# с водой и деревянный мост (сквозной: из воды на него можно запрыгнуть снизу),
# над мостом — каменный уступ с алтарём баффов. Между замком и рвом — поле:
# деревья, ящики, площадки.
# Замок: высокая башня с винтовыми площадками и пушкой на смотровой площадке,
# донжон в три этажа (лестницы, зал с троном и знамёнами, оружейные стойки,
# спальня наверху со станцией лечения), зубчатая крыша со второй пушкой.
# Стены крепкие, деревянные этажи и мебель ломаются легко и горят.
#
# «Мгновенная смерть» — «Осада!»: пушки замков оживают и бьют по чужакам
# (синие — по красному игроку, красные — по синему): на земле видна метка, куда
# упадёт ядро. Горящие стрелы поджигают мост. Пушку можно заставить замолчать —
# выбей площадку из-под неё, и она рухнет.

const W := 4800.0
const H := 1500.0
const G := H - 48.0            # дно рва (низ карты)
const GL := G - 200.0          # земля у замков
const MOAT_L := 1950.0
const MOAT_R := W - 1950.0
const WATER_Y := G - 112.0     # поверхность воды во рву

const BLUE_STONE := Color(0.53, 0.57, 0.67)
const RED_STONE := Color(0.66, 0.53, 0.50)
const WOOD := Color(0.56, 0.40, 0.25)
const DARK_WOOD := Color(0.40, 0.28, 0.18)
const EARTH := Color(0.44, 0.33, 0.21)
const GRASS := Color(0.40, 0.62, 0.30)
const GOLD := Color(0.95, 0.78, 0.30)
const WATER := Color(0.22, 0.45, 0.75, 0.62)

# Прямоугольник замка: координаты даны для левого (синего), правый — зеркально
static func _r(left: bool, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(x, y, w, h) if left else Rect2(W - x - w, y, w, h)

static func _x(left: bool, x: float) -> float:
	return x if left else W - x

static func build(world: Node) -> Dictionary:
	Maps.build_frame(world, W, H, false)
	if not Maps.preview_mode:
		var sky := PixelArt.make_sprite(PixelArt.valley_backdrop(W, -1500.0, GL), PixelArt.SCALE)
		sky.position = Vector2(0, -1500)
		sky.z_index = -10
		world.add_child(sky)
	# земля по обе стороны рва (неразрушаемая), дно рва — низ карты
	for side in [true, false]:
		var r := _r(side, 0, GL, MOAT_L, G - GL)
		Maps.add_block(world, r, EARTH)
		Maps.add_block(world, Rect2(r.position, Vector2(r.size.x, 10)), GRASS)
	var cannons: Array = []
	for side in [true, false]:
		cannons.append_array(_castle(world, side))
		_field(world, side)
	var bridge := _bridge(world)
	# над мостом — каменный уступ с алтарём баффов
	var top := Rect2(W / 2 - 150, GL - 285, 300, 20)
	Colosseum.plat(world, top)
	var altar := PickupSpawner.new()
	altar.kind = "buff"
	altar.position = Vector2(W / 2, top.position.y)
	world.add_child(altar)
	if not Maps.preview_mode:
		var moat := Moat.new()
		world.add_child(moat)
	return {"size": Vector2(W, H), "p1": Vector2(440, GL - 37), "p2": Vector2(W - 440, GL - 37),
			"follow": true, "open_top": true, "top_y": -200.0,
			"sky": [Vector2(720, GL - 1300), Vector2(W - 720, GL - 1300)],
			"cannons": cannons, "bridge": bridge, "doom": Castles.start_siege}

# «Мгновенная смерть» карты: осада
static func start_siege(ev: DuelEvents) -> Node:
	var s := Siege.new()
	s.events = ev
	s.cannons = ev.info.get("cannons", [])
	s.bridge = ev.info.get("bridge")
	ev.add_child(s)
	return s

# ---------- Замок ----------
static func _castle(world: Node, left: bool) -> Array:
	var stone := BLUE_STONE if left else RED_STONE
	var team_c: Color = Config.OUTLINE_P1 if left else Config.OUTLINE_P2
	var dir := 1.0 if left else -1.0          # куда смотрит замок (к середине)
	# задняя стена: сквозь неё все проходят, выбивают только взрывы
	_back_wall(world, left, stone.darkened(0.35))
	# внешняя стена башни и донжона (до самой смотровой площадки)
	_stone(world, _r(left, 20, GL - 680, 40, 680), stone, "bottom")
	# площадки в башне — зигзагом вверх
	for k in 4:
		var y := GL - 140.0 * (k + 1)
		var x0 := 60.0 if k % 2 == 0 else 160.0
		_wood_floor(world, _r(left, x0, y, 140 if k % 2 == 1 else 130, 20))
	# смотровая площадка башни, зубцы, пушка, флаг
	_stone(world, _r(left, 20, GL - 700, 320, 20), stone.lightened(0.05), "all", true)
	for mx in [20.0, 110.0, 200.0]:
		_stone(world, _r(left, mx, GL - 740, 30, 40), stone, "bottom")
	# стена башни над крышей донжона — с проходом на крышу
	_stone(world, _r(left, 300, GL - 680, 40, 40), stone, "all")
	# этажи донжона (сквозные, деревянные) и крыша
	_wood_floor(world, _r(left, 300, GL - 210, 760, 20))
	_wood_floor(world, _r(left, 300, GL - 420, 760, 20))
	_stone(world, _r(left, 300, GL - 560, 800, 20), stone.lightened(0.05), "all", true)
	for mx in [400.0, 560.0, 720.0, 860.0]:
		_stone(world, _r(left, mx, GL - 600, 30, 40), stone, "bottom")
	# лестницы: с пола на второй этаж — у ворот, со второго на третий — у башни
	for k in 2:
		_wood_floor(world, _r(left, 900 - k * 90, GL - 70 - k * 70, 90, 16))
		_wood_floor(world, _r(left, 380 + k * 90, GL - 280 - k * 70, 90, 16))
	# передняя стена: ворота внизу и окно-бойница на втором этаже
	var front := Maps.make_destructible(_r(left, 1060, GL - 540, 40, 540), 20.0, stone, 220, 60.0)
	front.mat_kind = "stone"
	front.anchored = true
	for cx in front.cols:
		for cy in front.rows:
			var y_top := GL - 540 + cy * 20.0
			var gate := y_top >= GL - 160
			var window := y_top >= GL - 330 and y_top < GL - 230
			if not gate and not window:
				front.cells[Vector2i(cx, cy)] = front.cell_hp
		front.anchors.append(Vector2i(cx, 0))
	world.add_child(front)
	if not Maps.preview_mode:
		_interior(world, left, stone, team_c, dir)
	# мебель: стол в зале, бочки у ворот, ящики и сундук наверху
	_table(world, _x(left, 640), GL)
	for bx in [990.0, 1030.0]:
		_barrel(world, Vector2(_x(left, bx), GL - 26))
	Maps.add_crate(world, Vector2(_x(left, 980), GL - 420 - 31))
	_table(world, _x(left, 560), GL - 210, 120)
	# станция лечения на третьем этаже
	var st := PickupSpawner.new()
	st.kind = "heal"
	st.position = Vector2(_x(left, 720), GL - 420)
	world.add_child(st)
	# пушки: на башне и на крыше у переднего края
	var res: Array = []
	for at in [Vector2(270, GL - 700), Vector2(1020, GL - 560)]:
		var c := Cannon.new()
		c.team = 0 if left else 1
		c.facing = dir
		c.position = Vector2(_x(left, at.x), at.y)
		if not Maps.preview_mode:
			world.add_child(c)
		else:
			c.free()
			continue
		res.append(c)
	if not Maps.preview_mode:
		var flag := Flag.new()
		flag.color = team_c
		flag.dir = dir
		flag.position = Vector2(_x(left, 70), GL - 700)
		world.add_child(flag)
	return res

# Каменный блок замка (anchor: "bottom" — держится нижним рядом, "all" — весь)
static func _stone(world: Node, r: Rect2, c: Color, anchor: String, one_way := false) -> Destructible:
	var d := Maps.make_destructible(r, 20.0, c, 220 if not one_way else 160, 60.0)
	d.mat_kind = "stone"
	d.anchored = true
	d.one_way = one_way
	for cx in d.cols:
		for cy in d.rows:
			if anchor == "all" or cy == d.rows - 1:
				d.anchors.append(Vector2i(cx, cy))
	world.add_child(d)
	return d

# Деревянный сквозной пол: снизу пропрыгнуть, сверху стоять; горит
static func _wood_floor(world: Node, r: Rect2) -> Destructible:
	var d := Maps.make_destructible(r, 20.0 if r.size.y >= 20.0 else 16.0, WOOD, 40, 20.0)
	d.mat_kind = "wood"
	d.one_way = true
	d.flammable = true
	d.anchored = true
	for cy in d.rows:
		d.anchors.append(Vector2i(0, cy))
		d.anchors.append(Vector2i(d.cols - 1, cy))
	world.add_child(d)
	return d

static func _back_wall(world: Node, left: bool, c: Color) -> void:
	var cell := 40.0
	var r := _r(left, 20, GL - 680, 1080, 680)
	var d := Destructible.new()
	d.cell = cell
	d.cols = int(r.size.x / cell)
	d.rows = int(r.size.y / cell)
	d.color = c
	d.mat_kind = "stone"
	d.cell_hp = 60
	d.density = 0.0
	d.background = true
	d.ghost = true
	d.anchored = true
	d.position = r.get_center()
	for cx in d.cols:
		var wx := r.position.x + (cx + 0.5) * cell        # x клетки в мире
		var lx := wx if left else W - wx                 # то же для левого замка
		for cy in d.rows:
			var y := r.position.y + cy * cell
			if lx < 340.0 or y >= GL - 560.0:
				d.cells[Vector2i(cx, cy)] = d.cell_hp
				d.anchors.append(Vector2i(cx, cy))
	world.add_child(d)

# Стол: столешница на двух ножках (на него можно встать)
static func _table(world: Node, x: float, floor_y: float, w := 160.0) -> void:
	var d := Maps.make_destructible(Rect2(x - w / 2, floor_y - 60, w, 60), 20.0, DARK_WOOD, 30, 15.0)
	d.mat_kind = "wood"
	d.flammable = true
	d.anchored = true
	for cx in d.cols:
		d.cells[Vector2i(cx, 0)] = d.cell_hp
	for cx in [0, d.cols - 1]:
		for cy in range(1, d.rows):
			d.cells[Vector2i(cx, cy)] = d.cell_hp
		d.anchors.append(Vector2i(cx, d.rows - 1))
	world.add_child(d)

static func _barrel(world: Node, pos: Vector2) -> void:
	var d := Maps.make_destructible(Rect2(pos - Vector2(20, 26), Vector2(40, 52)), 13.0, WOOD.darkened(0.1), 22, 15.0)
	d.mat_kind = "wood"
	d.flammable = true
	world.add_child(d)

# ---------- Убранство замка (фон: сквозь него ходят) ----------
static func _interior(world: Node, left: bool, stone: Color, team_c: Color, dir: float) -> void:
	var deco := Node2D.new()
	deco.z_index = -4
	world.add_child(deco)
	# окна в задней стене (видно небо), на каждом этаже
	for fy in [GL - 110.0, GL - 320.0, GL - 470.0]:
		for wx in [520.0, 820.0]:
			_window(deco, Vector2(_x(left, wx), fy))
	_window(deco, Vector2(_x(left, 180), GL - 620))
	# ковёр к трону и трон
	var carpet := ColorRect.new()
	carpet.color = team_c.darkened(0.35)
	carpet.size = Vector2(520, 6)
	carpet.position = Vector2(_x(left, 330) if left else _x(left, 850), GL - 6)
	deco.add_child(carpet)
	_throne(deco, Vector2(_x(left, 380), GL), team_c, dir)
	# знамёна в зале и на втором этаже
	for b in [[460.0, GL - 30.0], [760.0, GL - 30.0], [660.0, GL - 240.0]]:
		_banner(deco, Vector2(_x(left, b[0]), b[1] - 170.0), team_c, left)
	# оружейная стойка у ворот, доспех на втором этаже
	_weapon_rack(deco, Vector2(_x(left, 820), GL))
	_armor(deco, Vector2(_x(left, 960), GL - 210), team_c)
	# кровать на третьем этаже
	_bed(deco, Vector2(_x(left, 880), GL - 420), team_c)
	# решётка ворот поднята
	var gate := Node2D.new()
	gate.position = Vector2(_x(left, 1080), GL - 160)
	for k in 4:
		var bar := ColorRect.new()
		bar.color = Color(0.25, 0.24, 0.26)
		bar.size = Vector2(4, 34)
		bar.position = Vector2(-16 + k * 10, 0)
		gate.add_child(bar)
	deco.add_child(gate)
	# факелы на стенах
	for t in [[340.0, GL - 120.0], [1030.0, GL - 120.0], [340.0, GL - 330.0], [1030.0, GL - 330.0],
			[340.0, GL - 500.0], [1030.0, GL - 500.0], [100.0, GL - 620.0]]:
		var torch := Torch.new()
		torch.position = Vector2(_x(left, t[0]), t[1])
		torch.lit = true
		world.add_child(torch)

static func _window(parent: Node, c: Vector2) -> void:
	var w := Polygon2D.new()
	var pts := PackedVector2Array([Vector2(-24, 40), Vector2(-24, -20)])
	for k in 9:
		pts.append(Vector2(-24 * cos(PI * k / 8.0), -20 - 24 * sin(PI * k / 8.0)))
	pts.append(Vector2(24, 40))
	w.polygon = pts
	w.position = c
	w.color = Color(0.55, 0.72, 0.95)
	parent.add_child(w)
	var frame := Line2D.new()
	var fp := pts.duplicate()
	fp.append(pts[0])
	frame.points = fp
	frame.width = 5.0
	frame.default_color = Color(0.30, 0.28, 0.30)
	frame.position = c
	parent.add_child(frame)
	for seg in [[Vector2(0, -44), Vector2(0, 40)], [Vector2(-24, 4), Vector2(24, 4)]]:
		var l := Line2D.new()
		l.points = PackedVector2Array(seg)
		l.width = 3.0
		l.default_color = Color(0.30, 0.28, 0.30)
		l.position = c
		parent.add_child(l)

static func _banner(parent: Node, top: Vector2, c: Color, blue: bool) -> void:
	var rod := ColorRect.new()
	rod.color = GOLD.darkened(0.2)
	rod.size = Vector2(70, 5)
	rod.position = top + Vector2(-35, -5)
	parent.add_child(rod)
	var cloth := Polygon2D.new()
	cloth.polygon = PackedVector2Array([Vector2(-28, 0), Vector2(28, 0), Vector2(28, 120), Vector2(0, 140), Vector2(-28, 120)])
	cloth.color = c.darkened(0.15)
	cloth.position = top
	parent.add_child(cloth)
	var trim := Line2D.new()
	trim.points = PackedVector2Array([Vector2(-24, 4), Vector2(24, 4), Vector2(24, 117), Vector2(0, 135), Vector2(-24, 117), Vector2(-24, 4)])
	trim.width = 3.0
	trim.default_color = GOLD
	trim.position = top
	parent.add_child(trim)
	var em := Polygon2D.new()
	if blue:            # синие — звезда
		var pts := PackedVector2Array()
		for k in 10:
			var r := 16.0 if k % 2 == 0 else 7.0
			pts.append(Vector2.from_angle(-PI / 2 + k * PI / 5) * r)
		em.polygon = pts
	else:               # красные — корона
		em.polygon = PackedVector2Array([Vector2(-16, 10), Vector2(-16, -8), Vector2(-8, 2), Vector2(0, -12),
				Vector2(8, 2), Vector2(16, -8), Vector2(16, 10)])
	em.color = Color(1.0, 0.95, 0.8)
	em.position = top + Vector2(0, 55)
	parent.add_child(em)

static func _throne(parent: Node, base: Vector2, c: Color, dir: float) -> void:
	var t := Node2D.new()
	t.position = base
	t.scale.x = dir
	parent.add_child(t)
	var dais := ColorRect.new()
	dais.color = Color(0.45, 0.42, 0.44)
	dais.size = Vector2(110, 12)
	dais.position = Vector2(-55, -12)
	t.add_child(dais)
	var back := Polygon2D.new()
	back.polygon = PackedVector2Array([Vector2(-34, -12), Vector2(-34, -120), Vector2(-24, -138), Vector2(-14, -124),
			Vector2(-4, -142), Vector2(6, -124), Vector2(-4, -12)])
	back.color = GOLD.darkened(0.15)
	t.add_child(back)
	var cush := Polygon2D.new()
	cush.polygon = PackedVector2Array([Vector2(-28, -40), Vector2(-28, -110), Vector2(-10, -110), Vector2(-10, -40)])
	cush.color = c.darkened(0.2)
	t.add_child(cush)
	var seat := Polygon2D.new()
	seat.polygon = PackedVector2Array([Vector2(-36, -40), Vector2(26, -40), Vector2(26, -12), Vector2(-36, -12)])
	seat.color = GOLD.darkened(0.3)
	t.add_child(seat)
	var pad := ColorRect.new()
	pad.color = c.darkened(0.1)
	pad.size = Vector2(56, 8)
	pad.position = Vector2(-32, -48)
	t.add_child(pad)

static func _weapon_rack(parent: Node, base: Vector2) -> void:
	var frame := Line2D.new()
	frame.points = PackedVector2Array([Vector2(-50, 0), Vector2(-50, -110), Vector2(50, -110), Vector2(50, 0)])
	frame.width = 6.0
	frame.default_color = DARK_WOOD
	frame.position = base
	parent.add_child(frame)
	for k in 4:
		var x := -36.0 + k * 24.0
		var shaft := Line2D.new()
		shaft.points = PackedVector2Array([Vector2(x, -4), Vector2(x, -150)])
		shaft.width = 3.0
		shaft.default_color = Color(0.55, 0.42, 0.28)
		shaft.position = base
		parent.add_child(shaft)
		var tip := Polygon2D.new()
		if k % 2 == 0:       # копьё
			tip.polygon = PackedVector2Array([Vector2(x - 5, -150), Vector2(x, -170), Vector2(x + 5, -150)])
		else:                # меч
			tip.polygon = PackedVector2Array([Vector2(x - 3, -110), Vector2(x - 3, -168), Vector2(x, -176), Vector2(x + 3, -168), Vector2(x + 3, -110)])
		tip.color = Color(0.80, 0.82, 0.86)
		tip.position = base
		parent.add_child(tip)
	var shield := Polygon2D.new()
	shield.polygon = PackedVector2Array([Vector2(-20, -24), Vector2(20, -24), Vector2(20, 4), Vector2(0, 22), Vector2(-20, 4)])
	shield.color = Color(0.62, 0.62, 0.66)
	shield.position = base + Vector2(0, -60)
	parent.add_child(shield)

static func _armor(parent: Node, base: Vector2, c: Color) -> void:
	var a := Node2D.new()
	a.position = base
	parent.add_child(a)
	var pole := ColorRect.new()
	pole.color = DARK_WOOD
	pole.size = Vector2(6, 100)
	pole.position = Vector2(-3, -100)
	a.add_child(pole)
	var chest := Polygon2D.new()
	chest.polygon = PackedVector2Array([Vector2(-22, -96), Vector2(22, -96), Vector2(18, -50), Vector2(-18, -50)])
	chest.color = Color(0.70, 0.72, 0.76)
	a.add_child(chest)
	var tabard := Polygon2D.new()
	tabard.polygon = PackedVector2Array([Vector2(-10, -90), Vector2(10, -90), Vector2(10, -40), Vector2(-10, -40)])
	tabard.color = c
	a.add_child(tabard)
	var helm := Polygon2D.new()
	helm.polygon = Util.circle(14.0, 12)
	helm.color = Color(0.74, 0.76, 0.80)
	helm.position = Vector2(0, -112)
	a.add_child(helm)
	var slit := ColorRect.new()
	slit.color = Color(0.1, 0.1, 0.12)
	slit.size = Vector2(16, 3)
	slit.position = Vector2(-8, -114)
	a.add_child(slit)

static func _bed(parent: Node, base: Vector2, c: Color) -> void:
	var frame := ColorRect.new()
	frame.color = DARK_WOOD
	frame.size = Vector2(150, 30)
	frame.position = base + Vector2(-75, -40)
	parent.add_child(frame)
	var blanket := ColorRect.new()
	blanket.color = c.darkened(0.1)
	blanket.size = Vector2(110, 14)
	blanket.position = base + Vector2(-40, -52)
	parent.add_child(blanket)
	var pillow := ColorRect.new()
	pillow.color = Color(0.92, 0.92, 0.88)
	pillow.size = Vector2(34, 12)
	pillow.position = base + Vector2(-74, -52)
	parent.add_child(pillow)
	var head := ColorRect.new()
	head.color = DARK_WOOD.darkened(0.15)
	head.size = Vector2(10, 70)
	head.position = base + Vector2(-82, -70)
	parent.add_child(head)

# ---------- Поле между замком и рвом ----------
static func _field(world: Node, left: bool) -> void:
	for tx in [1280.0, 1780.0]:
		Maps.add_tree(world, _x(left, tx), GL)
	for c in [Vector2(1470, GL - 31), Vector2(1535, GL - 31), Vector2(1502, GL - 92)]:
		Maps.add_crate(world, Vector2(_x(left, c.x), c.y))
	Maps.add_platform(world, _r(left, 1580, GL - 130, 200, 20), true)
	# над рвом — площадка к уступу с алтарём
	Maps.add_platform(world, _r(left, 2010, GL - 150, 170, 20), true)
	# ступени из рва наверх (у стенки рва)
	Colosseum.plat(world, _r(left, MOAT_L, G - 72, 90, 16))
	Colosseum.plat(world, _r(left, MOAT_L + 40, G - 144, 90, 16))
	if not Maps.preview_mode:
		# плетень у края рва
		for k in 4:
			var post := ColorRect.new()
			post.color = DARK_WOOD
			post.size = Vector2(8, 46)
			post.position = Vector2(_x(left, 1860 + k * 26) - 4, GL - 46)
			post.z_index = -3
			world.add_child(post)
		var rail := ColorRect.new()
		rail.color = WOOD
		rail.size = Vector2(90, 6)
		rail.position = Vector2(_x(left, 1860) - (0.0 if left else 90.0), GL - 34)
		rail.z_index = -3
		world.add_child(rail)

# ---------- Мост через ров ----------
static func _bridge(world: Node) -> Destructible:
	var d := Maps.make_destructible(Rect2(MOAT_L, GL, MOAT_R - MOAT_L, 20), 20.0, WOOD, 45, 20.0)
	d.mat_kind = "wood"
	d.one_way = true
	d.flammable = true
	d.anchored = true
	for cx in d.cols:
		if cx % 2 == 0:
			d.cell_colors[Vector2i(cx, 0)] = WOOD.darkened(0.12)
	# держится за края и за опоры
	for cx in [0, 1, d.cols - 2, d.cols - 1, 14, 15, d.cols - 16, d.cols - 15]:
		d.anchors.append(Vector2i(cx, 0))
	world.add_child(d)
	# каменные опоры до дна рва
	for px in [MOAT_L + 290.0, MOAT_R - 330.0]:
		var p := Maps.make_destructible(Rect2(px, GL + 20, 40, G - GL - 20), 20.0, Maps.STONE, 120, 45.0)
		p.anchored = true
		for cx in p.cols:
			p.anchors.append(Vector2i(cx, p.rows - 1))
		world.add_child(p)
	if not Maps.preview_mode:
		# перила: столбики и канат
		var rails := Node2D.new()
		rails.z_index = -3
		world.add_child(rails)
		var x := MOAT_L + 10.0
		var pts := PackedVector2Array()
		while x <= MOAT_R - 10.0:
			var post := ColorRect.new()
			post.color = DARK_WOOD
			post.size = Vector2(6, 40)
			post.position = Vector2(x - 3, GL - 40)
			rails.add_child(post)
			pts.append(Vector2(x, GL - 36))
			x += 90.0
		var rope := Line2D.new()
		rope.points = pts
		rope.width = 3.0
		rope.default_color = Color(0.75, 0.62, 0.42)
		rails.add_child(rope)
	return d

# ======================= Вода во рву =======================
# В воде герои двигаются медленнее; видна рябь.
class Moat extends Node2D:
	var _top: Polygon2D
	var _t := 0.0

	func _ready() -> void:
		z_index = 5
		var body := ColorRect.new()
		body.color = Castles.WATER
		body.position = Vector2(Castles.MOAT_L, Castles.WATER_Y)
		body.size = Vector2(Castles.MOAT_R - Castles.MOAT_L, Castles.G - Castles.WATER_Y)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(body)
		_top = Polygon2D.new()
		_top.color = Color(0.55, 0.75, 1.0, 0.7)
		add_child(_top)

	func _physics_process(delta: float) -> void:
		_t += delta
		var pts := PackedVector2Array()
		var x := Castles.MOAT_L
		while x <= Castles.MOAT_R:
			pts.append(Vector2(x, Castles.WATER_Y - 3.0 + 3.0 * sin(x * 0.03 + _t * 3.0)))
			x += 30.0
		pts.append(Vector2(Castles.MOAT_R, Castles.WATER_Y + 4))
		pts.append(Vector2(Castles.MOAT_L, Castles.WATER_Y + 4))
		_top.polygon = pts
		for n in get_parent().get_children():
			if n is Player and n.is_alive():
				var p: Player = n
				var feet := p.global_position.y + p.body_size.y / 2
				if feet > Castles.WATER_Y + 8.0 and p.global_position.x > Castles.MOAT_L and p.global_position.x < Castles.MOAT_R:
					p.slow(0.15, 0.6, "water")
					if absf(p.velocity.y) > 300.0 and randf() < 0.3:
						Fx.sparks(get_parent(), Vector2(p.global_position.x, Castles.WATER_Y), Color(0.75, 0.88, 1.0), 4, 160.0, 4.0)

# ======================= Флаг на башне =======================
class Flag extends Node2D:
	var color := Color.BLUE
	var dir := 1.0
	var _cloth: Polygon2D
	var _t := 0.0

	func _ready() -> void:
		z_index = -2
		var pole := ColorRect.new()
		pole.color = Color(0.35, 0.28, 0.2)
		pole.size = Vector2(6, 170)
		pole.position = Vector2(-3, -170)
		add_child(pole)
		var knob := Polygon2D.new()
		knob.polygon = Util.circle(6.0, 8)
		knob.color = Castles.GOLD
		knob.position = Vector2(0, -172)
		add_child(knob)
		_cloth = Polygon2D.new()
		_cloth.color = color
		add_child(_cloth)

	func _process(delta: float) -> void:
		_t += delta
		var pts := PackedVector2Array()
		var lower := PackedVector2Array()
		for k in 7:
			var x := k * 15.0 * dir
			var wave := sin(_t * 5.0 - k * 0.8) * (1.5 + k * 1.2)
			pts.append(Vector2(x, -164 + wave))
			lower.append(Vector2(x, -124 + wave))
		lower.reverse()
		pts.append_array(lower)
		_cloth.polygon = pts

# ======================= Пушка =======================
class Cannon extends Node2D:
	var team := 0                 # чей замок: бьёт по игроку другой команды
	var facing := 1.0
	var broken := false
	var _barrel: Node2D
	var _aim := 0.0

	func _ready() -> void:
		z_index = 2
		var carriage := Polygon2D.new()
		carriage.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-20, -22), Vector2(18, -22), Vector2(26, 0)])
		carriage.color = Castles.DARK_WOOD
		add_child(carriage)
		for wx in [-14.0, 14.0]:
			var wheel := Polygon2D.new()
			wheel.polygon = Util.circle(9.0, 10)
			wheel.color = Color(0.22, 0.16, 0.10)
			wheel.position = Vector2(wx, -6)
			add_child(wheel)
		_barrel = Node2D.new()
		_barrel.position = Vector2(0, -24)
		add_child(_barrel)
		var tube := Polygon2D.new()
		tube.polygon = PackedVector2Array([Vector2(-14, -9), Vector2(40, -7), Vector2(44, -9), Vector2(44, 9), Vector2(40, 7), Vector2(-14, 9)])
		tube.color = Color(0.20, 0.21, 0.24)
		_barrel.add_child(tube)
		var band := ColorRect.new()
		band.color = Color(0.45, 0.42, 0.30)
		band.size = Vector2(5, 18)
		band.position = Vector2(8, -9)
		_barrel.add_child(band)
		_set_aim(0.35)

	# Наклон ствола: e — угол над горизонтом (вверх — больше нуля)
	func _set_aim(e: float) -> void:
		_aim = e
		_barrel.scale.x = facing
		_barrel.rotation = -e * facing

	func muzzle() -> Vector2:
		return _barrel.global_position + Vector2(facing * cos(_aim), -sin(_aim)) * 44.0

	# Стоит ли ещё на площадке
	func supported() -> bool:
		var space := get_world_2d().direct_space_state
		var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -4), global_position + Vector2(0, 30), Layer.WORLD)
		return not space.intersect_ray(q).is_empty()

	# Площадку выбили — пушка падает и замолкает
	func fall() -> void:
		if broken:
			return
		broken = true
		var space := get_world_2d().direct_space_state
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 30), global_position + Vector2(0, 3000), Layer.WORLD))
		var land: float = hit["position"].y if not hit.is_empty() else Castles.G
		var t := create_tween()
		t.tween_property(self, "position:y", land, clampf((land - position.y) / 900.0, 0.2, 1.2)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(self, "rotation", 0.8 * facing, 0.6)
		t.tween_callback(func():
			Fx.sparks(get_parent(), global_position, Color(0.5, 0.5, 0.5), 10, 200.0, 4.0, true)
			modulate = Color(0.55, 0.5, 0.5))

	# Выстрел: ствол наводится, отдача, вспышка и дым
	func fire_at(goal: Vector2, flight: float) -> CannonBall:
		if absf(goal.x - global_position.x) > 10.0:
			facing = signf(goal.x - global_position.x)      # цель за спиной — разворачивается
		var from := muzzle()
		var g := CannonBall.GRAVITY
		var v := Vector2((goal.x - from.x) / flight, (goal.y - from.y - 0.5 * g * flight * flight) / flight)
		_set_aim(clampf(atan2(-v.y, absf(v.x)), -0.5, 1.3))
		from = muzzle()
		v = Vector2((goal.x - from.x) / flight, (goal.y - from.y - 0.5 * g * flight * flight) / flight)
		var b := CannonBall.new()
		b.position = from
		b.vel = v
		b.goal = goal
		b.life = flight + 1.5
		get_parent().add_child(b)
		var t := _barrel.create_tween()
		var base := _barrel.position
		t.tween_property(_barrel, "position", base + Vector2(-10 * facing, 2), 0.06)
		t.tween_property(_barrel, "position", base, 0.35)
		Util.flash(get_parent(), from, 34.0, Color(1.0, 0.85, 0.5, 0.9))
		Fx.sparks(get_parent(), from, Color(0.75, 0.75, 0.75, 0.8), 8, 120.0, 7.0)
		return b

# ======================= Ядро =======================
# Летит по дуге; там, куда упадёт, на земле заранее мигает метка.
class CannonBall extends Node2D:
	const GRAVITY := 900.0
	var vel := Vector2.ZERO
	var goal := Vector2.ZERO
	var life := 3.0
	var _mark: Node2D
	var _done := false

	func _ready() -> void:
		z_index = 7
		var ball := Polygon2D.new()
		ball.polygon = Util.circle(11.0, 12)
		ball.color = Color(0.13, 0.13, 0.15)
		add_child(ball)
		var shine := Polygon2D.new()
		shine.polygon = Util.circle(3.5, 6)
		shine.color = Color(0.6, 0.6, 0.65)
		shine.position = Vector2(-4, -4)
		add_child(shine)
		_mark = Node2D.new()
		_mark.position = goal
		_mark.z_index = 6
		var ring := Line2D.new()
		var pts := Util.circle(46.0, 20)
		for i in pts.size():
			pts[i].y *= 0.35
		pts.append(pts[0])
		ring.points = pts
		ring.width = 4.0
		ring.default_color = Color(1.0, 0.25, 0.15, 0.9)
		_mark.add_child(ring)
		var cross := Line2D.new()
		cross.points = PackedVector2Array([Vector2(-14, 0), Vector2(14, 0)])
		cross.width = 3.0
		cross.default_color = Color(1.0, 0.25, 0.15, 0.9)
		_mark.add_child(cross)
		get_parent().call_deferred("add_child", _mark)

	func _physics_process(delta: float) -> void:
		life -= delta
		if is_instance_valid(_mark):
			_mark.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02)
		var from := global_position
		vel.y += GRAVITY * delta
		var to := from + vel * delta
		var space := get_world_2d().direct_space_state
		var q := PhysicsRayQueryParameters2D.create(from, to, Layer.WORLD | Layer.PLAYER)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			var c = hit["collider"]
			if not (c is Player and not c.is_alive()):
				global_position = hit["position"]
				_boom()
				return
		global_position = to
		if randf() < 0.5:
			Fx.sparks(get_parent(), global_position, Color(0.6, 0.6, 0.6, 0.6), 1, 30.0, 5.0)
		if life <= 0.0 or global_position.y > Castles.H + 200.0:
			_boom()

	func _boom() -> void:
		if _done:
			return
		_done = true
		var world := get_parent()
		Util.explode(world, global_position, 115.0, 26, 170, 2, null)
		Util.flash(world, global_position, 150.0, Color(1.0, 0.8, 0.45, 0.8))
		Fx.ring(world, global_position, 120.0, Color(1.0, 0.6, 0.25, 0.9), 0.35, 6.0)
		Fx.sparks(world, global_position, Color(0.45, 0.42, 0.40), 14, 320.0, 6.0, true)
		if is_instance_valid(_mark):
			_mark.queue_free()
		queue_free()

# ======================= «Осада!» — Мгновенная смерть =======================
class Siege extends Node:
	var events: DuelEvents
	var cannons: Array = []
	var bridge: Destructible
	var _t := {}
	var _age := 0.0
	var _arrows := 6

	func _ready() -> void:
		for c in cannons:
			_t[c] = randf_range(0.6, 1.6)

	func _physics_process(delta: float) -> void:
		if events == null or not is_instance_valid(events) or not events.active or not events.doom:
			return
		_age += delta
		var world: Node = events.world
		# горящие стрелы летят в мост
		if _arrows > 0 and _age > 0.4 * (7 - _arrows):
			_arrows -= 1
			_fire_arrow(world)
		for c in cannons:
			if not is_instance_valid(c) or c.broken:
				continue
			if not c.supported():
				c.fall()
				continue
			_t[c] -= delta
			if _t[c] > 0.0:
				continue
			_t[c] = maxf(1.0, 2.8 - _age * 0.03) * randf_range(0.8, 1.25)
			var target := _target_for(c)
			if target == null:
				continue
			var flight := clampf(c.global_position.distance_to(target.global_position) / 1100.0, 0.9, 1.9)
			var lead: Vector2 = target.velocity * flight * 0.35
			var aim_x := target.global_position.x + lead.x + randf_range(-70.0, 70.0)
			var goal := _ground(world, aim_x, target.global_position.y - 40.0)
			c.fire_at(goal, flight)

	# Пушки бьют по чужаку; если его нет в живых — молчат
	func _target_for(c) -> Player:
		for p in events.players:
			if is_instance_valid(p) and p.is_alive() and p.team != c.team:
				return p
		return null

	func _ground(world: Node, x: float, from_y: float) -> Vector2:
		var space: PhysicsDirectSpaceState2D = world.get_world_2d().direct_space_state
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, Castles.H + 50.0), Layer.WORLD))
		return hit["position"] if not hit.is_empty() else Vector2(x, Castles.G)

	# Горящая стрела: прочерк по небу и пожар на мосту
	func _fire_arrow(world: Node) -> void:
		if bridge == null or not is_instance_valid(bridge):
			return
		var x := randf_range(Castles.MOAT_L + 60.0, Castles.MOAT_R - 60.0)
		var at := Vector2(x, Castles.GL + 6.0)
		var from := Vector2(x + randf_range(-500, 500), Castles.GL - 900.0)
		var l := Line2D.new()
		l.points = PackedVector2Array([from, from])
		l.width = 3.0
		l.default_color = Color(1.0, 0.6, 0.2)
		l.z_index = 7
		world.add_child(l)
		var t := l.create_tween()
		t.tween_method(func(k: float):
			l.points = PackedVector2Array([from.lerp(at, maxf(0.0, k - 0.15)), from.lerp(at, k)]), 0.0, 1.0, 0.45)
		t.tween_callback(func():
			if is_instance_valid(bridge):
				bridge.hit(at, Vector2.ZERO, 1, 30.0, 2, {"fire": true, "strict": true, "radial": true})
			Fx.sparks(world, at, Color(1.0, 0.6, 0.2), 8, 160.0, 4.0)
			l.queue_free())
