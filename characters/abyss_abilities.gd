class_name AbyssAbilities
# ---------- Способности врагов последних земель (волны 91–100) ----------
#   void_blink     — Ворон разлома: исчезает и появляется за спиной героя, сразу пикирует;
#   bale_toss      — Соломенный исполин: швыряет горящий тюк соломы (круг на земле — куда упадёт);
#   mill_roll      — Мельник Жернов: катит жернов по земле (перепрыгни), жернов ломает укрытия;
#   grain_rain     — Мельник: с неба падают мешки в отмеченные круги;
#   flour_burst    — Мельник: облако муки — кто в нём, тот вязнет;
#   void_mill      — Мельник в ярости: раскручивается, как мельница в бурю, и тянет героев к себе;
#   chain_hook     — Палач Бездны: видна линия — потом летит крюк на цепи и подтягивает к Палачу;
#   cleave_line    — Палач: удар тесаком оземь — по земле бежит разрез из шипов пустоты (прыгай);
#   execution_leap — Палач: прыжок-казнь — на земле вспыхивает круг, через миг он обрушивается;
#   void_chains    — Палач в ярости: из земли под героями рвутся цепи (видно кольцо) и сковывают;
#   thread_lines   — Ткачиха: поперёк поля натягиваются тонкие нити — потом вспыхивают и режут;
#   portal_bolts   — Ткачиха и Чтец: возле героя открываются порталы, из них бьют болты;
#   silk_snare     — Ткачиха: белый сгусток паутины — кого заденет, того опутает;
#   weave_clones   — Ткачиха: сплетает два своих отражения.

const GLOW := Color(0.78, 0.36, 1.0)
const CORE := Color(0.98, 0.86, 1.0)

static func _foes(p: Player) -> Array:
	return RiftAbilities._foes(p)

static func _am(p: Node) -> Node:
	return p.get_tree().get_first_node_in_group("arena_mode") if p.is_inside_tree() else null

static func _floor_y(p: Node) -> float:
	var am := _am(p)
	if am and am.info.has("floor"):
		return float(am.info["floor"])
	return Colosseum.FLOOR_Y

static func brain(p: Player) -> AbyssBrain:
	return p.get_node_or_null("AbyssBrain") as AbyssBrain

static func try(p: Player, ab: String, to: Vector2) -> bool:
	var d := absf(to.x)
	var has_t: bool = is_instance_valid(p.target) and p.target.is_alive()
	if not has_t:
		return false
	var wb = p.get_node_or_null("WandererBrain")
	if wb:
		return wb.use(ab, to)                 # Странник: всё решает его мозг
	var br := brain(p)
	if br and br.busy():
		return false
	match ab:
		"stampede":
			ShepherdAbilities.stampede(p, br_rage(p), 6 if br_rage(p) else 4)
			return true
		"crook_pull":
			if d > 140.0 and d < 760.0 and absf(to.y) < 240.0:
				ShepherdAbilities.crook_pull(p)
				return true
		"blight_sow":
			if d < 1000.0:
				ShepherdAbilities.blight_sow(p)
				return true
		"bell_toll":
			ShepherdAbilities.bell_toll(p)
			return true
		"void_blink":
			if to.length() < 520.0 and to.length() > 90.0:
				_void_blink(p)
				return true
		"bale_toss":
			if d > 160.0 and d < 900.0:
				_bale_toss(p)
				return true
		"mill_roll":
			if d > 150.0 and d < 1600.0 and absf(to.y) < 160.0:
				_mill_roll(p)
				return true
		"grain_rain":
			if to.length() < 1300.0:
				_grain_rain(p)
				return true
		"flour_burst":
			if to.length() < 420.0:
				_flour_burst(p)
				return true
		"void_mill":
			if br and to.length() < 900.0:
				br.start_mill()
				return true
		"chain_hook":
			if d > 180.0 and d < 900.0 and absf(to.y) < 220.0:
				_chain_hook(p)
				return true
		"cleave_line":
			if d < 1000.0 and absf(to.y) < 160.0 and p.is_on_floor():
				_cleave_line(p)
				return true
		"execution_leap":
			if d > 200.0 and d < 1100.0 and p.is_on_floor():
				_execution_leap(p)
				return true
		"void_chains":
			_void_chains(p)
			return true
		"thread_lines":
			_thread_lines(p)
			return true
		"portal_bolts":
			if to.length() < 1400.0:
				_portal_bolts(p)
				return true
		"silk_snare":
			if to.length() < 1000.0:
				_silk_snare(p)
				return true
		"weave_clones":
			_weave_clones(p)
			return true
	return false

# ======================= Ворон разлома =======================
static func _void_blink(p: Player) -> void:
	var world := p.get_parent()
	var t: Player = p.target
	var side := -signf(t.global_position.x - p.global_position.x)
	var at := t.global_position + Vector2(side * 150.0, -120.0)
	at.x = clampf(at.x, 120.0, p.map_w - 120.0)
	Fx.sparks(world, p.global_position, GLOW, 10, 200.0, 4.0)
	Util.flash(world, p.global_position, 40.0, Color(0.8, 0.5, 1.0, 0.8))
	p.global_position = at
	Fx.sparks(world, at, GLOW, 10, 200.0, 4.0)
	Util.flash(world, at, 40.0, Color(0.8, 0.5, 1.0, 0.8))
	p._after(0.18, func():
		if is_instance_valid(p) and p.is_alive() and is_instance_valid(p.target):
			p._anim("punch")
			p._dive_t = 0.45
			p._dive_v = (p.target.global_position - p.global_position).normalized() * 760.0)

# ======================= Брошенное по дуге (тюк, мешок) =======================
class Lob extends Node2D:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var time := 0.9
	var arc := 360.0
	var dmg := 14
	var radius := 80.0
	var team := 1
	var attacker: Node
	var look := "bale"               # bale — горящий тюк, sack — мешок с зерном
	var fire := false
	var _t := 0.0
	var _mark: Node2D
	var _body: Polygon2D

	func _ready() -> void:
		z_index = 6
		_mark = Fx.rune_circle(get_parent(), to, radius, Color(1.0, 0.7, 0.3, 0.8) if look == "bale" else Color(0.9, 0.85, 0.7, 0.8), time + 0.1)
		_body = Polygon2D.new()
		if look == "bale":
			_body.polygon = PackedVector2Array([Vector2(-18, -13), Vector2(18, -13), Vector2(18, 13), Vector2(-18, 13)])
			_body.color = Color(0.88, 0.74, 0.38)
			for k in 3:
				var band := Line2D.new()
				band.points = PackedVector2Array([Vector2(-18, -6 + k * 6), Vector2(18, -6 + k * 6)])
				band.width = 1.5
				band.default_color = Color(0.62, 0.48, 0.24)
				_body.add_child(band)
		else:
			_body.polygon = PackedVector2Array([Vector2(-14, 14), Vector2(-16, -4), Vector2(-8, -16), Vector2(8, -16), Vector2(16, -4), Vector2(14, 14)])
			_body.color = Color(0.82, 0.76, 0.62)
			var tie := Polygon2D.new()
			tie.polygon = PackedVector2Array([Vector2(-6, -16), Vector2(6, -16), Vector2(4, -20), Vector2(-4, -20)])
			tie.color = Color(0.55, 0.42, 0.28)
			_body.add_child(tie)
		add_child(_body)
		position = from

	func _physics_process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / time, 0.0, 1.0)
		position = from.lerp(to, k) + Vector2(0, -arc * 4.0 * k * (1.0 - k))
		_body.rotation += delta * 6.0
		if fire and randf() < 0.5:
			Fx.sparks(get_parent(), global_position, Color(1.0, 0.6, 0.2), 1, 80.0, 3.0)
		if k >= 1.0:
			var world := get_parent()
			Util.explode(world, to + Vector2(0, -20), radius, dmg, 18, team, attacker)
			Fx.sparks(world, to + Vector2(0, -8), Color(0.88, 0.74, 0.38) if look == "bale" else Color(0.95, 0.92, 0.82), 16, 260.0, 5.0, true)
			if fire:
				var fz := FireZone.new()
				fz.team = team
				fz.attacker = attacker
				fz.position = to
				world.add_child(fz)
			if is_instance_valid(_mark):
				_mark.queue_free()
			queue_free()

static func lob(p: Player, from: Vector2, at: Vector2, time: float, dmg: int, look := "bale", fire := false) -> Lob:
	var l := Lob.new()
	l.from = from
	l.to = at
	l.time = time
	l.dmg = dmg
	l.team = p.team
	l.attacker = p
	l.look = look
	l.fire = fire
	l.arc = maxf(200.0, from.distance_to(at) * 0.45) if look == "bale" else 0.0
	p.get_parent().add_child(l)
	return l

static func _bale_toss(p: Player) -> void:
	p._anim("throw")
	p._forced_time = 0.4
	p._forced_vx = 0.0
	var t: Player = p.target
	var lead := t.velocity.x * 0.5
	var at := Vector2(clampf(t.global_position.x + lead, 120.0, p.map_w - 120.0), RiftAbilities._ground(p, t.global_position))
	p._after(0.3, func():
		if is_instance_valid(p) and p.is_alive():
			lob(p, p.global_position + Vector2(p.facing * 20.0, -p.body_size.y * 0.4), at, 0.95, 16, "bale", true))

# ======================= Мельник Жернов =======================
class Millstone extends Node2D:
	var dir := 1.0
	var speed := 640.0
	var dmg := 22
	var radius := 46.0
	var team := 1
	var attacker: Node
	var bounces := 1
	var _hit := {}
	var _life := 5.0
	var _disc: Node2D

	func _ready() -> void:
		z_index = 5
		_disc = Node2D.new()
		add_child(_disc)
		var stone := Polygon2D.new()
		stone.polygon = Util.circle(radius, 22)
		stone.color = Color(0.56, 0.54, 0.56)
		_disc.add_child(stone)
		var rim := Line2D.new()
		var pts := Util.circle(radius - 3.0, 22)
		pts.append(pts[0])
		rim.points = pts
		rim.width = 3.0
		rim.default_color = Color(0.40, 0.38, 0.42)
		_disc.add_child(rim)
		for k in 6:                                       # бороздки жернова
			var g := Line2D.new()
			var a := k * TAU / 6.0
			g.points = PackedVector2Array([Vector2.from_angle(a) * 10.0, Vector2.from_angle(a + 0.5) * (radius - 6.0)])
			g.width = 2.0
			g.default_color = Color(0.42, 0.40, 0.44)
			_disc.add_child(g)
		var hole := Polygon2D.new()
		hole.polygon = Util.circle(8.0, 10)
		hole.color = Color(0.25, 0.10, 0.32)
		_disc.add_child(hole)
		var vg := Polygon2D.new()                         # жила бездны в отверстии
		vg.polygon = Util.circle(4.0, 8)
		vg.color = GLOW
		_disc.add_child(vg)

	func _physics_process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			_break()
			return
		position.x += dir * speed * delta
		_disc.rotation += dir * speed / radius * delta
		if randf() < 0.6:
			Fx.sparks(get_parent(), global_position + Vector2(-dir * radius * 0.6, radius - 4.0), Color(0.75, 0.70, 0.62), 1, 140.0, 3.0, true)
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield and not _hit.has(n):
				if absf(n.global_position.x - global_position.x) < radius + n.body_size.x * 0.4 \
						and absf(n.global_position.y - global_position.y) < radius + n.body_size.y * 0.4:
					_hit[n] = true
					n.take_damage(dmg, attacker)
					n.velocity = Vector2(dir * 520.0, -420.0)
			elif n is Destructible and not n.background and n.global_position.distance_to(global_position) < 400.0:
				n.hit(global_position + Vector2(dir * radius, 0), Vector2(dir, 0), 30, radius * 0.7, team,
						{"strict": true, "radial": true, "attacker": attacker, "power": 0.6})
		var lo := Colosseum.WALL + radius
		var hi := Colosseum.W - Colosseum.WALL - radius
		if global_position.x < lo or global_position.x > hi:
			if bounces > 0:
				bounces -= 1
				dir = -dir
				global_position.x = clampf(global_position.x, lo, hi)
				_hit.clear()
				Fx.shake(get_parent(), 6.0)
				Fx.sparks(get_parent(), global_position, Color(0.7, 0.66, 0.62), 12, 260.0, 5.0)
			else:
				_break()

	func _break() -> void:
		Fx.sparks(get_parent(), global_position, Color(0.6, 0.58, 0.6), 18, 300.0, 6.0, true)
		Fx.sparks(get_parent(), global_position, GLOW, 8, 200.0, 4.0)
		queue_free()

static func _mill_roll(p: Player) -> void:
	var world := p.get_parent()
	p._anim("throw")
	p._forced_time = 0.75
	p._forced_vx = 0.0
	var dir := signf(p.target.global_position.x - p.global_position.x)
	if dir == 0.0:
		dir = float(p.facing)
	p.facing = int(dir)
	var fy := _floor_y(p)
	LightBeam.aim_line(world, Vector2(p.global_position.x + dir * 80.0, fy - 6.0), Vector2(p.global_position.x + dir * 900.0, fy - 6.0), Color(0.85, 0.80, 0.70), 0.6)
	p._after(0.6, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		var m := Millstone.new()
		m.dir = dir
		m.team = p.team
		m.attacker = p
		m.dmg = int(22 * float(p.get_meta("bal_dmg", 1.0)) / 1.5)
		m.position = Vector2(p.global_position.x + dir * (p.body_size.x / 2 + 50.0), fy - m.radius)
		if br_rage(p):
			m.speed = 820.0
			m.bounces = 2
		p.get_parent().add_child(m)
		Fx.shake(world, 6.0))

static func br_rage(p: Player) -> bool:
	var br := brain(p)
	return br != null and br.rage

static func _grain_rain(p: Player) -> void:
	var world := p.get_parent()
	p._anim("roar")
	var tx: float = p.target.global_position.x
	var n := 7 if br_rage(p) else 5
	for k in n:
		var x := clampf(tx + (k - (n - 1) / 2.0) * 130.0 + randf_range(-30, 30), 120.0, p.map_w - 120.0)
		var gy := RiftAbilities._ground(p, Vector2(x, _floor_y(p) - 600.0))
		var l := lob(p, Vector2(x + randf_range(-60, 60), gy - 900.0), Vector2(x, gy), 1.1 + k * 0.08, 14, "sack")
		l.radius = 70.0

class FlourCloud extends Node2D:
	var radius := 260.0
	var life := 3.2
	var team := 1
	var _t := 0.0
	var _puffs: Array = []

	func _ready() -> void:
		z_index = 7
		for i in 16:
			var c := Polygon2D.new()
			var r := randf_range(40, 80)
			c.polygon = Util.circle(r, 12)
			c.color = Color(0.96, 0.94, 0.88, 0.5)
			c.position = Vector2.from_angle(randf() * TAU) * randf_range(0, radius * 0.8)
			c.scale = Vector2(0.2, 0.2)
			add_child(c)
			_puffs.append(c)
			c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)

	func _physics_process(delta: float) -> void:
		_t += delta
		for c in _puffs:
			c.position += c.position.normalized() * 14.0 * delta
			c.color.a = 0.5 * clampf((life - _t) / 0.8, 0.0, 1.0)
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and n.global_position.distance_to(global_position) < radius:
				n.slow(0.4, 0.5, "mud")
		if _t >= life:
			queue_free()

static func _flour_burst(p: Player) -> void:
	p._anim("slam")
	p._forced_time = 0.5
	p._forced_vx = 0.0
	p._after(0.35, func():
		if is_instance_valid(p) and p.is_alive():
			var fc := FlourCloud.new()
			fc.team = p.team
			fc.position = p.global_position + Vector2(0, p.body_size.y * 0.2)
			p.get_parent().add_child(fc)
			Fx.ring(p.get_parent(), fc.position, 260.0, Color(0.95, 0.92, 0.85, 0.8), 0.4, 6.0))

# ======================= Палач Бездны =======================
class Hook extends Node2D:
	var owner_p: Player
	var dir := Vector2.RIGHT
	var speed := 1350.0
	var max_len := 900.0
	var dmg := 12
	var _len := 0.0
	var _back := false
	var _caught: Player
	var _chain: Line2D
	var _head: Polygon2D

	func _ready() -> void:
		z_index = 7
		_chain = Line2D.new()
		_chain.width = 4.0
		_chain.default_color = Color(0.40, 0.36, 0.46)
		_chain.top_level = true
		add_child(_chain)
		_head = Polygon2D.new()
		_head.polygon = PackedVector2Array([Vector2(16, 0), Vector2(-6, -10), Vector2(0, 0), Vector2(-6, 10)])
		_head.color = Color(0.85, 0.60, 1.0)
		_head.top_level = true
		add_child(_head)

	func _hand() -> Vector2:
		if is_instance_valid(owner_p) and owner_p.rig:
			return owner_p.rig.muzzle()
		return owner_p.global_position if is_instance_valid(owner_p) else global_position

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(owner_p) or not owner_p.is_alive():
			queue_free()
			return
		var hand := _hand()
		if not _back:
			_len += speed * delta
			var tip := hand + dir * _len
			for n in owner_p.get_parent().get_children():
				if n is Player and n.team != owner_p.team and n.is_alive() and not n.cutscene_shield:
					if Rect2(n.global_position - n.body_size / 2, n.body_size).grow(10.0).has_point(tip):
						_caught = n
						_back = true
						n.take_damage(dmg, owner_p)
						n.stun(0.45)
						Fx.sparks(owner_p.get_parent(), tip, GLOW, 10, 220.0, 4.0)
						break
			if _len >= max_len:
				_back = true
			_draw_chain(hand, tip)
		else:
			_len -= speed * 1.15 * delta
			var tip2 := hand + dir * maxf(_len, 0.0)
			if _caught and is_instance_valid(_caught) and _caught.is_alive():
				var stop := hand + dir * (owner_p.body_size.x / 2 + 60.0)
				if (tip2 - hand).length() > (stop - hand).length():
					_caught.global_position = tip2
					_caught.velocity = Vector2.ZERO
				else:
					_caught.global_position = stop
			_draw_chain(hand, tip2)
			if _len <= 0.0:
				queue_free()

	func _draw_chain(a: Vector2, b: Vector2) -> void:
		_chain.points = PackedVector2Array([a, b])
		_head.global_position = b
		_head.rotation = dir.angle()

static func _chain_hook(p: Player) -> void:
	var world := p.get_parent()
	var from: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	var dir: Vector2 = (p.target.global_position - from).normalized()
	p._anim("windup")
	p._forced_time = 0.9
	p._forced_vx = 0.0
	LightBeam.aim_line(world, from, from + dir * 900.0, GLOW, 0.55)
	p._after(0.55, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		p._anim("throw")
		var h := Hook.new()
		h.owner_p = p
		h.dir = dir
		h.dmg = int(12 * float(p.get_meta("bal_dmg", 1.0)) / 1.5)
		p.get_parent().add_child(h))

static func _cleave_line(p: Player) -> void:
	var world := p.get_parent()
	var dir := float(p.facing)
	if is_instance_valid(p.target):
		dir = signf(p.target.global_position.x - p.global_position.x)
		if dir == 0.0:
			dir = float(p.facing)
	p.facing = int(dir)
	p._anim("slam")
	p._forced_time = 0.9
	p._forced_vx = 0.0
	var fy := _floor_y(p)
	var x0 := p.global_position.x + dir * (p.body_size.x / 2 + 30.0)
	LightBeam.aim_line(world, Vector2(x0, fy - 4.0), Vector2(x0 + dir * 1000.0, fy - 4.0), GLOW, 0.55)
	var hit := {}
	for k in 17:
		p._after(0.55 + k * 0.035, func():
			if not is_instance_valid(p):
				return
			var x := x0 + dir * k * 60.0
			if x < Colosseum.WALL or x > p.map_w - Colosseum.WALL:
				return
			var sp := Polygon2D.new()
			var hgt := randf_range(50, 80)
			sp.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(-2, -hgt), Vector2(4, -hgt * 0.7), Vector2(10, 0)])
			sp.color = Color(0.16, 0.06, 0.22)
			sp.position = Vector2(x, fy)
			sp.z_index = 5
			world.add_child(sp)
			var edge := Line2D.new()
			edge.points = PackedVector2Array([Vector2(-2, -hgt), Vector2(4, -hgt * 0.7)])
			edge.width = 2.0
			edge.default_color = GLOW
			sp.add_child(edge)
			sp.scale = Vector2(1, 0.1)
			var st := sp.create_tween()
			st.tween_property(sp, "scale", Vector2.ONE, 0.08)
			st.tween_interval(0.25)
			st.tween_property(sp, "modulate:a", 0.0, 0.3)
			st.tween_callback(sp.queue_free)
			for n in _foes(p):
				if hit.has(n):
					continue
				var feet: float = n.global_position.y + n.body_size.y / 2
				if absf(n.global_position.x - x) < 34.0 + n.body_size.x / 2 and feet > fy - 70.0:
					hit[n] = true
					n.take_damage(int(20 * float(p.get_meta("bal_dmg", 1.0)) / 1.5), p)
					n.velocity = Vector2(dir * 200.0, -480.0)
			if k % 3 == 0:
				Fx.sparks(world, Vector2(x, fy - 6), GLOW, 3, 200.0, 4.0, true))
	p._after(0.5, func(): Fx.shake(world, 8.0))

static func _execution_leap(p: Player) -> void:
	var world := p.get_parent()
	var fy := _floor_y(p)
	var tx := clampf(p.target.global_position.x, Colosseum.WALL + p.body_size.x, p.map_w - Colosseum.WALL - p.body_size.x)
	var land := Vector2(tx, fy - p.body_size.y / 2 - 2.0)
	var mark := Fx.rune_circle(world, Vector2(tx, fy), 170.0, Color(0.85, 0.45, 1.0, 0.9), 1.0)
	p._anim("windup")
	p.frozen = true
	p.velocity = Vector2.ZERO
	var from := p.global_position
	var t := p.create_tween()
	t.tween_interval(0.25)
	t.tween_method(func(k: float):
		if is_instance_valid(p):
			p.global_position = from.lerp(land, k) + Vector2(0, -520.0 * 4.0 * k * (1.0 - k)), 0.0, 1.0, 0.75)
	t.tween_callback(func():
		if not is_instance_valid(p):
			return
		p.frozen = false
		p._anim("slam")
		var feet := Vector2(tx, fy)
		Util.explode(world, feet + Vector2(0, -30), 170.0, int(28 * float(p.get_meta("bal_dmg", 1.0)) / 1.5), 40, p.team, p)
		Fx.shake(world, 14.0)
		Fx.ring(world, feet, 220.0, Color(0.85, 0.5, 1.0, 0.9), 0.45, 8.0, 0.3)
		Fx.cracks(world, feet, Color(0.25, 0.10, 0.32), 160.0)
		Fx.sparks(world, feet + Vector2(0, -8), GLOW, 20, 340.0, 5.0, true)
		if is_instance_valid(mark):
			mark.queue_free())

static func _void_chains(p: Player) -> void:
	var world := p.get_parent()
	var fy := _floor_y(p)
	p._anim("roar")
	for n in _foes(p):
		var at := Vector2(n.global_position.x, fy)
		var ring := Fx.rune_circle(world, at, 70.0, Color(0.85, 0.45, 1.0, 0.9), 0.9)
		p._after(0.85, func():
			if not is_instance_valid(n) or not n.is_alive():
				return
			for k in 3:
				var ch := Line2D.new()
				ch.width = 4.0
				ch.default_color = Color(0.45, 0.40, 0.52)
				ch.points = PackedVector2Array([at + Vector2(-50 + k * 50, 0), at + Vector2(-20 + k * 20, -90)])
				ch.z_index = 6
				world.add_child(ch)
				var ct := ch.create_tween()
				ct.tween_interval(1.0)
				ct.tween_property(ch, "modulate:a", 0.0, 0.3)
				ct.tween_callback(ch.queue_free)
			if absf(n.global_position.x - at.x) < 70.0 + n.body_size.x / 2 and n.global_position.y + n.body_size.y / 2 > fy - 60.0:
				n.take_damage(int(10 * float(p.get_meta("bal_dmg", 1.0)) / 1.5), p)
				n.root(1.2)
				Fx.sparks(world, n.global_position, GLOW, 10, 200.0, 4.0))

# ======================= Ткачиха Разлома =======================
static func _thread_lines(p: Player) -> void:
	var world := p.get_parent()
	p._anim("cast")
	var fy := _floor_y(p)
	var t: Player = p.target
	var lines: Array = []
	# одна нить — точно через героя, две — выше и ниже, под небольшим наклоном
	for k in 3:
		var y: float = t.global_position.y + [0.0, -150.0, 130.0][k] + randf_range(-20, 20)
		y = clampf(y, fy - 520.0, fy - 18.0)
		var tilt := randf_range(-0.12, 0.12)
		var a := Vector2(Colosseum.WALL, y - tilt * 1300.0)
		var b := Vector2(p.map_w - Colosseum.WALL, y + tilt * 1300.0)
		lines.append([a, b])
		LightBeam.aim_line(world, a, b, Color(0.9, 0.85, 1.0), 1.0)
	p._after(1.0, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		for ln in lines:
			LightBeam.draw(world, [[ln[0], ln[1], 0]], Color(0.85, 0.55, 1.0), 6.0, 0.4)
			RiftAbilities.hit_segment(p, ln[0], ln[1], 16.0, int(16 * float(p.get_meta("bal_dmg", 1.0)) / 1.5), 0)
		Fx.shake(world, 5.0))

static func _portal_bolts(p: Player) -> void:
	var world := p.get_parent()
	p._anim("cast")
	var t: Player = p.target
	var fy := _floor_y(p)
	for side in [-1.0, 1.0]:
		var at := t.global_position + Vector2(side * randf_range(260, 360), -randf_range(80, 200))
		at.x = clampf(at.x, 120.0, p.map_w - 120.0)
		at.y = minf(at.y, fy - 60.0)
		var s := RiftAbilities.Slit.new()
		s.position = at + Vector2(0, 40)
		s.height = 80.0
		s.wide = 1.6
		s.life = 1.6
		world.add_child(s)
		for k in 3:
			p._after(0.6 + k * 0.28, func():
				if is_instance_valid(p) and p.is_alive() and is_instance_valid(p.target) and p.target.is_alive():
					RiftAbilities.bolt(p, at, (p.target.global_position - at).normalized(), 760.0, 8))

static func _silk_snare(p: Player) -> void:
	p._anim("cast")
	var from: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	var b := RiftAbilities.bolt(p, from, (p.target.global_position - from).normalized(), 620.0, 6, 16.0, 0)
	b.color = Color(0.95, 0.95, 1.0)
	b.homing = 160.0
	b.on_hit = func(n):
		if is_instance_valid(n) and n.is_alive():
			n.root(1.3)
			n.slow(2.0, 0.6, "web")

static func _weave_clones(p: Player) -> void:
	var am := _am(p)
	if am == null:
		return
	var world := p.get_parent()
	p._anim("summon")
	for side in [-1.0, 1.0]:
		var at := p.global_position + Vector2(side * 260.0, 0)
		at.x = clampf(at.x, 160.0, p.map_w - 160.0)
		Fx.sparks(world, at, CORE, 14, 220.0, 4.0)
		var e: Player = am.spawn_at("weaver_echo", at)
		e.set_meta("summoned", true)
