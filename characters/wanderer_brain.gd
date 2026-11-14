class_name WandererBrain
extends Node
# ---------- Странник (волна 100) ----------
# Ему не важна битва — он проверяет, на что способна поглощённая им сила бездны.
#   Фаза 1 (100–66%)  «Пробует силу»: бьётся аккуратно, вымеряет удары: удар посохом
#                     вблизи, одиночный сгусток. Часто уходит от выстрелов «шагом сквозь
#                     грань» (на миг исчезает — снаряды пролетают), а если подойти
#                     вплотную и ударить — отступает.
#   Фаза 2 (66–33%)   «Входит во вкус»: быстрее, веер из трёх сгустков, «Копьё пустоты»
#                     (видна линия — потом рывок сквозь героя), «Мины разлома» в земле.
#   Сцена: на трети здоровья — «Хватит разминки». Полностью лечится и переносит бой
#          в Зал Бездны (внутри дворца).
#   Фаза 3 (Зал)      + «Цепи бездны» из-под земли, «Эхо удара» — две тени бьют с боков,
#                     «Воронка».
#   Сцена: повержен — встаёт на колено… и поглощает ещё больше бездны. Снова здоров,
#          бой уходит на Изнанку (обломки мира над пустотой).
#   Фаза 4 (Изнанка)  в полную силу: + «Дождь осколков», «Луч» метёт по островам,
#                     призывает порождений, рывки за спину.
#   Сцена: на половине — замешательство: «Мало… мне не хватает сил?!» Поглощает ещё —
#          и Изнанка начинает рушиться: края островов обваливаются.
#   Фаза 5 (рушится)  последний бой: всё быстрее, парит на крыльях сбоку от героя и чуть
#                     выше (по нему можно попасть) и бьёт без передышки, «Сверхновая» — копит заряд:
#                     собьёшь уроном — рухнет оглушённым, не успеешь — удар по всем.
#   Финал: не умирает — признаёт силу героя и уходит в разлом, в другой мир, искать
#          больше силы. Бой окончен, победа засчитана.

var p: Player
var phase := 1
var _t := 0.0
var _busy := false                # идёт сцена
var _dodge_cd := 0.0
var _melee_cd := 0.0
var _charge_t := 0.0
var _charge_dmg := 0.0
var _charge_fx: Node2D
var _crumble: Node
var _lance := {}
var _diving := false
var _frenzy := false
var _gap_cd := 0.0
var _storm_fx_t := 0.0

const DODGE := [0.0, 0.55, 0.42, 0.35, 0.28, 0.22]       # шанс уйти от снаряда по фазам
const SHOTS := ["Bullet", "Arrow", "Spear", "Shuriken", "BigShuriken", "Shell", "Knife", "ThrownHammer"]
const TITLES := ["", "Странник", "Странник", "Странник — Зал Бездны", "Странник, поглотивший бездну", "Странник на грани"]

func _ready() -> void:
	name = "WandererBrain"
	p.on_lethal = _on_lethal
	p.on_hurt = _on_hurt
	p.bar_lift = 30.0
	p.set_meta("title", TITLES[1])
	_set_phase_kit(1)

func _am() -> Node:
	return p.get_tree().get_first_node_in_group("arena_mode") if p.is_inside_tree() else null

func _banner(text: String, c := Color(0.85, 0.65, 1.0), hold := 1.8) -> void:
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

func _dmg(base: float) -> int:
	return int(base * float(p.get_meta("bal_dmg", 1.0)))

# ----- набор приёмов по фазам -----
func _set_phase_kit(ph: int) -> void:
	phase = ph
	p.set_meta("title", TITLES[ph])
	match ph:
		1:
			p.speed = 200.0
			p.bot_abilities = {"staff_strike": 2.6, "void_bolt": 3.4}
		2:
			p.speed = 250.0
			p.bot_abilities = {"staff_strike": 2.2, "void_fan": 3.6, "void_lance": 6.0, "rift_mines": 8.0}
		3:
			p.speed = 260.0
			p.bot_abilities = {"staff_strike": 2.0, "void_fan": 3.4, "void_lance": 6.5, "rift_mines": 8.5,
					"abyss_chains": 7.5, "echo_strike": 9.0, "gravity_well": 11.0}
		4:
			p.speed = 280.0
			p.bot_abilities = {"staff_strike": 1.8, "void_fan": 3.0, "void_lance": 5.5, "abyss_chains": 8.0,
					"echo_strike": 8.0, "shard_rain": 6.5, "beam_sweep": 9.5, "blink_strike": 7.0, "summon": 16.0}
		5:
			# в небе на крыльях: перья, пике с мечом, клинки с неба, гроза, взмах крыльев
			p.speed = 420.0
			p.bot_abilities = {"feather_gale": 2.4, "sky_dive": 7.0, "sky_blades": 7.0, "storm_judgement": 10.0,
					"wing_burst": 3.5, "void_fan": 4.0, "nova": 20.0}
			p._bot_cd = {"nova": 9.0, "sky_dive": 3.0, "storm_judgement": 5.0}
	for k in p.bot_abilities:
		if not p._bot_cd.has(k):
			p._bot_cd[k] = randf_range(1.0, float(p.bot_abilities[k]))

func use(ab: String, to: Vector2) -> bool:
	if _busy or _charge_t > 0.0 or p._forced_time > 0.0 or not _target_ok() or p.frozen:
		return false
	var d := absf(to.x)
	match ab:
		"staff_strike":
			if d > p.body_size.x / 2 + 150.0 or absf(to.y) > 150.0:
				return false
			_staff_strike()
		"void_bolt":
			_bolt_fan(1)
		"void_fan":
			_bolt_fan(3 if phase < 5 else 5)
		"void_lance":
			if d < 160.0 or d > 1100.0 or absf(to.y) > 140.0 or not p.is_on_floor():
				return false
			_void_lance()
		"rift_mines":
			_rift_mines()
		"abyss_chains":
			AbyssAbilities._void_chains(p)
		"echo_strike":
			_echo_strike()
		"gravity_well":
			RiftAbilities._gravity_slam(p)
		"shard_rain":
			_shard_rain()
		"beam_sweep":
			_beam_sweep()
		"blink_strike":
			if to.length() > 1200.0:
				return false
			_blink_strike()
		"nova":
			_start_nova()
		"feather_gale":
			_feather_gale()
		"sky_dive":
			if _diving:
				return false
			_sky_dive()
		"sky_blades":
			_sky_blades()
		"storm_judgement":
			_storm_judgement()
		"wing_burst":
			if to.length() > 230.0:                    # только если герой подлетел ближе, чем он парит
				return false
			_wing_burst()
		_:
			return false
	return true

# ======================= каждый кадр =======================
func _physics_process(delta: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		_end_nova()
		return
	_t += delta
	_dodge_cd -= delta
	_melee_cd -= delta
	if _charge_t > 0.0:
		_nova_tick(delta)
	if _busy or p.frozen:
		return
	if phase == 1 and p.hp <= int(p.max_hp * 0.66):
		_get_serious()
	elif phase == 2 and p.hp <= int(p.max_hp * 0.33):
		_scene_hall()
	elif phase == 4 and p.hp <= int(p.max_hp * 0.5):
		_scene_breaking()
	elif phase == 5 and not _frenzy and p.hp <= int(p.max_hp * 0.3):
		_last_stand()
	if phase == 4:
		_gap_guard()
	if phase == 5 and _t > _storm_fx_t:
		_storm_fx_t = _t + randf_range(1.2, 2.6)
		_ambient_lightning()
	_dodge()

# Шаг сквозь грань: уходит от летящего в него снаряда
func _dodge() -> void:
	if _dodge_cd > 0.0 or _charge_t > 0.0 or p.is_stunned():
		return
	for n in p.get_parent().get_children():
		if not (n is Node2D) or n.get_script() == null:
			continue
		var cls: String = n.get_script().get_global_name()
		if not (cls in SHOTS) or not ("team" in n) or n.team == p.team:
			continue
		var to_me: Vector2 = p.global_position - n.global_position
		if to_me.length() > 230.0:
			continue
		var v: Vector2 = Vector2.ZERO
		if "direction" in n:
			v = n.direction
		elif "velocity" in n:
			v = n.velocity.normalized()
		if v.dot(to_me.normalized()) < 0.6:
			continue
		_dodge_cd = 0.9
		if randf() < DODGE[phase]:
			_phase_step(-signf(v.x) if v.x != 0.0 else float(-p.facing), 170.0)
		return

func _on_hurt(_amount: int, by) -> void:
	note_damage(_amount)
	# ударили вплотную — отступает
	if _busy or _melee_cd > 0.0 or by == null or not is_instance_valid(by):
		return
	if absf(by.global_position.x - p.global_position.x) < 150.0 and randf() < (0.35 if phase <= 2 else 0.22):
		_melee_cd = 3.0
		_phase_step(signf(p.global_position.x - by.global_position.x), 260.0)

func _phase_step(dir: float, dist: float) -> void:
	var world := p.get_parent()
	var from := p.global_position
	var to := Vector2(clampf(from.x + dir * dist, 140.0, p.map_w - 140.0), from.y)
	_ghost(from)
	p._col.set_deferred("disabled", true)
	p.cutscene_shield = true
	p.visible = false
	if p.rig:
		p.rig.play("blink")
	p._after(0.18, func():
		if not is_instance_valid(p):
			return
		p.global_position = to
		p.visible = true
		p.cutscene_shield = false
		p._col.set_deferred("disabled", false)
		Fx.sparks(world, to, RiftRig.GLOW, 10, 200.0, 4.0))
	Fx.sparks(world, from, RiftRig.GLOW, 8, 200.0, 4.0)

# Тающий силуэт на месте, откуда он ушёл
func _ghost(at: Vector2) -> void:
	var g := RiftRig.new()
	g.kind = "wanderer"
	g.size = p.body_size
	g.puppet_facing = p.facing
	g.modulate = Color(0.8, 0.6, 1.0, 0.6)
	p.get_parent().add_child(g)
	g.global_position = at
	if p.rig and "awake" in p.rig:
		g.awaken(p.rig.awake)
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.45)
	t.tween_callback(g.queue_free)

# ======================= приёмы =======================
func _staff_strike() -> void:
	var world := p.get_parent()
	p._anim("swing")
	p._forced_time = 0.55
	p._forced_vx = 0.0
	Fx.star(world, p.global_position + Vector2(p.facing * 40.0, -30.0), 12.0, Color(0.9, 0.7, 1.0), 0.3)
	p._after(0.32, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		var at := p.global_position + Vector2(p.facing * (p.body_size.x / 2 + 70.0), -10.0)
		RiftAbilities.swing_arc(world, at, 90.0, p.facing)
		for n in RiftAbilities._foes(p):
			var dd: Vector2 = n.global_position - p.global_position
			if signf(dd.x) == p.facing and absf(dd.x) < p.body_size.x / 2 + 150.0 and absf(dd.y) < 110.0:
				n.take_damage(_dmg(14.0 + phase * 2.0), p)
				n.velocity = Vector2(p.facing * 360.0, -260.0))

func _bolt_fan(n: int) -> void:
	p._anim("cast")
	p._forced_time = 0.35
	p._forced_vx = 0.0
	var from: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	var base: Vector2 = (p.target.global_position - from).normalized()
	for k in n:
		var a := (k - (n - 1) / 2.0) * 0.16
		var b := RiftAbilities.bolt(p, from, base.rotated(a), 520.0 + phase * 40.0, _dmg(9.0), 13.0, 0)
		b.homing = 140.0 if phase >= 3 else 0.0

func _void_lance() -> void:
	var world := p.get_parent()
	var dir := signf(p.target.global_position.x - p.global_position.x)
	if dir == 0.0:
		dir = float(p.facing)
	p.facing = int(dir)
	var y := p.global_position.y
	var x0 := p.global_position.x
	var x1 := clampf(x0 + dir * 650.0, 140.0, p.map_w - 140.0)
	LightBeam.aim_line(world, Vector2(x0, y), Vector2(x1, y), RiftRig.GLOW, 0.5)
	p._anim("windup")
	p._forced_time = 0.5
	p._forced_vx = 0.0
	_lance.clear()
	p._after(0.5, func():
		if not is_instance_valid(p) or not p.is_alive() or _busy:
			return
		p._anim("punch")
		var from := p.global_position
		var t := p.create_tween()
		t.tween_method(func(k: float):
			if not is_instance_valid(p):
				return
			p.global_position.x = lerpf(from.x, x1, k)
			for n in RiftAbilities._foes(p):
				if _lance.has(n):
					continue
				if absf(n.global_position.x - p.global_position.x) < 50.0 + n.body_size.x / 2 and absf(n.global_position.y - from.y) < 90.0:
					_lance[n] = true
					n.take_damage(_dmg(18.0), p)
					n.velocity = Vector2(dir * 300.0, -420.0), 0.0, 1.0, 0.28)
		LightBeam.draw(world, [[from, Vector2(x1, from.y), 0]], Color(0.85, 0.55, 1.0), 10.0, 0.3))

func _rift_mines() -> void:
	var world := p.get_parent()
	p._anim("cast")
	var tx: float = p.target.global_position.x
	var fy := _floor_y()
	for k in 3:
		var x := clampf(tx + (k - 1) * 170.0 + randf_range(-30, 30), 140.0, p.map_w - 140.0)
		var gy := RiftAbilities._ground(p, Vector2(x, fy - 500.0))
		var s := RiftAbilities.Slit.new()
		s.position = Vector2(x, gy)
		s.height = 50.0
		s.wide = 1.4
		s.life = 1.3
		world.add_child(s)
		var at := Vector2(x, gy - 20.0)
		p._after(1.1, func():
			if is_instance_valid(p):
				Util.explode(world, at, 75.0, _dmg(14.0), 18, p.team, p)
				Fx.sparks(world, at, RiftRig.GLOW, 10, 240.0, 4.0))

func _echo_strike() -> void:
	var world := p.get_parent()
	var t: Player = p.target
	p._anim("cast")
	for side in [-1.0, 1.0]:
		var at := t.global_position + Vector2(side * 120.0, 0)
		var g := RiftRig.new()
		g.kind = "wanderer"
		g.size = p.body_size
		g.puppet_facing = int(-side)
		g.modulate = Color(0.75, 0.55, 1.0, 0.0)
		world.add_child(g)
		g.global_position = Vector2(at.x, at.y + t.body_size.y / 2 - p.body_size.y / 2)
		var gt := g.create_tween()
		gt.tween_property(g, "modulate:a", 0.75, 0.25)
		gt.tween_interval(0.35)
		gt.tween_callback(func():
			if is_instance_valid(g):
				g.play("swing")
				RiftAbilities.swing_arc(world, g.global_position + Vector2(-side * 50.0, 0), 80.0, int(-side))
				for n in RiftAbilities._foes(p):
					if n.global_position.distance_to(g.global_position + Vector2(-side * 60.0, 0)) < 110.0:
						n.take_damage(_dmg(12.0), p))
		gt.tween_property(g, "modulate:a", 0.0, 0.3)
		gt.tween_callback(g.queue_free)

func _shard_rain() -> void:
	var world := p.get_parent()
	p._anim("summon")
	for n in RiftAbilities._foes(p):
		for k in 3:
			var x := clampf(n.global_position.x + (k - 1) * 120.0 + randf_range(-30, 30), 120.0, p.map_w - 120.0)
			var gy := RiftAbilities._ground(p, Vector2(x, n.global_position.y - 60.0))
			RiftAbilities.drop_shard(world, p, Vector2(x + randf_range(-80, 80), gy - 900.0), Vector2(x, gy), 1.0 + k * 0.12, _dmg(12.0))

func _beam_sweep() -> void:
	var world := p.get_parent()
	var fy := _floor_y()
	var dir := 1.0 if randf() < 0.5 else -1.0
	var xa := 140.0 if dir > 0 else p.map_w - 140.0
	var xb := p.map_w - 140.0 if dir > 0 else 140.0
	var y := fy - 26.0
	LightBeam.aim_line(world, Vector2(xa, y), Vector2(xb, y), RiftRig.GLOW, 0.9)
	_banner("Луч! Прыгай!", Color(0.9, 0.6, 1.0), 0.9)
	p._anim("cast")
	var hit := {}
	p._after(0.9, func():
		if not is_instance_valid(p):
			return
		var steps := 22
		for k in steps:
			p._after(k * 0.035, func():
				if not is_instance_valid(p):
					return
				var x := lerpf(xa, xb, float(k) / (steps - 1))
				LightBeam.draw(world, [[Vector2(x - dir * 120.0, y), Vector2(x, y), 0]], Color(0.85, 0.5, 1.0), 14.0, 0.15)
				for n in RiftAbilities._foes(p):
					if hit.has(n):
						continue
					var feet: float = n.global_position.y + n.body_size.y / 2
					if absf(n.global_position.x - x) < 70.0 and feet > y - 40.0 and feet < y + 60.0:
						hit[n] = true
						n.take_damage(_dmg(18.0), p)))

func _blink_strike() -> void:
	var t: Player = p.target
	var side := -float(t.facing) if t.facing != 0 else 1.0
	var at := Vector2(clampf(t.global_position.x + side * 110.0, 140.0, p.map_w - 140.0), t.global_position.y + t.body_size.y / 2 - p.body_size.y / 2)
	_ghost(p.global_position)
	Fx.sparks(p.get_parent(), p.global_position, RiftRig.GLOW, 10, 200.0, 4.0)
	p.global_position = at
	p.velocity = Vector2.ZERO
	p.facing = 1 if t.global_position.x > at.x else -1
	Fx.sparks(p.get_parent(), at, RiftRig.GLOW, 10, 200.0, 4.0)
	p._after(0.25, _staff_strike)

# ----- «Сверхновая»: копит заряд — сбей уроном -----
func _start_nova() -> void:
	var world := p.get_parent()
	_charge_t = 3.0
	_charge_dmg = 0.0
	p._anim("summon")
	p._forced_time = 3.1
	p._forced_vx = 0.0
	_banner("Сверхновая! Сбей заряд уроном!", Color(1.0, 0.65, 1.0), 1.6)
	_charge_fx = Node2D.new()
	_charge_fx.z_index = 6
	p.add_child(_charge_fx)
	var r := Line2D.new()
	var pts := Util.circle(1.0, 28)
	pts.append(pts[0])
	r.points = pts
	r.width = 0.04
	r.default_color = RiftRig.CORE
	r.name = "R"
	_charge_fx.add_child(r)
	var bar := ColorRect.new()
	bar.name = "Need"
	bar.color = Color(1, 1, 1, 0.9)
	bar.size = Vector2(0, 8)
	bar.position = Vector2(-80, -p.body_size.y / 2.0 - 84.0)
	_charge_fx.add_child(bar)
	var bg := ColorRect.new()
	bg.color = Color(0.3, 0.1, 0.4, 0.8)
	bg.size = Vector2(160, 8)
	bg.position = bar.position
	bg.show_behind_parent = true
	_charge_fx.add_child(bg)
	_charge_fx.move_child(bg, 0)
	Fx.ring(world, p.global_position, 320.0, RiftRig.GLOW, 0.5, 8.0)

func _nova_tick(delta: float) -> void:
	_charge_t -= delta
	var need := p.max_hp * 0.06
	var k := clampf(_charge_dmg / need, 0.0, 1.0)
	if _charge_fx and is_instance_valid(_charge_fx):
		var r: Line2D = _charge_fx.get_node_or_null("R")
		if r:
			var rad := 460.0 * (_charge_t / 3.0) + 50.0
			r.scale = Vector2(rad, rad * 0.8)
			r.rotation += delta * 2.5
		var nb: ColorRect = _charge_fx.get_node_or_null("Need")
		if nb:
			nb.size.x = 160.0 * k
	var world := p.get_parent()
	if k >= 1.0:
		_end_nova()
		p._forced_time = 0.0
		Util.flash(world, p.global_position, 220.0, Color(1.0, 0.9, 1.0, 0.9))
		_banner("Заряд сорван!", Color(1.0, 0.85, 0.4))
		p.stun(3.0)
		return
	if _charge_t <= 0.0:
		_end_nova()
		Util.flash(world, p.global_position, 900.0, Color(0.9, 0.6, 1.0, 0.85))
		Fx.shake(world, 14.0)
		Fx.ring(world, p.global_position, 1300.0, RiftRig.GLOW, 0.7, 14.0)
		for n in RiftAbilities._foes(p):
			n.take_damage(_dmg(22.0), p)
		p._forced_time = 1.0

func _end_nova() -> void:
	_charge_t = 0.0
	if _charge_fx and is_instance_valid(_charge_fx):
		_charge_fx.queue_free()
	_charge_fx = null

# Урон по нему во время заряда копится (сбивает Сверхновую)
func note_damage(amount: int) -> void:
	if _charge_t > 0.0:
		_charge_dmg += amount

# ======================= сцены =======================
func _freeze_for_scene() -> void:
	_busy = true
	_end_nova()
	p.cutscene_shield = true
	p.frozen = true
	p.velocity = Vector2.ZERO
	p._forced_time = 0.0
	p.stagger = 0.0
	p._stun_t = 0.0
	p.visible = true
	p._col.set_deferred("disabled", false)
	if p._stun_fx:
		p._stun_fx.visible = false
	var am := _am()
	if am:
		for b in am._alive.duplicate():
			if is_instance_valid(b) and b != p and b.is_alive():
				Util.flash(p.get_parent(), b.global_position, 50.0, Color(0.8, 0.45, 1.0, 0.8))
				b.take_damage(99999)

func _resume(ph: int) -> void:
	if not is_instance_valid(p):
		return
	_set_phase_kit(ph)
	if ph == 5:
		_take_wing()
	_busy = false
	p.frozen = false
	p.cutscene_shield = false

func _heal_to(frac: float, time := 1.2) -> void:
	var goal := int(p.max_hp * frac)
	var ht := p.create_tween()
	ht.tween_method(func(v: float):
		if is_instance_valid(p) and p.is_alive():
			p.hp = maxi(p.hp, int(v)), float(p.hp), float(goal), time)
	Fx.sparks(p.get_parent(), p.global_position, RiftRig.CORE, 20, 260.0, 4.0)

# Втягивает бездну: фиолетовые нити со всех сторон сходятся в нём
func _absorb(time: float, n: int) -> void:
	var world := p.get_parent()
	for k in n:
		p._after(k * time / n, func():
			if not is_instance_valid(p):
				return
			var c := p.global_position + Vector2(0, -p.body_size.y * 0.25)
			var from := c + Vector2.from_angle(randf() * TAU) * randf_range(500, 900)
			var l := Line2D.new()
			l.width = 4.0
			l.default_color = Color(0.78, 0.40, 1.0, 0.8)
			l.points = PackedVector2Array([from, from.lerp(c, 0.2)])
			l.z_index = 7
			world.add_child(l)
			var lt := l.create_tween()
			lt.tween_method(func(q: float):
				if is_instance_valid(l):
					l.points = PackedVector2Array([from.lerp(c, q), from.lerp(c, minf(1.0, q + 0.25))]), 0.0, 0.8, 0.45)
			lt.tween_callback(l.queue_free))

func _get_serious() -> void:
	_freeze_for_scene()
	if p.rig:
		p.rig.play("roar")
		if p.rig.has_method("awaken"):
			p.rig.awaken(1)
	_banner("Странник: «Неплохо. Тогда — чуть серьёзнее.»", Color(0.85, 0.7, 1.0), 2.0)
	var world := p.get_parent()
	Fx.ring(world, p.global_position, 300.0, RiftRig.GLOW, 0.5, 8.0)
	for n in RiftAbilities._foes(p):
		if n.global_position.distance_to(p.global_position) < 300.0:
			n.velocity = Vector2(signf(n.global_position.x - p.global_position.x + 0.01) * 520.0, -360.0)
	p._after(1.3, _resume.bind(2))

# Треть здоровья: лечится и уводит бой в Зал Бездны
func _scene_hall() -> void:
	_freeze_for_scene()
	var am := _am()
	var world := p.get_parent()
	if am:
		am.cinematic(p, 6.2)
		am.shield_heroes(7.5)
	_banner("Странник: «Хватит разминки.»", Color(0.85, 0.7, 1.0), 2.0)
	if p.rig:
		p.rig.play("summon")
	p._after(0.6, func(): _absorb(1.4, 14))
	p._after(1.4, func(): _heal_to(1.0, 1.0))
	p._after(2.4, func():
		if not is_instance_valid(p):
			return
		Fx.shake(world, 10.0)
		Util.flash(world, p.global_position, 400.0, Color(0.85, 0.6, 1.0, 0.9)))
	p._after(2.6, func():
		if am == null or not is_instance_valid(p):
			return
		var cx := Colosseum.W / 2.0
		am.relocate(func(w: Node) -> Dictionary: return AbyssStages.hall(w), [p], func():
			am.place_name = AbyssStages.HALL_NAME
			if is_instance_valid(p):
				p.global_position = Vector2(cx + 300.0, am.info["floor"] - p.body_size.y / 2 - 2.0)
				p.facing = -1
				if p.rig and p.rig.has_method("awaken"):
					p.rig.awaken(2)
			am.cut_jump(Vector2(cx, am.info["floor"] - 300.0)), [cx - 420.0, cx - 300.0]))
	p._after(4.6, func(): _banner("Бой переходит в Зал Бездны!", Color(0.85, 0.7, 1.0), 1.4))
	p._after(6.0, func():
		_resume(3)
		if am:
			am._name_card("wanderer", TITLES[3], "ТРЕТЬЯ ФАЗА"))

# Повержен в Зале: поглощает больше бездны, бой уходит на Изнанку
func _on_lethal() -> bool:
	if _busy:
		p.hp = maxi(p.hp, 1)
		return true
	match phase:
		3:
			p.hp = 1
			_scene_abyss()
			return true
		5:
			p.hp = 1
			_scene_depart()
			return true
		1, 2:
			p.hp = 1                         # сразу из первых фаз не погибает — идёт по сценарию
			_scene_hall()
			return true
		4:
			p.hp = 1
			_scene_breaking()
			return true
	return false

func _scene_abyss() -> void:
	_freeze_for_scene()
	var am := _am()
	var world := p.get_parent()
	if am:
		am.cinematic(p, 7.6)
		am.shield_heroes(9.0)
	Engine.time_scale = 0.35
	p.get_tree().create_timer(0.7, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	if p.rig:
		p.rig.play("kneel")
	_banner("Странник повержен…", Color(0.85, 0.7, 1.0), 1.6)
	p._after(1.7, func(): _banner("Странник: «…Так вот она какая — сила, которую я взял.»", Color(0.85, 0.7, 1.0), 2.2))
	p._after(2.4, func(): _absorb(2.2, 26))
	p._after(3.2, func():
		_heal_to(1.0, 1.4)
		if p.rig and p.rig.has_method("awaken"):
			p.rig.awaken(3)
			p.rig.play("roar"))
	p._after(4.2, func():
		if is_instance_valid(p):
			Fx.shake(world, 14.0)
			Util.flash(world, p.global_position, 700.0, Color(0.9, 0.6, 1.0, 0.95)))
	p._after(4.4, func():
		if am == null or not is_instance_valid(p):
			return
		Audio.intensity(3)                       # дальше — в полную силу
		var cx := Colosseum.W / 2.0
		am.relocate(func(w: Node) -> Dictionary: return AbyssStages.abyss(w), [p], func():
			am.place_name = AbyssStages.ABYSS_NAME
			if is_instance_valid(p):
				p.global_position = Vector2(cx + 280.0, am.info["floor"] - p.body_size.y / 2 - 2.0)
				p.facing = -1
			am.cut_jump(Vector2(cx, am.info["floor"] - 320.0)), [cx - 420.0, cx - 300.0]))
	p._after(6.0, func(): _banner("Странник: «Теперь — в полную силу.»", Color(0.9, 0.65, 1.0), 1.6))
	p._after(7.4, func():
		_resume(4)
		if am:
			am._name_card("wanderer", TITLES[4], "ЧЕТВЁРТАЯ ФАЗА"))

# Половина здоровья на Изнанке: замешательство — ему мало сил; Изнанка рушится
func _scene_breaking() -> void:
	_freeze_for_scene()
	var am := _am()
	var world := p.get_parent()
	if am:
		am.cinematic(p, 6.4)
		am.shield_heroes(7.6)
	if p.rig:
		p.rig.play("kneel")
	_banner("Странник: «Мало… Мне не хватает сил?!»", Color(1.0, 0.7, 0.85), 2.0)
	p._after(2.0, func():
		_absorb(2.0, 34)
		if p.rig:
			p.rig.play("roar"))
	p._after(3.2, func():
		_heal_to(0.85, 1.2)
		if p.rig and p.rig.has_method("awaken"):
			p.rig.awaken(4)
		if p.rig and p.rig.has_method("set_wings"):
			p.rig.set_wings(true)                    # за спиной раскрываются крылья бездны
		_feather_burst(40)
		Fx.shake(world, 16.0)
		Util.flash(world, p.global_position, 900.0, Color(1.0, 0.7, 1.0, 0.95))
		if am:
			_crumble = AbyssStages.start_collapse(world, am.info))
	p._after(4.2, func(): _banner("Странник: «Тогда я возьму всё!» — Изнанка рушится!", Color(1.0, 0.6, 0.6), 1.8))
	p._after(6.2, func():
		_resume(5)
		p.ab_tempo *= 1.25
		if am:
			am._name_card("wanderer", TITLES[5], "ПОСЛЕДНИЙ БОЙ"))

# Финал: не умирает — признаёт силу героя и уходит в разлом
func _scene_depart() -> void:
	_freeze_for_scene()
	var am := _am()
	var world := p.get_parent()
	if _crumble and is_instance_valid(_crumble):
		_crumble.queue_free()
	if am:
		am.cinematic(p, 8.6)
		am.shield_heroes(11.0)
	Engine.time_scale = 0.35
	p.get_tree().create_timer(0.8, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	if p.rig:
		p.rig.play("kneel")
		if p.rig.has_method("awaken"):
			p.rig.awaken(1)
	p.set_tint(Color(0.9, 0.85, 1.0))
	_banner("Странник опускает меч…", Color(0.85, 0.75, 1.0), 1.6)
	p._after(1.8, func(): _banner("Странник: «Ты сильнее, чем я думал.»", Color(0.85, 0.75, 1.0), 2.2))
	p._after(4.0, func(): _banner("«Этого мира мне мало. Я найду больше силы — там, за гранью.»", Color(0.85, 0.75, 1.0), 2.6))
	var rift: Node2D = null
	p._after(4.4, func():
		if not is_instance_valid(p):
			return
		var s := RiftAbilities.Slit.new()
		s.position = p.global_position + Vector2(-p.facing * 90.0, p.body_size.y / 2)
		s.height = 260.0
		s.wide = 3.0
		s.life = 4.0
		world.add_child(s)
		Fx.shake(world, 8.0))
	p._after(6.2, func():
		if not is_instance_valid(p):
			return
		if p.rig:
			p.rig.play("blink")
		var t := p.create_tween()
		t.tween_property(p, "modulate:a", 0.0, 0.9)
		Fx.sparks(world, p.global_position, RiftRig.GLOW, 30, 260.0, 4.0))
	p._after(7.4, func():
		if is_instance_valid(p):
			Util.flash(world, p.global_position, 300.0, Color(1.0, 0.9, 1.0, 0.95))
			Fx.ring(world, p.global_position, 400.0, RiftRig.GLOW, 0.5, 10.0)
		_banner("Странник ушёл в разлом.", Color(1.0, 0.85, 0.4), 2.0)
		if am:
			am.boss_departs(p))


# ======================= Изнанка: не падает в пропасти =======================
func _gap_guard() -> void:
	if _t < _gap_cd or p.flying or _charge_t > 0.0:
		return
	var fy := _floor_y()
	var gy := RiftAbilities._ground(p, p.global_position)
	if gy < fy + 60.0 and p.global_position.y < fy + 20.0:
		return
	_gap_cd = _t + 1.0
	var am := _am()
	if am == null:
		return
	var best: Node2D = null
	var bd := INF
	for s in am.info.get("isle_segs", []):
		if is_instance_valid(s) and not s.get_meta("falling", false):
			var d := absf(s.global_position.x - p.global_position.x)
			if d < bd:
				bd = d
				best = s
	if best == null:
		return
	_ghost(p.global_position)
	p.global_position = Vector2(best.global_position.x, fy - p.body_size.y / 2 - 4.0)
	p.velocity = Vector2.ZERO
	Util.flash(p.get_parent(), p.global_position, 60.0, Color(0.85, 0.6, 1.0, 0.85))

# ======================= последняя фаза: в небе на крыльях =======================
func _take_wing() -> void:
	p.flying = true
	p.fly_side = true                                 # парит сбоку от героя, чуть выше — по нему можно попасть
	p.fly_hover = Vector2(300.0, -95.0)
	p.ignore_one_way_platforms()
	p.velocity = Vector2(0, -650)
	if p.rig and p.rig.has_method("set_wings"):
		p.rig.set_wings(true)
	_feather_burst(16)

# Перья осыпаются с крыльев
func _feather_burst(n: int) -> void:
	var world := p.get_parent()
	for k in n:
		var f := Polygon2D.new()
		f.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -2.5), Vector2(7, 0), Vector2(0, 2.5)])
		f.color = Color(0.08, 0.06, 0.11) if k % 3 else Color(0.55, 0.30, 0.85)
		f.position = p.global_position + Vector2(randf_range(-60, 60), randf_range(-70, 10))
		f.rotation = randf() * TAU
		f.z_index = 6
		world.add_child(f)
		var t := f.create_tween()
		t.set_parallel(true)
		t.tween_property(f, "position", f.position + Vector2(randf_range(-160, 160), randf_range(120, 320)), 1.6)
		t.tween_property(f, "rotation", f.rotation + randf_range(-4.0, 4.0), 1.6)
		t.tween_property(f, "modulate:a", 0.0, 1.6).set_delay(0.6)
		t.chain().tween_callback(f.queue_free)

func _feather_shot(b: Bullet) -> void:
	if b._vis2:
		for c in b._vis2.get_children():
			c.queue_free()
		var f := Polygon2D.new()
		f.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-4, -3), Vector2(10, 0), Vector2(-4, 3)])
		f.color = Color(0.08, 0.06, 0.11)
		b._vis2.add_child(f)
		var e := Polygon2D.new()
		e.polygon = PackedVector2Array([Vector2(-2, -1), Vector2(10, 0), Vector2(-2, 1)])
		e.color = Color(0.80, 0.55, 1.0)
		b._vis2.add_child(e)

# Взмах крыльев — веер перьев-клинков
func _feather_gale() -> void:
	p._anim("cast")
	var from := p.global_position + Vector2(0, -12)
	var aim: Variant = (p.target.global_position - from).normalized()
	var n := 9 if _frenzy else 7
	for i in n:
		var b := RiftAbilities.bolt(p, from, aim.rotated((i - (n - 1) / 2.0) * 0.12), 660.0, _dmg(7.0), 10.0, 0)
		_feather_shot(b)
	_feather_burst(6)

# Пике: метит точку, падает на неё с мечом, бьёт оземь и на миг застревает — окно для удара
func _sky_dive() -> void:
	var world := p.get_parent()
	var fy := _floor_y()
	var x := clampf(p.target.global_position.x, 160.0, Colosseum.W - 160.0)
	var gy := RiftAbilities._ground(p, Vector2(x, fy - 500.0))
	var solid := gy < fy + 60.0
	var land := Vector2(x, (gy if solid else fy) - p.body_size.y / 2 - 2.0)
	_diving = true
	p._anim("roar")
	p.velocity = Vector2(0, -200)
	LightBeam.aim_line(world, p.global_position, land + Vector2(0, p.body_size.y / 2), Color(0.85, 0.55, 1.0), 0.75)
	Fx.rune_circle(world, Vector2(x, land.y + p.body_size.y / 2), 150.0, Color(0.85, 0.5, 1.0, 0.9), 0.75)
	p._after(0.75, func():
		if not is_instance_valid(p) or not p.is_alive() or _busy:
			_diving = false
			return
		p._anim("slam")
		p._dive_v = (land - p.global_position) / 0.28
		p._dive_t = 0.28)
	p._after(1.05, func(): _dive_impact(land, solid))

func _dive_impact(land: Vector2, solid: bool) -> void:
	if not is_instance_valid(p) or not p.is_alive() or _busy:
		_diving = false
		return
	var world := p.get_parent()
	var at := land + Vector2(0, p.body_size.y / 2)
	p._dive_t = 0.0
	p.global_position = land
	p.velocity = Vector2.ZERO
	Fx.shake(world, 13.0)
	Fx.ring(world, at, 210.0, Color(0.9, 0.6, 1.0, 0.95), 0.45, 10.0, 0.3)
	Fx.sparks(world, at, RiftRig.GLOW, 26, 380.0, 5.0, true)
	Fx.cracks(world, at, Color(0.30, 0.10, 0.40), 200.0)
	for n in AbyssAbilities._foes(p):
		if n.global_position.distance_to(at + Vector2(0, -40)) < 210.0:
			n.take_damage(_dmg(16.0), p)
			n.velocity = Vector2(signf(n.global_position.x - at.x) * 520.0, -420.0)
	if solid:
		var gw := HardMode.GroundWave.new()
		gw.src = weakref(p)
		gw.col = Color(0.80, 0.50, 1.0)
		gw.fy = at.y
		gw.dmg = _dmg(9.0)
		world.add_child(gw)
		gw.start(at.x)
		# меч застрял в камне: 1,4 с стоит на земле — бей!
		p.flying = false
		p._forced_time = 1.4
		p._forced_vx = 0.0
		if p.rig:
			p.rig.play("kneel")
	p._after(1.45 if solid else 0.3, func():
		_diving = false
		if is_instance_valid(p) and p.is_alive() and phase == 5 and not _busy:
			p.flying = true
			p.velocity = Vector2(0, -700)
			_feather_burst(8))

# Клинки с неба: над героем вспыхивают круги, сверху падают призрачные мечи
func _sky_blades() -> void:
	p._anim("cast")
	var fy := _floor_y()
	var tx: float = p.target.global_position.x
	var n := 7 if _frenzy else 5
	for k in n:
		var x := clampf(tx + (k - (n - 1) / 2.0) * 160.0 + randf_range(-25, 25), 140.0, Colosseum.W - 140.0)
		var gy := RiftAbilities._ground(p, Vector2(x, fy - 600.0))
		p._after(k * 0.16, func(): _blade_drop(Vector2(x, minf(gy, fy + 40.0))))

func _blade_drop(at: Vector2) -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	Fx.rune_circle(world, at, 58.0, Color(0.85, 0.5, 1.0, 0.9), 0.8)
	var sw := Polygon2D.new()
	sw.polygon = PackedVector2Array([Vector2(-5, -150), Vector2(5, -150), Vector2(5, -40), Vector2(0, 0), Vector2(-5, -40)])
	sw.color = Color(0.85, 0.75, 1.0, 0.85)
	var guard := Polygon2D.new()
	guard.polygon = PackedVector2Array([Vector2(-18, -150), Vector2(18, -150), Vector2(14, -144), Vector2(-14, -144)])
	guard.color = Color(0.30, 0.18, 0.45)
	sw.add_child(guard)
	sw.position = Vector2(at.x, at.y - 900.0)
	sw.z_index = 6
	world.add_child(sw)
	var who: WeakRef = weakref(p)
	var t := sw.create_tween()
	t.tween_interval(0.62)
	t.tween_property(sw, "position", at, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		var src: Variant = who.get_ref()
		for h in HardMode.heroes(world):
			if absf(h.global_position.x - at.x) < 58.0 + h.body_size.x * 0.4 and absf(h.global_position.y - (at.y - 40.0)) < 90.0:
				h.take_damage(_dmg(13.0), src if is_instance_valid(src) else null)
				h.velocity.y = -360.0
		Fx.sparks(world, at, Color(0.85, 0.6, 1.0), 12, 280.0, 4.0, true)
		Fx.shake(world, 3.0))
	t.tween_interval(0.5)
	t.tween_property(sw, "modulate:a", 0.0, 0.3)
	t.tween_callback(sw.queue_free)

# Гроза: в столбах вспыхивают знаки, через миг туда бьют лиловые молнии (две волны)
func _storm_judgement() -> void:
	p._anim("roar")
	var world := p.get_parent()
	Fx.shake(world, 5.0)
	for wv in 2:
		p._after(wv * 1.1, func():
			if not is_instance_valid(p) or not p.is_alive() or _busy:
				return
			var xs: Array = []
			if _target_ok():
				xs.append(p.target.global_position.x)
			while xs.size() < (8 if _frenzy else 6):
				xs.append(randf_range(150.0, Colosseum.W - 150.0))
			for x in xs:
				_strike_column(float(x)))

func _strike_column(x: float) -> void:
	var world := p.get_parent()
	var fy := _floor_y()
	var gy := minf(RiftAbilities._ground(p, Vector2(x, fy - 700.0)), fy + 40.0)
	var top := Vector2(x, fy - 1000.0)
	var bot := Vector2(x, gy)
	var warn := Line2D.new()
	warn.points = PackedVector2Array([top, bot])
	warn.width = 26.0
	warn.default_color = Color(0.75, 0.40, 1.0, 0.18)
	world.add_child(warn)
	Fx.rune_circle(world, bot, 50.0, Color(0.85, 0.5, 1.0, 0.8), 0.85)
	p._after(0.85, func():
		if is_instance_valid(warn):
			warn.queue_free()
		if not is_instance_valid(p):
			return
		Fx.bolt(world, top, bot, Color(0.85, 0.6, 1.0))
		LightBeam.draw(world, [[top, bot, 0]], Color(0.85, 0.55, 1.0), 12.0, 0.25)
		RiftAbilities.hit_segment(p, top, bot, 34.0, _dmg(14.0), 0)
		Util.flash(world, bot, 70.0, Color(0.95, 0.85, 1.0, 0.9)))

# Взмах крыльев: если герой подлетел близко — отбрасывает его ударной волной
func _wing_burst() -> void:
	var world := p.get_parent()
	p._anim("roar")
	Fx.ring(world, p.global_position, 300.0, Color(0.85, 0.55, 1.0, 0.9), 0.4, 9.0)
	_feather_burst(14)
	for n in AbyssAbilities._foes(p):
		if n.global_position.distance_to(p.global_position) < 300.0:
			n.take_damage(_dmg(10.0), p)
			n.velocity = (n.global_position - p.global_position).normalized() * 760.0 + Vector2(0, -200)

# Последний натиск (30% в последней фазе): гроза почти без передышки
func _last_stand() -> void:
	_frenzy = true
	_banner("Странник: «Я не отступлю — не сейчас!»", Color(1.0, 0.6, 0.85), 1.8)
	p.ab_tempo *= 1.2
	p.fly_hover = Vector2(320.0, -110.0)
	p.bot_abilities["storm_judgement"] = 6.5
	p._bot_cd["storm_judgement"] = 1.0
	Util.flash(p.get_parent(), p.global_position, 500.0, Color(0.9, 0.6, 1.0, 0.8))
	_feather_burst(30)

# Фон последней фазы: далёкие молнии без урона
func _ambient_lightning() -> void:
	var world := p.get_parent()
	var x := randf_range(100.0, Colosseum.W - 100.0)
	var fy := _floor_y()
	Fx.bolt(world, Vector2(x, fy - 1100.0), Vector2(x + randf_range(-120, 120), fy - randf_range(300.0, 700.0)), Color(0.75, 0.55, 1.0, 0.7))
