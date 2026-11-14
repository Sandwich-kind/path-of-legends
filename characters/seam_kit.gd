class_name SeamKit
extends HeroKit
# ---------- ШОВ — легенда за Странника, поглощённого бездной (103-я волна сложной Арены) ----------
# Девушка, что шла за героем все сто три волны и подбирала осколки всего побеждённого —
# щепу Энта, кость Короля, перо Странника — и сшила из них себя заново. Тело в золотых
# швах, плащ из лоскутов всех земель, оружие — игла-копьё с золотой нитью.
# Оружие «Игла»: иглы летят прямо, каждое 3-е попадание «пришивает» врага к земле (0,6 с).
# 1 «Лоскут прошлого» — комбо: жми ещё раз в течение секунды. 1 — корни Энта опутывают
#   врагов, 2 — молния Владыки Бури, 3 — волны Колосса. МЕГА: ещё 4 — вязкий яд и град
#   костей, 5 — луч с неба, как у Тёмного Лорда. Приёмы боссов — ослабленные.
#   Перезарядка — когда комбо закончилось.
# 2 «Шов» — нить-рельс вперёд: враги, пересекающие её, ранены и замедлены, свои по ней
#   скользят. Арена: держится дольше.
# 3 «Щупальца бездны» — из земли встают щупальца и бьют по области вокруг себя.
#   МЕГА: три вместо двух. Арена: стоят дольше.
# Ульта «Сто три волны» — сама проводит всю серию приёмов боссов, усиленных, и ещё
#   паутину Королевы, пламя Цербера и лёд Ётуна. Копится долго.

const GOLD := Color(1.0, 0.82, 0.35)
const THREAD := Color(1.0, 0.90, 0.55)
const VOID := Color(0.62, 0.30, 0.90)

var _hits := 0
var _combo_step := 0
var _combo_t := 0.0
var _combo_i := 0
var _combo_mega := false
var _ult_t := 0.0

# ---------- Оружие: игла ----------
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
	b.global_position = p.global_position + Vector2(p.facing * 26.0, -12.0)
	if b._vis2:
		var nd := Polygon2D.new()
		nd.polygon = PackedVector2Array([Vector2(-10, -1), Vector2(10, 0), Vector2(-10, 1)])
		nd.color = Skins.col(p, Color(0.85, 0.85, 0.92))
		b._vis2.add_child(nd)
		var eye := Polygon2D.new()
		eye.polygon = Util.circle(1.6, 6)
		eye.position = Vector2(-8, 0)
		eye.color = Skins.col(p, GOLD)
		b._vis2.add_child(eye)
	if b._trail:
		b._trail.width = 2.0
		b._trail.default_color = Color(Skins.col(p, THREAD), 0.8)
	b.on_hit = _needle_hit
	if rapid and p.is_mega("rapid"):
		b.pierce = 2
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

func _needle_hit(v: Node) -> void:
	if not is_instance_valid(p) or not (v is Player) or not v.is_alive():
		return
	_hits += 1
	if _hits % 3 == 0:
		v.root(0.6)
		_stitch(v)

# Золотые стежки на пришитом враге
func _stitch(v: Player) -> void:
	var world := v.get_parent()
	for k in 3:
		var l := Line2D.new()
		var at := v.global_position + Vector2(-16 + k * 16, v.body_size.y * 0.35)
		l.points = PackedVector2Array([at + Vector2(-6, -6), at + Vector2(6, 6)])
		l.width = 2.0
		l.default_color = Skins.col(p, THREAD)
		world.add_child(l)
		var t := l.create_tween()
		t.tween_interval(0.5)
		t.tween_property(l, "modulate:a", 0.0, 0.2)
		t.tween_callback(l.queue_free)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	if ab == "patch_combo":
		if _combo_step > 0:
			_combo_t -= delta
			if Input.is_action_just_pressed(action):
				_combo_next()
			elif _combo_t <= 0.0:
				_combo_end()
			return
		if Input.is_action_just_pressed(action) and p._cd[i] <= 0.0:
			_combo_i = i
			_combo_mega = p._mega_ab()
			_combo_next()
		return
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"patch_combo":
			# бот (или вызов извне) проводит всё комбо сам, с паузами
			for n in (5 if mega else 3):
				p._after(n * 0.7, func(): _strike(n + 1, 1.0))
		"seam_thread":
			_seam(mega)
		"abyss_tentacles":
			_tentacles(mega)

# ----- Лоскут прошлого: комбо -----
func _combo_next() -> void:
	_combo_step += 1
	_strike(_combo_step, 1.0)
	if _combo_step >= (5 if _combo_mega else 3):
		_combo_end()
	else:
		_combo_t = 1.0

func _combo_end() -> void:
	_combo_step = 0
	_combo_t = 0.0
	if _combo_i >= 0 and _combo_i < p._cd.size():
		p._cd[_combo_i] = p.ability_cds[_combo_i]

# Один приём из прошлого. power: 1 — ослабленный (комбо), больше — ульта
func _strike(n: int, power: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var arena := Balance.arena(p)
	var k := power * (1.25 if arena else 1.0)
	p._anim("cast")
	match n:
		1: _p_roots(k)
		2: _p_lightning(k)
		3: _p_waves(k)
		4: _p_poison_bones(k)
		5: _p_sky_beam(k)
		6: _p_web(k)
		7: _p_hellfire(k)
		8: _p_ice(k)

func _ahead(range_x: float) -> Array:
	var res: Array = []
	for e in _enemies():
		if e.cutscene_shield:
			continue
		var dx: float = e.global_position.x - p.global_position.x
		if absf(dx) < range_x and absf(e.global_position.y - p.global_position.y) < 420.0:
			res.append(e)
	res.sort_custom(func(a, b): return absf(a.global_position.x - p.global_position.x) < absf(b.global_position.x - p.global_position.x))
	return res

func _feet(e: Player) -> Vector2:
	return e.global_position + Vector2(0, e.body_size.y / 2)

# 1. Корни Энта
func _p_roots(k: float) -> void:
	var world := p.get_parent()
	var foes := _ahead(560.0 * sqrt(k))
	if foes.is_empty():
		foes = []
	for e in foes.slice(0, int(4 * k)):
		e.root(1.1 * minf(k, 1.6))
		e.take_damage(int(9 * k), p)
		var at := _feet(e)
		for s in 4:
			var r := Polygon2D.new()
			var x := -24.0 + s * 16.0
			r.polygon = PackedVector2Array([Vector2(x - 5, 0), Vector2(x + randf_range(-6, 6), -randf_range(40, 70)), Vector2(x + 5, 0)])
			r.color = Skins.col(p, Color(0.36, 0.26, 0.16))
			r.position = at
			r.z_index = 5
			world.add_child(r)
			var t := r.create_tween()
			t.tween_property(r, "scale", Vector2(1, 1), 0.15).from(Vector2(1, 0.1))
			t.tween_interval(0.9)
			t.tween_property(r, "modulate:a", 0.0, 0.3)
			t.tween_callback(r.queue_free)
	Fx.leaf_burst(world, p.global_position + Vector2(p.facing * 60.0, 0), 10)

# 2. Молния Владыки Бури
func _p_lightning(k: float) -> void:
	var world := p.get_parent()
	for e in _ahead(800.0).slice(0, int(3 * k)):
		var at: Vector2 = e.hurt_center()
		Fx.bolt(world, at + Vector2(randf_range(-40, 40), -700.0), at, Skins.col(p, Color(0.75, 0.9, 1.0)))
		Util.flash(world, at, 50.0, Skins.col(p, Color(0.85, 0.95, 1.0, 0.9)))
		e.take_damage(int(15 * k), p)
	Fx.shake(world, 4.0)

# 3. Волны Колосса
func _p_waves(k: float) -> void:
	var w := SeamWave.new()
	w.owner_p = p
	w.dmg = int(11 * k)
	w.big = k > 1.2
	w.position = Vector2(p.global_position.x, p.global_position.y + p.body_size.y / 2)
	p.get_parent().add_child(w)
	Fx.shake(p.get_parent(), 6.0)

# 4. Вязкий яд и град костей
func _p_poison_bones(k: float) -> void:
	var world := p.get_parent()
	var cx := p.global_position.x + p.facing * 260.0
	var pool := Pool.new()
	pool.owner_p = p
	pool.dps = 5.0 * k
	pool.position = Vector2(cx, p.global_position.y + p.body_size.y / 2)
	pool.width = 260.0 * sqrt(k)
	world.add_child(pool)
	for s in int(6 * k):
		var x := cx + randf_range(-160, 160) * sqrt(k)
		var bone := Polygon2D.new()
		bone.polygon = PackedVector2Array([Vector2(-3, -12), Vector2(3, -12), Vector2(3, 12), Vector2(-3, 12)])
		bone.color = Skins.col(p, Color(0.92, 0.90, 0.80))
		bone.position = Vector2(x, p.global_position.y - 700.0)
		bone.rotation = randf() * TAU
		world.add_child(bone)
		var gy := p.global_position.y + p.body_size.y / 2 - 12.0
		var t := bone.create_tween()
		t.tween_interval(s * 0.07)
		t.tween_property(bone, "position:y", gy, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(func():
			for e in _enemies():
				if e.global_position.distance_to(Vector2(x, gy - 20)) < 70.0:
					e.take_damage(int(7 * k), p)
			Fx.sparks(world, Vector2(x, gy), Skins.col(p, Color(0.92, 0.9, 0.8)), 5, 160.0, 3.0, true))
		t.tween_property(bone, "modulate:a", 0.0, 0.3)
		t.tween_callback(bone.queue_free)

# 5. Луч с неба (как Тёмный Лорд в третьей фазе): идёт по земле вперёд
func _p_sky_beam(k: float) -> void:
	var world := p.get_parent()
	var x0 := p.global_position.x + p.facing * 120.0
	var gy := p.global_position.y + p.body_size.y / 2
	var hit := {}
	for s in 8:
		var x := x0 + p.facing * s * 70.0 * sqrt(k)
		p._after(s * 0.08, func():
			if not is_instance_valid(p):
				return
			var top := Vector2(x, gy - 900.0)
			var bot := Vector2(x, gy)
			LightBeam.draw(world, [[top, bot, 0]], Skins.col(p, Color(1.0, 0.45, 0.25)), 26.0 * minf(k, 1.6), 0.18)
			for e in _enemies():
				var id: int = e.get_instance_id()
				if not hit.has(id) and absf(e.global_position.x - x) < 46.0 + e.body_size.x / 2:
					hit[id] = true
					e.take_damage(int(16 * k), p))
	Fx.shake(world, 7.0)

# 6. Паутина Королевы: все враги рядом вязнут
func _p_web(k: float) -> void:
	var world := p.get_parent()
	for e in _ahead(900.0):
		e.slow(2.0 * k, 0.45, "web")
		e.take_damage(int(5 * k), p)
	Fx.ring(world, p.global_position, 700.0, Skins.col(p, Color(0.95, 0.95, 1.0, 0.7)), 0.5, 4.0)

# 7. Пламя Цербера: конус огня вперёд
func _p_hellfire(k: float) -> void:
	var world := p.get_parent()
	for s in 10:
		var at := p.global_position + Vector2(p.facing * (60.0 + s * 48.0), randf_range(-30, 30))
		p._after(s * 0.03, func(): Fx.sparks(world, at, Skins.col(p, Color(1.0, 0.5, 0.15)), 6, 200.0, 5.0))
	for e in _ahead(560.0):
		if signf(e.global_position.x - p.global_position.x) == float(p.facing):
			e.burn(3.0, 6.0 * k, p)
			e.take_damage(int(8 * k), p)

# 8. Лёд Ётуна: шипы льда под каждым врагом
func _p_ice(k: float) -> void:
	var world := p.get_parent()
	for e in _ahead(900.0):
		var at := _feet(e)
		Fx.rune_circle(world, at, 50.0, Skins.col(p, Color(0.7, 0.9, 1.0, 0.9)), 0.5)
		p._after(0.5, func():
			if is_instance_valid(e) and e.is_alive():
				e.take_damage(int(12 * k), p)
				e.slow(1.5, 0.5)
				e.velocity.y = -420.0
				Fx.sparks(world, at, Skins.col(p, Color(0.8, 0.95, 1.0)), 10, 260.0, 4.0, true))

# ----- Шов: нить-рельс -----
func _seam(mega: bool) -> void:
	var world := p.get_parent()
	p._anim("throw")
	var a := p.global_position + Vector2(p.facing * 20.0, 6.0)
	var reach := 560.0 if not mega else 760.0
	var bx := clampf(a.x + p.facing * reach, 60.0, p.map_w - 60.0)
	var t := SeamThread.new()
	t.owner_p = p
	t.a = a
	t.b = Vector2(bx, a.y)
	t.life = 7.0 if Balance.arena(p) else 5.0
	t.mega = mega
	world.add_child(t)

# ----- Щупальца бездны -----
func _tentacles(mega: bool) -> void:
	var world := p.get_parent()
	p._anim("cast")
	var xs: Array = []
	for e in _ahead(700.0).slice(0, 3 if mega else 2):
		xs.append(e.global_position.x)
	while xs.size() < (3 if mega else 2):
		xs.append(p.global_position.x + p.facing * (180.0 + xs.size() * 200.0))
	var gy := p.global_position.y + p.body_size.y / 2
	for x in xs:
		var hit := p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, gy - 80.0), Vector2(x, gy + 600.0), Layer.WORLD | Layer.FRAME))
		var tc := Tentacle.new()
		Fx.cracks(world, Vector2(clampf(x, 60.0, p.map_w - 60.0), hit["position"].y if not hit.is_empty() else gy), Skins.col(p, Color(0.30, 0.10, 0.45)), 90.0)
		tc.owner_p = p
		tc.life = 8.0 if Balance.arena(p) else 6.0
		tc.position = Vector2(clampf(x, 60.0, p.map_w - 60.0), hit["position"].y if not hit.is_empty() else gy)
		world.add_child(tc)

# ---------- Ульта: Сто три волны ----------
func ult() -> void:
	_ult_t = 4.6
	var world := p.get_parent()
	p._anim("roar")
	p._float_label("Сто три волны!", Skins.col(p, GOLD))
	Util.flash(world, p.global_position, 260.0, Color(Skins.col(p, GOLD), 0.8))
	# за спиной встают тени побеждённых
	for s in 6:
		var sh := Polygon2D.new()
		var w := randf_range(50, 90)
		var h := randf_range(140, 230)
		sh.polygon = PackedVector2Array([Vector2(-w / 2, 0), Vector2(-w * 0.4, -h * 0.7), Vector2(0, -h), Vector2(w * 0.4, -h * 0.7), Vector2(w / 2, 0)])
		sh.color = Skins.col(p, Color(0.40, 0.20, 0.60, 0.35))
		sh.position = p.global_position + Vector2(-p.facing * (60.0 + s * 55.0), p.body_size.y / 2)
		sh.z_index = -3
		world.add_child(sh)
		var t := sh.create_tween()
		t.tween_property(sh, "modulate:a", 1.0, 0.3).from(0.0)
		t.tween_interval(4.0)
		t.tween_property(sh, "modulate:a", 0.0, 0.5)
		t.tween_callback(sh.queue_free)
	for n in 8:
		p._after(0.15 + n * 0.5, func(): _strike(n + 1, 1.9))

func ulting() -> bool:
	return _ult_t > 0.0

func _physics_process(delta: float) -> void:
	if _ult_t > 0.0:
		_ult_t -= delta

func on_death() -> void:
	super()
	_combo_step = 0
	_ult_t = 0.0


# =====================================================================
# Волна Колосса — бежит по земле в обе стороны и бьёт врагов
class SeamWave extends Node2D:
	var owner_p: Player
	var dmg := 10
	var big := false
	var _xs := [0.0, 0.0]
	var _hit := {}
	var _t := 0.0
	var _fins: Array = []

	func _ready() -> void:
		z_index = 4
		for d in [-1.0, 1.0]:
			var f := Polygon2D.new()
			var s := 1.4 if big else 1.0
			f.polygon = PackedVector2Array([Vector2(-d * 30 * s, 0), Vector2(0, -50 * s), Vector2(d * 20 * s, 0)])
			f.color = Color(0.95, 0.75, 0.40, 0.9)
			add_child(f)
			_fins.append(f)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(owner_p) or _t > 1.3:
			queue_free()
			return
		for i in 2:
			var d := -1.0 if i == 0 else 1.0
			_xs[i] = float(_xs[i]) + d * 720.0 * delta
			(_fins[i] as Node2D).position.x = _xs[i]
			if randf() < 0.5:
				Fx.sparks(get_parent(), global_position + Vector2(_xs[i], -4), Color(0.9, 0.75, 0.45), 1, 140.0, 3.0, true)
			for e in owner_p.kit._enemies():
				var id: int = e.get_instance_id()
				var feet: float = e.global_position.y + e.body_size.y / 2
				if not _hit.has(id) and absf(e.global_position.x - (global_position.x + _xs[i])) < 34.0 + e.body_size.x / 2 \
						and absf(feet - global_position.y) < 40.0:
					_hit[id] = true
					e.take_damage(dmg, owner_p)
					e.velocity = Vector2(d * 360.0, -420.0)

# Вязкий яд: лужа травит врагов
class Pool extends Node2D:
	var owner_p: Player
	var dps := 5.0
	var width := 260.0
	var life := 4.0
	var _tick := 0.0
	var _poly: Polygon2D

	func _ready() -> void:
		z_index = 3
		_poly = Polygon2D.new()
		var pts := PackedVector2Array()
		for k in 14:
			var a := PI + PI * k / 13.0
			pts.append(Vector2(cos(a) * width / 2, sin(a) * 14.0))
		_poly.polygon = pts
		_poly.color = Color(0.45, 0.85, 0.25, 0.6)
		add_child(_poly)

	func _physics_process(delta: float) -> void:
		life -= delta
		_poly.color.a = 0.6 * minf(1.0, life)
		_tick -= delta
		if _tick <= 0.0 and is_instance_valid(owner_p):
			_tick = 0.5
			for e in owner_p.kit._enemies():
				var feet: float = e.global_position.y + e.body_size.y / 2
				if absf(e.global_position.x - position.x) < width / 2 and absf(feet - position.y) < 26.0:
					e.poison(2.0, dps)
					e.slow(0.6, 0.6, "mud")
		if life <= 0.0:
			queue_free()

# Шов: золотая нить на уровне пояса. Враг, задевший её, разрезан и замедлен;
# свои, идущие вдоль неё, ускоряются
class SeamThread extends Node2D:
	var owner_p: Player
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var life := 5.0
	var mega := false
	var _line: Line2D
	var _cd := {}
	var _t := 0.0

	func _ready() -> void:
		z_index = 5
		_line = Line2D.new()
		_line.points = PackedVector2Array([a, b])
		_line.width = 3.0
		_line.default_color = Color(1.0, 0.90, 0.55)
		add_child(_line)
		for k in 8:
			var st := Line2D.new()
			var q := a.lerp(b, (k + 0.5) / 8.0)
			st.points = PackedVector2Array([q + Vector2(-4, -6), q + Vector2(4, 6)])
			st.width = 2.0
			st.default_color = Color(1.0, 0.82, 0.35)
			add_child(st)
		var t := _line.create_tween()
		t.tween_method(func(v: float): _line.points = PackedVector2Array([a, a.lerp(b, v)]), 0.0, 1.0, 0.15)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		_line.width = 3.0 + sin(_t * 8.0)
		modulate.a = minf(1.0, life * 2.0)
		if life <= 0.0 or not is_instance_valid(owner_p):
			queue_free()
			return
		var x0 := minf(a.x, b.x)
		var x1 := maxf(a.x, b.x)
		for n in get_parent().get_children():
			if not (n is Player) or not n.is_alive():
				continue
			var half: Vector2 = n.body_size / 2
			if n.global_position.x + half.x < x0 or n.global_position.x - half.x > x1 \
					or absf(n.global_position.y - a.y) > half.y + 6.0:
				continue
			if n.team == owner_p.team:
				if absf(n.velocity.x) > 40.0:
					n._ext_t = 0.12
					n._ext_vx = signf(n.velocity.x) * (200.0 if not mega else 280.0)
				continue
			var id: int = n.get_instance_id()
			_cd[id] = float(_cd.get(id, 0.0)) - delta
			if float(_cd[id]) <= 0.0:
				_cd[id] = 0.7
				n.take_damage(8 if not mega else 12, owner_p)
				n.slow(1.5, 0.5, "water")
				Fx.sparks(get_parent(), Vector2(n.global_position.x, a.y), Color(1.0, 0.85, 0.4), 6, 160.0, 3.0)

# Щупальце бездны: стоит на месте и бьёт по области вокруг себя
class Tentacle extends Node2D:
	var owner_p: Player
	var life := 6.0
	var radius := 150.0
	var _t := 0.0
	var _hit_t := 0.8
	var _line: Line2D
	var _tip: Polygon2D
	var _slam := 0.0

	func _ready() -> void:
		z_index = 4
		_line = Line2D.new()
		_line.width = 22.0
		var g := Curve.new()
		g.add_point(Vector2(0, 1))
		g.add_point(Vector2(1, 0.25))
		_line.width_curve = g
		_line.default_color = Color(0.18, 0.08, 0.26)
		add_child(_line)
		_tip = Polygon2D.new()
		_tip.polygon = Util.circle(5.0, 8)
		_tip.color = Color(0.80, 0.50, 1.0)
		add_child(_tip)
		scale = Vector2(1, 0.1)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		_slam = maxf(0.0, _slam - delta)
		var pts := PackedVector2Array()
		var bend := sin(_t * 3.0) * 30.0
		var down := _slam / 0.3
		for k in 9:
			var q := k / 8.0
			var tip_x := bend * q * q + down * 90.0 * q * q
			pts.append(Vector2(tip_x, -q * (140.0 - down * 100.0)))
		_line.points = pts
		_tip.position = pts[pts.size() - 1]
		_hit_t -= delta
		if _hit_t <= 0.0 and is_instance_valid(owner_p):
			_hit_t = 1.1
			_slam = 0.3
			Fx.ring(get_parent(), position, radius, Color(0.75, 0.40, 1.0, 0.8), 0.3, 5.0, 0.3)
			for e in owner_p.kit._enemies():
				if e.global_position.distance_to(position + Vector2(0, -40)) < radius + e.body_size.x * 0.3:
					e.take_damage(9, owner_p)
					e.velocity = Vector2(signf(e.global_position.x - position.x) * 260.0, -300.0)
		if life <= 0.0:
			var t := create_tween()
			t.tween_property(self, "scale", Vector2(1, 0.05), 0.2)
			t.tween_callback(queue_free)
			set_physics_process(false)
