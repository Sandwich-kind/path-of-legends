class_name RiftAbilities
# ---------- Способности свиты Странника (волны 81–90) ----------
# Вызываются из Player._bot_try, если способность не нашлась у других наборов.
#
# Общая механика — «Метка разлома»: многие удары свиты оставляют на герое осколок-метку
# (до трёх кружат над головой). Третья метка схлопывается: удар силой разлома и
# короткое оцепенение. Метки гаснут, если 5 секунд не получать новых.
#
#   Отрёкшийся:        rift_step   — над землёй за спиной героя раскрывается щель, через миг
#                                    он выходит из неё и рубит (метка);
#   Стрелок разлома:   rift_bolt   — болт с меткой; pin_volley — три прицельных линии, потом залп;
#   Призывательница:   void_orb    — медленная сфера с доводкой (метка); open_rift — разлом
#                                    на земле выпускает порождений; veil — щит союзнику;
#   Разрыватель:       void_grasp  — длань летит по земле, схватив — подтягивает (метка);
#                      gravity_slam — удар оземь: воронка тянет к себе и жжёт;
#   Око разлома:       gaze        — тонкий луч-прицел ведёт героя, потом бьёт луч;
#   Носитель осколка:  shard_burst — осколки взлетают и падают в отмеченные круги;
#   Пустокрыл и Предвестник — см. RiftBrain (здесь только вызов).

const MARK_DMG := 18
const MARK_TIME := 5.0

static func brain(p: Player) -> RiftBrain:
	return p.get_node_or_null("RiftBrain") as RiftBrain

static func _foes(p: Player) -> Array:
	var res: Array = []
	for n in p.get_parent().get_children():
		if n is Player and n.team != p.team and n.is_alive() and not n.cutscene_shield:
			res.append(n)
	return res

static func _ground(p: Node2D, at: Vector2) -> float:
	var hit := p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			at + Vector2(0, -40), at + Vector2(0, 1400), Layer.WORLD | Layer.FRAME))
	return hit["position"].y if not hit.is_empty() else Colosseum.FLOOR_Y

static func try(p: Player, ab: String, to: Vector2) -> bool:
	var d := absf(to.x)
	var world := p.get_parent()
	var has_t: bool = is_instance_valid(p.target) and p.target.is_alive()
	match ab:
		"rift_step":
			if has_t and to.length() < 950.0 and to.length() > 140.0 and absf(to.y) < 200.0:
				_rift_step(p)
				return true
		"rift_bolt":
			if has_t and to.length() < 1150.0 and absf(to.y) < 320.0:
				p._anim("shoot")
				if p.rig and "hold_aim" in p.rig:
					p.rig.hold_aim = 1.0
					p._after(0.4, func():
						if is_instance_valid(p) and p.rig:
							p.rig.hold_aim = 0.0)
				var from := _muzzle(p)
				bolt(p, from, (p.target.global_position - from).normalized(), 1050.0, 9)
				return true
		"pin_volley":
			if has_t and to.length() < 1100.0:
				_pin_volley(p)
				return true
		"void_orb":
			if has_t and to.length() < 1000.0:
				p._anim("cast")
				var from2 := _muzzle(p)
				var b := bolt(p, from2, (p.target.global_position - from2).normalized(), 300.0, 8, 15.0)
				b.homing = 420.0
				b.set("_life", 4.5)
				return true
		"open_rift":
			if p.summon.is_valid():
				_open_rift(p)
				return true
		"veil":
			return _veil(p)
		"void_grasp":
			if has_t and d > 140.0 and d < 680.0 and absf(to.y) < 150.0 and p.is_on_floor():
				_grasp(p)
				return true
		"gravity_slam":
			if has_t and d < 320.0 and absf(to.y) < 140.0 and p.is_on_floor():
				_gravity_slam(p)
				return true
		"gaze":
			var be := brain(p)
			if be and has_t and to.length() < 1000.0:
				be.start_gaze()
				return true
		"shard_burst":
			if has_t and to.length() < 1100.0:
				_shard_burst(p)
				return true
		# ----- Пустокрыл и Предвестник: всё делает мозг -----
		"void_rain", "swoop", "wing_gust", "sky_rift", "tail_beam", \
		"glaive_combo", "rift_cut", "phase_step", "mark_storm", "harvest", "shard_rain", "void_well", "mirror_cuts", "collapse":
			var bb := brain(p)
			return bb != null and bb.use(ab, to)
	return false

static func _muzzle(p: Player) -> Vector2:
	if p.rig and p.rig.has_method("muzzle"):
		return p.rig.muzzle()
	return p.global_position + Vector2(p.facing * 20, -10)

# ---------- Метка разлома ----------
static func mark(target, by, n := 1) -> void:
	if not (target is Player) or not is_instance_valid(target) or not target.is_alive():
		return
	if by is Player and target.team == by.team:
		return
	var fx := target.get_node_or_null("RiftMarks") as MarkFx
	if fx == null:
		fx = MarkFx.new()
		fx.name = "RiftMarks"
		target.add_child(fx)
	fx.add(n, by)

static func marks(target) -> int:
	if not (target is Player) or not is_instance_valid(target):
		return 0
	var fx := target.get_node_or_null("RiftMarks") as MarkFx
	return fx.count if fx else 0

# Забирает метки (Жатва Предвестника): возвращает, сколько было
static func take_marks(target) -> int:
	var fx := target.get_node_or_null("RiftMarks") as MarkFx if is_instance_valid(target) else null
	if fx == null:
		return 0
	var c := fx.count
	fx.clear()
	return c

class MarkFx extends Node2D:
	var count := 0
	var _left := 0.0
	var _by = null
	var _shards: Array = []
	var _t := 0.0
	var _boom := -1.0

	func _ready() -> void:
		z_index = 12
		for k in 3:
			var s := Polygon2D.new()
			s.polygon = PackedVector2Array([Vector2(0, -9), Vector2(4, 0), Vector2(0, 7), Vector2(-4, 0)])
			s.color = RiftRig.GLOW
			s.visible = false
			var core := Polygon2D.new()
			core.polygon = PackedVector2Array([Vector2(0, -4), Vector2(1.6, 0), Vector2(0, 3), Vector2(-1.6, 0)])
			core.color = RiftRig.CORE
			s.add_child(core)
			add_child(s)
			_shards.append(s)

	func add(n: int, by) -> void:
		if _boom >= 0.0:
			return
		count = mini(3, count + n)
		_left = RiftAbilities.MARK_TIME
		_by = by
		var p := get_parent() as Player
		if p:
			Fx.sparks(p.get_parent(), p.global_position + Vector2(0, -p.body_size.y * 0.6), RiftRig.GLOW, 6, 160.0, 3.0)
		if count >= 3:
			_boom = 0.45                                   # осколки сходятся — сейчас схлопнутся

	func clear() -> void:
		count = 0
		_boom = -1.0
		for s in _shards:
			s.visible = false

	func _process(delta: float) -> void:
		var p := get_parent() as Player
		if p == null or not p.is_alive():
			clear()
			return
		_t += delta
		var top := -p.body_size.y / 2.0 - 30.0
		for i in _shards.size():
			var s: Polygon2D = _shards[i]
			s.visible = i < count
			var a := _t * 3.0 + TAU * i / 3.0
			var r := 26.0
			if _boom >= 0.0:
				r = 26.0 * (_boom / 0.45)
			s.position = Vector2(cos(a) * r, top + sin(a) * r * 0.35)
			s.rotation = 0.0
			s.scale = Vector2.ONE * (1.0 + (0.6 if _boom >= 0.0 else 0.0))
		if _boom >= 0.0:
			_boom -= delta
			if _boom < 0.0:
				_collapse(p)
			return
		if count > 0:
			_left -= delta
			if _left <= 0.0:
				clear()

	func _collapse(p: Player) -> void:
		var world := p.get_parent()
		var at := p.global_position + Vector2(0, -p.body_size.y * 0.2)
		Fx.ring(world, at, 90.0, RiftRig.GLOW, 0.4, 8.0)
		Util.flash(world, at, 70.0, Color(0.85, 0.5, 1.0, 0.8))
		Fx.sparks(world, at, RiftRig.CORE, 14, 260.0, 4.0)
		var by = _by if is_instance_valid(_by) else null
		p.take_damage(RiftAbilities.MARK_DMG, by)
		if p.is_alive():
			p.root(0.45)
			p._float_label("Разлом!", Color(0.85, 0.55, 1.0))
		clear()

# ---------- Снаряд свиты: фиолетовый болт/сфера с меткой ----------
static func bolt(p: Player, from: Vector2, dir: Vector2, speed: float, dmg: int, size := 9.0, marks_n := 1) -> Bullet:
	var b := Bullet.new()
	b.shooter = p
	b.team = p.team
	b.direction = dir
	b.speed = speed
	b.damage = dmg
	b.size = size
	b.style = "rift"
	b.position = from
	if marks_n > 0:
		var who: WeakRef = weakref(p)                     # стрелок может погибнуть, пока болт летит
		b.on_hit = func(body):
			RiftAbilities.mark(body, who.get_ref(), marks_n)
	p.get_parent().add_child(b)
	if b._vis2:
		var long := size < 12.0
		var body := Polygon2D.new()
		if long:                                           # болт: вытянутый осколок
			body.polygon = PackedVector2Array([Vector2(-size * 1.2, -size * 0.25), Vector2(size * 1.3, 0), Vector2(-size * 1.2, size * 0.25), Vector2(-size * 0.8, 0)])
		else:                                              # сфера: тёмное ядро, светлая кайма
			body.polygon = Util.circle(size * 0.75, 14)
		body.color = RiftRig.GLOW
		b._vis2.add_child(body)
		var core := Polygon2D.new()
		core.polygon = Util.circle(size * (0.25 if long else 0.42), 10)
		core.color = RiftRig.CORE if long else RiftRig.VOID
		b._vis2.add_child(core)
	if b._trail:
		b._trail.width = size * 0.7
		b._trail.default_color = Color(RiftRig.GLOW, 0.45)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0))
		g.set_color(1, Color(1, 1, 1, 1))
		b._trail.gradient = g
	return b

# Тусклые нити на замедленном (паутина «Восходит» фиолетовой)
static func void_slow(t: Player, time: float, mult: float) -> void:
	t.slow(time, mult)
	if t._slow_fx:
		t._slow_fx.modulate = Color(0.85, 0.45, 1.0)

# Попадание по отрезку: всем противникам у линии a–b
static func hit_segment(p: Player, a: Vector2, b: Vector2, width: float, dmg: int, marks_n := 0) -> Array:
	var res: Array = []
	for n in _foes(p):
		var cp := Geometry2D.get_closest_point_to_segment(n.global_position, a, b)
		if cp.distance_to(n.global_position) < width + n.body_size.x * 0.4:
			n.take_damage(dmg, p)
			if marks_n > 0:
				mark(n, p, marks_n)
			res.append(n)
	return res

# ---------- Отрёкшийся: шаг сквозь грань ----------
static func _rift_step(p: Player) -> void:
	var world := p.get_parent()
	var t: Player = p.target
	var behind := -float(t.facing) if t.facing != 0 else -signf(p.global_position.x - t.global_position.x)
	var x := clampf(t.global_position.x + behind * 85.0, 100.0, p.map_w - 100.0)
	var y := t.global_position.y + t.body_size.y / 2.0 - p.body_size.y / 2.0
	var slit := Slit.new()
	slit.position = Vector2(x, y + p.body_size.y / 2.0)
	slit.height = p.body_size.y * 1.3
	slit.life = 0.95
	world.add_child(slit)
	p._anim("blink")
	p._forced_time = 0.7
	p._forced_vx = 0.0
	var gone := Slit.new()                                  # за спиной самого Отрёкшегося тоже щель
	gone.position = p.global_position + Vector2(0, p.body_size.y / 2.0)
	gone.height = p.body_size.y * 1.2
	gone.life = 0.6
	world.add_child(gone)
	p._after(0.25, func():
		if is_instance_valid(p) and p.is_alive() and p._rig_root:
			p._rig_root.modulate.a = 0.0)
	p._after(0.6, func():
		if not is_instance_valid(p) or not p.is_alive() or p.is_stunned():
			if is_instance_valid(p) and p._rig_root:
				p._rig_root.modulate.a = 1.0
			return
		p.global_position = Vector2(x, y)
		p.velocity = Vector2.ZERO
		if is_instance_valid(t):
			p.facing = 1 if t.global_position.x > x else -1
		if p._rig_root:
			p._rig_root.modulate.a = 1.0
		Util.flash(world, Vector2(x, y), 50.0, Color(0.8, 0.45, 1.0, 0.8))
		p._anim("swing")
		p._after(0.16, func():
			if not is_instance_valid(p) or not p.is_alive():
				return
			var a2 := p.global_position + Vector2(p.facing * 10.0, -6)
			var b2 := a2 + Vector2(p.facing * 120.0, 0)
			swing_arc(world, p.global_position + Vector2(p.facing * 30.0, -10), 70.0, p.facing)
			hit_segment(p, a2, b2, 50.0, 20, 1)))

# Фиолетовый полумесяц удара (в сторону взгляда)
static func swing_arc(world: Node, at: Vector2, r: float, facing: int, c := Color(0.85, 0.5, 1.0, 0.9)) -> void:
	if facing >= 0:
		Fx.arc(world, at, r, -1.2, 1.0, c)
	else:
		Fx.arc(world, at, r, PI - 1.0, PI + 1.2, c)

# ---------- Стрелок: залп по трём прицельным линиям ----------
static func _pin_volley(p: Player) -> void:
	var world := p.get_parent()
	p._anim("shoot")
	p._forced_time = 0.9
	p._forced_vx = 0.0
	if p.rig and "hold_aim" in p.rig:
		p.rig.hold_aim = 1.0
	var from := _muzzle(p)
	var base: Vector2 = (p.target.global_position - from).normalized()
	var dirs: Array = []
	for k in 3:
		var dv: Vector2 = base.rotated((k - 1) * 0.16)
		dirs.append(dv)
		LightBeam.aim_line(world, from, from + dv * 1200.0, RiftRig.GLOW, 0.55)
	p._after(0.6, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		if p.rig and "hold_aim" in p.rig:
			p.rig.hold_aim = 0.0
		for dv2 in dirs:
			bolt(p, from, dv2, 1250.0, 10))

# ---------- Призывательница ----------
static func _open_rift(p: Player) -> void:
	var world := p.get_parent()
	p._anim("summon")
	p._forced_time = 1.0
	p._forced_vx = 0.0
	var x := clampf(p.global_position.x + p.facing * 140.0, 140.0, p.map_w - 140.0)
	var gy := _ground(p, Vector2(x, p.global_position.y))
	var portal := Slit.new()
	portal.position = Vector2(x, gy)
	portal.height = 120.0
	portal.wide = 2.2
	portal.life = 1.6
	world.add_child(portal)
	p._after(0.85, func():
		if is_instance_valid(p) and p.is_alive() and p.summon.is_valid():
			p.summon.call("rift_spawn", 2, Vector2(x, gy - 30)))

static func _veil(p: Player) -> bool:
	if not p.allies.is_valid():
		return false
	var best: Player = null
	var br := 2.0
	for a in p.allies.call():
		if is_instance_valid(a) and a.is_alive() and a != p and a.crust <= 0.0 and not Bots.is_boss(String(a.get_meta("kind", ""))) \
				and a.global_position.distance_to(p.global_position) < 650.0:
			var r: float = float(a.hp) / a.max_hp
			if r < br:
				br = r
				best = a
	if best == null:
		return false
	p._anim("cast")
	best.give_crust(best.max_hp * 0.3, 6.0)
	var l := Line2D.new()
	l.points = PackedVector2Array([_muzzle(p), best.global_position])
	l.width = 4.0
	l.default_color = Color(RiftRig.GLOW, 0.8)
	l.z_index = 6
	p.get_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
	Fx.ring(p.get_parent(), best.global_position, best.body_size.y * 0.7, RiftRig.GLOW, 0.4, 6.0)
	return true

# ---------- Разрыватель ----------
static func _grasp(p: Player) -> void:
	var world := p.get_parent()
	p._anim("grasp")
	p._forced_time = 1.1
	p._forced_vx = 0.0
	var dirx := float(p.facing)
	var fy := p.global_position.y + p.body_size.y / 2.0 - 30.0
	var from := Vector2(p.global_position.x + dirx * p.body_size.x * 0.5, fy)
	var to := from + Vector2(dirx * 680.0, 0)
	LightBeam.aim_line(world, from, to, RiftRig.GLOW, 0.45)
	p._after(0.45, func():
		if not is_instance_valid(p) or not p.is_alive() or p.is_stunned():
			return
		var h := Hand.new()
		h.owner_p = p
		h.position = from
		h.dir = dirx
		h.reach = 680.0
		world.add_child(h))

class Hand extends Node2D:
	var owner_p: Player
	var dir := 1.0
	var reach := 680.0
	var _gone := 0.0
	var _back := false
	var _caught: Player = null
	var _from := Vector2.ZERO
	var _chain: Line2D

	func _ready() -> void:
		z_index = 7
		_from = position
		var palm := Polygon2D.new()
		palm.polygon = PackedVector2Array([Vector2(-14, -12), Vector2(6, -14), Vector2(18, -6), Vector2(22, 4), Vector2(10, 14), Vector2(-14, 12)])
		palm.color = Color(0.55, 0.30, 0.85, 0.85)
		add_child(palm)
		for k in 4:
			var fng := Polygon2D.new()
			fng.polygon = PackedVector2Array([Vector2(16, -10 + k * 6), Vector2(32, -12 + k * 7), Vector2(18, -6 + k * 6)])
			fng.color = RiftRig.CORE
			add_child(fng)
		scale.x = dir
		_chain = Line2D.new()
		_chain.width = 5.0
		_chain.default_color = Color(RiftRig.GLOW, 0.6)
		_chain.top_level = true
		add_child(_chain)

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(owner_p) or not owner_p.is_alive():
			queue_free()
			return
		var root_pt := owner_p.global_position + Vector2(dir * owner_p.body_size.x * 0.45, -10)
		if not _back:
			position.x += dir * 1400.0 * delta
			_gone += 1400.0 * delta
			for n in RiftAbilities._foes(owner_p):
				if absf(n.global_position.x - position.x) < 40.0 + n.body_size.x / 2 and absf(n.global_position.y - position.y) < 90.0:
					_caught = n
					_back = true
					n.take_damage(10, owner_p)
					RiftAbilities.mark(n, owner_p, 1)
					Fx.sparks(get_parent(), n.global_position, RiftRig.GLOW, 10, 220.0, 4.0)
					break
			if _gone >= reach:
				_back = true
		else:
			var to := root_pt + Vector2(dir * 60.0, 0)
			position = position.move_toward(Vector2(to.x, position.y), 1500.0 * delta)
			if _caught and is_instance_valid(_caught) and _caught.is_alive():
				_caught.global_position.x = position.x + dir * 10.0
				_caught.velocity = Vector2.ZERO
			if absf(position.x - to.x) < 8.0:
				if _caught and is_instance_valid(_caught):
					_caught.root(0.35)
					owner_p._bot_cd.erase("swing")             # притянул — сразу бьёт
				queue_free()
		_chain.points = PackedVector2Array([root_pt, global_position])

static func _gravity_slam(p: Player) -> void:
	var world := p.get_parent()
	p._anim("slam")
	p._forced_time = 0.9
	p._forced_vx = 0.0
	var feet := p.global_position + Vector2(p.facing * 30.0, p.body_size.y / 2.0)
	Fx.rune_circle(world, feet, 200.0, Color(RiftRig.GLOW, 0.8), 0.5)
	p._after(0.5, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		Util.explode(world, feet + Vector2(0, -20), 140.0, 16, 25, p.team, p)
		Fx.shake(world, 8.0)
		var w := Well.new()
		w.team = p.team
		w.attacker = p
		w.position = feet
		w.radius = 230.0
		w.life = 2.2
		world.add_child(w))

# ---------- Носитель: осколки взлетают и падают в круги ----------
static func _shard_burst(p: Player) -> void:
	var world := p.get_parent()
	p._anim("roar")
	p._forced_time = 0.7
	p._forced_vx = 0.0
	var from: Vector2 = p.rig.point("crystal") if p.rig and p.rig.has_method("point") else p.global_position + Vector2(0, -40)
	Util.flash(world, from, 60.0, Color(0.85, 0.5, 1.0, 0.9))
	var tx: float = p.target.global_position.x
	for k in 5:
		var x := clampf(tx + (k - 2) * 110.0 + randf_range(-25, 25), 120.0, p.map_w - 120.0)
		var gy := _ground(p, Vector2(x, p.target.global_position.y - 60.0))
		drop_shard(world, p, from, Vector2(x, gy), 0.9 + k * 0.1, 12)

static func drop_shard(world: Node, p: Player, from: Vector2, at: Vector2, delay: float, dmg: int) -> void:
	var mk := Fx.rune_circle(world, at, 52.0, Color(RiftRig.GLOW, 0.85), delay + 0.1)
	mk.z_index = 3
	var s := FallingShard.new()
	s.from = from
	s.goal = at
	s.time = delay
	s.damage = dmg
	s.attacker = p
	s.team = p.team if is_instance_valid(p) else 1
	world.add_child(s)

class FallingShard extends Node2D:
	var from := Vector2.ZERO
	var goal := Vector2.ZERO
	var time := 1.0
	var damage := 12
	var attacker = null
	var team := 1
	var _k := 0.0
	var _vis: Polygon2D

	func _ready() -> void:
		z_index = 7
		position = from
		_vis = Polygon2D.new()
		_vis.polygon = PackedVector2Array([Vector2(0, -16), Vector2(6, 0), Vector2(0, 14), Vector2(-6, 0)])
		_vis.color = RiftRig.GLOW
		add_child(_vis)
		var c := Polygon2D.new()
		c.polygon = PackedVector2Array([Vector2(0, -8), Vector2(2.5, 0), Vector2(0, 7), Vector2(-2.5, 0)])
		c.color = RiftRig.CORE
		_vis.add_child(c)

	func _physics_process(delta: float) -> void:
		_k = minf(1.0, _k + delta / time)
		var top := minf(from.y, goal.y) - 320.0
		var p := from.lerp(goal, _k)
		p.y = lerpf(lerpf(from.y, top, minf(1.0, _k * 2.0)), goal.y, maxf(0.0, _k * 2.0 - 1.0) ** 2)
		var dv := p - position
		position = p
		if dv.length() > 0.1:
			_vis.rotation = dv.angle() + PI / 2
		if _k >= 1.0:
			var world := get_parent()
			for n in world.get_children():
				if n is Player and n.team != team and n.is_alive() and n.global_position.distance_to(goal + Vector2(0, -n.body_size.y / 2)) < 60.0 + n.body_size.x / 2:
					n.take_damage(damage, attacker if is_instance_valid(attacker) else null)
					if is_instance_valid(attacker):
						RiftAbilities.mark(n, attacker, 1)
			Fx.sparks(world, goal + Vector2(0, -4), RiftRig.GLOW, 10, 220.0, 4.0, true)
			Fx.ring(world, goal, 60.0, RiftRig.GLOW, 0.3, 5.0, 0.35)
			queue_free()

# ---------- Щель-разлом: вертикальная рваная прорезь (телеграф и портал) ----------
class Slit extends Node2D:
	var height := 80.0
	var wide := 1.0
	var life := 1.0
	var _t := 0.0
	var _tear: Polygon2D
	var _core: Polygon2D
	var _glow: Polygon2D

	func _ready() -> void:
		z_index = 4
		_glow = Polygon2D.new()
		_glow.polygon = Util.circle(1.0, 20)
		_glow.color = Color(RiftRig.GLOW, 0.25)
		add_child(_glow)
		_tear = Polygon2D.new()
		_core = Polygon2D.new()
		var pts := PackedVector2Array()
		var inner := PackedVector2Array()
		var n := 9
		for i in n + 1:
			var k := float(i) / n
			var w := sin(k * PI) * 9.0 * wide + (randf_range(-2, 2) if i > 0 and i < n else 0.0)
			pts.append(Vector2(w, -k * height))
			inner.append(Vector2(w * 0.45, -k * height))
		for i in range(n, -1, -1):
			var k2 := float(i) / n
			var w2 := sin(k2 * PI) * 9.0 * wide + (randf_range(-2, 2) if i > 0 and i < n else 0.0)
			pts.append(Vector2(-w2, -k2 * height))
			inner.append(Vector2(-w2 * 0.45, -k2 * height))
		_tear.polygon = pts
		_tear.color = RiftRig.GLOW
		_core.polygon = inner
		_core.color = RiftRig.VOID
		add_child(_tear)
		add_child(_core)
		scale = Vector2(0.1, 0.1)

	func _process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / 0.2, 0.0, 1.0) * clampf((life - _t) / 0.2, 0.0, 1.0)
		scale = Vector2(maxf(0.05, k), maxf(0.05, k))
		_glow.position = Vector2(0, -height / 2.0)
		_glow.scale = Vector2(height * 0.3 * wide, height * 0.6)
		_tear.modulate.a = 0.75 + 0.25 * sin(_t * 20.0)
		if _t >= life:
			queue_free()

# ---------- Воронка: тянет к центру и жжёт ----------
class Well extends Node2D:
	var team := 1
	var attacker = null
	var radius := 230.0
	var life := 2.2
	var power := 360.0
	var dps := 12.0
	var _t := 0.0
	var _tick := 0.0
	var _spin: Node2D

	func _ready() -> void:
		z_index = 3
		_spin = Node2D.new()
		add_child(_spin)
		for k in 3:
			var l := Line2D.new()
			var pts := PackedVector2Array()
			for i in 26:
				var a := i * 0.32 + k * TAU / 3.0
				var r := radius * (1.0 - i / 26.0)
				pts.append(Vector2(cos(a) * r, sin(a) * r * 0.32))
			l.points = pts
			l.width = 4.0
			l.default_color = Color(RiftRig.GLOW, 0.7)
			_spin.add_child(l)
		var hole := Polygon2D.new()
		hole.polygon = Util.circle(26.0, 16)
		hole.scale = Vector2(1.0, 0.4)
		hole.color = RiftRig.VOID
		add_child(hole)

	func _physics_process(delta: float) -> void:
		_t += delta
		_spin.rotation -= delta * 5.0
		_spin.scale.x = 1.0 + 0.05 * sin(_t * 9.0)
		modulate.a = clampf((life - _t) / 0.3, 0.0, 1.0)
		_tick -= delta
		var hurt := _tick <= 0.0
		if hurt:
			_tick = 0.4
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				var dv: Vector2 = global_position - n.global_position
				if absf(dv.x) < radius and absf(dv.y) < 160.0:
					n.push_wind(signf(dv.x) * power * (0.4 + 0.6 * (1.0 - absf(dv.x) / radius)))
					if hurt and absf(dv.x) < radius * 0.45:
						n.take_damage(int(dps * 0.4), attacker if is_instance_valid(attacker) else null)
		if _t >= life:
			queue_free()

# ---------- Пустота на земле: замедляет и жжёт (осколок Носителя) ----------
class VoidZone extends Node2D:
	var team := 1
	var radius := 170.0
	var life := 3.5
	var _t := 0.0
	var _tick := 0.0

	func _ready() -> void:
		z_index = 2
		var pool := Polygon2D.new()
		pool.polygon = Util.circle(radius, 28)
		pool.scale = Vector2(1.0, 0.18)
		pool.color = Color(0.25, 0.06, 0.35, 0.75)
		add_child(pool)
		var rim := Line2D.new()
		var pts := Util.circle(radius, 28)
		pts.append(pts[0])
		rim.points = pts
		rim.scale = Vector2(1.0, 0.18)
		rim.width = 3.0
		rim.default_color = RiftRig.GLOW
		add_child(rim)

	func _physics_process(delta: float) -> void:
		_t += delta
		modulate.a = clampf((life - _t) / 0.4, 0.0, 1.0)
		if randf() < 0.35:
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-radius, radius) * 0.8, -4), RiftRig.GLOW, 1, 90.0, 3.0, true)
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.5
			for n in get_parent().get_children():
				if n is Player and n.team != team and n.is_alive():
					var feet: float = n.global_position.y + n.body_size.y / 2.0
					if absf(n.global_position.x - global_position.x) < radius and absf(feet - global_position.y) < 40.0:
						n.take_damage(5)
						RiftAbilities.void_slow(n, 0.6, 0.55)
		if _t >= life:
			queue_free()
