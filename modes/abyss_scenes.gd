class_name AbyssScenes
# ---------- Сцены последних земель (волны 91–100) ----------
#   Мельник Жернов   — земля дрожит в такт шагам: с края поля, волоча молот, выходит
#                      огромный мельник, обсыпанный мукой; в глазах — бездна.
#   Палач Бездны     — с неба падают цепи, Палач обрушивается в середину двора и
#                      волочит тесак по камню.
#   Ткачиха Разлома  — над двором из ниоткуда тянутся светлые нити и сплетаются в неё.
#   Странник         — где-то вдали открывается разлом, и из него спокойно выходит
#                      мечник в чёрном плаще и маске. Не рычит — просто поднимает меч.
#   Пробуждение дворца (после 97-й и 98-й волн) — камера смотрит на дворец: всё
#   дрожит, и он меняется прямо на глазах (AbyssStages.transform).

# Возвращает [точка, куда смотрит камера, длительность сцены]
static func intro(am: ArenaMode, kind: String) -> Array:
	var world := am.world
	var floor_y: float = am.info["floor"]
	var c: Vector2 = am.info["center"]
	var size: Vector2 = Bots.TYPES[kind]["size"]
	match kind:
		"void_shepherd":
			# звон колокола, по дальнему краю поля проносится стадо бездны, следом выходит пастух
			var side0 := 1.0 if am.players[0].position.x < c.x else -1.0
			var sx0 := c.x + side0 * 900.0
			var sx1 := c.x + side0 * 420.0
			am._after(0.3, func():
				var st := ShepherdAbilities.Stampede.new()
				st.dir = -side0
				st.count = 6
				st.fy = floor_y
				st.dmg = 0
				st.z_index = -4
				st.modulate = Color(0.8, 0.75, 0.9, 0.9)
				world.add_child(st))
			for k in 3:
				am._after(0.2 + k * 0.6, func():
					Fx.ring(world, Vector2(sx0, floor_y - 120.0), 90.0 + k * 40.0, Color(0.85, 0.6, 1.0, 0.7), 0.6, 5.0))
			am._after(1.4, func():
				var b0 := am._make_boss(kind, Vector2(sx0, floor_y - size.y / 2 - 2))
				b0.facing = int(-side0)
				b0.cutscene_walk = -side0 * 0.7
				am._after(1.8, func():
					if not is_instance_valid(b0):
						return
					b0.cutscene_walk = 0.0
					if b0.rig:
						b0.rig.play("roar")
					Util.flash(world, b0.global_position + Vector2(b0.facing * 16.0, -b0.body_size.y * 0.55), 60.0, Color(1.0, 0.9, 0.6, 0.9))
					Fx.ring(world, b0.global_position, 300.0, Color(0.85, 0.6, 1.0, 0.85), 0.5, 7.0)
					am._name_card(kind, "", "МИНИ-БОСС · ВЕТРЯНЫЕ ХОЛМЫ")))
			return [Vector2(lerpf(sx0, sx1, 0.5), floor_y - 220.0), 4.8]
		"mill_giant":
			var side := 1.0 if am.players[0].position.x < c.x else -1.0
			var x0 := c.x + side * 1050.0
			var x1 := c.x + side * 420.0
			for k in 5:
				am._after(0.3 + k * 0.5, func():
					Fx.shake(world, 4.0 + k)
					Fx.sparks(world, Vector2(lerpf(x0, x1, k / 4.0), floor_y - 4), Color(0.95, 0.92, 0.85), 10, 220.0, 5.0, true))
			am._after(0.8, func():
				var b := am._make_boss(kind, Vector2(x0, floor_y - size.y / 2 - 2))
				b.facing = int(-side)
				b.cutscene_walk = -side
				am._after(1.9, func():
					if not is_instance_valid(b):
						return
					b.cutscene_walk = 0.0
					if b.rig:
						b.rig.play("roar")
					var fc := AbyssAbilities.FlourCloud.new()
					fc.team = b.team
					fc.life = 1.6
					fc.position = b.global_position
					world.add_child(fc)
					Fx.shake(world, 12.0)
					am._name_card(kind, "", "МИНИ-БОСС · ВЕТРЯНЫЕ ХОЛМЫ")))
			return [Vector2(lerpf(x0, x1, 0.6), floor_y - 220.0), 4.6]
		"abyss_headsman":
			var hx := am._clear_x(c.x + 120.0, 300.0)
			for k in 6:
				am._after(0.2 + k * 0.12, func():
					var ch := Line2D.new()
					ch.width = 4.0
					ch.default_color = Color(0.40, 0.36, 0.46)
					var x := hx + randf_range(-260, 260)
					ch.points = PackedVector2Array([Vector2(x, -200), Vector2(x, -200)])
					ch.z_index = 4
					world.add_child(ch)
					var ct := ch.create_tween()
					ct.tween_method(func(y: float):
						if is_instance_valid(ch):
							ch.points = PackedVector2Array([Vector2(x, -200), Vector2(x, y)]), -200.0, floor_y - randf_range(80, 300), 0.4)
					ct.tween_interval(2.4)
					ct.tween_property(ch, "modulate:a", 0.0, 0.4)
					ct.tween_callback(ch.queue_free))
			am._after(1.2, func():
				var land := Vector2(hx, floor_y - size.y / 2 - 2)
				var b := am._make_boss(kind, land + Vector2(0, -900))
				b.set_physics_process(false)
				b.facing = -1 if am.players[0].position.x < hx else 1
				var t := b.create_tween()
				t.tween_property(b, "global_position", land, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				t.tween_callback(func():
					if not is_instance_valid(b):
						return
					b.set_physics_process(true)
					Fx.shake(world, 16.0)
					Fx.ring(world, Vector2(hx, floor_y), 260.0, Color(0.85, 0.5, 1.0, 0.9), 0.5, 9.0, 0.3)
					Fx.cracks(world, Vector2(hx, floor_y), Color(0.25, 0.10, 0.32), 180.0)
					Fx.sparks(world, Vector2(hx, floor_y - 8), RiftRig.GLOW, 24, 340.0, 5.0, true)
					am._after(0.7, func():
						if is_instance_valid(b) and b.rig:
							b.rig.play("roar")
						am._name_card(kind, "", "МИНИ-БОСС · ДВОРЕЦ БЕЗДНЫ"))))
			return [Vector2(hx, floor_y - 260.0), 4.8]
		"rift_weaver":
			var wx := am._clear_x(c.x - 100.0, 320.0)
			var at := Vector2(wx, floor_y - size.y * 0.55)
			for k in 22:
				am._after(0.2 + k * 0.07, func():
					var from := at + Vector2.from_angle(randf() * TAU) * randf_range(500, 900)
					var l := Line2D.new()
					l.width = 2.0
					l.default_color = Color(0.92, 0.85, 1.0, 0.8)
					l.points = PackedVector2Array([from, from])
					l.z_index = 7
					world.add_child(l)
					var lt := l.create_tween()
					lt.tween_method(func(q: float):
						if is_instance_valid(l):
							l.points = PackedVector2Array([from, from.lerp(at, q)]), 0.0, 1.0, 0.5)
					lt.tween_property(l, "modulate:a", 0.0, 0.6)
					lt.tween_callback(l.queue_free))
			am._after(2.0, func():
				var b := am._make_boss(kind, Vector2(wx, floor_y - size.y / 2 - 2))
				b.facing = -1 if am.players[0].position.x < wx else 1
				b.modulate = Color(1, 1, 1, 0)
				b.create_tween().tween_property(b, "modulate:a", 1.0, 0.6)
				Util.flash(world, at, 160.0, Color(0.9, 0.8, 1.0, 0.9))
				am._after(0.7, func():
					if is_instance_valid(b) and b.rig:
						b.rig.play("roar")
					Fx.shake(world, 10.0)
					am._name_card(kind, "", "МИНИ-БОСС · ДВОРЕЦ БЕЗДНЫ")))
			return [Vector2(wx, floor_y - 260.0), 4.6]
		"wanderer":
			var side2 := 1.0 if am.players[0].position.x < c.x else -1.0
			var rx := c.x + side2 * 700.0
			var tear := RiftAbilities.Slit.new()
			tear.position = Vector2(rx, floor_y)
			tear.height = 240.0
			tear.wide = 2.6
			tear.life = 4.4
			am._after(0.5, func():
				world.add_child(tear)
				Fx.shake(world, 6.0))
			am._after(1.0, func(): am._banner_text("…", Color(0.9, 0.8, 1.0)))
			am._after(1.6, func():
				var b := am._make_boss(kind, Vector2(rx, floor_y - size.y / 2 - 2))
				b.facing = int(-side2)
				b.modulate = Color(1, 1, 1, 0)
				b.create_tween().tween_property(b, "modulate:a", 1.0, 0.8)
				b.cutscene_walk = -side2 * 0.55              # идёт спокойно, не спеша
				am._after(2.2, func():
					if not is_instance_valid(b):
						return
					b.cutscene_walk = 0.0
					if b.rig:
						b.rig.play("cast")
					Util.flash(world, b.global_position + Vector2(0, -b.body_size.y * 0.4), 90.0, Color(0.85, 0.6, 1.0, 0.85))
					am._name_card(kind, "", "ТОТ, КТО ПОГЛОТИЛ БЕЗДНУ")))
			am._after(4.6, func(): am._banner_text("Странник: «Покажи, на что способен. Мне любопытно.»", Color(0.85, 0.75, 1.0)))
			return [Vector2(c.x + side2 * 450.0, floor_y - 240.0), 6.4]
	return [Vector2(c.x, floor_y - 200.0), 4.6]

# Дворец пробуждается (после 97-й — трещины, после 98-й — раскрывается око над ним, земля раскалывается)
static func palace_wakes(am: ArenaMode, level: int) -> float:
	var world := am.world
	var floor_y: float = am.info["floor"]
	var mark := Node2D.new()
	mark.position = Vector2(Colosseum.W / 2.0, floor_y - 380.0)
	world.add_child(mark)
	am.cinematic(mark, 4.4, true)
	am.shield_heroes(5.2)
	for k in 6:
		am._after(0.3 + k * 0.25, func(): Fx.shake(world, 3.0 + k * 1.5))
	am._after(0.6, func():
		am.hud.show_banner("Дворец пробуждается…" if level == 1 else "Око Бездны раскрывается!", Color(0.85, 0.6, 1.0))
		am._after(1.6, am.hud.hide_banner))
	am._after(1.6, func(): AbyssStages.transform(world, am.info, level, 2.4))
	am._after(4.8, mark.queue_free)
	return 5.0
