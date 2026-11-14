class_name RiftDoom
extends Node2D
# ---------- «Мгновенная смерть» на картах земель Странника (Дуэль) ----------
#   arena_sky     — «Острова рушатся!»: восходящие потоки гаснут — пропасть теперь
#                   убивает; края островов трескаются (видно заранее) и обваливаются
#                   кусок за куском, пока не останется середина центрального острова.
#   arena_burning — «Огненный вал!»: с обоих краёв карты на середину ползёт стена огня
#                   (коснёшься — горишь, отбрасывает назад), а пылающие балки падают
#                   чаще и крупнее. Вал останавливается, оставив в центре узкий пятачок.
# Поверх этого работает общий хаос DuelEvents.

const MAPS := ["arena_sky", "arena_burning"]

var events: DuelEvents
var map_id := ""
var info := {}
var _t := 0.0
var _crumble_t := 3.0
var _order: Array = []
var _walls: Array = []

static func names() -> Dictionary:
	return {"arena_sky": "Острова рушатся!", "arena_burning": "Огненный вал!"}

static func start(de: DuelEvents) -> RiftDoom:
	if not (de.map_id in MAPS):
		return null
	var d := RiftDoom.new()
	d.events = de
	d.map_id = de.map_id
	d.info = de.info
	de.world.add_child(d)
	return d

func _ready() -> void:
	match map_id:
		"arena_sky":
			for u in info.get("updrafts", []):
				if is_instance_valid(u):
					u.deadly = true
			# порядок обвала: от пропастей — к краям карты и к середине центрального острова
			var segs: Array = info.get("isle_segs", []).duplicate()
			var keep_lo := SkyIsles.W / 2.0 - 160.0
			var keep_hi := SkyIsles.W / 2.0 + 160.0
			var scored: Array = []
			for sg in segs:
				var mid := (float(sg["x0"]) + float(sg["x1"])) / 2.0
				if mid > keep_lo and mid < keep_hi:
					continue                             # середина центрального острова держится
				var gd := INF
				for gap in SkyIsles.GAPS:
					gd = minf(gd, minf(absf(mid - float(gap[0])), absf(mid - float(gap[1]))))
				scored.append([gd, sg])
			scored.sort_custom(func(a, b): return a[0] < b[0])
			for e in scored:
				_order.append(e[1])
		"arena_burning":
			for s in [-1.0, 1.0]:
				var w := FireWall.new()
				w.side = s
				w.x = 70.0 if s < 0 else Colosseum.W - 70.0
				w.stop = Colosseum.W / 2.0 - s * 260.0
				get_parent().add_child(w)
				_walls.append(w)
			var dr = info.get("debris")
			if dr and is_instance_valid(dr):
				dr.every = Vector2(1.6, 2.8)
				dr.power = 1.35
				dr._t = 1.0

func _physics_process(delta: float) -> void:
	if not events or not is_instance_valid(events) or not events.doom:
		return
	_t += delta
	if map_id == "arena_sky":
		# кто сорвался вниз — гибнет (поток больше не поднимает)
		for p in events.players:
			if is_instance_valid(p) and p.is_alive() and p.global_position.y > SkyIsles.FLOOR_Y + 200.0:
				p.take_damage(99999)
		_crumble_t -= delta
		if _crumble_t <= 0.0 and not _order.is_empty():
			_crumble_t = maxf(1.4, 3.2 - _t * 0.03)
			_crack(_order.pop_front())
			if randf() < 0.5 and not _order.is_empty():
				_crack(_order.pop_front())                 # иногда рушится сразу пара кусков

# Кусок острова: трещины и тряска, через 1,4 с — обваливается
func _crack(sg: Dictionary) -> void:
	var body: Node2D = sg["node"]
	if not is_instance_valid(body):
		return
	var x0: float = sg["x0"]
	var x1: float = sg["x1"]
	var fy := SkyIsles.FLOOR_Y
	var world := get_parent()
	for k in 3:
		Fx.cracks(world, Vector2(randf_range(x0 + 10, x1 - 10), fy + 2), Color(0.20, 0.10, 0.08), 60.0)
	var warn := Polygon2D.new()
	warn.polygon = PackedVector2Array([Vector2(x0, fy - 3), Vector2(x1, fy - 3), Vector2(x1, fy + 6), Vector2(x0, fy + 6)])
	warn.color = Color(1.0, 0.25, 0.2, 0.0)
	warn.z_index = 6
	world.add_child(warn)
	var t := warn.create_tween().set_loops(4)
	t.tween_property(warn, "color:a", 0.85, 0.17)
	t.tween_property(warn, "color:a", 0.15, 0.17)
	var shake := body.create_tween()
	for i in 8:
		shake.tween_property(body, "position:x", body.position.x + (2.0 if i % 2 else -2.0), 0.17)
	shake.tween_callback(func():
		if is_instance_valid(warn):
			warn.queue_free()
		if not is_instance_valid(body):
			return
		_fall(world, x0, x1, fy)
		body.queue_free())

# Обломки летят вниз в облака
func _fall(world: Node, x0: float, x1: float, fy: float) -> void:
	Fx.sparks(world, Vector2((x0 + x1) / 2.0, fy), Color(0.55, 0.48, 0.42), 14, 260.0, 5.0, true)
	for k in 5:
		var r := Polygon2D.new()
		var s := randf_range(14, 30)
		r.polygon = PackedVector2Array([Vector2(-s, -s * 0.6), Vector2(s * 0.8, -s * 0.7), Vector2(s, s * 0.5), Vector2(-s * 0.6, s * 0.8)])
		r.color = SkyIsles.ROCK.darkened(randf_range(0.0, 0.25))
		r.position = Vector2(randf_range(x0, x1), fy + randf_range(0, 50))
		r.z_index = 3
		world.add_child(r)
		var tt := r.create_tween()
		tt.tween_property(r, "position:y", r.position.y + 700.0, randf_range(0.9, 1.4)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tt.parallel().tween_property(r, "rotation", randf_range(-4, 4), 1.2)
		tt.tween_callback(r.queue_free)

# Безопасная точка возрождения: над уцелевшей серединой
static func safe_spawn(de: DuelEvents, r: Dictionary, p: Player) -> Dictionary:
	if de.map_id != "arena_sky" or not de.doom:
		return r
	var x := SkyIsles.W / 2.0 + (-90.0 if p.team == 0 else 90.0)
	return {"pos": Vector2(x, SkyIsles.FLOOR_Y - p.body_size.y / 2.0 - 4.0), "parachute": false}

# ---------- Огненный вал: ползёт от края к середине ----------
class FireWall extends Node2D:
	var side := -1.0                       # -1 — слева направо, 1 — справа налево
	var x := 0.0
	var stop := 0.0
	var speed := 16.0
	var _tongues: Array = []
	var _t := 0.0
	var _tick := 0.0

	func _ready() -> void:
		z_index = 7
		for i in 18:
			var p := Polygon2D.new()
			var hw := randf_range(22, 40)
			var hh := randf_range(80, 160)
			p.polygon = PackedVector2Array([Vector2(-hw, 0), Vector2(-hw * 0.3, -hh * 0.65), Vector2(0, -hh), Vector2(hw * 0.4, -hh * 0.5), Vector2(hw, 0)])
			p.color = [Color(0.85, 0.20, 0.06, 0.85), Color(1.0, 0.50, 0.12, 0.9), Color(1.0, 0.82, 0.35, 0.9)][i % 3]
			add_child(p)
			_tongues.append([p, randf_range(-60.0, 0.0), Colosseum.FLOOR_Y - i * 55.0])
		var heat := Polygon2D.new()
		heat.polygon = PackedVector2Array([Vector2(-40, Colosseum.FLOOR_Y), Vector2(-40, -200), Vector2(120, -200), Vector2(120, Colosseum.FLOOR_Y)])
		heat.color = Color(1.0, 0.35, 0.10, 0.25)
		heat.name = "Heat"
		add_child(heat)

	func _physics_process(delta: float) -> void:
		_t += delta
		var target := stop
		x = move_toward(x, target, speed * delta * (1.0 + _t * 0.02))
		# пламя — у «переднего» края вала, всё, что позади, тоже горит
		for e in _tongues:
			var p: Polygon2D = e[0]
			p.position = Vector2(x + float(e[1]) * -side, float(e[2]))
			p.scale = Vector2(1.0 * -side, 0.8 + 0.35 * absf(sin(_t * 7.0 + float(e[2]))))
		var heat: Polygon2D = get_node("Heat")
		var lo := 0.0 if side < 0 else x
		var hi := x if side < 0 else Colosseum.W
		heat.polygon = PackedVector2Array([Vector2(lo, Colosseum.FLOOR_Y), Vector2(lo, -800), Vector2(hi, -800), Vector2(hi, Colosseum.FLOOR_Y)])
		if randf() < 0.5:
			Fx.sparks(get_parent(), Vector2(x, Colosseum.FLOOR_Y - randf_range(0, 500)), Color(1.0, 0.55, 0.15), 1, 160.0, 3.0, true)
		_tick -= delta
		for n in get_parent().get_children():
			if n is Player and n.is_alive():
				var inside: bool = (n.global_position.x < x + 20.0) if side < 0 else (n.global_position.x > x - 20.0)
				if inside:
					n.velocity.x = -side * 700.0                 # отбрасывает от огня
					if _tick <= 0.0:
						n.take_damage(14)
						if n.has_method("burn") and not n.has_meta("fireproof"):
							n.burn(1.5, 6.0)
		if _tick <= 0.0:
			_tick = 0.35
