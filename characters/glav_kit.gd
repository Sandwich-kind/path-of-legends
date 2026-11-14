class_name GlavKit
extends HeroKit
# ---------- ГЛАВНЫЙ — легенда из Лавки (персонаж друга автора игры) ----------
# Чёрное пальто со светящимся фиолетовым контуром, белая футболка, джинсы, модные
# кроссовки и пиксельные тёмные очки.
# Оружие «Газировка»: зажми — Главный взбалтывает бутылку, отпусти — бьёт луч газировки.
#   Чем дольше тряс, тем дольше луч. После луча пустая бутылка летит прочь, в руке —
#   следующая. Бутылки по кругу:
#     Жидкий азот  — понемногу замедляет, пока враг не застынет;
#     Кола         — где луч бьёт в цель или в пол, разливается липкая лужа;
#     Энергетик    — прошивает до трёх врагов и бьёт сильнее;
#     Монтажная пена — там, куда бьёт луч, вырастают временные блоки;
#     Имбирный лимонад — жжётся, поджигает;
#     Шипучка «Мега-пузырь» — пузыри отталкивают врагов.
# 1 «Лови сэндвич!» — сэндвич по дуге. Попал — врагу «Ох, что-то мне не хорошо»: он
#   чуть медленнее, а луч газировки по нему усилен — больше урона и постоянные
#   взрывы вокруг, у каждой бутылки свои (ледяной, фонтан колы, цепная молния,
#   пена схватывает, огненный, пузырь-хлопушка). МЕГА: три сэндвича веером.
# 2 «Очки за 23914$» — бросает вперёд пиксельные очки. Враг: ослеплён (не стреляет),
#   ранен и становится целью — под ним метка, и дважды (МЕГА — трижды) с неба бьёт луч
#   (за 0,5 с до удара метка замирает). Союзник (и призванный): надевает очки — бегает
#   и стреляет быстрее, не перезаряжается. Мимо — очки лежат на земле, пока их не
#   подберут.
# 3 «Будьте добры, оплатите счёт» — сама не перезаряжается: копит заряды за каждую
#   бутылку и каждую способность, нужно 7. Чек летит вперёд, бьёт только врагов: враг
#   долго смотрит в чек, не понимает, что с ним делать (оглушён), и выбрасывает его.
#   МЕГА: три чека веером.
# Ульта «Сейчас всё поправлю!» — перед Главным голографическая консоль, он стоит и
#   кодит. Каждые полсекунды-секунду что-то случается: случайное лечение, молния,
#   взрывы, здание посреди карты, сброс баффов, телепорт, отключение гравитации,
#   «синий экран», дождь из резиновых уточек, уменьшение врага, ускорение своих
#   (подбрасывание, уменьшение, синий экран, заморозка, спам и поджог задевают и боссов —
#   послабее; лечить «по ошибке» и телепортировать боссов он не может),
#   поджог всех (и своих, но слабо), заморозка всех (свои — на миг), спам — на экране
#   всплывают «уведомления» выдуманных компаний, а враги на них отвлекаются, и звонок:
#   игра встаёт на паузу, на экране входящий вызов. Не трогать 10 с — сбросится;
#   «Отклонить» — абонент пришлёт сообщение; «Ответить» — 5 с из трубки слышна
#   неразборчивая речь, а игра сразу продолжается. Ещё: реклама (пауза, 15 с, через 5 с —
#   «Пропустить»), «Бесконечная сила» своим, «Перерыв на кофе» (все, кроме Главного, замерли),
#   хотфикс босса, лаги у врагов, сборщик мусора (вражеские снаряды исчезают).
#   Звонок и реклама — вместе не чаще раза за ульту, кофе — раз за ульту.
#   МЕГА: событий за раз больше, а в начале срабатывает МЕГА-ульта другой легенды.

const VIO := Color(0.72, 0.42, 1.0)
const BOTTLES := [
	{"id": "nitro", "name": "Жидкий азот", "col": Color(0.72, 0.93, 1.0), "dmg": 0.7},
	{"id": "cola", "name": "Кола", "col": Color(0.45, 0.20, 0.08), "dmg": 0.85},
	{"id": "energy", "name": "Энергетик «Разряд»", "col": Color(0.78, 1.0, 0.25), "dmg": 1.25},
	{"id": "foam", "name": "Монтажная пена", "col": Color(0.98, 0.93, 0.72), "dmg": 0.55},
	{"id": "ginger", "name": "Имбирный лимонад", "col": Color(1.0, 0.58, 0.15), "dmg": 0.8},
	{"id": "fizz", "name": "Шипучка «Мега-пузырь»", "col": Color(0.98, 0.55, 0.85), "dmg": 0.75},
]
const MAX_SHAKE := 1.2
const TICK := 0.1
const RANGE := 640.0
const STACKS := 7

var bottle := 0
var stacks := 0
var _shake := -1.0
var _beam_t := 0.0
var _tick := 0.0
var _beam: Line2D
var _core: Line2D
var _liquid: Polygon2D
var _chill := {}
var _sick := {}              # враг -> [осталось секунд, значок над головой]
var _blind := {}             # враг -> [осталось секунд, очки на лице]
var _boom_t := 0.0
var _spill_t := 0.0
var _foam_t := 0.0
var _foams: Array = []
var _ult_t := 0.0
var _ult_tick := 0.0
var _ult_mega := false
var _console: Node2D
var _cmd: Label
var _guest: Node              # чужая ульта в МЕГА-ульте
var _called := false          # пауза (звонок или реклама) уже была в этой ульте
var _coffee_used := false
var _coffee_t := 0.0          # «Перерыв на кофе»: все, кроме Главного, замерли
var _frozen: Array = []       # [weakref узла, прежний process_mode]
var _cup: Node2D
var _dir := Vector2.ZERO      # куда бьёт луч (на Арене — доводится на ближайшего врага впереди)

# ---------- Оружие: газировка ----------
func weapon(delta: float, shoot: bool) -> void:
	var rapid := p.has_buff("rapid")
	p._reloading = 0.0
	p.ammo = p.clip_size
	_tint_bottle()
	if _beam_t > 0.0:
		_spray(delta)
		return
	if _shake >= 0.0:
		if shoot:
			_shake = minf(_shake + delta * (2.0 if rapid else 1.0), MAX_SHAKE)
			_shaking()
			return
		_release()
		return
	if shoot and p._cooldown_left <= 0.0:
		_shake = 0.0

func _bottle() -> Dictionary:
	return BOTTLES[bottle]

# Жидкость в бутылке в руке — цвета текущей газировки
func _tint_bottle() -> void:
	if not p.rig or not is_instance_valid(p.rig):
		return
	var w: Variant = p.rig.get("_weapon")
	if not (w is Sprite2D):
		return
	if _liquid == null or not is_instance_valid(_liquid) or _liquid.get_parent() != w:
		_liquid = Polygon2D.new()
		_liquid.polygon = PackedVector2Array([Vector2(-1, -1.5), Vector2(6, -1.5), Vector2(6, 1.5), Vector2(-1, 1.5)])
		(w as Sprite2D).add_child(_liquid)
	_liquid.color = Color(Skins.col(p, _bottle()["col"]), 0.9)

func _shaking() -> void:
	var k := _shake / MAX_SHAKE
	_bar(k)
	if p.rig:
		p.rig.hold = "draw"
		var w: Variant = p.rig.get("_weapon")
		if w is Sprite2D:
			(w as Sprite2D).position.y = float(p.rig.spec["arm"][1] - 2) + sin(_shake * 60.0) * 1.2
	if randf() < 0.35 + k * 0.5:
		var m: Vector2 = p.rig.muzzle() if p.rig else p.global_position
		Fx.sparks(p.get_parent(), m, Skins.col(p, _bottle()["col"]).lightened(0.3), 1, 80.0 + k * 120.0, 2.5, true)

func _bar(k: float) -> void:
	p._charge_fill.visible = k >= 0.0
	p._charge_bg.visible = k >= 0.0
	if k >= 0.0:
		p._charge_fill.size.x = p._bar_w * k
		p._charge_fill.color = Skins.col(p, _bottle()["col"])

func _release() -> void:
	var k := clampf(_shake / MAX_SHAKE, 0.15, 1.0)
	_shake = -1.0
	_bar(-1.0)
	if p.rig:
		p.rig.hold = ""
		var w: Variant = p.rig.get("_weapon")
		if w is Sprite2D:
			(w as Sprite2D).position.y = float(p.rig.spec["arm"][1] - 2)
	_beam_t = 0.3 + 1.7 * k
	_tick = 0.0
	_dir = Vector2.ZERO
	_add_stack()
	var world := p.get_parent()
	var c: Color = Skins.col(p, _bottle()["col"])
	_beam = Line2D.new()
	_beam.width = 9.0
	_beam.default_color = Color(c, 0.85)
	_beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_beam.end_cap_mode = Line2D.LINE_CAP_ROUND
	_beam.z_index = 5
	world.add_child(_beam)
	_core = Line2D.new()
	_core.width = 3.0
	_core.default_color = Color(1, 1, 1, 0.85)
	_core.z_index = 6
	world.add_child(_core)
	Fx.sparks(world, p.rig.muzzle() if p.rig else p.global_position, c, 8, 220.0, 3.0)

func _spray(delta: float) -> void:
	_beam_t -= delta
	var b: Dictionary = _bottle()
	var c: Color = Skins.col(p, b["col"])
	var from: Vector2 = p.rig.muzzle() if p.rig else p.global_position + Vector2(p.facing * 20.0, -8)
	var dir := _aim(from)
	var to := from + dir * _range()
	var hit := _ray(from, to)
	var wall := not hit.is_empty()
	if wall:
		to = hit["position"]
	# кто на пути луча
	var on: Array = []
	var seg := to - from
	var ln := maxf(1.0, seg.length())
	for e in _enemies():
		if e.cutscene_shield:
			continue
		var ec: Vector2 = e.hurt_center() - from
		var along: float = ec.dot(dir)
		var off: float = absf(ec.cross(dir))
		if along > -e.body_size.x / 2 and along < ln + e.body_size.x / 2 and off < e.body_size.y / 2 + 8.0:
			on.append(e)
	on.sort_custom(func(a, bb): return (a.hurt_center() - from).dot(dir) < (bb.hurt_center() - from).dot(dir))
	var pierce := 3 if b["id"] == "energy" else 1
	on = on.slice(0, pierce)
	if not on.is_empty() and pierce == 1:
		to = from + dir * maxf(0.0, (on[0].hurt_center() - from).dot(dir) - on[0].body_size.x * 0.3)
		wall = false
	_beam.points = PackedVector2Array([from, to])
	_core.points = PackedVector2Array([from, to])
	_beam.width = 8.0 + sin(_beam_t * 40.0) * 2.0
	if randf() < 0.6:
		Fx.sparks(p.get_parent(), to, c.lightened(0.2), 2, 160.0, 3.0)
	p._anim("shoot")
	_tick -= delta
	_boom_t -= delta
	_spill_t -= delta
	_foam_t -= delta
	if _tick <= 0.0:
		_tick = TICK * (0.6 if p.has_buff("rapid") else 1.0)
		for e in on:
			_hit(e, b)
		# пол и стены: кола разливается, пена застывает блоками
		if on.is_empty():
			if b["id"] == "cola" and _spill_t <= 0.0:
				_spill_t = 0.5
				_puddle(to, 110.0, 3.0)
			if b["id"] == "foam" and _foam_t <= 0.0:
				_foam_t = 0.45
				_foam_block(to - dir * 22.0)
	if _beam_t <= 0.0:
		_end_beam(true)

# Длина луча: на Арене — длиннее (там просторнее, а враги держат дистанцию)
func _range() -> float:
	return RANGE * (1.3 if Balance.arena(p) else 1.0)

# Луч упирается в стены, а сквозные платформы на Арене пробивает (как пули)
func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(from, to, Layer.WORLD | Layer.FRAME)
	var ex: Array[RID] = []
	for k in 5:
		q.exclude = ex
		var hit := p.get_world_2d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or not (Balance.arena(p) and Util.is_one_way(hit["collider"])):
			return hit
		ex.append(hit["rid"])
	return {}

# Направление луча: в Дуэли — строго вперёд; на Арене луч сам доводится на ближайшего
# врага впереди (в пределах ±35°), как пули других легенд
func _aim(from: Vector2) -> Vector2:
	var want := Vector2(p.facing, 0)
	if Balance.arena(p) and not p.is_bot:
		var bd := _range() + 80.0
		for e in _enemies():
			if e.cutscene_shield:
				continue
			var d: Vector2 = e.hurt_center() - from
			if d.x * p.facing <= 8.0 or absf(atan2(d.y, absf(d.x))) > 0.6 or d.length() > bd:
				continue
			bd = d.length()
			want = d.normalized()
	if _dir == Vector2.ZERO or signf(_dir.x) != signf(want.x):
		_dir = want
	else:
		_dir = _dir.lerp(want, 0.35).normalized()           # луч ведёт плавно, не дёргается
	return _dir

func _hit(e: Player, b: Dictionary) -> void:
	var id: String = b["id"]
	var sick := _sick.has(e)
	var dmg := int(round(p.bullet_damage * float(b["dmg"]) * (1.6 if sick else 1.0)))
	e.take_damage(maxi(1, dmg), p)
	var boss := e.stagger_max > 0.0
	match id:
		"nitro":
			var ch: float = float(_chill.get(e, 0.0)) + (0.15 if sick else 0.075)
			e.slow(0.4, maxf(0.25, 1.0 - ch * 0.75), "water")
			e.set_tint(Color(0.75, 0.92, 1.25).lerp(Color.WHITE, 1.0 - minf(ch, 1.0)))
			if ch >= 1.0:
				ch = 0.0
				e.stun(0.5 if boss else 1.3)                    # застыл
				e.set_tint(Color(0.7, 0.9, 1.4))
				Fx.sparks(p.get_parent(), e.hurt_center(), Color(0.85, 0.95, 1.0), 12, 220.0, 3.5)
				e._float_label("Застыл!", Color(0.75, 0.92, 1.0))
				var we: WeakRef = weakref(e)
				_after(1.3, func():
					var o: Variant = we.get_ref()
					if o:
						o.set_tint(Color.WHITE))
			_chill[e] = ch
		"cola":
			if _spill_t <= 0.0:
				_spill_t = 0.5
				_puddle(e.global_position + Vector2(0, e.body_size.y / 2), 110.0, 3.0)
		"foam":
			if _foam_t <= 0.0:
				_foam_t = 0.6
				_foam_block(e.global_position + Vector2(-p.facing * (e.body_size.x / 2 + 24.0), 0))
		"ginger":
			e.burn(2.0, 5.0, p)
		"fizz":
			if not boss:
				e.velocity.x = clampf(e.velocity.x + p.facing * 140.0, -520.0, 520.0)
			Fx.ring(p.get_parent(), e.hurt_center() + Vector2(randf_range(-14, 14), randf_range(-14, 14)), 10.0, Color(1, 0.8, 0.95, 0.8), 0.25, 2.0)
	if sick and _boom_t <= 0.0:
		_boom_t = 0.3
		_sick_boom(e, b)

# Усиленный луч по тому, кому плохо: постоянные взрывы, у каждой бутылки свои
func _sick_boom(e: Player, b: Dictionary) -> void:
	var world := p.get_parent()
	var at := e.hurt_center()
	var c: Color = Skins.col(p, b["col"])
	Fx.ring(world, at, 90.0, Color(c, 0.9), 0.3, 6.0)
	Fx.sparks(world, at, c, 10, 240.0, 4.0)
	var near: Array = _enemies().filter(func(o): return o.global_position.distance_to(at) < 90.0 + o.body_size.x * 0.4)
	for o in near:
		o.take_damage(6, p)
	match b["id"]:
		"nitro":
			for o in near:
				_chill[o] = float(_chill.get(o, 0.0)) + 0.25
		"cola":
			_puddle(e.global_position + Vector2(0, e.body_size.y / 2), 200.0, 3.5)
			for o in near:
				if o.stagger_max <= 0.0:
					o.velocity.y = minf(o.velocity.y, -260.0)
		"energy":
			var others: Array = _enemies().filter(func(o): return o != e and o.global_position.distance_to(at) < 280.0)
			for o in others.slice(0, 2):
				Fx.bolt(world, at, o.hurt_center(), c)
				o.take_damage(8, p)
		"foam":
			for o in near:
				o.root(0.6)
		"ginger":
			Util.flash(world, at, 70.0, Color(1.0, 0.55, 0.15, 0.8))
			for o in near:
				o.burn(2.5, 7.0, p)
		"fizz":
			for o in near:
				if o.stagger_max <= 0.0:
					o.velocity = (o.global_position - at).normalized() * 520.0 + Vector2(0, -260)

func _end_beam(next: bool) -> void:
	_beam_t = 0.0
	for l in [_beam, _core]:
		if l and is_instance_valid(l):
			var t: Variant = l.create_tween()
			t.tween_property(l, "modulate:a", 0.0, 0.12)
			t.tween_callback(l.queue_free)
	_beam = null
	_core = null
	if not next:
		return
	_toss_bottle()
	bottle = (bottle + 1) % BOTTLES.size()
	p._cooldown_left = 0.15 if p.has_buff("rapid") else 0.35
	p._float_label(_bottle()["name"], Skins.col(p, _bottle()["col"]).lightened(0.2))

# Пустая бутылка летит за спину, кувыркаясь
func _toss_bottle() -> void:
	var world := p.get_parent()
	var bt := Polygon2D.new()
	bt.polygon = PackedVector2Array([Vector2(-7, -3), Vector2(4, -3), Vector2(6, -2), Vector2(9, -2), Vector2(9, 2), Vector2(6, 2), Vector2(4, 3), Vector2(-7, 3)])
	bt.color = Color(0.80, 0.90, 0.95, 0.85)
	bt.position = p.rig.muzzle() if p.rig else p.global_position
	bt.z_index = 4
	world.add_child(bt)
	var t := bt.create_tween().set_parallel(true)
	t.tween_property(bt, "position", bt.position + Vector2(-p.facing * 140.0, 90.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(bt, "rotation", -p.facing * TAU * 1.5, 0.6)
	t.chain().tween_property(bt, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(bt.queue_free)

func _puddle(at: Vector2, width: float, life: float) -> void:
	var gh := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(at + Vector2(0, -20), at + Vector2(0, 600), Layer.WORLD | Layer.FRAME))
	var pud := SwampBits.MudPuddle.new()
	pud.width = width
	pud.life = life
	pud.team = p.team
	pud.position = gh["position"] if not gh.is_empty() else at
	pud.modulate = Color(1.5, 0.6, 0.4)                    # липкая кола
	p.get_parent().call_deferred("add_child", pud)

# Монтажная пена: застывает блоком 2×2 на земле
func _foam_block(at: Vector2) -> void:
	_foams = _foams.filter(func(f): return is_instance_valid(f))
	if _foams.size() >= 6:
		return
	var gh := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(at + Vector2(0, -30), at + Vector2(0, 600), Layer.WORLD | Layer.FRAME))
	if gh.is_empty():
		return
	var ground: Vector2 = gh["position"]
	var d := Maps.make_destructible(Rect2(ground.x - 20.0, ground.y - 40.0, 40.0, 40.0), 20.0, Skins.col(p, Color(0.98, 0.93, 0.72)), 30, 15.0)
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	d.lifetime = 5.0
	p.get_parent().add_child(d)
	_foams.append(d)
	Fx.sparks(p.get_parent(), ground + Vector2(0, -20), Color(1.0, 0.97, 0.85), 8, 160.0, 4.0, true)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	if ab == "receipt":
		p._cd[i] = float(STACKS - stacks)          # на кнопке — сколько зарядов осталось набрать
		if Input.is_action_just_pressed(action) and stacks >= STACKS:
			use(ab)
		return
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"sandwich":
			p._anim("throw")
			for k in (3 if mega else 1):
				var s := Sandwich.new()
				s.owner_p = p
				s.vel = Vector2(p.facing * 640.0, -420.0).rotated(p.facing * (k - (1 if mega else 0)) * 0.2)
				s.position = p.global_position + Vector2(p.facing * 20.0, -24.0)
				p.get_parent().add_child(s)
			_add_stack()
		"shades":
			p._anim("throw")
			var sh := Shades.new()
			sh.owner_p = p
			sh.mega = mega
			sh.dir = p.facing
			sh.position = p.global_position + Vector2(p.facing * 22.0, -18.0)
			p.get_parent().add_child(sh)
			_add_stack()
		"receipt":
			if stacks < STACKS:
				return
			stacks = 0
			p._anim("throw")
			for k in (3 if mega else 1):
				var r := Receipt.new()
				r.owner_p = p
				r.dir = Vector2(p.facing, 0).rotated(p.facing * (k - (1 if mega else 0)) * 0.18)
				r.position = p.global_position + Vector2(p.facing * 22.0, -12.0)
				p.get_parent().add_child(r)

func _add_stack() -> void:
	var was := stacks
	stacks = mini(STACKS, stacks + 1)
	if stacks == STACKS and was < STACKS:
		p._float_label("Счёт готов!", Color(0.95, 0.95, 0.85))

# Сэндвич попал: «Ох, что-то мне не хорошо»
func make_sick(e: Player) -> void:
	var dur := 8.0 if Balance.arena(p) else 6.0
	if _sick.has(e) and is_instance_valid(_sick[e][1]):
		_sick[e][0] = dur
		return
	var icon := Node2D.new()
	icon.position = Vector2(0, -e.body_size.y / 2 - 30)
	for k in 3:
		var bub := Polygon2D.new()
		bub.polygon = Util.circle(4.0 - k, 8)
		bub.color = Color(0.55, 0.85, 0.30, 0.85)
		bub.position = Vector2(-8 + k * 8, -k * 3)
		icon.add_child(bub)
	e.add_child(icon)
	_sick[e] = [dur, icon]
	e._float_label("Ох, что-то мне не хорошо…", Color(0.60, 0.90, 0.35))

# Очки попали во врага: ослеплён и под прицелом
func blind(e: Player, mega: bool) -> void:
	var dur := 2.5
	var g := Shades.glasses(1.1)
	g.position = Vector2(e.body_size.x * 0.12 * e.facing, -e.body_size.y * 0.32)
	e.add_child(g)
	if _blind.has(e) and is_instance_valid(_blind[e][1]):
		_blind[e][1].queue_free()
	_blind[e] = [dur, g]
	e.take_damage(12, p)
	e._float_label("Ничего не вижу!", Color(0.9, 0.9, 0.95))
	var m := SkyMark.new()
	m.owner_p = p
	m.target = e
	m.strikes = 3 if mega else 2
	p.get_parent().add_child(m)

# Очки достались своему: модный — быстрее бегает и стреляет, без перезарядки
static func cool(a: Player) -> void:
	for t in ["speed", "rapid"]:
		a.buffs[t] = {"t": 6.0, "mega": false}
	var g := Shades.glasses(1.1)
	g.position = Vector2(a.body_size.x * 0.12, -a.body_size.y * 0.32)
	a.add_child(g)
	var tw := g.create_tween()
	tw.tween_interval(5.6)
	tw.tween_property(g, "modulate:a", 0.0, 0.4)
	tw.tween_callback(g.queue_free)
	a._float_label("Стильно!", Color(0.85, 0.75, 1.0))

func _physics_process(delta: float) -> void:
	if p == null:
		return
	if _coffee_t > 0.0 and _ult_t <= 0.0:
		_coffee_step(delta)                                 # кофе допивается, даже если ульта кончилась
	for e in _sick.keys():
		if not is_instance_valid(e) or not e.is_alive():
			_drop(_sick, e)
			continue
		_sick[e][0] = float(_sick[e][0]) - delta
		e.slow(0.2, 0.85, "water")
		if is_instance_valid(_sick[e][1]):
			(_sick[e][1] as Node2D).rotation = sin(Time.get_ticks_msec() * 0.006) * 0.3
		if float(_sick[e][0]) <= 0.0:
			_drop(_sick, e)
	for e in _blind.keys():
		if not is_instance_valid(e) or not e.is_alive():
			_drop(_blind, e)
			continue
		_blind[e][0] = float(_blind[e][0]) - delta
		e._cooldown_left = maxf(e._cooldown_left, 0.15)       # ослеплён — не стреляет
		if float(_blind[e][0]) <= 0.0:
			_drop(_blind, e)
	for e in _chill.keys():
		if not is_instance_valid(e):
			_chill.erase(e)
		else:
			_chill[e] = maxf(0.0, float(_chill[e]) - delta * 0.15)
	if _ult_t > 0.0:
		_ult_step(delta)

func _drop(d: Dictionary, e) -> void:
	if is_instance_valid(d[e][1]):
		d[e][1].queue_free()
	d.erase(e)

# ---------- Ульта: «Сейчас всё поправлю!» ----------
func ult() -> void:
	var world := p.get_parent()
	var dur := 7.0 if Balance.arena(p) else 6.0
	_ult_t = dur
	_ult_tick = 0.6
	_ult_mega = p._mega_ab()
	_called = false
	_coffee_used = false
	p._forced_time = dur
	p._forced_vx = 0.0
	p._anim("cast")
	p._float_label("Сейчас всё поправлю!", VIO.lightened(0.3))
	_end_beam(false)
	_shake = -1.0
	_bar(-1.0)
	_console = Node2D.new()
	_console.position = p.global_position + Vector2(p.facing * 64.0, -34.0)
	_console.z_index = 7
	var panel := Polygon2D.new()
	panel.polygon = PackedVector2Array([Vector2(-46, -34), Vector2(46, -40), Vector2(46, 30), Vector2(-46, 34)])
	panel.color = Color(0.35, 0.18, 0.60, 0.45)
	_console.add_child(panel)
	var rim := Line2D.new()
	rim.points = PackedVector2Array([Vector2(-46, -34), Vector2(46, -40), Vector2(46, 30), Vector2(-46, 34), Vector2(-46, -34)])
	rim.width = 2.0
	rim.default_color = Color(0.85, 0.65, 1.0, 0.9)
	_console.add_child(rim)
	for k in 6:                                               # строчки кода
		var ln := Line2D.new()
		var y := -24.0 + k * 9.0
		ln.points = PackedVector2Array([Vector2(-38, y), Vector2(-38 + randf_range(20, 70), y)])
		ln.width = 2.0
		ln.default_color = Color(0.70, 1.0, 0.80, 0.8) if k % 2 == 0 else Color(0.95, 0.85, 1.0, 0.8)
		ln.name = "Code%d" % k
		_console.add_child(ln)
	_cmd = Label.new()
	_cmd.position = Vector2(-80, -66)
	_cmd.size = Vector2(160, 20)
	_cmd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cmd.add_theme_font_size_override("font_size", 14)
	_cmd.add_theme_color_override("font_color", Color(0.75, 1.0, 0.80))
	_cmd.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
	_cmd.add_theme_constant_override("outline_size", 4)
	_console.add_child(_cmd)
	world.add_child(_console)
	_console.scale = Vector2(0.1, 1.0)
	_console.create_tween().tween_property(_console, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if _ult_mega:
		_guest_ult()

func ulting() -> bool:
	return _ult_t > 0.0

func _ult_step(delta: float) -> void:
	p._forced_time = maxf(p._forced_time, 0.1)
	p._forced_vx = 0.0
	if _coffee_t > 0.0:
		_coffee_step(delta)                                 # пьёт кофе: консоль ждёт, время ульты стоит
		return
	_ult_t -= delta
	_ult_tick -= delta
	if is_instance_valid(_console):
		for k in 6:
			var ln: Variant = _console.get_node_or_null("Code%d" % k)
			if ln is Line2D and randf() < 0.15:
				var y := -24.0 + k * 9.0
				(ln as Line2D).points = PackedVector2Array([Vector2(-38, y), Vector2(-38 + randf_range(16, 74), y)])
		if randf() < 0.1:
			p._anim("cast")
	if _ult_tick <= 0.0:
		_ult_tick = randf_range(0.5, 0.85)
		var n := 1 if randf() < 0.65 else 2
		if _ult_mega:
			n = 2 if randf() < 0.6 else 3
		var pool := _ult_pool()
		pool.shuffle()
		var names: Array = []
		var stop := false                                   # звонок, реклама или кофе — в пачке последние
		for ev in pool:
			if names.size() >= n:
				break
			if stop and ev in STOPPERS:
				continue
			names.append(ev)
			call("_ev_" + String(ev))
			if ev in STOPPERS:
				stop = true
		if is_instance_valid(_cmd):
			_cmd.text = " ; ".join(names.map(func(x): return CMD[x]))
	if _ult_t <= 0.0:
		_end_ult()

func _end_ult() -> void:
	_ult_t = 0.0
	if is_instance_valid(_console):
		var t := _console.create_tween()
		t.tween_property(_console, "scale", Vector2(0.05, 1.0), 0.2)
		t.tween_callback(_console.queue_free)
	if is_instance_valid(_guest):
		var wg: WeakRef = weakref(_guest)
		_after(6.0, func():
			var g: Variant = wg.get_ref()
			if g:
				g.queue_free())

const EVENTS := ["heal", "zap", "boom", "build", "dispel", "teleport", "gravity", "bsod", "ducks", "shrink", "haste",
		"ignite", "freeze", "spam", "call", "ad", "power", "coffee", "boss_fix", "lag", "gc"]
const STOPPERS := ["call", "ad", "coffee"]          # «останавливают» игру — не больше одного за пачку

# Из каких событий выбирать сейчас: звонок и реклама — редкость, вместе не чаще раза за ульту;
# кофе — раз за ульту; хотфикс босса — только если босс на арене
func _ult_pool() -> Array:
	var pool := EVENTS.duplicate()
	var busy := p.get_tree().paused
	for ev in ["call", "ad"]:
		if _called or busy or randf() < 0.5:
			pool.erase(ev)
	if _coffee_used or busy:
		pool.erase("coffee")
	if _boss() == null:
		pool.erase("boss_fix")
	return pool

func _boss() -> Player:
	for e in _enemies():
		if e.stagger_max > 0.0 and not e.cutscene_shield:
			return e
	return null
const CMD := {"heal": "heal(random)", "zap": "zap(enemy)", "boom": "explode(rand×3)", "build": "spawn(House)",
		"dispel": "buffs.clear()", "teleport": "tp(any, anywhere)", "gravity": "gravity = 0", "bsod": "BSOD :(",
		"ducks": "import ducks", "shrink": "scale = 0.6", "haste": "team.speed++",
		"ignite": "world.fire = true", "freeze": "world.temp = -273", "spam": "notify(everyone)", "call": "phone.ring()",
		"ad": "ads.show(15)", "power": "team.power = 9999", "coffee": "sleep(coffee)", "boss_fix": "hotfix(boss)",
		"lag": "ping = 999", "gc": "gc.collect()"}

# Спам: [приложение, текст, цвет значка]. Все компании выдуманы.
const SPAM := [
	["Пельмень-Банк", "Вам одобрен кредит на 1 000 000 монет! Ставка — всего 99% в день.", Color(0.95, 0.72, 0.18)],
	["Доставка «Сытый гоблин»", "Курьер съел ваш заказ. Оцените поездку!", Color(0.35, 0.70, 0.30)],
	["Магазин «Всё по 99»", "Только сегодня: второй меч в подарок!", Color(0.90, 0.30, 0.30)],
	["Такси «Колёсико»", "Водитель ждёт у портала уже 3 минуты.", Color(1.0, 0.82, 0.20)],
	["Онлайн-школа «Мозг+»", "Стань легендой за 3 дня! Осталось 2 места.", Color(0.45, 0.45, 0.95)],
	["Оператор «Сигнал-Ноль»", "Ваш тариф «Безлимит на 5 минут» продлён.", Color(0.20, 0.70, 0.85)],
	["Облако «ТучаДиск»", "Место закончилось. Удалить одну легенду?", Color(0.55, 0.75, 1.0)],
	["Фитнес «Качалка Колизея»", "Гладиаторам скидка 90% на абонемент!", Color(0.85, 0.45, 0.20)],
	["Антивирус «Щит-Про»", "Найдено 47 угроз! Купите Про, чтобы узнать какие.", Color(0.30, 0.75, 0.45)],
	["Аптека «Хилка»", "Зелья здоровья 3+1. Только онлайн!", Color(0.95, 0.40, 0.55)],
	["Гороскоп «Звёздный пиксель»", "Сегодня удачный день, чтобы нажать ульту.", Color(0.70, 0.45, 0.95)],
	["Маркетплейс «ВсёСразу»", "Ваш заказ «Сэндвич» передан в службу доставки.", Color(0.95, 0.55, 0.15)],
]
# Звонок: [кто звонит, подпись, сообщение, если отклонить, цвет]
const CALLERS := [
	["Мама", "мобильный", "Ты поел? Перезвони, как закончишь с боссами.", Color(0.95, 0.45, 0.55)],
	["Пельмень-Банк", "возможно, реклама", "Вы не взяли трубку, но кредит «Бесконечность» уже одобрен! Перезвоните до 23:59.", Color(0.95, 0.72, 0.18)],
	["Торговец из Лавки", "Лавка", "Завёз новые сундуки. Заходи, когда победишь!", Color(0.85, 0.60, 0.30)],
	["Доставка «Сытый гоблин»", "курьер", "Курьер у портала. Портал закрыт. Сэндвич съеден.", Color(0.35, 0.70, 0.30)],
	["Начальник", "работа", "Ты где? Совещание началось пять минут назад.", Color(0.35, 0.55, 0.90)],
	["Кузнец", "друг", "Одолжи молот на часок, мой куда-то улетел. Перезвони.", Color(0.80, 0.50, 0.30)],
	["Неизвестный номер", "возможно, спам", "Здравствуйте! Вас беспокоит служба безопасности Арены. Назовите код из СМС.", Color(0.55, 0.55, 0.60)],
]

func _allies() -> Array:
	return p.get_parent().get_children().filter(func(n): return n is Player and n.team == p.team and n.is_alive())

func _pick(a: Array):
	return a[randi() % a.size()] if not a.is_empty() else null

func _ground(x: float) -> float:
	var gh := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(Vector2(x, p.map_top + 60.0), Vector2(x, p.map_top + 3000.0), Layer.WORLD | Layer.FRAME))
	return gh["position"].y if not gh.is_empty() else p.global_position.y + p.body_size.y / 2

func _k() -> float:
	return 1.25 if Balance.arena(p) else 1.0

# Случайного выхилил (чаще своего — но как повезёт; босса «по ошибке» не лечит)
func _ev_heal() -> void:
	var who: Variant = _pick(_allies()) if randf() < 0.7 else _pick(_enemies().filter(func(e): return e.stagger_max <= 0.0))
	if who == null:
		return
	who.heal(int(who.max_hp * 0.3))
	Fx.ring(p.get_parent(), who.global_position, 60.0, Color(0.5, 1.0, 0.6, 0.9), 0.4, 5.0)
	who._float_label("+HP", Color(0.5, 1.0, 0.6))

func _ev_zap() -> void:
	var e: Variant = _pick(_enemies())
	if e == null:
		return
	Fx.bolt(p.get_parent(), e.hurt_center() + Vector2(randf_range(-60, 60), -700), e.hurt_center(), Color(0.85, 0.7, 1.0))
	e.take_damage(int(30 * _k()), p)

func _ev_boom() -> void:
	var world := p.get_parent()
	for k in 3:
		var e: Variant = _pick(_enemies())
		var x: float = (e.global_position.x if e else p.global_position.x) + randf_range(-260, 260)
		x = clampf(x, 40.0, p.map_w - 40.0)
		var at := Vector2(x, _ground(x))
		Fx.rune_circle(world, at, 90.0, Color(1.0, 0.4, 0.3, 0.9), 0.6)
		_after(0.6 + k * 0.15, func():
			if not is_instance_valid(p) or not p.is_inside_tree():
				return
			var w2 := p.get_parent()
			Util.flash(w2, at + Vector2(0, -30), 100.0, Color(1.0, 0.6, 0.3, 0.9))
			Fx.sparks(w2, at, Color(1.0, 0.6, 0.2), 16, 300.0, 5.0, true)
			Fx.shake(w2, 5.0)
			for o in _enemies():
				if o.global_position.distance_to(at + Vector2(0, -30)) < 110.0:
					o.take_damage(int(25 * _k()), p))

# Здание посреди карты
func _ev_build() -> void:
	var x := randf_range(120.0, p.map_w - 120.0)
	var g := _ground(x)
	var d := Maps.make_destructible(Rect2(x - 40.0, g - 100.0, 80.0, 100.0), 20.0, Color(0.62, 0.38, 0.30), 40, 30.0)
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	d.lifetime = 14.0
	for cx in d.cols:                                          # крыша
		d.cell_colors[Vector2i(cx, 0)] = Color(0.30, 0.30, 0.40)
	d.cell_colors[Vector2i(1, 2)] = Color(0.95, 0.85, 0.45)     # окна
	d.cell_colors[Vector2i(2, 2)] = Color(0.95, 0.85, 0.45)
	p.get_parent().add_child(d)
	Fx.sparks(p.get_parent(), Vector2(x, g - 50), VIO, 16, 260.0, 4.0)

# Сброс баффов: обычно — врагам, но иногда и своим
func _ev_dispel() -> void:
	var who: Array = _enemies() if randf() < 0.7 else _allies()
	for n in who:
		n.buffs.clear()
		Fx.ring(p.get_parent(), n.global_position, 50.0, Color(0.9, 0.9, 1.0, 0.8), 0.3, 4.0)

# Телепорт кого угодно куда угодно
func _ev_teleport() -> void:
	var all: Array = p.get_parent().get_children().filter(func(n): return n is Player and n.is_alive() and n.stagger_max <= 0.0 and not n.cutscene_shield)
	var who: Variant = _pick(all)
	if who == null:
		return
	var x := randf_range(80.0, p.map_w - 80.0)
	var to := Vector2(x, _ground(x) - who.body_size.y / 2 - 6.0)
	Util.flash(p.get_parent(), who.global_position, 50.0, Color(0.85, 0.65, 1.0, 0.9))
	who.global_position = to
	who.velocity = Vector2.ZERO
	Util.flash(p.get_parent(), to, 50.0, Color(0.85, 0.65, 1.0, 0.9))

# Без гравитации: врагов подбрасывает (и босса — пониже, он тяжёлый)
func _ev_gravity() -> void:
	for e in _enemies():
		if e.cutscene_shield or e.flying:
			continue
		var boss: bool = e.stagger_max > 0.0
		e.velocity.y = -460.0 if boss else -820.0
		e.slow(1.0, 0.75 if boss else 0.6, "water")

# Синий экран: враги замирают
func _ev_bsod() -> void:
	for e in _enemies():
		var t := 0.5 if e.stagger_max > 0.0 else 1.3
		e.stun(t)
		var scr := Polygon2D.new()
		var s: Vector2 = e.body_size * 0.6
		scr.polygon = PackedVector2Array([Vector2(-s.x, -s.y), Vector2(s.x, -s.y), Vector2(s.x, s.y * 0.3), Vector2(-s.x, s.y * 0.3)])
		scr.color = Color(0.10, 0.30, 0.85, 0.85)
		e.add_child(scr)
		var sad := Label.new()
		sad.text = ":("
		sad.position = Vector2(-10, -s.y + 2)
		sad.add_theme_font_size_override("font_size", 16)
		scr.add_child(sad)
		var tw := scr.create_tween()
		tw.tween_interval(t)
		tw.tween_callback(scr.queue_free)

# Дождь из резиновых уточек
func _ev_ducks() -> void:
	var world := p.get_parent()
	for k in 6:
		var e: Variant = _pick(_enemies())
		if e == null:
			return
		var duck := Polygon2D.new()
		duck.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(-7, -6), Vector2(2, -6), Vector2(3, -12), Vector2(9, -12), Vector2(12, -9), Vector2(9, -6), Vector2(10, 0), Vector2(5, 4), Vector2(-6, 4)])
		duck.color = Color(1.0, 0.86, 0.20)
		var beak := Polygon2D.new()
		beak.polygon = PackedVector2Array([Vector2(11, -10), Vector2(16, -9), Vector2(11, -8)])
		beak.color = Color(1.0, 0.50, 0.15)
		duck.add_child(beak)
		duck.scale = Vector2(1.6, 1.6)
		duck.z_index = 6
		var tx: float = e.global_position.x + randf_range(-30, 30)
		var we: WeakRef = weakref(e)
		var ey: float = e.global_position.y
		duck.position = Vector2(tx, e.global_position.y - 650.0)
		world.add_child(duck)
		var t := duck.create_tween()
		t.tween_interval(k * 0.12)
		t.tween_property(duck, "position:y", ey - 10.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(func():
			var o: Variant = we.get_ref()
			if o and o.is_alive() and absf(o.global_position.x - tx) < 50.0 and is_instance_valid(p):
				o.take_damage(int(10 * _k()), p)
			Fx.sparks(world, duck.position, Color(1.0, 0.9, 0.3), 6, 160.0, 3.0))
		t.tween_property(duck, "modulate:a", 0.0, 0.3)
		t.tween_callback(duck.queue_free)

# Уменьшение: враг (и босс — не так сильно) съёживается и замедляется
func _ev_shrink() -> void:
	var e: Variant = _pick(_enemies().filter(func(o): return not o.cutscene_shield and not o.has_meta("glav_small")))
	if e == null:
		_ev_zap()
		return
	var boss: bool = e.stagger_max > 0.0
	var s0: float = e._rig_root.scale.x if e._rig_root else 1.0
	e.set_meta("glav_small", true)
	e.set_visual_scale(s0 * (0.75 if boss else 0.6), 0.2)
	e.slow(3.0 if boss else 4.0, 0.82 if boss else 0.7, "water")
	var we: WeakRef = weakref(e)
	_after(3.0 if boss else 4.0, func():
		var o: Variant = we.get_ref()
		if o:
			o.set_visual_scale(s0, 0.2)
			o.remove_meta("glav_small"))

# Поджог всех: враги горят долго и сильно, свои (и сам Главный) — чуть-чуть
func _ev_ignite() -> void:
	var world := p.get_parent()
	Util.flash(world, p.global_position, 320.0, Color(1.0, 0.5, 0.15, 0.45))
	for n in world.get_children():
		if n is Player and n.is_alive() and not n.cutscene_shield and not n.has_meta("fireproof"):
			var foe: bool = n.team != p.team
			n.burn(4.0 if foe else 1.5, 8.0 * _k() if foe else 2.0, p if foe else null)
			Fx.flame_ring(n, 26.0, 0.6)
			Fx.sparks(world, n.hurt_center(), Color(1.0, 0.55, 0.15), 8, 180.0, 3.5, true)

# Заморозка всех: враги вмерзают в лёд надолго (боссы — сильно замедлены), свои — на миг
func _ev_freeze() -> void:
	var world := p.get_parent()
	Util.flash(world, p.global_position, 320.0, Color(0.7, 0.92, 1.0, 0.5))
	for n in world.get_children():
		if n is Player and n.is_alive() and not n.cutscene_shield:
			var foe: bool = n.team != p.team
			if foe and n.stagger_max > 0.0:
				n.freeze(0.8)                                        # босс вмерзает ненадолго, потом замедлен
				var wb: WeakRef = weakref(n)
				_after(0.8, func():
					var o: Variant = wb.get_ref()
					if o and o.is_alive():
						o.chill(2.0, 0.5))
			else:
				n.freeze((2.5 if Balance.arena(p) else 2.2) if foe else 0.7)
			Fx.sparks(world, n.hurt_center(), Color(0.85, 0.96, 1.0), 10, 160.0, 3.0)

# Спам: на экране всплывают «уведомления», враги отвлекаются на них
func _ev_spam() -> void:
	var world := p.get_parent()
	var ads := SPAM.duplicate()
	ads.shuffle()
	var es := _enemies()
	for k in randi_range(3, 5):
		var ad: Array = ads[k]
		GlavKit.toast(world, ad[0], ad[1], ad[2], k * 0.3)
		var e: Variant = _pick(es)
		if e == null:
			continue
		var we: WeakRef = weakref(e)
		_after(k * 0.3 + 0.15, func():
			var o: Variant = we.get_ref()
			if o == null or not o.is_alive() or not is_instance_valid(p) or not p.is_inside_tree():
				return
			o.take_damage(int(8 * _k()), p)
			o.glitch_t = maxf(o.glitch_t, 0.4 if o.stagger_max > 0.0 else 1.4)
			_envelope(o))

# Конвертик над головой отвлёкшегося врага
func _envelope(o: Player) -> void:
	var env := Node2D.new()
	env.z_index = 8
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-10, -7), Vector2(10, -7), Vector2(10, 7), Vector2(-10, 7)])
	body.color = Color(0.97, 0.97, 1.0)
	env.add_child(body)
	var flap := Line2D.new()
	flap.points = PackedVector2Array([Vector2(-10, -7), Vector2(0, 1), Vector2(10, -7)])
	flap.width = 1.5
	flap.default_color = Color(0.45, 0.55, 0.75)
	env.add_child(flap)
	var dot := Polygon2D.new()
	dot.polygon = Util.circle(4.0, 8)
	dot.position = Vector2(10, -7)
	dot.color = Color(1.0, 0.25, 0.25)
	env.add_child(dot)
	env.position = Vector2(0, -o.body_size.y / 2 - 24)
	o.add_child(env)
	var tw := env.create_tween()
	tw.tween_property(env, "position:y", env.position.y - 14.0, 1.2)
	tw.parallel().tween_property(env, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.tween_callback(env.queue_free)

# Звонок: игра на паузе, на экране — входящий вызов
func _ev_call() -> void:
	if _called or p.get_tree().paused:
		_ev_spam()
		return
	_called = true
	var c := PhoneCall.new()
	c.caller = CALLERS[randi() % CALLERS.size()]
	p.get_parent().add_child(c)

# Всплывающее «уведомление» сверху посередине экрана (спам, сообщения после звонка).
# Нарочно поверх интерфейса: спам мешает всем, кто играет, — и обоим в игре вдвоём.
static func toast(world: Node, app: String, text: String, col: Color, delay := 0.0, life := 3.4) -> void:
	if world == null or not world.is_inside_tree():
		return
	var layer: CanvasLayer = world.get_node_or_null("GlavToasts")
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "GlavToasts"
		layer.layer = 14
		layer.process_mode = Node.PROCESS_MODE_ALWAYS
		world.add_child(layer)
	var used := {}
	for c in layer.get_children():
		if not c.is_queued_for_deletion():
			used[int(c.get_meta("slot", -1))] = true
	var slot := 0
	while used.has(slot) and slot < 5:
		slot += 1
	var vs := Config.screen(world)
	var w := minf(440.0, vs.x - 40.0)
	var box := Panel.new()
	box.size = Vector2(w, 76)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.97, 0.97, 0.98, 0.96)
	st.set_corner_radius_all(14)
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 6
	box.add_theme_stylebox_override("panel", st)
	var icon := Panel.new()
	icon.size = Vector2(48, 48)
	icon.position = Vector2(12, 14)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ist := StyleBoxFlat.new()
	ist.bg_color = col
	ist.set_corner_radius_all(12)
	icon.add_theme_stylebox_override("panel", ist)
	box.add_child(icon)
	var letter := Label.new()
	letter.text = app.substr(0, 1)
	letter.size = icon.size
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.add_theme_font_size_override("font_size", 26)
	letter.add_theme_color_override("font_color", Color(1, 1, 1))
	icon.add_child(letter)
	var title := Label.new()
	title.text = app
	title.position = Vector2(72, 8)
	title.size = Vector2(w - 140, 22)
	title.clip_text = true
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.10, 0.10, 0.14))
	box.add_child(title)
	var when := Label.new()
	when.text = "сейчас"
	when.position = Vector2(w - 70, 9)
	when.size = Vector2(58, 20)
	when.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	when.add_theme_font_size_override("font_size", 12)
	when.add_theme_color_override("font_color", Color(0.50, 0.50, 0.56))
	box.add_child(when)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.position = Vector2(72, 30)
	body.size = Vector2(w - 84, 42)
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color(0.25, 0.25, 0.30))
	box.add_child(body)
	var y := 10.0 + slot * 84.0
	box.position = Vector2((vs.x - w) / 2, -90.0)                     # выезжает сверху
	box.set_meta("slot", slot)
	for l in [letter, title, when, body]:
		(l as Label).add_theme_constant_override("outline_size", 0)   # без игровой обводки — как на телефоне
	layer.add_child(box)
	var tw := box.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): Audio.sfx("notify"))
	tw.tween_property(box, "position:y", y, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(life)
	tw.tween_property(box, "modulate:a", 0.0, 0.3)
	tw.tween_callback(box.queue_free)

# ---------- Реклама: пауза, на экране — реклама (через 5 с её можно пропустить) ----------
func _ev_ad() -> void:
	if _called or p.get_tree().paused:
		_ev_spam()
		return
	_called = true
	var ad := AdBreak.new()
	ad.kind = randi() % AdBreak.ADS.size()
	p.get_parent().add_child(ad)

# ---------- Бесконечная сила: все свои — как в очках, только сильнее ----------
func _ev_power() -> void:
	var world := p.get_parent()
	for a in _allies():
		for t in ["speed", "rapid"]:
			a.buffs[t] = {"t": 7.0, "mega": true}             # МЕГА-скорость и МЕГА-шквал
		a.buffs["damage"] = {"t": 7.0, "mega": false}        # и урон ×1,5
		a._float_label("Бесконечная сила!", Color(1.0, 0.85, 0.35))
		Fx.ring(world, a.hurt_center(), 70.0, Color(1.0, 0.85, 0.35, 0.95), 0.4, 6.0)
		var aura := PowerAura.new()
		aura.life = 7.0
		a.add_child(aura)

# ---------- Перерыв на кофе: «СТОООП!» — все замирают, Главный пьёт кофе ----------
const COFFEE := 2.6

func _ev_coffee() -> void:
	if _coffee_used or _coffee_t > 0.0:
		return
	_coffee_used = true
	_coffee_t = COFFEE
	var world := p.get_parent()
	world.set_meta("glav_coffee", true)
	_frozen.clear()
	for n in world.get_children():
		if n == p or n == _console or n is CanvasLayer or n is Camera2D or n is AdBreak or n is PhoneCall:
			continue
		var m: Variant = (n as CanvasItem).modulate if n is CanvasItem else null
		var stop: bool = n is Player or n is ArenaMode or ("team" in n)   # карту не трогаем: иначе пропадут стены и пол
		_frozen.append([weakref(n), n.process_mode if stop else -1, m])
		if stop:
			n.process_mode = Node.PROCESS_MODE_DISABLED   # время встало: и враги, и снаряды, и свои
		if n is CanvasItem:
			(n as CanvasItem).modulate = (n as CanvasItem).modulate * Color(0.62, 0.66, 0.82)   # всё посерело, кроме Главного
	var layer := CanvasLayer.new()                            # крик — крупно, посередине экрана
	layer.name = "GlavCoffeeShout"
	layer.layer = 13
	world.add_child(layer)
	var vs := Config.screen(world)
	var shout := Label.new()
	shout.text = "СТОООООП!!!!"
	shout.size = Vector2(vs.x, 80)
	shout.position = Vector2(0, vs.y * 0.26)
	shout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shout.add_theme_font_size_override("font_size", 64)
	shout.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	shout.add_theme_constant_override("outline_size", 12)
	shout.add_theme_color_override("font_outline_color", Color(0.25, 0.10, 0.30))
	shout.pivot_offset = Vector2(vs.x / 2, 40)
	shout.scale = Vector2(0.3, 0.3)
	layer.add_child(shout)
	var tw := shout.create_tween()
	tw.tween_property(shout, "scale", Vector2(1.1, 1.1), 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(1.1)
	tw.tween_property(shout, "modulate:a", 0.0, 0.4)
	tw.tween_callback(layer.queue_free)
	Fx.shake(world, 9.0)
	# кружка в руке
	_cup = Node2D.new()
	_cup.z_index = 8
	var mug := Polygon2D.new()
	mug.polygon = PackedVector2Array([Vector2(-6, -8), Vector2(6, -8), Vector2(5, 7), Vector2(-5, 7)])
	mug.color = Color(0.96, 0.96, 0.94)
	_cup.add_child(mug)
	var coffee := Polygon2D.new()
	coffee.polygon = PackedVector2Array([Vector2(-5, -7), Vector2(5, -7), Vector2(5, -4), Vector2(-5, -4)])
	coffee.color = Color(0.40, 0.22, 0.10)
	_cup.add_child(coffee)
	var handle := Line2D.new()
	handle.points = PackedVector2Array([Vector2(6, -5), Vector2(10, -4), Vector2(10, 2), Vector2(5, 3)])
	handle.width = 2.0
	handle.default_color = Color(0.92, 0.92, 0.90)
	_cup.add_child(handle)
	var logo := Polygon2D.new()                              # сердечко-логотип на кружке
	logo.polygon = PackedVector2Array([Vector2(0, 4), Vector2(-3, 0), Vector2(-2, -2), Vector2(0, -1), Vector2(2, -2), Vector2(3, 0)])
	logo.color = Color(0.72, 0.42, 1.0)
	_cup.add_child(logo)
	_cup.position = Vector2(p.facing * 16.0, -4.0)
	_cup.scale = Vector2(1.5, 1.5)
	p.add_child(_cup)

func _coffee_step(delta: float) -> void:
	_coffee_t -= delta
	var k := 1.0 - _coffee_t / COFFEE
	if is_instance_valid(_cup):
		if k < 0.25:                                             # поднёс ко рту
			_cup.position = Vector2(p.facing * 16.0, -4.0).lerp(Vector2(p.facing * 10.0, -p.body_size.y * 0.42), k / 0.25)
		elif k < 0.7:                                            # пьёт залпом
			_cup.rotation = -p.facing * lerpf(0.0, 1.9, (k - 0.25) / 0.45)
			if randf() < 0.3:
				Fx.sparks(p.get_parent(), _cup.global_position + Vector2(0, -10), Color(0.9, 0.9, 0.95, 0.7), 1, 30.0, 2.5, true)
		elif not _cup.has_meta("thrown"):
			_cup.set_meta("thrown", true)                         # и выбрасывает кружку за спину
			p._float_label("Ахх… Так, на чём я остановился?", Color(0.85, 0.75, 1.0))
			var at := _cup.global_position
			p.remove_child(_cup)
			p.get_parent().add_child(_cup)
			_cup.global_position = at
			var to := at + Vector2(-p.facing * 160.0, 40.0)
			var tw := _cup.create_tween().set_parallel(true)
			tw.tween_property(_cup, "position:x", to.x, 0.6)
			tw.tween_property(_cup, "position:y", at.y - 70.0, 0.25).set_ease(Tween.EASE_OUT)
			tw.tween_property(_cup, "position:y", to.y, 0.35).set_delay(0.25).set_ease(Tween.EASE_IN)
			tw.tween_property(_cup, "rotation", -p.facing * 9.0, 0.6)
			tw.chain().tween_property(_cup, "modulate:a", 0.0, 0.3)
			tw.chain().tween_callback(_cup.queue_free)
	if _coffee_t <= 0.0:
		_coffee_end()

func _coffee_end() -> void:
	_coffee_t = 0.0
	if p == null or not is_instance_valid(p) or not p.is_inside_tree():
		return
	var world := p.get_parent()
	world.remove_meta("glav_coffee")
	for e in _frozen:
		var n: Variant = (e[0] as WeakRef).get_ref()
		if n:
			var mode: int = e[1]
			if mode >= 0:
				n.process_mode = Node.PROCESS_MODE_INHERIT if (n is Player and mode == Node.PROCESS_MODE_DISABLED) else mode
			if e[2] != null and n is CanvasItem:
				(n as CanvasItem).modulate = e[2]
	_frozen.clear()
	if is_instance_valid(_cup) and not _cup.has_meta("thrown"):
		_cup.queue_free()

# ---------- Хотфикс босса: одна способность босса отключена (8 с) ----------
func _ev_boss_fix() -> void:
	var b := _boss()
	if b == null:
		_ev_zap()
		return
	var keys: Array = []
	for k in b.bot_abilities.keys():
		keys.append([String(k), null])
	for c in b.get_children():
		if "_cd" in c and c.get("_cd") is Dictionary:
			for k2 in (c.get("_cd") as Dictionary).keys():
				keys.append([String(k2), c])
	for c2 in b.get_children():
		if c2 is BossFix and is_instance_valid(c2):
			keys = keys.filter(func(x): return x[0] != c2.key)    # уже отключённую — не трогаем, берём другую
	var fx := BossFix.new()
	fx.boss = b
	if keys.is_empty():
		fx.key = "speed"                                       # нечего отключать — босс просто медленнее
		b.slow(6.0, 0.55, "water")
	else:
		var pick: Array = keys[randi() % keys.size()]
		fx.key = pick[0]
		fx.brain = pick[1]
	b.add_child(fx)

# ---------- Лаги: враги дёргаются, будто сервер тормозит ----------
func _ev_lag() -> void:
	var lag := LagFx.new()
	for e in _enemies():
		if not e.cutscene_shield:
			lag.targets.append(weakref(e))
	p.get_parent().add_child(lag)

# ---------- Сборщик мусора: все вражеские снаряды и лужи исчезают ----------
func _ev_gc() -> void:
	var world := p.get_parent()
	var n := 0
	for o in world.get_children():
		if o is Player or not ("team" in o) or o.is_queued_for_deletion():
			continue
		if not (o is Bullet or o is Arrow or o is Spear or o is Grenade or o is FallingBomb or o is Shell or o is Shuriken \
				or o is BigShuriken or o is ThrownHammer or o is SlashWave or o is GasBubble or o is FireZone or o is PoisonPool or o is DustCloud):
			continue
		var t: Variant = o.get("team")
		if not (t is int) or int(t) == p.team or int(t) < 0:
			continue
		n += 1
		Fx.sparks(world, (o as Node2D).global_position, Color(0.75, 1.0, 0.75), 4, 120.0, 2.5)
		o.queue_free()
	p._float_label("gc: удалено %d" % n, Color(0.70, 1.0, 0.75))

func _ev_haste() -> void:
	for a in _allies():
		a.buffs["speed"] = {"t": 5.0, "mega": false}
		Fx.ring(p.get_parent(), a.global_position, 50.0, Color(0.5, 1.0, 0.6, 0.8), 0.3, 4.0)

# МЕГА-ульта: заодно срабатывает МЕГА-ульта случайной другой легенды
const GUESTS := [["hunter", "starter"], ["champion", "hero"], ["mortis", "hero"], ["soldier", "elite"], ["seam", "seam"], ["pivozavr", "pivozavr"]]

func _guest_ult(idx := -1) -> void:
	var g: Array = GUESTS[idx if idx >= 0 else randi() % GUESTS.size()]
	var k: HeroKit
	match g[1]:
		"starter": k = StarterKit.new()
		"elite": k = EliteKit.new()
		"seam": k = SeamKit.new()
		"pivozavr": k = PivozavrKit.new()
		_: k = HeroKit.new()
	k.hero = g[0]
	k.p = p
	k.duel = duel
	k.name = "GuestKit"
	p.add_child(k)
	_guest = k
	for ch in Characters.LIST:
		if ch.get("kit", "") == g[0]:
			p._float_label("+ %s!" % String(ch["skills"][3][0]).replace("Ульта: ", ""), Color(1.0, 0.85, 0.4))
	var wk: WeakRef = weakref(k)
	_after(0.4, func():
		var kk: Variant = wk.get_ref()
		if kk and is_instance_valid(p) and p.is_alive():
			kk.ult())

func on_death() -> void:
	super()
	_end_beam(false)
	_shake = -1.0
	if _coffee_t > 0.0:
		_coffee_end()
	if _ult_t > 0.0:
		_end_ult()
	p.fly_free = false


# =====================================================================
# Сэндвич: летит по дуге, попал во врага — ему нехорошо
class Sandwich extends Node2D:
	var owner_p: Player
	var vel := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 5
		var bread := Polygon2D.new()
		bread.polygon = PackedVector2Array([Vector2(-9, -2), Vector2(-7, -6), Vector2(7, -6), Vector2(9, -2), Vector2(9, 5), Vector2(-9, 5)])
		bread.color = Color(0.92, 0.72, 0.42)
		add_child(bread)
		for c in [[Color(0.40, 0.80, 0.30), -1.0], [Color(0.95, 0.40, 0.35), 1.0], [Color(1.0, 0.85, 0.30), 3.0]]:
			var l := Polygon2D.new()                                      # салат, ветчина, сыр
			l.polygon = PackedVector2Array([Vector2(-10, c[1] - 1), Vector2(10, c[1] - 1), Vector2(10, c[1] + 1), Vector2(-10, c[1] + 1)])
			l.color = c[0]
			add_child(l)

	func _physics_process(delta: float) -> void:
		_t += delta
		vel.y += 1100.0 * delta
		var from := position
		position += vel * delta
		rotation += delta * 8.0 * signf(vel.x)
		if not is_instance_valid(owner_p) or _t > 3.0:
			queue_free()
			return
		for e in owner_p.kit._enemies():
			if e.hurt_center().distance_to(position) < 16.0 + e.body_size.x * 0.5:
				owner_p.kit.make_sick(e)
				e.take_damage(6, owner_p)
				_splat()
				return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, position, Layer.WORLD | Layer.FRAME))
		if not hit.is_empty():
			position = hit["position"]
			_splat()

	func _splat() -> void:
		Fx.sparks(get_parent(), position, Color(0.92, 0.72, 0.42), 8, 160.0, 4.0)
		queue_free()

# Пиксельные очки: летят вперёд; мимо — падают и лежат, пока их не подберут
class Shades extends Node2D:
	var owner_p: Player
	var mega := false
	var dir := 1
	var _vel := Vector2.ZERO
	var _state := "fly"
	var _t := 0.0
	var _travel := 0.0

	static func glasses(k: float) -> Node2D:
		var n := Node2D.new()
		var frame := Polygon2D.new()                          # чёрная оправа, как на фото
		frame.polygon = PackedVector2Array([Vector2(-14, -3), Vector2(16, -3), Vector2(16, 0), Vector2(5, 0), Vector2(4, 3),
				Vector2(-1, 3), Vector2(-2, 0), Vector2(-4, 0), Vector2(-5, 3), Vector2(-12, 3), Vector2(-13, 0), Vector2(-14, 0)])
		frame.color = Color(0.03, 0.03, 0.04)
		n.add_child(frame)
		for lens in [-9.0, 1.0]:                              # белые пиксели-блики
			for k2 in 3:
				var px := Polygon2D.new()
				px.polygon = PackedVector2Array([Vector2(0, 0), Vector2(1.6, 0), Vector2(1.6, 1.4), Vector2(0, 1.4)])
				px.color = Color(1, 1, 1)
				px.position = Vector2(lens + k2 * 1.6, -2.2 + (k2 % 2) * 1.4)
				n.add_child(px)
		n.scale = Vector2(k, k)
		n.z_index = 3
		return n

	func _ready() -> void:
		z_index = 6
		add_child(glasses(1.3))
		_vel = Vector2(dir * 900.0, 0)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(owner_p):
			queue_free()
			return
		match _state:
			"fly":
				var from := position
				position += _vel * delta
				_travel += absf(_vel.x) * delta
				rotation = sin(_t * 20.0) * 0.15
				for n in get_parent().get_children():
					if n is Player and n != owner_p and n.is_alive() and not n.cutscene_shield \
							and n.hurt_center().distance_to(position) < 14.0 + n.body_size.x * 0.5:
						_land_on(n)
						return
				var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, position, Layer.WORLD | Layer.FRAME))
				if not hit.is_empty() or _travel > 620.0:
					if not hit.is_empty():
						position = hit["position"] - Vector2(dir * 6.0, 0)
					_state = "fall"
					_vel = Vector2(-dir * 60.0, -120.0)
			"fall":
				var from2 := position
				_vel.y += 1200.0 * delta
				position += _vel * delta
				rotation += delta * 6.0
				var hit2 := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from2, position + Vector2(0, 4), Layer.WORLD | Layer.FRAME))
				if not hit2.is_empty():
					position = hit2["position"] + Vector2(0, -4)
					rotation = 0.0
					_state = "lie"
					_t = 0.0
			"lie":
				modulate.a = 1.0 if _t < 7.0 else (0.5 + 0.5 * sin(_t * 12.0))
				if _t > 9.0:
					queue_free()
					return
				for n in get_parent().get_children():
					if n is Player and n.is_alive() and not n.cutscene_shield and n.global_position.distance_to(position) < n.body_size.x * 0.5 + 16.0 \
							and absf(n.global_position.y + n.body_size.y / 2 - position.y) < 30.0:
						_land_on(n)
						return

	func _land_on(n: Player) -> void:
		if n.team == owner_p.team:
			GlavKit.cool(n)
		elif owner_p.kit is GlavKit:
			owner_p.kit.blind(n, mega)
		Fx.sparks(get_parent(), position, Color(0.9, 0.9, 1.0), 8, 180.0, 3.0)
		queue_free()

# Метка под ослеплённым врагом: ходит за ним, за 0,5 с до удара замирает — и с неба бьёт луч
class SkyMark extends Node2D:
	var owner_p: Player
	var target: Player
	var strikes := 2
	var _t := 0.0
	var _next := 1.2
	var _ring: Line2D

	func _ready() -> void:
		z_index = 3
		_ring = Line2D.new()
		var pts := PackedVector2Array()
		for k in 25:
			var a := TAU * k / 24.0
			pts.append(Vector2(cos(a) * 46.0, sin(a) * 12.0))
		_ring.points = pts
		_ring.width = 3.0
		_ring.default_color = Color(1.0, 0.9, 0.5, 0.9)
		add_child(_ring)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(owner_p):
			queue_free()
			return
		var frozen := _next - _t < 0.5
		if not frozen and is_instance_valid(target) and target.is_alive():
			position = target.global_position + Vector2(0, target.body_size.y / 2)
		_ring.default_color = Color(1.0, 0.35, 0.3, 0.95) if frozen else Color(1.0, 0.9, 0.5, 0.9)
		_ring.rotation = 0.0
		_ring.scale = Vector2.ONE * (1.0 + (0.15 * sin(_t * 30.0) if frozen else 0.0))
		if _t >= _next:
			_strike()
			strikes -= 1
			_next += 1.3
			if strikes <= 0:
				queue_free()

	func _strike() -> void:
		var world := get_parent()
		LightBeam.draw(world, [[position + Vector2(0, -900), position, 0]], Color(1.0, 0.92, 0.55), 30.0, 0.35)
		Fx.ring(world, position, 80.0, Color(1.0, 0.95, 0.7, 0.9), 0.35, 6.0, 0.3)
		Fx.shake(world, 4.0)
		for e in owner_p.kit._enemies():
			if absf(e.global_position.x - position.x) < 60.0 + e.body_size.x / 2 \
					and absf(e.global_position.y + e.body_size.y / 2 - position.y) < e.body_size.y + 20.0:
				e.take_damage(int(28 * (1.25 if Balance.arena(owner_p) else 1.0)), owner_p)

# Чек: летит прямо сквозь своих, враг смотрит в него и не понимает, что с ним делать
class Receipt extends Node2D:
	var owner_p: Player
	var dir := Vector2.RIGHT
	var _t := 0.0

	func _ready() -> void:
		z_index = 6
		add_child(paper())

	static func paper() -> Node2D:
		var n := Node2D.new()
		var sheet := Polygon2D.new()
		sheet.polygon = PackedVector2Array([Vector2(-7, -10), Vector2(7, -10), Vector2(7, 8), Vector2(5, 10), Vector2(3, 8), Vector2(1, 10),
				Vector2(-1, 8), Vector2(-3, 10), Vector2(-5, 8), Vector2(-7, 10)])
		sheet.color = Color(0.97, 0.96, 0.92)
		n.add_child(sheet)
		for k in 5:
			var l := Line2D.new()
			l.points = PackedVector2Array([Vector2(-5, -7 + k * 3), Vector2(3 - (k % 2) * 3, -7 + k * 3)])
			l.width = 1.0
			l.default_color = Color(0.35, 0.35, 0.40)
			n.add_child(l)
		var total := Line2D.new()
		total.points = PackedVector2Array([Vector2(-5, 7), Vector2(5, 7)])
		total.width = 1.5
		total.default_color = Color(0.85, 0.15, 0.15)
		n.add_child(total)
		return n

	func _physics_process(delta: float) -> void:
		_t += delta
		var from := position
		position += dir * 1000.0 * delta
		rotation = sin(_t * 18.0) * 0.4
		if not is_instance_valid(owner_p) or _t > 1.0:
			queue_free()
			return
		for e in owner_p.kit._enemies():
			if not e.cutscene_shield and e.hurt_center().distance_to(position) < 14.0 + e.body_size.x * 0.5:
				_bill(e)
				queue_free()
				return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, position, Layer.WORLD | Layer.FRAME))
		if not hit.is_empty() and not (Balance.arena(owner_p) and Util.is_one_way(hit["collider"])):
			queue_free()                                     # сквозные платформы Арены чек пролетает, как пули

	func _bill(e: Player) -> void:
		var t := 0.9 if e.stagger_max > 0.0 else 2.6
		e.stun(t)
		e._float_label("…Сколько?!", Color(0.95, 0.95, 0.85))
		var held := paper()
		held.position = Vector2(e.facing * e.body_size.x * 0.35, -e.body_size.y * 0.2)
		held.scale = Vector2(1.4, 1.4)
		e.add_child(held)
		var q := Label.new()
		q.text = "?"
		q.position = Vector2(-6, -e.body_size.y * 0.5 - 40)
		q.add_theme_font_size_override("font_size", 26)
		q.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
		q.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.06))
		q.add_theme_constant_override("outline_size", 5)
		e.add_child(q)
		var tw := held.create_tween()
		tw.tween_property(held, "rotation", 0.25, t * 0.5)
		tw.tween_property(held, "rotation", -0.25, t * 0.5)
		tw.tween_callback(func():
			if is_instance_valid(q):
				q.queue_free()
			if not is_instance_valid(e):
				held.queue_free()
				return
			# выбросил: чек улетает, кувыркаясь
			var world := e.get_parent()
			var gp := held.global_position
			held.get_parent().remove_child(held)
			world.add_child(held)
			held.global_position = gp
			var t2 := held.create_tween().set_parallel(true)
			t2.tween_property(held, "position", gp + Vector2(-e.facing * 90.0, 70.0), 0.6)
			t2.tween_property(held, "rotation", TAU * 2.0, 0.6)
			t2.chain().tween_callback(held.queue_free))

# Входящий звонок (событие ульты): игра на паузе, на экране телефон.
# 10 с не трогать — сбросится; «Отклонить» — абонент пришлёт сообщение; «Ответить» —
# игра сразу продолжается, а 5 с из трубки слышна неразборчивая речь.
class PhoneCall extends CanvasLayer:
	var caller: Array = ["Мама", "мобильный", "Перезвони.", Color(0.95, 0.45, 0.55)]
	var state := "ring"
	var _t := 0.0
	var _talk := 0.0
	var _paused_by_me := false
	var _phone: Control
	var _timer: Label
	var _pill: Panel
	var _pill_lbl: Label
	var _ring: AudioStreamPlayer
	var _voice: AudioStreamPlayer
	var _world: Node
	var _hint: Label
	const RING := 10.0
	const TALK := 5.0

	func _ready() -> void:
		layer = 19
		process_mode = Node.PROCESS_MODE_ALWAYS
		_world = get_parent()
		_t = RING
		if not get_tree().paused:
			get_tree().paused = true
			_paused_by_me = true
		var vs := Config.screen(self)
		_phone = Control.new()
		_phone.size = vs
		_phone.add_to_group("pad_scope")              # геймпад выбирает только кнопки звонка
		add_child(_phone)
		var dim := ColorRect.new()
		dim.size = vs
		dim.color = Color(0, 0, 0, 0.55)
		_phone.add_child(dim)
		var h := minf(520.0, vs.y - 50.0)
		var w := h * 0.56
		var body := Panel.new()
		body.size = Vector2(w, h)
		body.position = (vs - body.size) / 2
		body.pivot_offset = body.size / 2
		body.name = "Body"
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.07, 0.07, 0.10)
		st.border_color = Color(0.30, 0.30, 0.36)
		st.set_border_width_all(5)
		st.set_corner_radius_all(36)
		st.shadow_color = Color(0, 0, 0, 0.5)
		st.shadow_size = 12
		body.add_theme_stylebox_override("panel", st)
		_phone.add_child(body)
		var notch := ColorRect.new()                   # «чёлка» с камерой
		notch.size = Vector2(w * 0.3, 10)
		notch.position = Vector2(w * 0.35, 12)
		notch.color = Color(0.02, 0.02, 0.03)
		body.add_child(notch)
		_label(body, "Входящий вызов", Vector2(0, h * 0.08), w, 16, Color(0.70, 0.72, 0.78))
		var av := Panel.new()                          # аватар — круг с первой буквой
		var ar := w * 0.22
		av.size = Vector2(ar * 2, ar * 2)
		av.position = Vector2(w / 2 - ar, h * 0.17)
		var ast := StyleBoxFlat.new()
		ast.bg_color = caller[3]
		ast.set_corner_radius_all(int(ar))
		av.add_theme_stylebox_override("panel", ast)
		body.add_child(av)
		var ini := Label.new()
		ini.text = String(caller[0]).substr(0, 1)
		ini.size = av.size
		ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ini.add_theme_font_size_override("font_size", int(ar * 1.1))
		ini.add_theme_color_override("font_color", Color(1, 1, 1))
		av.add_child(ini)
		var nm := _label(body, caller[0], Vector2(10, h * 0.17 + ar * 2 + 14), w - 20, 24, Color(1, 1, 1))
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.size = Vector2(w - 20, 64)
		_label(body, caller[1], Vector2(0, h * 0.17 + ar * 2 + 80), w, 15, Color(0.65, 0.67, 0.72))
		_timer = _label(body, "", Vector2(0, h * 0.70), w, 13, Color(0.60, 0.62, 0.68))
		var bw := w * 0.40
		var dec := _round_button(body, "Отклонить", Color(0.85, 0.20, 0.22), Vector2(w * 0.07, h * 0.78), Vector2(bw, 58))
		dec.pressed.connect(decline)
		var ans := _round_button(body, "Ответить", Color(0.20, 0.72, 0.32), Vector2(w * 0.53, h * 0.78), Vector2(bw, 58))
		ans.pressed.connect(answer)
		ans.grab_focus.call_deferred()
		# геймпад: значки кнопок на «Ответить» / «Отклонить» и подсказка под ними
		PadGlyph.attach(dec, "B")
		PadGlyph.attach(ans, "A")
		_hint = _label(body, "Геймпад:  A — ответить,  B — отклонить", Vector2(0, h * 0.78 + 66), w, 13, Color(0.78, 0.80, 0.86))
		_ring = _player("res://audio/sfx/phone_ring.wav", -4.0)
		_ring.finished.connect(func():
			if state == "ring" and is_instance_valid(_ring):
				_ring.play())
		_ring.play()

	func _label(parent: Control, t: String, pos: Vector2, w: float, fs: int, c: Color) -> Label:
		var l := Label.new()
		l.text = t
		l.position = pos
		l.size = Vector2(w, fs + 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", fs)
		l.add_theme_color_override("font_color", c)
		parent.add_child(l)
		return l

	func _round_button(parent: Control, t: String, c: Color, pos: Vector2, sz: Vector2) -> Button:
		var b := Button.new()
		b.text = t
		b.position = pos
		b.size = sz
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override("font_size", 17)
		b.add_theme_color_override("font_color", Color(1, 1, 1))
		b.add_theme_color_override("font_focus_color", Color(1, 1, 1))
		b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		for s in ["normal", "hover", "pressed", "focus"]:
			var st := StyleBoxFlat.new()
			st.bg_color = c.lightened(0.15) if s == "hover" else (c.darkened(0.2) if s == "pressed" else c)
			st.set_corner_radius_all(int(sz.y / 2))
			if s == "focus":
				st.bg_color = c.lightened(0.1)
				st.border_color = Color(1, 1, 1, 0.9)
				st.set_border_width_all(3)
			b.add_theme_stylebox_override(s, st)
		parent.add_child(b)
		return b

	func _player(path: String, db: float) -> AudioStreamPlayer:
		var a := AudioStreamPlayer.new()
		a.stream = load(path) if ResourceLoader.exists(path) else null
		a.bus = "SFX"
		a.volume_db = db
		a.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(a)
		return a

	# геймпад: A — ответить, B — отклонить (в любой момент, куда бы ни стоял выбор)
	func _input(event: InputEvent) -> void:
		if state != "ring" or not (event is InputEventJoypadButton) or not event.pressed:
			return
		if event.button_index == JOY_BUTTON_A:
			get_viewport().set_input_as_handled()
			answer()
		elif event.button_index == JOY_BUTTON_B:
			get_viewport().set_input_as_handled()
			decline()

	func _process(delta: float) -> void:
		if is_instance_valid(_hint):
			_hint.visible = (Pad.connected() and Pad.using_pad) or PadGlyph.force
		match state:
			"ring":
				_t -= delta
				_timer.text = "Сбросится через %d с" % ceili(maxf(_t, 0.0))
				var body: Control = _phone.get_node("Body")
				var buzz := fmod(RING - _t, 1.2) < 0.45            # телефон вибрирует
				body.rotation = sin(_t * 70.0) * 0.025 if buzz else 0.0
				if _t <= 0.0:
					missed()
			"talk":
				_talk -= delta
				if is_instance_valid(_pill_lbl):
					_pill_lbl.text = "Разговор: %s · 0:%02d    …бу-бу-бу… да-да… ага…" % [caller[0], ceili(maxf(_talk, 0.0))]
				if _talk <= 0.0:
					GlavKit.toast(_world, "Звонок завершён", "%s · 0:05" % caller[0], caller[3], 0.0, 1.6)
					queue_free()

	func _resume() -> void:
		if is_instance_valid(_ring):
			_ring.stop()
		if is_instance_valid(_phone):
			_phone.remove_from_group("pad_scope")
			_phone.queue_free()
		if _paused_by_me:
			_paused_by_me = false
			get_tree().paused = false

	func answer() -> void:
		if state != "ring":
			return
		state = "talk"
		_talk = TALK
		_resume()
		_voice = _player("res://audio/sfx/phone_babble.wav", -2.0)
		_voice.play()
		var vs := Config.screen(self)
		_pill = Panel.new()                                    # плашка разговора сверху
		_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pill.size = Vector2(minf(560.0, vs.x - 40.0), 40)
		_pill.position = Vector2((vs.x - _pill.size.x) / 2, 118)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.12, 0.55, 0.25, 0.92)
		st.set_corner_radius_all(20)
		_pill.add_theme_stylebox_override("panel", st)
		add_child(_pill)
		_pill_lbl = Label.new()
		_pill_lbl.size = _pill.size
		_pill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pill_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_pill_lbl.add_theme_font_size_override("font_size", 15)
		_pill_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		_pill.add_child(_pill_lbl)

	func decline() -> void:
		if state != "ring":
			return
		state = "done"
		_resume()
		GlavKit.toast(_world, caller[0], caller[2], caller[3], 0.6, 4.5)    # абонент пишет сообщение
		queue_free()

	func missed() -> void:
		if state != "ring":
			return
		state = "done"
		_resume()
		GlavKit.toast(_world, "Пропущенный вызов", caller[0], caller[3], 0.0, 2.5)
		queue_free()

	func _exit_tree() -> void:
		if _paused_by_me:
			_paused_by_me = false
			get_tree().paused = false

# Золотое сияние «Бесконечной силы» вокруг союзника
class PowerAura extends Node2D:
	var life := 7.0
	var _t := 0.0
	var _ring: Line2D

	func _ready() -> void:
		z_index = 3
		_ring = Line2D.new()
		var pts := PackedVector2Array()
		for k in 25:
			var a := TAU * k / 24.0
			pts.append(Vector2(cos(a) * 30.0, sin(a) * 9.0))
		_ring.points = pts
		_ring.width = 3.0
		_ring.default_color = Color(1.0, 0.85, 0.35, 0.85)
		add_child(_ring)

	func _process(delta: float) -> void:
		_t += delta
		life -= delta
		var par: Variant = get_parent()
		if par is Player:
			_ring.position = Vector2(0, (par as Player).body_size.y / 2 - 2)
			if randf() < 0.35:
				Fx.sparks(par.get_parent(), (par as Player).global_position + Vector2(randf_range(-16, 16), (par as Player).body_size.y * 0.3),
						Color(1.0, 0.88, 0.40), 1, 70.0, 3.0, true)
		_ring.width = 3.0 + sin(_t * 9.0) * 1.2
		_ring.modulate.a = minf(1.0, life * 2.0)
		if life <= 0.0:
			queue_free()

# Хотфикс босса: над ним строчка «кода», одна его способность на 8 с отключена
class BossFix extends Node2D:
	var boss: Player
	var key := ""
	var brain: Variant = null
	var life := 8.0
	var _lbl: Label

	func _ready() -> void:
		z_index = 9
		_lbl = Label.new()
		_lbl.text = "hotfix: boss.%s = null" % key if key != "speed" else "hotfix: boss.speed /= 2"
		_lbl.add_theme_font_size_override("font_size", 15)
		_lbl.add_theme_color_override("font_color", Color(0.60, 1.0, 0.70))
		_lbl.add_theme_constant_override("outline_size", 5)
		_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.10, 0.06))
		add_child(_lbl)
		var patch := Polygon2D.new()                            # заплатка-пластырь
		patch.polygon = PackedVector2Array([Vector2(-14, -5), Vector2(14, -5), Vector2(14, 5), Vector2(-14, 5)])
		patch.color = Color(0.95, 0.85, 0.62)
		patch.position = Vector2(-20, 11)
		patch.rotation = -0.4
		add_child(patch)
		for x in [-4.0, 4.0]:
			var dot := Polygon2D.new()
			dot.polygon = Util.circle(1.5, 5)
			dot.position = Vector2(x, 0)
			dot.color = Color(0.75, 0.62, 0.40)
			patch.add_child(dot)
		boss._float_label("Хотфикс!", Color(0.60, 1.0, 0.70))
		Fx.sparks(boss.get_parent(), boss.hurt_center(), Color(0.60, 1.0, 0.70), 12, 200.0, 3.5)

	func _physics_process(delta: float) -> void:
		life -= delta
		if not is_instance_valid(boss) or not boss.is_alive() or life <= 0.0:
			queue_free()
			return
		position = Vector2(-96, -boss.body_size.y / 2 - 50)
		if key != "speed":
			if boss.bot_abilities.has(key):
				boss._bot_cd[key] = maxf(float(boss._bot_cd.get(key, 0.0)), 0.3)   # не даём способности откатиться
			if brain != null and is_instance_valid(brain):
				var d: Variant = brain.get("_cd")
				if d is Dictionary and (d as Dictionary).has(key):
					d[key] = maxf(float(d[key]), 0.3)
		_lbl.modulate.a = 1.0 if life > 1.0 else life

# Лаги: враги то замирают, то дёргаются дальше; над ними — «ping 999 ms»
class LagFx extends Node2D:
	var targets: Array = []          # слабые ссылки на врагов
	var life := 3.0
	var _t := 0.0
	var _tags: Array = []

	func _ready() -> void:
		for w in targets:
			var e: Variant = (w as WeakRef).get_ref()
			if e:
				var l := Label.new()
				l.text = "ping 999 ms"
				l.position = Vector2(-44, -e.body_size.y / 2 - 40)
				l.add_theme_font_size_override("font_size", 14)
				l.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
				l.add_theme_constant_override("outline_size", 4)
				l.add_theme_color_override("font_outline_color", Color(0.1, 0.03, 0.03))
				e.add_child(l)
				_tags.append(weakref(l))

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		var coffee: bool = get_parent().has_meta("glav_coffee")
		var stuck := fmod(_t, 0.32) < 0.17 and life > 0.0
		if not coffee:
			for w in targets:
				var e: Variant = (w as WeakRef).get_ref()
				if e:
					e.process_mode = Node.PROCESS_MODE_DISABLED if stuck else Node.PROCESS_MODE_INHERIT
		if life <= 0.0:
			for t in _tags:
				var l: Variant = (t as WeakRef).get_ref()
				if l:
					l.queue_free()
			queue_free()

# Рекламная пауза: игра на паузе, поверх всего — реклама на 15 с; через 5 с её можно пропустить
class AdBreak extends CanvasLayer:
	const ADS := [
		{"brand": "Тяни булавку!", "type": "Мобильная игра", "slogan": "99% игроков не проходят этот уровень!", "cta": "Играть бесплатно",
			"reply": "Игра не найдена :)", "bg": [Color(0.34, 0.18, 0.58), Color(0.10, 0.05, 0.22)], "acc": Color(1.0, 0.82, 0.25)},
		{"brand": "Соедини сундуки", "type": "Мобильная игра", "slogan": "Соединяй сундуки — дойди до 999 уровня!", "cta": "Скачать",
			"reply": "Сначала доиграй бой :)", "bg": [Color(0.10, 0.48, 0.58), Color(0.03, 0.16, 0.24)], "acc": Color(0.55, 1.0, 0.75)},
		{"brand": "Сундуки обликов", "type": "Только в Лавке", "slogan": "Огненный и Ледяной сундуки: облики без повторов — по 400 G!", "cta": "В Лавку!",
			"reply": "Лавка откроется после боя :)", "bg": [Color(0.48, 0.27, 0.13), Color(0.16, 0.08, 0.04)], "acc": Color(1.0, 0.75, 0.30)},
		{"brand": "Зелья из Лавки", "type": "Только в Лавке", "slogan": "Купи три зелья — четвёртое в подарок!", "cta": "Хочу зелье",
			"reply": "Торговец уже несёт… нет :)", "bg": [Color(0.13, 0.34, 0.22), Color(0.04, 0.12, 0.08)], "acc": Color(0.95, 0.42, 0.48)},
		{"brand": "Шипучка «Мега-пузырь»", "type": "Напиток", "slogan": "Взболтай — и в бой!", "cta": "Хочу пузырь",
			"reply": "Пузырь лопнул :)", "bg": [Color(0.88, 0.38, 0.62), Color(0.34, 0.10, 0.30)], "acc": Color(1.0, 0.92, 0.42)},
	]
	const LONG := 15.0
	const SKIP_AT := 5.0
	var kind := 0
	var _t := 0.0
	var _paused_by_me := false
	var _done := false
	var _stage: AdStage
	var _skip: Button
	var _wait: Label
	var _cta: Button
	var _reply: Label

	func _ready() -> void:
		layer = 19
		process_mode = Node.PROCESS_MODE_ALWAYS
		if not get_tree().paused:
			get_tree().paused = true
			_paused_by_me = true
		var ad: Dictionary = ADS[kind]
		var vs := Config.screen(self)
		var root := Control.new()
		root.size = vs
		root.add_to_group("pad_scope")
		add_child(root)
		var dim := ColorRect.new()
		dim.size = vs
		dim.color = Color(0, 0, 0, 0.82)
		root.add_child(dim)
		var w := minf(880.0, vs.x - 30.0)
		var h := minf(580.0, vs.y - 24.0)
		var frame := Panel.new()
		frame.size = Vector2(w, h)
		frame.position = (vs - frame.size) / 2
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.06, 0.06, 0.08)
		st.border_color = Color(0.25, 0.25, 0.30)
		st.set_border_width_all(3)
		st.set_corner_radius_all(16)
		frame.add_theme_stylebox_override("panel", st)
		root.add_child(frame)
		_stage = AdStage.new()
		_stage.kind = kind
		_stage.ad = ad
		_stage.position = Vector2(12, 46)
		_stage.size = Vector2(w - 24, h - 170)
		_stage.clip_contents = true
		frame.add_child(_stage)
		var chip := Label.new()                                  # «Реклама» в углу
		chip.text = "Реклама · " + String(ad["type"])
		chip.position = Vector2(16, 10)
		chip.add_theme_font_size_override("font_size", 16)
		chip.add_theme_color_override("font_color", Color(0.75, 0.76, 0.80))
		frame.add_child(chip)
		_wait = Label.new()
		_wait.position = Vector2(w - 330, 10)
		_wait.size = Vector2(314, 26)
		_wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_wait.add_theme_font_size_override("font_size", 16)
		_wait.add_theme_color_override("font_color", Color(0.75, 0.76, 0.80))
		frame.add_child(_wait)
		_skip = Button.new()
		_skip.text = "Пропустить  »"
		_skip.size = Vector2(190, 40)
		_skip.position = Vector2(w - 206, 4)
		_skip.add_theme_font_size_override("font_size", 18)
		_skip.visible = false
		_skip.pressed.connect(finish)
		frame.add_child(_skip)
		PadGlyph.attach(_skip, "A", -1)
		var brand := Label.new()
		brand.text = ad["brand"]
		brand.position = Vector2(0, h - 120)
		brand.size = Vector2(w, 40)
		brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		brand.add_theme_font_size_override("font_size", 30)
		brand.add_theme_color_override("font_color", ad["acc"])
		frame.add_child(brand)
		var slogan := Label.new()
		slogan.text = ad["slogan"]
		slogan.position = Vector2(0, h - 82)
		slogan.size = Vector2(w, 26)
		slogan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slogan.add_theme_font_size_override("font_size", 18)
		slogan.add_theme_color_override("font_color", Color(0.95, 0.95, 0.97))
		frame.add_child(slogan)
		_cta = Button.new()
		_cta.text = ad["cta"]
		_cta.size = Vector2(280, 46)
		_cta.position = Vector2((w - 280) / 2, h - 52)
		_cta.pivot_offset = _cta.size / 2
		_cta.focus_mode = Control.FOCUS_NONE
		_cta.add_theme_font_size_override("font_size", 20)
		var cst := StyleBoxFlat.new()
		cst.bg_color = ad["acc"]
		cst.set_corner_radius_all(23)
		for s in ["normal", "hover", "pressed"]:
			_cta.add_theme_stylebox_override(s, cst)
		_cta.add_theme_color_override("font_color", Color(0.10, 0.08, 0.12))
		_cta.add_theme_color_override("font_hover_color", Color(0.10, 0.08, 0.12))
		_cta.add_theme_color_override("font_pressed_color", Color(0.10, 0.08, 0.12))
		_cta.pressed.connect(func():
			_reply.text = String(ad["reply"])
			_reply.modulate.a = 1.0
			_cta.rotation = 0.08)
		frame.add_child(_cta)
		_reply = Label.new()
		_reply.position = Vector2(w / 2 + 150, h - 46)
		_reply.add_theme_font_size_override("font_size", 15)
		_reply.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		_reply.modulate.a = 0.0
		frame.add_child(_reply)
		Audio.sfx("buff")

	# геймпад: A или B — пропустить (когда уже можно)
	func _input(event: InputEvent) -> void:
		if _done or not (event is InputEventJoypadButton) or not event.pressed:
			return
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B]:
			get_viewport().set_input_as_handled()
			if _t >= SKIP_AT:
				finish()

	func _process(delta: float) -> void:
		if _done:
			return
		_t += delta
		_stage.t = _t
		_stage.queue_redraw()
		_skip.visible = _t >= SKIP_AT
		if _t < SKIP_AT:
			_wait.text = "Пропустить через %d" % ceili(SKIP_AT - _t)
		else:
			_wait.text = ""
			if not _skip.has_focus():
				_skip.grab_focus()
		_cta.scale = Vector2.ONE * (1.0 + 0.05 * sin(_t * 6.0))
		_cta.rotation = move_toward(_cta.rotation, 0.0, delta * 0.5) * (-1.0 if fmod(_t, 0.1) < 0.05 else 1.0)
		_reply.modulate.a = maxf(0.0, _reply.modulate.a - delta * 0.4)
		if _t >= LONG:
			finish()

	func finish() -> void:
		if _done:
			return
		_done = true
		if _paused_by_me:
			_paused_by_me = false
			get_tree().paused = false
		queue_free()

	func _exit_tree() -> void:
		if _paused_by_me:
			_paused_by_me = false
			get_tree().paused = false

# Картинка рекламы: рисуется кодом и всё время двигается (t — секунды с начала)
class AdStage extends Control:
	var kind := 0
	var ad: Dictionary = {}
	var t := 0.0

	func _txt(pos: Vector2, s: String, fs: int, c: Color, w := -1.0) -> void:
		var f := get_theme_default_font()
		var ww := size.x if w < 0.0 else w
		draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_CENTER, ww, fs, 8, Color(0.05, 0.03, 0.08, 0.9))
		draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_CENTER, ww, fs, c)

	func _bg() -> void:
		var c0: Color = ad["bg"][0]
		var c1: Color = ad["bg"][1]
		for k in 12:
			draw_rect(Rect2(0, size.y * k / 12.0, size.x, size.y / 12.0 + 1.0), c0.lerp(c1, k / 11.0))
		for k in 7:                                              # лучи из центра медленно крутятся
			var a := t * 0.25 + TAU * k / 7.0
			var cc := size / 2
			draw_colored_polygon(PackedVector2Array([cc, cc + Vector2.from_angle(a) * 900.0, cc + Vector2.from_angle(a + 0.22) * 900.0]),
					Color(1, 1, 1, 0.05))

	func _chest(c: Vector2, s: float, col: Color, lid := 0.0) -> void:
		draw_rect(Rect2(c + Vector2(-26, -10) * s, Vector2(52, 30) * s), col)
		draw_rect(Rect2(c + Vector2(-26, -10) * s, Vector2(52, 4) * s), col.darkened(0.3))
		draw_rect(Rect2(c + Vector2(-4, -6) * s, Vector2(8, 9) * s), Color(1.0, 0.85, 0.35))
		var hinge := c + Vector2(-26, -10) * s
		var pts := PackedVector2Array()
		for v in [Vector2(0, 0), Vector2(52, 0), Vector2(52, -14), Vector2(0, -14)]:
			pts.append(hinge + (v * s).rotated(-lid))
		draw_colored_polygon(pts, col.lightened(0.12))
		for x in [6.0, 44.0]:
			draw_rect(Rect2(c + Vector2(-26 + x, -10) * s, Vector2(3, 30) * s), col.darkened(0.4))

	func _draw() -> void:
		_bg()
		match kind:
			0: _pins()
			1: _merge()
			2: _chests()
			3: _potions()
			_: _soda()

	# «Тяни булавку!»: выдернул не ту — лава на гнома. Классика.
	func _pins() -> void:
		var W := size.x
		var H := size.y
		var lt := fmod(t, 6.0)
		var x0 := W * 0.5 - 140.0
		var x1 := W * 0.5 + 140.0
		var y0 := 24.0
		var y1 := H - 16.0
		var py := y0 + (y1 - y0) * 0.48
		var stone := Color(0.55, 0.52, 0.60)
		draw_rect(Rect2(x0 - 14, y0, 14, y1 - y0), stone)
		draw_rect(Rect2(x1, y0, 14, y1 - y0), stone)
		draw_rect(Rect2(x0 - 14, y1, x1 - x0 + 28, 12), stone.darkened(0.2))
		draw_rect(Rect2(W * 0.5 - 5, y0, 10, py - y0), stone)
		draw_rect(Rect2(x0, py + 8, x1 - x0, y1 - py - 8), Color(0, 0, 0, 0.25))
		var pull_a: float = clampf((lt - 1.0) / 0.5, 0.0, 1.0) * 330.0 if lt < 5.8 else 0.0
		var pull_b: float = clampf((lt - 4.6) / 0.4, 0.0, 1.0) * 30.0 if lt < 5.8 else 0.0
		var gold := Color(1.0, 0.80, 0.25)
		draw_rect(Rect2(x0 - pull_a, py, W * 0.5 - x0, 8), gold)              # булавка A (под лавой)
		draw_circle(Vector2(x0 - 26 - pull_a, py + 4), 11.0, gold)
		draw_rect(Rect2(W * 0.5 + pull_b, py, x1 - W * 0.5, 8), gold)          # булавка B (под монетами)
		draw_circle(Vector2(x1 + 26 + pull_b, py + 4), 11.0, gold)
		# лава слева: падает, когда выдернули A
		var fall: float = maxf(0.0, lt - 1.3)
		for i in 15:
			var bx := x0 + 18.0 + (i % 5) * 24.0
			var by := py - 14.0 - (i / 5) * 22.0
			var dy: float = minf(fall * fall * 900.0, y1 - 22.0 - (2 - i / 5) * 14.0 - by) if lt < 5.8 else 0.0
			draw_circle(Vector2(bx + (sin(i * 3.1) * dy * 0.12), by + dy), 13.0, Color(1.0, 0.35 + 0.15 * (i % 3), 0.08))
		for i in 10:                                                         # монеты справа
			draw_circle(Vector2(W * 0.5 + 22.0 + (i % 5) * 24.0, py - 14.0 - (i / 5) * 22.0), 10.0, Color(1.0, 0.85, 0.25))
			draw_circle(Vector2(W * 0.5 + 19.0 + (i % 5) * 24.0, py - 17.0 - (i / 5) * 22.0), 3.0, Color(1.0, 1.0, 0.8))
		# гном
		var g := Vector2(W * 0.5, y1 - 30.0)
		var burnt := lt > 2.1 and lt < 5.8
		draw_rect(Rect2(g + Vector2(-14, -4), Vector2(28, 30)), Color(0.15, 0.12, 0.12) if burnt else Color(0.25, 0.45, 0.85))
		draw_circle(g + Vector2(0, -16), 14.0, Color(0.25, 0.20, 0.18) if burnt else Color(0.98, 0.80, 0.68))
		draw_colored_polygon(PackedVector2Array([g + Vector2(-14, -24), g + Vector2(14, -24), g + Vector2(0, -56)]), Color(0.85, 0.15, 0.15) if not burnt else Color(0.3, 0.1, 0.1))
		if burnt:
			for s in [-1.0, 1.0]:
				draw_line(g + Vector2(s * 6 - 3, -20), g + Vector2(s * 6 + 3, -14), Color(1, 1, 1), 2.0)
				draw_line(g + Vector2(s * 6 + 3, -20), g + Vector2(s * 6 - 3, -14), Color(1, 1, 1), 2.0)
		else:
			draw_circle(g + Vector2(-5, -17), 2.0, Color(0.1, 0.1, 0.1))
			draw_circle(g + Vector2(5, -17), 2.0, Color(0.1, 0.1, 0.1))
			_txt(g + Vector2(-W * 0.5 + 80.0, -66), "ПОМОГИ!", 20, Color(1, 1, 1))
		# «рука» игрока
		var knob_a := Vector2(x0 - 26 - pull_a, py + 4)
		var knob_b := Vector2(x1 + 26 + pull_b, py + 4)
		var hand := Vector2(W * 0.86, H * 0.92)
		if lt < 1.0:
			hand = hand.lerp(knob_a, lt)
		elif lt < 4.0:
			hand = knob_a
		else:
			hand = knob_a.lerp(knob_b, clampf((lt - 4.0) / 0.6, 0.0, 1.0))
		draw_circle(hand + Vector2(10, 14), 13.0, Color(1, 1, 1))
		draw_rect(Rect2(hand + Vector2(4, -4), Vector2(8, 18)), Color(1, 1, 1))
		if lt > 2.4 and lt < 4.0:
			_txt(Vector2(0, H * 0.30), "ПРОВАЛ!", int(54 + 6 * sin(t * 12.0)), Color(1.0, 0.30, 0.25))
		elif lt >= 4.0 and lt < 5.8:
			_txt(Vector2(0, H * 0.30), "А ТЫ СМОЖЕШЬ?", 40, Color(1.0, 0.90, 0.35))

	# «Соедини сундуки»: два одинаковых сундука сливаются в сундук побольше
	func _merge() -> void:
		var W := size.x
		var H := size.y
		var cols := [Color(0.55, 0.36, 0.18), Color(0.62, 0.65, 0.72), Color(0.95, 0.75, 0.25), Color(0.60, 0.35, 0.90), Color(0.30, 0.85, 0.90)]
		for r in 2:                                                         # поле с сундуками внизу
			for c in 7:
				var cell := Vector2(W * 0.5 + (c - 3) * 74.0, H - 70.0 + r * 0.0 - r * 66.0)
				draw_rect(Rect2(cell - Vector2(32, 30), Vector2(64, 60)), Color(1, 1, 1, 0.08))
				if (c + r * 3) % 3 != 0:
					_chest(cell + Vector2(0, 6), 0.75, cols[(c * 3 + r) % 3])
		var cyc := 1.6
		var tier := int(t / cyc) % 4
		var k := fmod(t, cyc) / cyc
		var cen := Vector2(W * 0.5, H * 0.36)
		if k < 0.45:
			var d := lerpf(170.0, 0.0, ease(k / 0.45, 2.0))
			_chest(cen + Vector2(-d, 0), 1.4, cols[tier])
			_chest(cen + Vector2(d, 0), 1.4, cols[tier])
		elif k < 0.58:
			draw_circle(cen, 70.0 * (k - 0.45) / 0.13 + 20.0, Color(1, 1, 1, 0.9))
		else:
			var pop := 1.9 + 0.35 * sin(minf(1.0, (k - 0.58) / 0.2) * PI)
			_chest(cen, pop, cols[tier + 1], 0.0)
			for s in 8:
				var a := TAU * s / 8.0 + t
				draw_circle(cen + Vector2.from_angle(a) * (90.0 + 30.0 * (k - 0.58)), 4.0, Color(1.0, 1.0, 0.7))
			_txt(cen + Vector2(-W * 0.5, -70), "+1", 36, Color(0.55, 1.0, 0.75))
		_txt(Vector2(0, 40), "УРОВЕНЬ %d" % (995 + tier + (1 if k >= 0.58 else 0)), 30, Color(1, 1, 1))

	# Сундуки обликов из Лавки: огненный и ледяной прыгают и открываются
	func _chests() -> void:
		var W := size.x
		var H := size.y
		draw_rect(Rect2(0, H * 0.72, W, 10), Color(0.30, 0.17, 0.08))
		for i in 2:
			var ice := i == 1
			var ph := float(i) * 1.6
			var c := Vector2(W * (0.32 + 0.36 * i), H * 0.66 - absf(sin(t * 3.0 + ph)) * 18.0)
			var open := clampf(sin(t * 1.4 + ph) * 1.8, 0.0, 1.0)
			if open > 0.05:
				for r in 9:                                              # свет из сундука
					var a := -PI / 2 + (r - 4) * 0.17
					draw_colored_polygon(PackedVector2Array([c + Vector2(0, -30), c + Vector2(0, -30) + Vector2.from_angle(a - 0.05) * 220.0 * open,
							c + Vector2(0, -30) + Vector2.from_angle(a + 0.05) * 220.0 * open]),
							Color(0.6, 0.9, 1.0, 0.18) if ice else Color(1.0, 0.7, 0.3, 0.18))
				var fig := c + Vector2(0, -40 - 60 * open)               # облик поднимается из сундука
				draw_circle(fig + Vector2(0, -26), 11.0, Color(1, 1, 1, 0.85 * open))
				draw_rect(Rect2(fig + Vector2(-11, -14), Vector2(22, 34)), Color(1, 1, 1, 0.85 * open))
				for p2 in 6:
					var q := fmod(t * 0.9 + p2 / 6.0 + ph, 1.0)
					var pp := c + Vector2(sin(p2 * 2.3 + t) * 40.0, -30 - q * 150.0)
					if ice:
						draw_line(pp + Vector2(-5, 0), pp + Vector2(5, 0), Color(0.85, 0.97, 1.0, 1.0 - q), 2.0)
						draw_line(pp + Vector2(0, -5), pp + Vector2(0, 5), Color(0.85, 0.97, 1.0, 1.0 - q), 2.0)
					else:
						draw_colored_polygon(PackedVector2Array([pp + Vector2(-5, 4), pp + Vector2(0, -9), pp + Vector2(5, 4)]), Color(1.0, 0.55 + 0.3 * (p2 % 2), 0.15, 1.0 - q))
			_chest(c, 2.2, Color(0.32, 0.55, 0.82) if ice else Color(0.85, 0.32, 0.10), open * 1.1)
			draw_rect(Rect2(c + Vector2(-46, 62), Vector2(92, 34)), Color(1.0, 0.95, 0.80))
			_txt(c + Vector2(-46, 87), "400 G", 22, Color(0.45, 0.25, 0.08), 92.0)
		# «НОВИНКА!» — крутящаяся звезда
		var sc := Vector2(W - 90.0, 70.0)
		var star := PackedVector2Array()
		for s in 24:
			star.append(sc + Vector2.from_angle(t * 0.8 + TAU * s / 24.0) * (54.0 if s % 2 == 0 else 42.0))
		draw_colored_polygon(star, Color(0.95, 0.20, 0.25))
		_txt(sc + Vector2(-60, 7), "НОВИНКА!", 17, Color(1, 1, 1), 120.0)

	# Зелья из Лавки: четыре склянки покачиваются и булькают
	func _potions() -> void:
		var W := size.x
		var H := size.y
		var cols := [Color(0.92, 0.22, 0.28), Color(0.28, 0.52, 1.0), Color(0.32, 0.86, 0.38), Color(0.92, 0.76, 0.22)]
		for i in 4:
			var c := Vector2(W * (0.2 + 0.2 * i), H * 0.58 + sin(t * 2.2 + i) * 10.0)
			draw_rect(Rect2(c + Vector2(-9, -78), Vector2(18, 34)), Color(0.85, 0.92, 1.0, 0.45))     # горлышко
			draw_rect(Rect2(c + Vector2(-11, -90), Vector2(22, 14)), Color(0.55, 0.35, 0.18))       # пробка
			draw_circle(c, 46.0, Color(0.85, 0.92, 1.0, 0.35))
			draw_circle(c + Vector2(0, 6), 40.0, cols[i])
			draw_circle(c + Vector2(-14, -12), 9.0, Color(1, 1, 1, 0.55))
			for b in 5:                                                       # пузырьки
				var q := fmod(t * 0.7 + b * 0.2 + i * 0.13, 1.0)
				draw_circle(c + Vector2(sin(b * 2.0 + t * 3.0) * 6.0, 20.0 - q * 110.0), 3.0 + b % 2, Color(1, 1, 1, 0.8 * (1.0 - q)))
		for hh in 4:                                                          # сердечки от красного зелья
			var q2 := fmod(t * 0.5 + hh * 0.25, 1.0)
			var hp := Vector2(W * 0.2 + sin(hh * 1.7 + t) * 30.0, H * 0.4 - q2 * 140.0)
			var s := 9.0
			draw_circle(hp + Vector2(-s * 0.5, 0), s * 0.6, Color(1.0, 0.35, 0.45, 1.0 - q2))
			draw_circle(hp + Vector2(s * 0.5, 0), s * 0.6, Color(1.0, 0.35, 0.45, 1.0 - q2))
			draw_colored_polygon(PackedVector2Array([hp + Vector2(-s * 1.05, 2), hp + Vector2(s * 1.05, 2), hp + Vector2(0, s * 1.3)]), Color(1.0, 0.35, 0.45, 1.0 - q2))
		var sc := Vector2(W - 80.0, 66.0)
		var star := PackedVector2Array()
		for k in 20:
			star.append(sc + Vector2.from_angle(-t + TAU * k / 20.0) * (52.0 if k % 2 == 0 else 40.0))
		draw_colored_polygon(star, Color(1.0, 0.85, 0.25))
		_txt(sc + Vector2(-50, 12), "3+1", 32, Color(0.6, 0.1, 0.1), 100.0)

	# «Мега-пузырь»: бутылку трясут — крышка улетает — фонтан пузырей
	func _soda() -> void:
		var W := size.x
		var H := size.y
		var lt := fmod(t, 4.0)
		var shake := sin(lt * 45.0) * lt * 5.0 if lt < 2.0 else 0.0
		var b := Vector2(W * 0.5 + shake, H * 0.62)
		draw_rect(Rect2(b + Vector2(-38, -80), Vector2(76, 150)), Color(0.80, 0.95, 1.0, 0.45))     # бутылка
		draw_rect(Rect2(b + Vector2(-32, -40), Vector2(64, 106)), Color(1.0, 0.50, 0.75))           # шипучка
		draw_rect(Rect2(b + Vector2(-16, -112), Vector2(32, 34)), Color(0.80, 0.95, 1.0, 0.45))     # горлышко
		draw_rect(Rect2(b + Vector2(-38, -10), Vector2(76, 32)), Color(1.0, 0.92, 0.42))            # этикетка
		_txt(b + Vector2(-38, 13), "МЕГА", 20, Color(0.75, 0.15, 0.45), 76.0)
		for k in 8:
			var q := fmod(lt * (0.6 + lt * 0.6) + k * 0.125, 1.0)
			draw_circle(b + Vector2(sin(k * 1.9) * 22.0, 60.0 - q * 100.0), 3.5, Color(1, 1, 1, 0.7))
		var neck := b + Vector2(0, -112)
		if lt < 2.0:
			draw_rect(Rect2(neck + Vector2(-19, -12), Vector2(38, 14)), Color(0.90, 0.15, 0.20))       # крышка
		else:
			var u := lt - 2.0
			var cap := neck + Vector2(u * 120.0, -u * 520.0 + u * u * 700.0)
			draw_set_transform(cap, u * 12.0, Vector2.ONE)
			draw_rect(Rect2(Vector2(-19, -7), Vector2(38, 14)), Color(0.90, 0.15, 0.20))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for j in 46:                                                      # фонтан пузырей
				var q2 := fmod(u * 1.3 + j / 46.0, 1.0)
				var pp := neck + Vector2(sin(j * 12.9) * q2 * 170.0, -q2 * 330.0 + q2 * q2 * 300.0)
				draw_circle(pp, 4.0 + (j % 4) * 2.0, Color(1.0, 0.75 + 0.25 * (j % 2), 0.90, 1.0 - q2 * 0.8))
			if u < 0.7:
				_txt(Vector2(0, H * 0.22), "ПШШШ!", 56, Color(1.0, 0.95, 0.50))
