class_name Train
# ---------- Карта Дуэли «Экспресс» ----------
# Бой на мчащемся поезде (тяни-толкай: паровоз с каждого конца). Пейзаж за окнами
# несётся мимо, колёса крутятся, из труб валит дым.
#   Паровоз — тендерная будка (кабина), котёл (на него можно залезть), труба;
#   Пассажирский вагон — скамьи, багажные полки, люк в крыше, станция лечения;
#   Платформы — ящики и брёвна (укрытия);
#   Вагон-ресторан посередине — столики и алтарь баффов.
# Между вагонами — переходы и лесенки на крышу; две сцепки посередине открыты.
# Под колёсами — несущиеся шпалы: кто упал на пути, того бьёт и подбрасывает обратно.
# На крышах дует встречный ветер.
#
# «Мгновенная смерть» — «Тоннели»: поезд разгоняется, паровоз гудит — и через
# пару секунд въезжает в тоннель. Всех, кто выше крыш (на крыше, на котле в прыжке),
# сносит каменным сводом; внутри темно, горят только лампы вагонов. Тоннели — всё
# чаще. Прятаться — внутри вагонов, но искры из-под колёс поджигают вагоны (чаще тот,
# где кто-то сидит), а на крышах ветер всё сильнее сдувает к хвосту — на шпалы.

const W := 5000.0
const H := 1100.0
const G := H - 48.0              # шпалы (низ карты)
const TF := G - 90.0             # пол вагонов
const RT := TF - 220.0           # верх крыш
const CLEAR_Y := RT - 12.0       # свод тоннеля: кто выше — того сносит
const DOOR_H := 140.0            # высота прохода в торцах вагонов

const IRON := Color(0.26, 0.27, 0.30)
const CHASSIS := Color(0.15, 0.15, 0.17)
const GREEN := Color(0.20, 0.42, 0.31)
const WINE := Color(0.47, 0.17, 0.19)
const LOCO := Color(0.17, 0.17, 0.19)
const TRIM := Color(0.86, 0.70, 0.32)
const WOOD := Color(0.56, 0.40, 0.25)
const DARK_WOOD := Color(0.38, 0.27, 0.17)
const LOG := Color(0.45, 0.31, 0.20)

# Вагоны слева направо: [ширина, вид]; между ними — зазоры GAP
const GAP := 80.0
const START := 270.0
const CARS := [[520.0, "loco_l"], [640.0, "pass"], [480.0, "flat_l"], [700.0, "dining"],
		[480.0, "flat_r"], [640.0, "pass"], [520.0, "loco_r"]]
const OPEN_GAPS := [2, 3]       # сцепки без перехода: 2 — между платформой и рестораном, 3 — за ним

static func build(world: Node) -> Dictionary:
	Maps.build_frame(world, W, H, false)
	var info := {"size": Vector2(W, H), "p1": Vector2(1000, TF - 37), "p2": Vector2(W - 1000, TF - 37),
			"follow": true, "open_top": true, "top_y": -200.0,
			"sky": [Vector2(1200, TF - 1100), Vector2(W - 1200, TF - 1100)],
			"x_lo": 250.0, "x_hi": W - 250.0, "spawn_max_y": TF,
			"doom": Train.start_tunnels}
	var lamps: Array = []
	var wheels: Array = []
	var stacks: Array = []
	var x := START
	for i in CARS.size():
		var w: float = CARS[i][0]
		var kind: String = CARS[i][1]
		_floor(world, x, w)
		match kind:
			"loco_l", "loco_r":
				_loco(world, x, w, kind == "loco_l", wheels, stacks, lamps)
			"pass":
				_passenger(world, x, w, i < 3, lamps)
			"dining":
				_dining(world, x, w, lamps)
			"flat_l", "flat_r":
				_flatcar(world, x, w, kind == "flat_r")
		if kind != "loco_l" and kind != "loco_r" and not Maps.preview_mode:
			for k in [0.25, 0.75]:
				wheels.append(_bogie(world, x + w * k))
		x += w
		if i < CARS.size() - 1:
			_gap(world, x, i in OPEN_GAPS)
			x += GAP
	if not Maps.preview_mode:
		var tw := TrainWorld.new()
		tw.wheels = wheels
		tw.stacks = stacks
		world.add_child(tw)
	info["lamps"] = lamps
	return info

# «Мгновенная смерть» карты: тоннели
static func start_tunnels(ev: DuelEvents) -> Node:
	var t := Tunnels.new()
	t.events = ev
	t.lamps = ev.info.get("lamps", [])
	ev.world.add_child(t)
	return t

# ---------- Части поезда ----------
# Пол вагона и рама под ним (неразрушаемые)
static func _floor(world: Node, x0: float, w: float) -> void:
	_solid(world, Rect2(x0, TF, w, 20), IRON)
	_solid(world, Rect2(x0 + 24, TF + 20, w - 48, 36), CHASSIS)

# Неразрушаемый железный блок (как Maps.add_block, но всегда с клёпаным железом)
static func _solid(world: Node, rect: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layer.WORLD | Layer.FRAME
	body.position = rect.get_center()
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	col.shape = rs
	body.add_child(col)
	body.add_child(Tex.slab(rect.size, "iron", color, int(rect.position.x)))
	body.set_meta("color", color)
	world.add_child(body)

# Зазор между вагонами: переход (или открытая сцепка), лесенка на крышу
static func _gap(world: Node, x0: float, open: bool) -> void:
	if not open:
		_solid(world, Rect2(x0, TF, GAP, 12), IRON.darkened(0.2))
	Colosseum.plat(world, Rect2(x0 + 15, TF - 115, GAP - 30, 14))
	if not Maps.preview_mode:
		var coupler := ColorRect.new()
		coupler.color = CHASSIS
		coupler.size = Vector2(GAP + 20, 10)
		coupler.position = Vector2(x0 - 10, TF + 34)
		coupler.z_index = -1
		world.add_child(coupler)
		for bx in [x0 + 4.0, x0 + GAP - 14.0]:        # буфера
			var buf := ColorRect.new()
			buf.color = IRON.lightened(0.15)
			buf.size = Vector2(10, 16)
			buf.position = Vector2(bx, TF + 22)
			buf.z_index = -1
			world.add_child(buf)

# Кузов: крыша (с люками), торцевые перемычки над дверями, задняя стенка
static func _shell(world: Node, x0: float, w: float, paint: Color, hatches: Array) -> void:
	var roof := Maps.make_destructible(Rect2(x0 - 10, RT, w + 20, 20), 20.0, IRON, 120, 50.0)
	roof.mat_kind = "iron"
	roof.anchored = true
	for cx in roof.cols:
		var lx := cx * 20.0 - 10.0                   # от левого края кузова
		var open := false
		for hx in hatches:
			if lx >= hx - 40.0 and lx < hx + 40.0:
				open = true
		if not open:
			roof.cells[Vector2i(cx, 0)] = roof.cell_hp
			roof.cell_colors[Vector2i(cx, 0)] = IRON.lightened(0.08) if cx % 3 == 0 else IRON
	for cx in [0, 1, 2, roof.cols - 3, roof.cols - 2, roof.cols - 1]:
		roof.anchors.append(Vector2i(cx, 0))
	world.add_child(roof)
	for ex in [x0, x0 + w - 20.0]:
		var lintel := Maps.make_destructible(Rect2(ex, RT + 20, 20, TF - DOOR_H - RT - 20), 20.0, paint.darkened(0.2), 120, 40.0)
		lintel.mat_kind = "iron"
		lintel.anchored = true
		lintel.anchors.append(Vector2i(0, 0))
		world.add_child(lintel)
	_back(world, Rect2(x0, RT + 20, w, TF - RT - 20), paint)

# Задняя стенка (фон): сквозь неё ходят, выбивают взрывами
static func _back(world: Node, r: Rect2, paint: Color) -> void:
	var d := Destructible.new()
	d.cell = 40.0
	d.cols = int(r.size.x / 40.0)
	d.rows = int(r.size.y / 40.0)
	d.color = paint.darkened(0.25)
	d.mat_kind = "iron"
	d.cell_hp = 60
	d.density = 0.0
	d.background = true
	d.ghost = true
	d.anchored = true
	d.position = r.get_center()
	for cx in d.cols:
		for cy in d.rows:
			d.anchors.append(Vector2i(cx, cy))
	world.add_child(d)

# Тележка с колёсами под вагоном
static func _bogie(world: Node, cx: float) -> Node2D:
	var b := Node2D.new()
	b.position = Vector2(cx, G - 18)
	b.z_index = 2
	world.add_child(b)
	var frame := ColorRect.new()
	frame.color = CHASSIS.lightened(0.05)
	frame.size = Vector2(110, 12)
	frame.position = Vector2(-55, -22)
	b.add_child(frame)
	var ws: Array = []
	for wx in [-32.0, 32.0]:
		var wh := _wheel(18.0)
		wh.position = Vector2(wx, 0)
		b.add_child(wh)
		ws.append(wh)
	b.set_meta("wheels", ws)
	return b

static func _wheel(r: float) -> Node2D:
	var wh := Node2D.new()
	var rim := Polygon2D.new()
	rim.polygon = Util.circle(r, 16)
	rim.color = Color(0.12, 0.12, 0.13)
	wh.add_child(rim)
	var hub := Polygon2D.new()
	hub.polygon = Util.circle(r * 0.78, 14)
	hub.color = Color(0.30, 0.30, 0.33)
	wh.add_child(hub)
	for k in 4:
		var sp := Line2D.new()
		sp.points = PackedVector2Array([Vector2.from_angle(k * PI / 4) * -r * 0.75, Vector2.from_angle(k * PI / 4) * r * 0.75])
		sp.width = 3.0
		sp.default_color = Color(0.16, 0.16, 0.18)
		wh.add_child(sp)
	var cap := Polygon2D.new()
	cap.polygon = Util.circle(r * 0.22, 8)
	cap.color = Color(0.70, 0.62, 0.40)
	wh.add_child(cap)
	wh.set_meta("r", r)
	return wh

# Окно в задней стенке и лампа под потолком (лампы светят в тоннеле)
static func _windows(world: Node, x0: float, w: float, lamps: Array, n: int) -> void:
	var deco := Node2D.new()
	deco.z_index = -4
	world.add_child(deco)
	var step := w / n
	for k in n:
		var cx := x0 + step * (k + 0.5)
		var win := Polygon2D.new()
		win.polygon = PackedVector2Array([Vector2(-30, -34), Vector2(30, -34), Vector2(30, 26), Vector2(-30, 26)])
		win.color = Color(0.62, 0.80, 0.98)
		win.position = Vector2(cx, TF - 130)
		deco.add_child(win)
		var fr := Line2D.new()
		fr.points = PackedVector2Array([Vector2(-30, -34), Vector2(30, -34), Vector2(30, 26), Vector2(-30, 26), Vector2(-30, -34)])
		fr.width = 4.0
		fr.default_color = TRIM.darkened(0.25)
		fr.position = win.position
		deco.add_child(fr)
		var lamp := Polygon2D.new()
		lamp.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(6, 10), Vector2(-6, 10)])
		lamp.color = Color(1.0, 0.86, 0.5)
		lamp.position = Vector2(cx, RT + 22)
		deco.add_child(lamp)
		var glow := Torch.make_glow(170.0, Color(1.0, 0.85, 0.55, 1.0))
		glow.position = Vector2(cx, RT + 40)
		glow.z_index = 26
		glow.modulate.a = 0.18
		world.add_child(glow)
		lamps.append(glow)
	# золотая полоса по борту
	var trim := ColorRect.new()
	trim.color = TRIM
	trim.size = Vector2(w, 4)
	trim.position = Vector2(x0, TF - 64)
	deco.add_child(trim)

# Пассажирский вагон: скамьи, багажная полка под люком, станция лечения
static func _passenger(world: Node, x0: float, w: float, left_side: bool, lamps: Array) -> void:
	var hatch := w - 120.0 if left_side else 120.0           # люк над полкой — со стороны платформы
	_shell(world, x0, w, GREEN, [hatch])
	# багажная полка под люком (сквозная): с пола на полку, с полки — в люк
	_shelf(world, Rect2(x0 + hatch - 80, TF - 130, 160, 14))
	# скамьи-укрытия
	for bx in [0.38, 0.62]:
		_bench(world, x0 + w * bx)
	var st := PickupSpawner.new()
	st.kind = "heal"
	st.position = Vector2(x0 + (80.0 if left_side else w - 80.0), TF)
	world.add_child(st)
	if not Maps.preview_mode:
		_windows(world, x0, w, lamps, 5)

# Вагон-ресторан: столики, два люка, алтарь баффов посередине
static func _dining(world: Node, x0: float, w: float, lamps: Array) -> void:
	_shell(world, x0, w, WINE, [100.0, w - 100.0])
	for hx in [100.0, w - 100.0]:
		_shelf(world, Rect2(x0 + hx - 80, TF - 130, 160, 14))
	for tx in [0.3, 0.7]:
		_table(world, x0 + w * tx)
	var altar := PickupSpawner.new()
	altar.kind = "buff"
	altar.position = Vector2(x0 + w / 2, TF)
	world.add_child(altar)
	if not Maps.preview_mode:
		_windows(world, x0, w, lamps, 5)
		# барная стойка на фоне
		var bar := ColorRect.new()
		bar.color = DARK_WOOD
		bar.size = Vector2(120, 6)
		bar.position = Vector2(x0 + w / 2 - 60, TF - 92)
		bar.z_index = -4
		world.add_child(bar)

static func _shelf(world: Node, r: Rect2) -> void:
	var d := Maps.make_destructible(r, 14.0, WOOD, 40, 15.0)
	d.mat_kind = "wood"
	d.one_way = true
	d.flammable = true
	d.anchored = true
	d.anchors.append(Vector2i(0, 0))
	d.anchors.append(Vector2i(d.cols - 1, 0))
	world.add_child(d)

static func _bench(world: Node, cx: float) -> void:
	var d := Maps.make_destructible(Rect2(cx - 40, TF - 60, 80, 60), 20.0, DARK_WOOD, 35, 15.0)
	d.mat_kind = "wood"
	d.flammable = true
	d.anchored = true
	for cy in d.rows:                     # спинка
		d.cells[Vector2i(0, cy)] = d.cell_hp
	for cx2 in d.cols:                    # сиденье
		d.cells[Vector2i(cx2, 1)] = d.cell_hp
	d.cells[Vector2i(d.cols - 1, 2)] = d.cell_hp
	d.anchors.append(Vector2i(0, d.rows - 1))
	d.anchors.append(Vector2i(d.cols - 1, 2))
	world.add_child(d)

static func _table(world: Node, cx: float) -> void:
	var d := Maps.make_destructible(Rect2(cx - 50, TF - 60, 100, 60), 20.0, DARK_WOOD, 30, 15.0)
	d.mat_kind = "wood"
	d.flammable = true
	d.anchored = true
	for cx2 in d.cols:
		d.cells[Vector2i(cx2, 0)] = d.cell_hp
	for cy in range(1, d.rows):
		d.cells[Vector2i(2, cy)] = d.cell_hp
	d.anchors.append(Vector2i(2, d.rows - 1))
	world.add_child(d)

# Платформа: низкие борта, большой ящик под брезентом посередине, ящики с
# внешнего края и штабель брёвен (горит) — к ресторану; правая — зеркально
static func _flatcar(world: Node, x0: float, w: float, mirror: bool) -> void:
	var fx := func(d: float) -> float: return x0 + d if not mirror else x0 + w - d
	for ex in [x0, x0 + w - 20.0]:
		var post := Maps.make_destructible(Rect2(ex, TF - 60, 20, 60), 20.0, WOOD, 40, 15.0)
		post.mat_kind = "wood"
		post.flammable = true
		post.anchored = true
		post.anchors.append(Vector2i(0, post.rows - 1))
		world.add_child(post)
	var box := Maps.make_destructible(Rect2(x0 + w / 2 - 70, TF - 100, 140, 100), 20.0, Maps.CRATE.darkened(0.15), 45, 20.0)
	box.mat_kind = "crate"
	box.flammable = true
	box.anchored = true
	for cx in box.cols:
		box.anchors.append(Vector2i(cx, box.rows - 1))
	world.add_child(box)
	for c in [Vector2(80, TF - 31), Vector2(80, TF - 92)]:
		Maps.add_crate(world, Vector2(fx.call(c.x), c.y))
	for row in 2:
		var lw := 120.0 - row * 45.0
		var lx: float = minf(fx.call(w - 50.0 - lw / 2 - lw / 2), fx.call(w - 50.0 - lw / 2 + lw / 2))
		var d := Maps.make_destructible(Rect2(lx, TF - 30 * (row + 1), lw, 30), 15.0, LOG, 35, 20.0)
		d.mat_kind = "log"
		d.flammable = true
		d.anchored = true
		for cx in d.cols:
			d.anchors.append(Vector2i(cx, d.rows - 1))
		world.add_child(d)
	# помост над ящиком: с ящика — на помост, с помоста — на крышу соседнего вагона
	Colosseum.plat(world, Rect2(x0 + w / 2 - 90, TF - 170, 180, 14))

# Паровоз: котёл с трубой спереди, будка сзади; колёса с дышлом
static func _loco(world: Node, x0: float, w: float, front_left: bool, wheels: Array, stacks: Array, lamps: Array) -> void:
	var fx := func(d: float) -> float: return x0 + d if front_left else x0 + w - d
	var span := func(d0: float, d1: float) -> float: return minf(fx.call(d0), fx.call(d1))
	# котёл: на него можно залезть с переднего мостика
	var boiler := Maps.make_destructible(Rect2(span.call(40.0, 340.0), TF - 140, 300, 140), 20.0, LOCO, 200, 70.0)
	boiler.mat_kind = "iron"
	boiler.anchored = true
	for cx in boiler.cols:
		boiler.anchors.append(Vector2i(cx, boiler.rows - 1))
		boiler.cell_colors[Vector2i(cx, 0)] = LOCO.lightened(0.12)
	for cy in boiler.rows:                       # красные обручи
		for d in [100.0, 200.0]:
			var cx2 := int((fx.call(d) - span.call(40.0, 340.0)) / 20.0)
			if cx2 >= 0 and cx2 < boiler.cols:
				boiler.cell_colors[Vector2i(cx2, cy)] = Color(0.55, 0.14, 0.12)
	world.add_child(boiler)
	var stack := Maps.make_destructible(Rect2(span.call(70.0, 110.0), TF - 220, 40, 80), 20.0, LOCO.darkened(0.2), 160, 60.0)
	stack.mat_kind = "iron"
	stack.anchored = true
	stack.anchors.append(Vector2i(0, stack.rows - 1))
	stack.anchors.append(Vector2i(1, stack.rows - 1))
	world.add_child(stack)
	stacks.append(Vector2(fx.call(90.0), TF - 225))
	# будка машиниста
	var cab_x: float = span.call(340.0, 520.0)
	var roof := Maps.make_destructible(Rect2(span.call(330.0, 530.0), RT, 200, 20), 20.0, LOCO, 140, 50.0)
	roof.mat_kind = "iron"
	roof.anchored = true
	for cx in roof.cols:
		roof.anchors.append(Vector2i(cx, 0))
	world.add_child(roof)
	var front := Maps.make_destructible(Rect2(span.call(340.0, 360.0), RT + 20, 20, TF - 140 - RT - 20), 20.0, LOCO.lightened(0.05), 160, 50.0)
	front.mat_kind = "iron"
	front.anchored = true
	front.anchors.append(Vector2i(0, front.rows - 1))
	world.add_child(front)
	var rear := Maps.make_destructible(Rect2(span.call(500.0, 520.0), RT + 20, 20, TF - DOOR_H - RT - 20), 20.0, LOCO.lightened(0.05), 120, 40.0)
	rear.mat_kind = "iron"
	rear.anchored = true
	rear.anchors.append(Vector2i(0, 0))
	world.add_child(rear)
	_back(world, Rect2(cab_x, RT + 20, 180, TF - RT - 20), Color(0.42, 0.20, 0.16))
	if Maps.preview_mode:
		return
	var deco := Node2D.new()
	deco.z_index = 3
	world.add_child(deco)
	# метельник и прожектор спереди
	var fdir := -1.0 if front_left else 1.0
	var cow := Polygon2D.new()
	cow.position = Vector2(fx.call(0.0), 0)
	cow.polygon = PackedVector2Array([Vector2(0, TF + 20), Vector2(fdir * 40, G - 6), Vector2(0, G - 6)])
	cow.color = Color(0.55, 0.13, 0.12)
	deco.add_child(cow)
	var beam := ColorRect.new()
	beam.color = Color(0.62, 0.15, 0.13)
	beam.size = Vector2(40, 14)
	beam.position = Vector2(span.call(0.0, 40.0), TF + 2)
	deco.add_child(beam)
	var lampb := Polygon2D.new()
	lampb.polygon = Util.circle(11.0, 10)
	lampb.color = Color(1.0, 0.95, 0.7)
	lampb.position = Vector2(fx.call(26.0), TF - 110)
	deco.add_child(lampb)
	var hl := Torch.make_glow(140.0, Color(1.0, 0.95, 0.7))
	hl.position = lampb.position
	hl.z_index = 26
	hl.modulate.a = 0.35
	world.add_child(hl)
	lamps.append(hl)
	# паровой колпак на котле
	var dome := Polygon2D.new()
	var dp := PackedVector2Array()
	for k in 9:
		dp.append(Vector2(-22 * cos(PI * k / 8.0), -22 * sin(PI * k / 8.0)))
	dome.polygon = dp
	dome.color = TRIM.darkened(0.2)
	dome.position = Vector2(fx.call(220.0), TF - 140)
	dome.z_index = -1
	world.add_child(dome)
	# топка в будке
	var fire := ColorRect.new()
	fire.color = Color(1.0, 0.55, 0.15)
	fire.size = Vector2(40, 30)
	fire.position = Vector2(fx.call(380.0) - 20, TF - 50)
	fire.z_index = -4
	world.add_child(fire)
	var fg := Torch.make_glow(160.0, Color(1.0, 0.6, 0.25))
	fg.position = fire.position + Vector2(20, 15)
	fg.z_index = 26
	fg.modulate.a = 0.3
	world.add_child(fg)
	lamps.append(fg)
	# колёса: бегунок и три ведущих с дышлом
	var drive := Node2D.new()
	drive.z_index = 2
	world.add_child(drive)
	var lead := _wheel(18.0)
	lead.position = Vector2(fx.call(70.0), G - 18)
	drive.add_child(lead)
	var ws: Array = [lead]
	for d in [160.0, 245.0, 330.0]:
		var wh := _wheel(34.0)
		wh.position = Vector2(fx.call(d), G - 34)
		drive.add_child(wh)
		ws.append(wh)
	var rod := Line2D.new()
	rod.width = 6.0
	rod.default_color = Color(0.70, 0.70, 0.74)
	drive.add_child(rod)
	drive.set_meta("wheels", ws)
	drive.set_meta("rod", rod)
	drive.set_meta("rod_x", [fx.call(160.0), fx.call(330.0)])
	wheels.append(drive)

# ======================= Движение поезда =======================
# Пейзаж несётся мимо (слои с разной скоростью), колёса крутятся, из труб дым,
# под колёсами шпалы — кто упал на пути, того бьёт и подбрасывает обратно к вагону.
# На крышах — встречный ветер. speed — множитель скорости (в «Мгновенную смерть» растёт).
class TrainWorld extends Node2D:
	var wheels: Array = []
	var stacks: Array = []
	var speed := 1.0
	var _layers: Array = []          # [узел, ширина плитки, скорость]
	var _t := 0.0
	var _smoke_t := 0.0
	var _hurt := {}

	func _ready() -> void:
		add_to_group("train_world")
		var sky := Image.create(int(Train.W / 8.0), int((Train.G + 1500.0) / 8.0), false, Image.FORMAT_RGBA8)
		PixelArt._vgrad(sky, 0, sky.get_width(), 0, sky.get_height(), Color(0.32, 0.50, 0.82), Color(0.98, 0.84, 0.66), 18)
		var ss := PixelArt.make_sprite(sky, 8.0)
		ss.position = Vector2(0, -1500)
		ss.z_index = -10
		add_child(ss)
		_layer(_far_img(), Train.TF - 40.0, 35.0, -9)
		_layer(_hills_img(), Train.G - 10.0, 150.0, -8)
		_layer(_poles_img(), Train.G, 650.0, -7)
		_layer(_rail_img(), Train.H + 22.0, 1300.0, 1)

	func _layer(img: Image, bottom: float, spd: float, z: int) -> void:
		var holder := Node2D.new()
		holder.z_index = z
		add_child(holder)
		var tw := img.get_width() * 4.0
		var tex := ImageTexture.create_from_image(img)
		var n := int(ceilf(Train.W / tw)) + 2
		for k in n:
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.centered = false
			s.scale = Vector2(4, 4)
			s.position = Vector2(k * tw, bottom - img.get_height() * 4.0)
			holder.add_child(s)
		_layers.append([holder, tw, spd])

	# Дальние горы (бесшовные: из синусоид с целым числом периодов)
	func _far_img() -> Image:
		var w := 640
		var h := 120
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var hs := PackedFloat32Array()
		hs.resize(w)
		for x in w:
			var t := TAU * x / w
			hs[x] = h - 30.0 - 30.0 * (0.5 + 0.5 * sin(t * 2.0 + 0.7)) - 22.0 * (0.5 + 0.5 * sin(t * 5.0 + 2.1)) \
					- 10.0 * (0.5 + 0.5 * sin(t * 11.0)) - 4.0 * sin(t * 37.0)
		PixelArt._mountains(img, hs, h, Color(0.60, 0.60, 0.76), Color(0.47, 0.48, 0.65), h - 82.0, rng)
		return img

	# Холмы с лесом
	func _hills_img() -> Image:
		var w := 640
		var h := 70
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		var hs := PackedFloat32Array()
		hs.resize(w)
		for x in w:
			var t := TAU * x / w
			hs[x] = h - 14.0 - 12.0 * (0.5 + 0.5 * sin(t * 3.0 + 1.3)) - 6.0 * (0.5 + 0.5 * sin(t * 7.0))
		PixelArt._mountains(img, hs, h, Color(0.40, 0.62, 0.42), Color(0.33, 0.53, 0.37), -1.0, rng)
		var x := 0
		while x < w:
			var th := rng.randi_range(8, 16)
			var c := Color(0.15, 0.37, 0.24) if rng.randf() < 0.5 else Color(0.19, 0.43, 0.28)
			for off in [0, w, -w]:
				PixelArt._pine(img, x + off, int(hs[x]) + 4, th, c)
			x += rng.randi_range(4, 12)
		return img

	# Телеграфные столбы и кусты у самых путей
	func _poles_img() -> Image:
		var w := 400
		var h := 70
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for px in [60, 260]:
			img.fill_rect(Rect2i(px, 6, 3, h - 6), Color(0.33, 0.24, 0.16))
			img.fill_rect(Rect2i(px - 10, 10, 23, 2), Color(0.33, 0.24, 0.16))
			for ix in [px - 9, px + 10]:
				img.set_pixel(ix, 9, Color(0.85, 0.85, 0.9))
		for x in w:                       # провода провисают между столбами
			var k := fposmod(float(x - 60), 200.0) / 200.0
			var y := 10 + int(6.0 * sin(k * PI))
			img.set_pixel(x, y, Color(0.12, 0.12, 0.14, 0.8))
		for i in 18:
			var bx := rng.randi_range(0, w - 1)
			for off in [0, w, -w]:
				PixelArt._bush(img, bx + off, h - 2, rng.randi_range(3, 6), Color(0.27, 0.48, 0.24))
		return img

	# Шпалы, рельс и щебёнка насыпи (закрывают пол карты)
	func _rail_img() -> Image:
		var img := Image.create(64, 19, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.42, 0.38, 0.34))
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 260:
			var c := Color(0.34, 0.31, 0.28) if rng.randf() < 0.5 else Color(0.50, 0.46, 0.42)
			img.set_pixel(rng.randi_range(0, 63), rng.randi_range(4, 18), c)
		for sx in [4, 36]:
			img.fill_rect(Rect2i(sx, 2, 16, 4), Color(0.36, 0.25, 0.16))
			img.fill_rect(Rect2i(sx, 5, 16, 1), Color(0.26, 0.18, 0.11))
		img.fill_rect(Rect2i(0, 0, 64, 2), Color(0.66, 0.66, 0.70))
		img.fill_rect(Rect2i(0, 2, 64, 1), Color(0.40, 0.40, 0.44))
		return img

	func _physics_process(delta: float) -> void:
		_t += delta
		for l in _layers:
			var holder: Node2D = l[0]
			holder.position.x = -fposmod(_t * float(l[2]) * speed, float(l[1]))
		# колёса крутятся, дышло ходит по кругу
		var turn := _t * 9.0 * speed
		for wn in wheels:
			if not is_instance_valid(wn):
				continue
			for wh in wn.get_meta("wheels", []):
				wh.rotation = turn * 34.0 / float(wh.get_meta("r", 34.0))
			if wn.has_meta("rod"):
				var xs: Array = wn.get_meta("rod_x")
				var off := Vector2.from_angle(turn) * 16.0
				var rod: Line2D = wn.get_meta("rod")
				rod.points = PackedVector2Array([Vector2(xs[0], Train.G - 34) + off, Vector2(xs[1], Train.G - 34) + off])
		# дым из труб
		_smoke_t -= delta
		if _smoke_t <= 0.0:
			_smoke_t = 0.12 / speed
			for s in stacks:
				_puff(s)
		var world := get_parent()
		for n in world.get_children():
			if not (n is Player) or not n.is_alive():
				continue
			var p: Player = n
			var feet := p.global_position.y + p.body_size.y / 2
			# встречный ветер на крышах
			if feet < Train.RT + 4.0:
				p.push_wind(-(90.0 + 170.0 * (speed - 1.0)))
			# шпалы: бьют и подбрасывают к ближайшему вагону
			_hurt[p] = maxf(0.0, _hurt.get(p, 0.0) - delta)
			if feet > Train.G - 6.0 and _hurt[p] <= 0.0:
				_hurt[p] = 0.45
				p.take_damage(10)
				var to_x := _nearest_floor_x(p.global_position.x)
				p.velocity = Vector2(clampf((to_x - p.global_position.x) * 3.0, -420.0, 420.0), -780.0)
				if p._para != 0:
					p._land()
				Fx.sparks(world, Vector2(p.global_position.x, Train.G - 4), Color(1.0, 0.75, 0.3), 10, 260.0, 4.0, true)

	# Середина ближайшего пола вагона по x
	func _nearest_floor_x(x: float) -> float:
		var best := x
		var bd := INF
		var cx := Train.START
		for c in Train.CARS:
			var w: float = c[0]
			var mid := clampf(x, cx + 30.0, cx + w - 30.0)
			if absf(mid - x) < bd:
				bd = absf(mid - x)
				best = mid
			cx += w + Train.GAP
		return best

	func _puff(at: Vector2) -> void:
		var p := Polygon2D.new()
		p.polygon = Util.circle(randf_range(12.0, 20.0), 10)
		var g := randf_range(0.55, 0.75)
		p.color = Color(g, g, g, 0.7)
		p.position = at + Vector2(randf_range(-6, 6), 0)
		p.z_index = 4
		get_parent().add_child(p)
		var t := p.create_tween()
		t.set_parallel(true)
		t.tween_property(p, "position", p.position + Vector2(-260.0 * speed - randf_range(0, 120), -randf_range(80, 160)), 1.6)
		t.tween_property(p, "scale", Vector2(2.6, 2.6), 1.6)
		t.tween_property(p, "modulate:a", 0.0, 1.6)
		t.chain().tween_callback(p.queue_free)

# ======================= «Тоннели» — Мгновенная смерть =======================
# Гудок и мигающие фонари — через пару секунд свод тоннеля проносится над поездом
# справа налево: кто выше крыш, того сносит. Внутри темно, только лампы горят;
# пока поезд в тоннеле, над крышами не высунуться. Тоннели всё чаще и длиннее.
class Tunnels extends Node2D:
	var events: DuelEvents
	var lamps: Array = []
	var tunnel_on := false            # сейчас над поездом свод
	var _phase := "wait"
	var _t := 1.5
	var _age := 0.0
	var _count := 0
	var _edge := 0.0                  # где свод начинается (въезд) или кончается (выезд)
	var _band: Polygon2D
	var _portal: Node2D
	var _dark: ColorRect
	var _warn: Array = []
	var _hit := {}
	var _tick := 0.0
	var _lights: Array = []

	func _ready() -> void:
		z_index = 24
		_band = Polygon2D.new()
		Tex.apply(_band, "rock", Color(0.20, 0.18, 0.18))
		_band.visible = false
		add_child(_band)
		_dark = ColorRect.new()
		_dark.color = Color(0.0, 0.0, 0.02, 0.0)
		_dark.position = Vector2(-400, Train.CLEAR_Y)
		_dark.size = Vector2(Train.W + 800, Train.H - Train.CLEAR_Y + 200)
		_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_dark)
		_portal = Node2D.new()
		_portal.visible = false
		add_child(_portal)
		var face := Polygon2D.new()
		face.polygon = PackedVector2Array([Vector2(-90, -3200), Vector2(90, -3200), Vector2(90, Train.CLEAR_Y), Vector2(-90, Train.CLEAR_Y)])
		Tex.apply(face, "stone", Color(0.50, 0.47, 0.44))
		_portal.add_child(face)
		var rim := Line2D.new()
		rim.points = PackedVector2Array([Vector2(-90, Train.CLEAR_Y - 6), Vector2(90, Train.CLEAR_Y - 6)])
		rim.width = 14.0
		rim.default_color = Color(0.35, 0.32, 0.30)
		_portal.add_child(rim)
		# мигающие фонари вдоль крыш — сигнал «тоннель!»
		for k in 9:
			var l := Polygon2D.new()
			l.polygon = Util.circle(9.0, 10)
			l.color = Color(1.0, 0.25, 0.15)
			l.position = Vector2(Train.START + 150.0 + k * (Train.W - 2.0 * Train.START - 300.0) / 8.0, Train.RT - 18.0)
			l.visible = false
			add_child(l)
			_warn.append(l)
		for k in 12:                                 # лампы на своде — видно, что мчимся
			var lt := Polygon2D.new()
			lt.polygon = PackedVector2Array([Vector2(-14, -4), Vector2(14, -4), Vector2(14, 4), Vector2(-14, 4)])
			lt.color = Color(1.0, 0.85, 0.45)
			lt.visible = false
			add_child(lt)
			_lights.append(lt)

	func _tw() -> TrainWorld:
		for n in get_tree().get_nodes_in_group("train_world"):
			if is_instance_valid(n) and get_parent().is_ancestor_of(n):
				return n
		return null

	func _physics_process(delta: float) -> void:
		if events == null or not is_instance_valid(events) or not events.active or not events.doom:
			return
		_age += delta
		if _age >= 5.0 and _age - delta < 5.0:
			_ignite_car()
		var tw := _tw()
		if tw:
			tw.speed = minf(2.2, 1.0 + _age * 0.04)          # поезд разгоняется
		_t -= delta
		match _phase:
			"wait":
				if _t <= 0.0:
					_phase = "warn"
					_t = 2.2
					_count += 1
					var w := events.world
					if _count == 1:
						events.hud.show_banner("Тоннель! Прячьтесь в вагоны!", Color(1.0, 0.6, 0.3))
						var bt := create_tween()
						bt.tween_interval(1.6)
						bt.tween_callback(events.hud.hide_banner)
					events.float_text("ТУ-ТУУУ!", Color(1.0, 0.95, 0.8), Vector2(Train.W - Train.START - 260.0, Train.RT - 120.0))
					events.float_text("ТУ-ТУУУ!", Color(1.0, 0.95, 0.8), Vector2(Train.START + 260.0, Train.RT - 120.0))
					Fx.shake(w, 4.0)
			"warn":
				var on := int(_t * 6.0) % 2 == 0
				for l in _warn:
					l.visible = on
				if _t <= 0.0:
					for l in _warn:
						l.visible = false
					_phase = "enter"
					_edge = Train.W + 200.0
					_hit.clear()
					_portal.visible = true
					_band.visible = true
					tunnel_on = true
			"enter":
				_edge -= 6200.0 * delta
				_portal.position.x = _edge
				_set_band(_edge, Train.W + 400.0)
				_dark.color.a = 0.55 * clampf((Train.W - _edge) / Train.W, 0.0, 1.0)
				_sweep(_edge, Train.W + 400.0, true)
				if _edge <= -300.0:
					_portal.visible = false
					_phase = "inside"
					_t = minf(5.0, 2.6 + _age * 0.04)
			"inside":
				_set_band(-400.0, Train.W + 400.0)
				_dark.color.a = 0.55
				_sweep(-400.0, Train.W + 400.0, false)
				if _t <= 0.0:
					_phase = "exit"
					_edge = Train.W + 200.0
			"exit":
				if _edge >= Train.W + 199.0:
					_ignite_car()                         # искры в тоннеле — пожар в вагоне
				_edge -= 6200.0 * delta
				_set_band(-400.0, _edge)
				_dark.color.a = 0.55 * clampf(_edge / Train.W, 0.0, 1.0)
				_sweep(-400.0, _edge, false)
				if _edge <= -300.0:
					_band.visible = false
					_dark.color.a = 0.0
					tunnel_on = false
					_phase = "wait"
					_t = maxf(3.0, 7.5 - _age * 0.06)
		var dark := _dark.color.a
		for l in lamps:
			if is_instance_valid(l):
				l.modulate.a = lerpf(0.18, 0.95, dark / 0.55)
		# лампы на своде проносятся мимо
		for k in _lights.size():
			var lt: Polygon2D = _lights[k]
			var lx := fposmod(float(k) * 520.0 - _age * 2600.0, Train.W + 800.0) - 400.0
			lt.position = Vector2(lx, Train.CLEAR_Y - 22.0)
			lt.visible = _band.visible and _band.polygon.size() == 4 and lx > _band.polygon[0].x and lx < _band.polygon[1].x

	# Пожар в вагоне: огонь по всему полу (чаще там, где кто-то прячется)
	func _ignite_car() -> void:
		var spans: Array = []
		var x := Train.START
		for c in Train.CARS:
			var w: float = c[0]
			if c[1] in ["pass", "dining"]:
				spans.append([x, w])
			x += w + Train.GAP
		var pick: Array = spans.pick_random()
		var al: Array = events.players.filter(func(q): return is_instance_valid(q) and q.is_alive())
		if not al.is_empty() and randf() < 0.75:
			var q: Player = al.pick_random()
			for sp in spans:
				if q.global_position.x > sp[0] and q.global_position.x < sp[0] + sp[1] and q.global_position.y > Train.RT:
					pick = sp
		var world := events.world
		events.float_text("Пожар в вагоне!", Color(1.0, 0.55, 0.25), Vector2(pick[0] + pick[1] / 2.0, Train.TF - 150.0))
		for wave in 2:
			var fx: float = pick[0] + 50.0
			while fx < pick[0] + pick[1] - 40.0:
				var fz := FireZone.new()
				fz.team = 2
				fz.position = Vector2(fx + randf_range(-15, 15), Train.TF - 4.0)
				if wave == 0:
					world.add_child(fz)
				else:
					var t := create_tween()
					t.tween_interval(3.6)
					t.tween_callback(func():
						if is_instance_valid(world) and events.doom:
							world.add_child(fz)
						else:
							fz.free())
				fx += 110.0

	func _set_band(x0: float, x1: float) -> void:
		_band.polygon = PackedVector2Array([Vector2(x0, -3200), Vector2(x1, -3200), Vector2(x1, Train.CLEAR_Y),
				Vector2(x0, Train.CLEAR_Y)])

	# Кто выше крыш под сводом — того сносит (въезд бьёт сильно, дальше — понемногу)
	func _sweep(x0: float, x1: float, portal: bool) -> void:
		_tick -= get_physics_process_delta_time()
		var tick := _tick <= 0.0
		if tick:
			_tick = 0.2
		for p in events.players:
			if not is_instance_valid(p) or not p.is_alive():
				continue
			var top: float = p.global_position.y - p.body_size.y / 2
			var x: float = p.global_position.x
			if top >= Train.CLEAR_Y or x < x0 or x > x1:
				continue
			if portal and not _hit.has(p):
				_hit[p] = true
				p.take_damage(30)
				p.stun(0.5)
				p.velocity = Vector2(-650.0, 250.0)
				Util.flash(events.world, p.global_position, 60.0, Color(1.0, 0.8, 0.5, 0.9))
				Fx.sparks(events.world, p.global_position, Color(0.6, 0.55, 0.5), 12, 300.0, 5.0, true)
				Fx.shake(events.world, 8.0)
			elif tick:
				p.take_damage(8)
				p.velocity.y = maxf(p.velocity.y, 350.0)
				Fx.sparks(events.world, Vector2(x, Train.CLEAR_Y), Color(0.6, 0.55, 0.5), 4, 160.0, 4.0, true)

	# Возрождение, пока поезд в тоннеле (или вот-вот въедет): не на крыше и не с неба
	func safe_spawn(r: Dictionary, p: Player) -> Dictionary:
		if _phase == "wait" and _t > 2.0:
			return r
		var pos: Vector2 = r["pos"]
		if not r["parachute"] and pos.y - p.body_size.y / 2 > Train.CLEAR_Y + 4.0:
			return r
		var space: PhysicsDirectSpaceState2D = events.world.get_world_2d().direct_space_state
		var cars: Array = [[Train.START + 520.0 + Train.GAP, 640.0]] if p.team == 0 else \
				[[Train.W - Train.START - 520.0 - Train.GAP - 640.0, 640.0]]
		for attempt in 30:
			var c: Array = cars[0]
			var x := randf_range(c[0] + 50.0, c[0] + c[1] - 50.0)
			var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, Train.CLEAR_Y + 30.0),
					Vector2(x, Train.TF + 4.0), Layer.WORLD))
			if hit.is_empty():
				continue
			var s := Vector2(x, hit["position"].y - Player.SIZE.y / 2.0 - 2.0)
			if Spawner._is_free(space, s):
				p.last_spawn = s
				return {"pos": s, "parachute": false}
		return {"pos": events.info["p1"] if p.team == 0 else events.info["p2"], "parachute": false}
