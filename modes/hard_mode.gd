class_name HardMode
# ---------- Сложный режим Арены (открывается после победы над Странником) ----------
# Те же сто волн, но:
#   * обычные враги прочнее (×HP), бьют больнее (×DMG), чаще пользуются приёмами,
#     чуть быстрее, и в каждой волне их на пятую часть больше;
#   * часть врагов выходит с ОСОБЕННОСТЬЮ (значок-ромб над головой и цветной отсвет
#     под ногами). Чем дальше волна, тем чаще особенности и тем они опаснее, а с
#     70-й волны у врага бывает сразу две;
#   * боссы и мини-боссы прочнее и злее, у каждого есть новые приёмы (HardMode.Boss),
#     а у десяти — новая фаза: на 40% здоровья кат-сцена, частичное лечение, ярость;
#   * золото за волну ×GOLD.

const HP := 1.30
const DMG := 1.20
const TEMPO := 1.10
const SPEED := 1.06
const EXTRA := 0.20
const BOSS_HP := 1.30
const BOSS_DMG := 1.15
const BOSS_TEMPO := 1.10
const GOLD := 1.5

# Особенности обычных врагов. "from" — с какой волны встречается.
const AFFIXES := {
	"shield": {"name": "Оберег", "desc": "кристальная корка принимает удары и отрастает снова", "color": Color(0.55, 0.85, 1.0), "from": 1},
	"haste": {"name": "Стремительный", "desc": "быстрее бегает и чаще бьёт", "color": Color(1.0, 0.85, 0.30), "from": 1},
	"tough": {"name": "Живучий", "desc": "если его не бить три секунды — залечивает раны", "color": Color(0.95, 0.35, 0.35), "from": 8},
	"blast": {"name": "Взрывной", "desc": "погибая, взрывается — отбегите!", "color": Color(1.0, 0.50, 0.15), "from": 21},
	"volley": {"name": "Залповый", "desc": "время от времени стреляет веером сгустков", "color": Color(1.0, 0.55, 0.70), "from": 21},
	"mender": {"name": "Целитель", "desc": "лечит врагов рядом с собой — бейте его первым", "color": Color(0.45, 1.0, 0.50), "from": 41},
	"blink": {"name": "Мерцающий", "desc": "переносится прямо к герою, за спину", "color": Color(0.70, 0.60, 1.0), "from": 41},
	"vengeful": {"name": "Мстительный", "desc": "погибая, выпускает кольцо сгустков", "color": Color(0.85, 0.40, 1.0), "from": 61},
}

# Ничего не получают: подставные, отражения, осколки, ростки
const NO_AFFIX := ["totem", "dummy", "crystal_decoy", "irida_image", "mirror_double", "weaver_echo",
		"sapling", "shardling_s", "shardling_xs", "magma_blob_s"]

# Боссы: новые приёмы [название, перезарядка] и цвет, у некоторых — новая фаза.
#   fan / fan_web / fan_fire / fan_poison / fan_void — веер сгустков (с замедлением, огнём, ядом);
#   wave / wave_frost — волна по земле в обе стороны (перепрыгните);
#   drops — с неба падают снаряды на отмеченные круги;
#   spikes — из земли под каждым героем бьют шипы;
#   lane — луч поперёк всей арены на высоте героя (уйдите вверх или вниз);
#   pull — босс тянет героев к себе и бьёт кольцом.
# phase: at — доля здоровья, heal — сколько лечит (доля от максимума), adds — сколько
# подручных зовёт, tempo/speed — ярость, crust — ледяная корка (доля от здоровья).
const BOSS := {
	"sergeant": {"color": Color(1.0, 0.72, 0.35), "moves": [["fan", 8.0]],
			"phase": {"at": 0.4, "heal": 0.0, "adds": 3, "tempo": 1.25, "text": "Сержант: «Подкрепление, сюда!»"}},
	"ataman": {"color": Color(1.0, 0.55, 0.30), "moves": [["wave", 9.0]],
			"phase": {"at": 0.4, "heal": 0.30, "speed": 1.15, "tempo": 1.2, "text": "Атаман: «Рано радуетесь!»"}},
	"chief": {"color": Color(1.0, 0.80, 0.40), "moves": [["drops", 9.0]],
			"phase": {"at": 0.4, "heal": 0.0, "adds": 3, "tempo": 1.25, "text": "Вождь бьёт в барабан войны!"}},
	"treant": {"color": Color(0.55, 0.95, 0.35), "moves": [["spikes", 9.0]]},
	"spider_queen": {"color": Color(0.85, 0.95, 0.90), "moves": [["fan_web", 8.0]],
			"phase": {"at": 0.4, "heal": 0.35, "adds": 3, "tempo": 1.15, "text": "Королева сбрасывает старый панцирь!"}},
	"skeleton_king": {"color": Color(0.90, 0.88, 0.75), "moves": [["spikes", 9.0]]},
	"baron_gryz": {"color": Color(0.95, 0.65, 0.35), "moves": [["wave", 8.5]],
			"phase": {"at": 0.4, "heal": 0.30, "tempo": 1.25, "text": "Барон Грыз: «Вы мне надоели!»"}},
	"irida": {"color": Color(0.70, 0.95, 1.0), "moves": [["lane", 9.0]]},
	"gladiator": {"color": Color(1.0, 0.75, 0.40), "moves": [["drops", 8.5]],
			"phase": {"at": 0.4, "heal": 0.30, "speed": 1.15, "tempo": 1.2, "text": "Толпа ревёт — Гладиатор воспрял!"}},
	"colossus": {"color": Color(1.0, 0.50, 0.25), "moves": [["wave", 9.0]]},
	"witch": {"color": Color(0.55, 1.0, 0.40), "moves": [["fan_poison", 8.0], ["drops", 12.0]],
			"phase": {"at": 0.4, "heal": 0.30, "tempo": 1.25, "text": "Ведьма пьёт последнее зелье!"}},
	"bog_lord": {"color": Color(0.60, 0.80, 0.35), "moves": [["pull", 12.0], ["spikes", 10.0]],
			"phase": {"at": 0.4, "heal": 0.35, "adds": 3, "text": "Трясина поднимается!"}},
	"jotun": {"color": Color(0.65, 0.92, 1.0), "moves": [["drops", 9.0], ["wave_frost", 12.0]],
			"phase": {"at": 0.4, "heal": 0.40, "crust": 0.15, "text": "Ётун одевается в вечный лёд!"}},
	"storm_lord": {"color": Color(0.70, 0.85, 1.0), "moves": [["drops", 8.0], ["lane", 12.0]],
			"phase": {"at": 0.4, "heal": 0.30, "tempo": 1.25, "text": "Буря усиливается!"}},
	"cerberus": {"color": Color(1.0, 0.50, 0.20), "moves": [["fan_fire", 8.0], ["wave", 11.0]],
			"phase": {"at": 0.4, "heal": 0.35, "speed": 1.15, "text": "Цербер: просыпается третья ярость!"}},
	"dark_lord": {"color": Color(0.80, 0.40, 1.0), "moves": [["lane", 10.0], ["drops", 13.0]]},
	"voidwing": {"color": Color(0.80, 0.45, 1.0), "moves": [["fan_void", 8.0]],
			"phase": {"at": 0.4, "heal": 0.25, "tempo": 1.2, "text": "Крыло Бездны рвёт небо!"}},
	"harbinger": {"color": Color(0.85, 0.50, 1.0), "moves": [["spikes", 9.0], ["lane", 13.0]]},
	"mill_giant": {"color": Color(0.95, 0.90, 0.80), "moves": [["wave", 9.0]]},
	"void_shepherd": {"color": Color(0.85, 0.65, 1.0), "moves": [["drops", 9.0]],
			"phase": {"at": 0.25, "heal": 0.25, "adds": 3, "text": "Пастух: «Стадо, вперёд!»"}},
	"abyss_headsman": {"color": Color(0.85, 0.45, 1.0), "moves": [["lane", 10.0]]},
	"rift_weaver": {"color": Color(0.92, 0.85, 1.0), "moves": [["fan_void", 8.0]]},
}

# ---------- Подготовка ----------
# Вызывается из ArenaMode._make_bot (бот уже в мире)
static func apply(am: Node, b: Player, kind: String) -> void:
	if kind == "totem":
		return
	b.set_meta("hard", true)
	if Bots.is_boss(kind):
		b.max_hp = int(b.max_hp * BOSS_HP)
		b.hp = b.max_hp
		b.set_meta("bal_dmg", float(b.get_meta("bal_dmg", 1.0)) * BOSS_DMG)
		b.ab_tempo *= BOSS_TEMPO
		if b.stagger_max > 0.0:
			b.stagger_max = b.max_hp * Balance.STAGGER_SHARE
		if BOSS.has(kind):
			var br := Boss.new()
			br.p = b
			br.am = am
			br.kind = kind
			b.add_child(br)
		return
	b.max_hp = int(b.max_hp * HP)
	b.hp = b.max_hp
	b.set_meta("bal_dmg", float(b.get_meta("bal_dmg", 1.0)) * DMG)
	b.ab_tempo *= TEMPO
	b.speed *= SPEED
	# особенность решаем чуть позже: призванные помечаются уже после создания
	(func(): HardMode._roll(am, b, kind)).call_deferred()

static func _roll(am: Node, b: Player, kind: String) -> void:
	if not is_instance_valid(b) or not b.is_alive() or b.has_meta("summoned") or kind in NO_AFFIX:
		return
	var w: int = am.wave
	var chance := clampf(0.15 + w * 0.0025, 0.0, 0.4)
	if randf() >= chance:
		return
	var pool: Array = []
	for k in AFFIXES:
		if w >= int(AFFIXES[k]["from"]):
			pool.append(k)
	pool.shuffle()
	var n := 2 if w >= 70 and randf() < 0.2 else 1
	var chosen: Array = pool.slice(0, mini(n, pool.size()))
	var a := Affix.new()
	a.p = b
	a.am = am
	a.kinds = chosen
	b.add_child(a)
	# впервые за забег — подсказка, что умеет эта особенность
	var seen: Dictionary = am.get_meta("hard_seen", {})
	for k in chosen:
		if not seen.has(k):
			seen[k] = true
			am.set_meta("hard_seen", seen)
			if am.hud and am.get("_cut_cam") == null:
				am.hud.show_hint("Особый враг «%s»: %s" % [AFFIXES[k]["name"], AFFIXES[k]["desc"]], 6.0)
			break

# Волна больше на пятую часть (тех же видов, что уже есть в волне)
static func extra_foes(am: Node) -> void:
	var q: Array = am._queue
	var regular := q.filter(func(k): return not Bots.is_boss(k))
	if regular.is_empty():
		return
	var add := ceili(regular.size() * EXTRA)
	var extra: Array = []
	for i in add:
		extra.append(regular[randi() % regular.size()])
	var bosses := q.filter(func(k): return Bots.is_boss(k))
	var all := regular + extra
	all.shuffle()
	am._queue = all + bosses

# ---------- Общие приёмы ----------
static func heroes(world: Node) -> Array:
	var res: Array = []
	if world == null:
		return res
	for n in world.get_children():
		if n is Player and n.team == 0 and n.is_alive() and not n.cutscene_shield:
			res.append(n)
	return res

# Поверхность под точкой (x, y): пол или платформа
static func floor_at(p: Node2D, x: float, y: float) -> float:
	return RiftAbilities._ground(p, Vector2(x, y))

static func arena_floor(p: Node) -> float:
	var am := p.get_tree().get_first_node_in_group("arena_mode") if p.is_inside_tree() else null
	return float(am.info["floor"]) if am and am.info.has("floor") else Colosseum.FLOOR_Y

static func base(p: Player, n: float) -> int:
	return maxi(1, int(round(n)))

# Цветной сгусток (полетит сквозь платформы, как все снаряды)
static func orb(p: Player, from: Vector2, dir: Vector2, spd: float, dmg: int, col: Color, sz := 12.0) -> Bullet:
	var b := Bullet.new()
	b.shooter = p
	b.team = p.team
	b.direction = dir
	b.speed = spd
	b.damage = dmg
	b.size = sz
	b.style = "rift"
	b.position = from
	p.get_parent().add_child(b)
	if b._vis2:
		var body := Polygon2D.new()
		body.polygon = Util.circle(sz * 0.75, 14)
		body.color = col
		b._vis2.add_child(body)
		var core := Polygon2D.new()
		core.polygon = Util.circle(sz * 0.38, 10)
		core.color = col.lightened(0.65)
		b._vis2.add_child(core)
	if b._trail:
		b._trail.width = sz * 0.7
		b._trail.default_color = Color(col, 0.45)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0))
		g.set_color(1, Color(1, 1, 1, 1))
		b._trail.gradient = g
	return b

static func slow_tint(n: Player, t: float, mult: float, col: Color) -> void:
	n.slow(t, mult)
	if n._slow_fx:
		n._slow_fx.modulate = col

static func fan(p: Player, col: Color, kind := "") -> void:
	if not is_instance_valid(p.target):
		return
	p._anim("cast")
	var from: Vector2 = p.rig.muzzle() if p.rig and p.rig.has_method("muzzle") else p.global_position + Vector2(0, -p.body_size.y * 0.25)
	var aim: Vector2 = (p.target.global_position - from).normalized()
	var n := 5
	Util.flash(p.get_parent(), from, 46.0, Color(col, 0.9))
	for i in n:
		var a := (i - (n - 1) / 2.0) * 0.2
		var b := orb(p, from, aim.rotated(a), 540.0, 7, col)
		match kind:
			"web":
				b.on_hit = func(t):
					if is_instance_valid(t) and t is Player and t.is_alive():
						HardMode.slow_tint(t, 1.6, 0.6, Color(0.95, 0.95, 1.0))
			"fire":
				b.burn_t = 2.0
			"poison":
				b.poison = 2.5
				b.homing = 120.0
			"void":
				b.homing = 90.0

static func wave(p: Player, col: Color, frost := false) -> void:
	var world := p.get_parent()
	var x := p.global_position.x
	var fy := floor_at(p, x, p.global_position.y)
	p._anim("slam")
	Fx.ring(world, Vector2(x, fy), 140.0, Color(col, 0.9), 0.5, 6.0, 0.3)
	var gw := GroundWave.new()
	gw.src = weakref(p)
	gw.col = col
	gw.fy = fy
	gw.dmg = 9
	gw.frost = frost
	p._after(0.45, func():
		if not is_instance_valid(p) or not p.is_alive():
			gw.free()
			return
		world.add_child(gw)
		gw.start(x)
		Fx.shake(world, 6.0)
		Fx.cracks(world, Vector2(x, fy), col.darkened(0.5), 120.0))

static func drops(p: Player, col: Color) -> void:
	var world := p.get_parent()
	var hs := heroes(world)
	if hs.is_empty():
		return
	p._anim("roar")
	var marks: Array = []
	for h in hs:
		var hx: float = h.global_position.x
		for k in 3:
			var x := clampf(hx + (k - 1) * 150.0 + randf_range(-30, 30), Colosseum.WALL + 40.0, Colosseum.W - Colosseum.WALL - 40.0)
			marks.append(Vector2(x, floor_at(p, x, h.global_position.y)))
	var who: WeakRef = weakref(p)
	for i in marks.size():
		var at: Vector2 = marks[i]
		Fx.rune_circle(world, at, 62.0, Color(col, 0.9), 1.0)
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([Vector2(0, 22), Vector2(-12, -10), Vector2(-5, -34), Vector2(5, -34), Vector2(12, -10)])
		shard.color = col
		shard.position = at + Vector2(randf_range(-40, 40), -900.0)
		shard.z_index = 6
		world.add_child(shard)
		var t := shard.create_tween()
		t.tween_interval(0.65 + i * 0.05)
		t.tween_property(shard, "position", at + Vector2(0, -10), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_callback(func():
			var src: Variant = who.get_ref()
			for h in HardMode.heroes(world):
				if h.global_position.distance_to(at + Vector2(0, -h.body_size.y * 0.4)) < 66.0 + h.body_size.x * 0.4:
					h.take_damage(10, src if is_instance_valid(src) else null)
					h.velocity.y = -380.0
			Fx.sparks(world, at + Vector2(0, -6), col, 10, 260.0, 4.0, true)
			Fx.ring(world, at, 70.0, Color(col, 0.8), 0.3, 5.0, 0.3)
			Fx.shake(world, 2.5))
		t.tween_property(shard, "modulate:a", 0.0, 0.35)
		t.tween_callback(shard.queue_free)

static func spikes(p: Player, col: Color) -> void:
	var world := p.get_parent()
	var hs := heroes(world)
	if hs.is_empty():
		return
	p._anim("roar")
	var who: WeakRef = weakref(p)
	for h in hs:
		var x: float = h.global_position.x
		var at := Vector2(x, floor_at(p, x, h.global_position.y))
		Fx.rune_circle(world, at, 72.0, Color(col, 0.9), 0.9)
		p._after(0.85, func():
			var src: Variant = who.get_ref()
			for k in 5:
				var sp := Polygon2D.new()
				var sx := -60.0 + k * 30.0
				var hgt := randf_range(70.0, 120.0)
				sp.polygon = PackedVector2Array([Vector2(sx - 11, 0), Vector2(sx + 2, -hgt), Vector2(sx + 11, 0)])
				sp.color = col.darkened(0.15)
				sp.position = at + Vector2(0, 40)
				sp.z_index = 5
				world.add_child(sp)
				var st := sp.create_tween()
				st.tween_property(sp, "position:y", at.y, 0.08)
				st.tween_interval(0.7)
				st.tween_property(sp, "modulate:a", 0.0, 0.3)
				st.tween_callback(sp.queue_free)
			for n in HardMode.heroes(world):
				var feet: float = n.global_position.y + n.body_size.y / 2
				if absf(n.global_position.x - at.x) < 72.0 + n.body_size.x / 2 and feet > at.y - 110.0 and feet < at.y + 30.0:
					n.take_damage(11, src if is_instance_valid(src) else null)
					n.velocity.y = -560.0
			Fx.sparks(world, at, col, 12, 280.0, 4.0, true))

static func lane(p: Player, col: Color) -> void:
	if not is_instance_valid(p.target):
		return
	var world := p.get_parent()
	p._anim("cast")
	var fy := arena_floor(p)
	var y := clampf(p.target.global_position.y, fy - 520.0, fy - 26.0)
	var a := Vector2(Colosseum.WALL, y)
	var b := Vector2(Colosseum.W - Colosseum.WALL, y)
	LightBeam.aim_line(world, a, b, col, 1.0)
	p._after(1.0, func():
		if not is_instance_valid(p) or not p.is_alive():
			return
		LightBeam.draw(world, [[a, b, 0]], col, 9.0, 0.4)
		RiftAbilities.hit_segment(p, a, b, 18.0, 12, 0)
		Fx.shake(world, 5.0))

static func pull(p: Player, col: Color) -> void:
	var world := p.get_parent()
	p._anim("roar")
	p._forced_time = 1.7
	p._forced_vx = 0.0
	var swirl := Node2D.new()
	swirl.z_index = 5
	p.add_child(swirl)
	for k in 3:
		var arc := Line2D.new()
		arc.width = 5.0
		arc.default_color = Color(col, 0.6)
		var pts := PackedVector2Array()
		for i in 12:
			pts.append(Vector2.from_angle(k * TAU / 3.0 + i * 0.15) * (220.0 - i * 10.0))
		arc.points = pts
		swirl.add_child(arc)
	var st := swirl.create_tween()
	st.tween_property(swirl, "rotation", -TAU * 2.0, 1.4)
	var steps := 14
	for i in steps:
		p._after(i * 0.1, func():
			if not is_instance_valid(p) or not p.is_alive():
				return
			for n in HardMode.heroes(world):
				var dx: float = n.global_position.x - p.global_position.x
				if absf(dx) < 950.0:
					n.push_wind(-signf(dx) * 380.0))
	p._after(1.45, func():
		if is_instance_valid(swirl):
			swirl.queue_free()
		if not is_instance_valid(p) or not p.is_alive():
			return
		p._anim("slam")
		Fx.ring(world, p.global_position, 230.0, Color(col, 0.9), 0.4, 8.0)
		Fx.shake(world, 7.0)
		for n in HardMode.heroes(world):
			if n.global_position.distance_to(p.global_position) < 230.0:
				n.take_damage(12, p)
				n.velocity = Vector2(signf(n.global_position.x - p.global_position.x) * 420.0, -360.0))

# ---------- Волна по земле ----------
class GroundWave extends Node2D:
	var src: WeakRef
	var col := Color.WHITE
	var dmg := 9
	var speed := 680.0
	var fy := 940.0
	var frost := false
	var _waves: Array = []

	func start(x: float) -> void:
		z_index = 4
		for d in [-1.0, 1.0]:
			# гребень волны: тёмная кромка, светлое тело, яркая сердцевина — видно на любом фоне
			var l := Node2D.new()
			l.position = Vector2(x, fy)
			add_child(l)
			for layer in [[1.15, col.darkened(0.55), 0.9], [1.0, col, 0.9], [0.55, col.lightened(0.6), 1.0]]:
				var s: float = layer[0]
				var crest := Polygon2D.new()
				crest.polygon = PackedVector2Array([Vector2(-d * 46.0 * s, 0), Vector2(-d * 18.0 * s, -30.0 * s),
						Vector2(d * 6.0 * s, -70.0 * s), Vector2(d * 22.0 * s, -36.0 * s), Vector2(d * 30.0 * s, 0)])
				crest.color = Color(layer[1], layer[2])
				l.add_child(crest)
			_waves.append({"x": x, "d": d, "hit": {}, "l": l})

	func _physics_process(delta: float) -> void:
		var world := get_parent()
		var who: Variant = src.get_ref() if src else null
		for wv in _waves.duplicate():
			wv["x"] = float(wv["x"]) + float(wv["d"]) * speed * delta
			var l: Node2D = wv["l"]
			l.position.x = wv["x"]
			l.scale.y = 0.9 + 0.15 * sin(float(wv["x"]) * 0.05)
			if randf() < 0.7:
				Fx.sparks(world, Vector2(wv["x"] - float(wv["d"]) * 20.0, fy - 6), col, 2, 180.0, 4.0, true)
			for n in HardMode.heroes(world):
				var feet: float = n.global_position.y + n.body_size.y / 2
				var id: int = n.get_instance_id()
				if absf(n.global_position.x - float(wv["x"])) < 26.0 + n.body_size.x / 2 and feet > fy - 34.0 \
						and feet < fy + 30.0 and not wv["hit"].has(id):
					wv["hit"][id] = true
					n.take_damage(dmg, who if is_instance_valid(who) else null)
					n.velocity = Vector2(float(wv["d"]) * 360.0, -480.0)
					if frost:
						HardMode.slow_tint(n, 2.0, 0.55, Color(0.6, 0.9, 1.0))
			if float(wv["x"]) < Colosseum.WALL or float(wv["x"]) > Colosseum.W - Colosseum.WALL:
				l.queue_free()
				_waves.erase(wv)
		if _waves.is_empty():
			queue_free()

# ---------- Особенность обычного врага ----------
class Affix extends Node2D:
	var p: Player
	var am: Node
	var kinds: Array = []
	var _cd := {}
	var _calm := 0.0
	var _last_hp := 0
	var _regen_acc := 0.0
	var _shield_max := 0.0
	var _regrow := 0.0
	var _gems: Array = []
	var _t := 0.0

	func _ready() -> void:
		name = "HardAffix"
		z_index = 8
		_last_hp = p.hp
		for k in kinds:
			_cd[k] = randf_range(2.5, 4.5)
		if "shield" in kinds:
			_shield_max = p.max_hp * 0.35
			p.crust = _shield_max
			p._update_crust()
		if "haste" in kinds:
			p.speed *= 1.3
			p.ab_tempo *= 1.3
		p.died.connect(_on_died)
		var y := -p.body_size.y / 2 - 30.0
		for i in kinds.size():
			var c: Color = HardMode.AFFIXES[kinds[i]]["color"]
			var gem := Polygon2D.new()
			gem.polygon = PackedVector2Array([Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)])
			gem.color = c
			gem.position = Vector2((i - (kinds.size() - 1) / 2.0) * 18.0, y)
			add_child(gem)
			var rim := Line2D.new()
			rim.points = PackedVector2Array([Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0), Vector2(0, -8)])
			rim.width = 1.5
			rim.default_color = Color(0.1, 0.08, 0.12, 0.8)
			gem.add_child(rim)
			_gems.append(gem)
		var glow := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 18:
			var a := TAU * i / 18.0
			pts.append(Vector2(cos(a) * p.body_size.x * 0.75, sin(a) * 8.0))
		glow.polygon = pts
		glow.color = Color(HardMode.AFFIXES[kinds[0]]["color"], 0.32)
		glow.position = Vector2(0, p.body_size.y / 2 - 2)
		glow.z_index = -2
		glow.z_as_relative = true
		add_child(glow)

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(p) or not p.is_alive():
			return
		_t += delta
		for i in _gems.size():
			_gems[i].position.y = -p.body_size.y / 2 - 30.0 + sin(_t * 3.0 + i) * 3.0
		if p.frozen or p.cutscene_shield:
			return
		if p.hp < _last_hp:
			_calm = 0.0
		else:
			_calm += delta
		_last_hp = p.hp
		for k in kinds:
			_cd[k] = float(_cd[k]) - delta
		if "shield" in kinds and p.crust <= 0.0:
			_regrow += delta
			if _regrow >= 9.0:
				_regrow = 0.0
				p.crust = _shield_max * 0.5
				p._update_crust()
				Util.flash(p.get_parent(), p.global_position, p.body_size.y * 0.6, Color(0.6, 0.85, 1.0, 0.8))
		if "tough" in kinds and _calm > 3.0 and p.hp < p.max_hp:
			_regen_acc += p.max_hp * 0.025 * delta
			if _regen_acc >= 1.0:
				p.heal(int(_regen_acc))
				_regen_acc -= int(_regen_acc)
				if randf() < 0.2:
					Fx.sparks(p.get_parent(), p.global_position, Color(1.0, 0.4, 0.4), 2, 120.0, 3.0, true)
		if "haste" in kinds and randf() < 0.15 and absf(p.velocity.x) > 60.0:
			Fx.sparks(p.get_parent(), p.global_position + Vector2(0, p.body_size.y * 0.3), Color(1.0, 0.85, 0.3), 1, 80.0, 3.0)
		if "mender" in kinds and float(_cd["mender"]) <= 0.0:
			_cd["mender"] = 7.0
			_mend()
		if "blink" in kinds and float(_cd["blink"]) <= 0.0:
			_cd["blink"] = randf_range(5.0, 7.0)
			_blink()
		if "volley" in kinds and float(_cd["volley"]) <= 0.0:
			_cd["volley"] = randf_range(5.5, 7.5)
			_volley()

	func _mend() -> void:
		var world := p.get_parent()
		var hurt: Array = []
		for b in am._alive:
			if is_instance_valid(b) and b.is_alive() and b.hp < b.max_hp and not Bots.is_boss(String(b.get_meta("kind", "grunt"))) \
					and b.global_position.distance_to(p.global_position) < 340.0:
				hurt.append(b)
		if hurt.is_empty():
			_cd["mender"] = 1.5
			return
		p._anim("cast")
		Fx.ring(world, p.global_position, 340.0, Color(0.45, 1.0, 0.5, 0.7), 0.5, 5.0)
		for b in hurt:
			b.heal(int(b.max_hp * 0.10))
			Fx.sparks(world, b.global_position, Color(0.45, 1.0, 0.5), 6, 140.0, 3.0, true)

	func _blink() -> void:
		var t: Player = p.target
		if not is_instance_valid(t) or not t.is_alive() or t.cutscene_shield:
			return
		if t.global_position.distance_to(p.global_position) < 320.0:
			_cd["blink"] = 1.5
			return
		var world := p.get_parent()
		var side := -float(t.facing) if t.facing != 0 else 1.0
		var to := Vector2(clampf(t.global_position.x + side * 120.0, Colosseum.WALL + 50.0, Colosseum.W - Colosseum.WALL - 50.0),
				t.global_position.y + t.body_size.y / 2 - p.body_size.y / 2 - 4.0)
		Util.flash(world, p.global_position, p.body_size.y * 0.7, Color(0.7, 0.6, 1.0, 0.85))
		p.global_position = to
		p.velocity = Vector2.ZERO
		p.facing = -1 if t.global_position.x < to.x else 1
		Util.flash(world, to, p.body_size.y * 0.7, Color(0.7, 0.6, 1.0, 0.85))

	func _volley() -> void:
		var t: Player = p.target
		if not is_instance_valid(t) or not t.is_alive() or t.global_position.distance_to(p.global_position) > 900.0:
			_cd["volley"] = 1.5
			return
		var world := p.get_parent()
		var from := p.global_position + Vector2(0, -p.body_size.y * 0.2)
		Util.flash(world, from, 40.0, Color(1.0, 0.55, 0.7, 0.9))
		p._after(0.35, func():
			if not is_instance_valid(p) or not p.is_alive() or not is_instance_valid(t):
				return
			var aim := (t.global_position - from).normalized()
			for i in 3:
				HardMode.orb(p, from, aim.rotated((i - 1) * 0.22), 500.0, 5, Color(1.0, 0.55, 0.7), 10.0))

	func _on_died(_i: int) -> void:
		var world := p.get_parent()
		if world == null:
			return
		var at := p.global_position
		var mult := float(p.get_meta("bal_dmg", 1.0))
		if "blast" in kinds:
			var c := Color(1.0, 0.5, 0.15)
			Fx.rune_circle(world, at + Vector2(0, p.body_size.y / 2), 140.0, Color(c, 0.9), 0.7)
			var dmg := int(12 * mult)
			am._after(0.7, func():
				Fx.ring(world, at, 150.0, Color(c, 0.95), 0.4, 9.0)
				Fx.sparks(world, at, c, 20, 340.0, 5.0)
				Fx.shake(world, 6.0)
				for h in HardMode.heroes(world):
					if h.global_position.distance_to(at) < 150.0 + h.body_size.x * 0.3:
						h.take_damage(dmg)
						h.velocity = Vector2(signf(h.global_position.x - at.x) * 420.0, -380.0))
		if "vengeful" in kinds:
			var c2 := Color(0.85, 0.4, 1.0)
			Util.flash(world, at, 70.0, Color(c2, 0.9))
			for i in 8:
				HardMode.orb(p, at, Vector2.from_angle(TAU * i / 8.0 + 0.2), 380.0, 5, c2, 11.0)

# ---------- Новые приёмы и фаза босса ----------
class Boss extends Node:
	var p: Player
	var am: Node
	var kind := ""
	var cfg: Dictionary
	var col := Color.WHITE
	var _cd: Array = []
	var _phased := false
	var _shielded := false

	func _ready() -> void:
		name = "HardBoss"
		cfg = HardMode.BOSS[kind]
		col = cfg["color"]
		for m in cfg["moves"]:
			_cd.append(float(m[1]) * randf_range(0.6, 0.9))

	func _blocked() -> bool:
		if p.frozen or p.cutscene_shield or p._stun_t > 0.0 or p.invulnerable and kind != "treant":
			return true
		if am.get("_cut_cam") != null and is_instance_valid(am.get("_cut_cam")):
			return true
		if am.get("_state") != "fight" and am.get("_state") != "cutscene":
			return true
		var t: Variant = p.target
		return not (is_instance_valid(t) and t is Player and t.is_alive() and t.team != p.team)

	func _physics_process(delta: float) -> void:
		if not is_instance_valid(p) or not p.is_alive():
			return
		if cfg.has("phase") and not _phased and p.hp > 0 and p.hp <= p.max_hp * float(cfg["phase"]["at"]) \
				and not p.cutscene_shield and not p.frozen:
			_phase()
			return
		if _blocked():
			return
		for i in _cd.size():
			_cd[i] = float(_cd[i]) - delta * p.ab_tempo
			if float(_cd[i]) <= 0.0:
				_cd[i] = float(cfg["moves"][i][1]) * randf_range(0.9, 1.15)
				_use(String(cfg["moves"][i][0]))
				# два приёма подряд не выходят: второй ждёт хотя бы пару секунд
				for j in _cd.size():
					if j != i:
						_cd[j] = maxf(float(_cd[j]), 2.2)
				break

	func _use(m: String) -> void:
		match m:
			"fan":
				HardMode.fan(p, col)
			"fan_web":
				HardMode.fan(p, col, "web")
			"fan_fire":
				HardMode.fan(p, col, "fire")
			"fan_poison":
				HardMode.fan(p, col, "poison")
			"fan_void":
				HardMode.fan(p, col, "void")
			"wave":
				HardMode.wave(p, col)
			"wave_frost":
				HardMode.wave(p, col, true)
			"drops":
				HardMode.drops(p, col)
			"spikes":
				HardMode.spikes(p, col)
			"lane":
				HardMode.lane(p, col)
			"pull":
				HardMode.pull(p, col)

	# Новая фаза: короткая сцена, частичное лечение и ярость
	func _phase() -> void:
		_phased = true
		var ph: Dictionary = cfg["phase"]
		var world := p.get_parent()
		am.cinematic(p, 1.9, true)
		am.shield_heroes(2.5)
		p.cutscene_shield = true
		_shielded = true
		if p.rig:
			p.rig.play("roar")
		am.hud.show_banner(String(ph["text"]), col.lightened(0.2))
		am._after(1.8, am.hud.hide_banner)
		Fx.shake(world, 10.0)
		Fx.ring(world, p.global_position, 320.0, Color(col, 0.9), 0.6, 9.0)
		Fx.sparks(world, p.global_position, col, 28, 340.0, 5.0)
		var heal := float(ph.get("heal", 0.0))
		if heal > 0.0:
			var from := float(p.hp)
			var to := minf(float(p.max_hp), from + p.max_hp * heal)
			var ht := p.create_tween()
			ht.tween_method(func(v: float):
				if is_instance_valid(p) and p.is_alive():
					p.hp = maxi(p.hp, int(v))
					p.heal(0), from, to, 1.3)
		am._after(1.95, func():
			if not is_instance_valid(p) or not p.is_alive():
				return
			if _shielded:
				p.cutscene_shield = false
				_shielded = false
			p.ab_tempo *= float(ph.get("tempo", 1.1))
			p.speed *= float(ph.get("speed", 1.0))
			p.set_tint(Color(1.0, 1.0, 1.0).lerp(col, 0.25) * 1.08)
			if ph.has("crust"):
				p.crust = p.max_hp * float(ph["crust"])
				p._update_crust()
			var adds := int(ph.get("adds", 0))
			if adds > 0 and Bots.SUMMONS.has(kind):
				am._summon(Bots.SUMMONS[kind], adds, p.global_position)
			for i in _cd.size():
				_cd[i] = minf(float(_cd[i]), 1.5 + i * 2.0))
