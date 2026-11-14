class_name RiftScenes
# ---------- Сцены боссов свиты Странника: появление и гибель ----------
#   Пустокрыл   — над островами разрывается небо, скат вылетает из разлома, проносится
#                 над ареной и разворачивается в воздухе. Гибнет: рушится на остров,
#                 трещины вспыхивают, тело рассыпается фиолетовым пеплом, хвост-кристалл
#                 раскалывается.
#   Предвестник — пламя пожаров тянется к земле: посреди поля раскрывается разлом,
#                 он выходит из него, волоча глефу. Гибнет: падает на колено, маска
#                 раскалывается надвое, тело расплетается нитями в разлом над ним —
#                 из разлома на миг смотрят чьи-то глаза… и он захлопывается.

# Возвращает [точка, куда смотрит камера, длительность сцены]
static func intro(am: ArenaMode, kind: String) -> Array:
	var world := am.world
	var floor_y: float = am.info["floor"]
	var c: Vector2 = am.info["center"]
	match kind:
		"voidwing":
			var size: Vector2 = Bots.TYPES[kind]["size"]
			var rift_at := Vector2(c.x + 420.0, floor_y - 500.0)
			var tear := RiftAbilities.Slit.new()
			tear.position = rift_at + Vector2(0, 160.0)
			tear.height = 300.0
			tear.wide = 3.2
			tear.life = 3.2
			world.add_child(tear)
			am._after(0.3, func(): Fx.shake(world, 6.0))
			for k in 6:
				am._after(0.4 + k * 0.15, func():
					Fx.sparks(world, rift_at + Vector2(randf_range(-30, 30), randf_range(-20, 120)), RiftRig.GLOW, 4, 200.0, 4.0))
			am._after(1.3, func():
				var b := am._make_boss(kind, rift_at)
				b.set_physics_process(false)
				b.facing = -1
				var from := rift_at
				var mid := Vector2(c.x - 200.0, floor_y - 200.0)
				var to := Vector2(c.x - 340.0, RiftBrain.CRUISE_Y)
				var tw := b.create_tween()
				tw.tween_method(func(k: float):
					if is_instance_valid(b):
						var prev := b.global_position
						b.global_position = from.lerp(mid, k).lerp(mid.lerp(to, k), k)
						if b.global_position.x > prev.x + 0.5:
							b.facing = 1
						elif b.global_position.x < prev.x - 0.5:
							b.facing = -1, 0.0, 1.0, 1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tw.tween_callback(func():
					if not is_instance_valid(b):
						return
					b.facing = 1                       # физика включится, когда сцена кончится (RiftBrain)
					if b.rig:
						b.rig.play("roar")
					Fx.shake(world, 10.0)
					Fx.ring(world, b.global_position, 260.0, Color(0.85, 0.55, 1.0, 0.9), 0.5, 8.0)
					am._after(0.4, am._name_card.bind(kind, "", "МИНИ-БОСС · НЕБО РАЗОРВАНО"))))
			return [Vector2(c.x, floor_y - 360.0), 5.6]
		"harbinger":
			var size_h: Vector2 = Bots.TYPES[kind]["size"]
			var hx := am._clear_x(c.x + 160.0, 300.0)
			var at := Vector2(hx, floor_y)
			var cm: CanvasModulate = null
			for n in world.get_children():
				if n is CanvasModulate:
					cm = n
			var cm_col: Color = cm.color if cm else Color.WHITE
			if cm:
				cm.create_tween().tween_property(cm, "color", Color(0.62, 0.48, 0.70), 1.0)
			# искры пожаров тянет к одной точке на поле
			for k in 16:
				am._after(0.2 + k * 0.1, func():
					var from := at + Vector2(randf_range(-700, 700), randf_range(-420, -60))
					var e := Polygon2D.new()
					e.polygon = PackedVector2Array([Vector2(-4, 0), Vector2(0, -3), Vector2(4, 0), Vector2(0, 3)])
					e.color = Color(1.0, 0.55, 0.2)
					e.position = from
					e.z_index = 8
					world.add_child(e)
					var et := e.create_tween()
					et.tween_property(e, "position", at + Vector2(0, -size_h.y * 0.5), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					et.parallel().tween_property(e, "color", RiftRig.GLOW, 0.9)
					et.tween_callback(e.queue_free))
			var tear := RiftAbilities.Slit.new()
			tear.position = at
			tear.height = size_h.y * 1.35
			tear.wide = 3.0
			tear.life = 3.6
			am._after(0.9, func():
				world.add_child(tear)
				Fx.shake(world, 8.0)
				Fx.cracks(world, at, Color(0.35, 0.15, 0.45), 160.0))
			am._after(2.0, func(): am._banner_text("Мой господин уже близко…", Color(0.9, 0.6, 1.0)))
			am._after(2.9, func():
				var b := am._make_boss(kind, Vector2(hx, floor_y - size_h.y / 2 - 2))
				b.facing = -1 if am.players[0].position.x < hx else 1
				if b._rig_root:
					b._rig_root.modulate = Color(0.2, 0.05, 0.3)
					b._rig_root.create_tween().tween_property(b._rig_root, "modulate", Color.WHITE, 1.0)
				var st := b.create_tween()
				st.tween_property(b, "global_position:x", hx + b.facing * 70.0, 0.9).set_trans(Tween.TRANS_SINE)
				Util.flash(world, Vector2(hx, floor_y - size_h.y * 0.5), 160.0, Color(0.85, 0.5, 1.0, 0.8))
				am._after(1.0, func():
					if cm:
						cm.create_tween().tween_property(cm, "color", cm_col, 1.2)
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					Fx.shake(world, 12.0)
					Fx.ring(world, Vector2(hx, floor_y), 340.0, Color(0.8, 0.45, 1.0, 0.9), 0.6, 10.0, 0.3)
					am._name_card(kind, "", "ПЕРВЫЙ ИЗ ОТРЁКШИХСЯ")))
			return [Vector2(hx, floor_y - 240.0), 6.4]
	return [Vector2(c.x, floor_y - 200.0), 4.6]

# ---------- Гибель ----------
static func _rig_of(c: Node) -> RiftRig:
	for n in c.find_children("*", "RiftRig", true, false):
		return n as RiftRig
	return null

static func death(world: Node, c: Node2D, kind: String, feet: Vector2, f: float, bs: Vector2) -> void:
	match kind:
		"voidwing": _voidwing(world, c, feet, f, bs)
		"harbinger": _harbinger(world, c, feet, f, bs)

static func _voidwing(world: Node, c: Node2D, feet: Vector2, _f: float, bs: Vector2) -> void:
	var rig := _rig_of(c)
	if rig:
		rig.play("slam")
	Fx.shake(world, 12.0)
	Fx.ring(world, feet, 280.0, Color(0.8, 0.6, 1.0, 0.9), 0.45, 8.0, 0.3)
	Fx.sparks(world, feet + Vector2(0, -10), Color(0.70, 0.66, 0.78), 24, 360.0, 5.0, true)
	Fx.cracks(world, feet, Color(0.25, 0.15, 0.30), 180.0)
	var t := c.create_tween()
	t.tween_interval(0.5)
	t.tween_property(c, "modulate", Color(1.8, 1.2, 2.2), 0.5)              # трещины вспыхивают
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		for k in 26:                                                       # рассыпается пеплом
			var a := Polygon2D.new()
			a.polygon = PackedVector2Array([Vector2(-5, -3), Vector2(4, -4), Vector2(5, 3), Vector2(-3, 4)])
			a.color = Color(0.30, 0.18, 0.44) if k % 3 else RiftRig.GLOW
			a.position = feet + Vector2(randf_range(-bs.x * 0.5, bs.x * 0.5), -randf_range(10, bs.y * 0.9))
			a.z_index = 6
			world.add_child(a)
			var at := a.create_tween()
			at.tween_property(a, "position", a.position + Vector2(randf_range(-60, 60), -randf_range(120, 320)), randf_range(1.2, 2.2))
			at.parallel().tween_property(a, "modulate:a", 0.0, 2.0)
			at.parallel().tween_property(a, "rotation", randf_range(-6, 6), 2.0)
			at.tween_callback(a.queue_free)
		if rig:
			var tip := rig.point("tail")
			Util.flash(world, tip, 80.0, Color(0.9, 0.6, 1.0, 0.9))
			Fx.sparks(world, tip, RiftRig.CORE, 16, 260.0, 4.0))
	t.tween_property(c, "modulate", Color(0.4, 0.2, 0.6, 0.0), 1.6)
	t.tween_callback(c.queue_free)

static func _harbinger(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var rig := _rig_of(c)
	if rig:
		rig.levitate = 0.0
		rig.play("kneel")
	var head := feet + Vector2(f * bs.x * 0.1, -bs.y * 0.8)
	var t := c.create_tween()
	t.tween_interval(0.9)
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		# маска раскалывается надвое
		Util.flash(world, head, 60.0, Color(1.0, 0.95, 1.0, 0.95))
		for s in [-1.0, 1.0]:
			var half := Polygon2D.new()
			half.polygon = PackedVector2Array([Vector2(0, -22), Vector2(s * 14, -18), Vector2(s * 16, 2), Vector2(s * 8, 16), Vector2(0, 18)])
			half.color = RiftRig.MASK
			half.position = head
			half.z_index = 9
			world.add_child(half)
			var gy := feet.y - 4.0
			var ht := half.create_tween()
			ht.tween_property(half, "position", Vector2(head.x + s * randf_range(60, 110), gy), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			ht.parallel().tween_property(half, "rotation", s * randf_range(2.0, 4.0), 0.7)
			ht.tween_interval(2.4)
			ht.tween_property(half, "modulate:a", 0.0, 0.8)
			ht.tween_callback(half.queue_free)
		if rig and rig._head:
			rig._head.visible = false)
	# над ним раскрывается разлом
	var sky := feet + Vector2(0, -bs.y * 1.9)
	var tear := RiftAbilities.Slit.new()
	tear.position = sky + Vector2(0, 150.0)
	tear.height = 300.0
	tear.wide = 3.4
	tear.life = 3.3
	t.tween_interval(0.4)
	t.tween_callback(func():
		if is_instance_valid(world):
			world.add_child(tear)
			Fx.shake(world, 8.0))
	# тело расплетается нитями и уходит в разлом
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		for k in 22:
			var l := Line2D.new()
			var from := feet + Vector2(randf_range(-bs.x * 0.4, bs.x * 0.4), -randf_range(10, bs.y * 0.9))
			l.points = PackedVector2Array([from, from + Vector2(randf_range(-6, 6), -14)])
			l.width = 3.0
			l.default_color = RiftRig.GLOW if k % 3 else RiftRig.CORE
			l.z_index = 7
			world.add_child(l)
			var lt := l.create_tween()
			lt.tween_interval(k * 0.04)
			lt.tween_property(l, "position", sky + Vector2(randf_range(-20, 20), 40) - from, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			lt.parallel().tween_property(l, "modulate:a", 0.0, 1.3)
			lt.tween_callback(l.queue_free))
	t.tween_property(c, "modulate", Color(0.6, 0.3, 0.9, 0.0), 1.4)
	# на миг в разломе — чьи-то глаза
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		var eyes := Node2D.new()
		eyes.position = sky + Vector2(0, 110.0)
		eyes.z_index = 9
		for s in [-1.0, 1.0]:
			var e := Polygon2D.new()
			e.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -2.5), Vector2(7, 0), Vector2(0, 2.5)])
			e.color = Color(0.95, 0.92, 1.0)
			e.position = Vector2(s * 10.0, 0)
			eyes.add_child(e)
		eyes.modulate.a = 0.0
		world.add_child(eyes)
		var et := eyes.create_tween()
		et.tween_property(eyes, "modulate:a", 1.0, 0.35)
		et.tween_interval(0.6)
		et.tween_property(eyes, "modulate:a", 0.0, 0.2)
		et.tween_callback(eyes.queue_free))
	t.tween_interval(1.2)
	t.tween_callback(func():
		if is_instance_valid(world):
			Util.flash(world, sky + Vector2(0, 110.0), 140.0, Color(1.0, 0.9, 1.0, 0.95))
			Fx.ring(world, sky + Vector2(0, 110.0), 200.0, RiftRig.GLOW, 0.4, 6.0))
	t.tween_callback(c.queue_free)
