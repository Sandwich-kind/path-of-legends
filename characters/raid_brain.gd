class_name RaidBrain
extends Node
# ---------- Особое поведение боссов Деревни и Колизея ----------
#   ataman, gladiator — «вихрь»: крутятся с оружием и идут на героя, потом
#                       у них кружится голова (оглушены → урон ×2);
#   colossus          — три фазы: обычная, «ярость» (с 2/3 здоровья: быстрее,
#                       зовёт бойцов) и «перегрев» (с 1/3: ещё быстрее, но
#                       раскалённая броня слабее, а спина уязвима сильнее).
#                       Пар из труб на спине, горящие глаза, земля трескается
#                       под шагами.
#                       Повергнутый, Колосс не умирает, а ПРОБУЖДАЕТСЯ (вторая фаза):
#                       броня трескается и разлетается кусками (шлем, нагрудник,
#                       наплечники падают на песок) — остаётся железный остов,
#                       в груди за рёбрами пылает ядро; небо над Колизеем горит
#                       и с него падают метеоры (InfernoSky). После огненного
#                       рывка и прыжка-метеора грудная клетка раскрывается —
#                       удары спереди в открытое ядро бьют ×1,5.
#                       Новые атаки: огненный рывок (за ним горит земля),
#                       прыжок-метеор (тень с неба → удар и столбы пламени),
#                       залп лавой и «Сверхновая» — после неё он выдыхается
#                       (оглушён, урон ×2).
#   witch             — «стая воронов»: рассыпается воронами и появляется
#                       в другом конце поля;
#   bog_lord          — ныряет в трясину: по земле к герою бегут пузыри,
#                       потом Владыка вырывается из грязи прямо под ним.

var p: Player
var kind := ""
var _whirl_t := 0.0
var _whirl_tick := 0.0
var _disc: Node2D
var _phase := 0
var _vent_t := 0.0
var _step_t := 0.0
var _t := 0.0
var _crush_t := 0.0
var _hide_t := 0.0             # ведьма в стае воронов / Владыка под трясиной
var _hide_kind := ""
var _goal_x := 0.0
var _floor_y := 0.0
# ----- Колосс: вторая фаза -----
var _awake := false
var _waking := false
var _sky: Node2D
var _ember_t := 0.0
var _dash_t := 0.0
var _dash_dir := 1.0
var _dash_hit := {}
var _trail_x := 0.0
var _leap := ""                 # crouch, up, track, lock, fall
var _leap_t := 0.0
var _leap_ground := 0.0
var _shadow: Node2D
var _nova_t := 0.0
var _nova_fx: Node2D
var _rig_y := 0.0
var _rig_rot := 0.0
var _crack_level := 0
var _chip_t := 0.0
var _core_open_t := 0.0         # ядро открыто (после рывка и прыжка-метеора)
var _core_note := -9.0
var _spent := false             # после Сверхновой ядро погасло
const NOVA_R := 440.0
const NOVA_T := 2.4
const CORE_MULT := 1.5          # урон спереди в открытое ядро
const CORE_OPEN := 2.6          # сколько секунд ядро открыто

func _ready() -> void:
	name = "RaidBrain"
	if kind == "colossus":
		p.on_lethal = _on_lethal              # смертельный удар — не конец: Колосс пробуждается
		p.on_hurt = _on_hurt

func _physics_process(delta: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		if _disc:
			_disc.queue_free()
			_disc = null
		return
	_t += delta
	if _whirl_t > 0.0:
		_whirl_tick_fn(delta)
	if kind == "colossus":
		if _awake:
			_colossus_awake(delta)
		elif not _waking:
			_colossus(delta)
		elif _crack_level > 0:
			_chips(delta)
	if _hide_t > 0.0:
		_hidden_tick(delta)
	elif kind == "bog_lord" and fmod(_t, 0.4) < delta:
		# с Владыки капает грязь, вокруг жужжит мошкара
		Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-60, 60), p.body_size.y * 0.2), Color(0.28, 0.30, 0.18), 2, 60.0, 4.0)

# ---------- Вихрь ----------
func start_whirl(time: float) -> void:
	_whirl_t = time
	_whirl_tick = 0.0
	if p.rig:
		p.rig.play("swing")
	_disc = Node2D.new()
	_disc.z_index = 4
	p.add_child(_disc)
	var r := p.body_size.x / 2 + 60.0
	for k in 3:                                        # три размытых лезвия по кругу
		var bl := Polygon2D.new()
		var a0 := TAU * k / 3.0
		var pts := PackedVector2Array()
		for i in 9:
			pts.append(Vector2.from_angle(a0 + i * 0.12) * r)
		for i in 9:
			pts.append(Vector2.from_angle(a0 + (8 - i) * 0.12) * (r - 18.0))
		bl.polygon = pts
		bl.color = Color(0.85, 0.87, 0.92, 0.75)
		_disc.add_child(bl)
	var ring := Line2D.new()
	var rp := Util.circle(r - 9.0, 28)
	rp.append(rp[0])
	ring.points = rp
	ring.width = 3.0
	ring.default_color = Color(1, 1, 1, 0.35)
	_disc.add_child(ring)
	_disc.scale = Vector2(1.0, 0.45)                    # крутится плашмя, вокруг пояса

func _whirl_tick_fn(delta: float) -> void:
	_whirl_t -= delta
	var dir := float(p.facing)
	if is_instance_valid(p.target):
		dir = signf(p.target.global_position.x - p.global_position.x)
	p._forced_time = 0.1
	p._forced_vx = dir * 270.0
	if _disc:
		_disc.rotation = 0.0
		for c in _disc.get_children():
			if c is Polygon2D:
				c.rotation += delta * 18.0
	if p.rig and fmod(_whirl_t, 0.5) < delta:
		p.rig.play("swing")
	_whirl_tick -= delta
	if _whirl_tick <= 0.0:
		_whirl_tick = 0.2
		var reach := p.body_size.x / 2 + 70.0
		for n in p.get_parent().get_children():
			if n is Player and n.team != p.team and n.is_alive():
				var dd: Vector2 = n.global_position - p.global_position
				if absf(dd.x) < reach + n.body_size.x / 2 and absf(dd.y) < p.body_size.y / 2 + 20.0:
					n.take_damage(7 if kind == "ataman" else 8, p)
					n.velocity.x = signf(dd.x) * 380.0
		Fx.sparks(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2 - 4), Color(0.7, 0.6, 0.45), 3, 160.0, 3.0)
	if _whirl_t <= 0.0:
		_whirl_t = 0.0
		if _disc:
			_disc.queue_free()
			_disc = null
		p._forced_time = 0.0
		p.stun(1.6)                                    # голова кружится
		p._float_label("Голова кружится!", Color(1.0, 0.9, 0.4))

# ---------- Колосс ----------
func _colossus(delta: float) -> void:
	var bs := p.body_size
	# пар из труб на спине (в перегреве — искры и огонь)
	_vent_t -= delta
	if _vent_t <= 0.0:
		_vent_t = 0.35 if _phase < 2 else 0.18
		var at := p.global_position + Vector2(-p.facing * bs.x * 0.38, -bs.y * 0.42)
		var c := Color(0.75, 0.75, 0.78, 0.8) if _phase < 2 else Color(1.0, 0.55, 0.2, 0.9)
		Fx.sparks(p.get_parent(), at, c, 3 if _phase < 2 else 5, 120.0, 6.0, true)
	# тяжёлые шаги: земля трескается
	if p.is_on_floor() and absf(p.velocity.x) > 30.0:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.6
			var feet := p.global_position + Vector2(p.facing * bs.x * 0.2, bs.y / 2)
			Fx.sparks(p.get_parent(), feet, Color(0.65, 0.55, 0.42), 5, 140.0, 4.0, true)
			Fx.cracks(p.get_parent(), feet, Color(0.3, 0.24, 0.2), 40.0)
	# огромный Колосс не перепрыгивает препятствия — он их сносит
	_crush_t -= delta
	if _crush_t <= 0.0:
		_crush_t = 0.25
		_crush()
	# фазы
	var ratio := float(p.hp) / p.max_hp
	var want := 0
	if ratio < 0.67:
		want = 1
	if ratio < 0.34:
		want = 2
	if want > _phase:
		_phase = want
		_enter_phase()

func _crush() -> void:
	var dirx := signf(p.velocity.x) if absf(p.velocity.x) > 5.0 else float(p.facing)
	if is_instance_valid(p.target) and absf(p.velocity.x) <= 5.0:
		dirx = signf(p.target.global_position.x - p.global_position.x)
	var space := p.get_world_2d().direct_space_state
	var bs := p.body_size
	for fy in [0.42, 0.15, -0.15, -0.4]:
		var from := p.global_position + Vector2(0, bs.y * fy)
		var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(dirx * (bs.x / 2 + 40.0), 0), Layer.WORLD, [p.get_rid()])
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and hit["collider"] is Destructible and not hit["collider"].background and not hit["collider"].one_way:
			hit["collider"].hit(hit["position"] + Vector2(dirx * 10.0, 0), Vector2(dirx, 0), 90, 46.0, p.team,
					{"strict": true, "radial": true, "origin": hit["position"], "attacker": p})
			Fx.sparks(p.get_parent(), hit["position"], Color(0.7, 0.62, 0.5), 6, 200.0, 4.0)

func _enter_phase() -> void:
	var world := p.get_parent()
	for ab in p.bot_abilities.keys():
		p.bot_abilities[ab] = p.bot_abilities[ab] * 0.8      # способности чаще
	p.speed *= 1.15
	if p.rig:
		p.rig.play("roar")
	Fx.ring(world, p.global_position, 260.0, Color(1.0, 0.35, 0.2, 0.85), 0.6, 9.0)
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	if _phase == 1:
		_banner(am, "Колосс в ярости!")
		if p.summon.is_valid():
			p.summon.call("fighter", 2, p.global_position)
	else:
		# перегрев: броня раскалилась и стала мягче, спина — ещё уязвимее
		_banner(am, "Колосс раскалился! Броня слабеет")
		p.front_armor = 0.6
		p.back_mult = 1.5
		p.set_tint(Color(1.25, 0.82, 0.75))
		if p.rig and "core_heat" in p.rig:
			p.rig.core_heat = 1.0                # ядро в нагруднике раскалилось
		if p.summon.is_valid():
			p.summon.call("fighter", 2, p.global_position)

# ========== Вторая фаза: «Колосс Пробуждённый» ==========
func _on_lethal() -> bool:
	if _awake or _waking:
		return false
	_waking = true
	p.hp = 1
	_start_awakening()
	return true

# Сцена пробуждения (~3,6 с): замедление, Колосс падает на колено, по броне бегут
# огненные трещины — и броня разлетается, а небо над Колизеем загорается.
func _start_awakening() -> void:
	var world := p.get_parent()
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	p.cutscene_shield = true
	p.frozen = true
	p.velocity = Vector2.ZERO
	p._forced_time = 0.0
	p.stagger = 0.0
	p._stun_t = 0.0                          # не «оглушён», а повержен
	if p._stun_fx:
		p._stun_fx.visible = false
	_whirl_t = 0.0
	if _disc:
		_disc.queue_free()
		_disc = null
	# бойцы, которых он звал, разбегаются
	if am:
		for b in am._alive.duplicate():
			if is_instance_valid(b) and b != p and b.is_alive():
				Fx.sparks(world, b.global_position, Color(0.8, 0.7, 0.5), 8, 200.0, 4.0)
				b.take_damage(99999)
	# замедление времени на миг
	Engine.time_scale = 0.3
	p.get_tree().create_timer(0.8, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	Util.flash(world, p.global_position, 260.0, Color(1.0, 0.9, 0.7, 0.9))
	Fx.shake(world, 8.0)
	if am:
		am.cinematic(p, 5.2)                    # камера смотрит на Колосса, герои ждут
	_banner(am, "Колосс повержен…")
	if p.rig:
		p.rig.play("roar")
	if p._rig_root:
		_rig_y = p._rig_root.position.y
		_rig_rot = p._rig_root.rotation
		var kt := p._rig_root.create_tween()
		kt.tween_property(p._rig_root, "rotation", -0.14 * p.facing, 0.7).set_trans(Tween.TRANS_SINE)
		kt.parallel().tween_property(p._rig_root, "position:y", _rig_y + 22.0, 0.7)
	# броня трескается всё сильнее, сыплются осколки — и разлетается; встаёт железный остов
	p._after(1.0, _shell_crack.bind(1))
	p._after(1.7, _shell_crack.bind(2))
	p._after(2.0, func(): _banner(am, "…но в груди у него горит огонь!"))
	p._after(2.4, _shell_crack.bind(3))
	p._after(3.0, _armor_burst)
	p._after(3.45, _endo_eyes)
	p._after(3.75, _endo_core_on)
	p._after(4.0, _endo_rise)
	p._after(4.4, _endo_roar)
	p._after(4.9, _begin_phase2)

# Броня трескается: огненные трещины на частях модели, дрожь, искры из швов
func _shell_crack(level: int) -> void:
	if not is_instance_valid(p):
		return
	_crack_level = level
	var world := p.get_parent()
	if p.rig and p.rig.has_method("shell_cracks"):
		p.rig.shell_cracks(level)
		p.rig.tremble = 0.35 * level
		p.rig.core_heat = 1.0
	Fx.shake(world, 3.0 + level * 2.0)
	Fx.sparks(world, p.global_position + Vector2(randf_range(-40, 40), randf_range(-60, 20)), Color(1.0, 0.6, 0.2), 8 + level * 4, 220.0, 4.0)
	if level >= 2:
		for k in level:                                     # пар бьёт из швов
			Fx.sparks(world, p.global_position + Vector2(randf_range(-50, 50), randf_range(-90, 30)), Color(0.85, 0.85, 0.88, 0.8), 5, 160.0, 6.0, true)

# Пока броня трещит — с неё сыплются мелкие осколки
func _chips(delta: float) -> void:
	_chip_t -= delta
	if _chip_t > 0.0 or not p.rig or not p.rig.has_method("body_points"):
		return
	_chip_t = 0.24 / _crack_level
	var pts: Array = p.rig.body_points()
	if pts.is_empty():
		return
	var at: Vector2 = pts[randi() % pts.size()] + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	var world := p.get_parent()
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	var floor_y: float = am.info["floor"] if am else p.global_position.y + p.body_size.y / 2
	var pl := Polygon2D.new()
	var w := randf_range(4, 9)
	pl.polygon = PackedVector2Array([Vector2(-w, -3), Vector2(w, -4), Vector2(w * 0.7, 4), Vector2(-w * 0.6, 3)])
	pl.color = Color(0.30, 0.24, 0.36).lerp(Color(0.55, 0.30, 0.25), randf() * 0.4)
	pl.position = at
	pl.z_index = 5
	world.add_child(pl)
	var vx := randf_range(-160, 160)
	var t := pl.create_tween()
	t.set_parallel(true)
	t.tween_property(pl, "position", Vector2(at.x + vx * 0.5, floor_y - 3.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(pl, "rotation", randf_range(-6.0, 6.0), 0.5)
	t.chain().tween_property(pl, "modulate:a", 0.0, 0.6).set_delay(1.5)
	t.chain().tween_callback(pl.queue_free)

func _armor_burst() -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	var c := p.global_position
	var floor_y: float = am.info["floor"] if am else c.y + p.body_size.y / 2
	_crack_level = 0
	# куски брони — настоящие части старой модели: шлем, две половины нагрудника,
	# наплечники с пушкой, поножи, плащ — разлетаются и падают на песок
	if p.rig:
		_fling_shell(world, p.rig, floor_y)
	p.set_rig("colossus_endo")
	p.set_tint(Color(1, 1, 1))
	if p.rig and "core_state" in p.rig:
		p.rig.core_state = "off"
		p.rig.pupils_on = false
	Fx.shake(world, 16.0)
	Util.flash(world, c, 340.0, Color(1.0, 0.7, 0.3, 0.95))
	Fx.ring(world, c, 440.0, Color(1.0, 0.5, 0.2, 0.95), 0.6, 12.0)
	Fx.ring(world, c, 260.0, Color(1.0, 0.85, 0.5, 0.9), 0.45, 8.0)
	Fx.sparks(world, c, Color(1.0, 0.6, 0.2), 40, 520.0, 7.0)
	Fx.sparks(world, Vector2(c.x, floor_y - 6), Color(0.75, 0.66, 0.5), 24, 360.0, 6.0, true)     # пыль с песка
	# мелкие осколки
	for k in 10:
		var pl := Polygon2D.new()
		var w := randf_range(6, 14)
		pl.polygon = PackedVector2Array([Vector2(-w, -5), Vector2(w, -6), Vector2(w * 0.8, 5), Vector2(-w * 0.7, 6)])
		pl.color = Color(0.26, 0.20, 0.32) if k % 3 else Color(0.36, 0.30, 0.40)
		pl.position = c + Vector2(randf_range(-40, 40), randf_range(-80, 40))
		pl.z_index = 5
		world.add_child(pl)
		var dir := Vector2.from_angle(randf_range(-PI, 0.0))
		var t := pl.create_tween()
		t.set_parallel(true)
		t.tween_property(pl, "position", pl.position + dir * randf_range(220, 460) + Vector2(0, 260), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(pl, "rotation", randf_range(-8.0, 8.0), 1.1)
		t.tween_property(pl, "modulate:a", 0.0, 0.5).set_delay(0.7)
		t.chain().tween_callback(pl.queue_free)
	# героев рядом отбрасывает волной (без урона)
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and n.global_position.distance_to(c) < 440.0:
			n.velocity = Vector2(signf(n.global_position.x - c.x + 0.01) * 720.0, -460.0)
	# небо загорается
	_sky = InfernoSky.new()
	_sky.boss = p
	_sky.map_w = p.map_w
	_sky.floor_y = floor_y
	_sky.glow = am.info.get("glow") if am else null
	world.add_child(_sky)

# Части брони — копии кусков старой модели: летят по дуге, падают на песок,
# лежат какое-то время и тают
func _fling_shell(world: Node, rig: Node, floor_y: float) -> void:
	var c := p.global_position
	var lo := Colosseum.WALL + 60.0
	var hi := (p.map_w if p.map_w > 0.0 else Colosseum.W) - Colosseum.WALL - 60.0
	var torso = rig.get("_torso")
	for nm in ["_head", "_torso", "_arm_f", "_arm_b", "_leg_f", "_leg_b", "_cape"]:
		var part = rig.get(nm)
		if not (part is Sprite2D) or not is_instance_valid(part):
			continue
		var skin := (part as Node).get_node_or_null("Skin") as Sprite2D
		if skin == null:
			continue
		var tex: Texture2D = skin.texture
		var tr: Transform2D = skin.get_global_transform()
		var size := tex.get_size()
		var pieces := [Rect2(Vector2.ZERO, size)]
		if part == torso:                                    # нагрудник раскалывается надвое
			pieces = [Rect2(0, 0, size.x / 2, size.y), Rect2(size.x / 2, 0, size.x / 2, size.y)]
		for r in pieces:
			var holder := Node2D.new()
			holder.z_index = 4
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.region_enabled = true
			sp.region_rect = r
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.modulate = (part as CanvasItem).modulate * Color(1.2, 0.9, 0.85)
			holder.add_child(sp)
			world.add_child(holder)
			var centre: Vector2 = tr * (r.position + r.size / 2.0)
			holder.global_transform = Transform2D(tr.x, tr.y, centre)
			var half_h: float = (tr.basis_xform(Vector2(0, r.size.y))).length() / 2.0
			var half_w: float = (tr.basis_xform(Vector2(r.size.x, 0))).length() / 2.0
			var g := 2300.0
			var up := randf_range(520.0, 880.0)
			var rest_y := floor_y - minf(half_h, half_w) - 1.0
			var dy := rest_y - centre.y
			var t_land := (up + sqrt(maxf(up * up + 2.0 * g * dy, 1.0))) / g
			var land_x := clampf(centre.x + signf(centre.x - c.x + randf_range(-25.0, 25.0)) * randf_range(160.0, 520.0), lo, hi)
			var vx := (land_x - centre.x) / t_land
			var spin := randf_range(-7.0, 7.0)
			var r0 := holder.rotation
			var p0 := centre
			var tw := holder.create_tween()
			tw.tween_method(func(t: float):
				if is_instance_valid(holder):
					holder.global_position = p0 + Vector2(vx * t, -up * t + 0.5 * g * t * t)
					holder.rotation = r0 + spin * t, 0.0, t_land, t_land)
			# упал: пыль, лёгкий отскок, ложится плашмя
			var flat := r0 + spin * t_land
			flat = round(flat / (PI / 2.0)) * (PI / 2.0)
			if absf(fmod(absf(flat), PI) - PI / 2.0) < 0.1 and half_w > half_h * 1.3:
				flat += PI / 2.0                              # длинной стороной — на песок
			tw.tween_callback(func():
				if is_instance_valid(world):
					Fx.sparks(world, Vector2(land_x, floor_y - 4.0), Color(0.75, 0.66, 0.5), 8, 180.0, 4.0, true))
			tw.tween_property(holder, "global_position:y", rest_y - 26.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(holder, "global_position:x", land_x + vx * 0.06, 0.28)
			tw.parallel().tween_property(holder, "rotation", flat, 0.28)
			tw.tween_property(holder, "global_position:y", rest_y, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_interval(7.0)
			tw.tween_property(holder, "modulate:a", 0.0, 1.5)
			tw.tween_callback(holder.queue_free)

# В пустых глазницах остова зажигаются зрачки (мигнув пару раз), голова дёргается
func _endo_eyes() -> void:
	if not is_instance_valid(p) or not p.rig or not ("pupils_on" in p.rig):
		return
	var rig = p.rig
	rig.tremble = 0.0
	for k in 4:
		p._after(k * 0.07, func():
			if is_instance_valid(rig):
				rig.pupils_on = k % 2 == 0)
	p._after(0.3, func():
		if is_instance_valid(rig):
			rig.pupils_on = true
			rig.jerk(-0.5 * 1.0, 0.2))

# Ядро в груди вспыхивает
func _endo_core_on() -> void:
	if not is_instance_valid(p) or not p.rig or not ("core_state" in p.rig):
		return
	var world := p.get_parent()
	p.rig.core_state = "on"
	p.rig.core_hit()
	var at: Vector2 = p.rig.core_point()
	Util.flash(world, at, 140.0, Color(1.0, 0.7, 0.3, 0.9))
	Fx.ring(world, at, 160.0, Color(1.0, 0.55, 0.2, 0.9), 0.4, 6.0)
	Fx.sparks(world, at, Color(1.0, 0.6, 0.2), 16, 260.0, 4.0)
	Fx.shake(world, 6.0)

# Остов выпрямляется — рывками, как механизм
func _endo_rise() -> void:
	if not is_instance_valid(p) or not p._rig_root:
		return
	var root := p._rig_root
	var r0 := root.rotation
	var y0 := root.position.y
	var kt := root.create_tween()
	for k in 3:
		var q := (k + 1) / 3.0
		kt.tween_property(root, "rotation", lerpf(r0, _rig_rot, q), 0.05)
		kt.parallel().tween_property(root, "position:y", lerpf(y0, _rig_y, q), 0.05)
		kt.tween_interval(0.08)
	if p.rig and p.rig.has_method("jerk"):
		p.rig.jerk(0.35, 0.15)

# Рёв: пасть настежь
func _endo_roar() -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	if p.rig:
		p.rig.play("roar")
	Fx.shake(world, 10.0)
	Fx.ring(world, p.global_position + Vector2(0, -p.body_size.y * 0.35), 300.0, Color(1.0, 0.45, 0.2, 0.8), 0.5, 7.0)

func _begin_phase2() -> void:
	Engine.time_scale = 1.0
	if not is_instance_valid(p):
		return
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	var t: Dictionary = Bots.TYPES["colossus"]
	var factor := float(p.max_hp) / float(t["hp"])          # волна и игра вдвоём
	var share := p.stagger_max / float(maxi(p.max_hp, 1))
	p.max_hp = int(t["phase2_hp"] * factor)
	p.stagger_max = p.max_hp * share
	p.stagger = 0.0
	var ht := p.create_tween()                                # полоска здоровья заполняется заново
	ht.tween_method(func(v: float):
		if is_instance_valid(p) and p.is_alive():
			p.hp = maxi(p.hp, int(v)), 1.0, float(p.max_hp), 1.0)
	p.front_armor = 0.0
	p.back_mult = 1.0
	p.speed = float(t["speed"]) * 1.5
	p.set_meta("title", t["phase2_name"])
	p.bot_abilities = {"fire_dash": 7.0, "meteor_leap": 11.0, "lava_volley": 6.0, "core_nova": 19.0, "shockwave": 10.0}
	p._bot_cd = {}
	if p._rig_root:
		p._rig_root.rotation = _rig_rot
		p._rig_root.position.y = _rig_y
	if p.rig and "core_state" in p.rig:
		p.rig.core_state = "on"
		p.rig.pupils_on = true
		p.rig.tremble = 0.0
	_awake = true
	_waking = false
	p.frozen = false
	p.cutscene_shield = false
	if am:
		am._name_card("colossus", t["phase2_name"], "ВТОРАЯ ФАЗА")
		var hint: String = t["hint2"]
		am._after(2.6, am.hud.show_hint.bind(hint, 10.0))

func _colossus_awake(delta: float) -> void:
	var bs := p.body_size
	var world := p.get_parent()
	_core_tick(delta)
	# искры с раскалённого каркаса
	_ember_t -= delta
	if _ember_t <= 0.0:
		_ember_t = 0.14
		Fx.sparks(world, p.global_position + Vector2(randf_range(-bs.x * 0.3, bs.x * 0.3), randf_range(-bs.y * 0.4, bs.y * 0.3)),
				Color(1.0, 0.55, 0.15), 2, 90.0, 3.0, true)
	_crush_t -= delta
	if _crush_t <= 0.0:
		_crush_t = 0.25
		_crush()
	if _dash_t > 0.0:
		_dash_tick(delta)
	if _leap != "":
		_leap_tick(delta)
	if _nova_t > 0.0:
		_nova_tick(delta)

# ----- Ядро остова: открывается после рывка и прыжка-метеора -----
func open_core(time: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var first := _core_open_t <= 0.0
	_core_open_t = maxf(_core_open_t, time)
	if first:
		p._float_label("Ядро открыто! Бей в грудь!", Color(1.0, 0.85, 0.4))
		if p.rig and p.rig.has_method("core_hit"):
			p.rig.core_hit()
			var at: Vector2 = p.rig.core_point()
			Fx.sparks(p.get_parent(), at, Color(0.9, 0.9, 0.92, 0.85), 10, 200.0, 6.0, true)     # пар из груди

func _core_tick(delta: float) -> void:
	if _core_open_t > 0.0:
		_core_open_t = maxf(0.0, _core_open_t - delta)
	if _spent and not p.is_stunned():
		_spent = false
	var opened := _core_open_t > 0.0
	p.front_mult = CORE_MULT if opened and _nova_t <= 0.0 else 1.0
	var rig = p.rig
	if rig and "core_open" in rig:
		var want := 1.0 if opened or _nova_t > 0.0 or _spent else 0.0
		rig.core_open = move_toward(rig.core_open, want, delta * 5.0)
		rig.core_state = "hot" if _nova_t > 0.0 else ("spent" if _spent else "on")
		if opened and fmod(_t, 0.3) < delta:
			Fx.sparks(p.get_parent(), rig.core_point() + Vector2(p.facing * 30.0, 0), Color(0.88, 0.88, 0.9, 0.7), 2, 110.0, 5.0, true)

# Попадание в открытое ядро: вспышка и надпись (не чаще раза в секунду)
func _on_hurt(_amount: int, attacker) -> void:
	if not _awake or p.front_mult <= 1.0 or attacker == null or not is_instance_valid(attacker) or not (attacker is Node2D):
		return
	var side := signf(attacker.global_position.x - p.global_position.x)
	if side != float(p.facing) and side != 0.0:
		return
	var at: Vector2 = p.global_position
	if p.rig and p.rig.has_method("core_hit"):
		p.rig.core_hit()
		at = p.rig.core_point()
	Fx.sparks(p.get_parent(), at, Color(1.0, 0.85, 0.45), 4, 200.0, 3.0)
	if _t - _core_note > 1.2:
		_core_note = _t
		p._float_label("ЯДРО! ×1,5", Color(1.0, 0.85, 0.35))

# ----- Огненный рывок: линия на земле, потом таран через поле, за ним горит земля -----
func start_dash(dir: float) -> void:
	var world := p.get_parent()
	_dash_dir = dir
	p._anim("windup")
	p._forced_time = 0.7
	p._forced_vx = 0.0
	p.facing = int(dir)
	var fy := p.global_position.y + p.body_size.y * 0.2
	var end_x := clampf(p.global_position.x + dir * 1400.0, 80.0, p.map_w - 80.0)
	LightBeam.aim_line(world, Vector2(p.global_position.x, fy), Vector2(end_x, fy), Color(1.0, 0.4, 0.1), 0.7)
	Fx.sparks(world, p.global_position + Vector2(-dir * 30.0, p.body_size.y / 2 - 6), Color(1.0, 0.55, 0.2), 10, 160.0, 4.0, true)
	p._after(0.7, func():
		if not is_instance_valid(p) or not p.is_alive() or p.is_stunned():
			return
		_dash_t = 0.85
		_dash_hit.clear()
		_trail_x = p.global_position.x
		p._forced_time = 0.85
		p._forced_vx = _dash_dir * 1450.0
		Fx.ring(world, p.global_position, 120.0, Color(1.0, 0.5, 0.2, 0.9), 0.3, 6.0))

func _dash_tick(delta: float) -> void:
	_dash_t -= delta
	var world := p.get_parent()
	var bs := p.body_size
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and not _dash_hit.has(n):
			var dd: Vector2 = n.global_position - p.global_position
			if absf(dd.x) < bs.x / 2 + n.body_size.x / 2 + 10.0 and absf(dd.y) < bs.y / 2 + n.body_size.y / 2:
				_dash_hit[n] = true
				n.take_damage(22, p)
				n.velocity = Vector2(_dash_dir * 650.0, -520.0)
				n.burn(2.0, 5.0, p)
	# за Колоссом горит земля
	var feet_y := p.global_position.y + bs.y / 2
	if absf(p.global_position.x - _trail_x) > 120.0:
		_trail_x = p.global_position.x
		var fz := FireZone.new()
		fz.team = p.team
		fz.attacker = p
		fz._life = 3.0
		fz.position = Vector2(p.global_position.x - _dash_dir * bs.x * 0.4, feet_y - 6.0)
		world.add_child(fz)
	if is_on_wall_ahead():
		_dash_t = 0.0
	if _dash_t <= 0.0:
		_dash_t = 0.0
		p._forced_time = 0.35
		p._forced_vx = 0.0
		Fx.shake(world, 6.0)
		Fx.sparks(world, p.global_position + Vector2(_dash_dir * bs.x / 2, bs.y / 2 - 10), Color(0.8, 0.6, 0.4), 12, 240.0, 4.0, true)
		open_core(CORE_OPEN)                              # перегрелся — грудь раскрывается, ядро наружу

func is_on_wall_ahead() -> bool:
	return p.global_position.x < 120.0 + p.body_size.x / 2 or p.global_position.x > p.map_w - 120.0 - p.body_size.x / 2

# ----- Прыжок-метеор: взмывает за край экрана, тень ищет героя, падает огненным ударом -----
func start_leap() -> void:
	_leap = "crouch"
	_leap_t = 0.4
	p._anim("stomp")
	p._forced_time = 0.5
	p._forced_vx = 0.0
	_leap_ground = p.global_position.y

func _leap_tick(delta: float) -> void:
	var world := p.get_parent()
	_leap_t -= delta
	match _leap:
		"crouch":
			if _leap_t <= 0.0:
				_leap = "up"
				_leap_t = 0.45
				p.cutscene_shield = true          # в небе его не достать
				p.set_physics_process(false)
				Fx.ring(world, Vector2(p.global_position.x, _leap_ground + p.body_size.y / 2), 160.0, Color(1.0, 0.6, 0.3, 0.9), 0.4, 7.0, 0.3)
				Fx.sparks(world, Vector2(p.global_position.x, _leap_ground + p.body_size.y / 2), Color(0.8, 0.65, 0.45), 16, 260.0, 5.0, true)
				var t := p.create_tween()
				t.tween_property(p, "global_position:y", _leap_ground - 1100.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				# тень на земле
				_shadow = Node2D.new()
				_shadow.z_index = 3
				var sh := Polygon2D.new()
				var pts := Util.circle(p.body_size.x * 0.7, 24)
				for i in pts.size():
					pts[i].y *= 0.22
				sh.polygon = pts
				sh.color = Color(0.0, 0.0, 0.0, 0.45)
				_shadow.add_child(sh)
				var ring := Line2D.new()
				var rp := pts.duplicate()
				rp.append(rp[0])
				ring.points = rp
				ring.width = 3.0
				ring.default_color = Color(1.0, 0.45, 0.15, 0.0)
				ring.name = "Ring"
				_shadow.add_child(ring)
				_shadow.position = Vector2(p.global_position.x, _leap_ground + p.body_size.y / 2)
				_shadow.scale = Vector2(0.3, 0.3)
				world.add_child(_shadow)
				_shadow.create_tween().tween_property(_shadow, "scale", Vector2.ONE, 1.2)
		"up":
			if _leap_t <= 0.0:
				_leap = "track"
				_leap_t = 1.3
		"track":
			if is_instance_valid(p.target) and is_instance_valid(_shadow):
				var tx := clampf(p.target.global_position.x, 120.0 + p.body_size.x / 2, p.map_w - 120.0 - p.body_size.x / 2)
				_shadow.position.x = move_toward(_shadow.position.x, tx, 850.0 * delta)
			if _leap_t <= 0.0:
				_leap = "lock"
				_leap_t = 0.5
				if is_instance_valid(_shadow):
					var ring: Line2D = _shadow.get_node("Ring")
					ring.default_color.a = 0.95
		"lock":
			if is_instance_valid(_shadow):
				var ring2: Line2D = _shadow.get_node("Ring")
				ring2.width = 3.0 + 2.0 * absf(sin(_t * 18.0))
			if _leap_t <= 0.0:
				_leap = "fall"
				_leap_t = 0.22
				var x: float = _shadow.position.x if is_instance_valid(_shadow) else p.global_position.x
				p.global_position = Vector2(x, _leap_ground - 1100.0)
				var t2 := p.create_tween()
				t2.tween_property(p, "global_position:y", _leap_ground, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"fall":
			if _leap_t <= 0.0:
				_leap = ""
				_land()

func _land() -> void:
	var world := p.get_parent()
	p.global_position.y = _leap_ground
	p.set_physics_process(true)
	p.cutscene_shield = false
	p.velocity = Vector2.ZERO
	p._forced_time = 0.7                              # приходит в себя после удара
	p._forced_vx = 0.0
	if is_instance_valid(_shadow):
		_shadow.queue_free()
	var feet := Vector2(p.global_position.x, _leap_ground + p.body_size.y / 2)
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive():
			var dd: Vector2 = n.global_position - feet
			if absf(dd.x) < 190.0 and dd.y > -260.0 and dd.y < 40.0:
				n.take_damage(30, p)
				n.velocity = Vector2(signf(dd.x + 0.01) * 600.0, -480.0)
	Util.explode(world, feet + Vector2(0, -20), 150.0, 0, 50, p.team, p, true)
	Fx.ring(world, feet, 220.0, Color(1.0, 0.5, 0.2, 0.95), 0.45, 10.0, 0.3)
	Fx.cracks(world, feet, Color(0.25, 0.12, 0.08), 180.0)
	Fx.sparks(world, feet + Vector2(0, -8), Color(1.0, 0.6, 0.2), 30, 420.0, 6.0, true)
	Fx.shake(world, 14.0)
	# столбы пламени расходятся в обе стороны — перепрыгивай!
	for side in [-1.0, 1.0]:
		for k in 8:
			p._after(0.12 + k * 0.08, _fire_pillar.bind(feet.x + side * (210.0 + k * 100.0), feet.y))
	open_core(CORE_OPEN)                                  # после удара грудь раскрывается — ядро наружу

func _fire_pillar(x: float, fy: float) -> void:
	if not is_instance_valid(p) or x < 70.0 or x > p.map_w - 70.0:
		return
	var world := p.get_parent()
	var col := Node2D.new()
	col.position = Vector2(x, fy)
	col.z_index = 4
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-16, -90), Vector2(-4, -150), Vector2(6, -140), Vector2(18, -86), Vector2(26, 0)])
	outer.color = Color(1.0, 0.42, 0.1, 0.9)
	col.add_child(outer)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-6, -80), Vector2(2, -110), Vector2(10, -70), Vector2(12, 0)])
	inner.color = Color(1.0, 0.88, 0.45, 0.95)
	col.add_child(inner)
	col.scale = Vector2(0.7, 0.05)
	world.add_child(col)
	var t := col.create_tween()
	t.tween_property(col, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(col, "scale", Vector2(0.5, 0.0), 0.3).set_delay(0.12)
	t.tween_callback(col.queue_free)
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive():
			var feet_n: float = n.global_position.y + n.body_size.y / 2
			if absf(n.global_position.x - x) < 30.0 + n.body_size.x / 2 and absf(feet_n - fy) < 24.0:
				n.take_damage(14, p)
				n.velocity.y = -560.0
				n.burn(1.5, 5.0, p)

# ----- Сверхновая: ядро разгорается 2,4 с (тянет героев к себе), взрыв — и Колосс выдыхается -----
func start_nova() -> void:
	var world := p.get_parent()
	_nova_t = NOVA_T
	p._anim("roar")
	p._forced_time = NOVA_T + 0.2
	p._forced_vx = 0.0
	p._float_label("Сверхновая!", Color(1.0, 0.6, 0.2))
	_nova_fx = Node2D.new()
	_nova_fx.z_index = 4
	var ring := Line2D.new()
	var pts := Util.circle(NOVA_R, 48)
	pts.append(pts[0])
	ring.points = pts
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.35, 0.1, 0.85)
	_nova_fx.add_child(ring)
	var fill := Polygon2D.new()
	fill.polygon = Util.circle(NOVA_R, 48)
	fill.color = Color(1.0, 0.4, 0.1, 0.12)
	fill.name = "Fill"
	fill.scale = Vector2(0.05, 0.05)
	_nova_fx.add_child(fill)
	_nova_fx.position = p.global_position
	world.add_child(_nova_fx)

func _nova_tick(delta: float) -> void:
	var world := p.get_parent()
	_nova_t -= delta
	if p.is_stunned():                                 # оглушили во время зарядки — сорвалась
		_nova_t = 0.0
		if is_instance_valid(_nova_fx):
			_nova_fx.queue_free()
		return
	if is_instance_valid(_nova_fx):
		_nova_fx.position = p.global_position
		var fill: Polygon2D = _nova_fx.get_node("Fill")
		fill.scale = Vector2.ONE * (1.0 - _nova_t / NOVA_T)
		fill.color.a = 0.12 + 0.15 * absf(sin(_t * 10.0))
	# ядро тянет героев к себе
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and not n.is_minion:
			var dx: float = p.global_position.x - n.global_position.x
			if absf(dx) < 900.0:
				n.global_position.x += signf(dx) * 110.0 * delta
	if fmod(_nova_t, 0.15) < delta:
		Fx.sparks(world, p.global_position + Vector2.from_angle(randf() * TAU) * 220.0, Color(1.0, 0.6, 0.2), 3, 60.0, 3.0)
	if _nova_t <= 0.0:
		_nova_t = 0.0
		_nova_boom()

func _nova_boom() -> void:
	var world := p.get_parent()
	var c := p.global_position
	if is_instance_valid(_nova_fx):
		_nova_fx.queue_free()
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and n.hurt_center().distance_to(c) < NOVA_R:
			n.take_damage(34, p)
			n.velocity = Vector2(signf(n.global_position.x - c.x + 0.01) * 820.0, -480.0)
	Util.explode(world, c, NOVA_R * 0.8, 0, 40, p.team, p, true)
	Util.flash(world, c, NOVA_R, Color(1.0, 0.75, 0.4, 0.95))
	Fx.ring(world, c, NOVA_R, Color(1.0, 0.55, 0.2, 0.95), 0.5, 12.0)
	Fx.ring(world, c, NOVA_R * 0.6, Color(1.0, 0.9, 0.6, 0.9), 0.35, 8.0)
	Fx.sparks(world, c, Color(1.0, 0.6, 0.2), 40, 600.0, 7.0)
	Fx.shake(world, 16.0)
	# выдохся: ядро погасло, урон по нему двойной
	_core_open_t = 0.0
	p.stun(3.0)
	_spent = true
	p._float_label("Колосс выдохся! урон ×%s" % str(p.stun_mult).trim_suffix(".0"), Color(1.0, 0.85, 0.3))

func _banner(am, text: String) -> void:
	if am and am.hud:
		am.hud.show_banner(text, Color(1.0, 0.45, 0.3))
		am._after(1.6, am.hud.hide_banner)

# ---------- Ведьма: стая воронов ----------
func start_blink() -> void:
	_begin_hide("blink", 0.9)
	var world := p.get_parent()
	for k in 8:
		Fx.sparks(world, p.global_position + Vector2(randf_range(-30, 30), randf_range(-50, 30)), Color(0.08, 0.08, 0.1), 3, 260.0, 6.0, true)
	# появится подальше от героя, но на арене
	var tx: float = p.target.global_position.x if is_instance_valid(p.target) else p.global_position.x
	var side := -1.0 if tx > Colosseum.W / 2 else 1.0
	_goal_x = _safe_x(tx + side * randf_range(450.0, 700.0))

# ---------- Трясинный Владыка: под трясиной ----------
func start_submerge() -> void:
	_begin_hide("submerge", 1.6)
	_goal_x = _safe_x(p.target.global_position.x if _good_target() else p.global_position.x)
	var world := p.get_parent()
	Fx.ring(world, Vector2(p.global_position.x, _floor_y), 150.0, Color(0.35, 0.4, 0.2, 0.9), 0.5, 7.0, 0.3)
	Fx.sparks(world, Vector2(p.global_position.x, _floor_y - 6), Color(0.3, 0.32, 0.18), 16, 260.0, 6.0, true)

# Куда можно вынырнуть/появиться: не в стене и не за краем арены
func _safe_x(x: float) -> float:
	var m := Colosseum.WALL + p.body_size.x / 2 + 20.0
	var w: float = p.map_w if p.map_w > 0.0 else Colosseum.W
	if x != x:                                   # NaN — на всякий случай
		x = p.global_position.x
	return clampf(x, m, w - m)

# Цель, за которой можно нырять: живой герой (не приманка и не призванный)
func _good_target() -> bool:
	var t = p.target
	return is_instance_valid(t) and t.is_alive() and t.visible and not t.is_minion and not t.has_meta("decoy")

func _begin_hide(kind_h: String, time: float) -> void:
	_hide_kind = kind_h
	_hide_t = time
	_floor_y = p.global_position.y + p.body_size.y / 2
	p.cutscene_shield = true
	p.visible = false
	p.frozen = true
	p.velocity = Vector2.ZERO
	p._col.set_deferred("disabled", true)
	p.set_physics_process(false)

func _hidden_tick(delta: float) -> void:
	_hide_t -= delta
	var world := p.get_parent()
	if _hide_kind == "submerge":
		if _good_target() and _hide_t > 0.75:
			_goal_x = _safe_x(move_toward(_goal_x, p.target.global_position.x, 420.0 * delta))
		p.global_position.x = move_toward(p.global_position.x, _goal_x, 700.0 * delta)
		if fmod(_hide_t, 0.12) < delta:
			Fx.sparks(world, Vector2(p.global_position.x, _floor_y - 4), Color(0.4, 0.45, 0.25), 3, 120.0, 5.0, true)
		if _hide_t < 0.75 and fmod(_hide_t, 0.15) < delta:
			Fx.ring(world, Vector2(_goal_x, _floor_y), 120.0, Color(0.6, 0.9, 0.3, 0.7), 0.2, 4.0, 0.3)
	else:
		p.global_position.x = move_toward(p.global_position.x, _goal_x, 1600.0 * delta)
		if fmod(_hide_t, 0.06) < delta:
			Fx.sparks(world, p.global_position + Vector2(randf_range(-50, 50), randf_range(-60, 20)), Color(0.08, 0.08, 0.1), 2, 200.0, 5.0)
	if _hide_t <= 0.0:
		_unhide()

func _unhide() -> void:
	var world := p.get_parent()
	var hk := _hide_kind
	_hide_kind = ""
	_hide_t = 0.0
	_goal_x = _safe_x(_goal_x)
	p.global_position = Vector2(_goal_x, _floor_y - p.body_size.y / 2 - 2.0)
	p.velocity = Vector2.ZERO
	p.visible = true
	p.frozen = false
	p.cutscene_shield = false
	p._col.set_deferred("disabled", false)
	p.set_physics_process(true)
	if p.rig:
		p.rig.play("roar")
	if hk == "submerge":
		var at := Vector2(_goal_x, _floor_y)
		Util.explode(world, at, 150.0, 28, 40, p.team, p)
		for n in world.get_children():
			if n is Player and n.team != p.team and n.is_alive() and absf(n.global_position.x - _goal_x) < 150.0:
				n.velocity = Vector2(signf(n.global_position.x - _goal_x) * 320.0, -720.0)
		Fx.ring(world, at, 170.0, Color(0.45, 0.5, 0.25, 0.9), 0.4, 8.0, 0.35)
		var pud := SwampBits.MudPuddle.new()
		pud.width = 200.0
		pud.life = 5.0
		pud.position = at
		world.add_child(pud)
	else:
		for k in 10:
			Fx.sparks(world, p.global_position + Vector2(randf_range(-40, 40), randf_range(-60, 30)), Color(0.08, 0.08, 0.1), 3, 240.0, 6.0)
		Fx.ring(world, p.global_position, 90.0, Color(0.6, 0.3, 0.9, 0.8), 0.3, 5.0)
