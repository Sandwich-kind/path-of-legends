class_name AbyssFinale
# ---------- Сердце Бездны: волны 101–103 (только сложная Арена) ----------
#   101 — Совет Отрёкшихся: Предвестник, Палач и Ткачиха вместе (CouncilBrain).
#         Узы Совета: пока двое стоят рядом, их связывают нити — урон по ним вдвое меньше.
#         Разводи их! Предвестник поднимает павших — сорви ритуал уроном или убей его первым.
#         Совместные приёмы: «Нить и плаха», «Приговор», «Портал казни», «Тройной узел».
#   102 — Лорд Бездны (AbyssLordBrain).
#   103 — Странник, поглощённый бездной (MadWandererBrain).

static func intro(am: ArenaMode, kind: String) -> Array:
	var world := am.world
	var fy: float = am.info["floor"]
	var c: Vector2 = am.info["center"]
	match kind:
		"council":
			# три разлома: слева Палач, справа Ткачиха, в середине — Предвестник
			var spots := [["abyss_headsman", c.x - 620.0], ["harbinger", c.x], ["rift_weaver", c.x + 620.0]]
			var members: Array = []
			for i in 3:
				var k: String = spots[i][0]
				var x: float = spots[i][1]
				am._after(0.4 + i * 0.7, func():
					var s := RiftAbilities.Slit.new()
					s.position = Vector2(x, fy)
					s.height = 230.0
					s.wide = 2.2
					s.life = 2.6
					world.add_child(s)
					Fx.shake(world, 6.0)
					am._after(0.5, func():
						var sz: Vector2 = Bots.TYPES[k]["size"]
						var b := am._make_boss(k, Vector2(x, fy - sz.y / 2 - 2))
						b.facing = -1 if x > c.x else 1
						b.modulate = Color(1, 1, 1, 0)
						b.create_tween().tween_property(b, "modulate:a", 1.0, 0.6)
						members.append(b)
						if i == 2:
							CouncilBrain.setup(am, members)))
			am._after(3.4, func(): am._banner_text("«Совет собран. Приговор един.»", Color(0.85, 0.7, 1.0)))
			am._after(4.6, func(): am._name_card("harbinger", "Совет Отрёкшихся", "ВОЛНА 101 · СЛОЖНАЯ АРЕНА"))
			am._after(7.6, func():
				for b in members:
					if is_instance_valid(b):
						b.frozen = false
						b.cutscene_shield = false
				am.hud.show_hint("Узы Совета: пока двое рядом, по ним проходит вдвое меньше урона — разводи их! Предвестник поднимает павших — сорви ритуал уроном или убей его первым.", 10.0))
			return [Vector2(c.x, fy - 260.0), 6.8]
		"abyss_lord":
			var lx := am._clear_x(c.x + 200.0, 320.0)
			for k in 6:
				am._after(0.3 + k * 0.3, func():
					Fx.bolt(world, Vector2(lx + randf_range(-300, 300), fy - 900.0), Vector2(lx + randf_range(-80, 80), fy), Color(0.8, 0.5, 1.0))
					Fx.shake(world, 3.0 + k))
			am._after(1.8, func():
				var sz2: Vector2 = Bots.TYPES["abyss_lord"]["size"]
				var b2 := am._make_boss("abyss_lord", Vector2(lx, fy - sz2.y / 2 - 2))
				b2.facing = -1 if am.players[0].position.x < lx else 1
				b2.modulate = Color(0.2, 0.1, 0.3, 0.0)
				var t := b2.create_tween()
				t.tween_property(b2, "modulate", Color(1, 1, 1, 1), 1.2)
				Util.flash(world, b2.global_position, 400.0, Color(0.7, 0.4, 1.0, 0.8))
				am._after(1.4, func():
					if is_instance_valid(b2) and b2.rig:
						b2.rig.play("roar")
					Fx.shake(world, 16.0)
					Fx.ring(world, Vector2(lx, fy), 420.0, Color(0.8, 0.45, 1.0, 0.9), 0.6, 10.0, 0.3)
					am._name_card("abyss_lord", "Лорд Бездны", "ВОЛНА 102 · СЛОЖНАЯ АРЕНА")))
			am._after(4.4, func(): am._banner_text("«Свет, что сжёг меня, погаснет»", Color(0.85, 0.6, 1.0)))
			return [Vector2(lx, fy - 280.0), 6.6]
		"mad_wanderer":
			if Audio.inst:
				Audio.inst._play_track("boss_wanderer_final")
			var mx := c.x
			am._after(0.3, func():
				Util.flash(world, Vector2(mx, fy - 400.0), 900.0, Color(1.0, 0.5, 0.9, 0.9))
				Fx.shake(world, 12.0))
			am._after(0.9, func():
				var sz3: Vector2 = Bots.TYPES["mad_wanderer"]["size"]
				var b3 := am._make_boss("mad_wanderer", Vector2(mx, fy - 420.0))
				b3.facing = -1 if am.players[0].position.x < mx else 1
				am._after(1.6, func():
					if is_instance_valid(b3) and b3.rig:
						b3.rig.play("roar")
					Fx.shake(world, 18.0)
					for k in 8:
						Fx.bolt(world, b3.global_position, b3.global_position + Vector2.from_angle(TAU * k / 8.0) * 500.0, Color(1.0, 0.5, 0.9))
					am._name_card("mad_wanderer", "Странник, поглощённый бездной", "ВОЛНА 103 · ПОСЛЕДНИЙ БОЙ")))
			am._after(4.2, func(): am._banner_text("Странник: «…НЕ… ОСТАНОВИТЬ…»", Color(1.0, 0.55, 0.85)))
			return [Vector2(mx, fy - 340.0), 6.0]
	return [Vector2(c.x, fy - 200.0), 4.0]


# =====================================================================
# Совет Отрёкшихся: узы, воскрешение, совместные приёмы
class CouncilBrain extends Node:
	var am: ArenaMode
	var members: Array = []           # живые члены Совета
	var _lines: Dictionary = {}
	var _revived := {}                # кого уже поднимали (по разу)
	var _combo_t := 9.0
	var _combo_i := 0
	var _channel := {}                # ритуал Предвестника: {"t", "dmg", "kind", "at", "fx"}
	var _pending: Array = []          # павшие, ждущие ритуала: [вид, место, через сколько]
	var _last := false
	var _tick := 0.0

	static func setup(arena: ArenaMode, list: Array) -> void:
		var cb := CouncilBrain.new()
		cb.am = arena
		arena.world.add_child(cb)
		for b in list:
			cb.adopt(b)
			if b.get_meta("kind") == "harbinger":
				arena._boss = b                     # полоска здоровья — у Предвестника

	func adopt(b: Player) -> void:
		members.append(b)
		b.set_meta("council", true)
		b.max_hp = int(b.max_hp * 0.7)                  # их трое — каждый чуть слабее
		b.hp = b.max_hp
		b.heal(0)
		var kind: String = b.get_meta("kind")
		if kind == "harbinger":
			var rb = b.get_node_or_null("RiftBrain")
			if rb:
				rb.set("_phase2", true)                # грань уже открыта; вторая фаза без сцены
			b.bot_abilities = {"glaive_combo": 2.4, "rift_cut": 6.0, "mirror_cuts": 9.5, "mark_storm": 9.0, "void_well": 12.0}
			var prev := b.on_hurt
			b.on_hurt = func(amount: int, by):
				if prev.is_valid():
					prev.call(amount, by)
				if not _channel.is_empty():
					_channel["dmg"] = float(_channel["dmg"]) + amount
		b.died.connect(_on_member_died.bind(b))

	func _harbinger() -> Player:
		for b in members:
			if is_instance_valid(b) and b.is_alive() and b.get_meta("kind") == "harbinger":
				return b
		return null

	func _alive() -> Array:
		members = members.filter(func(b): return is_instance_valid(b) and b.is_alive())
		return members

	func _on_member_died(_i: int, b: Player) -> void:
		var kind: String = b.get_meta("kind")
		var at := b.global_position
		if kind != "harbinger" and not _revived.has(kind):
			_pending.append([kind, at, 6.0])
		_clear_line_of(b)

	func _physics_process(delta: float) -> void:
		var alive := _alive()
		if alive.is_empty():
			for k in _lines:
				if is_instance_valid(_lines[k]):
					_lines[k].queue_free()
			queue_free()
			return
		if am._state == "over":
			return
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.15
			_bonds(alive)
		_revive_tick(delta)
		if alive.size() == 1 and not _last and _pending.is_empty() and _channel.is_empty():
			_last_stand(alive[0])
		var busy := alive.any(func(b): return b.frozen or b.cutscene_shield)
		if busy or not _channel.is_empty():
			return
		_combo_t -= delta
		if _combo_t <= 0.0 and alive.size() >= 2:
			_combo_t = randf_range(12.0, 15.0)
			_combo(alive)

	# ----- Узы: пары ближе 650 — нить, урон по ним вдвое меньше -----
	func _bonds(alive: Array) -> void:
		var bonded := {}
		var want := {}
		for i in alive.size():
			for j in range(i + 1, alive.size()):
				var a: Player = alive[i]
				var b: Player = alive[j]
				if a.global_position.distance_to(b.global_position) < 650.0:
					var key := "%d_%d" % [a.get_instance_id(), b.get_instance_id()]
					want[key] = [a, b]
					bonded[a] = true
					bonded[b] = true
		for key in _lines.keys():
			if not want.has(key):
				if is_instance_valid(_lines[key]):
					_lines[key].queue_free()
				_lines.erase(key)
		for key in want:
			var ln: Line2D = _lines.get(key)
			if ln == null or not is_instance_valid(ln):
				ln = Line2D.new()
				ln.width = 4.0
				ln.default_color = Color(0.80, 0.50, 1.0, 0.55)
				ln.z_index = 4
				am.world.add_child(ln)
				_lines[key] = ln
			var pa: Player = want[key][0]
			var pb: Player = want[key][1]
			var m := (pa.global_position + pb.global_position) / 2.0 + Vector2(0, -40 + sin(Time.get_ticks_msec() * 0.005) * 12.0)
			ln.points = PackedVector2Array([pa.hurt_center(), m, pb.hurt_center()])
		for b in alive:
			b.armor_mult = 0.5 if bonded.has(b) else 1.0
			b.modulate = Color(0.85, 0.75, 1.15) if bonded.has(b) else Color.WHITE

	func _clear_line_of(b: Player) -> void:
		var id := str(b.get_instance_id())
		for key in _lines.keys():
			if key.contains(id):
				if is_instance_valid(_lines[key]):
					_lines[key].queue_free()
				_lines.erase(key)

	# ----- Предвестник поднимает павших -----
	func _revive_tick(delta: float) -> void:
		var h := _harbinger()
		if h == null:
			_pending.clear()
			_end_channel(false)
			return
		if not _channel.is_empty():
			_channel["t"] = float(_channel["t"]) - delta
			if float(_channel["dmg"]) >= h.max_hp * 0.08:
				_end_channel(false)
				h.stun(1.8)
				am.hud.show_banner("Ритуал сорван!", Color(1.0, 0.85, 0.4))
				am._after(1.4, am.hud.hide_banner)
				return
			if float(_channel["t"]) <= 0.0:
				var kind: String = _channel["kind"]
				var at: Vector2 = _channel["at"]
				_end_channel(true)
				_revived[kind] = true
				var sz: Vector2 = Bots.TYPES[kind]["size"]
				var b := am.spawn_at(kind, Vector2(at.x, am.info["floor"] - sz.y / 2 - 4))
				b.remove_meta("summoned")
				adopt(b)
				b.hp = int(b.max_hp * 0.4)
				b.heal(0)
				Util.flash(am.world, b.global_position, 160.0, Color(0.9, 0.6, 1.0, 0.9))
				am.hud.show_banner("Предвестник поднял павшего!", Color(0.9, 0.6, 1.0))
				am._after(1.4, am.hud.hide_banner)
			return
		for e in _pending:
			e[2] = float(e[2]) - delta
		if not _pending.is_empty() and float(_pending[0][2]) <= 0.0:
			var e0: Array = _pending.pop_front()
			_start_channel(h, e0[0], e0[1])

	func _start_channel(h: Player, kind: String, at: Vector2) -> void:
		var fx := Node2D.new()
		am.world.add_child(fx)
		var ring := Fx.rune_circle(am.world, Vector2(at.x, am.info["floor"]), 110.0, Color(0.85, 0.5, 1.0, 0.9), 3.0)
		var beam := Line2D.new()
		beam.width = 5.0
		beam.default_color = Color(0.85, 0.55, 1.0, 0.7)
		fx.add_child(beam)
		_channel = {"t": 3.0, "dmg": 0.0, "kind": kind, "at": at, "fx": fx, "beam": beam, "h": h, "ring": ring}
		h._forced_time = 3.0
		h._forced_vx = 0.0
		if h.rig:
			h.rig.play("cast")
		am.hud.show_banner("Ритуал — сбей его уроном!", Color(1.0, 0.65, 1.0))
		am._after(1.8, am.hud.hide_banner)

	func _process(_d: float) -> void:
		if not _channel.is_empty():
			var beam: Variant = _channel["beam"]
			var h: Variant = _channel["h"]
			if is_instance_valid(beam) and is_instance_valid(h):
				beam.points = PackedVector2Array([h.hurt_center(), Vector2(_channel["at"].x, am.info["floor"] - 20.0)])

	func _end_channel(_ok: bool) -> void:
		if _channel.is_empty():
			return
		var fx: Variant = _channel["fx"]
		if is_instance_valid(fx):
			fx.queue_free()
		var ring: Variant = _channel.get("ring")
		if is_instance_valid(ring):
			ring.queue_free()
		var h: Variant = _channel.get("h")
		if is_instance_valid(h):
			h._forced_time = 0.0
		_channel = {}

	# ----- Последний из Совета: ярость -----
	func _last_stand(b: Player) -> void:
		_last = true
		b.heal(int(b.max_hp * 0.2))
		b.ab_tempo *= 1.3
		b.speed *= 1.15
		b.set_tint(Color(1.1, 0.8, 1.25))
		Fx.ring(am.world, b.global_position, 360.0, Color(0.9, 0.5, 1.0, 0.9), 0.5, 9.0)
		am.hud.show_banner("«Совет не падёт!»", Color(1.0, 0.6, 0.9))
		am._after(1.6, am.hud.hide_banner)

	# ----- Совместные приёмы -----
	func _by(kind: String, alive: Array) -> Player:
		for b in alive:
			if b.get_meta("kind") == kind:
				return b
		return null

	func _combo(alive: Array) -> void:
		var h := _by("harbinger", alive)
		var x := _by("abyss_headsman", alive)
		var w := _by("rift_weaver", alive)
		var options: Array = []
		if w and x:
			options.append("thread_block")
		if h and x:
			options.append("verdict")
		if h and w:
			options.append("exec_portals")
		if alive.size() >= 3:
			options.append("triple_knot")
		if options.is_empty():
			return
		_combo_i += 1
		var pick: String = options[_combo_i % options.size()]
		match pick:
			"thread_block":
				_announce("Нить и плаха!")
				for n in RiftAbilities._foes(w):
					var b := RiftAbilities.bolt(w, w.global_position + Vector2(0, -40), (n.hurt_center() - w.global_position).normalized(), 900.0, 6, 16.0, 0)
					b.homing = 260.0
					b.on_hit = func(t):
						if is_instance_valid(t) and t is Player and t.is_alive():
							t.root(1.4)
				x._after(0.9, func():
					if is_instance_valid(x) and x.is_alive() and is_instance_valid(x.target):
						AbyssAbilities._execution_leap(x))
			"verdict":
				_announce("Приговор!")
				AbyssAbilities._cleave_line(x)
				var rb = h.get_node_or_null("RiftBrain")
				if rb and is_instance_valid(h.target):
					rb.use("rift_cut", h.target.global_position - h.global_position)
			"exec_portals":
				_announce("Портал казни!")
				if is_instance_valid(w.target):
					AbyssAbilities._portal_bolts(w)
				var rb2 = h.get_node_or_null("RiftBrain")
				if rb2 and is_instance_valid(h.target):
					rb2.use("mark_storm", h.target.global_position - h.global_position)
			"triple_knot":
				_triple_knot(alive)

	func _announce(t: String) -> void:
		am.hud.show_banner("Совет: «%s»" % t, Color(0.95, 0.65, 1.0))
		am._after(1.4, am.hud.hide_banner)

	# Тройной узел: трое встают треугольником, нити между ними 4 с жгут всех, кто их касается
	func _triple_knot(alive: Array) -> void:
		_announce("Тройной узел!")
		var fy: float = am.info["floor"]
		var pts := [Vector2(Colosseum.W * 0.2, fy - 60.0), Vector2(Colosseum.W * 0.5, fy - 420.0), Vector2(Colosseum.W * 0.8, fy - 60.0)]
		for i in mini(3, alive.size()):
			var b: Player = alive[i]
			Util.flash(am.world, b.global_position, 60.0, Color(0.85, 0.6, 1.0, 0.8))
			b.global_position = pts[i] - Vector2(0, b.body_size.y * 0.3)
			b.velocity = Vector2.ZERO
			b._forced_time = 4.6
			b._forced_vx = 0.0
			Util.flash(am.world, b.global_position, 60.0, Color(0.85, 0.6, 1.0, 0.8))
		var knot := Knot.new()
		knot.points = [alive[0], alive[1], alive[2]]
		knot.src = alive[1]
		am.world.add_child(knot)

class Knot extends Node2D:
	var points: Array = []
	var src: Player
	var _t := 0.0
	var _tick := 0.0
	var _lines: Array = []

	func _ready() -> void:
		z_index = 5
		for k in 3:
			var l := Line2D.new()
			l.width = 6.0
			l.default_color = Color(0.85, 0.55, 1.0, 0.3)
			add_child(l)
			_lines.append(l)

	func _physics_process(delta: float) -> void:
		_t += delta
		var live := points.filter(func(b): return is_instance_valid(b) and b.is_alive())
		if _t > 4.8 or live.size() < 2:
			queue_free()
			return
		var hot := _t > 0.8
		for k in 3:
			var a = points[k]
			var b = points[(k + 1) % 3]
			var l: Line2D = _lines[k]
			if not (is_instance_valid(a) and is_instance_valid(b) and a.is_alive() and b.is_alive()):
				l.visible = false
				continue
			l.points = PackedVector2Array([a.hurt_center(), b.hurt_center()])
			l.default_color = Color(0.95, 0.65, 1.0, 0.95 if hot else 0.3 + 0.2 * sin(_t * 20.0))
			l.width = 8.0 if hot else 4.0
		_tick -= delta
		if hot and _tick <= 0.0:
			_tick = 0.35
			for k in 3:
				var a2 = points[k]
				var b2 = points[(k + 1) % 3]
				if is_instance_valid(a2) and is_instance_valid(b2) and a2.is_alive() and b2.is_alive() and is_instance_valid(src):
					RiftAbilities.hit_segment(src, a2.hurt_center(), b2.hurt_center(), 18.0, int(9 * float(src.get_meta("bal_dmg", 1.0)) / 1.5), 0)
