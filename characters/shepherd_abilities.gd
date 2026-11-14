class_name ShepherdAbilities
# ---------- Пастух Разлома — мини-босс 95-й волны (Ветряные холмы) ----------
# Старый пастух, чьё стадо первым ушло в трещину в небе — и вернулось оттуда другим.
#   stampede   — «Стадо бездны»: с края поля с грохотом несутся бараны с лиловыми рогами.
#                Перепрыгни их или уйди на площадку. В ярости — с обеих сторон.
#   crook_pull — бросает посох-крюк: зацепил — тащит героя к себе.
#   blight_sow — сеет порчу: зёрна падают вокруг героя, на земле вспыхивают пятна, жгут.
#   bell_toll  — бьёт в колокол на посохе: волна звона замедляет, следом бегут два барана.

const WOOL := Color(0.86, 0.82, 0.88)
const HORN := Color(0.70, 0.40, 1.0)

static func _floor(p: Node) -> float:
	return AbyssAbilities._floor_y(p)

static func _dmg(p: Player, base: float) -> int:
	return int(base * float(p.get_meta("bal_dmg", 1.0)) / 1.5)

# ----- Стадо бездны -----
static func stampede(p: Player, both := false, n := 4) -> void:
	var world := p.get_parent()
	p._anim("roar")
	var sides: Array = [1.0, -1.0] if both else [(-1.0 if p.target.global_position.x < p.global_position.x else 1.0) * -1.0]
	for s in sides:
		var st := Stampede.new()
		st.src = weakref(p)
		st.dir = -float(s)                              # бегут от своего края к другому
		st.count = n
		st.fy = _floor(p)
		st.dmg = _dmg(p, 10.0)
		world.add_child(st)

class Stampede extends Node2D:
	var src: WeakRef
	var dir := 1.0
	var count := 4
	var fy := 940.0
	var dmg := 10
	var speed := 760.0
	var _t := 0.0
	var _rams: Array = []          # [узел, x, задетые]
	var _spawned := 0
	var _warn: Node2D
	var _last := {}               # герой -> когда его последний раз задел баран (стадо не «перемалывает»)

	func _ready() -> void:
		z_index = 5
		# предупреждение: пыль и стрелки у края, откуда понесётся стадо
		_warn = Node2D.new()
		add_child(_warn)
		var x0 := Colosseum.WALL + 40.0 if dir > 0.0 else Colosseum.W - Colosseum.WALL - 40.0
		for k in 3:
			var a := Polygon2D.new()
			a.polygon = PackedVector2Array([Vector2(0, -12), Vector2(dir * 22, 0), Vector2(0, 12)])
			a.color = Color(0.85, 0.55, 1.0, 0.85)
			a.position = Vector2(x0 + dir * k * 30.0, fy - 40.0)
			_warn.add_child(a)
		Fx.shake(get_parent(), 4.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		var world := get_parent()
		if is_instance_valid(_warn):
			_warn.modulate.a = 0.5 + 0.5 * sin(_t * 18.0)
			if _t > 1.0:
				_warn.queue_free()
		if _t > 1.0 and _spawned < count and _t > 1.0 + _spawned * 0.28:
			_spawned += 1
			var x := Colosseum.WALL - 40.0 if dir > 0.0 else Colosseum.W - Colosseum.WALL + 40.0
			var r := _ram()
			r.position = Vector2(x, fy)
			add_child(r)
			_rams.append([r, x, {}])
			if _spawned == 1:
				Fx.shake(world, 7.0)
		var who: Variant = src.get_ref() if src else null
		for e in _rams.duplicate():
			var node: Node2D = e[0]
			e[1] = float(e[1]) + dir * speed * delta
			node.position.x = e[1]
			node.position.y = fy - absf(sin(_t * 16.0 + node.get_index())) * 4.0
			if randf() < 0.4:
				Fx.sparks(world, Vector2(e[1] - dir * 30.0, fy - 4), Color(0.70, 0.60, 0.55), 1, 140.0, 4.0, true)
			for h in HardMode.heroes(world):
				var feet: float = h.global_position.y + h.body_size.y / 2
				var hid: Variant = h.get_instance_id()
				if dmg > 0 and absf(h.global_position.x - float(e[1])) < 34.0 + h.body_size.x / 2 and feet > fy - 46.0 and not e[2].has(hid) \
						and _t - float(_last.get(hid, -9.0)) > 0.8:
					e[2][hid] = true
					_last[hid] = _t
					h.take_damage(dmg, who if is_instance_valid(who) else null)
					h.velocity = Vector2(dir * 520.0, -420.0)
			if float(e[1]) < -80.0 or float(e[1]) > Colosseum.W + 80.0:
				node.queue_free()
				_rams.erase(e)
		if _spawned >= count and _rams.is_empty() and _t > 1.5:
			queue_free()

	# Баран бездны: кудрявое тело, тёмная морда, лиловые рога-завитки, светящийся глаз
	func _ram() -> Node2D:
		var r := Node2D.new()
		r.scale.x = dir
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([Vector2(-30, -16), Vector2(-24, -34), Vector2(-6, -38), Vector2(14, -34), Vector2(24, -24), Vector2(22, -12), Vector2(-28, -10)])
		body.color = WOOL.lerp(Color(0.60, 0.50, 0.70), randf() * 0.3)
		r.add_child(body)
		for k in 4:
			var curl := Polygon2D.new()
			curl.polygon = Util.circle(5.0, 8)
			curl.position = Vector2(-22 + k * 12, -34 + (k % 2) * 3)
			curl.color = body.color.lightened(0.12)
			r.add_child(curl)
		for lx in [-20.0, -8.0, 8.0, 16.0]:
			var leg := Polygon2D.new()
			leg.polygon = PackedVector2Array([Vector2(lx - 2, -12), Vector2(lx + 2, -12), Vector2(lx + 2, 0), Vector2(lx - 2, 0)])
			leg.color = Color(0.20, 0.16, 0.22)
			r.add_child(leg)
		var head := Polygon2D.new()
		head.polygon = PackedVector2Array([Vector2(20, -34), Vector2(34, -30), Vector2(40, -20), Vector2(34, -14), Vector2(22, -18)])
		head.color = Color(0.18, 0.14, 0.22)
		r.add_child(head)
		var horn := Polygon2D.new()
		horn.polygon = PackedVector2Array([Vector2(22, -34), Vector2(16, -44), Vector2(8, -40), Vector2(10, -32), Vector2(16, -36), Vector2(20, -28)])
		horn.color = HORN
		r.add_child(horn)
		var eye := Polygon2D.new()
		eye.polygon = Util.circle(2.2, 6)
		eye.position = Vector2(32, -25)
		eye.color = Color(0.95, 0.85, 1.0)
		r.add_child(eye)
		return r

# ----- Посох-крюк -----
static func crook_pull(p: Player) -> void:
	p._anim("throw")
	var from: Vector2 = p.global_position + Vector2(p.facing * 20.0, -p.body_size.y * 0.25)
	var b := RiftAbilities.bolt(p, from, (p.target.hurt_center() - from).normalized(), 760.0, _dmg(p, 9.0), 14.0, 0)
	if b._vis2:
		for c in b._vis2.get_children():
			c.queue_free()
		var hook := Line2D.new()
		hook.points = PackedVector2Array([Vector2(-14, 0), Vector2(6, 0), Vector2(10, -5), Vector2(8, -10), Vector2(3, -9)])
		hook.width = 3.0
		hook.default_color = Color(0.55, 0.40, 0.26)
		b._vis2.add_child(hook)
	var who: WeakRef = weakref(p)
	b.on_hit = func(n):
		var src: Variant = who.get_ref()
		if src == null or not is_instance_valid(src) or not (n is Player) or not n.is_alive():
			return
		var to: Vector2 = (src.global_position - n.global_position)
		n.velocity = Vector2(signf(to.x) * minf(absf(to.x) * 2.2, 980.0), -300.0)
		n.slow(0.8, 0.6)
		var line := Line2D.new()
		line.points = PackedVector2Array([src.global_position, n.global_position])
		line.width = 2.0
		line.default_color = Color(0.55, 0.40, 0.26)
		src.get_parent().add_child(line)
		var t := line.create_tween()
		t.tween_property(line, "modulate:a", 0.0, 0.35)
		t.tween_callback(line.queue_free)

# ----- Посев порчи -----
static func blight_sow(p: Player) -> void:
	p._anim("throw")
	var world := p.get_parent()
	var fy := _floor(p)
	var tx: float = p.target.global_position.x
	var n := 5 if AbyssAbilities.br_rage(p) else 3
	for k in n:
		var x := clampf(tx + (k - (n - 1) / 2.0) * 170.0 + randf_range(-30, 30), 120.0, Colosseum.W - 120.0)
		var gy := RiftAbilities._ground(p, Vector2(x, minf(p.target.global_position.y, fy - 40.0)))
		var l := AbyssAbilities.lob(p, p.global_position + Vector2(0, -p.body_size.y * 0.3), Vector2(x, gy), 0.8 + k * 0.08, _dmg(p, 6.0), "sack")
		l.radius = 40.0
		l.scale = Vector2(0.55, 0.55)
		var at := Vector2(x, gy)
		p._after(0.8 + k * 0.08, func():
			var bp := Blight.new()
			bp.src = weakref(p)
			bp.dmg = maxi(1, _dmg(p, 5.0))
			bp.position = at
			world.add_child(bp))

class Blight extends Node2D:
	var src: WeakRef
	var dmg := 4
	var life := 4.5
	var width := 130.0
	var _tick := 0.6
	var _t := 0.0
	var _poly: Polygon2D

	func _ready() -> void:
		z_index = 3
		_poly = Polygon2D.new()
		var pts := PackedVector2Array()
		for k in 12:
			var a := PI + PI * k / 11.0
			pts.append(Vector2(cos(a) * width / 2, sin(a) * 18.0 * (0.7 + randf() * 0.3)))
		_poly.polygon = pts
		_poly.color = Color(0.55, 0.20, 0.75, 0.0)
		add_child(_poly)
		Fx.cracks(get_parent(), position, Color(0.35, 0.10, 0.45), 70.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		_poly.color.a = minf(0.65, _t * 1.2) * (0.75 + 0.25 * sin(_t * 10.0)) * minf(1.0, life)
		if randf() < 0.3:
			Fx.sparks(get_parent(), position + Vector2(randf_range(-width / 2, width / 2), -4), Color(0.80, 0.45, 1.0), 1, 90.0, 3.0, true)
		_tick -= delta
		if _tick <= 0.0 and _t > 0.5:
			_tick = 0.5
			var who: Variant = src.get_ref() if src else null
			for h in HardMode.heroes(get_parent()):
				var feet: float = h.global_position.y + h.body_size.y / 2
				if absf(h.global_position.x - position.x) < width / 2 + h.body_size.x * 0.3 and absf(feet - position.y) < 24.0:
					h.take_damage(dmg, who if is_instance_valid(who) else null)
		if life <= 0.0:
			queue_free()

# ----- Колокол -----
static func bell_toll(p: Player) -> void:
	var world := p.get_parent()
	p._anim("roar")
	var at := p.global_position + Vector2(p.facing * 18.0, -p.body_size.y * 0.55)
	for k in 3:
		p._after(k * 0.18, func():
			Fx.ring(world, at, 120.0 + k * 110.0, Color(0.85, 0.60, 1.0, 0.85 - k * 0.2), 0.5, 7.0))
	Util.flash(world, at, 50.0, Color(1.0, 0.9, 0.6, 0.9))
	for h in HardMode.heroes(world):
		if h.global_position.distance_to(p.global_position) < 380.0:
			h.take_damage(_dmg(p, 8.0), p)
			h.slow(1.6, 0.5)
	p._after(0.8, func():
		if is_instance_valid(p) and p.is_alive() and is_instance_valid(p.target):
			stampede(p, false, 2))
