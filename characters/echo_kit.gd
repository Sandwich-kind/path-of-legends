class_name EchoKit
extends HeroKit
# ---------- ОТГОЛОСОК — легенда за Странника (100-я волна Арены) ----------
# То, что осталось в мире, когда Странник ушёл в разлом: путник с фонарём на посохе.
# Всё, что он делает, отзывается эхом.
# Оружие «Фонарь»: сгустки света. Через 0,6 с по задетому врагу бьёт эхо — ещё 50% урона.
# 1 «Шаг на изнанку» — рывок вперёд сквозь врагов (на миг неуязвим). На старом месте
#   остаётся тень и через 0,8 с взрывается. МЕГА: взрывается и тень в конце пути,
#   враги рядом замедлены. Арена: взрыв шире и сильнее.
# 2 «Грань» — впереди встаёт линия разлома. Свои сгустки, пролетая сквозь неё,
#   раздваиваются; чужие снаряды вязнут; враги, переходя её, замедлены и ранены.
#   МЕГА: свои — натрое, чужие снаряды гаснут. Дуэль 5 с, Арена 7 с.
# 3 «Тяга бездны» — под ближайшим врагом впереди открывается круг: через 0,5 с враги
#   в нём взмывают, а потом их швыряет о землю. МЕГА: круг шире, удар оглушает.
#   Арена: удар сильнее. Боссов не поднимает — только бьёт.
# Ульта «Эхо пути» — 6 с (Арена 8 с) за Отголоском идёт его эхо: каждый выстрел и каждый
#   приём через полсекунды повторяется с того же места. МЕГА: эхо повторяет дважды,
#   эхо-сгустки сами ищут цель.

const VIOLET := Color(0.72, 0.48, 1.0)
const PALE := Color(0.95, 0.90, 1.0)
const ECHO_DELAY := 0.5

var _echo_t := 0.0
var _echo_mega := false
var _trail: Array = []            # [время, позиция] — где был герой (эхо идёт следом)
var _fig: Node2D
var _edge: Edge

# ---------- Стрельба: фонарь ----------
func weapon(delta: float, shoot: bool) -> void:
	var rapid := p.has_buff("rapid")
	if p._reloading > 0.0:
		p._reloading -= delta
		if p._reloading <= 0.0:
			p._reloading = 0.0
			p.ammo = p.clip_size
	elif not p.is_bot and Input.is_action_just_pressed(p.prefix + "_reload") and p.ammo < p.clip_size:
		p._reloading = p.reload_time
	if rapid:
		p._reloading = 0.0
		p.ammo = p.clip_size
	if not shoot or p._cooldown_left > 0.0 or p._reloading > 0.0:
		return
	p.bullet_style = "rift"
	var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, 0.0)
	b.global_position = p.global_position + Vector2(p.facing * 26.0, -10.0)   # из фонаря на посохе
	_dress(b, VIOLET)
	b.on_hit = _lamp_hit
	if rapid and p.is_mega("rapid"):
		b.pierce = 2
	var from := b.global_position
	var dir := b.direction
	var dmg := b.damage
	_repeat(func(): _echo_shot(from, dir, dmg))
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

# Облик сгустка: светлое ядро в лиловом ореоле и хвост
static func _dress(b: Bullet, col: Color) -> void:
	if b._vis2:
		var body := Polygon2D.new()
		body.polygon = Util.circle(b.size * 0.75, 14)
		body.color = col
		b._vis2.add_child(body)
		var core := Polygon2D.new()
		core.polygon = Util.circle(b.size * 0.36, 10)
		core.color = PALE
		b._vis2.add_child(core)
	if b._trail:
		b._trail.width = b.size * 0.7
		b._trail.default_color = Color(col, 0.45)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0))
		g.set_color(1, Color(1, 1, 1, 1))
		b._trail.gradient = g

# Сгусток без выстрела из оружия (эхо, раздвоение на Грани)
static func lamp(owner_p: Player, from: Vector2, dir: Vector2, spd: float, dmg: int, col := VIOLET) -> Bullet:
	var b := Bullet.new()
	b.shooter = owner_p
	b.team = owner_p.team
	b.direction = dir
	b.speed = spd
	b.damage = dmg
	b.size = owner_p.bullet_size * 0.9
	b.style = "rift"
	b.position = from
	owner_p.get_parent().add_child(b)
	_dress(b, col)
	if owner_p.kit is EchoKit:
		b.on_hit = (owner_p.kit as EchoKit)._lamp_hit
	return b

func _echo_shot(from: Vector2, dir: Vector2, dmg: int) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var b := EchoKit.lamp(p, from, dir, p.bullet_speed, dmg, Color(0.85, 0.70, 1.0))
	if _echo_mega:
		b.homing = 220.0
	b.modulate = Color(1, 1, 1, 0.75)

# Эхо удара: через 0,6 с по тому же врагу — ещё половина урона
func _lamp_hit(victim: Node) -> void:
	if not is_instance_valid(p) or not (victim is Player) or not victim.is_alive():
		return
	var v: Player = victim
	var dmg := maxi(1, int(round(p.bullet_damage * 0.5)))
	p._after(0.6, func():
		if is_instance_valid(v) and v.is_alive() and is_instance_valid(p):
			v.take_damage(dmg, p)
			Fx.ring(v.get_parent(), v.hurt_center(), 30.0, Color(Skins.col(p, VIOLET), 0.9), 0.25, 3.0))

# Во время ульты — повторить ещё раз (МЕГА — дважды) с того же места
func _repeat(fn: Callable) -> void:
	if _echo_t <= 0.0:
		return
	p._after(ECHO_DELAY, fn)
	if _echo_mega:
		p._after(ECHO_DELAY * 2.0, fn)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"rift_step":
			var a := p.global_position
			var b := _step(mega)
			_repeat(func(): _shades(mega, a, b))
		"edge_line":
			var at := _edge_spot()
			_place_edge(mega, at)
			_repeat(func(): _place_edge(mega, at + Vector2(p.facing * 90.0, 0)))
		"abyss_pull":
			var c := _pull_spot()
			_pull_at(mega, c)
			_repeat(func(): _pull_at(mega, c))

# ---------- 1. Шаг на изнанку ----------
func _step(mega: bool) -> Vector2:
	var world := p.get_parent()
	var from := p.global_position
	var dx := p.facing * (340.0 if Balance.arena(p) else 300.0)
	for k in 8:
		if not p.test_move(p.global_transform, Vector2(dx, 0)):
			break
		dx *= 0.75
	p._anim("cast")
	p._invuln = maxf(p._invuln, 0.35)
	p.global_position.x = clampf(from.x + dx, 40.0, p.map_w - 40.0)
	p.velocity.y = minf(p.velocity.y, 0.0)
	var to := p.global_position
	var l := Line2D.new()
	l.points = PackedVector2Array([from, to])
	l.width = p.body_size.y * 0.5
	l.default_color = Color(Skins.col(p, VIOLET), 0.45)
	l.z_index = 4
	world.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "modulate:a", 0.0, 0.3)
	t.tween_callback(l.queue_free)
	Util.flash(world, from, 50.0, Color(Skins.col(p, VIOLET), 0.8))
	Util.flash(world, to, 50.0, Color(Skins.col(p, PALE), 0.8))
	_shades(mega, from, to)
	return to

# Тени, которые взрываются (в начале пути; МЕГА — и в конце)
func _shades(mega: bool, a: Vector2, b: Vector2) -> void:
	_shade(a, mega)
	if mega:
		_shade(b, mega)

func _shade(at: Vector2, mega: bool) -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	var arena := Balance.arena(p)
	var r := 140.0 if arena else 110.0
	var dmg := 24 if arena else 18
	var fig := _silhouette(Color(VIOLET, 0.55))
	fig.position = at
	world.add_child(fig)
	Fx.ring(world, at, r, Color(Skins.col(p, VIOLET), 0.6), 0.8, 3.0)
	var who: WeakRef = weakref(p)
	var t := fig.create_tween()
	t.tween_property(fig, "modulate", Color(1.6, 1.3, 2.0, 1.0), 0.8)
	t.tween_callback(func():
		var owner_p: Variant = who.get_ref()
		Fx.ring(world, at, r, Color(Skins.col(p, PALE), 0.95), 0.35, 7.0)
		Fx.sparks(world, at, Skins.col(p, VIOLET), 14, 260.0, 4.0)
		if owner_p != null and is_instance_valid(owner_p):
			for e in (owner_p.kit as EchoKit)._enemies():
				if e.hurt_center().distance_to(at) < r + e.body_size.x * 0.3 and not e.cutscene_shield:
					e.take_damage(dmg, owner_p)
					if mega:
						e.slow(1.5, 0.5)
		fig.queue_free())

# Силуэт героя (тень, эхо)
func _silhouette(c: Color) -> Node2D:
	var n := Node2D.new()
	n.z_index = 3
	var bs := p.body_size
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-bs.x * 0.45, bs.y * 0.5), Vector2(-bs.x * 0.35, -bs.y * 0.15), Vector2(-bs.x * 0.5, -bs.y * 0.3),
			Vector2(0, -bs.y * 0.52), Vector2(bs.x * 0.5, -bs.y * 0.3), Vector2(bs.x * 0.35, -bs.y * 0.15), Vector2(bs.x * 0.45, bs.y * 0.5)])
	body.color = c
	n.add_child(body)
	var eye := Polygon2D.new()
	eye.polygon = Util.circle(2.5, 6)
	eye.position = Vector2(p.facing * bs.x * 0.15, -bs.y * 0.3)
	eye.color = Skins.col(p, PALE)
	n.add_child(eye)
	return n

# ---------- 2. Грань ----------
func _edge_spot() -> Vector2:
	var x := clampf(p.global_position.x + p.facing * 170.0, 60.0, p.map_w - 60.0)
	return Vector2(x, p.global_position.y + p.body_size.y / 2)

func _place_edge(mega: bool, at: Vector2) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	p._anim("cast")
	var e := Edge.new()
	e.owner_p = p
	e.team = p.team
	e.mega = mega
	e.life = 7.0 if Balance.arena(p) else 5.0
	e.position = at
	p.get_parent().add_child(e)
	if _echo_t <= 0.0:
		if is_instance_valid(_edge):
			_edge.close()
		_edge = e

# ---------- 3. Тяга бездны ----------
func _pull_spot() -> Vector2:
	var to := p.global_position + Vector2(p.facing * 380.0, p.body_size.y / 2)
	var bd := 760.0
	for e in _enemies():
		var dx: float = e.global_position.x - p.global_position.x
		if signf(dx) == float(p.facing) and absf(e.global_position.y - p.global_position.y) < 380.0 and absf(dx) < bd \
				and not e.cutscene_shield:
			bd = absf(dx)
			to = e.global_position + Vector2(0, e.body_size.y / 2)
	return to

func _pull_at(mega: bool, c: Vector2) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var world := p.get_parent()
	var arena := Balance.arena(p)
	var r := 240.0 if mega else 170.0
	var dmg := 34 if arena else 26
	p._anim("cast")
	Fx.rune_circle(world, c, r, Color(Skins.col(p, VIOLET), 0.9), 0.5)
	var who: WeakRef = weakref(p)
	p._after(0.5, func():
		var owner_p: Variant = who.get_ref()
		if owner_p == null or not is_instance_valid(owner_p):
			return
		var caught: Array = []
		for e in (owner_p.kit as EchoKit)._enemies():
			if absf(e.global_position.x - c.x) < r and absf(e.global_position.y - c.y) < 260.0 and not e.cutscene_shield:
				caught.append(e)
				if e.stagger_max <= 0.0 and not e.get_meta("kind", "") == "totem":
					e.velocity = Vector2((c.x - e.global_position.x) * 1.2, -780.0)
		Fx.sparks(world, c, Skins.col(p, VIOLET), 18, 320.0, 4.0, true)
		Fx.ring(world, c, r, Color(Skins.col(p, PALE), 0.8), 0.3, 5.0, 0.3)
		owner_p._after(0.55, func():
			if not is_instance_valid(owner_p):
				return
			for e in caught:
				if is_instance_valid(e) and e.is_alive():
					if e.stagger_max <= 0.0:
						e.velocity.y = 1700.0
					e.take_damage(dmg, owner_p)
					if mega:
						e.stun(1.0)
					Fx.sparks(world, e.global_position, Skins.col(p, VIOLET), 8, 220.0, 4.0)
			Fx.shake(world, 5.0)))

# ---------- Ульта: Эхо пути ----------
func ult() -> void:
	_echo_mega = p._mega_ab()
	_echo_t = 8.0 if Balance.arena(p) else 6.0
	_trail.clear()
	p._anim("roar")
	var world := p.get_parent()
	Util.flash(world, p.global_position, 180.0, Color(Skins.col(p, VIOLET), 0.85))
	Fx.ring(world, p.global_position, 200.0, Skins.col(p, PALE), 0.5, 7.0)
	p._float_label("Эхо пути!", Skins.col(p, PALE))
	if is_instance_valid(_fig):
		_fig.queue_free()
	_fig = _silhouette(Color(0.80, 0.62, 1.0, 0.5))
	_fig.top_level = true
	_fig.global_position = p.global_position
	p.add_child(_fig)

func ulting() -> bool:
	return _echo_t > 0.0

func _physics_process(delta: float) -> void:
	if p == null or _echo_t <= 0.0:
		return
	_echo_t -= delta
	var now := Time.get_ticks_msec() / 1000.0
	_trail.append([now, p.global_position])
	while _trail.size() > 2 and float(_trail[1][0]) <= now - ECHO_DELAY:
		_trail.pop_front()
	if is_instance_valid(_fig):
		_fig.global_position = _trail[0][1]
		_fig.scale.x = float(p.facing)
		if randf() < 0.3:
			Fx.sparks(p.get_parent(), _fig.global_position + Vector2(randf_range(-14, 14), randf_range(-30, 20)), Skins.col(p, VIOLET), 1, 60.0, 3.0)
	if _echo_t <= 0.0:
		_end_echo()

func _end_echo() -> void:
	_echo_t = 0.0
	if is_instance_valid(_fig):
		var f := _fig
		var t := f.create_tween()
		t.tween_property(f, "modulate:a", 0.0, 0.3)
		t.tween_callback(f.queue_free)
	_fig = null

func on_death() -> void:
	super()
	_end_echo()
	if is_instance_valid(_edge):
		_edge.close()


# =====================================================================
# Грань: вертикальная линия разлома
class Edge extends Node2D:
	const H := 400.0
	var owner_p: Player
	var team := 0
	var mega := false
	var life := 5.0
	var _seen := {}
	var _crossed := {}
	var _line: Line2D
	var _glow: Polygon2D
	var _t := 0.0
	var _closing := false

	func _ready() -> void:
		z_index = 5
		_glow = Polygon2D.new()
		_glow.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(-6, -H), Vector2(6, -H), Vector2(16, 0)])
		_glow.color = Color(0.72, 0.48, 1.0, 0.22)
		add_child(_glow)
		_line = Line2D.new()
		_line.width = 4.0
		_line.default_color = Color(0.95, 0.88, 1.0, 0.95)
		add_child(_line)
		_shape()
		scale = Vector2(1, 0.05)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

	func _shape() -> void:
		var pts := PackedVector2Array()
		for k in 11:
			pts.append(Vector2(randf_range(-5, 5) if k % 10 != 0 else 0.0, -H * k / 10.0))
		_line.points = pts

	func close() -> void:
		if _closing:
			return
		_closing = true
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(0.1, 1.0), 0.2)
		t.tween_callback(queue_free)

	func _physics_process(delta: float) -> void:
		if _closing:
			return
		life -= delta
		_t += delta
		if fmod(_t, 0.12) < delta:
			_shape()
		_glow.color.a = 0.18 + 0.08 * sin(_t * 9.0)
		if life <= 0.0:
			close()
			return
		var world := get_parent()
		for n in world.get_children():
			if not (n is Bullet) or n.is_queued_for_deletion():
				continue
			var gy: float = n.global_position.y
			if gy < position.y - H or gy > position.y + 10.0:
				continue
			var id := n.get_instance_id()
			var side := signf(n.global_position.x - position.x)
			if _seen.has(id) and side != 0.0 and float(_seen[id]) != side:
				_cross(n)
			_seen[id] = side
		for e in world.get_children():
			if not (e is Player) or e.team == team or not e.is_alive() or e.cutscene_shield:
				continue
			var gy2: float = e.global_position.y
			if gy2 < position.y - H or gy2 > position.y + 40.0:
				continue
			var eid := e.get_instance_id()
			var s2 := signf(e.global_position.x - position.x)
			if _crossed.has(eid) and s2 != 0.0 and float(_crossed[eid]) != s2:
				e.slow(1.6, 0.5)
				if is_instance_valid(owner_p):
					e.take_damage(6, owner_p)
				Fx.sparks(world, e.hurt_center(), Color(0.72, 0.48, 1.0), 6, 160.0, 3.0)
			_crossed[eid] = s2

	func _cross(b: Bullet) -> void:
		if b.has_meta("edge"):
			return
		b.set_meta("edge", true)
		var world := get_parent()
		if b.team == team:
			if not is_instance_valid(owner_p):
				return
			var angles := [-0.16, 0.16] if mega else [0.14]
			for a in angles:
				var c := EchoKit.lamp(owner_p, b.global_position, b.direction.rotated(a), b.speed, maxi(1, int(b.damage * 0.6)))
				c.set_meta("edge", true)
			Util.flash(world, b.global_position, 26.0, Color(0.95, 0.88, 1.0, 0.9))
		elif mega:
			Fx.sparks(world, b.global_position, Color(0.72, 0.48, 1.0), 6, 140.0, 3.0)
			b.queue_free()
		else:
			b.speed *= 0.3
			Util.flash(world, b.global_position, 20.0, Color(0.72, 0.48, 1.0, 0.8))
