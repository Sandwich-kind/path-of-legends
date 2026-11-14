class_name RassvetKit
extends HeroKit
# ---------- РАССВЕТ — легенда за Тёмного Лорда (80-я волна Арены) ----------
# Бывший чёрный рыцарь Лорда, отказавшийся ему служить. Подобрал камень, что
# выпал из головы Воплощения Тьмы, — и камень очистился: трещины на доспехе
# светятся золотом.
# Оружие: обсидиановый двуручный меч — серия из 3 широких ударов вблизи,
#   третий тяжёлый и бросает вперёд серп света. Каждый удар — короткий шаг к врагу
#   впереди (меч «доходит»), первые два почти не отбрасывают — серия не срывается.
# «Осколок сердца»: раз за жизнь, когда здоровья меньше 30% (или удар смертелен),
#   камень вспыхивает — 2 с неуязвимости и лечение на 30%.
# 1 «Шаг тени» — телепорт за спину врагу впереди (нет впереди — ближайшему рядом)
#   и удар; на старом месте остаётся тёмный силуэт и через секунду взрывается
#   (круг показывает, где рванёт). МЕГА: 3 шага подряд. Арена: удар оглушает.
# 2 «Затмение» — 4 с тьма ходит вместе с Рассветом: враги в ней замедлены и
#   ослеплены (боты не стреляют), над ними — знак тьмы; Рассвет бьёт на 30% сильнее,
#   меч светится фиолетовым. МЕГА: удары во тьме лечат. Арена: шире, 5 с.
# 3 «Чёрное солнце» — осколок камня летит к врагу впереди (дуга подбирается сама),
#   на месте падения 1,2 с тянет врагов в точку, сжимающийся круг показывает,
#   когда рванёт; потом взрыв света. МЕГА: тянет вдвое дальше, взрыв оглушает.
#   Арена: взрыв сильнее и шире.
# Ульта «Восход» — крылья света: 6 с полёта, каждый удар меча бросает серп света;
#   в конце — удар о землю, волна рассвета. МЕГА: небо светлеет — Рассвет
#   лечится, враги вокруг горят. Арена: полёт 8 с.

const GOLD := Color(1.0, 0.84, 0.42)
const DUSK := Color(0.16, 0.08, 0.20)
const VIOLET := Color(0.72, 0.48, 1.0)
const CUT_ANIM := ["cut1", "cut2", "big_cut"]
const CUT_HIT := [0.08, 0.08, 0.16]
const CUT_CD := [0.31, 0.31, 0.5]
const CUT_ANIM_SPEED := 1.25                # серия быстрее — и замахи короче
const CUT_REACH := [150.0, 150.0, 190.0]
const CUT_HALF_H := [70.0, 95.0, 80.0]       # второй удар снизу вверх — достаёт и прыгнувших
const CUT_DMG := [13, 13, 21]
const CUT_KNOCK := [50.0, 50.0, 240.0]      # первые два почти не отбрасывают — враг остаётся под мечом
const CUT_STEP := [380.0, 380.0, 560.0]     # шаг к врагу на каждом ударе

var _combo := 0
var _combo_t := 0.0
var _shard := true                # «Осколок сердца» ещё не сработал в этой жизни
var _shard_fx: Node2D
var _steps := 0                   # МЕГА «Шага тени»: сколько шагов осталось
var _eclipse: Node2D
var _eclipse_t := 0.0
var _eclipse_mega := false
var _eclipse_r := 240.0
var _marks := {}                  # знаки тьмы над ослеплёнными врагами
var _dawn_t := 0.0
var _dawn_mega := false
var _wings: Node2D
var _dawn_tick := 0.0
var _crash_t := 0.0

func _ready() -> void:
	if p:
		p.on_lethal = _on_lethal

# ---------- Меч ----------
func weapon(delta: float, shoot: bool) -> void:
	p.ammo = p.clip_size
	p._reloading = 0.0
	_combo_t -= delta
	if _combo_t <= 0.0:
		_combo = 0
	if not shoot or p._cooldown_left > 0.0:
		return
	var step := _combo
	_combo = (_combo + 1) % 3
	_combo_t = 1.1
	var spd := 0.6 if p.has_buff("rapid") else 1.0
	if p.rig:
		p.rig.play(CUT_ANIM[step], CUT_ANIM_SPEED / spd)
	_after(CUT_HIT[step] * spd, _cut.bind(step))
	p._cooldown_left = CUT_CD[step] * spd
	# меч «доходит»: если враг впереди чуть дальше удара — короткий шаг к нему
	var foe := _front_foe(CUT_REACH[step] + 150.0, 140.0)
	if foe and p.is_on_floor() and not p.fly_free:
		var gap: float = absf(foe.global_position.x - p.global_position.x) - foe.body_size.x / 2.0 - p.body_size.x / 2.0
		if gap > 30.0:
			p._forced_time = clampf(gap / CUT_STEP[step], 0.04, 0.12)
			p._forced_vx = p.facing * CUT_STEP[step]

# Ближайший враг впереди (по направлению взгляда) в пределах reach по X и dy по Y
func _front_foe(reach: float, dy: float) -> Player:
	var best: Player = null
	var bd := reach
	for e in _enemies():
		if e.cutscene_shield:
			continue
		var to: Vector2 = e.global_position - p.global_position
		if to.x * p.facing < -10.0 or absf(to.y) > dy + e.body_size.y / 2.0:
			continue
		if absf(to.x) < bd:
			bd = absf(to.x)
			best = e
	return best

func _cut(step: int) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var world := p.get_parent()
	var hit := _swing(CUT_REACH[step], CUT_HALF_H[step], CUT_DMG[step], CUT_KNOCK[step])
	var c := p.global_position + Vector2(p.facing * 18.0, -8.0)
	var col := Color(GOLD, 0.8) if _dawn_t > 0.0 or step == 2 else Color(0.85, 0.80, 0.95, 0.75)
	if _eclipse_t > 0.0 and _in_eclipse(p):
		col = Color(VIOLET, 0.85)
	var arcs := [[-2.1, 0.9], [1.2, -1.6], [-2.4, 1.3]]
	var a: Array = arcs[step]
	Fx.arc(world, c, CUT_REACH[step] * 0.75, _ang(a[0]), _ang(a[1]), col, 0.2, 20.0 if step == 2 else 14.0)
	# попал — искры по месту удара; тяжёлый удар ещё и встряхивает экран
	for e in hit:
		var at: Vector2 = e.hurt_center() - Vector2(p.facing * e.body_size.x * 0.3, 0)
		Fx.sparks(world, at, col.lightened(0.3), 6 if step == 2 else 4, 220.0, 3.0)
	if step == 2 and not hit.is_empty():
		Util.flash(world, hit[0].hurt_center(), 50.0, Skins.col(p, Color(1.0, 0.95, 0.8, 0.8)))
		Fx.shake(world, 3.0)
	if step == 2 or _dawn_t > 0.0:
		_light_wave()

func _ang(a: float) -> float:
	return a if p.facing > 0 else PI - a

# Удар мечом по всем впереди (и по блокам)
func _swing(reach: float, half_h: float, dmg: int, knock: float, both := false) -> Array:
	var hit := []
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if both or signf(to.x) == p.facing or absf(to.x) < 20.0:
			if absf(to.x) < reach + e.body_size.x / 2 and absf(to.y) < half_h + e.body_size.y / 2:
				e.take_damage(dmg, p)
				if not GasBubble._is_boss(e):
					e.velocity = Vector2((signf(to.x) if both and to.x != 0.0 else float(p.facing)) * knock, -140.0 if knock > 100.0 else -40.0)
				hit.append(e)
	for n in p.get_parent().get_children():
		if n is Destructible and n.shield_team != p.team and not n.background \
				and n.global_position.distance_to(p.global_position) < 500.0:
			var x := 30.0
			while x <= reach:
				var y := -half_h
				while y <= half_h * 0.6:
					n.hit(p.global_position + Vector2(p.facing * x, y), Vector2(p.facing, 0), 24, 5.0, p.team,
							{"strict": true, "attacker": p, "power": 0.5})
					y += 22.0
				x += 22.0
	return hit

# Серп света вперёд
func _light_wave() -> void:
	var w := SlashWave.new()
	w.team = p.team
	w.attacker = p
	w.dir = p.facing
	w.damage = 16
	w.color = Color(Skins.col(p, GOLD), 0.85)
	w.position = p.global_position + Vector2(p.facing * 40.0, -8.0)
	if _dawn_t > 0.0 and _dawn_mega:
		w.burn = 6.0
	p.get_parent().add_child(w)

# Затмение: урон по врагам внутри тьмы лечит (МЕГА)
func on_dealt(amount: int, victim: Node) -> void:
	if _eclipse_t > 0.0 and _eclipse_mega and _in_eclipse(p) and victim is Player:
		p.heal(maxi(1, int(amount * 0.25)))

# ---------- Осколок сердца ----------
func _on_lethal() -> bool:
	if not _shard:
		return false
	p.hp = 1
	_flare_shard()
	return true

func _flare_shard() -> void:
	_shard = false
	p._invuln = maxf(p._invuln, 2.0)
	p.heal(int(p.max_hp * 0.3))
	var world := p.get_parent()
	Util.flash(world, p.global_position, 160.0, Skins.col(p, Color(1.0, 0.9, 0.6, 0.9)))
	Fx.ring(world, p.global_position, 180.0, Skins.col(p, GOLD), 0.45, 8.0)
	Fx.sparks(world, p.global_position, Skins.col(p, GOLD), 18, 260.0, 4.0)
	p._float_label("Осколок сердца!", Skins.col(p, GOLD))
	_shard_fx = Node2D.new()                         # золотое сияние, пока неуязвим
	var g := Polygon2D.new()
	g.polygon = Util.circle(maxf(p.body_size.x, p.body_size.y) * 0.7, 20)
	g.color = Skins.col(p, Color(1.0, 0.85, 0.45, 0.3))
	_shard_fx.add_child(g)
	p.add_child(_shard_fx)
	var t := _shard_fx.create_tween()
	t.tween_interval(1.6)
	t.tween_property(_shard_fx, "modulate:a", 0.0, 0.4)
	t.tween_callback(_shard_fx.queue_free)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"dawn_step":
			_steps = 2 if mega else 0
			_shadow_step({})
		"dawn_eclipse":
			_start_eclipse(mega)
		"black_sun":
			_throw_sun(mega)

# ----- 1. Шаг тени -----
func _shadow_step(done: Dictionary) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var world := p.get_parent()
	var from := p.global_position
	# цель: ближайший враг впереди (куда смотрит Рассвет); если впереди никого — ближайший рядом
	var target: Player = null
	var bd := 560.0
	for e in _enemies():
		if done.has(e) or e.cutscene_shield:
			continue
		var to_e: Vector2 = e.global_position - from
		if to_e.x * p.facing < -10.0 or absf(to_e.y) > 260.0:
			continue
		var d: float = to_e.length()
		if d < bd:
			bd = d
			target = e
	if target == null:
		bd = 360.0
		for e in _enemies():
			if done.has(e) or e.cutscene_shield:
				continue
			var d2: float = e.global_position.distance_to(from)
			if d2 < bd:
				bd = d2
				target = e
	var to := from + Vector2(p.facing * 280.0, 0)
	if target:
		var side := signf(target.global_position.x - from.x)
		if side == 0.0:
			side = float(p.facing)
		var feet_y: float = target.global_position.y + target.body_size.y / 2
		to = Vector2(target.global_position.x + side * (target.body_size.x / 2 + p.body_size.x / 2 + 16.0), feet_y - p.body_size.y / 2 - 2.0)
		if _blocked(to):
			to.x = target.global_position.x - side * (target.body_size.x / 2 + p.body_size.x / 2 + 16.0)
		done[target] = true
	if _blocked(to):
		to = from
	to.x = clampf(to.x, 40.0, p.map_w - 40.0)
	_silhouette(from)
	var trail := Line2D.new()                           # тёмный след шага
	trail.points = PackedVector2Array([from, to])
	trail.width = 26.0
	trail.default_color = Skins.col(p, Color(0.45, 0.22, 0.70, 0.55))
	trail.z_index = 4
	world.add_child(trail)
	var tt := trail.create_tween()
	tt.tween_property(trail, "width", 2.0, 0.25)
	tt.parallel().tween_property(trail, "modulate:a", 0.0, 0.25)
	tt.tween_callback(trail.queue_free)
	p.global_position = to
	p.velocity = Vector2.ZERO
	if target:
		p.facing = 1 if target.global_position.x > to.x else -1
		p._update_eye()
	Fx.sparks(world, to, Skins.col(p, Color(0.55, 0.30, 0.75)), 10, 200.0, 4.0)
	p._anim("cut1")
	var hit := _swing(150.0, 70.0, 22, 160.0)
	Fx.arc(world, to + Vector2(p.facing * 18.0, -8.0), 110.0, _ang(-2.1), _ang(0.9), Skins.col(p, Color(0.75, 0.55, 1.0, 0.85)), 0.2, 16.0)
	if Balance.arena(p):
		for e in hit:
			e.stun(0.6)
	p._invuln = maxf(p._invuln, 0.25)
	if _steps > 0:
		_steps -= 1
		_after(0.28, _shadow_step.bind(done))

func _blocked(at: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var rs := RectangleShape2D.new()
	rs.size = p.body_size - Vector2(6, 6)
	q.shape = rs
	q.transform = Transform2D(0, at)
	q.collision_mask = Layer.WORLD
	return not p.get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()

# Тёмный силуэт на старом месте — через секунду взрывается
func _silhouette(at: Vector2) -> void:
	var world := p.get_parent()
	var s := Node2D.new()
	s.position = at
	s.z_index = 5
	var bs := p.body_size
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-bs.x * 0.4, bs.y * 0.5), Vector2(-bs.x * 0.45, -bs.y * 0.1), Vector2(-bs.x * 0.25, -bs.y * 0.3),
			Vector2(-bs.x * 0.2, -bs.y * 0.5), Vector2(bs.x * 0.2, -bs.y * 0.5), Vector2(bs.x * 0.25, -bs.y * 0.3), Vector2(bs.x * 0.45, -bs.y * 0.1), Vector2(bs.x * 0.4, bs.y * 0.5)])
	body.color = Skins.col(p, Color(0.20, 0.08, 0.28, 0.85))
	s.add_child(body)
	world.add_child(s)
	var team := p.team
	var who := p
	var big := Balance.arena(p)
	var r0 := 130.0 if big else 105.0
	var zone := Line2D.new()                             # где рванёт: круг сжимается до взрыва
	var zp := Util.circle(r0, 32)
	zp.append(zp[0])
	zone.points = zp
	zone.width = 3.0
	zone.default_color = Skins.col(p, Color(0.7, 0.4, 1.0, 0.7))
	zone.scale = Vector2(1.6, 1.6)
	s.add_child(zone)
	zone.create_tween().tween_property(zone, "scale", Vector2.ONE * 0.87, 0.9)   # силуэт сам растёт ×1,15
	var t := s.create_tween()
	t.tween_property(s, "scale", Vector2(1.15, 1.15), 0.9)
	t.parallel().tween_property(body, "color", Color(0.55, 0.25, 0.85, 0.95), 0.9)
	t.tween_callback(func():
		var w2 := s.get_parent()
		if w2 == null:
			return
		var r := 130.0 if big else 105.0
		Fx.ring(w2, s.global_position, r, Skins.col(p, Color(0.7, 0.4, 1.0, 0.9)), 0.35, 8.0)
		Fx.sparks(w2, s.global_position, Skins.col(p, Color(0.6, 0.3, 0.9)), 14, 260.0, 4.0)
		for n in w2.get_children():
			if n is Player and n.team != team and n.is_alive() and n.global_position.distance_to(s.global_position) < r + n.body_size.x * 0.4:
				n.take_damage(18, who if is_instance_valid(who) else null)
		s.queue_free())

# ----- 2. Затмение -----
func _start_eclipse(mega: bool) -> void:
	if is_instance_valid(_eclipse):
		_eclipse.queue_free()
	_clear_marks()
	var arena := Balance.arena(p)
	_eclipse_mega = mega
	_eclipse_t = 5.0 if arena else 4.0
	_eclipse_r = 300.0 if arena else 240.0
	p._anim("cast")
	_eclipse = Node2D.new()
	_eclipse.z_index = 6
	_eclipse.position = p.global_position
	var dome := Polygon2D.new()
	dome.polygon = Util.circle(_eclipse_r, 36)
	dome.color = Skins.col(p, Color(0.06, 0.02, 0.10, 0.62))
	_eclipse.add_child(dome)
	var rim := Line2D.new()
	var pts := Util.circle(_eclipse_r, 36)
	pts.append(pts[0])
	rim.points = pts
	rim.width = 4.0
	rim.default_color = Skins.col(p, Color(0.60, 0.35, 0.95, 0.8)) if not mega else Color(Skins.col(p, GOLD), 0.85)
	_eclipse.add_child(rim)
	for k in 8:                                           # клочья тьмы по краю
		var wisp := Polygon2D.new()
		var a := TAU * k / 8.0
		wisp.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(0, -26), Vector2(14, 0)])
		wisp.position = Vector2.from_angle(a) * _eclipse_r
		wisp.rotation = a + PI / 2
		wisp.color = Skins.col(p, Color(0.10, 0.03, 0.15, 0.8))
		_eclipse.add_child(wisp)
	p.get_parent().add_child(_eclipse)
	_eclipse.scale = Vector2(0.2, 0.2)
	_eclipse.create_tween().tween_property(_eclipse, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

func _in_eclipse(n: Node2D) -> bool:
	return is_instance_valid(_eclipse) and n.global_position.distance_to(_eclipse.global_position) < _eclipse_r

func _eclipse_tick(delta: float) -> void:
	_eclipse_t -= delta
	_eclipse.rotation += delta * 0.4
	# тьма ходит вместе с Рассветом
	_eclipse.global_position = _eclipse.global_position.lerp(p.global_position, minf(1.0, 12.0 * delta))
	var arena := Balance.arena(p)
	var inside := {}
	for e in _enemies():
		if _in_eclipse(e):
			inside[e] = true
			e.slow(0.2, 0.55 if arena else 0.7)
			if e.is_bot:
				e._cooldown_left = maxf(e._cooldown_left, 0.25)     # ослеплён: не стреляет
			if not _marks.has(e) or not is_instance_valid(_marks[e]):
				_marks[e] = _blind_mark(e)
	for e in _marks.keys():                                  # вышел из тьмы — знак гаснет
		if not inside.has(e):
			if is_instance_valid(_marks[e]):
				_marks[e].queue_free()
			_marks.erase(e)
	var lit := _in_eclipse(p)
	if lit:
		p.boost(1.3, 0.2)
	if p.rig and _dawn_t <= 0.0:
		p.rig.blade_fire = Color(VIOLET, 0.9) if lit else Color(0, 0, 0, 0)    # меч светится — удары сильнее
	if _eclipse_t <= 0.0:
		var t := _eclipse.create_tween()
		t.tween_property(_eclipse, "modulate:a", 0.0, 0.35)
		t.tween_callback(_eclipse.queue_free)
		_eclipse = null
		_clear_marks()
		if p.rig and _dawn_t <= 0.0:
			p.rig.blade_fire = Color(0, 0, 0, 0)

# Знак тьмы над ослеплённым врагом: тёмный вихрь с фиолетовой каймой
func _blind_mark(e: Player) -> Node2D:
	var m := Node2D.new()
	m.position = Vector2(0, -e.body_size.y / 2.0 - 26.0)
	m.z_index = 8
	for k in 3:
		var arc := Line2D.new()
		var pts := PackedVector2Array()
		for i in 7:
			pts.append(Vector2.from_angle(TAU * k / 3.0 + i * 0.28) * (6.0 + i * 1.6))
		arc.points = pts
		arc.width = 3.0
		arc.default_color = Skins.col(p, Color(0.55, 0.30, 0.85, 0.9)) if k == 0 else Skins.col(p, Color(0.12, 0.05, 0.18, 0.9))
		m.add_child(arc)
	e.add_child(m)
	m.create_tween().set_loops().tween_property(m, "rotation", -TAU, 0.9).as_relative()
	return m

func _clear_marks() -> void:
	for e in _marks.keys():
		if is_instance_valid(_marks[e]):
			_marks[e].queue_free()
	_marks.clear()

# ----- 3. Чёрное солнце -----
func _throw_sun(mega: bool) -> void:
	p._anim("throw")
	var s := BlackSun.new()
	s.team = p.team
	s.attacker = p
	s.mega = mega
	s.arena = Balance.arena(p)
	var from: Vector2 = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(0, -6)
	s.vel = Vector2(p.facing * 640.0, -360.0)
	# враг впереди — дуга подбирается так, чтобы осколок упал прямо к нему
	var foe := _front_foe(760.0, 320.0)
	if foe:
		var to: Vector2 = foe.hurt_center() - from
		var t := clampf(absf(to.x) / 1000.0, 0.25, 0.55)          # дуга пологая — не цепляет платформы над головой
		s.vel = Vector2(to.x / t, to.y / t - 0.5 * BlackSun.G * t)
	s.position = from
	p.get_parent().add_child(s)

# ---------- Ульта: Восход ----------
func ult() -> void:
	if _dawn_t > 0.0:
		return
	_dawn_mega = p._mega_ab()
	_dawn_t = 8.0 if Balance.arena(p) else 6.0
	p.fly_free = true
	if p.rig:
		p.rig.blade_fire = Color(GOLD, 0.95)
	p._anim("invoke")
	p.velocity = Vector2(0, -420)
	var world := p.get_parent()
	Util.flash(world, p.global_position, 200.0, Skins.col(p, Color(1.0, 0.9, 0.6, 0.85)))
	Fx.ring(world, p.global_position, 220.0, Skins.col(p, GOLD), 0.5, 8.0)
	p._float_label("Восход!", Skins.col(p, GOLD))
	_make_wings()

func ulting() -> bool:
	return _dawn_t > 0.0

# ---------- Крылья «Восхода» ----------
# Нарисованы по клеточкам, как сама модель. В игре — blades: веер парящих клинков зари.
# Остальные виды оставлены для сравнения: feathers — оперённые крылья света, sun — солнечный
# нимб с лучами, flame — языки рассветного пламени, old — прежние (два гладких лепестка).
const WING_STYLES := ["feathers", "sun", "blades", "flame", "old"]
static var wing_style := "blades"

func _make_wings() -> void:
	_wings = Node2D.new()
	_wings.z_index = -1
	var bs := p.body_size
	var px: float = p.rig.px if p.rig else 2.5
	var base := Skins.col(p, GOLD)
	var pal := [Color(1.0, 0.98, 0.88).lerp(base, 0.15), base.lightened(0.25), base, base.darkened(0.35).lerp(Color(0.95, 0.45, 0.2), 0.35), base.darkened(0.72)]
	_wings.set_meta("style", wing_style)
	match wing_style:
		"old":
			for s in [-1.0, 1.0]:
				var w := Polygon2D.new()
				w.polygon = PackedVector2Array([Vector2(0, -bs.y * 0.15), Vector2(s * bs.x * 1.4, -bs.y * 0.75), Vector2(s * bs.x * 1.9, -bs.y * 0.55),
						Vector2(s * bs.x * 1.5, -bs.y * 0.3), Vector2(s * bs.x * 1.8, -bs.y * 0.1), Vector2(s * bs.x * 1.2, 0.0), Vector2(s * bs.x * 0.9, bs.y * 0.2)])
				w.color = Skins.col(p, Color(1.0, 0.88, 0.55, 0.75))
				_wings.add_child(w)
		"sun":
			for k in 2:                                   # два кадра нимба: лучи «мерцают», сменяя друг друга
				var sp := _wing_sprite(_sun_img(pal, k), Vector2(24, 24), Vector2(0, -bs.y * 0.22), px)
				sp.visible = k == 0
		"blades":
			for s in [-1.0, 1.0]:
				for k in 3:
					var sp := _wing_sprite(_blade_img(pal), Vector2(4.5, 27), Vector2(s * (6.0 + k * 2.0) * px, (-5.0 + k * 3.5) * px), px)
					sp.rotation = s * (0.55 + k * 0.5)
					sp.set_meta("rest", sp.position)
					sp.set_meta("ph", k * 1.3 + (0.0 if s < 0.0 else 0.6))
		_:
			for s in [-1.0, 1.0]:
				var frames := 3 if wing_style == "flame" else 1
				for k in frames:
					var img := _flame_img(pal, k) if wing_style == "flame" else _feather_img(pal)
					var sp := _wing_sprite(img, Vector2(1, 21 if wing_style == "flame" else 17), Vector2(s * 1.5 * px, -bs.y * 0.12), px)
					sp.scale.x = s * px
					sp.set_meta("side", s)
					sp.visible = k == 0
	for w in _wings.get_children():
		var sc: Vector2 = (w as Node2D).scale
		(w as Node2D).scale = sc * 0.1
		w.create_tween().tween_property(w, "scale", sc, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	p.add_child(_wings)

func _wing_sprite(img: Image, pivot: Vector2, at: Vector2, px: float) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = ImageTexture.create_from_image(img)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.centered = false
	sp.offset = -pivot
	sp.position = at
	sp.scale = Vector2(px, px)
	_wings.add_child(sp)
	return sp

func _wing_tick() -> void:
	if not is_instance_valid(_wings):
		return
	var t := Time.get_ticks_msec() * 0.001
	var kids := _wings.get_children()
	match String(_wings.get_meta("style", "old")):
		"old":
			for k in kids.size():
				(kids[k] as Node2D).rotation = sin(t * 8.0 + k * PI) * 0.15
		"sun":
			var fr := int(t * 4.0) % 2
			for k in kids.size():
				(kids[k] as Node2D).visible = k == fr
			_wings.position.y = sin(t * 3.0) * 2.0
		"blades":
			for w in kids:
				var n := w as Node2D
				var ph := float(n.get_meta("ph", 0.0))
				n.position = (n.get_meta("rest") as Vector2) + Vector2(0, sin(t * 3.2 + ph) * 3.0)
		_:
			var per := kids.size() / 2
			var fr := int(t * 9.0) % maxi(per, 1)
			for k in kids.size():
				var n := kids[k] as Node2D
				var s := float(n.get_meta("side", 1.0))
				n.visible = (k % maxi(per, 1)) == fr
				n.rotation = -s * (0.10 + 0.16 * sin(t * 7.0))            # взмах: крыло поднимается и опускается
				n.scale.x = s * absf(n.scale.y) * (0.9 + 0.1 * sin(t * 7.0 + 1.2))

static func _wpx(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)

static func _outline(im: Image, c: Color) -> void:
	var src := im.duplicate() as Image
	for y in im.get_height():
		for x in im.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < im.get_width() and q.y < im.get_height() and src.get_pixel(q.x, q.y).a > 0.0:
					im.set_pixel(x, y, c)
					break

# Оперённое крыло (правое; левое — зеркально): дуга-«кость» и три ряда перьев, к концам темнее
static func _feather_img(pal: Array) -> Image:
	var im := Image.create(34, 34, false, Image.FORMAT_RGBA8)
	var n := 11
	for row in 3:                                  # дальний ряд — длинные маховые, ближний — короткие кроющие
		for i in n:
			var t := float(i) / (n - 1)
			var bx := 1.0 + 30.0 * t
			var by := 17.0 - 13.0 * sin(PI * minf(1.0, t * 1.15) * 0.62) + 5.0 * t * t
			var ln: float = [7.0 + 15.0 * sin(PI * (0.25 + 0.75 * t) * 0.8), 5.0 + 8.0 * sin(PI * (0.2 + 0.8 * t) * 0.8), 3.0 + 3.0 * t][row]
			var dx := 0.15 + 0.55 * t
			for k in int(ln):
				var q := float(k) / maxf(ln, 1.0)
				var c: Color = pal[[2, 1, 0][row]]
				if q > 0.72:
					c = pal[[3, 2, 1][row]]
				var x := int(round(bx + dx * k))
				var y := int(round(by + k))
				_wpx(im, x, y, c)
				if q < 0.8:
					_wpx(im, x + 1, y, c.lightened(0.12) if (i + row) % 2 == 0 else c)
	for i in 31:                                    # «кость» крыла — светлая кромка сверху
		var t := i / 30.0
		var y := int(round(17.0 - 13.0 * sin(PI * minf(1.0, t * 1.15) * 0.62) + 5.0 * t * t))
		_wpx(im, 1 + i, y, pal[0])
		_wpx(im, 1 + i, y - 1, pal[1])
	_outline(im, pal[4])
	return im

# Крыло-пламя: языки рассветного огня, от белого у спины к розово-рыжему на концах
static func _flame_img(pal: Array, frame: int) -> Image:
	var im := Image.create(36, 40, false, Image.FORMAT_RGBA8)
	var rose := Color(0.95, 0.42, 0.45)
	for i in 6:
		var a := -1.35 + i * 0.36                           # куда тянется язык: от «вверх» до «в сторону-вниз»
		var ln: float = float([17.0, 24.0, 28.0, 26.0, 20.0, 13.0][i]) + float([0.0, 3.0, -2.0][(frame + i) % 3])
		var dir := Vector2(cos(a), sin(a))
		for k in int(ln):
			var q: float = k / ln
			var wd := maxf(0.6, 3.6 * (1.0 - q * q) * (1.0 - 0.2 * sin(k * 0.9 + frame * 2.1 + i)))
			var c: Color = pal[0] if q < 0.22 else (pal[1] if q < 0.45 else (pal[2] if q < 0.7 else pal[3].lerp(rose, 0.5)))
			var cx := 2.0 + dir.x * k + sin(k * 0.55 + frame * 1.7 + i) * 0.9
			var cy := 21.0 + dir.y * k
			for w in range(-int(wd), int(wd) + 1):
				_wpx(im, int(round(cx - dir.y * w)), int(round(cy + dir.x * w)), c)
				_wpx(im, int(round(cx - dir.y * w + 0.5)), int(round(cy + dir.x * w)), c)
	_outline(im, pal[3].lerp(rose, 0.6))
	return im

# Солнечный нимб: диск-кольцо и лучи — длинные через один с короткими; второй кадр — лучи наоборот
static func _sun_img(pal: Array, frame: int) -> Image:
	var im := Image.create(49, 49, false, Image.FORMAT_RGBA8)
	var c0 := Vector2(24, 24)
	for y in 49:
		for x in 49:
			var d := Vector2(x, y).distance_to(c0)
			if d >= 8.5 and d < 11.5:
				im.set_pixel(x, y, pal[0] if d < 10.0 else pal[1])
	for i in 16:
		var a := TAU * i / 16.0
		var long_ray := (i + frame) % 2 == 0
		var ln := 11.0 if long_ray else 5.0
		for k in int(ln):
			var q := k / ln
			var r := 13.0 + k
			var wd := 1 if q > 0.55 else 2
			for w in range(-wd + 1, wd):
				var pt := c0 + Vector2.from_angle(a) * r + Vector2.from_angle(a + PI / 2.0) * w
				_wpx(im, int(round(pt.x)), int(round(pt.y)), pal[1] if q < 0.4 else (pal[2] if q < 0.75 else pal[3]))
	_outline(im, pal[4])
	return im

# Парящий клинок зари: обсидиан с золотой кромкой и светлой сердцевиной (как меч Рассвета)
static func _blade_img(pal: Array) -> Image:
	var im := Image.create(9, 29, false, Image.FORMAT_RGBA8)
	var obs := Color(0.13, 0.11, 0.16)
	for y in range(1, 28):
		var hw := 3 if y > 6 and y < 21 else (2 if y > 3 and y < 24 else (1 if y > 1 and y < 26 else 0))
		for x in range(4 - hw, 4 + hw + 1):
			var c := obs
			if x == 4:
				c = pal[0] if y % 4 != 0 else pal[1]              # светящаяся жила по центру
			elif absi(x - 4) == hw:
				c = pal[2]                                        # золотая кромка
			im.set_pixel(x, y, c)
	_outline(im, pal[4])
	return im

func _dawn_tick_fn(delta: float) -> void:
	_dawn_t -= delta
	_wing_tick()
	if randf() < 0.5:
		Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-30, 30), randf_range(-20, 30)), Skins.col(p, GOLD), 1, 90.0, 3.0)
	if _dawn_mega:
		_dawn_tick -= delta
		if _dawn_tick <= 0.0:
			_dawn_tick = 1.0
			p.heal(4)
			for e in _enemies():
				if e.global_position.distance_to(p.global_position) < 600.0:
					e.burn(2.0, 6.0, p)
	if _dawn_t <= 0.0:
		_dawn_crash()

# Конец ульты: удар о землю, волна рассвета
func _dawn_crash() -> void:
	_dawn_t = 0.0
	p.fly_free = false
	if p.rig:
		p.rig.blade_fire = Color(0, 0, 0, 0)
	if is_instance_valid(_wings):
		var t := _wings.create_tween()
		t.tween_property(_wings, "modulate:a", 0.0, 0.3)
		t.tween_callback(_wings.queue_free)
	_wings = null
	_crash_t = 1.2                                     # пикирует вниз до земли
	p.velocity = Vector2(0, 1600.0)
	p._invuln = maxf(p._invuln, 0.4)

func _dawn_wave() -> void:
	var world := p.get_parent()
	var feet := p.global_position + Vector2(0, p.body_size.y / 2)
	Fx.shake(world, 9.0)
	Util.flash(world, feet + Vector2(0, -40), 220.0, Skins.col(p, Color(1.0, 0.9, 0.6, 0.9)))
	Fx.ring(world, feet, 280.0, Skins.col(p, GOLD), 0.5, 10.0, 0.3)
	Fx.cracks(world, feet, Skins.col(p, GOLD), 120.0)
	for e in _enemies():
		var d: Vector2 = e.global_position - feet
		if absf(d.x) < 260.0 + e.body_size.x * 0.4 and d.y > -320.0 and d.y < 60.0:
			e.take_damage(40, p)
			if not GasBubble._is_boss(e):
				e.velocity = Vector2(signf(d.x + 0.01) * 520.0, -420.0)

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	if _shard and p.hp < p.max_hp * 0.3 and p.hp > 0:
		_flare_shard()
	if _eclipse_t > 0.0 and is_instance_valid(_eclipse):
		_eclipse_tick(delta)
	if _dawn_t > 0.0:
		_dawn_tick_fn(delta)
	if _crash_t > 0.0:
		_crash_t -= delta
		p.velocity.y = maxf(p.velocity.y, 1400.0)
		if p.is_on_floor() or _crash_t <= 0.0:
			_crash_t = 0.0
			_dawn_wave()

func on_death() -> void:
	super()
	_dawn_t = 0.0
	_crash_t = 0.0
	_steps = 0
	if is_instance_valid(_wings):
		_wings.queue_free()
	_wings = null
	if is_instance_valid(_eclipse):
		_eclipse.queue_free()
	_eclipse = null
	_eclipse_t = 0.0
	_clear_marks()
	if p.rig:
		p.rig.blade_fire = Color(0, 0, 0, 0)
	_shard = true                                     # после возрождения камень снова готов


# =====================================================================
# Осколок камня: летит по дуге, на месте падения тянет врагов, потом взрыв света
class BlackSun extends Node2D:
	const G := 1500.0
	const PULL_T := 1.25            # сколько тянет до взрыва
	var team := 0
	var attacker: Player
	var mega := false
	var arena := false
	var vel := Vector2.ZERO
	var _landed := false
	var _t := 0.0
	var _tick := 0.0
	var _core: Polygon2D
	var _rings: Array = []
	var _fuse: Line2D               # круг взрыва: сжимается к моменту взрыва
	var _burst_r := 170.0

	func _ready() -> void:
		z_index = 7
		_core = Polygon2D.new()
		_core.polygon = PackedVector2Array([Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)])
		_core.color = Color(1.0, 0.84, 0.42)
		add_child(_core)

	func _foes() -> Array:
		var res := []
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				res.append(n)
		return res

	func _physics_process(delta: float) -> void:
		_t += delta
		if not _landed:
			vel.y += G * delta
			var next := global_position + vel * delta
			var hit := get_world_2d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters2D.create(global_position, next, Layer.WORLD | Layer.FRAME))
			if not hit.is_empty() and vel.y < 0.0 and _one_way(hit):
				hit = {}                                   # сквозные платформы пролетает снизу насквозь
			var touch := false
			for e in _foes():
				if e.hurt_center().distance_to(next) < maxf(e.body_size.x, e.body_size.y) * 0.5 + 10.0:
					touch = true
			_core.rotation += delta * 12.0
			if not hit.is_empty() or touch or _t > 2.0:
				global_position = hit["position"] + Vector2(0, -30) if not hit.is_empty() else next
				_open()
			else:
				global_position = next
			return
		# чёрная дыра
		var pull_r := 600.0 if mega else 300.0
		for k in _rings.size():
			(_rings[k] as Node2D).rotation += delta * (2.5 + k)
		_tick -= delta
		for e in _foes():
			var d: Vector2 = global_position - e.global_position
			if d.length() < pull_r:
				if not GasBubble._is_boss(e):
					e.push_wind(signf(d.x) * 260.0)
					if absf(d.y) > 30.0 and d.y < 0.0:
						e.velocity.y = minf(e.velocity.y, -120.0)
				if _tick <= 0.0 and d.length() < 140.0:
					e.take_damage(4, attacker if is_instance_valid(attacker) else null)
		if _tick <= 0.0:
			_tick = 0.3
		if randf() < 0.7:
			var s := Polygon2D.new()
			s.polygon = Util.circle(3.0, 6)
			s.color = Color(1.0, 0.85, 0.5, 0.8)
			s.position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(pull_r * 0.4, pull_r * 0.8)
			s.z_index = 6
			get_parent().add_child(s)
			var tw := s.create_tween()
			tw.tween_property(s, "position", global_position, 0.5).set_ease(Tween.EASE_IN)
			tw.tween_callback(s.queue_free)
		if is_instance_valid(_fuse):
			var k := clampf(_t / PULL_T, 0.0, 1.0)
			_fuse.scale = Vector2.ONE * lerpf(2.2, 1.0, k)
			_fuse.default_color.a = 0.35 + 0.55 * k
		if _t >= PULL_T:
			_burst()

	func _one_way(hit: Dictionary) -> bool:
		var col = hit.get("collider")
		if col is Destructible:
			return col.one_way
		if col is CollisionObject2D:
			var owner_id: int = col.shape_find_owner(int(hit.get("shape", 0)))
			return col.is_shape_owner_one_way_collision_enabled(owner_id)
		return false

	func _open() -> void:
		_landed = true
		_t = 0.0
		var hole := Polygon2D.new()
		hole.polygon = Util.circle(26.0, 18)
		hole.color = Color(0.02, 0.0, 0.04)
		add_child(hole)
		move_child(hole, 0)
		for k in 3:
			var ring := Line2D.new()
			var pts := Util.circle(38.0 + k * 20.0, 24)
			pts.append(pts[0])
			ring.points = pts
			ring.width = 4.0 - k
			ring.default_color = Color(1.0, 0.84, 0.42, 0.85 - k * 0.2)
			add_child(ring)
			_rings.append(ring)
		_burst_r = (220.0 if arena else 170.0) + (40.0 if mega else 0.0)
		var pull_r := 600.0 if mega else 300.0
		var area := Line2D.new()                        # докуда тянет
		var ap := Util.circle(pull_r, 48)
		ap.append(ap[0])
		area.points = ap
		area.width = 2.0
		area.default_color = Color(1.0, 0.84, 0.42, 0.25)
		add_child(area)
		_fuse = Line2D.new()                            # где рванёт — сжимается к взрыву
		var fp := Util.circle(_burst_r, 40)
		fp.append(fp[0])
		_fuse.points = fp
		_fuse.width = 4.0
		_fuse.default_color = Color(1.0, 0.92, 0.6, 0.35)
		_fuse.scale = Vector2(2.2, 2.2)
		add_child(_fuse)
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

	func _burst() -> void:
		var world := get_parent()
		var r := _burst_r
		var dmg := 34 if arena else 26
		Util.flash(world, global_position, r, Color(1.0, 0.92, 0.65, 0.95))
		Fx.ring(world, global_position, r * 1.2, Color(1.0, 0.84, 0.42, 0.9), 0.45, 9.0)
		Fx.sparks(world, global_position, Color(1.0, 0.85, 0.5), 20, 300.0, 4.0)
		for e in _foes():
			if e.global_position.distance_to(global_position) < r + e.body_size.x * 0.4:
				e.take_damage(dmg, attacker if is_instance_valid(attacker) else null)
				if mega:
					e.stun(1.2)
				elif not GasBubble._is_boss(e):
					e.velocity = Vector2(signf(e.global_position.x - global_position.x + 0.01) * 300.0, -380.0)
		queue_free()
