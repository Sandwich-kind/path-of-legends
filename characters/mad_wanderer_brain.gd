class_name MadWandererBrain
extends WandererBrain
# ---------- Странник, поглощённый бездной (волна 103, только сложная Арена) ----------
# Бездна проникла в его сердце и завладела им. Он больше не сдерживается: с первой секунды
# в небе на крыльях, бьёт быстро и без пауз. Три фазы — с каждой ещё яростнее:
#   1 (100–66%) — веер перьев, пике, «Тройной рывок» (три удара насквозь через арену),
#                 «Серпы» — волны меча; взмах крыльев.
#   2 (66–33%)  — сердце в груди рвётся наружу: добавляются клинки с неба, гроза,
#                 дождь осколков и «Тени Странника» (две тени-клинка).
#   3 (33–0%)   — «Хаос»: каждые 8 с на арену обрушивается что-то ещё — звездопад,
#                 сетка молний с двумя просветами, перекрёстные лучи, буря осколков.
# Как победить: «Пожирание» — он зависает и тянет в себя бездну (кольцо сжимается).
#   Набей урона по нему, пока кольцо не сомкнулось, — заряд сорван: он падает на землю,
#   и сердце бездны в груди обнажено (урон ×2, 3,5 с). Не успеешь — волна по всей арене,
#   а он залечивает раны.
# В конце сердце бездны раскалывается: Странник освобождается и уходит.

var mad := 1
var _chaos_t := 8.0
var _open_t := 0.0
var _heart: Polygon2D

func _ready() -> void:
	name = "WandererBrain"                       # AbyssAbilities.try ищет мозг по этому имени
	phase = 5
	p.on_lethal = _mad_lethal
	p.on_hurt = _on_hurt
	p.bar_lift = 30.0
	p.set_meta("title", "Странник, поглощённый бездной")
	_heart = Polygon2D.new()
	_heart.polygon = PackedVector2Array([Vector2(0, -7), Vector2(6, -1), Vector2(0, 8), Vector2(-6, -1)])
	_heart.color = Color(1.0, 0.35, 0.85, 0.9)
	_heart.position = Vector2(0, -p.body_size.y * 0.2)
	_heart.z_index = 9
	p.add_child.call_deferred(_heart)
	_mad_kit(1)
	(func(): _wake()).call_deferred()

func _wake() -> void:
	if not is_instance_valid(p):
		return
	if p.rig and p.rig.has_method("awaken"):
		p.rig.awaken(4)
	p.set_tint(Color(1.0, 0.72, 1.08))
	_take_wing()
	p.fly_hover = Vector2(310.0, -105.0)

func _mad_kit(n: int) -> void:
	mad = n
	_frenzy = n >= 2
	match n:
		1:
			p.speed = 380.0
			p.bot_abilities = {"feather_gale": 2.2, "sky_dive": 4.2, "blade_dash": 4.6, "crescent_wave": 3.2,
					"wing_burst": 2.8, "void_fan": 3.6, "nova": 15.0}
		2:
			p.speed = 420.0
			p.bot_abilities = {"feather_gale": 2.0, "sky_dive": 3.8, "blade_dash": 4.0, "crescent_wave": 2.8,
					"wing_burst": 2.6, "sky_blades": 5.5, "storm_judgement": 7.5, "shard_rain": 6.0, "shadow_clones": 16.0, "nova": 13.0}
		3:
			p.speed = 460.0
			p.bot_abilities = {"feather_gale": 1.7, "sky_dive": 3.4, "blade_dash": 3.4, "crescent_wave": 2.4,
					"wing_burst": 2.4, "sky_blades": 4.6, "storm_judgement": 6.0, "shard_rain": 5.0, "shadow_clones": 14.0, "nova": 11.0}
	p._bot_cd = {"nova": 9.0 if n == 1 else 6.0, "shadow_clones": 4.0}
	for k in p.bot_abilities:
		if not p._bot_cd.has(k):
			p._bot_cd[k] = randf_range(0.5, float(p.bot_abilities[k]) * 0.6)

func use(ab: String, to: Vector2) -> bool:
	if _busy or _charge_t > 0.0 or _open_t > 0.0 or not _target_ok() or p.frozen:
		return false
	match ab:
		"blade_dash":
			if _diving:
				return false
			_blade_dash()
			return true
		"crescent_wave":
			_crescent_wave()
			return true
		"shadow_clones":
			_shadow_clones()
			return true
	return super.use(ab, to)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		_end_nova()
		return
	_t += delta
	_dodge_cd -= delta
	if _charge_t > 0.0:
		_nova_tick(delta)
	if not is_instance_valid(_heart):
		pass
	elif _open_t > 0.0:
		_open_t -= delta
		_heart.scale = Vector2.ONE * (2.2 + 0.4 * sin(_t * 12.0))
		if _open_t <= 0.0:
			p.armor_mult = 1.0
			if is_instance_valid(_heart):
				_heart.scale = Vector2.ONE
			if p.is_alive() and not _busy:
				p.flying = true
				p.velocity = Vector2(0, -700)
				_feather_burst(10)
	elif is_instance_valid(_heart):
		_heart.scale = Vector2.ONE * (1.0 + 0.25 * sin(_t * 7.0))
	if _busy or p.frozen:
		return
	if mad == 1 and p.hp <= int(p.max_hp * 0.66):
		_mad_scene(2)
		return
	if mad == 2 and p.hp <= int(p.max_hp * 0.33):
		_mad_scene(3)
		return
	if mad == 3 and _charge_t <= 0.0 and _open_t <= 0.0:
		_chaos_t -= delta
		if _chaos_t <= 0.0:
			_chaos_t = 8.0
			_chaos()
	if _t > _storm_fx_t:
		_storm_fx_t = _t + randf_range(0.5, 1.4)
		_ambient_lightning()
	_dodge()

# ======================= новые приёмы =======================
# Тройной рывок: три удара насквозь — с разных сторон, через героя
func _blade_dash() -> void:
	_diving = true
	var world := p.get_parent()
	for k in 3:
		p._after(k * 0.55, func():
			if not is_instance_valid(p) or not p.is_alive() or _busy or not _target_ok():
				return
			var t: Vector2 = p.target.hurt_center()
			var side := -1.0 if k % 2 == 0 else 1.0
			var from := Vector2(clampf(t.x + side * 420.0, 120.0, Colosseum.W - 120.0), t.y - 120.0 + k * 60.0)
			var to := t + (t - from).normalized() * 380.0
			_ghost(p.global_position)
			p.global_position = from
			LightBeam.aim_line(world, from, to, Color(1.0, 0.5, 0.9), 0.22)
			p._after(0.22, func():
				if not is_instance_valid(p):
					return
				p._dive_v = (to - p.global_position) / 0.16
				p._dive_t = 0.16
				p._anim("slam")
				p._after(0.16, func():
					if is_instance_valid(p):
						LightBeam.draw(world, [[from, to, 0]], Color(1.0, 0.55, 0.95), 7.0, 0.3)
						RiftAbilities.hit_segment(p, from, to, 30.0, _dmg(11.0), 0))))
	p._after(1.9, func(): _diving = false)

# Серпы: веер широких волн меча
func _crescent_wave() -> void:
	p._anim("slam")
	var from := p.global_position
	var aim: Vector2 = (p.target.hurt_center() - from).normalized()
	for i in 3:
		var b := RiftAbilities.bolt(p, from, aim.rotated((i - 1) * 0.18), 840.0, _dmg(10.0), 24.0, 0)
		if b._vis2:
			for c in b._vis2.get_children():
				c.queue_free()
			var arc := Polygon2D.new()
			var pts := PackedVector2Array()
			for k in 9:
				pts.append(Vector2.from_angle(-1.1 + k * 0.275) * 22.0)
			for k in 9:
				pts.append(Vector2.from_angle(1.1 - k * 0.275) * 14.0 + Vector2(-6, 0))
			arc.polygon = pts
			arc.color = Color(1.0, 0.6, 0.95, 0.9)
			b._vis2.add_child(arc)

# Тени Странника: две тени-клинка из разломов
func _shadow_clones() -> void:
	var am := _am()
	if am == null:
		return
	p._anim("cast")
	for side in [-1.0, 1.0]:
		var at: Vector2 = p.target.global_position + Vector2(side * 360.0, -40.0)
		var s := RiftAbilities.Slit.new()
		s.position = Vector2(at.x, _floor_y())
		s.height = 140.0
		s.life = 1.2
		p.get_parent().add_child(s)
		p._after(0.5, func():
			if am and is_instance_valid(p):
				var c: Player = am.spawn_at("rift_blade", at)
				c.max_hp = maxi(1, int(c.max_hp * 0.35))
				c.hp = c.max_hp
				c.set_tint(Color(0.35, 0.15, 0.45))
				c.ab_tempo *= 1.4)

# Хаос (третья фаза): на арену обрушивается то одно, то другое
func _chaos() -> void:
	var world := p.get_parent()
	var pick := randi() % 4
	Fx.shake(world, 8.0)
	match pick:
		0:
			_banner("Звездопад!", Color(1.0, 0.6, 0.9), 1.2)
			for k in 3:
				p._after(k * 0.8, func(): if is_instance_valid(p): HardMode.drops(p, Color(1.0, 0.55, 0.9)))
		1:
			_banner("Сетка молний!", Color(1.0, 0.6, 0.9), 1.4)
			var gaps := [randi() % 9, randi() % 9]
			for k in 9:
				if k in gaps:
					continue
				_strike_column(260.0 + k * 260.0)
		2:
			_banner("Перекрёстные лучи!", Color(1.0, 0.6, 0.9), 1.2)
			_beam_sweep()
			p._after(1.2, func():
				if is_instance_valid(p):
					var fy := _floor_y()
					for y in [fy - 60.0, fy - 330.0]:
						var a := Vector2(Colosseum.WALL, y)
						var b := Vector2(Colosseum.W - Colosseum.WALL, y)
						LightBeam.aim_line(world, a, b, Color(1.0, 0.5, 0.9), 0.9)
						p._after(0.9, func():
							if is_instance_valid(p):
								LightBeam.draw(world, [[a, b, 0]], Color(1.0, 0.55, 0.95), 12.0, 0.3)
								RiftAbilities.hit_segment(p, a, b, 24.0, _dmg(13.0), 0)))
		3:
			_banner("Буря осколков!", Color(1.0, 0.6, 0.9), 1.2)
			_shard_rain()
			p._after(0.6, func(): if is_instance_valid(p) and _target_ok(): _feather_gale())
			p._after(1.4, func(): if is_instance_valid(p) and _target_ok(): _feather_gale())

# ======================= Пожирание и обнажённое сердце =======================
func _start_nova() -> void:
	super._start_nova()
	_banner("Пожирание! Сбей заряд!", Color(1.0, 0.65, 1.0), 1.6)

func _nova_tick(delta: float) -> void:
	_charge_t -= delta
	var need := p.max_hp * 0.06
	var k := clampf(_charge_dmg / need, 0.0, 1.0)
	if _charge_fx and is_instance_valid(_charge_fx):
		var r: Line2D = _charge_fx.get_node_or_null("R")
		if r:
			var rad := 460.0 * (_charge_t / 3.0) + 50.0
			r.scale = Vector2(rad, rad * 0.8)
			r.rotation += delta * 3.0
		var nb: ColorRect = _charge_fx.get_node_or_null("Need")
		if nb:
			nb.size.x = 160.0 * k
	var world := p.get_parent()
	if k >= 1.0:
		_end_nova()
		Util.flash(world, p.global_position, 260.0, Color(1.0, 0.9, 1.0, 0.95))
		_banner("Сердце обнажено — бей!", Color(1.0, 0.85, 0.4))
		p.flying = false
		p.velocity = Vector2(0, 500)
		p.stun(3.5)
		p.armor_mult = 2.0
		_open_t = 3.5
		return
	if _charge_t <= 0.0:
		_end_nova()
		Util.flash(world, p.global_position, 1000.0, Color(1.0, 0.5, 0.9, 0.85))
		Fx.shake(world, 16.0)
		Fx.ring(world, p.global_position, 1400.0, Color(1.0, 0.5, 0.9), 0.7, 14.0)
		for n in RiftAbilities._foes(p):
			n.take_damage(_dmg(26.0), p)
		p.heal(int(p.max_hp * 0.08))

# ======================= между фазами =======================
func _mad_scene(n: int) -> void:
	_freeze_for_scene()
	var am := _am()
	var world := p.get_parent()
	if am:
		am.cinematic(p, 3.6)
		am.shield_heroes(4.4)
	if p.rig:
		p.rig.play("roar")
	_absorb(1.6, 30)
	Fx.shake(world, 16.0)
	_banner("Странник: «БОЛЬШЕ… ЕЩЁ БОЛЬШЕ!»" if n == 2 else "ХАОС!", Color(1.0, 0.55, 0.85), 2.0)
	for c in world.get_children():
		if c is CanvasModulate:
			c.create_tween().tween_property(c, "color", Color(0.62, 0.42, 0.72) if n == 2 else Color(0.70, 0.36, 0.62), 1.5)
	p._after(2.0, func():
		if is_instance_valid(p):
			p.set_tint(Color(1.05, 0.6, 1.1) if n == 2 else Color(1.15, 0.5, 1.0))
			Util.flash(world, p.global_position, 700.0, Color(1.0, 0.55, 0.9, 0.9))
			_feather_burst(40))
	p._after(3.8, func():
		if not is_instance_valid(p):
			return
		_busy = false
		p.frozen = false
		p.cutscene_shield = false
		_mad_kit(n)
		p.flying = true
		p.fly_hover = Vector2(310.0 + n * 20.0, -105.0 - n * 10.0)
		if am:
			am._name_card("mad_wanderer", "Странник, поглощённый бездной", "ВТОРАЯ ФАЗА" if n == 2 else "ТРЕТЬЯ ФАЗА · ХАОС"))

func _mad_lethal() -> bool:
	if _busy:
		p.hp = 1
		return true
	if mad < 3:
		p.hp = int(p.max_hp * (0.6 if mad == 1 else 0.3))
		_mad_scene(mad + 1)
		return true
	p.hp = 1
	_set_free()
	return true

# Конец: сердце бездны раскалывается, Странник свободен и уходит
func _set_free() -> void:
	_freeze_for_scene()
	var am := _am()
	var world := p.get_parent()
	if am:
		am.cinematic(p, 7.4)
		am.shield_heroes(9.0)
	Engine.time_scale = 0.35
	p.get_tree().create_timer(0.8, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	p.flying = false
	if p.rig:
		p.rig.play("kneel")
	p._after(0.6, func():
		if is_instance_valid(_heart):
			Util.flash(world, p.hurt_center(), 300.0, Color(1.0, 0.9, 1.0, 0.95))
			Fx.sparks(world, p.hurt_center(), Color(1.0, 0.5, 0.9), 40, 420.0, 5.0)
			_heart.queue_free()
		_banner("Сердце бездны раскололось!", Color(1.0, 0.85, 0.4), 1.8))
	p._after(2.4, func():
		if is_instance_valid(p):
			p.set_tint(Color(1, 1, 1))
			if p.rig and p.rig.has_method("set_wings"):
				p.rig.set_wings(false)
			if p.rig and p.rig.has_method("awaken"):
				p.rig.awaken(0)
		_banner("Странник: «…Тихо. Впервые за долгое время — тихо.»", Color(0.85, 0.8, 1.0), 2.4))
	p._after(4.8, func(): _banner("Странник: «Спасибо, герой. Дальше я пойду сам.»", Color(0.85, 0.8, 1.0), 2.0))
	p._after(6.4, func():
		if not is_instance_valid(p):
			return
		var t := p.create_tween()
		t.tween_property(p, "modulate:a", 0.0, 0.9)
		Fx.sparks(world, p.global_position, Color(0.95, 0.9, 1.0), 30, 260.0, 4.0))
	p._after(7.4, func():
		_banner("Бездна отступила.", Color(1.0, 0.85, 0.4), 2.0)
		if am:
			am.boss_departs(p))
