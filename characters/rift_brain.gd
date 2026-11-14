class_name RiftBrain
extends Node
# ---------- Особое поведение свиты Странника ----------
#   rift_spawn  — Порождение: гибнет — через миг хлопает пустотой вокруг себя;
#   rift_eye    — Око: «Взгляд» — тонкий луч-прицел ведёт героя секунду, потом бьёт луч;
#   rift_bearer — Носитель: пока жив, союзники рядом получают на треть меньше урона
#                 (к ним тянутся нити от кристалла). Гибнет — кристалл раскалывается,
#                 на земле остаётся пустота (жжёт и замедляет);
#   voidwing    — Пустокрыл (мини-босс 85): сам летает над островами.
#                 «Дождь осколков» — осколки падают в отмеченные круги;
#                 «Пикирование» — видна дуга пути: ныряет к герою и врезается в остров —
#                 тогда выдыхается (оглушён, урон ×2);
#                 «Взмах крыльев» — ветер сдувает героев (к пропастям!);
#                 «Разрыв неба» — из разлома падают порождения;
#                 с половины здоровья — в ярости: быстрее, «Луч хвоста» метёт по земле.
#   harbinger   — Предвестник (босс 90). Первая фаза: связка ударов глефой, «Разрез» —
#                 линия по земле (прыгай!) или столбы (отойди), «Шаг сквозь грань» за
#                 спину, «Буря меток», «Жатва» (забирает метки: бьёт и лечится).
#                 Повергнутый, раскалывает маску и открывает разлом над деревней —
#                 вторая фаза: парит, «Дождь осколков», «Воронка», «Зеркальные разрезы»
#                 и «Схлопывание»: копит заряд — собьёшь уроном, он рухнет оглушённым,
#                 не успеешь — удар по всем.

var p: Player
var kind := ""
var _t := 0.0
# ----- Око -----
var _gaze_t := 0.0
var _gaze_line: Line2D
var _gaze_dir := Vector2.RIGHT
# ----- Носитель -----
var _warded: Array = []
var _tethers := {}
# ----- Пустокрыл -----
var _state := "cruise"
var _st := 0.0
var _side := 1.0
var _side_t := 0.0
var _path: Array = []
var _hit := {}
var _land := Vector2.ZERO
var _rage := false
var _sweep := Vector2.ZERO
var _sweep_line: Line2D
# ----- Предвестник -----
var _phase2 := false
var _waking := false
var _charge_t := 0.0
var _charge_dmg := 0.0
var _charge_fx: Node2D
var _sky_rift: Node2D
var _cm: CanvasModulate
const CRUISE_Y := Colosseum.FLOOR_Y - 300.0

func _ready() -> void:
	name = "RiftBrain"
	match kind:
		"rift_spawn":
			p.died.connect(_spawn_pop.unbind(1))
		"rift_bearer":
			p.died.connect(_bearer_died.unbind(1))
		"voidwing":
			p.bar_lift = 10.0                           # пролетает сквозь острова и площадки (маска — в _wing_tick)
			_side = 1.0 if randf() < 0.5 else -1.0
		"harbinger":
			p.on_lethal = _on_lethal
			p.on_hurt = _on_hurt
			p.bar_lift = 40.0

func _am() -> Node:
	return p.get_tree().get_first_node_in_group("arena_mode") if p.is_inside_tree() else null

func _banner(text: String, c := Color(0.85, 0.6, 1.0), hold := 1.5) -> void:
	var am := _am()
	if am and am.hud:
		am.hud.show_banner(text, c)
		am._after(hold, am.hud.hide_banner)

func _floor_y() -> float:
	var am := _am()
	if am and am.info.has("floor"):
		return float(am.info["floor"])
	return Colosseum.FLOOR_Y

func _target_ok() -> bool:
	return is_instance_valid(p.target) and p.target.is_alive()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(p):
		return
	if not p.is_alive():
		_cleanup()
		return
	_t += delta
	match kind:
		"rift_eye":
			if _gaze_t > 0.0:
				_gaze_tick(delta)
		"rift_bearer":
			_ward_tick()
		"voidwing":
			if not p.frozen and not p.is_physics_processing():
				p.set_physics_process(true)            # кончилась сцена появления — полетел
			_wing_tick(delta)
		"harbinger":
			_harb_tick(delta)

func _cleanup() -> void:
	if _gaze_line and is_instance_valid(_gaze_line):
		_gaze_line.queue_free()
	_unward_all()
	if _sweep_line and is_instance_valid(_sweep_line):
		_sweep_line.queue_free()
	if _charge_fx and is_instance_valid(_charge_fx):
		_charge_fx.queue_free()

# Способности боссов — по имени (вызов из RiftAbilities.try)
func use(ab: String, to: Vector2) -> bool:
	if kind == "voidwing":
		if _state != "cruise" or p.is_stunned() or not _target_ok():
			return false
		match ab:
			"void_rain": _start_rain()
			"swoop": _start_swoop()
			"wing_gust": _start_gust()
			"sky_rift": _start_sky_rift()
			"tail_beam":
				if not _rage:
					return false
				_start_beam()
			_: return false
		return true
	if kind == "harbinger":
		if _waking or _charge_t > 0.0 or p._forced_time > 0.0 or not _target_ok():
			return false
		match ab:
			"glaive_combo":
				if absf(to.x) > 300.0 or absf(to.y) > 170.0:
					return false
				_combo()
			"rift_cut": _rift_cut()
			"phase_step": _phase_step()
			"mark_storm": _mark_storm()
			"harvest": return _harvest()
			"shard_rain": _shard_rain()
			"void_well": _void_well()
			"mirror_cuts": _mirror_cuts()
			"collapse": _start_collapse()
			_: return false
		return true
	return false

# ======================= Порождение =======================
func _spawn_pop() -> void:
	var world := p.get_parent()
	var at := p.global_position
	var team := p.team
	if world == null:
		return
	Fx.ring(world, at, 70.0, Color(RiftRig.GLOW, 0.8), 0.35, 4.0)
	world.get_tree().create_timer(0.35).timeout.connect(func():
		if is_instance_valid(world):
			Util.explode(world, at, 75.0, 9, 10, team, null)
			Fx.sparks(world, at, RiftRig.GLOW, 10, 220.0, 4.0))

# ======================= Око =======================
func start_gaze() -> void:
	_gaze_t = 1.0
	if p.rig and "hold_aim" in p.rig:
		p.rig.hold_aim = 1.0
	_gaze_line = Line2D.new()
	_gaze_line.width = 2.0
	_gaze_line.default_color = Color(RiftRig.GLOW, 0.5)
	_gaze_line.z_index = 6
	p.get_parent().add_child(_gaze_line)

func _gaze_tick(delta: float) -> void:
	_gaze_t -= delta
	var from := p.global_position
	if _target_ok() and _gaze_t > 0.25:
		_gaze_dir = _gaze_dir.lerp((p.target.global_position - from).normalized(), minf(1.0, delta * 6.0)).normalized()
	if _gaze_line and is_instance_valid(_gaze_line):
		_gaze_line.points = PackedVector2Array([from, from + _gaze_dir * 1300.0])
		_gaze_line.width = 2.0 + (1.0 - _gaze_t) * 3.0
		_gaze_line.default_color = Color(RiftRig.GLOW, 0.4 + (1.0 - _gaze_t) * 0.4) if _gaze_t > 0.25 else Color(1.0, 0.55, 1.0, 0.95)
	if _gaze_t <= 0.0:
		if _gaze_line and is_instance_valid(_gaze_line):
			_gaze_line.queue_free()
		if p.rig and "hold_aim" in p.rig:
			p.rig.hold_aim = 0.0
		var b := from + _gaze_dir * 1300.0
		var hit := p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, b, Layer.WORLD))
		if not hit.is_empty() and not Util.is_one_way(hit["collider"]):
			b = hit["position"]
		LightBeam.draw(p.get_parent(), [[from, b, 0]], Color(0.85, 0.45, 1.0), 12.0, 0.3)
		RiftAbilities.hit_segment(p, from, b, 22.0, 18, 1)

# ======================= Носитель =======================
func _ward_tick() -> void:
	if not p.allies.is_valid():
		return
	var near: Array = []
	for a in p.allies.call():
		if is_instance_valid(a) and a.is_alive() and a != p and a.global_position.distance_to(p.global_position) < 400.0 \
				and not Bots.is_boss(String(a.get_meta("kind", ""))) and String(a.get_meta("kind", "")) != "rift_bearer":
			near.append(a)
	for a in near:
		if not a.has_meta("ward_base"):
			a.set_meta("ward_base", a.armor_mult)
			a.armor_mult = float(a.get_meta("ward_base")) * 0.65
	for a in _warded:
		if is_instance_valid(a) and not (a in near):
			_unward(a)
	_warded = near
	var from: Vector2 = p.rig.point("crystal") if p.rig and p.rig.has_method("point") else p.global_position
	for a in near:
		var id: int = a.get_instance_id()
		var l: Line2D = _tethers.get(id)
		if l == null or not is_instance_valid(l):
			l = Line2D.new()
			l.width = 2.5
			l.default_color = Color(RiftRig.GLOW, 0.5)
			l.z_index = 4
			p.get_parent().add_child(l)
			_tethers[id] = l
		var mid: Vector2 = (from + a.global_position) / 2.0 + Vector2(0, -30.0 + sin(_t * 5.0 + id) * 8.0)
		l.points = PackedVector2Array([from, mid, a.global_position])
	for id in _tethers.keys():
		var alive := false
		for a in near:
			if a.get_instance_id() == id:
				alive = true
		if not alive:
			if is_instance_valid(_tethers[id]):
				_tethers[id].queue_free()
			_tethers.erase(id)

func _unward(a) -> void:
	if is_instance_valid(a) and a.has_meta("ward_base"):
		a.armor_mult = float(a.get_meta("ward_base"))
		a.remove_meta("ward_base")

func _unward_all() -> void:
	for a in _warded:
		_unward(a)
	_warded.clear()
	for id in _tethers:
		if is_instance_valid(_tethers[id]):
			_tethers[id].queue_free()
	_tethers.clear()

func _bearer_died() -> void:
	_unward_all()
	var world := p.get_parent()
	if world == null:
		return
	var at := p.global_position + Vector2(0, p.body_size.y / 2.0)
	Util.flash(world, at + Vector2(0, -p.body_size.y * 0.6), 120.0, Color(0.85, 0.5, 1.0, 0.9))
	Fx.sparks(world, at + Vector2(0, -p.body_size.y * 0.6), RiftRig.GLOW, 22, 340.0, 5.0)
	var z := RiftAbilities.VoidZone.new()
	z.team = p.team
	z.position = at
	world.add_child(z)

# ======================= Пустокрыл =======================
func _wing_tick(delta: float) -> void:
	p.collision_mask = 0                                # (Player._ready ставит свою маску — снимаем)
	_st -= delta
	if not _rage and p.hp <= p.max_hp / 2:
		_rage = true
		p.speed *= 1.3
		p.bot_abilities["tail_beam"] = 7.0
		for k in p.bot_abilities:
			p.bot_abilities[k] = float(p.bot_abilities[k]) * 0.8
		if p.rig:
			p.rig.play("roar")
		p.set_tint(Color(1.15, 0.95, 1.25))
		_banner("Пустокрыл в ярости!", Color(0.9, 0.55, 1.0))
		Fx.ring(p.get_parent(), p.global_position, 260.0, RiftRig.GLOW, 0.5, 8.0)
	if p.frozen:
		return
	var fy := _floor_y()
	var v := Vector2.ZERO
	if p.is_stunned() and _state != "crash":
		# оглушён (пошатнули уроном) — опускается к земле, по нему проще попасть
		var gy := _ground_at(p.global_position.x)
		if gy < 9000.0:
			v.y = clampf((gy - p.body_size.y / 2.0 - 4.0) - p.global_position.y, -400.0, 600.0) * 4.0
		_drive(v)
		return
	match _state:
		"cruise":
			_side_t -= delta
			if _side_t <= 0.0:
				_side_t = randf_range(3.5, 5.0)
				_side = -_side
			var tx := p.global_position.x
			if _target_ok():
				tx = p.target.global_position.x + _side * 320.0
			tx = clampf(tx, 220.0, p.map_w - 220.0)
			var goal := Vector2(tx, CRUISE_Y + sin(_t * 0.9) * 50.0)
			v = (goal - p.global_position) * 1.6
			if v.length() > p.speed:
				v = v.normalized() * p.speed
			if _target_ok():
				p.facing = 1 if p.target.global_position.x > p.global_position.x else -1
		"rain", "gust", "rift", "beam_prep", "beam":
			var gl := Vector2(p.global_position.x, (fy - 260.0) if _state != "rift" else CRUISE_Y - 40.0)
			v = (gl - p.global_position) * 2.0
			if _state == "gust":
				for n in RiftAbilities._foes(p):
					var dx: float = n.global_position.x - p.global_position.x
					if absf(dx) < 900.0:
						n.push_wind(signf(dx) * 520.0)
				if randf() < 0.5:
					Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-120, 120), randf_range(40, 120)), Color(0.9, 0.85, 1.0, 0.8), 1, 520.0, 3.0)
			if _state == "beam":
				_beam_tick(delta)
			if _st <= 0.0:
				if _state == "beam_prep":
					_state = "beam"
					_st = 1.3
					_hit.clear()
				else:
					_end_state()
		"swoop_prep":
			v = (_path[0] - p.global_position) * 4.0
			if v.length() > 900.0:
				v = v.normalized() * 900.0
			if _st <= 0.0:
				_state = "swoop"
				_st = 1.1
				_hit.clear()
				if p.rig:
					p.rig.play("slam")
		"swoop":
			var k := clampf(1.0 - _st / 1.1, 0.0, 1.0)
			var a: Vector2 = _path[0]
			var c: Vector2 = _path[1]
			var b: Vector2 = _path[2]
			var pos := a.lerp(c, k).lerp(c.lerp(b, k), k)
			v = (pos - p.global_position) / maxf(delta, 0.001)
			p.facing = 1 if b.x > a.x else -1
			_contact(26, 520.0)
			if _st <= 0.0:
				_crash()
		"crash":
			v = Vector2.ZERO
			if _st <= 0.0:
				_end_state()
	_drive(v)

func _drive(v: Vector2) -> void:
	p._dive_t = 0.05
	p._dive_v = v

func _end_state() -> void:
	_state = "cruise"
	_st = 0.0
	if _sweep_line and is_instance_valid(_sweep_line):
		_sweep_line.queue_free()

func _ground_at(x: float) -> float:
	var hit := p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			Vector2(x, CRUISE_Y - 200.0), Vector2(x, _floor_y() + 60.0), Layer.FRAME))
	return hit["position"].y if not hit.is_empty() else 99999.0

# Врезался телом (пикирование): урон и отброс — каждому один раз
func _contact(dmg: int, knock: float) -> void:
	var r := Rect2(p.global_position - p.body_size * 0.5, p.body_size).grow(10.0)
	for n in RiftAbilities._foes(p):
		if _hit.has(n.get_instance_id()):
			continue
		if r.has_point(n.global_position):
			_hit[n.get_instance_id()] = true
			n.take_damage(dmg, p)
			n.velocity = Vector2(signf(n.global_position.x - p.global_position.x) * knock, -420.0)
			Fx.sparks(p.get_parent(), n.global_position, RiftRig.GLOW, 10, 260.0, 4.0)

func _start_rain() -> void:
	_state = "rain"
	_st = 1.8
	if p.rig:
		p.rig.play("roar")
	var world := p.get_parent()
	var tx: float = p.target.global_position.x
	var n := 7 if _rage else 6
	for k in n:
		var x := clampf(tx + (k - (n - 1) / 2.0) * 115.0 + randf_range(-25, 25), 120.0, p.map_w - 120.0)
		var gy := _ground_at(x)
		if gy > 9000.0:
			continue                                   # над пропастью — некуда падать
		RiftAbilities.drop_shard(world, p, p.global_position + Vector2(0, 30), Vector2(x, gy), 1.0 + k * 0.08, 14)

func _start_swoop() -> void:
	var fy := _floor_y()
	var tgt: Player = p.target
	var dir := 1.0 if tgt.global_position.x > p.global_position.x else -1.0
	var sx := clampf(tgt.global_position.x - dir * 700.0, 200.0, p.map_w - 200.0)
	if absf(sx - tgt.global_position.x) < 400.0:
		dir = -dir
		sx = clampf(tgt.global_position.x - dir * 700.0, 200.0, p.map_w - 200.0)
	var start := Vector2(sx, fy - 560.0)
	var dip := Vector2(tgt.global_position.x, fy + 180.0)        # опорная точка кривой (сама дуга — у земли)
	var lx := clampf(tgt.global_position.x + dir * 300.0, 260.0, p.map_w - 260.0)
	var gy := _ground_at(lx)
	var tries := 0
	while gy > 9000.0 and tries < 30:                              # над пропастью садиться некуда — ближе к середине
		lx += signf(p.map_w / 2.0 - lx) * 40.0
		gy = _ground_at(lx)
		tries += 1
	if gy > 9000.0:
		gy = fy
	_land = Vector2(lx, gy - p.body_size.y / 2.0 + 6.0)
	_path = [start, dip, _land]
	_state = "swoop_prep"
	_st = 1.2
	if p.rig:
		p.rig.play("roar")
	# видна дуга, по которой он нырнёт
	var l := Line2D.new()
	var pts := PackedVector2Array()
	for i in 25:
		var k := i / 24.0
		pts.append(start.lerp(dip, k).lerp(dip.lerp(_land, k), k) + Vector2(0, p.body_size.y * 0.3))
	l.points = pts
	l.width = 26.0
	l.default_color = Color(RiftRig.GLOW, 0.22)
	l.z_index = 3
	p.get_parent().add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "default_color:a", 0.45, 1.1)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(l.queue_free)

func _crash() -> void:
	var world := p.get_parent()
	_state = "crash"
	_st = 2.6
	p.global_position = _land
	var feet := _land + Vector2(0, p.body_size.y / 2.0)
	Fx.shake(world, 12.0)
	Fx.ring(world, feet, 240.0, Color(0.85, 0.6, 1.0, 0.9), 0.45, 8.0, 0.3)
	Fx.cracks(world, feet, Color(0.25, 0.15, 0.30), 140.0)
	Fx.sparks(world, feet + Vector2(0, -8), Color(0.75, 0.70, 0.80), 20, 340.0, 5.0, true)
	Util.explode(world, feet + Vector2(0, -30), 150.0, 16, 30, p.team, p)
	p.stun(2.4)
	p._float_label("Выдохся!", Color(1.0, 0.85, 0.4))

func _start_gust() -> void:
	_state = "gust"
	_st = 1.6
	if p.rig:
		p.rig.play("roar")
	_banner("Взмах крыльев!", Color(0.85, 0.85, 1.0), 1.0)
	for k in 4:
		p._after(0.3 + k * 0.25, func():
			if is_instance_valid(p) and p.is_alive() and _target_ok():
				var from := p.global_position + Vector2(0, 20)
				RiftAbilities.bolt(p, from, (p.target.global_position - from).normalized().rotated(randf_range(-0.2, 0.2)), 700.0, 8))

func _start_sky_rift() -> void:
	_state = "rift"
	_st = 1.4
	if p.rig:
		p.rig.play("roar")
	var world := p.get_parent()
	var x := clampf(p.global_position.x + p.facing * 220.0, 200.0, p.map_w - 200.0)
	var s := RiftAbilities.Slit.new()
	s.position = Vector2(x, CRUISE_Y + 60.0)
	s.height = 180.0
	s.wide = 2.4
	s.life = 1.8
	world.add_child(s)
	p._after(0.9, func():
		if is_instance_valid(p) and p.is_alive() and p.summon.is_valid():
			var gy := _ground_at(x)
			p.summon.call("rift_spawn", 2, Vector2(x, gy if gy < 9000.0 else _floor_y())))

func _start_beam() -> void:
	_state = "beam_prep"
	_st = 0.8
	var tx: float = p.target.global_position.x
	var dir := 1.0 if randf() < 0.5 else -1.0
	var gy := _floor_y()
	_sweep = Vector2(clampf(tx - dir * 450.0, 120.0, p.map_w - 120.0), clampf(tx + dir * 450.0, 120.0, p.map_w - 120.0))
	LightBeam.aim_line(p.get_parent(), Vector2(_sweep.x, gy - 6.0), Vector2(_sweep.y, gy - 6.0), RiftRig.GLOW, 0.8)
	_sweep_line = Line2D.new()
	_sweep_line.width = 10.0
	_sweep_line.default_color = Color(0.9, 0.55, 1.0, 0.9)
	_sweep_line.z_index = 6
	_sweep_line.visible = false
	p.get_parent().add_child(_sweep_line)
	if p.rig:
		p.rig.play("cast")

func _beam_tick(_delta: float) -> void:
	var k := clampf(1.0 - _st / 1.3, 0.0, 1.0)
	var x := lerpf(_sweep.x, _sweep.y, k)
	var gy := _ground_at(x)
	if gy > 9000.0:
		gy = _floor_y() + 40.0
	var from: Vector2 = p.rig.point("tail") if p.rig and p.rig.has_method("point") else p.global_position
	if _sweep_line and is_instance_valid(_sweep_line):
		_sweep_line.visible = true
		_sweep_line.points = PackedVector2Array([from, Vector2(x, gy)])
	if randf() < 0.7:
		Fx.sparks(p.get_parent(), Vector2(x, gy - 4), RiftRig.GLOW, 2, 200.0, 4.0, true)
	for n in RiftAbilities._foes(p):
		if _hit.has(n.get_instance_id()):
			continue
		var feet: float = n.global_position.y + n.body_size.y / 2.0
		if absf(n.global_position.x - x) < 40.0 + n.body_size.x / 2 and absf(feet - gy) < 30.0:
			_hit[n.get_instance_id()] = true
			n.take_damage(16, p)
			RiftAbilities.mark(n, p, 1)

# ======================= Предвестник =======================
func _harb_tick(delta: float) -> void:
	if p.rig and "levitate" in p.rig:
		var want := 1.0 if _phase2 and not p.is_stunned() else 0.0
		p.rig.levitate = move_toward(p.rig.levitate, want, delta * 2.0)
	if _charge_t > 0.0:
		_charge_tick(delta)

func _on_hurt(amount: int, _by) -> void:
	if _charge_t > 0.0:
		_charge_dmg += amount

func _swing_hit(reach: float, dmg: int, knock: float) -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	RiftAbilities.swing_arc(world, p.global_position + Vector2(p.facing * 60.0, -30), reach * 0.55, p.facing)
	for n in RiftAbilities._foes(p):
		var dd: Vector2 = n.global_position - p.global_position
		if signf(dd.x) == p.facing and absf(dd.x) < reach and absf(dd.y) < p.body_size.y * 0.6:
			n.take_damage(dmg, p)
			if knock > 0.0:
				n.velocity = Vector2(p.facing * knock, -380.0)

# Связка глефой: два взмаха, второй шире и отбрасывает
func _combo() -> void:
	p._anim("swing")
	p._forced_time = 1.1
	p._forced_vx = p.facing * 60.0
	p._after(0.35, _swing_hit.bind(230.0, 18, 0.0))
	p._after(0.62, func():
		if is_instance_valid(p) and p.is_alive():
			p._anim("swing"))
	p._after(0.85, _swing_hit.bind(300.0, 22, 560.0))

# Разрез: линия по земле (перепрыгни) или столбы-разрывы (отойди)
func _rift_cut() -> void:
	var world := p.get_parent()
	var fy := _floor_y()
	p._anim("cast")
	p._forced_time = 1.0
	p._forced_vx = 0.0
	var low := randf() < 0.5
	var warn := 0.85 if not _phase2 else 0.7
	if low:
		var a := Vector2(80.0, fy - 26.0)
		var b := Vector2(p.map_w - 80.0, fy - 26.0)
		LightBeam.aim_line(world, a, b, RiftRig.GLOW, warn)
		_banner("Разрез — прыгай!", Color(0.9, 0.6, 1.0), 0.9)
		p._after(warn, func():
			if not is_instance_valid(p) or not p.is_alive():
				return
			LightBeam.draw(world, [[a, b, 0]], Color(0.9, 0.5, 1.0), 14.0, 0.3)
			Fx.shake(world, 6.0)
			for n in RiftAbilities._foes(p):
				var feet: float = n.global_position.y + n.body_size.y / 2.0
				if feet > fy - 50.0 and n.is_on_floor():
					n.take_damage(24, p)
					RiftAbilities.mark(n, p, 1))
	else:
		var xs: Array = []
		for n in RiftAbilities._foes(p):
			xs.append(n.global_position.x)
		if xs.size() < 2:
			xs.append(clampf(xs[0] + (1.0 if randf() < 0.5 else -1.0) * 260.0, 120.0, p.map_w - 120.0) if not xs.is_empty() else p.global_position.x)
		if _phase2:
			xs.append(clampf(float(xs[0]) + 180.0 * (1.0 if randf() < 0.5 else -1.0), 120.0, p.map_w - 120.0))
		for x in xs:
			LightBeam.aim_line(world, Vector2(x, fy), Vector2(x, fy - 700.0), RiftRig.GLOW, warn)
		p._after(warn, func():
			if not is_instance_valid(p) or not p.is_alive():
				return
			for x2 in xs:
				var s := RiftAbilities.Slit.new()
				s.position = Vector2(x2, fy)
				s.height = 640.0
				s.wide = 1.4
				s.life = 0.45
				world.add_child(s)
				RiftAbilities.hit_segment(p, Vector2(x2, fy), Vector2(x2, fy - 700.0), 34.0, 24, 1))

# Шаг сквозь грань: щель за спиной дальнего героя — выходит оттуда и бьёт
func _phase_step() -> void:
	var world := p.get_parent()
	var far: Player = p.target
	var best := -1.0
	for n in RiftAbilities._foes(p):
		var dd: float = absf(n.global_position.x - p.global_position.x)
		if dd > best:
			best = dd
			far = n
	var behind := -float(far.facing) if far.facing != 0 else 1.0
	var x := clampf(far.global_position.x + behind * 150.0, 160.0, p.map_w - 160.0)
	var fy := _floor_y()
	var s := RiftAbilities.Slit.new()
	s.position = Vector2(x, fy)
	s.height = p.body_size.y * 1.2
	s.wide = 2.0
	s.life = 1.1
	world.add_child(s)
	p._anim("blink")
	p._forced_time = 1.2
	p._forced_vx = 0.0
	p._after(0.25, func():
		if is_instance_valid(p) and p._rig_root:
			p._rig_root.modulate.a = 0.15)
	p._after(0.75, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		p.global_position = Vector2(x, fy - p.body_size.y / 2.0 - 2.0)
		p.velocity = Vector2.ZERO
		if p._rig_root:
			p._rig_root.modulate.a = 1.0
		if is_instance_valid(far):
			p.facing = 1 if far.global_position.x > x else -1
		Util.flash(world, p.global_position, 120.0, Color(0.85, 0.5, 1.0, 0.8))
		p._anim("swing"))
	p._after(0.95, _swing_hit.bind(260.0, 22, 420.0))

# Буря меток: сферы кружат вокруг него, потом летят в героев
func _mark_storm() -> void:
	var world := p.get_parent()
	p._anim("cast")
	p._forced_time = 0.9
	p._forced_vx = 0.0
	var n := 6 if not _phase2 else 8
	for k in n:
		p._after(0.5 + k * 0.08, func():
			if not is_instance_valid(p) or not p.is_alive() or not _target_ok():
				return
			var a := TAU * k / n
			var from := p.global_position + Vector2(cos(a) * 90.0, -60.0 + sin(a) * 60.0)
			Fx.sparks(world, from, RiftRig.GLOW, 4, 100.0, 3.0)
			var b := RiftAbilities.bolt(p, from, Vector2.from_angle(a), 360.0, 7, 13.0)
			b.homing = 700.0
			b.set("_life", 4.0))

# Жатва: забирает метки с героев — каждая бьёт героя и лечит Предвестника
func _harvest() -> bool:
	var world := p.get_parent()
	var marked: Array = []
	for n in RiftAbilities._foes(p):
		if RiftAbilities.marks(n) > 0:
			marked.append(n)
	if marked.is_empty():
		return false
	p._anim("roar")
	p._forced_time = 0.9
	p._forced_vx = 0.0
	_banner("Жатва!", Color(0.9, 0.55, 1.0), 1.0)
	for n in marked:
		var l := Line2D.new()
		l.points = PackedVector2Array([n.global_position, p.global_position + Vector2(0, -p.body_size.y * 0.3)])
		l.width = 5.0
		l.default_color = Color(RiftRig.GLOW, 0.8)
		l.z_index = 6
		world.add_child(l)
		var t := l.create_tween()
		t.tween_property(l, "width", 1.0, 0.6)
		t.tween_callback(l.queue_free)
	p._after(0.6, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		var total := 0
		for n2 in marked:
			if is_instance_valid(n2) and n2.is_alive():
				var c := RiftAbilities.take_marks(n2)
				if c > 0:
					n2.take_damage(8 * c, p)
					total += c
		if total > 0:
			p.heal(int(p.max_hp * 0.015 * total))
			Util.flash(world, p.global_position, 140.0, Color(0.85, 0.5, 1.0, 0.7))
			p._float_label("+%d" % int(p.max_hp * 0.015 * total), Color(0.85, 0.6, 1.0)))
	return true

# ----- Вторая фаза -----
func _on_lethal() -> bool:
	if _phase2 or _waking:
		return false
	p.hp = 1
	_waking = true
	_start_phase2()
	return true

func _start_phase2() -> void:
	var world := p.get_parent()
	var am := _am()
	p.cutscene_shield = true
	p.frozen = true
	p.velocity = Vector2.ZERO
	p._forced_time = 0.0
	p.stagger = 0.0
	p._stun_t = 0.0
	if p._stun_fx:
		p._stun_fx.visible = false
	if am:
		for b in am._alive.duplicate():
			if is_instance_valid(b) and b != p and b.is_alive():
				Util.flash(world, b.global_position, 50.0, Color(0.8, 0.45, 1.0, 0.8))
				b.take_damage(99999)
		am.cinematic(p, 6.2)
	Engine.time_scale = 0.35
	p.get_tree().create_timer(0.7, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	if p.rig:
		p.rig.play("kneel")
	_banner("Предвестник повержен…", Color(0.9, 0.6, 1.0))
	p._after(1.3, func():
		if not is_instance_valid(p):
			return
		if p.rig and p.rig.has_method("crack_mask"):
			p.rig.crack_mask()
		Util.flash(world, p.global_position + Vector2(0, -p.body_size.y * 0.4), 90.0, Color(1.0, 0.9, 1.0, 0.95))
		Fx.sparks(world, p.global_position + Vector2(0, -p.body_size.y * 0.4), RiftRig.CORE, 18, 260.0, 4.0)
		_banner("…маска треснула. Из щели бьёт свет разлома!", Color(0.9, 0.6, 1.0)))
	p._after(2.6, _open_sky)
	p._after(4.4, func():
		if p.rig:
			p.rig.play("roar")
		Fx.shake(world, 12.0)
		Fx.ring(world, p.global_position, 360.0, RiftRig.GLOW, 0.6, 10.0))
	p._after(5.6, _begin_phase2)

func _open_sky() -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	for n in world.get_children():
		if n is CanvasModulate:
			_cm = n
	if _cm:
		_cm.create_tween().tween_property(_cm, "color", Color(0.86, 0.72, 0.98), 1.4)
	_sky_rift = Node2D.new()
	_sky_rift.position = Vector2(p.map_w / 2.0, _floor_y() - 520.0)
	_sky_rift.z_index = -8
	world.add_child(_sky_rift)
	var big := RiftAbilities.Slit.new()
	big.height = 420.0
	big.wide = 5.0
	big.life = 99999.0
	big.position = Vector2(0, 210.0)
	_sky_rift.add_child(big)
	_sky_rift.scale = Vector2(0.2, 0.2)
	_sky_rift.create_tween().tween_property(_sky_rift, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.shake(world, 10.0)

func _begin_phase2() -> void:
	if not is_instance_valid(p):
		return
	Audio.intensity(3)                    # вторая фаза Предвестника — музыка на пределе
	var am := _am()
	var t: Dictionary = Bots.TYPES["harbinger"]
	var factor := float(p.max_hp) / float(t["hp"])
	var share := p.stagger_max / float(maxi(p.max_hp, 1))
	p.max_hp = int(float(t["phase2_hp"]) * factor)
	p.stagger_max = p.max_hp * share
	p.stagger = 0.0
	var ht := p.create_tween()
	ht.tween_method(func(v: float):
		if is_instance_valid(p) and p.is_alive():
			p.hp = maxi(p.hp, int(v)), 1.0, float(p.max_hp), 1.0)
	p.speed = float(t["speed"]) * 1.15
	p.set_tint(Color(1.1, 0.95, 1.2))
	p.set_meta("title", t["phase2_name"])
	p.bot_abilities = {"glaive_combo": 2.4, "shard_rain": 5.0, "rift_cut": 6.0, "mirror_cuts": 8.5, "void_well": 10.0,
			"mark_storm": 9.0, "harvest": 12.0, "collapse": 20.0, "summon": 24.0}
	p._bot_cd = {"collapse": 9.0}
	_phase2 = true
	_waking = false
	p.frozen = false
	p.cutscene_shield = false
	if am:
		am._name_card("harbinger", String(t["phase2_name"]), "ВТОРАЯ ФАЗА")
		am._after(2.6, am.hud.show_hint.bind(String(t["hint2"]), 10.0))

func _sky_point() -> Vector2:
	if _sky_rift and is_instance_valid(_sky_rift):
		return _sky_rift.global_position + Vector2(randf_range(-40, 40), 200.0)
	return p.global_position + Vector2(0, -400)

# Дождь осколков из разлома в небе — в круги вокруг героев
func _shard_rain() -> void:
	var world := p.get_parent()
	p._anim("cast")
	var foes := RiftAbilities._foes(p)
	var n := 0
	for f in foes:
		for k in 4:
			var x := clampf(f.global_position.x + (k - 1.5) * 130.0 + randf_range(-30, 30), 120.0, p.map_w - 120.0)
			var gy := RiftAbilities._ground(p, Vector2(x, f.global_position.y - 80.0))
			RiftAbilities.drop_shard(world, p, _sky_point(), Vector2(x, gy), 1.0 + n * 0.09, 14)
			n += 1

func _void_well() -> void:
	var world := p.get_parent()
	p._anim("summon")
	p._forced_time = 0.8
	p._forced_vx = 0.0
	var at := Vector2(p.target.global_position.x, _floor_y())
	Fx.rune_circle(world, at, 240.0, Color(RiftRig.GLOW, 0.8), 0.6)
	p._after(0.6, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		var w := RiftAbilities.Well.new()
		w.team = p.team
		w.attacker = p
		w.position = at
		w.radius = 260.0
		w.life = 3.0
		w.power = 420.0
		world.add_child(w))

# Зеркальные разрезы: три отражения вокруг героя, у каждого видна линия рывка
func _mirror_cuts() -> void:
	var world := p.get_parent()
	var tgt: Player = p.target
	p._anim("cast")
	p._forced_time = 1.0
	p._forced_vx = 0.0
	var aim := tgt.global_position
	var spots := [Vector2(-280, -10), Vector2(280, -10), Vector2(0, -330)]
	spots.shuffle()
	for k in 3:
		var from: Vector2 = aim + spots[k]
		from.x = clampf(from.x, 100.0, p.map_w - 100.0)
		var to: Vector2 = from + (aim - from) * 2.0
		var ghost := RiftRig.new()
		ghost.kind = "harbinger"
		ghost.size = p.body_size * 0.8
		ghost.puppet_facing = 1 if aim.x > from.x else -1
		ghost.modulate = Color(0.75, 0.45, 1.0, 0.0)
		ghost.position = from
		world.add_child(ghost)
		var gt := ghost.create_tween()
		gt.tween_property(ghost, "modulate:a", 0.65, 0.3)
		LightBeam.aim_line(world, from, to, RiftRig.GLOW, 0.75 + k * 0.2)
		p._after(0.8 + k * 0.2, func():
			if not is_instance_valid(ghost):
				return
			if not is_instance_valid(p) or not p.is_alive():
				ghost.queue_free()
				return
			ghost.play("swing")
			var mt := ghost.create_tween()
			mt.tween_property(ghost, "position", to, 0.16)
			mt.tween_property(ghost, "modulate:a", 0.0, 0.3)
			mt.tween_callback(ghost.queue_free)
			LightBeam.draw(world, [[from, to, 0]], Color(0.85, 0.5, 1.0), 10.0, 0.25)
			RiftAbilities.hit_segment(p, from, to, 30.0, 20, 1))

# Схлопывание: копит заряд. Собьёшь уроном — рухнет оглушённым, иначе удар по всем
func _start_collapse() -> void:
	var world := p.get_parent()
	_charge_t = 2.8
	_charge_dmg = 0.0
	p._anim("summon")
	p._forced_time = 3.0
	p._forced_vx = 0.0
	_banner("Схлопывание! Сбей заряд уроном!", Color(1.0, 0.6, 1.0), 1.6)
	_charge_fx = Node2D.new()
	_charge_fx.z_index = 6
	p.add_child(_charge_fx)
	for k in 2:
		var r := Line2D.new()
		var pts := Util.circle(1.0, 28)
		pts.append(pts[0])
		r.points = pts
		r.width = 0.04
		r.default_color = RiftRig.GLOW if k == 0 else RiftRig.CORE
		r.name = "R%d" % k
		_charge_fx.add_child(r)
	var bar := ColorRect.new()                          # полоса заряда над головой
	bar.name = "Bar"
	bar.color = RiftRig.GLOW
	bar.size = Vector2(160, 10)
	bar.position = Vector2(-80, -p.body_size.y / 2.0 - 90.0)
	_charge_fx.add_child(bar)
	var need := ColorRect.new()
	need.name = "Need"
	need.color = Color(1, 1, 1, 0.9)
	need.size = Vector2(0, 6)
	need.position = Vector2(-80, -p.body_size.y / 2.0 - 78.0)
	_charge_fx.add_child(need)
	Fx.ring(world, p.global_position, 300.0, RiftRig.GLOW, 0.5, 8.0)

func _charge_tick(delta: float) -> void:
	_charge_t -= delta
	var need := p.max_hp * 0.07
	var k := clampf(_charge_dmg / need, 0.0, 1.0)
	if _charge_fx and is_instance_valid(_charge_fx):
		var grow := 1.0 - _charge_t / 2.8
		for i in 2:
			var r: Line2D = _charge_fx.get_node_or_null("R%d" % i)
			if r:
				var rad := 420.0 * (1.0 - grow) + 60.0 + i * 30.0
				r.scale = Vector2(rad, rad * 0.8)
				r.rotation += delta * (2.0 if i == 0 else -3.0)
		var bar: ColorRect = _charge_fx.get_node_or_null("Bar")
		if bar:
			bar.size.x = 160.0 * (_charge_t / 2.8)
		var nb: ColorRect = _charge_fx.get_node_or_null("Need")
		if nb:
			nb.size.x = 160.0 * k
	if randf() < 0.6:
		Fx.sparks(p.get_parent(), p.global_position + Vector2.from_angle(randf() * TAU) * 160.0, RiftRig.GLOW, 1, 120.0, 3.0)
	var world := p.get_parent()
	if k >= 1.0:
		_charge_t = 0.0
		_end_charge()
		p._forced_time = 0.0
		Util.flash(world, p.global_position, 200.0, Color(1.0, 0.9, 1.0, 0.9))
		_banner("Заряд сорван!", Color(1.0, 0.85, 0.4))
		p.stun(3.2)
		p._float_label("ОГЛУШЁН! урон ×%s" % str(p.stun_mult).trim_suffix(".0"), Color(1.0, 0.85, 0.3))
		return
	if _charge_t <= 0.0:
		_end_charge()
		Util.flash(world, p.global_position, 900.0, Color(0.9, 0.6, 1.0, 0.85))
		Fx.shake(world, 14.0)
		Fx.ring(world, p.global_position, 1200.0, RiftRig.GLOW, 0.7, 14.0)
		for n in RiftAbilities._foes(p):
			n.take_damage(30, p)
			RiftAbilities.mark(n, p, 2)
		p._forced_time = 1.2                                  # после удара — передышка

func _end_charge() -> void:
	if _charge_fx and is_instance_valid(_charge_fx):
		_charge_fx.queue_free()
	_charge_fx = null
