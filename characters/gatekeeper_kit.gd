class_name GatekeeperKit
extends HeroKit
# ---------- ПРИВРАТНИЦА — легенда за Предвестника (90-я волна Арены) ----------
# Хранительница, что закрывает разломы. Посох-ключ, порталы, цепи и печати.
# Оружие «Посох-ключ»: лучи-скобы летят прямо. Каждое 4-е попадание «запирает»
#   врага — на 1,2 с он сильно замедлен (над головой — замок).
# 1 «Парные врата» — два портала: под Привратницей и впереди. Сквозь них проходят
#   герои, враги и снаряды — вошёл в один, вышел из другого с той же скоростью.
#   МЕГА: врата стоят дольше, враги, прошедшие сквозь них, получают урон и замедлены.
#   Арена: врата стоят дольше.
# 2 «Цепь-замок» — сковывает двух ближайших врагов: половина урона по одному
#   достаётся и другому, а цепь стягивает их друг к другу. МЕГА: до 4 врагов.
#   Арена: цепь держится дольше.
# 3 «Схлопывание» — бросает ключ вперёд: там пространство сжимается в точку,
#   стягивает врагов и взрывается. МЕГА: шире и оглушает. Арена: шире и сильнее.
# Ульта «Запечатывание» — круг печати вокруг Привратницы: все враги внутри замирают
#   (Дуэль 2 с, Арена 3 с), а когда печать спадает — получают ещё половину урона,
#   нанесённого им за это время. МЕГА: замирают дольше, отдача — весь накопленный урон.

const GOLD := Color(1.0, 0.82, 0.38)
const VIOLET := Color(0.70, 0.45, 1.0)
const DEEP := Color(0.16, 0.12, 0.34)
const LOCK_EVERY := 4
const GATE_DIST := 460.0

var _hits := 0
var _gates: GatePair
var _chain: LockChain
var _seal: Seal

# ---------- Стрельба: лучи-скобы ----------
func weapon(delta: float, shoot: bool) -> void:
	var rapid := p.has_buff("rapid")
	if p._reloading > 0.0:
		p._reloading -= delta
		if p._reloading <= 0.0:
			p._reloading = 0.0
			p.ammo = p.clip_size
	elif not p.is_bot and Input.is_action_just_pressed(p.prefix + "_reload") and p.ammo < p.clip_size:
		p._reloading = p.reload_time
	if rapid:
		p._reloading = 0.0
		p.ammo = p.clip_size
	if not shoot or p._cooldown_left > 0.0 or p._reloading > 0.0:
		return
	p.bullet_style = "key"
	var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, 0.0)
	b.global_position = p.global_position + Vector2(p.facing * 28.0, -6.0)   # из навершия посоха на уровне груди
	b.color = Skins.col(p, GOLD)
	b.on_hit = _key_hit
	if rapid and p.is_mega("rapid"):
		b.pierce = 2
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

func _key_hit(victim: Node) -> void:
	if not is_instance_valid(p) or not (victim is Player) or not victim.is_alive():
		return
	_hits += 1
	if _hits % LOCK_EVERY != 0:
		return
	lock(victim, 1.2)

# «Запереть» врага: сильное замедление и замок над головой
static func lock(e: Player, t: float) -> void:
	e.slow(t, 0.35, "water")
	var world := e.get_parent()
	var icon := LockIcon.new()
	icon.target = e
	icon.life = t
	world.add_child(icon)
	Fx.ring(world, e.hurt_center(), 46.0, Color(GOLD, 0.9), 0.3, 4.0)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"gate_pair":
			_open_gates(mega)
		"lock_chain":
			_cast_chain(mega)
		"collapse":
			_throw_key(mega)

# ---------- 1. Парные врата ----------
func _open_gates(mega: bool) -> void:
	if is_instance_valid(_gates):
		_gates.close()
	var world := p.get_parent()
	var feet_y := p.global_position.y + p.body_size.y / 2
	var a := Vector2(p.global_position.x, feet_y - GatePair.H / 2)
	var bx := clampf(p.global_position.x + p.facing * GATE_DIST, 90.0, p.map_w - 90.0)
	# впереди стена — врата встают перед ней
	var space := p.get_world_2d().direct_space_state
	var wall := space.intersect_ray(PhysicsRayQueryParameters2D.create(p.global_position, Vector2(bx, p.global_position.y), Layer.FRAME, [p.get_rid()]))
	if not wall.is_empty():
		bx = wall["position"].x - p.facing * 50.0
	var b := Vector2(bx, a.y)
	var down := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(bx, a.y - 120.0), Vector2(bx, a.y + 900.0), Layer.WORLD | Layer.FRAME))
	if not down.is_empty():
		b.y = down["position"].y - GatePair.H / 2
	p._anim("cast")
	var g := GatePair.new()
	g.owner_p = p
	g.team = p.team
	g.mega = mega
	g.a = a
	g.b = b
	var arena := Balance.arena(p)
	g.life = (12.0 if arena else 9.0) if mega else (8.0 if arena else 6.0)
	world.add_child(g)
	_gates = g

# ---------- 2. Цепь-замок ----------
func _cast_chain(mega: bool) -> void:
	var arena := Balance.arena(p)
	var foes: Array = []
	for e in _enemies():
		if e.cutscene_shield or e.get_meta("kind", "") == "totem":
			continue
		if e.global_position.distance_to(p.global_position) < (760.0 if arena else 650.0):
			foes.append(e)
	foes.sort_custom(func(x, y): return x.global_position.distance_squared_to(p.global_position) < y.global_position.distance_squared_to(p.global_position))
	var n := 4 if mega else 2
	foes = foes.slice(0, n)
	p._anim("cast")
	if foes.is_empty():
		Fx.ring(p.get_parent(), p.hurt_center(), 60.0, Color(Skins.col(p, GOLD), 0.6), 0.3, 4.0)
		return
	if is_instance_valid(_chain):
		_chain.finish()
	if foes.size() == 1:
		# враг один (Дуэль): цепь приковывает его к земле
		var e: Player = foes[0]
		e.root(2.0 if mega else 1.4)
		GatekeeperKit.lock(e, 2.0 if mega else 1.4)
		var anchor := AnchorChain.new()
		anchor.target = e
		anchor.life = 2.0 if mega else 1.4
		p.get_parent().add_child(anchor)
		return
	var c := LockChain.new()
	c.owner_p = p
	c.links = foes
	c.life = 5.5 if arena else 4.0
	p.get_parent().add_child(c)
	_chain = c

# ---------- 3. Схлопывание ----------
func _throw_key(mega: bool) -> void:
	var arena := Balance.arena(p)
	var world := p.get_parent()
	var from: Vector2 = p.global_position + Vector2(p.facing * 20.0, -20.0)
	# цель — ближайший враг впереди, иначе точка впереди на уровне героя
	var to := p.global_position + Vector2(p.facing * 430.0, -10.0)
	var bd := 760.0
	for e in _enemies():
		var dx: float = e.global_position.x - p.global_position.x
		if signf(dx) == float(p.facing) and absf(e.global_position.y - p.global_position.y) < 360.0 and absf(dx) < bd:
			bd = absf(dx)
			to = e.hurt_center()
	p._anim("throw")
	var k := Collapse.new()
	k.owner_p = p
	k.team = p.team
	k.mega = mega
	k.radius = (320.0 if arena else 260.0) * (1.5 if mega else 1.0)
	k.damage = 34 if arena else 28
	k.from = from
	k.to = to
	world.add_child(k)

# ---------- Ульта: Запечатывание ----------
func ult() -> void:
	if is_instance_valid(_seal):
		return
	p._anim("roar")
	var s := Seal.new()
	s.owner_p = p
	s.mega = p._mega_ab()
	var arena := Balance.arena(p)
	s.radius = 470.0 if arena else 380.0
	s.hold = (3.0 if arena else 2.0) + (1.5 if s.mega else 0.0)
	s.echo = 1.0 if s.mega else 0.5
	s.position = p.global_position
	p.get_parent().add_child(s)
	_seal = s

func ulting() -> bool:
	return is_instance_valid(_seal)

func on_death() -> void:
	super()
	if is_instance_valid(_gates):
		_gates.close()
	if is_instance_valid(_chain):
		_chain.finish()


# =====================================================================
# Замок над головой «запертого» врага
class LockIcon extends Node2D:
	var target: Player
	var life := 1.2
	var _t := 0.0

	func _ready() -> void:
		z_index = 12
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([Vector2(-9, -2), Vector2(9, -2), Vector2(9, 12), Vector2(-9, 12)])
		body.color = Color(1.0, 0.82, 0.38)
		add_child(body)
		var shackle := Line2D.new()
		var pts := PackedVector2Array()
		for i in 9:
			pts.append(Vector2(cos(PI + PI * i / 8.0) * 6.0, -2.0 + sin(PI + PI * i / 8.0) * 8.0))
		shackle.points = pts
		shackle.width = 3.0
		shackle.default_color = Color(0.85, 0.85, 0.92)
		add_child(shackle)
		var hole := Polygon2D.new()
		hole.polygon = PackedVector2Array([Vector2(-2, 2), Vector2(2, 2), Vector2(1, 9), Vector2(-1, 9)])
		hole.color = Color(0.16, 0.12, 0.34)
		add_child(hole)

	func _process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(target) or not target.is_alive() or _t >= life:
			queue_free()
			return
		global_position = target.global_position + Vector2(0, -target.body_size.y / 2 - 30.0 - target.bar_lift)
		scale = Vector2.ONE * (1.0 + 0.12 * sin(_t * 12.0))
		modulate.a = 1.0 if _t < life - 0.25 else (life - _t) / 0.25


# =====================================================================
# Парные врата: два овальных портала; всё, что входит в один, выходит из другого
class GatePair extends Node2D:
	const H := 120.0
	const W := 64.0
	var owner_p: Player
	var team := 0
	var mega := false
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var life := 6.0
	var _t := 0.0
	var _closing := false
	var _vis: Array = []
	var _cd := {}                 # объект -> время, когда снова можно пройти

	func _ready() -> void:
		z_index = 4
		for at in [a, b]:
			var g := Node2D.new()
			g.position = at
			add_child(g)
			for r in [[1.0, Color(0.16, 0.12, 0.34, 0.95)], [0.78, Color(0.40, 0.25, 0.80, 0.9)], [0.52, Color(0.06, 0.03, 0.10, 1.0)]]:
				var o := Polygon2D.new()
				o.polygon = _oval(W / 2 * r[0], H / 2 * r[0])
				o.color = r[1]
				g.add_child(o)
			var rim := Line2D.new()
			var pts := _oval(W / 2 + 3.0, H / 2 + 3.0)
			pts.append(pts[0])
			rim.points = pts
			rim.width = 4.0
			rim.default_color = Color(1.0, 0.82, 0.38)
			g.add_child(rim)
			# руны-зубцы ключа по краю
			for k in 6:
				var ang := TAU * k / 6.0
				var tooth := Polygon2D.new()
				tooth.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(0, -7)])
				tooth.color = Color(1.0, 0.9, 0.6)
				tooth.position = Vector2(cos(ang) * (W / 2 + 6.0), sin(ang) * (H / 2 + 6.0))
				tooth.rotation = ang + PI / 2
				g.add_child(tooth)
			g.scale = Vector2(0.05, 1.0)
			var tw := g.create_tween()
			tw.tween_property(g, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_vis.append(g)
		var link := Line2D.new()                     # тонкая связь между вратами
		link.points = PackedVector2Array([a, b])
		link.width = 2.0
		link.default_color = Color(0.70, 0.45, 1.0, 0.25)
		link.z_index = -1
		add_child(link)
		Fx.ring(get_parent(), a, 70.0, Color(1.0, 0.82, 0.38, 0.9), 0.35, 5.0)
		Fx.ring(get_parent(), b, 70.0, Color(1.0, 0.82, 0.38, 0.9), 0.35, 5.0)
		Audio.sfx("zap", a, -4.0)

	static func _oval(rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 24:
			pts.append(Vector2(cos(TAU * i / 24.0) * rx, sin(TAU * i / 24.0) * ry))
		return pts

	func close() -> void:
		if _closing:
			return
		_closing = true
		for g in _vis:
			if is_instance_valid(g):
				var tw: Tween = g.create_tween()
				tw.tween_property(g, "scale", Vector2(0.05, 1.0), 0.2)
		var t := create_tween()
		t.tween_interval(0.22)
		t.tween_callback(queue_free)

	func _inside(pos: Vector2, c: Vector2) -> bool:
		var d := pos - c
		return (d.x * d.x) / (W * W * 0.25) + (d.y * d.y) / (H * H * 0.25) <= 1.0

	func _physics_process(delta: float) -> void:
		if _closing:
			return
		_t += delta
		for g in _vis:
			g.get_child(1).rotation += delta * 1.5
			g.get_child(2).scale = Vector2.ONE * (0.9 + 0.1 * sin(_t * 6.0))
		if _t >= life:
			close()
			return
		var now := _t
		for n in get_parent().get_children():
			if not (n is Node2D) or n == self:
				continue
			var mover := n is Player or n is Bullet or n is Arrow or n is Spear or n is Shuriken
			if not mover:
				continue
			if n is Player and (not n.is_alive() or n.cutscene_shield or n.body_size.y > 150.0):
				continue                            # огромные боссы во врата не пролезают
			if _cd.get(n, -1.0) > now:
				continue
			var pos: Vector2 = n.global_position
			var from := Vector2.INF
			var to := Vector2.INF
			if _inside(pos, a):
				from = a
				to = b
			elif _inside(pos, b):
				from = b
				to = a
			if from == Vector2.INF:
				continue
			_pass(n, from, to)
			_cd[n] = now + 0.7

	func _pass(n: Node2D, from: Vector2, to: Vector2) -> void:
		var world := get_parent()
		var off := n.global_position - from
		off.x = 0.0
		var dir := 0.0
		if n is Player:
			dir = signf(n.velocity.x) if absf(n.velocity.x) > 10.0 else float(n.facing)
		elif n is Bullet:
			dir = signf(n.direction.x)
		elif "velocity" in n:
			dir = signf(n.velocity.x)
		if dir == 0.0:
			dir = 1.0
		n.global_position = to + off + Vector2(dir * (W / 2 + 6.0), 0)
		if n is Player and n.team != team and mega and is_instance_valid(owner_p):
			n.take_damage(20, owner_p)
			n.slow(1.5, 0.5, "water")
		Fx.sparks(world, from, Color(0.70, 0.45, 1.0), 8, 160.0, 3.0)
		Fx.sparks(world, to, Color(1.0, 0.82, 0.38), 8, 160.0, 3.0)
		if n is Player:
			Audio.sfx("zap", to, -8.0)


# =====================================================================
# Цепь-замок: скованные враги делят урон и тянутся друг к другу
class LockChain extends Node2D:
	const SHARE := 0.5
	var owner_p: Player
	var links: Array = []
	var life := 4.0
	var _t := 0.0
	var _last := {}
	var _lines: Array = []
	var _done := false

	func _ready() -> void:
		z_index = 9
		for e in links:
			_last[e] = e.hp
			GatekeeperKit.lock(e, 0.6)
		for i in maxi(links.size() - 1, 0):
			var l := Line2D.new()
			l.width = 5.0
			l.default_color = Color(0.85, 0.80, 0.62)
			l.texture_mode = Line2D.LINE_TEXTURE_TILE
			add_child(l)
			var l2 := Line2D.new()
			l2.width = 2.0
			l2.default_color = Color(1.0, 0.82, 0.38)
			add_child(l2)
			_lines.append([l, l2])
		Audio.sfx("clank", links[0].global_position, -2.0)

	func finish() -> void:
		if _done:
			return
		_done = true
		for e in links:
			if is_instance_valid(e):
				Fx.sparks(get_parent(), e.hurt_center(), Color(1.0, 0.82, 0.38), 10, 220.0, 3.0)
		queue_free()

	func _physics_process(delta: float) -> void:
		if _done:
			return
		_t += delta
		links = links.filter(func(e): return is_instance_valid(e) and e.is_alive())
		if _t >= life or links.size() < 1 or (links.size() < 2 and _t > 0.6):
			finish()
			return
		# общий урон: половина того, что получил один, достаётся остальным
		var got := {}
		for e in links:
			got[e] = maxf(0.0, float(_last.get(e, e.hp)) - float(e.hp))
		for e in links:
			var extra := 0.0
			for o in links:
				if o != e:
					extra += got[o] * SHARE
			if extra >= 1.0:
				e.take_damage(int(extra), null)
				Fx.sparks(get_parent(), e.hurt_center(), Color(1.0, 0.82, 0.38), 3, 120.0, 2.5)
		for e in links:
			if is_instance_valid(e):
				_last[e] = e.hp
		# стягивает друг к другу
		if links.size() >= 2:
			var c := Vector2.ZERO
			for e in links:
				c += e.global_position
			c /= links.size()
			for e in links:
				var to: Vector2 = c - e.global_position
				if to.length() > 70.0:
					var pull := 260.0 if e.body_size.y < 140.0 else 60.0
					e.velocity.x = lerpf(e.velocity.x, signf(to.x) * pull, minf(1.0, delta * 6.0))
		# звенья цепи
		for i in _lines.size():
			if i + 1 >= links.size():
				_lines[i][0].visible = false
				_lines[i][1].visible = false
				continue
			var p0: Vector2 = links[i].hurt_center()
			var p1: Vector2 = links[i + 1].hurt_center()
			var pts := PackedVector2Array()
			var steps := 10
			for k in steps + 1:
				var q := p0.lerp(p1, float(k) / steps)
				q.y += sin(PI * k / steps) * 18.0 + sin(_t * 10.0 + k) * 2.0
				pts.append(q)
			_lines[i][0].points = pts
			_lines[i][1].points = pts


# =====================================================================
# Одиночная цепь: враг прикован к точке на земле
class AnchorChain extends Node2D:
	var target: Player
	var life := 1.4
	var _t := 0.0
	var _pegs: Array[Vector2] = []
	var _lines: Array[Line2D] = []

	func _ready() -> void:
		z_index = 9
		var foot := target.global_position + Vector2(0, target.body_size.y / 2 - 2)
		for side in [-1.0, 1.0]:
			var g := foot + Vector2(side * 70.0, 0)
			_pegs.append(g)
			# тёмная подложка + светлая цепь, чтобы читалась на любом фоне
			for w in [[7.0, Color(0.16, 0.10, 0.22)], [3.5, Color(1.0, 0.84, 0.42)]]:
				var ln := Line2D.new()
				ln.width = w[0]
				ln.default_color = w[1]
				add_child(ln)
				_lines.append(ln)
			var peg := Polygon2D.new()
			peg.polygon = PackedVector2Array([Vector2(-9, 2), Vector2(9, 2), Vector2(4, -12), Vector2(-4, -12)])
			peg.color = Color(1.0, 0.82, 0.38)
			peg.position = g
			add_child(peg)
		Audio.sfx("clank", foot, -2.0)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t >= life or not is_instance_valid(target) or not target.is_alive():
			queue_free()
			return
		var a := target.hurt_center()
		for i in _pegs.size():
			var pts := PackedVector2Array()
			for k in 9:
				var q: Vector2 = _pegs[i].lerp(a, k / 8.0)
				q.y += sin(PI * k / 8.0) * 6.0 * sin(_t * 9.0 + i)
				pts.append(q)
			_lines[i * 2].points = pts
			_lines[i * 2 + 1].points = pts


# =====================================================================
# Схлопывание: ключ летит в точку, пространство стягивается и взрывается
class Collapse extends Node2D:
	const FLY := 0.32
	const PULL := 1.0
	var owner_p: Player
	var team := 0
	var mega := false
	var radius := 260.0
	var damage := 28
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var _t := 0.0
	var _key: Node2D
	var _rings: Array = []
	var _done := false

	func _ready() -> void:
		z_index = 8
		_key = Node2D.new()
		add_child(_key)
		var shaft := Line2D.new()
		shaft.points = PackedVector2Array([Vector2(-12, 0), Vector2(10, 0)])
		shaft.width = 3.0
		shaft.default_color = Color(1.0, 0.82, 0.38)
		_key.add_child(shaft)
		var bow := Line2D.new()
		var pts := PackedVector2Array()
		for i in 13:
			pts.append(Vector2(-16, 0) + Vector2.from_angle(TAU * i / 12.0) * 5.0)
		bow.points = pts
		bow.width = 2.5
		bow.default_color = Color(1.0, 0.82, 0.38)
		_key.add_child(bow)
		var bit := Polygon2D.new()
		bit.polygon = PackedVector2Array([Vector2(4, 0), Vector2(10, 0), Vector2(10, 6), Vector2(7, 6), Vector2(7, 3), Vector2(4, 3)])
		bit.color = Color(1.0, 0.82, 0.38)
		_key.add_child(bit)
		var gem := Polygon2D.new()
		gem.polygon = Util.circle(2.5, 8)
		gem.position = Vector2(-16, 0)
		gem.color = Color(0.70, 0.45, 1.0)
		_key.add_child(gem)
		_key.position = from

	func _physics_process(delta: float) -> void:
		if _done:
			return
		_t += delta
		var world := get_parent()
		if _t < FLY:
			var k := _t / FLY
			_key.position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 60.0)
			_key.rotation += delta * 18.0
			return
		if _rings.is_empty():
			_key.position = to
			for i in 3:
				var r := Line2D.new()
				var pts := PackedVector2Array()
				for k2 in 33:
					pts.append(Vector2.from_angle(TAU * k2 / 32.0) * radius)
				r.points = pts
				r.width = 4.0 - i
				r.default_color = Color(0.70, 0.45, 1.0, 0.8) if i % 2 == 0 else Color(1.0, 0.82, 0.38, 0.8)
				r.position = to
				add_child(r)
				_rings.append(r)
			Audio.sfx("zap", to, -2.0)
		var k3 := clampf((_t - FLY) / PULL, 0.0, 1.0)
		for i in _rings.size():
			var s := maxf(0.05, 1.0 - k3 - i * 0.12)
			_rings[i].scale = Vector2.ONE * s
			_rings[i].rotation += delta * (3.0 + i * 2.0) * (1 if i % 2 == 0 else -1)
		_key.rotation += delta * 30.0
		_key.scale = Vector2.ONE * (1.0 + k3)
		# стягивает врагов к центру
		for n in world.get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				var d: Vector2 = to - n.global_position
				if d.length() < radius and d.length() > 16.0:
					var pull := (520.0 if n.body_size.y < 140.0 else 120.0) * (0.5 + k3)
					n.velocity = n.velocity.lerp(d.normalized() * pull, minf(1.0, delta * 8.0))
		if k3 >= 1.0:
			_implode()

	func _implode() -> void:
		_done = true
		var world := get_parent()
		var who: Player = owner_p if is_instance_valid(owner_p) else null
		for n in world.get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				if n.hurt_center().distance_to(to) < radius * 0.8 + n.body_size.x * 0.3:
					n.take_damage(damage, who)
					n.velocity = Vector2((n.global_position.x - to.x) * 2.0, -360.0)
					if mega:
						n.stun(1.0)
		Fx.ring(world, to, radius * 0.9, Color(1.0, 0.82, 0.38, 0.95), 0.35, 8.0)
		Fx.ring(world, to, radius * 0.5, Color(0.70, 0.45, 1.0, 0.95), 0.25, 6.0)
		Fx.sparks(world, to, Color(0.70, 0.45, 1.0), 24, 420.0, 4.0)
		Fx.sparks(world, to, Color(1.0, 0.82, 0.38), 16, 300.0, 4.0)
		Util.flash(world, to, 70.0, Color(0.85, 0.7, 1.0, 0.9))
		Fx.shake(world, 4.0)
		Audio.sfx("boom_small", to)
		queue_free()


# =====================================================================
# Запечатывание: круг печати — враги внутри замирают, потом печать «отдаёт» урон
class Seal extends Node2D:
	var owner_p: Player
	var mega := false
	var radius := 380.0
	var hold := 2.0
	var echo := 0.5
	var _t := 0.0
	var _sealed := {}             # враг -> здоровье в начале
	var _chains: Array = []
	var _circle: Node2D
	var _done := false

	func _ready() -> void:
		z_index = -1
		_circle = Node2D.new()
		add_child(_circle)
		var fill := Polygon2D.new()
		fill.polygon = Util.circle(radius, 48)
		fill.color = Color(0.16, 0.12, 0.34, 0.28)
		_circle.add_child(fill)
		for r in [radius, radius * 0.86, radius * 0.4]:
			var l := Line2D.new()
			var pts := PackedVector2Array()
			for k in 65:
				pts.append(Vector2.from_angle(TAU * k / 64.0) * r)
			l.points = pts
			l.width = 5.0 if r == radius else 3.0
			l.default_color = Color(1.0, 0.82, 0.38, 0.9) if r != radius * 0.86 else Color(0.70, 0.45, 1.0, 0.8)
			_circle.add_child(l)
		for k in 8:                                # руны-замочные скважины по кругу
			var ang := TAU * k / 8.0
			var rune := Polygon2D.new()
			rune.polygon = PackedVector2Array([Vector2(-5, -8), Vector2(5, -8), Vector2(5, 0), Vector2(2, 0), Vector2(3, 9), Vector2(-3, 9), Vector2(-2, 0), Vector2(-5, 0)])
			rune.color = Color(1.0, 0.82, 0.38)
			rune.position = Vector2.from_angle(ang) * radius * 0.93
			rune.rotation = ang + PI / 2
			_circle.add_child(rune)
		_circle.scale = Vector2(0.05, 0.05)
		var tw := _circle.create_tween()
		tw.tween_property(_circle, "scale", Vector2(1.0, 0.45), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var world := get_parent()
		Util.flash(world, global_position, 90.0, Color(1.0, 0.85, 0.45, 0.9))
		Fx.shake(world, 5.0)
		for n in world.get_children():
			if n is Player and is_instance_valid(owner_p) and n.team != owner_p.team and n.is_alive() and not n.cutscene_shield:
				if n.global_position.distance_to(global_position) < radius + n.body_size.x * 0.4:
					_sealed[n] = n.hp
					n.stun(hold)
					var ch := Node2D.new()
					ch.z_index = 10
					for s in [-1.0, 1.0]:
						var l2 := Line2D.new()
						l2.points = PackedVector2Array([Vector2(-n.body_size.x * 0.6, s * n.body_size.y * 0.3 - 8), Vector2(n.body_size.x * 0.6, -s * n.body_size.y * 0.3 - 8)])
						l2.width = 4.0
						l2.default_color = Color(1.0, 0.82, 0.38, 0.9)
						ch.add_child(l2)
					n.add_child(ch)
					_chains.append(ch)
					n.set_tint(Color(0.75, 0.7, 1.15))
		Audio.sfx("stun", global_position)

	func _physics_process(delta: float) -> void:
		if _done:
			return
		_t += delta
		_circle.rotation += delta * 0.6
		if _t >= hold:
			_release()

	func _release() -> void:
		_done = true
		var world := get_parent()
		for n in _sealed:
			if not is_instance_valid(n):
				continue
			n.set_tint(Color.WHITE)
			if not n.is_alive():
				continue
			var lost := maxi(0, int(_sealed[n]) - n.hp)
			var bonus := int(lost * echo)
			if bonus > 0:
				n.take_damage(bonus, null)
				Fx.sparks(world, n.hurt_center(), Color(1.0, 0.82, 0.38), 14, 260.0, 4.0)
				Fx.ring(world, n.hurt_center(), 60.0, Color(0.70, 0.45, 1.0, 0.9), 0.3, 5.0)
		for ch in _chains:
			if is_instance_valid(ch):
				ch.queue_free()
		Fx.ring(world, global_position, radius, Color(1.0, 0.82, 0.38, 0.9), 0.4, 6.0)
		Audio.sfx("break_glass", global_position)
		var tw := _circle.create_tween()
		tw.tween_property(_circle, "modulate:a", 0.0, 0.35)
		tw.tween_callback(queue_free)
