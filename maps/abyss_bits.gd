class_name AbyssBits
# ---------- Механики последних земель Арены (волны 91–100) ----------
#   LightBubble — «аномалия лёгкости» (Ветряные холмы): фиолетовый пузырь в воздухе,
#                 внутри почти нет тяжести — герои и враги прыгают выше и падают медленно;
#   VoidPatch   — «пустотная проплешина»: пятно порчи на земле. Тлеет, потом разгорается
#                 (видно за секунду) и выбрасывает пламя пустоты — жжёт и замедляет героев;
#   PalacePulse — «пульс дворца» (Дворец Бездны): ворота наливаются светом, и по земле
#                 от дворца катится волна — перепрыгни; чем сильнее дворец пробудился, тем чаще;
#   AbyssFall   — Изнанка: под островами пустота. Сорвался — больно, и тебя выбрасывает
#                 обратно наверх;
#   Crumble     — Изнанка рушится (последняя фаза Странника): края островов
#                 трескаются (видно заранее) и обваливаются кусок за куском;
#   Motes       — пылинки и комья, медленно поднимающиеся к разлому (для вида).

const FLOOR_Y := Colosseum.FLOOR_Y
const W := Colosseum.W
const VOID_C := Color(0.62, 0.26, 0.90)

# Кого задевают аномалии: героев (в Дуэли — обоих игроков), но не врагов и не призванных
static func _heroes(world: Node) -> Array:
	var res: Array = []
	for n in world.get_children():
		if n is Player and not n.is_bot and not n.is_minion and n.is_alive() and not n.cutscene_shield:
			res.append(n)
	return res

# ======================= Аномалия лёгкости =======================
class LightBubble extends Node2D:
	var radius := 140.0
	var base := Vector2.ZERO
	var drift := 40.0
	var _t := 0.0
	var _ring: Line2D
	var _fill: Polygon2D
	var _bits: Array = []

	func _ready() -> void:
		z_index = 3
		position = base
		_fill = Polygon2D.new()
		_fill.polygon = Util.circle(radius, 28)
		_fill.color = Color(0.62, 0.36, 0.92, 0.10)
		add_child(_fill)
		_ring = Line2D.new()
		var pts := Util.circle(radius, 40)
		pts.append(pts[0])
		_ring.points = pts
		_ring.width = 3.0
		_ring.default_color = Color(0.80, 0.55, 1.0, 0.45)
		add_child(_ring)
		for i in 12:
			var b := Polygon2D.new()
			b.polygon = Util.circle(randf_range(2.0, 4.0), 6)
			b.color = Color(0.92, 0.80, 1.0, 0.7)
			add_child(b)
			_bits.append([b, randf() * TAU, randf_range(0.2, 0.9), randf_range(0.6, 1.4)])

	func _physics_process(delta: float) -> void:
		_t += delta
		position = base + Vector2(sin(_t * 0.31) * drift, sin(_t * 0.53) * drift * 0.6)
		_ring.width = 3.0 + sin(_t * 3.0)
		for e in _bits:
			var b: Polygon2D = e[0]
			var a: float = e[1] + _t * e[3]
			b.position = Vector2(cos(a), sin(a * 1.3)) * radius * float(e[2])
		for n in get_parent().get_children():
			if not (n is Player) or not n.is_alive() or n.flying or n.fly_free:
				continue
			if n.global_position.distance_to(global_position) < radius:
				var p: Player = n
				if not p.is_on_floor():
					p.velocity.y -= p.gravity * 0.62 * delta        # внутри почти невесомость
					p.velocity.y = maxf(p.velocity.y, -1150.0)
				if randf() < 0.1:
					Fx.sparks(get_parent(), p.global_position + Vector2(0, p.body_size.y * 0.4), Color(0.85, 0.65, 1.0, 0.8), 1, 80.0, 3.0)

# ======================= Пустотная проплешина =======================
class VoidPatch extends Node2D:
	var width := 170.0
	var dmg := 8
	var rest := Vector2(4.0, 6.5)           # сколько тлеет между вспышками
	var burn := 1.3
	var _state := "rest"
	var _t := 2.0
	var _tick := 0.0
	var _base: Polygon2D
	var _flames: Array = []

	func _ready() -> void:
		z_index = 2
		_t = randf_range(1.5, rest.y)
		_base = Polygon2D.new()
		var pts := PackedVector2Array()
		for k in 14:
			var x := lerpf(-width / 2, width / 2, k / 13.0)
			pts.append(Vector2(x, -2.0 - randf() * 3.0))
		for k in 14:
			var x2 := lerpf(width / 2, -width / 2, k / 13.0)
			pts.append(Vector2(x2, 4.0 + randf() * 3.0))
		_base.polygon = pts
		_base.color = Color(0.22, 0.08, 0.30, 0.85)
		add_child(_base)
		for i in 9:
			var f := Polygon2D.new()
			f.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -40), Vector2(7, 0)])
			f.color = Color(0.75, 0.40, 1.0, 0.0)
			f.position = Vector2(lerpf(-width / 2 + 10, width / 2 - 10, i / 8.0), 0)
			add_child(f)
			_flames.append(f)

	func _physics_process(delta: float) -> void:
		_t -= delta
		match _state:
			"rest":
				_base.color = Color(0.22, 0.08, 0.30, 0.6 + 0.15 * sin(Time.get_ticks_msec() * 0.003))
				if _t <= 0.0:
					_state = "warn"
					_t = 1.0
			"warn":
				var k := 1.0 - _t
				_base.color = Color(0.55, 0.22, 0.80, 0.6 + 0.4 * absf(sin(k * 18.0)))
				for f in _flames:
					f.scale = Vector2(0.6, 0.15 + 0.15 * k)
					f.color.a = 0.4 * k
				if _t <= 0.0:
					_state = "burn"
					_t = burn
					_tick = 0.0
					Fx.sparks(get_parent(), global_position + Vector2(0, -10), VOID_C, 12, 260.0, 4.0, true)
			"burn":
				for i in _flames.size():
					var f: Polygon2D = _flames[i]
					f.scale = Vector2(1.0, 0.8 + 0.5 * absf(sin(Time.get_ticks_msec() * 0.02 + i)))
					f.color = Color(0.80, 0.45, 1.0, 0.85)
				_tick -= delta
				if _tick <= 0.0:
					_tick = 0.35
					for p in AbyssBits._heroes(get_parent()):
						var feet: float = p.global_position.y + p.body_size.y / 2
						if absf(p.global_position.x - global_position.x) < width / 2 + p.body_size.x * 0.3 \
								and feet > global_position.y - 60.0 and feet < global_position.y + 16.0:
							p.take_damage(dmg)
							p.slow(0.8, 0.6, "web")
				if _t <= 0.0:
					_state = "rest"
					_t = randf_range(rest.x, rest.y)
					for f in _flames:
						f.color.a = 0.0

# ======================= Пульс дворца =======================
class PalacePulse extends Node2D:
	var gate := Vector2(W / 2, FLOOR_Y)
	var every := Vector2(11.0, 14.0)
	var speed := 620.0
	var dmg := 12
	var enabled := true
	var _t := 6.0
	var _warn := 0.0
	var _waves: Array = []             # [x, dir, hit{}]
	var _glow: Polygon2D

	func _ready() -> void:
		z_index = 4
		_glow = Polygon2D.new()
		_glow.polygon = PackedVector2Array([Vector2(-60, 0), Vector2(-40, -120), Vector2(40, -120), Vector2(60, 0)])
		_glow.color = Color(0.75, 0.40, 1.0, 0.0)
		_glow.position = gate
		_glow.z_index = -5
		add_child(_glow)

	func _physics_process(delta: float) -> void:
		if not enabled:
			_glow.color.a = 0.0
			return
		_t -= delta
		if _warn > 0.0:
			_warn -= delta
			_glow.color.a = 0.25 + 0.35 * absf(sin(_warn * 14.0))
			if _warn <= 0.0:
				_glow.color.a = 0.0
				for d in [-1.0, 1.0]:
					var line := Line2D.new()
					line.width = 10.0
					line.default_color = Color(0.85, 0.55, 1.0, 0.9)
					line.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -46)])
					line.position = Vector2(gate.x, FLOOR_Y)
					add_child(line)
					_waves.append([gate.x, d, {}, line])
				Fx.ring(get_parent(), Vector2(gate.x, FLOOR_Y), 120.0, Color(0.8, 0.5, 1.0, 0.8), 0.35, 6.0, 0.35)
				Fx.shake(get_parent(), 4.0)
		elif _t <= 0.0:
			_t = randf_range(every.x, every.y)
			_warn = 1.1
		for wv in _waves.duplicate():
			wv[0] += float(wv[1]) * speed * delta
			var line: Line2D = wv[3]
			line.position.x = wv[0]
			if randf() < 0.6:
				Fx.sparks(get_parent(), Vector2(wv[0], FLOOR_Y - 6), Color(0.8, 0.5, 1.0), 1, 160.0, 3.0, true)
			for p in AbyssBits._heroes(get_parent()):
				var feet: float = p.global_position.y + p.body_size.y / 2
				if absf(p.global_position.x - wv[0]) < 26.0 + p.body_size.x / 2 and feet > FLOOR_Y - 40.0 \
						and not wv[2].has(p.get_instance_id()):
					wv[2][p.get_instance_id()] = true
					p.take_damage(dmg)
					p.velocity = Vector2(float(wv[1]) * 380.0, -520.0)
			if wv[0] < Colosseum.WALL or wv[0] > W - Colosseum.WALL:
				line.queue_free()
				_waves.erase(wv)

# ======================= Изнанка: падение в пустоту =======================
class AbyssFall extends Node2D:
	var center := Vector2(W / 2, FLOOR_Y - 400)
	var dmg := 15
	var _cd := {}

	func _physics_process(delta: float) -> void:
		for k in _cd.keys():
			_cd[k] -= delta
			if _cd[k] <= 0.0:
				_cd.erase(k)
		for n in get_parent().get_children():
			if not (n is Player) or not n.is_alive() or n.flying:
				continue
			var p: Player = n
			if p.global_position.y > FLOOR_Y + 260.0 and not _cd.has(p.get_instance_id()):
				_cd[p.get_instance_id()] = 1.0
				if p.team == 0:
					p.take_damage(dmg)
				Fx.sparks(get_parent(), p.global_position, VOID_C, 14, 260.0, 4.0)
				# пустота выплёвывает обратно — на ближайший уцелевший остров
				var x := _safe_x(p.global_position.x)
				p.global_position = Vector2(x, FLOOR_Y - 420.0)
				p.velocity = Vector2(0, 200.0)
				Util.flash(get_parent(), p.global_position, 60.0, Color(0.85, 0.6, 1.0, 0.8))

	func _safe_x(x: float) -> float:
		var best := W / 2
		var bd := INF
		for n in get_parent().get_children():
			if n is StaticBody2D and n.has_meta("isle"):
				var d: float = absf(n.global_position.x - x)
				if d < bd:
					bd = d
					best = n.global_position.x
		return best

# ======================= Изнанка рушится =======================
class Crumble extends Node2D:
	var order: Array = []          # куски островов в порядке обвала
	var every := 2.2
	var keep := 6                  # столько кусков остаётся всегда
	var _t := 2.0
	var _warned: Node = null

	func _physics_process(delta: float) -> void:
		_t -= delta
		if _t > 0.0:
			return
		_t = every
		order = order.filter(func(s): return is_instance_valid(s))
		if order.size() <= keep:
			return
		var seg: Node2D = order.pop_front()
		# трескается (видно), через секунду рушится
		var mark := Line2D.new()
		mark.width = 4.0
		mark.default_color = Color(0.9, 0.6, 1.0, 0.9)
		mark.points = PackedVector2Array([Vector2(-40, -36), Vector2(-10, -20), Vector2(5, -40), Vector2(30, -18)])
		mark.position = Vector2(0, -float(seg.get_meta("half_h", 30.0)) + 30.0)
		seg.add_child(mark)
		var t := seg.create_tween()
		t.tween_interval(1.0)
		t.tween_callback(func():
			if not is_instance_valid(seg):
				return
			Fx.sparks(seg.get_parent(), seg.global_position + Vector2(0, -float(seg.get_meta("half_h", 30.0))), Color(0.5, 0.3, 0.6), 14, 240.0, 5.0, true)
			for c in seg.get_children():
				if c is CollisionShape2D:
					c.set_deferred("disabled", true))
		t.tween_property(seg, "position:y", seg.position.y + 900.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(seg, "rotation", randf_range(-0.6, 0.6), 1.2)
		t.parallel().tween_property(seg, "modulate:a", 0.0, 1.2)
		t.tween_callback(seg.queue_free)

# ======================= Пылинки к разлому =======================
class Motes extends Node2D:
	var area := Rect2(0, 200, W, FLOOR_Y - 200)
	var color := Color(0.85, 0.65, 1.0, 0.6)
	var count := 26
	var _m: Array = []

	func _ready() -> void:
		z_index = -4
		for i in count:
			var m := Polygon2D.new()
			var s := randf_range(2.0, 5.0)
			m.polygon = PackedVector2Array([Vector2(-s, -s * 0.6), Vector2(s * 0.7, -s), Vector2(s, s * 0.5), Vector2(-s * 0.4, s)])
			m.color = color if randf() < 0.6 else Color(0.45, 0.33, 0.25, 0.8)
			m.position = Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
			add_child(m)
			_m.append([m, randf_range(14.0, 40.0), randf_range(-1.0, 1.0)])

	func _process(delta: float) -> void:
		for e in _m:
			var m: Polygon2D = e[0]
			m.position.y -= float(e[1]) * delta
			m.position.x += sin(m.position.y * 0.01 + float(e[2]) * 3.0) * 6.0 * delta
			m.rotation += float(e[2]) * delta
			if m.position.y < area.position.y - 40.0:
				m.position = Vector2(randf_range(area.position.x, area.end.x), area.end.y)
