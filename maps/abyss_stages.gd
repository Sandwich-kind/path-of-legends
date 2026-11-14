class_name AbyssStages
# ---------- Арены последних земель (волны 91–100) ----------
#   19 — Ветряные холмы (91–95): мирный край мельниц и полей, куда уже проросла
#        бездна. В воздухе висят «аномалии лёгкости» (внутри почти нет тяжести —
#        прыгаешь выше, падаешь медленно), на земле тлеют «пустотные проплешины»
#        (разгораются — жгут). Стога и изгороди — укрытия, леса мельников — площадки.
#   20 — Дворец Бездны (96–100): двор перед чёрным дворцом. Ворота дворца «пульсируют»:
#        по земле катится волна — перепрыгни. После 97-й волны дворец пробуждается и
#        меняется прямо на глазах (transform): по стенам бегут трещины, шпили кренятся,
#        площадки двора поднимаются, потом дворец отрывается от земли.
#   Зал Бездны и Изнанка — туда Странник переносит бой (волна 100), отдельно не выбираются.

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP

const DIRT := Color(0.46, 0.34, 0.24)
const GRASS := Color(0.50, 0.66, 0.30)
const BANK := Color(0.40, 0.32, 0.26)
const WOOD := Color(0.58, 0.42, 0.26)
const HAY := Color(0.88, 0.74, 0.38)
const OBSID := Color(0.11, 0.08, 0.14)
const OBSID_TOP := Color(0.24, 0.16, 0.30)
const PAL_STONE := Color(0.30, 0.24, 0.36)
const HALL_FLOOR := Color(0.16, 0.12, 0.19)
const ISLE := Color(0.22, 0.16, 0.28)
const ISLE_TOP := Color(0.46, 0.28, 0.58)

const HILLS_NAME := "Ветряные холмы"
const PALACE_NAME := "Дворец Бездны"
const HALL_NAME := "Зал Бездны"
const ABYSS_NAME := "Изнанка"

static func _bg(world: Node, img: Image) -> Sprite2D:
	if Maps.preview_mode:
		return null
	var bg := PixelArt.make_sprite(img, PixelArt.SCALE)
	bg.z_index = -10
	world.add_child(bg)
	return bg

static func _hay(world: Node, x: float, size: Vector2) -> void:
	var d := Maps.make_destructible(Rect2(x - size.x / 2, FLOOR_Y - size.y, size.x, size.y), 20.0, HAY, 30, 20.0)
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	d.flammable = true
	world.add_child(d)

static func _fence(world: Node, x: float) -> void:
	var d := Maps.make_destructible(Rect2(x - 60, FLOOR_Y - 40, 120, 40), 20.0, WOOD, 24, 20.0)
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	d.cells.erase(Vector2i(1, 0))
	d.cells.erase(Vector2i(4, 0))
	world.add_child(d)

# ======================= 19 — Ветряные холмы =======================
static func hills(world: Node, level := 0) -> Dictionary:
	var bg := _bg(world, AbyssArt.hills_backdrop(W, FLOOR_Y, level))
	FarStages._frame(world, DIRT, GRASS, BANK)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, FLOOR_Y), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, FLOOR_Y), "heal"))
	# леса мельников по бокам
	for side in [1.0, -1.0]:
		var x0: float = 470.0 if side > 0 else W - 470.0
		FarStages._plat(world, Rect2(x0 - 130, FLOOR_Y - STEP, 260, 18), WOOD)
		FarStages._plat(world, Rect2(x0 - 90 + side * 120, FLOOR_Y - STEP * 2, 200, 18), WOOD)
		sp.append(Colosseum._ledge(world, x0 + side * 30, STEP * 3, 150.0))
	# посередине — мостки к самому верху (там бафф)
	FarStages._plat(world, Rect2(W / 2 - 120, FLOOR_Y - STEP * 2, 240, 18), WOOD)
	FarStages._plat(world, Rect2(W / 2 - 310, FLOOR_Y - STEP * 3, 170, 18), WOOD)
	FarStages._plat(world, Rect2(W / 2 + 140, FLOOR_Y - STEP * 3, 170, 18), WOOD)
	FarStages._plat(world, Rect2(W / 2 - 70, FLOOR_Y - STEP, 140, 18), WOOD)
	sp.append(Colosseum._ledge(world, W / 2, STEP * 4 + 10, 160.0))
	# стога и изгороди — укрытия
	for x in [760.0, W - 760.0]:
		_hay(world, x, Vector2(80, 60))
	for x in [1080.0, W - 1080.0]:
		_fence(world, x)
	if not Maps.preview_mode:
		# аномалии лёгкости
		for b in [[W * 0.30, FLOOR_Y - 300.0], [W * 0.70, FLOOR_Y - 330.0]]:
			var lb := AbyssBits.LightBubble.new()
			lb.base = Vector2(b[0], b[1])
			world.add_child(lb)
		# пустотные проплешины
		for x in [920.0, W / 2, W - 920.0]:
			var vp := AbyssBits.VoidPatch.new()
			vp.position = Vector2(x, FLOOR_Y)
			world.add_child(vp)
		var m := AbyssBits.Motes.new()
		m.area = Rect2(200, 260, 900, FLOOR_Y - 260)
		world.add_child(m)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": null, "floor": FLOOR_Y, "spawners": sp, "totems": [], "bg": bg, "hill_level": level}

# Холмы мрачнеют: новый фон плавно проступает поверх старого
static func hills_darken(world: Node, info: Dictionary, level: int, time := 2.0) -> void:
	if Maps.preview_mode or int(info.get("hill_level", -1)) == level:
		return
	info["hill_level"] = level
	var old_bg: Sprite2D = info.get("bg")
	var nb := PixelArt.make_sprite(AbyssArt.hills_backdrop(W, FLOOR_Y, level), PixelArt.SCALE)
	nb.z_index = -10
	nb.modulate.a = 0.0
	world.add_child(nb)
	var bt := nb.create_tween()
	bt.tween_property(nb, "modulate:a", 1.0, time)
	if old_bg and is_instance_valid(old_bg):
		bt.tween_callback(old_bg.queue_free)
	info["bg"] = nb
	Fx.shake(world, 3.0 + level)

# ======================= 20 — Дворец Бездны =======================
# Площадки двора на каждом «уровне пробуждения» дворца: [центр x, y над полом, ширина]
# Площадки двора (на всех «уровнях» дворца одни и те же — все достижимы прыжком)
const PAL_LEVEL := [[470.0, STEP, 260.0], [560.0, STEP * 2, 200.0], [W - 470.0, STEP, 260.0], [W - 560.0, STEP * 2, 200.0],
		[W / 2, STEP, 140.0], [W / 2, STEP * 2, 240.0], [W / 2 - 225.0, STEP * 3, 170.0], [W / 2 + 225.0, STEP * 3, 170.0]]
const PAL_PLATS := [PAL_LEVEL, PAL_LEVEL, PAL_LEVEL]

static func palace(world: Node, level := 0) -> Dictionary:
	var bg := _bg(world, AbyssArt.palace_backdrop(W, FLOOR_Y, level))
	FarStages._frame(world, OBSID, OBSID_TOP, OBSID.darkened(0.2))
	var glow := FarStages._glow_layer(world, [Color(0.74, 0.64, 0.86), Color(0.70, 0.58, 0.86), Color(0.66, 0.52, 0.86)][level])
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	if not Maps.preview_mode:
		for g in gates:
			SkyIsles._rift_gate(world, g)
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, FLOOR_Y), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, FLOOR_Y), "heal"))
	var plats: Array = []
	for pd in PAL_PLATS[level]:
		var sl := Slab.new()
		sl.width = float(pd[2])
		sl.position = Vector2(float(pd[0]), FLOOR_Y - float(pd[1]))
		world.add_child(sl)
		plats.append(sl)
	sp.append(Colosseum._ledge(world, W / 2, STEP * 4 + 10, 160.0))
	# жаровни с пламенем бездны и обломки колонн-укрытий
	for x in [330.0, 1000.0, W - 1000.0, W - 330.0]:
		FarStages._brazier(world, glow, Vector2(x, FLOOR_Y), Color(0.75, 0.40, 1.0))
	for x in [800.0, W - 800.0]:
		var d := Maps.make_destructible(Rect2(x - 30, FLOOR_Y - 100, 60, 100), 20.0, PAL_STONE, 60, 40.0)
		d.anchored = true
		for cx in d.cols:
			d.anchors.append(Vector2i(cx, d.rows - 1))
		world.add_child(d)
	var pulse: AbyssBits.PalacePulse = null
	var patches: Array = []
	if not Maps.preview_mode:
		pulse = AbyssBits.PalacePulse.new()
		pulse.every = [Vector2(12.0, 15.0), Vector2(9.0, 12.0), Vector2(7.0, 10.0)][level]
		world.add_child(pulse)
		if level >= 2:
			patches = _palace_cracks(world)
		var m := AbyssBits.Motes.new()
		m.count = 14 + level * 12
		world.add_child(m)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow, "floor": FLOOR_Y, "spawners": sp, "totems": [],
			"bg": bg, "plats": plats, "pulse": pulse, "level": level, "patches": patches}

static func _palace_cracks(world: Node) -> Array:
	var res: Array = []
	for x in [700.0, W / 2 - 360.0, W / 2 + 360.0, W - 700.0]:
		var vp := AbyssBits.VoidPatch.new()
		vp.position = Vector2(x, FLOOR_Y)
		vp.width = 140.0
		vp.rest = Vector2(5.0, 8.0)
		world.add_child(vp)
		res.append(vp)
	return res

# Дворец пробуждается прямо на глазах: новый фон проступает поверх старого,
# площадки двора с грохотом поднимаются на новые места, свет становится лиловее.
static func transform(world: Node, info: Dictionary, level: int, time := 2.4) -> void:
	level = clampi(level, 0, 2)
	info["level"] = level
	var old_bg: Sprite2D = info.get("bg")
	if not Maps.preview_mode:
		var nb := PixelArt.make_sprite(AbyssArt.palace_backdrop(W, FLOOR_Y, level), PixelArt.SCALE)
		nb.z_index = -10
		nb.modulate.a = 0.0
		world.add_child(nb)
		var bt := nb.create_tween()
		bt.tween_property(nb, "modulate:a", 1.0, time)
		if old_bg and is_instance_valid(old_bg):
			bt.tween_callback(old_bg.queue_free)
		info["bg"] = nb
	var plats: Array = info.get("plats", [])
	for i in mini(plats.size(), PAL_PLATS[level].size()):
		var sl = plats[i]
		if not is_instance_valid(sl):
			continue
		var pd: Array = PAL_PLATS[level][i]
		var to := Vector2(float(pd[0]), FLOOR_Y - float(pd[1]))
		var pt: Tween = sl.create_tween()
		pt.tween_interval(randf_range(0.0, 0.5))
		pt.tween_property(sl, "position", to, time * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		sl.glow_cracks(true)
	for n in world.get_children():
		if n is CanvasModulate:
			n.create_tween().tween_property(n, "color", [Color(0.74, 0.64, 0.86), Color(0.70, 0.58, 0.86), Color(0.66, 0.52, 0.86)][level], time)
	var pulse = info.get("pulse")
	if pulse and is_instance_valid(pulse):
		pulse.every = [Vector2(12.0, 15.0), Vector2(9.0, 12.0), Vector2(7.0, 10.0)][level]
	if level >= 2 and (info.get("patches", []) as Array).is_empty() and not Maps.preview_mode:
		info["patches"] = _palace_cracks(world)
	# грохот: камни поднимаются с земли, трещины, тряска
	Fx.shake(world, 14.0)
	for k in 18:
		var r := Polygon2D.new()
		var s := randf_range(6, 16)
		r.polygon = PackedVector2Array([Vector2(-s, -s * 0.6), Vector2(s * 0.7, -s), Vector2(s, s * 0.5), Vector2(-s * 0.4, s)])
		r.color = OBSID_TOP if k % 2 else PAL_STONE
		r.position = Vector2(randf_range(150, W - 150), FLOOR_Y - 4)
		r.z_index = -2
		world.add_child(r)
		var rt := r.create_tween()
		rt.tween_interval(randf() * 0.8)
		rt.tween_property(r, "position:y", r.position.y - randf_range(250, 600), randf_range(1.6, 2.6)).set_trans(Tween.TRANS_SINE)
		rt.parallel().tween_property(r, "rotation", randf_range(-3, 3), 2.0)
		rt.tween_property(r, "modulate:a", 0.0, 0.6)
		rt.tween_callback(r.queue_free)
	for k in 6:
		Fx.cracks(world, Vector2(randf_range(200, W - 200), FLOOR_Y), RiftRig.GLOW, randf_range(60, 120))

# Площадка двора, которая может сдвинуться (AnimatableBody2D — герои едут вместе с ней)
class Slab extends AnimatableBody2D:
	var width := 200.0
	var _cracks: Line2D

	func _ready() -> void:
		collision_layer = Layer.WORLD | Layer.FRAME
		sync_to_physics = false
		var col := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(width, 18)
		col.shape = rs
		col.one_way_collision = true
		add_child(col)
		add_child(Tex.slab(rs.size, "stone", PAL_STONE, int(position.x)))
		var under := Polygon2D.new()
		var hw := width / 2
		under.polygon = PackedVector2Array([Vector2(-hw + 6, 8), Vector2(hw - 6, 8), Vector2(hw * 0.4, 26), Vector2(0, 36), Vector2(-hw * 0.5, 24)])
		under.color = OBSID
		add_child(under)
		_cracks = Line2D.new()
		_cracks.width = 2.0
		_cracks.default_color = Color(RiftRig.GLOW, 0.0)
		_cracks.points = PackedVector2Array([Vector2(-hw * 0.6, 10), Vector2(-hw * 0.2, 20), Vector2(hw * 0.1, 14), Vector2(hw * 0.5, 26)])
		add_child(_cracks)

	func glow_cracks(on: bool) -> void:
		create_tween().tween_property(_cracks, "default_color:a", 0.9 if on else 0.0, 0.8)

# ======================= Зал Бездны (Странник, третья фаза) =======================
static func hall(world: Node) -> Dictionary:
	_bg(world, AbyssArt.hall_backdrop(W, FLOOR_Y))
	FarStages._frame(world, HALL_FLOOR, HALL_FLOOR.lightened(0.15), HALL_FLOOR.darkened(0.2))
	var glow := FarStages._glow_layer(world, Color(0.66, 0.56, 0.80))
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, FLOOR_Y), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, FLOOR_Y), "heal"))
	# галереи по бокам и балкон под окном-розой
	for side in [1.0, -1.0]:
		var x0: float = 500.0 if side > 0 else W - 500.0
		FarStages._plat(world, Rect2(x0 - 150, FLOOR_Y - STEP, 300, 18), PAL_STONE)
		FarStages._plat(world, Rect2(x0 - 100 + side * 140, FLOOR_Y - STEP * 2, 200, 18), PAL_STONE)
	FarStages._plat(world, Rect2(W / 2 - 80, FLOOR_Y - STEP, 160, 18), PAL_STONE)
	FarStages._plat(world, Rect2(W / 2 - 200, FLOOR_Y - STEP * 2, 400, 18), PAL_STONE)
	FarStages._plat(world, Rect2(W / 2 - 320, FLOOR_Y - STEP * 3, 170, 18), PAL_STONE)
	FarStages._plat(world, Rect2(W / 2 + 150, FLOOR_Y - STEP * 3, 170, 18), PAL_STONE)
	sp.append(Colosseum._ledge(world, W / 2, STEP * 4 + 10, 180.0))
	for x in [300.0, 900.0, W - 900.0, W - 300.0]:
		FarStages._brazier(world, glow, Vector2(x, FLOOR_Y), Color(0.75, 0.40, 1.0))
	if not Maps.preview_mode:
		var m := AbyssBits.Motes.new()
		m.count = 18
		world.add_child(m)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow, "floor": FLOOR_Y, "spawners": sp, "totems": []}

# ======================= Изнанка (Странник, четвёртая и пятая фазы) =======================
const ISLES := [[120.0, 820.0], [1000.0, 1600.0], [1780.0, W - 120.0]]
const SEG := 100.0

static func abyss(world: Node) -> Dictionary:
	_bg(world, AbyssArt.abyss_backdrop(W, FLOOR_Y, 360.0))
	var segs: Array = []
	for isle in ISLES:
		var x := float(isle[0])
		while x < float(isle[1]) - 1.0:
			var w := minf(SEG, float(isle[1]) - x)
			var body := StaticBody2D.new()
			body.collision_layer = Layer.WORLD | Layer.FRAME
			var hh := 70.0 + randf_range(0.0, 30.0)
			body.position = Vector2(x + w / 2, FLOOR_Y + hh / 2)
			var col := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			rs.size = Vector2(w, hh)
			col.shape = rs
			body.add_child(col)
			body.add_child(Maps.block_visual(rs.size, ISLE))
			var top := Maps.block_visual(Vector2(w, 8), ISLE_TOP)
			top.position = Vector2(-w / 2, -hh / 2)
			body.add_child(top)
			var under := Polygon2D.new()
			under.polygon = PackedVector2Array([Vector2(-w / 2, hh / 2), Vector2(w / 2, hh / 2), Vector2(w * 0.2, hh / 2 + randf_range(20, 50)), Vector2(-w * 0.25, hh / 2 + randf_range(16, 40))])
			under.color = ISLE.darkened(0.3)
			body.add_child(under)
			body.set_meta("color", ISLE)
			body.set_meta("isle", true)
			body.set_meta("half_h", hh / 2)
			world.add_child(body)
			segs.append(body)
			x += w
	# невидимые края карты
	for x0 in [0.0, W - 20.0]:
		var wb := StaticBody2D.new()
		wb.collision_layer = Layer.WORLD | Layer.FRAME
		wb.position = Vector2(x0 + 10, FLOOR_Y - 900)
		var wc := CollisionShape2D.new()
		var wr := RectangleShape2D.new()
		wr.size = Vector2(20, 3000)
		wc.shape = wr
		wb.add_child(wc)
		world.add_child(wb)
	var glow := FarStages._glow_layer(world, Color(0.72, 0.60, 0.88))
	var gates := [Vector2(260.0, FLOOR_Y), Vector2(W - 260.0, FLOOR_Y)]
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(300.0, FLOOR_Y), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - 300.0, FLOOR_Y), "heal"))
	for side in [1.0, -1.0]:
		var x0: float = 470.0 if side > 0 else W - 470.0
		FarStages._plat(world, Rect2(x0 - 120, FLOOR_Y - STEP, 240, 18), ISLE_TOP)
	FarStages._plat(world, Rect2(W / 2 - 80, FLOOR_Y - STEP, 160, 18), ISLE_TOP)
	FarStages._plat(world, Rect2(W / 2 - 140, FLOOR_Y - STEP * 2, 280, 18), ISLE_TOP)
	sp.append(Colosseum._ledge(world, W / 2, STEP * 3, 170.0))
	# плиты над пропастями
	for gap in [[820.0, 1000.0], [1600.0, 1780.0]]:
		var dp := SkyIsles.DriftStone.new()
		dp.base = Vector2((gap[0] + gap[1]) / 2.0, FLOOR_Y - 200.0)
		dp.amp = 50.0
		world.add_child(dp)
	var fall := AbyssBits.AbyssFall.new()
	world.add_child(fall)
	if not Maps.preview_mode:
		var m := AbyssBits.Motes.new()
		m.area = Rect2(0, 100, W, FLOOR_Y + 200)
		m.count = 34
		world.add_child(m)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow, "floor": FLOOR_Y, "spawners": sp, "totems": [], "isle_segs": segs}

# Изнанка рушится: края островов обваливаются, середина центрального держится
static func start_collapse(world: Node, info: Dictionary) -> AbyssBits.Crumble:
	var segs: Array = (info.get("isle_segs", []) as Array).filter(func(s): return is_instance_valid(s))
	var scored: Array = []
	for s in segs:
		var x: float = s.global_position.x
		if absf(x - W / 2) < 200.0 or absf(x - 470.0) < 110.0 or absf(x - (W - 470.0)) < 110.0:
			continue
		scored.append([-absf(x - W / 2), s])
	scored.sort_custom(func(a, b): return a[0] < b[0])
	var c := AbyssBits.Crumble.new()
	for e in scored:
		c.order.append(e[1])
	c.keep = 0
	c.every = 2.6
	world.add_child(c)
	return c


# ======================= 21 — Сердце Бездны (101–103, только сложная Арена) =======================
const HEART_NAME := "Сердце Бездны"

static func heart(world: Node, level := 0) -> Dictionary:
	var bg := _bg(world, AbyssArt.heart_backdrop(W, FLOOR_Y, level))
	FarStages._frame(world, OBSID, OBSID_TOP, OBSID.darkened(0.2))
	var glow := FarStages._glow_layer(world, Color(0.62, 0.50, 0.80))
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, FLOOR_Y), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, FLOOR_Y), "heal"))
	# открытая площадка: ничего не мешает разворачиваться, ярусы ступенями по 120
	for pd in PAL_LEVEL:
		FarStages._plat(world, Rect2(float(pd[0]) - float(pd[2]) / 2.0, FLOOR_Y - float(pd[1]), float(pd[2]), 18), OBSID_TOP)
	sp.append(Colosseum._ledge(world, W / 2, STEP * 4 + 10, 160.0))
	for x in [330.0, W - 330.0]:
		FarStages._brazier(world, glow, Vector2(x, FLOOR_Y), Color(0.75, 0.40, 1.0))
	if not Maps.preview_mode:
		var m := AbyssBits.Motes.new()
		m.count = 30 + level * 10
		world.add_child(m)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow, "floor": FLOOR_Y, "spawners": sp, "totems": [], "bg": bg, "heart": level}
