class_name AbyssLordBrain
extends Node
# ---------- Лорд Бездны (волна 102, только сложная Арена) ----------
# Тёмный Лорд, собранный бездной заново. Три фазы, у каждой — своя слабость:
#   1 (100–60%) «Доспех Бездны»: урон по нему ×0.55. После «Клинка затмения» (удар оземь,
#     по полу бегут разломы) его сердце раскрывается на 2,8 с — урон ×1,7.
#   2 (60–25%) «Пожиратель света»: арена тонет во тьме, во тьме он почти неуязвим (×0.35),
#     но стоят три Столпа рассвета. Заманишь Лорда в столп — свет обжигает: столп гаснет,
#     Лорд оглушён и открыт (×2). Столпы отрастают. Герой в столпе понемногу лечится.
#   3 (25–0%) «Поглощённый»: парит над ареной, держась за три Якоря Бездны — пока они целы,
#     он неуязвим. Разбей якоря — рухнет, оглушён и открыт; через 12 с якоря вернутся.

const ARMOR := 0.55
const DARK_ARMOR := 0.35
const GLOW := Color(0.80, 0.45, 1.0)
const DAWN := Color(1.0, 0.86, 0.45)

var p: Player
var phase := 1
var _busy := false
var _cd := {}
var _open_t := 0.0                 # сердце раскрыто
var _heart: Polygon2D
var _tendrils: Array = []
var _t := 0.0
var _hinted := false
var _pillars: Array = []           # [узел, x, жив, через сколько отрастёт]
var _anchors: Array = []
var _chains: Array = []
var _fallen_t := 0.0
var _regrow_t := 0.0

func _ready() -> void:
	name = "AbyssLordBrain"
	p.armor_mult = ARMOR
	p.on_lethal = _on_lethal
	p.bar_lift = 40.0
	p.set_meta("title", "Лорд Бездны")
	p.bot_abilities = {"swing": 1.8}
	_cd = {"eclipse": 5.0, "chains": 7.0, "stars": 9.0, "shades": 14.0}
	(func(): _build_visuals()).call_deferred()       # герой ещё собирается — детей добавим кадром позже

func _build_visuals() -> void:
	if not is_instance_valid(p):
		return
	_heart = Polygon2D.new()
	_heart.polygon = PackedVector2Array([Vector2(0, -16), Vector2(12, -2), Vector2(0, 16), Vector2(-12, -2)])
	_heart.color = Color(1.0, 0.75, 1.0, 0.0)
	_heart.position = Vector2(0, -p.body_size.y * 0.18)
	_heart.z_index = 8
	p.add_child(_heart)
	for k in 4:                                    # щупальца бездны из-под плаща
		var l := Line2D.new()
		l.width = 7.0 - k
		l.default_color = Color(0.20, 0.08, 0.30, 0.85)
		l.z_index = -1
		p.add_child(l)
		_tendrils.append(l)

func _am() -> Node:
	return p.get_tree().get_first_node_in_group("arena_mode") if p.is_inside_tree() else null

func _dmg(base: float) -> int:
	return int(base * float(p.get_meta("bal_dmg", 1.0)) / 1.5)

func _fy() -> float:
	var am := _am()
	return float(am.info["floor"]) if am else Colosseum.FLOOR_Y

func _banner(t: String, c := Color(0.9, 0.6, 1.0), hold := 1.8) -> void:
	var am := _am()
	if am and am.hud:
		am.hud.show_banner(t, c)
		am._after(hold, am.hud.hide_banner)

func _process(_delta: float) -> void:
	if not is_instance_valid(p):
		return
	var tt := Time.get_ticks_msec() * 0.003
	for k in _tendrils.size():
		var l: Line2D = _tendrils[k]
		var base := Vector2(-p.facing * 14.0, -p.body_size.y * 0.15 + k * 10.0)
		var pts := PackedVector2Array()
		for s in 6:
			pts.append(base + Vector2(-p.facing * s * 16.0, s * 9.0 + sin(tt + k + s * 0.7) * 8.0))
		l.points = pts
	if _heart == null:
		return
	if _open_t > 0.0:
		_heart.color.a = 0.7 + 0.3 * sin(tt * 6.0)
		_heart.scale = Vector2.ONE * (1.0 + 0.2 * sin(tt * 6.0))
	else:
		_heart.color.a = 0.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		_cleanup()
		return
	_t += delta
	if _open_t > 0.0:
		_open_t -= delta
		if _open_t <= 0.0:
			_close_heart()
	_tick_pillars(delta)
	_tick_anchors(delta)
	if _busy or p.frozen or p.cutscene_shield or p.is_stunned():
		return
	if phase == 1 and p.hp <= int(p.max_hp * 0.6):
		_to_phase2()
		return
	if phase == 2 and p.hp <= int(p.max_hp * 0.25):
		_to_phase3()
		return
	if not (is_instance_valid(p.target) and p.target.is_alive()):
		return
	for k in _cd:
		_cd[k] = float(_cd[k]) - delta * p.ab_tempo
	var am := _am()
	match phase:
		1:
			if _cd["eclipse"] <= 0.0:
				_cd["eclipse"] = 8.0
				_eclipse_blade()
			elif _cd["chains"] <= 0.0:
				_cd["chains"] = 9.0
				AbyssAbilities._void_chains(p)
			elif _cd["stars"] <= 0.0:
				_cd["stars"] = 10.0
				HardMode.drops(p, GLOW)
			elif _cd["shades"] <= 0.0 and am:
				_cd["shades"] = 18.0
				am._summon("shade", 2, p.global_position)
		2:
			if _cd["eclipse"] <= 0.0:
				_cd["eclipse"] = 9.0
				_eclipse_blade()
			elif _cd["chains"] <= 0.0:
				_cd["chains"] = 6.5
				_devour_dash()
			elif _cd["stars"] <= 0.0:
				_cd["stars"] = 6.0
				_dark_orbs()
		3:
			if _fallen_t > 0.0:
				return
			if _cd["eclipse"] <= 0.0:
				_cd["eclipse"] = 7.0
				for k in 2:
					p._after(k * 0.9, func(): if is_instance_valid(p): HardMode.drops(p, GLOW))
			elif _cd["chains"] <= 0.0:
				_cd["chains"] = 9.0
				_world_beams()
			elif _cd["stars"] <= 0.0:
				_cd["stars"] = 6.0
				HardMode.spikes(p, GLOW)

# ======================= Клинок затмения и раскрытое сердце =======================
func _eclipse_blade() -> void:
	var world := p.get_parent()
	var fy := _fy()
	var x0 := p.global_position.x
	p._forced_time = 1.3
	p._forced_vx = 0.0
	if p.rig:
		p.rig.play("roar")
	Util.flash(world, p.global_position + Vector2(0, -p.body_size.y * 0.5), 80.0, Color(GLOW, 0.9))
	for s in [-1.0, 1.0]:
		LightBeam.aim_line(world, Vector2(x0, fy - 4), Vector2(x0 + s * 1400.0, fy - 4), GLOW, 0.8)
	p._after(0.8, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		if p.rig:
			p.rig.play("slam")
		Fx.shake(world, 14.0)
		Fx.ring(world, Vector2(x0, fy), 260.0, Color(GLOW, 0.9), 0.4, 9.0, 0.3)
		for k in 12:
			for s in [-1.0, 1.0]:
				var x: float = x0 + s * (90.0 + k * 115.0)
				if x < Colosseum.WALL or x > Colosseum.W - Colosseum.WALL:
					continue
				p._after(k * 0.07, func(): _rift_burst(Vector2(x, fy)))
		_open_heart(2.8))

func _rift_burst(at: Vector2) -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	var sp := Polygon2D.new()
	sp.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(-4, -110), Vector2(0, -130), Vector2(4, -110), Vector2(16, 0)])
	sp.color = Color(0.55, 0.22, 0.80, 0.9)
	sp.position = at
	sp.z_index = 5
	world.add_child(sp)
	var t := sp.create_tween()
	t.tween_property(sp, "scale", Vector2(1.0, 0.1), 0.35).from(Vector2(1.0, 1.0)).set_delay(0.15)
	t.tween_callback(sp.queue_free)
	Fx.sparks(world, at, GLOW, 5, 220.0, 4.0, true)
	for n in AbyssAbilities._foes(p):
		var feet: float = n.global_position.y + n.body_size.y / 2
		if absf(n.global_position.x - at.x) < 40.0 + n.body_size.x / 2 and feet > at.y - 130.0:
			n.take_damage(_dmg(12.0), p)
			n.velocity.y = -460.0

func _open_heart(time: float) -> void:
	_open_t = time
	p.armor_mult = 1.7
	if not _hinted:
		_hinted = true
		_banner("Сердце Лорда раскрыто — бей!", DAWN, 1.6)

func _close_heart() -> void:
	_open_t = 0.0
	p.armor_mult = DARK_ARMOR if phase == 2 else ARMOR

# ======================= Фаза 2: тьма и Столпы рассвета =======================
func _to_phase2() -> void:
	phase = 2
	_busy = true
	var am := _am()
	var world := p.get_parent()
	if am:
		am.cinematic(p, 3.6, true)
		am.shield_heroes(4.4)
	p.cutscene_shield = true
	if p.rig:
		p.rig.play("roar")
	_banner("Лорд Бездны пожирает свет!", Color(0.85, 0.55, 1.0), 2.2)
	for n in world.get_children():
		if n is CanvasModulate:
			n.create_tween().tween_property(n, "color", Color(0.34, 0.28, 0.44), 1.6)
	p._after(1.4, func(): _spawn_pillars())
	p._after(3.8, func():
		_busy = false
		p.cutscene_shield = false
		_close_heart()
		_banner("Столпы рассвета!", DAWN, 1.4)
		var am2 := _am()
		if am2:
			am2.hud.show_hint("Заманивай Лорда в Столпы рассвета: свет обжигает его — он оглушён и открыт. Во тьме он почти неуязвим.", 8.0))

func _spawn_pillars() -> void:
	var world := p.get_parent()
	var fy := _fy()
	for fx in [0.22, 0.5, 0.78]:
		var x: float = Colosseum.W * fx
		var n := Node2D.new()
		n.position = Vector2(x, fy)
		n.z_index = 4
		var beam := Polygon2D.new()
		beam.polygon = PackedVector2Array([Vector2(-46, 0), Vector2(-30, -900), Vector2(30, -900), Vector2(46, 0)])
		beam.color = Color(DAWN, 0.28)
		n.add_child(beam)
		var core := Polygon2D.new()
		core.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-6, -900), Vector2(6, -900), Vector2(12, 0)])
		core.color = Color(1.0, 0.95, 0.75, 0.55)
		n.add_child(core)
		world.add_child(n)
		_pillars.append([n, x, true, 0.0])
		Util.flash(world, Vector2(x, fy - 200.0), 120.0, Color(DAWN, 0.9))

func _tick_pillars(delta: float) -> void:
	if _pillars.is_empty():
		return
	for e in _pillars:
		var n: Node2D = e[0]
		if not bool(e[2]):
			e[3] = float(e[3]) - delta
			if float(e[3]) <= 0.0 and phase == 2:
				e[2] = true
				n.visible = true
				Util.flash(p.get_parent(), n.position + Vector2(0, -200), 100.0, Color(DAWN, 0.8))
			continue
		n.modulate.a = 0.8 + 0.2 * sin(_t * 4.0)
		for h in HardMode.heroes(p.get_parent()):
			if absf(h.global_position.x - float(e[1])) < 46.0 and fmod(_t, 0.5) < delta:
				h.heal(2)
		if phase == 2 and not _busy and absf(p.global_position.x - float(e[1])) < 60.0:
			e[2] = false
			e[3] = 14.0
			n.visible = false
			_burned()

func _burned() -> void:
	var world := p.get_parent()
	Util.flash(world, p.global_position, 260.0, Color(DAWN, 0.95))
	Fx.sparks(world, p.global_position, DAWN, 30, 360.0, 5.0)
	_banner("Свет обжигает Лорда!", DAWN, 1.4)
	p.stun(2.5)
	_open_t = 2.5
	p.armor_mult = 2.0

func _devour_dash() -> void:
	var world := p.get_parent()
	var dir := signf(p.target.global_position.x - p.global_position.x)
	if dir == 0.0:
		dir = float(p.facing)
	var from := p.global_position
	LightBeam.aim_line(world, from, from + Vector2(dir * 1100.0, 0), GLOW, 0.5)
	p._after(0.5, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		p.facing = int(dir)
		p._forced_time = 0.55
		p._forced_vx = dir * 1900.0
		p._after(0.55, func():
			if not is_instance_valid(p):
				return
			var to := p.global_position
			LightBeam.draw(world, [[from, to, 0]], Color(0.4, 0.15, 0.6), 30.0, 0.5)
			RiftAbilities.hit_segment(p, from, to, 40.0, _dmg(16.0), 0)))

func _dark_orbs() -> void:
	p._anim("cast")
	var from := p.global_position + Vector2(0, -p.body_size.y * 0.3)
	for k in 5:
		var b := RiftAbilities.bolt(p, from, Vector2.from_angle(-PI / 2 + (k - 2) * 0.45), 420.0, _dmg(9.0), 18.0, 0)
		b.homing = 320.0

# ======================= Фаза 3: Якоря Бездны =======================
func _to_phase3() -> void:
	phase = 3
	_busy = true
	var am := _am()
	if am:
		am.cinematic(p, 4.0, true)
		am.shield_heroes(5.0)
	p.cutscene_shield = true
	for e in _pillars:
		if is_instance_valid(e[0]):
			e[0].queue_free()
	_pillars.clear()
	_banner("Лорд: «Изнанка — моё тело!»", Color(0.95, 0.55, 1.0), 2.2)
	if p.rig:
		p.rig.play("roar")
	p._after(1.6, func(): _rise())
	p._after(4.2, func():
		_busy = false
		p.cutscene_shield = false
		_close_heart()
		_banner("Разбей Якоря Бездны!", DAWN, 1.4)
		var am3 := _am()
		if am3:
			am3.hud.show_hint("Пока целы Якоря Бездны, Лорд неуязвим. Разбей все три — он рухнет и будет открыт.", 8.0))

func _rise() -> void:
	if not is_instance_valid(p):
		return
	p.flying = true
	p.fly_hover = Vector2(260.0, -320.0)
	p.ignore_one_way_platforms()
	p.velocity = Vector2(0, -600)
	_make_anchors()

func _make_anchors() -> void:
	var am := _am()
	if am == null:
		return
	var fy := _fy()
	for e in [[0.18, 260.0], [0.5, 520.0], [0.82, 260.0]]:
		var a: Player = am.spawn_at("void_anchor", Vector2(Colosseum.W * float(e[0]), fy - float(e[1])))
		a.remove_meta("summoned")
		a.velocity = Vector2.ZERO
		a.set_tint(Color(1.2, 0.8, 1.4))
		_anchors.append(a)
		var ch := Line2D.new()
		ch.width = 5.0
		ch.default_color = Color(0.70, 0.40, 1.0, 0.8)
		ch.z_index = 3
		p.get_parent().add_child(ch)
		_chains.append(ch)
	p.invulnerable = true

func _tick_anchors(delta: float) -> void:
	if phase != 3:
		return
	if _fallen_t > 0.0:
		_fallen_t -= delta
		if _fallen_t <= 0.0:
			_regrow_t = 0.01
	if _regrow_t > 0.0:
		_regrow_t -= delta
		if _regrow_t <= 0.0 and is_instance_valid(p) and p.is_alive():
			_banner("Якоря Бездны возвращаются!", Color(0.9, 0.6, 1.0), 1.4)
			_rise()
		return
	if _anchors.is_empty():
		return
	var live := 0
	for i in _anchors.size():
		var a = _anchors[i]
		var ch: Line2D = _chains[i]
		if is_instance_valid(a) and a.is_alive():
			live += 1
			ch.points = PackedVector2Array([a.global_position, p.hurt_center()])
		elif is_instance_valid(ch):
			ch.visible = false
	if live == 0:
		_fall()

func _fall() -> void:
	for ch in _chains:
		if is_instance_valid(ch):
			ch.queue_free()
	_chains.clear()
	_anchors.clear()
	p.invulnerable = false
	p.flying = false
	p.velocity = Vector2(0, 600)
	_banner("Якоря разбиты — Лорд рухнул!", DAWN, 1.6)
	Fx.shake(p.get_parent(), 14.0)
	p._after(0.6, func():
		if is_instance_valid(p) and p.is_alive():
			p.stun(4.0)
			_open_t = 4.0
			p.armor_mult = 1.8)
	_fallen_t = 12.0

func _world_beams() -> void:
	var world := p.get_parent()
	var fy := _fy()
	p._anim("cast")
	var ys := [fy - 40.0, fy - 280.0, fy - 520.0]
	ys.shuffle()
	for k in 3:
		var y: float = ys[k]
		var a := Vector2(Colosseum.WALL, y)
		var b := Vector2(Colosseum.W - Colosseum.WALL, y)
		p._after(k * 0.9, func():
			if not is_instance_valid(p):
				return
			LightBeam.aim_line(world, a, b, GLOW, 0.9)
			p._after(0.9, func():
				if is_instance_valid(p):
					LightBeam.draw(world, [[a, b, 0]], GLOW, 14.0, 0.35)
					RiftAbilities.hit_segment(p, a, b, 26.0, _dmg(15.0), 0)
					Fx.shake(world, 5.0)))

# Смертельный удар до третьей фазы — не конец, а переход
func _on_lethal() -> bool:
	if phase == 1:
		p.hp = int(p.max_hp * 0.55)
		_to_phase2()
		return true
	if phase == 2:
		p.hp = int(p.max_hp * 0.22)
		_to_phase3()
		return true
	return false

func _cleanup() -> void:
	for e in _pillars:
		if is_instance_valid(e[0]):
			e[0].queue_free()
	_pillars.clear()
	for ch in _chains:
		if is_instance_valid(ch):
			ch.queue_free()
	_chains.clear()
	for a in _anchors:
		if is_instance_valid(a) and a.is_alive():
			a.take_damage(99999)
	_anchors.clear()
	if is_instance_valid(p) and p.is_inside_tree():
		for n in p.get_parent().get_children():
			if n is CanvasModulate:
				n.create_tween().tween_property(n, "color", Color(0.66, 0.56, 0.80), 1.5)
	set_physics_process(false)
