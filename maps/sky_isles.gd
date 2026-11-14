class_name SkyIsles
# ---------- Летающие острова (волны 81–85) ----------
# Бой идёт на трёх островах высоко в небе. Между ними — пропасти, но из них бьют
# «Восходящие потоки»: кто сорвался вниз, того ветер подбрасывает обратно наверх
# (и так можно запрыгнуть на самые высокие площадки). Над пропастями медленно
# плавают каменные плиты. По краям — башни-ворота: из их разломов выходит свита.
# На фоне — небесный город на островах, водопады в облака и разрыв в небе.
#   «Мгновенная смерть» в Дуэли: края островов рушатся, потоки гаснут (см. RiftDoom).

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP

const ROCK := Color(0.50, 0.44, 0.40)
const GRASS := Color(0.40, 0.64, 0.30)
const TOWER := Color(0.62, 0.62, 0.68)
const SEG := 100.0                        # ширина куска острова (рушатся по одному)

# Острова: [левый край, правый край]; между ними — пропасти
const ISLES := [[0.0, 780.0], [980.0, 1620.0], [1820.0, W]]
const GAPS := [[780.0, 980.0], [1620.0, 1820.0]]

static func build(world: Node) -> Dictionary:
	if not Maps.preview_mode:
		var bg := PixelArt.make_sprite(RiftArt.sky_backdrop(W, FLOOR_Y, 360.0), PixelArt.SCALE)
		bg.z_index = -10
		world.add_child(bg)
	var segs: Array = []
	for isle in ISLES:
		var x := float(isle[0])
		while x < float(isle[1]) - 1.0:
			var w := minf(SEG, float(isle[1]) - x)
			var body := StaticBody2D.new()
			body.collision_layer = Layer.WORLD | Layer.FRAME
			body.position = Vector2(x + w / 2, FLOOR_Y + (H + 40 - FLOOR_Y) / 2)
			var col := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			rs.size = Vector2(w, H + 40 - FLOOR_Y)
			col.shape = rs
			body.add_child(col)
			body.add_child(Maps.block_visual(rs.size, ROCK))
			var top := Maps.block_visual(Vector2(w, 10), GRASS)
			top.position = Vector2(-w / 2, -rs.size.y / 2)
			body.add_child(top)
			body.set_meta("color", ROCK)
			world.add_child(body)
			segs.append({"node": body, "x0": x, "x1": x + w})
			x += w
	# башни по краям — стены арены с воротами
	for side in [0, 1]:
		var x0: float = 0.0 if side == 0 else W - WALL
		Maps.add_block(world, Rect2(x0, -800, WALL, FLOOR_Y + 800), TOWER)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	if not Maps.preview_mode:
		for g in gates:
			_rift_gate(world, g)
		for gap in GAPS:
			_cliff_edges(world, float(gap[0]), float(gap[1]))
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, FLOOR_Y), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, FLOOR_Y), "heal"))
	var stone := Color(0.66, 0.64, 0.66)
	for side in [1.0, -1.0]:
		var x0: float = 440.0 if side > 0 else W - 440.0
		FarStages._plat(world, Rect2(x0 - 130, FLOOR_Y - STEP, 260, 18), stone)
		FarStages._plat(world, Rect2(x0 - 100 + side * 110, FLOOR_Y - STEP * 2, 200, 18), stone)
		sp.append(Colosseum._ledge(world, x0 + side * 20, STEP * 3, 150.0))
	FarStages._plat(world, Rect2(W / 2 - 70, FLOOR_Y - STEP, 140, 18), stone)
	FarStages._plat(world, Rect2(W / 2 - 130, FLOOR_Y - STEP * 2, 260, 18), stone)
	FarStages._plat(world, Rect2(W / 2 - 300, FLOOR_Y - STEP * 3, 170, 18), stone)
	FarStages._plat(world, Rect2(W / 2 + 130, FLOOR_Y - STEP * 3, 170, 18), stone)
	sp.append(Colosseum._ledge(world, W / 2, STEP * 4 + 10, 160.0))
	# руины на островах — разрушаемые укрытия
	for x in [640.0, W - 640.0]:
		var d := Maps.make_destructible(Rect2(x - 40, FLOOR_Y - 80, 80, 80), 20.0, stone, 60, 40.0)
		d.anchored = true
		for cx in d.cols:
			d.anchors.append(Vector2i(cx, d.rows - 1))
		d.cells.erase(Vector2i(d.cols - 1, 0))
		world.add_child(d)
	for x in [1060.0, W - 1060.0]:
		var d2 := Maps.make_destructible(Rect2(x - 20, FLOOR_Y - 100, 40, 100), 20.0, stone, 60, 40.0)
		d2.anchored = true
		for cx in d2.cols:
			d2.anchors.append(Vector2i(cx, d2.rows - 1))
		world.add_child(d2)
	var drafts: Array = []
	var drifts: Array = []
	for gap in GAPS:
		var u := Updraft.new()
		u.x0 = float(gap[0])
		u.x1 = float(gap[1])
		world.add_child(u)
		drafts.append(u)
		var dp := DriftStone.new()
		dp.base = Vector2((float(gap[0]) + float(gap[1])) / 2.0, FLOOR_Y - 250.0)
		dp.phase = 0.0 if gap[0] < W / 2 else PI
		world.add_child(dp)
		drifts.append(dp)
	if not Maps.preview_mode:
		for x in [300.0, 1180.0, 1420.0, W - 300.0]:
			_crystal(world, Vector2(x, FLOOR_Y))
		world.add_child(Wisps.new())                     # клочья облаков проплывают мимо
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": null, "floor": FLOOR_Y, "spawners": sp, "totems": [],
			"isle_segs": segs, "updrafts": drafts, "drifts": drifts}

# Стена-башня с воротами: внутри арки светится разлом — из него выходит свита
static func _rift_gate(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-96, 0), Vector2(-96, -230), Vector2(-70, -250), Vector2(-70, -300), Vector2(-40, -300),
			Vector2(-40, -270), Vector2(40, -270), Vector2(40, -300), Vector2(70, -300), Vector2(70, -250), Vector2(96, -230), Vector2(96, 0)])
	Tex.apply(frame, "stone", TOWER.darkened(0.08))
	g.add_child(frame)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-58, 0), Vector2(-58, -150), Vector2(-30, -190), Vector2(30, -190), Vector2(58, -150), Vector2(58, 0)])
	hole.color = Color(0.07, 0.03, 0.10)
	g.add_child(hole)
	var tear := Polygon2D.new()                  # разлом внутри арки
	tear.polygon = PackedVector2Array([Vector2(0, -175), Vector2(10, -120), Vector2(4, -80), Vector2(14, -30), Vector2(0, -4),
			Vector2(-12, -40), Vector2(-5, -90), Vector2(-12, -130)])
	tear.color = Color(RiftArt.RIFT, 0.85)
	g.add_child(tear)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(0, -160), Vector2(4, -110), Vector2(0, -60), Vector2(5, -24), Vector2(-4, -70), Vector2(-2, -120)])
	core.color = RiftArt.RIFT_CORE
	g.add_child(core)
	var tw := tear.create_tween().set_loops()
	tw.tween_property(tear, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(tear, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	for s in [-1.0, 1.0]:                        # голубые знамёна небесного города (порваны)
		var ban := Polygon2D.new()
		ban.polygon = PackedVector2Array([Vector2(s * 70, -230), Vector2(s * 88, -230), Vector2(s * 88, -150), Vector2(s * 79, -162), Vector2(s * 70, -146)])
		ban.color = Color(0.28, 0.42, 0.72)
		g.add_child(ban)
	world.add_child(g)

# Обрывы у пропасти: рваный край скалы, свисающие корни, водопад в облака
static func _cliff_edges(world: Node, gx0: float, gx1: float) -> void:
	for side in [0, 1]:
		var x: float = gx0 if side == 0 else gx1
		var dir := 1.0 if side == 0 else -1.0             # куда смотрит обрыв (в пропасть)
		var cliff := Polygon2D.new()
		var pts := PackedVector2Array([Vector2(x, FLOOR_Y + 4)])
		var y := FLOOR_Y + 4
		while y < H + 60:
			y += randf_range(14, 30)
			pts.append(Vector2(x - dir * randf_range(0, 22), y))
		pts.append(Vector2(x - dir * 60, H + 80))
		pts.append(Vector2(x - dir * 60, FLOOR_Y + 4))
		cliff.polygon = pts
		Tex.apply(cliff, "rock", ROCK.darkened(0.12))
		cliff.z_index = 1
		world.add_child(cliff)
		for k in 4:
			var root := Line2D.new()
			var rx := x - dir * randf_range(4, 40)
			root.points = PackedVector2Array([Vector2(rx, FLOOR_Y + 8), Vector2(rx + dir * 6, FLOOR_Y + 30), Vector2(rx + dir * 3, FLOOR_Y + randf_range(50, 80))])
			root.width = 2.0
			root.default_color = Color(0.34, 0.26, 0.16)
			root.z_index = 1
			world.add_child(root)
		var grass := Polygon2D.new()                    # трава свешивается за край
		grass.polygon = PackedVector2Array([Vector2(x - dir * 30, FLOOR_Y), Vector2(x + dir * 6, FLOOR_Y), Vector2(x + dir * 4, FLOOR_Y + 9),
				Vector2(x - dir * 2, FLOOR_Y + 6), Vector2(x - dir * 8, FLOOR_Y + 12), Vector2(x - dir * 30, FLOOR_Y + 8)])
		grass.color = GRASS.darkened(0.08)
		grass.z_index = 2
		world.add_child(grass)
	var fall := Waterfall.new()
	fall.position = Vector2(gx0 + 10.0, FLOOR_Y + 2)
	world.add_child(fall)

static func _crystal(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -5
	for k in 3:
		var sh := Polygon2D.new()
		var hh := randf_range(34, 64) * (1.0 - k * 0.2)
		var x := (k - 1) * 12.0
		sh.polygon = PackedVector2Array([Vector2(x - 7, 0), Vector2(x - 4, -hh * 0.8), Vector2(x, -hh), Vector2(x + 4, -hh * 0.8), Vector2(x + 7, 0)])
		sh.color = Color(0.55, 0.25, 0.80).lightened(k * 0.12)
		sh.rotation = (k - 1) * 0.22
		g.add_child(sh)
	var gl := Polygon2D.new()
	gl.polygon = Util.circle(40.0, 16)
	gl.color = Color(RiftArt.RIFT, 0.18)
	gl.position = Vector2(0, -26)
	g.add_child(gl)
	var t := gl.create_tween().set_loops()
	t.tween_property(gl, "modulate:a", 0.4, 1.2)
	t.tween_property(gl, "modulate:a", 1.0, 1.2)
	world.add_child(g)

# ---------- Восходящий поток в пропасти ----------
# Кто опустился ниже края острова — того подбрасывает вверх (≈430 пикселей).
# deadly = true («Мгновенная смерть»): поток гаснет, пропасть убивает.
class Updraft extends Node2D:
	var x0 := 0.0
	var x1 := 0.0
	var lift := 1250.0
	var deadly := false
	var _streaks: Array = []
	var _cd := {}

	func _ready() -> void:
		z_index = 2
		for i in 14:
			var l := Line2D.new()
			l.width = 2.0
			l.default_color = Color(1, 1, 1, 0.45)
			var h := randf_range(30, 70)
			l.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -h)])
			l.position = Vector2(randf_range(x0 + 14, x1 - 14), randf_range(FLOOR_Y - 360.0, H + 60.0))
			add_child(l)
			_streaks.append(l)

	func _physics_process(delta: float) -> void:
		for l in _streaks:
			l.position.y -= delta * (520.0 if not deadly else -260.0)
			if l.position.y < FLOOR_Y - 380.0:
				l.position = Vector2(randf_range(x0 + 14, x1 - 14), H + 60.0)
			elif l.position.y > H + 80.0:
				l.position = Vector2(randf_range(x0 + 14, x1 - 14), FLOOR_Y - 300.0)
			var a := 0.45 if not deadly else 0.2
			l.default_color = Color(1, 1, 1, a) if not deadly else Color(0.35, 0.15, 0.45, a)
		for k in _cd.keys():
			_cd[k] -= delta
			if _cd[k] <= 0.0:
				_cd.erase(k)
		for n in get_parent().get_children():
			if not (n is Player) or not n.is_alive() or n.flying:
				continue
			var p: Player = n
			var x := p.global_position.x
			if x < x0 or x > x1:
				continue
			if deadly:
				if p.global_position.y > FLOOR_Y + 160.0:
					p.take_damage(99999)              # сорвался в пропасть
				continue
			if p.global_position.y > FLOOR_Y - 30.0 and not _cd.has(p.get_instance_id()):
				_cd[p.get_instance_id()] = 0.35
				p.velocity.y = minf(p.velocity.y, -lift)
				Fx.sparks(get_parent(), p.global_position + Vector2(0, p.body_size.y * 0.4), Color(0.92, 0.96, 1.0, 0.9), 8, 220.0, 3.0, true)
				Fx.ring(get_parent(), Vector2(x, FLOOR_Y + 20.0), 60.0, Color(1, 1, 1, 0.6), 0.35, 4.0, 0.35)

# ---------- Плавучая плита над пропастью ----------
class DriftStone extends AnimatableBody2D:
	var base := Vector2.ZERO
	var phase := 0.0
	var amp := 70.0
	var period := 6.0
	var _t := 0.0

	func _ready() -> void:
		collision_layer = Layer.WORLD | Layer.FRAME
		sync_to_physics = true
		position = base
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(150, 18)
		col.shape = rs
		col.one_way_collision = true
		add_child(col)
		add_child(Tex.slab(rs.size, "stone", Color(0.62, 0.60, 0.64), int(base.x)))
		var under := Polygon2D.new()                  # каменное «днище» плиты
		under.polygon = PackedVector2Array([Vector2(-72, 8), Vector2(72, 8), Vector2(40, 30), Vector2(10, 44), Vector2(-30, 34)])
		Tex.apply(under, "rock", SkyIsles.ROCK)
		add_child(under)
		var rune := Polygon2D.new()                   # светящаяся руна держит плиту в воздухе
		rune.polygon = Util.circle(7.0, 8)
		rune.color = Color(0.6, 0.85, 1.0, 0.9)
		rune.position = Vector2(4, 24)
		add_child(rune)

	func _physics_process(delta: float) -> void:
		_t += delta
		position = base + Vector2(sin(_t * 0.7 + phase) * 22.0, sin(_t * TAU / period + phase) * amp)

# ---------- Водопад с края острова в облака ----------
class Waterfall extends Node2D:
	var _drops: Array = []

	func _ready() -> void:
		z_index = 0
		var sheet := Polygon2D.new()
		sheet.polygon = PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(22, 140), Vector2(-4, 140)])
		sheet.color = Color(0.72, 0.86, 1.0, 0.55)
		add_child(sheet)
		for i in 10:
			var d := Line2D.new()
			d.width = 2.0
			d.default_color = Color(1, 1, 1, 0.7)
			d.points = PackedVector2Array([Vector2.ZERO, Vector2(0, 14)])
			d.position = Vector2(randf_range(0, 16), randf_range(0, 140))
			add_child(d)
			_drops.append(d)

	func _process(delta: float) -> void:
		for d in _drops:
			d.position.y += delta * 380.0
			if d.position.y > 140.0:
				d.position = Vector2(randf_range(0, 16), 0)

# ---------- Клочья облаков: медленно плывут перед островами ----------
class Wisps extends Node2D:
	var _clouds: Array = []

	func _ready() -> void:
		z_index = -6
		for i in 7:
			var c := Polygon2D.new()
			var pts := PackedVector2Array()
			var w := randf_range(90, 170)
			for k in 12:
				var a := TAU * k / 12.0
				pts.append(Vector2(cos(a) * w * randf_range(0.8, 1.0), sin(a) * w * 0.22 * randf_range(0.7, 1.0)))
			c.polygon = pts
			c.color = Color(1, 1, 1, randf_range(0.18, 0.32))
			c.position = Vector2(randf_range(0, SkyIsles.W), randf_range(SkyIsles.FLOOR_Y - 620.0, SkyIsles.FLOOR_Y + 40.0))
			add_child(c)
			_clouds.append([c, randf_range(10.0, 26.0)])

	func _process(delta: float) -> void:
		for e in _clouds:
			var c: Polygon2D = e[0]
			c.position.x += float(e[1]) * delta
			if c.position.x > SkyIsles.W + 200.0:
				c.position.x = -200.0
