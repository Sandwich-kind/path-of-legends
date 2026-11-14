class_name DjKit
extends HeroKit
# ---------- DJ КЛИМА — легенда из Лавки (персонаж друга автора игры) ----------
# Синие джинсы, чёрная кофта с нотой на груди, цепочка на шее, на голове — большие
# диджейские наушники с неоновыми кольцами.
# Оружие «Пластинки» — бросает виниловые пластинки очередью по 3, потом пауза. Каждая
#   очередь — новый трек, над головой видно жанр: джаз замедляет, электроника бьёт током
#   и перескакивает на соседа, рок оглушает на 0,5 с (одного врага — не чаще раза в 2 с),
#   поп без эффекта, зато бьёт на 40% сильнее.
# 1 «Бросок микрофона» — микрофон повисает на враге и фонит: ранит, оглушает на 1,5 с и
#   заглушает на 3 с (не может применять способности и ульту), звук в игре на миг глохнет.
#   Промах — микрофон фонит на земле и заглушает тех, кто рядом. МЕГА: всё на 2 с дольше.
# 2 «Лютый слэм» — 5 с качается под свою музыку: каждый удар бита — волна вокруг, можно
#   двигаться (медленнее), урона по нему на 25% меньше. В конце — прыжок и удар об землю.
#   МЕГА: дольше, финальный удар сильно отбрасывает и оглушает на 2 с.
# 3 «Скретч-порт» — звук скретча, и он меняется местами с ближайшим врагом впереди: враг
#   ранен и замедлен на 2 с. Боссов не двигает — сам прыгает им за спину. Врагов нет —
#   «перематывается» вперёд. МЕГА: дальность намного больше, урон сильнее.
# Ульта «Рейв-пати» — пульт, прожекторы и своя музыка: разгон, «ДРОП!» (вспышка и волна),
#   потом 5 с в такт с неба падают ноты четырёх жанров (куда упадёт — видно заранее).
#   Враг в луче прожектора получает больше урона, свои в луче бегут быстрее. Пульт закрывает
#   от выстрелов спереди. Кнопка атаки в такт — лишняя нота на ближайшего врага. В конце —
#   «финальный аккорд»: огромная пластинка на самого сильного врага.
#   МЕГА: по бокам встают два охранника и бьют дубинками всех, кто подходит к диджею.

const NEON := Color(0.30, 0.90, 1.0)
const PINK := Color(1.0, 0.36, 0.80)
const GENRES := ["jazz", "electro", "rock", "pop"]
const GENRE := {
	"jazz": {"name": "ДЖАЗ", "color": Color(0.38, 0.58, 1.0)},
	"electro": {"name": "ЭЛЕКТРО", "color": Color(1.0, 0.92, 0.25)},
	"rock": {"name": "РОК", "color": Color(1.0, 0.30, 0.25)},
	"pop": {"name": "ПОП", "color": Color(1.0, 0.48, 0.86)},
}
const BPM := 150.0
const BEAT := 60.0 / BPM               # 0,4 с — один удар бита (и в слэме, и в ульте)
const BURST := 3
const ROCK_ICD := 2.0
const POP_MULT := 1.4
const SLAM_BEATS := 12                 # 4,8 с + финальный удар ≈ 5 с
const SLAM_BEATS_MEGA := 16
const G := 1400.0

var genre := ""
var _burst_left := 0
var _burst_dir := 1                    # куда полетела очередь: развернулся на середине — пластинки летят туда же
var _genre_lbl: Label
var _genre_t := 0.0
var _rock_cd := {}                     # враг -> сколько ещё рок не оглушит его снова

var _slam_t := 0.0                     # > 0 — идёт слэм (время до следующего бита)
var _slam_n := 0                       # сколько битов уже отбито
var _slam_need := SLAM_BEATS
var _slam_mega := false
var _slam_final := false
var _move0 := 1.0
var _armor0 := 1.0

var _rave: Node2D                      # сцена ульты (RaveStage)

# ---------- Оружие: пластинки ----------
func weapon(delta: float, shoot: bool) -> void:
	if _slam_t > 0.0 or ulting():
		return
	var rapid := p.has_buff("rapid")
	if p._reloading > 0.0:
		p._reloading -= delta
		if p._reloading <= 0.0:
			p._reloading = 0.0
			p.ammo = p.clip_size
	elif not p.is_bot and Input.is_action_just_pressed(p.prefix + "_reload") and p.ammo < p.clip_size:
		p._reloading = p.reload_time
		_burst_left = 0
	if rapid:
		p._reloading = 0.0
		p.ammo = p.clip_size
	# очередь из трёх: начал — пластинки летят все три, даже если кнопку отпустили
	if _burst_left <= 0 and not shoot:
		return
	if p._cooldown_left > 0.0 or p._reloading > 0.0:
		return
	if _burst_left <= 0:
		_burst_left = BURST
		_burst_dir = p.facing
		p.ammo = p.clip_size                                 # обойма — это и есть очередь
		_next_genre()
	_throw_record()
	_burst_left -= 1
	p._cooldown_left = p.fire_cooldown * (0.6 if rapid else 1.0)
	if not rapid:
		p.ammo = maxi(0, p.ammo - 1)
		if _burst_left <= 0:
			p._reloading = p.reload_time                     # пауза между треками
	elif _burst_left <= 0:
		p._cooldown_left = p.fire_cooldown * 2.0           # и под «Скорострельностью» — короткая пауза

func _next_genre() -> void:
	var pool: Array = GENRES.filter(func(g): return g != genre)
	genre = pool[randi() % pool.size()]
	_show_genre()

# Над головой — жанр текущего трека
func _show_genre() -> void:
	if _genre_lbl == null or not is_instance_valid(_genre_lbl):
		_genre_lbl = Label.new()
		_genre_lbl.add_theme_font_size_override("font_size", 15)
		_genre_lbl.add_theme_constant_override("outline_size", 5)
		_genre_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.10))
		_genre_lbl.z_index = 8
		p.add_child(_genre_lbl)
	_genre_lbl.text = "♪ " + String(GENRE[genre]["name"])
	_genre_lbl.add_theme_color_override("font_color", GENRE[genre]["color"])
	_genre_lbl.position = Vector2(-_genre_lbl.get_minimum_size().x / 2, -p.body_size.y / 2 - 50 - p.bar_lift * 0.6)
	_genre_lbl.modulate.a = 1.0
	_genre_lbl.scale = Vector2(1.25, 1.25)
	_genre_t = 1.4
	create_tween().tween_property(_genre_lbl, "scale", Vector2.ONE, 0.15)

func _throw_record() -> void:
	var g := genre
	var dmg := p.bullet_damage
	if g == "pop":
		dmg = int(round(dmg * POP_MULT))
	var b := p._shoot_bullet(p.bullet_speed, dmg, 0.0, p.bullet_size, randf_range(-0.03, 0.03))
	if signf(b.direction.x) != float(_burst_dir):
		b.direction.x = -b.direction.x
		b.position.x = p.global_position.x + _burst_dir * absf(b.position.x - p.global_position.x)
	b.position.y = minf(b.position.y, p.global_position.y + 2.0)    # бросок от груди: большой диск не чиркает по полу
	b.color = GENRE[g]["color"]
	b.restyle("vinyl")
	if p.has_buff("rapid") and p.is_mega("rapid"):
		b.pierce = 1
	b.on_hit = func(body): genre_hit(body, g, dmg, 1.0)
	p._anim("throw")

# Попадание пластинки или ноты: эффект по жанру (k — сила: ноты ульты, «финальный аккорд»)
func genre_hit(body: Node, g: String, dmg: int, k: float) -> void:
	if not (body is Player) or not is_instance_valid(body) or not body.is_alive():
		return
	var e := body as Player
	var world := p.get_parent()
	var boss := e.stagger_max > 0.0
	match g:
		"jazz":
			e.slow(1.3 * k, 0.6, "water")
			Fx.sparks(world, e.hurt_center(), GENRE["jazz"]["color"], 4, 90.0, 3.0, true)
		"electro":
			Fx.zap(world, e.hurt_center(), GENRE["electro"]["color"], 20.0)
			var best: Player = null
			var bd := 180.0
			for o in _enemies():
				if o != e:
					var d: float = o.global_position.distance_to(e.global_position)
					if d < bd:
						bd = d
						best = o
			if best:
				Fx.bolt(world, e.hurt_center(), best.hurt_center(), GENRE["electro"]["color"])
				best.take_damage(maxi(2, int(dmg * 0.5)), p)
		"rock":
			if boss:
				return
			if float(_rock_cd.get(e, 0.0)) <= 0.0:
				_rock_cd[e] = ROCK_ICD
				e.stun(0.5 if k <= 1.0 else 0.7)
				e._float_label("РОК!", GENRE["rock"]["color"])
		"pop":
			Fx.sparks(world, e.hurt_center(), GENRE["pop"]["color"], 5, 130.0, 3.5)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	if ulting():
		return                                            # за пультом — только музыка (откат идёт сам)
	if ab == "mosh_slam" and _slam_t > 0.0:
		p._cd[i] = p.ability_cds[i]                       # откат слэма пойдёт, когда он закончится
		return
	super(i, ab, action, delta)

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"mic_drop":
			_mic(mega)
		"mosh_slam":
			_slam(mega)
		"scratch_port":
			_scratch(mega)

# ----- 1. Бросок микрофона -----
func _mic(mega: bool) -> void:
	p._anim("throw")
	var m := Mic.new()
	m.owner_p = p
	m.mega = mega
	m.position = p.global_position + Vector2(p.facing * 18.0, -14.0)
	var t := _nearest_ahead(760.0)
	var dir := Vector2(p.facing, -0.08).normalized()
	if t:
		dir = (t.hurt_center() - m.position).normalized()
		dir = Vector2(signf(dir.x) if absf(dir.x) > 0.2 else float(p.facing), clampf(dir.y, -0.6, 0.6)).normalized()
	m.vel = dir * 980.0
	p.get_parent().add_child(m)
	p._float_label("Раз-раз!", Skins.col(p, NEON))

func _nearest_ahead(reach: float) -> Player:
	var best: Player = null
	var bd := reach
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if to.x * p.facing > -10.0 and absf(to.y) < 320.0 and not e.cutscene_shield:
			var d := to.length()
			if d < bd:
				bd = d
				best = e
	return best

# Микрофон попал: повис на враге и фонит
func mic_hit(e: Player, mega: bool) -> void:
	var boss := e.stagger_max > 0.0
	var stun := (2.0 if mega else 1.5) if not boss else (0.6 if mega else 0.4)
	var mute := (5.0 if mega else 3.0) if not boss else (2.5 if mega else 1.5)
	e.take_damage(16 if mega else 12, p)
	if not e.is_alive():
		return
	e.stun(stun)
	e.mute(mute)
	e._float_label("ПИИИИ!", Skins.col(p, NEON))
	var hang := MicHang.new()
	hang.life = mute
	hang.col = Skins.col(p, NEON)
	e.add_child(hang)
	hang.position = Vector2(e.body_size.x * 0.3, -e.body_size.y * 0.2)
	Audio.ring_sfx("feedback", -4.0)
	Audio.muffle(1.1)
	var world := p.get_parent()
	Fx.star(world, e.hurt_center(), 40.0, Color(1, 1, 1), 0.3)
	for j in 3:                                                # звуковые волны расходятся одна за другой
		get_tree().create_timer(j * 0.12).timeout.connect(func():
			if is_instance_valid(world) and is_instance_valid(e):
				Fx.ring(world, e.hurt_center(), 70.0 + j * 40.0, Color(Skins.col(p, NEON), 0.8 - j * 0.2), 0.35, 4.0))

# ----- 2. Лютый слэм -----
func _slam(mega: bool) -> void:
	if _slam_t > 0.0:
		return
	_slam_mega = mega
	_slam_need = (SLAM_BEATS_MEGA if mega else SLAM_BEATS) + (2 if Balance.arena(p) else 0)
	_slam_n = 0
	_slam_t = 0.05
	_slam_final = false
	_move0 = p.move_mult
	_armor0 = p.armor_mult
	p.move_mult = _move0 * 0.75
	p.armor_mult = _armor0 * 0.75
	p._float_label("ЛЮТЫЙ СЛЭМ!", Skins.col(p, PINK))
	Audio.hero_track("dj_slam")

func slamming() -> bool:
	return _slam_t > 0.0

func _slam_tick(delta: float) -> void:
	_dance(_slam_n, 1.0 - _slam_t / BEAT, 1.0)
	_slam_t -= delta
	if _slam_t > 0.0:
		return
	if _slam_n >= _slam_need:
		_slam_end()
		return
	_slam_n += 1
	_slam_t = BEAT
	var world := p.get_parent()
	var down := _slam_n % 4 == 1
	var r := (165.0 if _slam_mega else 150.0) * (1.15 if down else 1.0)
	var at := p.global_position + Vector2(0, p.body_size.y * 0.3)
	var c: Color = GENRE[GENRES[_slam_n % 4]]["color"]
	Fx.ring(world, at, r, Color(c, 0.85), 0.28, 5.0 if down else 3.0, 0.4)
	_eq_bars(world, p.global_position + Vector2(0, p.body_size.y / 2), r, down)
	if down:
		Fx.confetti(world, p.global_position + Vector2(0, -p.body_size.y / 2), 10, [], 380.0)
	Fx.sparks(world, at, c, 4 if down else 2, 200.0, 3.0, true)
	for e in _enemies():
		var to: Vector2 = e.hurt_center() - p.hurt_center()
		if absf(to.x) < r + e.body_size.x * 0.4 and absf(to.y) < 90.0 + e.body_size.y * 0.4:
			e.take_damage((12 if down else 8) if Balance.arena(p) else (8 if down else 5), p)
			if e.stagger_max <= 0.0 and e.is_alive():
				e.velocity = Vector2(signf(to.x if to.x != 0.0 else 1.0) * (340.0 if down else 220.0), -160.0 if down else -90.0)
	if down:
		Fx.shake(world, 2.5)

func _slam_end() -> void:
	_slam_t = 0.0
	_slam_final = true
	p.move_mult = _move0
	p.armor_mult = _armor0
	_dance_reset()
	Audio.stop_hero_track(0.5)
	# финальный удар: прыжок и удар об землю
	p.velocity.y = -520.0
	p._anim("stomp")
	_after(0.32, _slam_stomp)

func _slam_stomp() -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var world := p.get_parent()
	var r := 175.0 if _slam_mega else 150.0
	var at := p.global_position + Vector2(0, p.body_size.y / 2)
	Fx.shockwave(world, at, r * 1.1, Skins.col(p, PINK), 0.35)
	Fx.dust(world, at, 10, Color(0.6, 0.55, 0.5), 160.0, 22.0)
	Fx.debris(world, at, 10, Color(0.42, 0.38, 0.34), 460.0, 6.0)
	Fx.confetti(world, at + Vector2(0, -20), 24, [], 560.0)
	Fx.cracks(world, at, Color(0.15, 0.12, 0.2), 110.0)
	Fx.sparks(world, at, Skins.col(p, NEON), 16, 320.0, 4.5, true)
	Fx.shake(world, 8.0)
	Audio.sfx("slam", at)
	for e in _enemies():
		var to: Vector2 = e.hurt_center() - at
		if absf(to.x) < r + e.body_size.x * 0.4 and absf(to.y) < 130.0 + e.body_size.y * 0.4:
			e.take_damage(26 if _slam_mega else 20, p)
			if not e.is_alive() or e.stagger_max > 0.0:
				if _slam_mega and e.is_alive():
					e.stun(0.5)
				continue
			if _slam_mega:
				e.velocity = Vector2(signf(to.x if to.x != 0.0 else 1.0) * 820.0, -440.0)
				e.stun(2.0)
			else:
				e.velocity = Vector2(signf(to.x if to.x != 0.0 else 1.0) * 420.0, -240.0)

# Столбики эквалайзера выскакивают из пола вокруг диджея в такт
func _eq_bars(world: Node, feet: Vector2, r: float, down: bool) -> void:
	var n := 10 if down else 6
	for j in n:
		var bar := Polygon2D.new()
		var w := 10.0
		var hgt := randf_range(30.0, 70.0) * (1.4 if down else 1.0)
		bar.polygon = PackedVector2Array([Vector2(-w / 2, 0), Vector2(w / 2, 0), Vector2(w / 2, -hgt), Vector2(-w / 2, -hgt)])
		bar.color = Color(GENRE[GENRES[j % 4]]["color"], 0.8)
		var side := -1.0 if j % 2 == 0 else 1.0
		bar.position = feet + Vector2(side * randf_range(30.0, r), 0)
		bar.scale.y = 0.0
		bar.z_index = -1
		world.add_child(bar)
		var tw := bar.create_tween()
		tw.tween_property(bar, "scale:y", 1.0, 0.08).set_ease(Tween.EASE_OUT)
		tw.tween_property(bar, "scale:y", 0.0, 0.25).set_ease(Tween.EASE_IN)
		tw.tween_callback(bar.queue_free)

# Танец: голова качается в такт, корпус пружинит (phase — доля бита 0..1)
func _dance(n: int, phase: float, amp: float) -> void:
	if p._rig_root == null:
		return
	var hop := absf(sin(phase * PI)) * 7.0 * amp
	p._rig_root.position = Vector2(0, p.body_size.y / 2 - hop)
	p._rig_root.rotation = sin((n + phase) * PI) * 0.16 * amp

func _dance_reset() -> void:
	if p._rig_root:
		p._rig_root.position = Vector2(0, p.body_size.y / 2)
		p._rig_root.rotation = 0.0

# ----- 3. Скретч-порт -----
func _scratch(mega: bool) -> void:
	var world := p.get_parent()
	var reach := 900.0 if mega else 540.0
	var t := _nearest_ahead(reach)
	if t == null:
		t = _nearest_enemy(reach * 0.6)
	Audio.sfx("scratch", p.global_position)
	var from := p.global_position
	if t == null:
		# никого рядом: «перемотка» вперёд, если не упрёмся в стену
		var to := from + Vector2(p.facing * 230.0, 0)
		var hit := p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, Layer.WORLD))
		if not hit.is_empty():
			to = Vector2(hit["position"].x - p.facing * (p.body_size.x / 2 + 4.0), from.y)
		_rewind_fx(world, from, to)
		p.global_position = to
		p.velocity = Vector2.ZERO
		return
	var feet_e := t.global_position.y + t.body_size.y / 2
	var feet_p := from.y + p.body_size.y / 2
	var big := t.stagger_max > 0.0 or t.anchored or t.body_size.y > 130.0
	var dest: Vector2
	if big:
		# босса не сдвинуть — прыгаем ему за спину
		var side := signf(t.global_position.x - from.x)
		if side == 0.0:
			side = float(p.facing)
		dest = Vector2(t.global_position.x + side * (t.body_size.x / 2 + p.body_size.x / 2 + 18.0), feet_e - p.body_size.y / 2)
		var q := PhysicsPointQueryParameters2D.new()
		q.position = dest
		q.collision_mask = Layer.WORLD
		if not p.get_world_2d().direct_space_state.intersect_point(q, 1).is_empty():
			dest = Vector2(t.global_position.x - side * (t.body_size.x / 2 + p.body_size.x / 2 + 18.0), feet_e - p.body_size.y / 2)
	else:
		dest = Vector2(t.global_position.x, feet_e - p.body_size.y / 2)
		t.global_position = Vector2(from.x, feet_p - t.body_size.y / 2)
		t.velocity = Vector2.ZERO
	_rewind_fx(world, from, dest)
	p.global_position = dest
	p.velocity = Vector2.ZERO
	p.facing = 1 if t.global_position.x > p.global_position.x else -1
	t.take_damage(16 if mega else 8, p)
	if t.is_alive():
		t.slow(2.0, 0.55, "water")
		t._float_label("вжжик!", Skins.col(p, PINK))
		_vhs(t)
	_vhs(p)

# Скретч: спираль-дорожка от точки к точке и «полосы перемотки»
func _rewind_fx(world: Node, a: Vector2, b: Vector2) -> void:
	Fx.glow(world, a, 46.0, Color(Skins.col(p, PINK), 0.5), 0.35)
	Fx.glow(world, b, 46.0, Color(Skins.col(p, NEON), 0.5), 0.35)
	Fx.sparks(world, b, Skins.col(p, NEON), 10, 260.0, 4.0)
	var l := Line2D.new()
	var pts := PackedVector2Array()
	for k in 25:
		var q := k / 24.0
		pts.append(a.lerp(b, q) + Vector2(0, sin(q * TAU * 3.0) * 16.0 * (1.0 - absf(q - 0.5) * 2.0)))
	l.points = pts
	l.width = 4.0
	l.default_color = Color(Skins.col(p, PINK), 0.85)
	l.z_index = 6
	world.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.tween_callback(l.queue_free)
	Fx.ring(world, a, 40.0, Color(Skins.col(p, NEON), 0.9), 0.25, 4.0)
	Fx.ring(world, b, 40.0, Color(Skins.col(p, NEON), 0.9), 0.25, 4.0)

func _vhs(n: Player) -> void:
	var fx := Node2D.new()
	fx.z_index = 5
	n.add_child(fx)
	for k in 4:
		var r := Polygon2D.new()
		var w := n.body_size.x * 1.4
		r.polygon = PackedVector2Array([Vector2(-w / 2, 0), Vector2(w / 2, 0), Vector2(w / 2, 2), Vector2(-w / 2, 2)])
		r.color = [Color(1.0, 0.36, 0.8, 0.7), Color(0.3, 0.9, 1.0, 0.7)][k % 2]
		r.position = Vector2(randf_range(-6, 6), -n.body_size.y / 2 + k * n.body_size.y / 4.0)
		fx.add_child(r)
	var tw := fx.create_tween()
	tw.tween_property(fx, "modulate:a", 0.0, 0.4)
	tw.tween_callback(fx.queue_free)

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	for e in _rock_cd.keys():
		var v := float(_rock_cd[e]) - delta
		if v <= 0.0 or not is_instance_valid(e):
			_rock_cd.erase(e)
		else:
			_rock_cd[e] = v
	if _genre_t > 0.0 and _genre_lbl and is_instance_valid(_genre_lbl):
		_genre_t -= delta
		_genre_lbl.modulate.a = clampf(_genre_t / 0.4, 0.0, 1.0)
	if _slam_t > 0.0:
		_slam_tick(delta)
	if ulting():
		p._forced_time = maxf(p._forced_time, 0.05)
		p._forced_vx = 0.0
		var rv := _rave as RaveStage
		_dance(rv.beat_i, rv.beat_phase(), 0.7)
		if not p.is_bot and Input.is_action_just_pressed(p.prefix + "_shoot"):
			rv.player_tap()
	elif _rave != null:
		_rave = null
		_dance_reset()

# ---------- Ульта: Рейв-пати ----------
func ult() -> void:
	var mega := p._mega_ab()
	if _slam_t > 0.0:
		_slam_t = 0.0
		p.move_mult = _move0
		p.armor_mult = _armor0
	_burst_left = 0
	var st := RaveStage.new()
	st.owner_p = p
	st.kit = self
	st.mega = mega
	st.party_beats = 12 + (4 if Balance.arena(p) else 0)
	st.position = p.global_position + Vector2(0, p.body_size.y / 2)
	st.facing = p.facing
	p.get_parent().add_child(st)
	_rave = st
	Audio.hero_track("dj_rave")

func ulting() -> bool:
	return _rave != null and is_instance_valid(_rave) and not (_rave as RaveStage).done

# легенду убрали со сцены (конец раунда, выход в меню) — своя музыка не должна играть дальше
func _exit_tree() -> void:
	if _slam_t > 0.0 or ulting():
		Audio.stop_hero_track(0.3)

func on_death() -> void:
	super()
	if _slam_t > 0.0:
		_slam_t = 0.0
		p.move_mult = _move0
		p.armor_mult = _armor0
		Audio.stop_hero_track(0.3)
	if _rave != null and is_instance_valid(_rave):
		(_rave as RaveStage).finish()
	_dance_reset()


# =====================================================================
# Микрофон: летит почти прямо (чуть проседает), попал — повис на враге; промах — фонит на земле
class Mic extends Node2D:
	var owner_p: Player
	var mega := false
	var vel := Vector2.ZERO
	var _t := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 6
		var cable := Line2D.new()                         # хвостик провода
		cable.points = PackedVector2Array([Vector2(-6, 0), Vector2(-14, 3), Vector2(-20, -1)])
		cable.width = 1.5
		cable.default_color = Color(0.1, 0.1, 0.12)
		add_child(cable)
		var body := Polygon2D.new()                       # ручка
		body.polygon = PackedVector2Array([Vector2(-7, -2), Vector2(4, -3), Vector2(4, 3), Vector2(-7, 2)])
		body.color = Color(0.12, 0.12, 0.15)
		add_child(body)
		var ring := Polygon2D.new()
		ring.polygon = PackedVector2Array([Vector2(3, -3.5), Vector2(5, -3.5), Vector2(5, 3.5), Vector2(3, 3.5)])
		ring.color = Skins.col(owner_p, DjKit.NEON)
		add_child(ring)
		var head := Polygon2D.new()                       # сетка
		head.polygon = Util.circle(5.0, 10)
		head.position = Vector2(9, 0)
		head.color = Color(0.72, 0.74, 0.80)
		add_child(head)
		for k in 3:
			var g := Line2D.new()
			g.points = PackedVector2Array([Vector2(6 + k * 2.5, -4), Vector2(6 + k * 2.5, 4)])
			g.width = 1.0
			g.default_color = Color(0.45, 0.46, 0.52)
			add_child(g)

	func _physics_process(delta: float) -> void:
		if _done:
			return
		if not is_instance_valid(owner_p):
			queue_free()
			return
		_t += delta
		var from := position
		vel.y += 260.0 * delta
		position += vel * delta
		rotation = vel.angle()
		for e in owner_p.kit._enemies():
			var c: Vector2 = e.hurt_center()
			if absf(c.x - position.x) < e.body_size.x / 2 + 10.0 and absf(c.y - position.y) < e.body_size.y / 2 + 10.0 \
					and not e.cutscene_shield:
				_done = true
				owner_p.kit.mic_hit(e, mega)
				queue_free()
				return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, position, Layer.WORLD))
		if not hit.is_empty() and Util.shot_passes(hit["collider"], self):
			hit = {}                                       # сквозь мостки и платформы — как пули
		if not hit.is_empty() or _t > 0.8:
			if not hit.is_empty():
				position = hit["position"]
			_ground_feedback()

	# промах: фонит там, где упал — заглушает и чуть ранит всех рядом
	func _ground_feedback() -> void:
		_done = true
		var world := get_parent()
		var r := 120.0 if mega else 100.0
		Audio.sfx("feedback", position, -6.0)
		for k in 3:
			Fx.ring(world, position, r * (0.5 + k * 0.25), Color(Skins.col(owner_p, DjKit.NEON), 0.8 - k * 0.2), 0.3 + k * 0.1, 3.0)
		for e in owner_p.kit._enemies():
			if e.hurt_center().distance_to(position) < r + e.body_size.x * 0.4:
				e.take_damage(6, owner_p)
				if e.is_alive():
					e.mute((2.0 if mega else 1.5) * (0.5 if e.stagger_max > 0.0 else 1.0))
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.6)
		tw.tween_callback(queue_free)

# Микрофон висит на враге и фонит: волны звука, пока враг заглушён
class MicHang extends Node2D:
	var life := 3.0
	var col := Color(0.30, 0.90, 1.0)
	var _t := 0.0
	var _ring := 0.0

	func _ready() -> void:
		z_index = 6
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([Vector2(-2, -8), Vector2(2, -8), Vector2(3, 3), Vector2(-3, 3)])
		body.color = Color(0.12, 0.12, 0.15)
		add_child(body)
		var head := Polygon2D.new()
		head.polygon = Util.circle(4.5, 10)
		head.position = Vector2(0, 6)
		head.color = Color(0.72, 0.74, 0.80)
		add_child(head)

	func _physics_process(delta: float) -> void:
		_t += delta
		rotation = sin(_t * 9.0) * 0.4
		_ring -= delta
		if _ring <= 0.0:
			_ring = 0.35
			var w := Line2D.new()
			var pts := PackedVector2Array()
			for k in 9:
				var a := -0.9 + k * 0.225
				pts.append(Vector2.from_angle(a) * 10.0)
			w.points = pts
			w.width = 2.0
			w.default_color = Color(col, 0.9)
			w.position = Vector2(4, 6)
			add_child(w)
			var tw := w.create_tween().set_parallel(true)
			tw.tween_property(w, "scale", Vector2(2.6, 2.6), 0.5)
			tw.tween_property(w, "modulate:a", 0.0, 0.5)
			tw.chain().tween_callback(w.queue_free)
		if _t >= life:
			queue_free()

# =====================================================================
# Сцена «Рейв-пати»: пульт, прожекторы, бит. Отсчёт идёт по битам трека (150 уд/мин).
class RaveStage extends Node2D:
	var owner_p: Player
	var kit: DjKit
	var mega := false
	var facing := 1
	var party_beats := 12
	var done := false
	var beat_i := 0
	var _t := 0.0
	var _next := 0.0
	var _phase := "build"
	var _tapped := -1
	var _beams: Array = []
	var _console: Node2D
	var _guards: Array = []
	var _lights: Array = []

	const BUILD_BEATS := 4

	func _ready() -> void:
		z_index = 4
		_make_console()
		for k in 3:
			var b := Polygon2D.new()
			b.color = Color([DjKit.PINK, DjKit.NEON, Color(1.0, 0.92, 0.3)][k], 0.0)
			b.z_index = -1
			b.set_meta("k", k)
			add_child(b)
			_beams.append(b)
		if mega:
			for s in [-1, 1]:
				var g := Guard.new()
				g.owner_p = owner_p
				g.side = s
				g.position = Vector2(s * 92.0, 0)
				add_child(g)
				_guards.append(g)
		_next = DjKit.BEAT
		Fx.ring(get_parent(), global_position + Vector2(0, -20), 120.0, Color(Skins.col(owner_p, DjKit.PINK), 0.8), 0.4, 5.0, 0.35)

	# пульт перед диджеем: стол, две вертушки, фейдеры, огоньки-эквалайзер
	func _make_console() -> void:
		_console = Node2D.new()
		_console.position = Vector2(facing * 30.0, 0)
		add_child(_console)
		var legs := Polygon2D.new()
		legs.polygon = PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(30, -16), Vector2(-30, -16)])
		legs.color = Color(0.08, 0.08, 0.10)
		_console.add_child(legs)
		var desk := Polygon2D.new()
		desk.polygon = PackedVector2Array([Vector2(-40, -16), Vector2(40, -16), Vector2(36, -26), Vector2(-36, -26)])
		desk.color = Color(0.16, 0.16, 0.20)
		_console.add_child(desk)
		var rim := Line2D.new()
		rim.points = PackedVector2Array([Vector2(-40, -16), Vector2(40, -16)])
		rim.width = 2.0
		rim.default_color = Skins.col(owner_p, DjKit.NEON)
		_console.add_child(rim)
		for x in [-22.0, 22.0]:
			var deck := Polygon2D.new()
			deck.polygon = Util.circle(11.0, 16)
			deck.scale = Vector2(1.0, 0.35)
			deck.position = Vector2(x, -27)
			deck.color = Color(0.05, 0.05, 0.06)
			deck.name = "Deck"
			_console.add_child(deck)
			var lab := Polygon2D.new()
			lab.polygon = Util.circle(3.0, 8)
			lab.scale = Vector2(1.0, 0.35)
			lab.position = Vector2(x, -27)
			lab.color = Skins.col(owner_p, DjKit.PINK)
			_console.add_child(lab)
		for k in 8:                                       # эквалайзер на передней панели
			var bar := Polygon2D.new()
			bar.polygon = PackedVector2Array([Vector2(0, 0), Vector2(5, 0), Vector2(5, -1), Vector2(0, -1)])
			bar.position = Vector2(-26 + k * 7, -4)
			bar.color = Color(DjKit.GENRE[DjKit.GENRES[k % 4]]["color"])
			_console.add_child(bar)
			_lights.append(bar)

	func beat_phase() -> float:
		return clampf(1.0 - _next / DjKit.BEAT, 0.0, 1.0)

	func _physics_process(delta: float) -> void:
		if done:
			return
		if not is_instance_valid(owner_p) or not owner_p.is_alive():
			finish()
			return
		_t += delta
		_next -= delta
		_anim_lights()
		_block_shots()
		if _phase == "party":
			_spot_effects()
		if _next <= 0.0:
			_next += DjKit.BEAT
			beat_i += 1
			_on_beat()

	func _on_beat() -> void:
		var world := get_parent()
		if _phase == "build":
			Fx.ring(world, global_position + Vector2(0, -30), 40.0 + beat_i * 22.0, Color(Skins.col(owner_p, DjKit.NEON), 0.5), 0.25, 3.0, 0.4)
			if beat_i >= BUILD_BEATS:
				_drop()
			return
		if _phase == "party":
			var k := beat_i - BUILD_BEATS                   # бит вечеринки
			if k <= party_beats - 1:
				_spawn_notes(3 if k % 4 == 0 else 2)
			elif k == party_beats:
				_final_chord()
				_phase = "final"
			return
		if _phase == "final" and beat_i - BUILD_BEATS >= party_beats + 3:
			finish()

	# ДРОП: вспышка, басовая волна от пульта отбрасывает и ранит
	func _drop() -> void:
		_phase = "party"
		_spawn_notes(2)                                   # первые ноты упадут уже на следующий бит
		var world := get_parent()
		var at := global_position + Vector2(0, -30)
		Util.flash(world, at, 260.0, Color(1.0, 1.0, 1.0, 0.55))
		Fx.ring(world, at, 280.0, Color(Skins.col(owner_p, DjKit.PINK), 0.95), 0.45, 10.0, 0.4)
		Fx.ring(world, at, 200.0, Color(Skins.col(owner_p, DjKit.NEON), 0.9), 0.35, 6.0, 0.4)
		Fx.shake(world, 9.0)
		Audio.sfx("drop", at)
		Fx.shockwave(world, at, 300.0, Skins.col(owner_p, DjKit.PINK), 0.4)
		for j in 5:
			Fx.confetti(world, at + Vector2(randf_range(-500, 500), -randf_range(100, 300)), 14, [], 420.0)
		var l := Label.new()
		l.text = "ДРОП!"
		l.add_theme_font_size_override("font_size", 48)
		l.add_theme_color_override("font_color", Skins.col(owner_p, DjKit.PINK))
		l.add_theme_constant_override("outline_size", 9)
		l.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.10))
		l.position = at + Vector2(-72, -150)
		l.z_index = 10
		world.add_child(l)
		var tw := l.create_tween()
		tw.tween_property(l, "scale", Vector2(1.15, 1.15), 0.1)
		tw.tween_property(l, "scale", Vector2.ONE, 0.15)
		tw.tween_interval(0.5)
		tw.tween_property(l, "modulate:a", 0.0, 0.4)
		tw.tween_callback(l.queue_free)
		for e in kit._enemies():
			var to: Vector2 = e.hurt_center() - at
			if to.length() < 280.0 + e.body_size.x * 0.4:
				e.take_damage(10, owner_p)
				if e.stagger_max <= 0.0 and e.is_alive():
					e.velocity = to.normalized() * 560.0 + Vector2(0, -320)

	# ноты падают в такт: одна — на врага (там, где он стоит сейчас), остальные — вокруг
	func _spawn_notes(n: int) -> void:
		var es: Array = kit._enemies().filter(func(e): return e.global_position.distance_to(global_position) < 1000.0 and not e.cutscene_shield)
		es.shuffle()
		var arena := Balance.arena(owner_p)
		for j in n:
			var x := global_position.x + randf_range(-640.0, 640.0)
			var y0 := global_position.y
			# одна нота — всегда во врага; остальные — тоже во врагов, а на Арене по толпе и боссу все
			if not es.is_empty() and (j == 0 or arena or (j < es.size() and randf() < 0.6)):
				var e: Player = es[j % es.size()]
				var spread := 26.0 if j < es.size() else e.body_size.x * 0.5 + 30.0
				x = e.global_position.x + randf_range(-spread, spread)
				y0 = e.global_position.y + e.body_size.y / 2
			var g: String = DjKit.GENRES[randi() % 4]
			_note(x, y0, g, 12 if arena else 9, 72.0, false)

	func _note(x: float, near_y: float, g: String, dmg: int, r: float, big: bool) -> void:
		var space := get_world_2d().direct_space_state
		var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, near_y - 40.0), Vector2(x, near_y + 520.0), Layer.WORLD))
		var ground: Vector2 = Vector2(x, near_y) if hit.is_empty() else hit["position"]
		var nt := Note.new()
		nt.kit = kit
		nt.owner_p = owner_p
		nt.genre = g
		nt.dmg = dmg
		nt.radius = r
		nt.big = big
		nt.fall = DjKit.BEAT * (2.0 if big else 1.0)
		nt.ground = ground
		get_parent().add_child(nt)

	# игрок жмёт атаку во время ульты — «скретч»: лишняя нота на ближайшего врага (раз в бит)
	func player_tap() -> void:
		if _phase != "party" or _tapped == beat_i:
			return
		_tapped = beat_i
		var e: Player = kit._nearest_enemy(1000.0)
		if e == null:
			return
		var on_beat := beat_phase() < 0.25 or beat_phase() > 0.8
		if on_beat:
			owner_p._float_label("В ТАКТ!", Skins.col(owner_p, DjKit.NEON))
		_note(e.global_position.x, e.global_position.y + e.body_size.y / 2, DjKit.GENRES[randi() % 4], 12 if on_beat else 8, 72.0, false)
		Audio.sfx("scratch", owner_p.global_position, -8.0)

	# финальный аккорд: огромная пластинка на самого сильного врага
	func _final_chord() -> void:
		var best: Player = null
		for e in kit._enemies():
			if e.global_position.distance_to(global_position) < 1100.0 and not e.cutscene_shield:
				if best == null or e.hp > best.hp:
					best = e
		var x := global_position.x + facing * 260.0
		var y := global_position.y
		if best:
			x = best.global_position.x
			y = best.global_position.y + best.body_size.y / 2
		_note(x, y, "pop", 28, 130.0, true)

	# прожекторы: три луча шарят по сцене
	func _spot_effects() -> void:
		var cam_top := global_position.y - 560.0
		for b in _beams:
			var k: int = b.get_meta("k")
			var src := Vector2(global_position.x + (k - 1) * 380.0, cam_top)
			var sweep := sin(_t * (1.1 + k * 0.35) + k * 2.1) * 0.55
			var dir := Vector2(sin(sweep), cos(sweep))
			var tip := src + dir * 640.0
			var side := Vector2(-dir.y, dir.x) * 70.0
			(b as Polygon2D).polygon = PackedVector2Array([to_local(src), to_local(tip + side), to_local(tip - side)])
			(b as Polygon2D).color.a = 0.22
			for n in get_parent().get_children():
				if n is Player and n.is_alive() and _in_beam(n.hurt_center(), src, dir):
					if n.team != owner_p.team:
						n.mark_t = maxf(n.mark_t, 0.25)
						n.mark_mult = maxf(n.mark_mult if n.mark_t > 0.26 else 1.0, 1.2)   # «звезда шоу»
					else:
						n.buffs["speed"] = {"t": 0.4, "mega": false}

	func _in_beam(pt: Vector2, src: Vector2, dir: Vector2) -> bool:
		var v := pt - src
		var along := v.dot(dir)
		if along < 0.0 or along > 660.0:
			return false
		var across := absf(v.dot(Vector2(-dir.y, dir.x)))
		return across < 70.0 * along / 640.0 + 10.0

	func _anim_lights() -> void:
		var ph := beat_phase()
		for i in _lights.size():
			var hgt := 2.0 + 9.0 * absf(sin((beat_i + ph) * 1.7 + i * 0.9)) * (1.0 - ph * 0.5)
			(_lights[i] as Polygon2D).polygon = PackedVector2Array([Vector2(0, 0), Vector2(5, 0), Vector2(5, -hgt), Vector2(0, -hgt)])
		if _phase == "build":
			for b in _beams:
				(b as Polygon2D).color.a = 0.0

	# пульт закрывает диджея от выстрелов спереди
	func _block_shots() -> void:
		var c := _console.global_position + Vector2(facing * 30.0, -30)
		for n in get_parent().get_children():
			if n is Bullet and n.team != owner_p.team and not n.is_queued_for_deletion():
				var d: Vector2 = n.global_position - c
				if absf(d.x) < 22.0 and d.y > -60.0 and d.y < 34.0:
					n.queue_free()
					Fx.sparks(get_parent(), n.global_position, Skins.col(owner_p, DjKit.NEON), 4, 140.0, 3.0)

	func finish() -> void:
		if done:
			return
		done = true
		Audio.stop_hero_track(0.8)
		for g in _guards:
			if is_instance_valid(g):
				(g as Node2D).set_physics_process(false)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.45)
		tw.tween_callback(queue_free)

# Нота с неба: на земле заранее светится круг её цвета, потом она падает ровно в бит
class Note extends Node2D:
	var kit: DjKit
	var owner_p: Player
	var genre := "pop"
	var dmg := 9
	var radius := 72.0
	var big := false
	var fall := 0.4
	var ground := Vector2.ZERO
	var _t := 0.0
	var _mark: Line2D
	var _body: Node2D

	func _ready() -> void:
		z_index = 6
		var c: Color = DjKit.GENRE[genre]["color"]
		_mark = Line2D.new()
		var pts := PackedVector2Array()
		for k in 25:
			var a := TAU * k / 24.0
			pts.append(Vector2(cos(a) * radius, sin(a) * radius * 0.28))
		_mark.points = pts
		_mark.width = 3.0
		_mark.default_color = Color(c, 0.75)
		_mark.position = ground
		_mark.z_index = -1
		add_child(_mark)
		_body = Node2D.new()
		add_child(_body)
		if big:
			var disc := Polygon2D.new()
			disc.polygon = Util.circle(34.0, 22)
			disc.color = Color(0.07, 0.07, 0.09)
			_body.add_child(disc)
			var lab := Polygon2D.new()
			lab.polygon = Util.circle(12.0, 14)
			lab.color = Skins.col(owner_p, Color(1.0, 0.84, 0.40))
			_body.add_child(lab)
			_body.scale = Vector2(1.0, 0.6)
		else:
			var head := Polygon2D.new()                  # нота ♪: овальная головка, штиль, флажок
			head.polygon = Util.circle(8.0, 12)
			head.scale = Vector2(1.25, 0.9)
			head.rotation = -0.4
			head.color = c
			_body.add_child(head)
			var stem := Polygon2D.new()
			stem.polygon = PackedVector2Array([Vector2(7, -2), Vector2(10, -2), Vector2(10, -30), Vector2(7, -30)])
			stem.color = c
			_body.add_child(stem)
			var flag := Polygon2D.new()
			flag.polygon = PackedVector2Array([Vector2(10, -30), Vector2(20, -20), Vector2(18, -14), Vector2(10, -22)])
			flag.color = c
			_body.add_child(flag)
			var glow := Polygon2D.new()
			glow.polygon = Util.circle(16.0, 12)
			glow.color = Color(c, 0.25)
			glow.z_index = -1
			_body.add_child(glow)
		_body.position = ground + Vector2(0, -620.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		var q := clampf(_t / fall, 0.0, 1.0)
		_body.position = ground + Vector2(0, -620.0 * (1.0 - q * q))
		_mark.width = 3.0 + q * 3.0
		if big:
			_body.rotation += delta * 8.0
		if _t >= fall:
			_land()

	func _land() -> void:
		set_physics_process(false)
		if not is_instance_valid(owner_p) or kit == null or not is_instance_valid(kit):
			queue_free()
			return
		var world := get_parent()
		var c: Color = DjKit.GENRE[genre]["color"] if not big else Skins.col(owner_p, Color(1.0, 0.84, 0.40))
		Fx.ring(world, ground, radius, Color(c, 0.95), 0.3, 6.0 if big else 4.0, 0.3)
		Fx.star(world, ground + Vector2(0, -24), 34.0 if not big else 80.0, c.lightened(0.4), 0.3)
		if big:
			Fx.shockwave(world, ground, radius * 1.4, c, 0.3)
			Fx.confetti(world, ground + Vector2(0, -30), 30, [], 640.0)
			Fx.dust(world, ground, 8, Color(0.6, 0.55, 0.5), 150.0, 22.0)
		Fx.sparks(world, ground, c, 12 if big else 5, 260.0 if big else 170.0, 4.0, true)
		if big:
			Util.flash(world, ground + Vector2(0, -30), radius, Color(1.0, 0.95, 0.8, 0.8))
			Fx.shake(world, 10.0)
			Audio.sfx("drop", ground)
		for e in kit._enemies():
			var d: Vector2 = e.global_position + Vector2(0, e.body_size.y / 2) - ground
			if absf(d.x) < radius + e.body_size.x * 0.35 and d.y > -90.0 - e.body_size.y * 0.5 and d.y < 40.0:
				e.take_damage(dmg, owner_p)
				if big and e.is_alive() and e.stagger_max <= 0.0:
					e.velocity = Vector2(signf(d.x if d.x != 0.0 else 1.0) * 600.0, -420.0)
				kit.genre_hit(e, genre, dmg, 1.4 if big else 1.0)
		queue_free()

# Охранник (МЕГА): в чёрной форме с надписью «ОХРАНА», бьёт дубинкой всех, кто подходит к диджею
class Guard extends Node2D:
	var owner_p: Player
	var side := 1
	var _cd := 0.3
	var _arm: Node2D
	var _swing := 0.0

	func _ready() -> void:
		z_index = 5
		scale = Vector2(float(side), 1.0)
		var legs := Polygon2D.new()
		legs.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(8, -26), Vector2(-8, -26)])
		legs.color = Color(0.06, 0.06, 0.08)
		add_child(legs)
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([Vector2(-12, -26), Vector2(12, -26), Vector2(11, -58), Vector2(-11, -58)])
		body.color = Color(0.09, 0.09, 0.11)
		add_child(body)
		var head := Polygon2D.new()
		head.polygon = Util.circle(8.0, 12)
		head.position = Vector2(0, -67)
		head.color = Color(0.85, 0.68, 0.56)
		add_child(head)
		var cap := Polygon2D.new()
		cap.polygon = PackedVector2Array([Vector2(-9, -70), Vector2(9, -70), Vector2(12, -73), Vector2(8, -77), Vector2(-8, -77)])
		cap.color = Color(0.05, 0.05, 0.06)
		add_child(cap)
		var shades := Polygon2D.new()
		shades.polygon = PackedVector2Array([Vector2(-1, -69), Vector2(8, -69), Vector2(8, -66), Vector2(-1, -66)])
		shades.color = Color(0.02, 0.02, 0.03)
		add_child(shades)
		var tag := Label.new()
		tag.text = "ОХРАНА"
		tag.add_theme_font_size_override("font_size", 7)
		tag.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		tag.position = Vector2(-12, -52)
		add_child(tag)
		_arm = Node2D.new()
		_arm.position = Vector2(8, -54)
		add_child(_arm)
		var arm := Polygon2D.new()
		arm.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(3, 20), Vector2(-3, 20)])
		arm.color = Color(0.09, 0.09, 0.11)
		_arm.add_child(arm)
		var baton := Polygon2D.new()
		baton.polygon = PackedVector2Array([Vector2(-2, 16), Vector2(2, 16), Vector2(2, 42), Vector2(-2, 42)])
		baton.color = Color(0.15, 0.15, 0.17)
		_arm.add_child(baton)
		_arm.rotation = -0.5
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.2)

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(owner_p):
			return
		_cd -= delta
		if _swing > 0.0:
			_swing -= delta
			_arm.rotation = lerpf(-2.4, 0.9, 1.0 - _swing / 0.18)
		else:
			_arm.rotation = move_toward(_arm.rotation, -0.5, delta * 6.0)
		_soak()
		if _cd > 0.0:
			return
		var hit := false
		for e in owner_p.kit._enemies():
			var d: Vector2 = e.hurt_center() - global_position
			if d.x * side > -20.0 and absf(d.x) < 110.0 + e.body_size.x / 2 and absf(d.y + 40.0) < 70.0 + e.body_size.y / 2:
				hit = true
				e.take_damage(10, owner_p)
				if e.is_alive() and e.stagger_max <= 0.0:
					e.velocity = Vector2(side * 560.0, -260.0)
					e.stun(0.35)
				Fx.sparks(get_parent(), e.hurt_center(), Color(1.0, 0.95, 0.7), 5, 180.0, 3.0)
		if hit:
			_cd = 0.55
			_swing = 0.18
			Audio.sfx("baton", global_position)
		else:
			_cd = 0.1

	# охранник ловит телом выстрелы, летящие в диджея
	func _soak() -> void:
		for n in get_parent().get_parent().get_children():
			if n is Bullet and n.team != owner_p.team and not n.is_queued_for_deletion():
				var d: Vector2 = n.global_position - global_position
				if absf(d.x) < 14.0 and d.y < 0.0 and d.y > -80.0:
					n.queue_free()
