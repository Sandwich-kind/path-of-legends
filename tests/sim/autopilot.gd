extends Node
# Автопилот героя для замеров баланса: жмёт те же кнопки, что и игрок
# (p1_left/right/jump/shoot/a1..a3/ult). Не уворачивается намеренно — «средний игрок»:
# держит дистанцию своего типа, стреляет, жмёт способности по готовности,
# изредка прыгает и запрыгивает к цели на платформы.

var p: Player
var prefix := "p1"
var want_dist := 420.0          # ближний бой — меньше
var hold_shoot := 0.0           # сколько держать «огонь» до отпускания (луки с натяжкой)
var _held := {}
var _shoot_t := 0.0
var _ab_t := 0.0
var _jump_t := 0.0
var _kite_t := 0.0
var rng := RandomNumberGenerator.new()
var enabled := true
var duel := false               # Дуэль: цель — легенда соперника, карта любой ширины, умеет спрыгивать вниз
var dist_override := -1.0       # держать именно эту дистанцию (замер дальности, tests/sim_duel_range.gd)
var _stuck_t := 0.0

const MELEE := {"smith": 95.0, "samurai": 70.0, "assassin": 70.0, "rassvet": 85.0, "champion": 260.0}
# Лучшая дистанция в Дуэли — из замера tests/sim_duel_range.gd (урон по стоящей цели с разных дистанций)
const DUEL_DIST := {"hunter": 360.0, "smith": 130.0, "champion": 200.0, "ternovnik": 450.0, "mortis": 360.0, "soldier": 560.0,
		"samurai": 130.0, "assassin": 130.0, "prism": 560.0, "osoka": 70.0, "zarnitsa": 130.0, "rassvet": 200.0, "pivozavr": 360.0,
		"gatekeeper": 130.0, "echo": 200.0, "seam": 450.0, "glav": 560.0, "genius": 280.0, "scribe": 130.0, "dj": 450.0, "almost": 70.0}
const CHARGE := {"hunter": 0.45, "glav": 0.9, "almost": 0.75}   # Главный: взболтать и отпустить — луч; Почти легенда — заряженный кулак

func setup(hero: Player, seed_v := 1) -> void:
	p = hero
	prefix = hero.prefix
	rng.seed = seed_v
	var key := Balance.hero_key(p)
	want_dist = MELEE.get(key, 420.0)
	hold_shoot = CHARGE.get(key, 0.0)
	process_physics_priority = -100      # раньше героя: «только что нажато» видно в этом же кадре

func _key(action: String, on: bool) -> void:
	var a := prefix + "_" + action
	# нажатие могло «слететь» (окно потеряло фокус — движок отпускает все кнопки): жмём заново
	if on and (not _held.get(a, false) or not Input.is_action_pressed(a)):
		Input.action_press(a)
		_held[a] = true
	elif not on and _held.get(a, false):
		Input.action_release(a)
		_held[a] = false

func release_all() -> void:
	for a in _held.keys():
		if _held[a]:
			Input.action_release(a)
	_held.clear()

func _target() -> Node2D:
	var best: Node2D = null
	var bd := INF
	if duel:
		# в Дуэли цель — сам соперник; его призванные — только пока он не вернулся в бой
		for n in p.get_parent().get_children():
			if n is Player and n.team != p.team and n.is_alive() and not n.is_queued_for_deletion():
				var dd := p.global_position.distance_squared_to(n.global_position)
				if not n.is_bot:
					return n
				if dd < bd:
					bd = dd
					best = n
		return best
	for n in p.get_parent().get_children():
		if n is Player and n.team != p.team and n.is_alive() and not n.cutscene_shield and n.get_meta("kind", "") != "":
			var d := p.global_position.distance_squared_to(n.global_position)
			if n.get_meta("kind", "") == "totem":
				d *= 0.5                    # тотемы Энта — в приоритете
			if d < bd:
				bd = d
				best = n
	return best

func _physics_process(delta: float) -> void:
	if not enabled or p == null or not is_instance_valid(p) or not p.is_alive():
		release_all()
		return
	var t := _target()
	# одиночные нажатия прошлого кадра отпускаем
	for a in ["jump", "a1", "a2", "a3", "ult"]:
		_key(a, false)
	if t == null:
		_key("left", false)
		_key("right", false)
		_key("shoot", false)
		return
	var dx: float = t.global_position.x - p.global_position.x
	var dy: float = t.global_position.y - p.global_position.y
	var adx := absf(dx)
	# DJ Клима: во время «Лютого слэма» лезет в самую толпу (иначе волны мимо)
	want_dist = 60.0 if p.kit and p.kit.has_method("slamming") and p.kit.slamming() else MELEE.get(Balance.hero_key(p), 420.0)
	if duel and not (p.kit and p.kit.has_method("slamming") and p.kit.slamming()):
		# в Дуэли нет доводки снарядов: у каждой легенды своя дистанция, с которой она попадает
		want_dist = float(DUEL_DIST.get(Balance.hero_key(p), want_dist))
	if dist_override >= 0.0:
		want_dist = dist_override
	var side := 1 if dx > 0 else -1
	var move := 0
	var x: float = p.global_position.x
	var near_wall := x < Colosseum.WALL + 160.0 or x > Colosseum.W - Colosseum.WALL - 160.0
	if duel:
		near_wall = x < 200.0 or x > p.map_w - 200.0
	_kite_t -= delta
	if adx > want_dist + 40.0:
		move = side
		_kite_t = 0.0
	elif adx < want_dist * 0.5 and want_dist > 200.0 and not near_wall:
		# дальнобойный «кайтит»: отбежал — развернулся — пострелял — снова отбежал
		if _kite_t <= -0.55:
			_kite_t = 0.5
		if _kite_t > 0.0:
			move = -side
	if move == 0 and p.facing != side:
		move = side                      # развернуться к цели
	_key("right", move > 0)
	_key("left", move < 0)
	if duel:
		_key("down", false)
		# цель ниже — спрыгнуть со сквозной платформы; упёрся в ящик или колонну — перепрыгнуть
		if dy > 100.0 and adx < 320.0 and p.is_on_floor():
			_key("down", true)
		if move != 0 and absf(p.velocity.x) < 25.0:
			_stuck_t += delta
			if _stuck_t > 0.3:
				_key("jump", true)
				_stuck_t = 0.0
		else:
			_stuck_t = 0.0
	# запрыгнуть к цели на платформу / уйти от наземных атак
	_jump_t -= delta
	if _jump_t <= 0.0:
		if dy < -110.0 and adx < 500.0:
			_key("jump", true)
			_jump_t = 0.45
		elif rng.randf() < 0.18:
			_key("jump", true)
			_jump_t = 0.9
		else:
			_jump_t = 0.3
	# огонь
	var facing_ok: bool = p.facing == side
	if hold_shoot > 0.0:
		_shoot_t += delta
		if _shoot_t < hold_shoot:
			_key("shoot", facing_ok)
		else:
			_key("shoot", false)
			_shoot_t = -0.05
	else:
		_key("shoot", facing_ok and adx < 1300.0)
	# способности — по готовности, когда цель рядом
	_ab_t -= delta
	if _ab_t <= 0.0 and adx < 900.0:
		_ab_t = 0.35
		for i in 3:
			if p._cd[i] <= 0.0 and p.abilities[i] != "" and facing_ok:
				_key("a%d" % (i + 1), true)
				break
		if p.ult != "" and p.ult_charge >= p.ult_need and adx < 700.0:
			_key("ult", true)
