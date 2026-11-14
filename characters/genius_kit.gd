class_name GeniusKit
extends HeroKit
# ---------- НЕДОПОНЯТЫЙ ГЕНИЙ — легенда из Лавки (персонаж друга автора игры) ----------
# Ниндзя-самурай-сисадмин: тёмно-фиолетовое ги с тёмно-красными лацканами и наплечниками,
# пояс из Ethernet-кабеля, бейдж охраны на шнурке, гарнитура, катана с вилкой RJ-45 за
# спиной. Немного безумия — по ги бегут зелёные «строчки терминала».
# Оружие «Флешки с Arch Linux»: летят как кинжалы — прямо и быстро. Обойма 8.
# 1 «Ethernet-кнут» — хлещет кабелем вперёд: попавший ранен, замедлен, и у него на
#   0,7 с сбито управление (идёт не туда и не может стрелять; боссы — 0,3 с).
#   МЕГА: кнут длиннее, бьёт всех на линии, сбивает на 1 с.
# 2 «Пингвин-турель» — забрасывает хрупкую турель-пингвина поближе к врагам. Она
#   стреляет обычными снарядами, ломается от чужих попаданий, работает недолго —
#   и эффектно взрывается напоследок. МЕГА: стреляет очередями по два, живёт дольше,
#   взрыв больше.
# 3 «Перегазрука» — замирает на 2 с, разгоняя себя. Если за это время по нему не
#   попали — восстанавливает 10% здоровья (МЕГА — 13%; на Арене 25% и 30%, откат там
#   короче — см. Balance.DUEL). Если попали —
#   не лечит, а сбрасывает перегрев волной: отбрасывает и ранит всех рядом.
# Ульта «Перестройка» — бросает во врагов серверную стойку. Кто не успел уйти из зоны —
#   застывает и каждые полсекунды теряет 5% здоровья (боссы не застывают и теряют по
#   1,2%). Союзники в зоне ускоряются и понемногу лечатся. В конце в стойку влетает
#   дрон — и она взрывается. МЕГА: зона больше, держится дольше, взрыв сильнее.

const DARK_RED := Color(0.55, 0.08, 0.14)
const VIOLET := Color(0.62, 0.28, 0.82)
const CABLE := Color(0.25, 0.55, 0.95)
const TERM := Color(0.40, 1.0, 0.45)
const G := 1400.0

var _oc_t := 0.0
var _oc_hit := false
var _oc_hp := 0
var _oc_mega := false
var _oc_fx: Node2D

# ---------- Оружие: флешки ----------
func weapon(delta: float, shoot: bool) -> void:
	var rapid := p.has_buff("rapid")
	if _oc_t > 0.0:
		return
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
	var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, randf_range(-0.02, 0.02))
	b.restyle("usb")
	p._anim("throw")
	if rapid and p.is_mega("rapid"):
		b.pierce = 2
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

# ---------- Способности ----------
func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"ether_whip":
			_whip(mega)
		"penguin_turret":
			_turret(mega)
		"overclock":
			_overclock(mega)

# Точка поближе к врагам: ближайший враг впереди (или просто вперёд)
func _toss_target(reach: float) -> Vector2:
	var best: Player = null
	var bd := reach
	for e in _enemies():
		var d: float = absf(e.global_position.x - p.global_position.x)
		if d < bd and absf(e.global_position.y - p.global_position.y) < 400.0:
			bd = d
			best = e
	if best:
		return best.global_position + Vector2(-p.facing * 30.0, best.body_size.y / 2)
	return p.global_position + Vector2(p.facing * 380.0, p.body_size.y / 2)

static func lob(from: Vector2, to: Vector2) -> Vector2:
	var t := clampf(from.distance_to(to) / 700.0, 0.45, 1.0)
	return Vector2((to.x - from.x) / t, (to.y - from.y) / t - 0.5 * G * t)

# ----- 1. Ethernet-кнут -----
func _whip(mega: bool) -> void:
	var world := p.get_parent()
	p._anim("punch")
	var reach := 360.0 if mega else 280.0
	var from := p.global_position + Vector2(p.facing * 14.0, -10.0)
	var hits: Array = []
	for e in _enemies():
		var dx: float = (e.global_position.x - p.global_position.x) * p.facing
		if dx > 0.0 and dx < reach + e.body_size.x / 2 and absf(e.global_position.y - p.global_position.y) < 50.0 + e.body_size.y / 2 \
				and not e.cutscene_shield:
			hits.append(e)
	hits.sort_custom(func(a, b): return absf(a.global_position.x - p.global_position.x) < absf(b.global_position.x - p.global_position.x))
	if not mega:
		hits = hits.slice(0, 1)
	var end := from + Vector2(p.facing * reach, 0)
	if not hits.is_empty() and not mega:
		end = Vector2(hits[0].global_position.x, from.y)
	# кабель хлещет волной, на конце — вилка RJ-45
	var cable := Line2D.new()
	cable.width = 4.0
	cable.default_color = Skins.col(p, CABLE)
	cable.z_index = 6
	world.add_child(cable)
	var plug := Polygon2D.new()
	plug.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(6, -4), Vector2(6, 4), Vector2(-4, 4)])
	plug.color = Color(0.85, 0.90, 0.95, 0.9)
	plug.z_index = 6
	world.add_child(plug)
	var tw := cable.create_tween()
	tw.tween_method(func(v: float):
		if not is_instance_valid(plug):
			return
		var pts := PackedVector2Array()
		for k in 13:
			var q := k / 12.0 * v
			pts.append(from.lerp(end, q) + Vector2(0, sin(q * 14.0 - v * 8.0) * 14.0 * (1.0 - q)))
		cable.points = pts
		plug.position = pts[pts.size() - 1], 0.0, 1.0, 0.14)
	tw.tween_interval(0.12)
	tw.tween_property(cable, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		cable.queue_free()
		if is_instance_valid(plug):
			plug.queue_free())
	var glitch := 1.0 if mega else 0.7
	for e in hits:
		e.take_damage(12, p)
		e.slow(1.5, 0.6, "water")
		e.glitch_t = maxf(e.glitch_t, 0.3 if e.stagger_max > 0.0 else glitch)
		_glitch_fx(e, 0.3 if e.stagger_max > 0.0 else glitch)
		e._float_label("ERR: no route to host", TERM)

# Сбитое управление видно: по врагу мелькают цветные «битые пиксели»
func _glitch_fx(e: Player, t: float) -> void:
	var n := Node2D.new()
	n.z_index = 4
	e.add_child(n)
	for k in 6:
		var r := Polygon2D.new()
		var w := randf_range(6, 16)
		r.polygon = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 3), Vector2(0, 3)])
		r.color = [Color(1.0, 0.2, 0.4, 0.8), TERM, Color(0.3, 0.6, 1.0, 0.8)][k % 3]
		n.add_child(r)
	var tw := n.create_tween()
	for s in int(t / 0.08):
		tw.tween_callback(func():
			for c in n.get_children():
				(c as Node2D).position = Vector2(randf_range(-e.body_size.x * 0.6, e.body_size.x * 0.3), randf_range(-e.body_size.y * 0.5, e.body_size.y * 0.4)))
		tw.tween_interval(0.08)
	tw.tween_callback(n.queue_free)

# ----- 2. Пингвин-турель -----
func _turret(mega: bool) -> void:
	p._anim("throw")
	var t := PenguinTurret.new()
	t.owner_p = p
	t.mega = mega
	t.life = (6.0 if mega else 4.5) + (1.0 if Balance.arena(p) else 0.0)
	t.position = p.global_position + Vector2(p.facing * 16.0, -20.0)
	t.vel = lob(t.position, _toss_target(720.0))
	p.get_parent().add_child(t)

# ----- 3. Перегазрука -----
func _overclock(mega: bool) -> void:
	_oc_t = 2.0
	_oc_hit = false
	_oc_hp = p.hp
	_oc_mega = mega
	p._forced_time = 2.0
	p._forced_vx = 0.0
	p._anim("cast")
	p._float_label("Перегазрука…", Skins.col(p, VIOLET).lightened(0.3))
	_oc_fx = Node2D.new()
	_oc_fx.z_index = 5
	var ring := Line2D.new()
	ring.name = "Ring"
	ring.width = 4.0
	ring.default_color = Skins.col(p, VIOLET)
	_oc_fx.add_child(ring)
	for k in 3:                                    # лопасти кулера крутятся над головой
		var bl := Polygon2D.new()
		bl.polygon = PackedVector2Array([Vector2(0, -2), Vector2(14, -4), Vector2(14, 4), Vector2(0, 2)])
		bl.color = Color(0.85, 0.85, 0.95, 0.85)
		bl.rotation = TAU * k / 3.0
		bl.name = "Fan%d" % k
		_oc_fx.add_child(bl)
	p.add_child(_oc_fx)
	_oc_fx.position = Vector2(0, -p.body_size.y / 2 - 22)

func _overclock_tick(delta: float) -> void:
	_oc_t -= delta
	p._forced_time = maxf(p._forced_time, 0.05)
	p._forced_vx = 0.0
	if p.hp < _oc_hp:
		_oc_hit = true
	_oc_hp = p.hp
	if is_instance_valid(_oc_fx):
		var k := 1.0 - _oc_t / 2.0
		var pts := PackedVector2Array()
		for i in int(k * 24.0) + 1:
			var a := -PI / 2 + TAU * i / 24.0
			pts.append(Vector2(cos(a), sin(a)) * 16.0)
		(_oc_fx.get_node("Ring") as Line2D).points = pts
		(_oc_fx.get_node("Ring") as Line2D).default_color = Color(1.0, 0.3, 0.3) if _oc_hit else Skins.col(p, VIOLET)
		for i in 3:
			(_oc_fx.get_node("Fan%d" % i) as Node2D).rotation += delta * (18.0 + k * 30.0)
	if randf() < 0.3:
		Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-14, 14), -p.body_size.y * 0.3), Skins.col(p, TERM), 1, 90.0, 3.0, true)
	if _oc_t <= 0.0:
		_end_overclock()

func _end_overclock() -> void:
	_oc_t = 0.0
	if is_instance_valid(_oc_fx):
		_oc_fx.queue_free()
	var world := p.get_parent()
	if not _oc_hit:
		# в Дуэли лечит вдвое скромнее (против живого соперника 20% каждые несколько секунд — слишком много)
		var part := ((0.25 if _oc_mega else 0.20) + 0.05) if Balance.arena(p) else (0.13 if _oc_mega else 0.10)
		p.heal(int(p.max_hp * part))
		p._float_label("Разгон успешен! +%d%%" % int(part * 100), TERM)
		Fx.ring(world, p.global_position, 70.0, Color(TERM, 0.9), 0.4, 5.0)
		Fx.sparks(world, p.global_position, TERM, 14, 200.0, 3.5, true)
		return
	# не вышло: перегрев сбрасывается волной
	p._float_label("Перегрев!", Color(1.0, 0.4, 0.3))
	var r := 190.0 if _oc_mega else 160.0
	Fx.ring(world, p.global_position, r, Color(1.0, 0.45, 0.3, 0.9), 0.35, 8.0)
	Util.flash(world, p.global_position, r * 0.6, Color(1.0, 0.6, 0.4, 0.6))
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if to.length() < r + e.body_size.x * 0.4:
			e.take_damage(14 if not _oc_mega else 20, p)
			if e.stagger_max <= 0.0:
				e.velocity = Vector2(signf(to.x) * 620.0, -360.0)
				if _oc_mega:
					e.stun(0.5)

func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	if _oc_t > 0.0:
		_overclock_tick(delta)

# ---------- Ульта: Перестройка ----------
func ult() -> void:
	var mega := p._mega_ab()
	p._anim("throw")
	p._float_label("Перестройка!", Skins.col(p, DARK_RED).lightened(0.4))
	var rack := ServerRack.new()
	rack.owner_p = p
	rack.mega = mega
	rack.dur = (5.0 if mega else 4.0) + (1.0 if Balance.arena(p) else 0.0)
	rack.radius = 230.0 if mega else 180.0
	rack.position = p.global_position + Vector2(p.facing * 16.0, -40.0)
	var to := _toss_target(900.0)
	rack.vel = lob(rack.position, to)
	rack.aim = to
	p.get_parent().add_child(rack)

func on_death() -> void:
	super()
	if _oc_t > 0.0:
		_oc_t = 0.0
		if is_instance_valid(_oc_fx):
			_oc_fx.queue_free()


# =====================================================================
# Пингвин-турель: летит по дуге, встаёт, стреляет; хрупкая — ломается от чужих
# попаданий; в конце эффектно взрывается
class PenguinTurret extends Node2D:
	var owner_p: Player
	var mega := false
	var life := 4.5
	var vel := Vector2.ZERO
	var hp := 45
	var _state := "fly"
	var _shoot_t := 0.4
	var _t := 0.0
	var _beak: Polygon2D
	var _eye: Polygon2D

	func _ready() -> void:
		z_index = 5
		var body := Polygon2D.new()
		body.polygon = Util.circle(14.0, 14)
		body.scale = Vector2(0.9, 1.25)
		body.position = Vector2(0, -18)
		body.color = Color(0.10, 0.10, 0.14)
		add_child(body)
		var belly := Polygon2D.new()
		belly.polygon = Util.circle(9.0, 12)
		belly.scale = Vector2(0.8, 1.1)
		belly.position = Vector2(2, -15)
		belly.color = Color(0.95, 0.95, 0.98)
		add_child(belly)
		var visor := Polygon2D.new()                         # робо-визор с красным светодиодом
		visor.polygon = PackedVector2Array([Vector2(-6, -36), Vector2(9, -36), Vector2(9, -31), Vector2(-6, -31)])
		visor.color = Color(0.20, 0.22, 0.30)
		add_child(visor)
		_eye = Polygon2D.new()
		_eye.polygon = Util.circle(2.0, 6)
		_eye.position = Vector2(5, -33.5)
		_eye.color = Color(1.0, 0.2, 0.25)
		add_child(_eye)
		_beak = Polygon2D.new()                              # клюв-ствол
		_beak.polygon = PackedVector2Array([Vector2(0, -3), Vector2(16, -2), Vector2(16, 2), Vector2(0, 3)])
		_beak.position = Vector2(8, -27)
		_beak.color = Color(1.0, 0.55, 0.15)
		add_child(_beak)
		var ant := Line2D.new()                              # антенна
		ant.points = PackedVector2Array([Vector2(-2, -40), Vector2(-4, -50)])
		ant.width = 1.5
		ant.default_color = Color(0.7, 0.7, 0.75)
		add_child(ant)
		for x in [-8.0, 8.0]:                                # колёсики
			var w := Polygon2D.new()
			w.polygon = Util.circle(3.5, 8)
			w.position = Vector2(x, -2)
			w.color = Color(0.25, 0.25, 0.30)
			add_child(w)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(owner_p):
			queue_free()
			return
		match _state:
			"fly":
				var from := position
				vel.y += GeniusKit.G * delta
				position += vel * delta
				rotation += delta * 9.0
				var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, position + Vector2(0, 2), Layer.WORLD | Layer.FRAME))
				if not hit.is_empty() or _t > 2.5:
					if not hit.is_empty():
						position = hit["position"]
					rotation = 0.0
					_state = "work"
					_t = 0.0
					Fx.sparks(get_parent(), position, Color(0.8, 0.85, 0.95), 8, 160.0, 3.0, true)
			"work":
				_eye.visible = fmod(_t, 0.4) < 0.25
				_soak()
				var tgt := _target()
				if tgt:
					var d: Vector2 = tgt.hurt_center() - (global_position + Vector2(8, -27))
					_beak.rotation = clampf(d.angle() if d.x >= 0 else PI - d.angle(), -0.8, 0.8)
					scale.x = 1.0 if d.x >= 0 else -1.0
				_shoot_t -= delta
				if _shoot_t <= 0.0 and tgt:
					_shoot_t = 0.35
					_fire(tgt, 0.0)
					if mega:
						_fire(tgt, 0.12)
				if _t >= life or hp <= 0:
					_explode()

	func _target() -> Player:
		var best: Player = null
		var bd := 650.0
		for e in owner_p.kit._enemies():
			var d: float = e.global_position.distance_to(global_position)
			if d < bd and not e.cutscene_shield:
				bd = d
				best = e
		return best

	func _fire(t: Player, spread: float) -> void:
		var b := Bullet.new()
		b.shooter = owner_p
		b.team = owner_p.team
		b.speed = 900.0
		b.damage = 6
		b.size = 7.0
		b.color = Color(1.0, 0.6, 0.2)
		var from := global_position + Vector2(scale.x * 22.0, -27)
		b.direction = (t.hurt_center() - from).normalized().rotated(spread)
		b.position = from
		get_parent().add_child(b)

	# хрупкая: чужие снаряды, попавшие в неё, ломают её
	func _soak() -> void:
		for n in get_parent().get_children():
			if n is Bullet and n.team != owner_p.team and not n.is_queued_for_deletion() \
					and n.global_position.distance_to(global_position + Vector2(0, -20)) < 22.0:
				hp -= int(n.damage)
				n.queue_free()
				Fx.sparks(get_parent(), global_position + Vector2(0, -20), Color(1.0, 0.8, 0.5), 4, 140.0, 3.0)
				modulate = Color(1.6, 1.0, 1.0)
				create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)

	func _explode() -> void:
		var world := get_parent()
		var at := global_position + Vector2(0, -18)
		var r := 180.0 if mega else 140.0
		Util.flash(world, at, r * 0.7, Color(1.0, 0.7, 0.3, 0.9))
		Fx.ring(world, at, r, Color(1.0, 0.55, 0.2, 0.9), 0.4, 8.0)
		Fx.sparks(world, at, Color(1.0, 0.6, 0.2), 22, 360.0, 5.0)
		Fx.shake(world, 7.0)
		for k in 5:                                          # разлетаются детали пингвина
			var part := Polygon2D.new()
			part.polygon = PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)])
			part.color = [Color(0.1, 0.1, 0.14), Color(0.95, 0.95, 0.98), Color(1.0, 0.55, 0.15)][k % 3]
			part.position = at
			world.add_child(part)
			var tw := part.create_tween().set_parallel(true)
			tw.tween_property(part, "position", at + Vector2(randf_range(-110, 110), randf_range(-120, 20)), 0.5)
			tw.tween_property(part, "rotation", randf_range(-8, 8), 0.5)
			tw.chain().tween_property(part, "modulate:a", 0.0, 0.25)
			tw.chain().tween_callback(part.queue_free)
		for e in owner_p.kit._enemies():
			var to: Vector2 = e.hurt_center() - at
			if to.length() < r + e.body_size.x * 0.4:
				e.take_damage(45 if mega else 30, owner_p)
				if e.stagger_max <= 0.0:
					e.velocity = to.normalized() * 480.0 + Vector2(0, -300)
		queue_free()

# Серверная стойка: летит во врагов, зона «Перестройки», в конце в неё влетает дрон — взрыв
class ServerRack extends Node2D:
	var owner_p: Player
	var mega := false
	var dur := 4.0
	var radius := 180.0
	var vel := Vector2.ZERO
	var aim := Vector2.ZERO
	var _state := "fly"
	var _t := 0.0
	var _tick := 0.0
	var _caught: Array = []
	var _leds: Array = []
	var _zone: Line2D
	var _warn: Line2D
	var _tethers: Array = []

	func _ready() -> void:
		z_index = 5
		var box := Polygon2D.new()
		box.polygon = PackedVector2Array([Vector2(-22, -86), Vector2(22, -86), Vector2(22, 0), Vector2(-22, 0)])
		box.color = Color(0.10, 0.09, 0.12)
		add_child(box)
		var rim := Line2D.new()
		rim.points = PackedVector2Array([Vector2(-22, -86), Vector2(22, -86), Vector2(22, 0), Vector2(-22, 0), Vector2(-22, -86)])
		rim.width = 2.0
		rim.default_color = Skins.col(owner_p, GeniusKit.DARK_RED)
		add_child(rim)
		for k in 7:                                           # юниты серверов со светодиодами
			var u := Polygon2D.new()
			var y := -80.0 + k * 11.0
			u.polygon = PackedVector2Array([Vector2(-18, y), Vector2(18, y), Vector2(18, y + 8), Vector2(-18, y + 8)])
			u.color = Color(0.20, 0.19, 0.24)
			add_child(u)
			for j in 3:
				var led := Polygon2D.new()
				led.polygon = PackedVector2Array([Vector2(0, 0), Vector2(2.5, 0), Vector2(2.5, 2.5), Vector2(0, 2.5)])
				led.position = Vector2(8 + j * 3.5, y + 2.5)
				led.color = [GeniusKit.TERM, Color(1.0, 0.75, 0.2), Color(0.3, 0.6, 1.0)][j]
				add_child(led)
				_leds.append(led)
		for k in 3:                                           # торчащие кабели
			var c := Line2D.new()
			c.points = PackedVector2Array([Vector2(-22, -70 + k * 20), Vector2(-34, -60 + k * 22), Vector2(-30, -48 + k * 22)])
			c.width = 2.0
			c.default_color = [GeniusKit.CABLE, Color(0.9, 0.3, 0.3), Color(0.95, 0.85, 0.3)][k]
			add_child(c)
		# предупреждение: куда упадёт
		_warn = _ellipse(radius, Color(1.0, 0.3, 0.3, 0.85), 4.0)
		_warn.top_level = true
		_warn.global_position = aim
		add_child(_warn)

	func _ellipse(r: float, c: Color, w: float) -> Line2D:
		var l := Line2D.new()
		var pts := PackedVector2Array()
		for k in 33:
			var a := TAU * k / 32.0
			pts.append(Vector2(cos(a) * r, sin(a) * r * 0.3))
		l.points = pts
		l.width = w
		l.default_color = c
		return l

	func _physics_process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(owner_p):
			queue_free()
			return
		match _state:
			"fly":
				var from := position
				vel.y += GeniusKit.G * delta
				position += vel * delta
				rotation = clampf(vel.x * 0.0006, -0.4, 0.4)
				var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, position + Vector2(0, 2), Layer.WORLD | Layer.FRAME))
				if not hit.is_empty() or _t > 2.5:
					if not hit.is_empty():
						position = hit["position"]
					_land()
			"zone":
				for led in _leds:
					(led as Polygon2D).visible = randf() < 0.7
				_zone.width = 4.0 + sin(_t * 10.0) * 1.5
				for i in _tethers.size():
					var pair: Array = _tethers[i]
					var e: Variant = pair[0]
					if is_instance_valid(e) and is_instance_valid(pair[1]):
						(pair[1] as Line2D).points = PackedVector2Array([Vector2(0, -60), to_local(e.hurt_center())])
				_tick -= delta
				if _tick <= 0.0:
					_tick = 0.5
					_pulse()
				if _t >= dur:
					_drone()

	func _land() -> void:
		_state = "zone"
		_t = 0.0
		rotation = 0.0
		if is_instance_valid(_warn):
			_warn.queue_free()
		var world := get_parent()
		Fx.shake(world, 9.0)
		Fx.sparks(world, position, Color(0.85, 0.85, 0.95), 18, 300.0, 5.0, true)
		Fx.cracks(world, position, Color(0.20, 0.15, 0.20), 120.0)
		_zone = _ellipse(radius, Skins.col(owner_p, GeniusKit.VIOLET), 4.0)
		add_child(_zone)
		for e in owner_p.kit._enemies():
			if _inside(e):
				e.take_damage(20, owner_p)
				if e.stagger_max <= 0.0:
					_caught.append(e)
					e.root(dur)
					e.set_tint(Color(0.85, 0.75, 1.2))
					var tl := Line2D.new()
					tl.width = 2.0
					tl.default_color = Color(Skins.col(owner_p, GeniusKit.CABLE), 0.8)
					add_child(tl)
					_tethers.append([e, tl])
				else:
					e.slow(dur, 0.5, "water")

	func _inside(n: Player) -> bool:
		var d: Vector2 = n.global_position + Vector2(0, n.body_size.y / 2) - global_position
		return absf(d.x) < radius + n.body_size.x * 0.3 and absf(d.y) < 120.0

	func _pulse() -> void:
		var world := get_parent()
		Fx.ring(world, global_position + Vector2(0, -10), radius * 0.8, Color(Skins.col(owner_p, GeniusKit.VIOLET), 0.6), 0.3, 3.0, 0.3)
		var arena := Balance.arena(owner_p)
		for e in owner_p.kit._enemies():
			if _inside(e):
				var part := 0.012 if e.stagger_max > 0.0 else 0.05
				e.take_damage(clampi(int(e.max_hp * part), 3, 60 if not arena else 90), owner_p)
				Fx.sparks(world, e.hurt_center(), GeniusKit.TERM, 3, 120.0, 3.0)
		for n in world.get_children():
			if n is Player and n.team == owner_p.team and n.is_alive() and _inside(n):
				n.heal(maxi(2, int(n.max_hp * 0.03)))
				n.buffs["speed"] = {"t": 1.0, "mega": false}

	# дрон влетает в стойку — взрыв
	func _drone() -> void:
		_state = "boom"
		var world := get_parent()
		var dr := Polygon2D.new()
		dr.polygon = PackedVector2Array([Vector2(-10, -3), Vector2(10, -3), Vector2(12, 0), Vector2(10, 3), Vector2(-10, 3)])
		dr.color = Color(0.30, 0.30, 0.36)
		for x in [-12.0, 12.0]:
			var rot := Line2D.new()
			rot.points = PackedVector2Array([Vector2(x - 6, -5), Vector2(x + 6, -5)])
			rot.width = 2.0
			rot.default_color = Color(0.8, 0.8, 0.85)
			dr.add_child(rot)
		var led := Polygon2D.new()
		led.polygon = Util.circle(2.0, 6)
		led.color = Color(1.0, 0.2, 0.2)
		dr.add_child(led)
		dr.z_index = 7
		var start := global_position + Vector2(-owner_p.facing * 420.0, -380.0)
		dr.global_position = start
		world.add_child(dr)
		var tw := dr.create_tween()
		tw.tween_property(dr, "global_position", global_position + Vector2(0, -50), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			dr.queue_free()
			_blast())

	func _blast() -> void:
		if not is_instance_valid(owner_p):
			queue_free()
			return
		var world := get_parent()
		var at := global_position + Vector2(0, -40)
		var r := radius + 20.0
		Util.flash(world, at, r * 0.8, Color(1.0, 0.65, 0.35, 0.95))
		Fx.ring(world, at, r, Color(Skins.col(owner_p, GeniusKit.DARK_RED), 0.95), 0.45, 10.0)
		Fx.sparks(world, at, Color(1.0, 0.6, 0.25), 30, 420.0, 6.0)
		Fx.shake(world, 12.0)
		for e in owner_p.kit._enemies():
			var to: Vector2 = e.hurt_center() - at
			if to.length() < r + e.body_size.x * 0.4:
				e.take_damage(int((60 if mega else 45) * (1.25 if Balance.arena(owner_p) else 1.0)), owner_p)
				if e.stagger_max <= 0.0:
					e.velocity = to.normalized() * 520.0 + Vector2(0, -360)
		for e in _caught:
			if is_instance_valid(e):
				e.set_tint(Color.WHITE)
				e._root_t = 0.0
		queue_free()
