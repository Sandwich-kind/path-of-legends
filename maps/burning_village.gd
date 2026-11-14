class_name BurningVillage
# ---------- Окраина деревни в огне (волны 86–90) ----------
# Та же окраина, что на волнах 6–10 (VillageEdge.build(world, true)), но свита
# Странника уже здесь: небо багровое, деревня за полем горит, бьёт набат.
#   • живой огонь над горящими домами фона, дым и пепел в воздухе;
#   • вдалеке бегут жители (силуэты);
#   • механика: «Горящие обломки» — с неба (из пожаров) летят пылающие балки.
#     На земле заранее загорается круг — куда упадёт; после удара земля горит.
#     Стога сена и плетни горят и сами — огонь перекидывается.

const FLOOR_Y := Colosseum.FLOOR_Y
const W := Colosseum.W

static func dress(world: Node, info: Dictionary) -> void:
	var cm := CanvasModulate.new()
	cm.color = Color(1.0, 0.80, 0.74)
	world.add_child(cm)
	var gl := CanvasLayer.new()
	gl.layer = 1
	gl.follow_viewport_enabled = true
	world.add_child(gl)
	info["glow"] = gl
	if Maps.preview_mode:
		return
	# живой огонь поверх фона — там, где на картинке горят крыши
	for f: Vector2 in RiftArt.fires:
		var bf := BackFire.new()
		bf.position = f
		bf.size = randf_range(0.8, 1.3)
		world.add_child(bf)
		var g := Torch.make_glow(220.0, Color(1.0, 0.45, 0.12, 0.55))
		g.position = f + Vector2(0, 10)
		gl.add_child(g)
	# огонь у ног: тлеющие костры по полю (свет)
	for x in [520.0, 1300.0, W - 520.0]:
		var g2 := Torch.make_glow(300.0, Color(1.0, 0.5, 0.2, 0.5))
		g2.position = Vector2(x, FLOOR_Y - 40)
		gl.add_child(g2)
	# стога уже горят — огонь сам перекинется на плетни
	for n in world.get_children():
		if n is Destructible and n.flammable and not n.background and n.color == VillageEdge.HAY:
			n.hit(n.global_position + Vector2(0, -10), Vector2.ZERO, 1, 10.0, -1, {"fire": true, "strict": true})
	var fug := Fugitives.new()
	world.add_child(fug)
	var w := Weather.new()
	w.mode = "embers"
	world.add_child(w)
	var dr := DebrisRain.new()
	world.add_child(dr)
	info["debris"] = dr

# Языки пламени над горящим домом фона (дрожат, тянутся вверх)
class BackFire extends Node2D:
	var size := 1.0
	var _tongues: Array = []
	var _t := 0.0

	func _ready() -> void:
		z_index = -9
		for k in 5:
			var p := Polygon2D.new()
			var hw := randf_range(8, 14) * size
			var hh := randf_range(26, 44) * size
			p.polygon = PackedVector2Array([Vector2(-hw, 0), Vector2(-hw * 0.4, -hh * 0.6), Vector2(0, -hh), Vector2(hw * 0.5, -hh * 0.55), Vector2(hw, 0)])
			p.color = [Color(0.95, 0.30, 0.08, 0.85), Color(1.0, 0.55, 0.12, 0.9), Color(1.0, 0.85, 0.40, 0.9)][k % 3]
			p.position = Vector2((k - 2) * 9.0 * size, 4)
			add_child(p)
			_tongues.append(p)

	func _process(delta: float) -> void:
		_t += delta
		for i in _tongues.size():
			var p: Polygon2D = _tongues[i]
			p.scale = Vector2(0.9 + 0.15 * sin(_t * 9.0 + i), 0.8 + 0.3 * absf(sin(_t * 6.0 + i * 1.7)))

# Силуэты жителей вдалеке: выбегают с одного края и бегут прочь от деревни
class Fugitives extends Node2D:
	var _t := 1.0

	func _ready() -> void:
		z_index = -9

	func _process(delta: float) -> void:
		_t -= delta
		if _t > 0.0:
			return
		_t = randf_range(2.5, 5.0)
		var man := Node2D.new()
		var c := Color(0.08, 0.04, 0.04, 0.85)
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([Vector2(-3, -18), Vector2(3, -18), Vector2(4, -6), Vector2(-4, -6)])
		body.color = c
		man.add_child(body)
		var head := Polygon2D.new()
		head.polygon = Util.circle(3.2, 8)
		head.position = Vector2(0, -21)
		head.color = c
		man.add_child(head)
		for s in [-1.0, 1.0]:
			var leg := Polygon2D.new()
			leg.polygon = PackedVector2Array([Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(1.5, 8), Vector2(-1.5, 8)])
			leg.color = c
			leg.position = Vector2(s * 2.0, -7)
			leg.name = "Leg%d" % (0 if s < 0 else 1)
			man.add_child(leg)
		var dir := 1.0 if randf() < 0.5 else -1.0
		var y := FLOOR_Y - 150.0 - randf_range(0, 30)
		man.position = Vector2(W * 0.5 + randf_range(-200, 200), y)
		man.scale = Vector2(dir, 1.0)
		add_child(man)
		var t := man.create_tween()
		t.tween_property(man, "position:x", man.position.x + dir * randf_range(900, 1300), randf_range(6.0, 9.0))
		t.parallel().tween_method(func(k: float):
			if is_instance_valid(man) and man.get_child_count() > 3:
				man.get_child(2).rotation = sin(k * 40.0) * 0.6
				man.get_child(3).rotation = -sin(k * 40.0) * 0.6
				man.position.y = y - absf(sin(k * 40.0)) * 2.0, 0.0, 1.0, 7.0)
		t.tween_callback(man.queue_free)

# Пылающие балки с неба. Целится в героев (в Дуэли — в обоих), бьёт всех.
class DebrisRain extends Node2D:
	var _t := 5.0
	var every := Vector2(5.0, 8.0)
	var power := 1.0                               # «Мгновенная смерть» в Дуэли: чаще и больше

	func _physics_process(delta: float) -> void:
		_t -= delta
		if _t > 0.0:
			return
		_t = randf_range(every.x, every.y)
		var who: Array = []
		for n in FarBits._players(get_parent()):
			if not n.is_bot and not n.is_minion:
				who.append(n)
		var x := randf_range(200.0, W - 200.0)
		if not who.is_empty() and randf() < 0.85:
			var p: Player = who.pick_random()
			x = clampf(p.global_position.x + randf_range(-180.0, 180.0), 150.0, W - 150.0)
		drop(x)

	func drop(x: float) -> void:
		var world := get_parent()
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
				Vector2(x, -200.0), Vector2(x, FLOOR_Y + 20.0), Layer.WORLD | Layer.FRAME))
		var land: float = hit["position"].y if not hit.is_empty() else FLOOR_Y
		var mark := Fx.rune_circle(world, Vector2(x, land), 80.0 * power, Color(1.0, 0.35, 0.10, 0.9), 1.4)
		mark.z_index = 3
		var b := Beam.new()
		b.goal = Vector2(x, land)
		b.position = Vector2(x + randf_range(-260, 260), -260.0)
		b.delay = 0.75
		b.power = power
		world.add_child(b)

class Beam extends Node2D:
	var goal := Vector2.ZERO
	var delay := 0.0
	var power := 1.0
	var _from := Vector2.ZERO
	var _k := 0.0
	var _vis: Node2D
	var _spin := 0.0

	func _ready() -> void:
		z_index = 6
		_from = position
		_spin = randf_range(-7.0, 7.0)
		_vis = Node2D.new()
		_vis.scale = Vector2.ONE * power
		add_child(_vis)
		var wood := Polygon2D.new()
		wood.polygon = PackedVector2Array([Vector2(-34, -7), Vector2(34, -6), Vector2(36, 6), Vector2(-33, 7)])
		wood.color = Color(0.20, 0.10, 0.06)
		_vis.add_child(wood)
		for k in 4:
			var ember := Polygon2D.new()
			ember.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(0, -12), Vector2(6, 0)])
			ember.color = Color(1.0, 0.55 + 0.1 * k, 0.15)
			ember.position = Vector2(-24 + k * 16, -5)
			_vis.add_child(ember)
		visible = delay <= 0.0

	func _physics_process(delta: float) -> void:
		if delay > 0.0:
			delay -= delta
			visible = delay <= 0.0
			return
		_k = minf(1.0, _k + delta / 0.65)
		position = _from.lerp(goal, _k * _k)
		_vis.rotation += _spin * delta
		if randf() < 0.6:
			Fx.sparks(get_parent(), global_position, Color(1.0, 0.5, 0.15), 1, 60.0, 3.0)
		if _k >= 1.0:
			var world := get_parent()
			Util.explode(world, goal, 90.0 * power, int(16 * power), 25, -1, null, true)
			Fx.sparks(world, goal + Vector2(0, -6), Color(1.0, 0.55, 0.2), 16, 300.0, 5.0, true)
			Fx.cracks(world, goal, Color(0.25, 0.10, 0.06), 70.0)
			var fz := FireZone.new()
			fz.team = -1
			fz.position = goal + Vector2(0, -6)
			world.add_child(fz)
			queue_free()
