class_name Util
# Вспомогательные функции: круги, вспышки, взрывы.

static func circle(r: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

static func flash(parent: Node, pos: Vector2, r: float, color: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = Fx.pixel_disc(r)                    # вспышка — круг из клеточек, как остальные эффекты
	p.color = color
	p.position = pos
	p.scale = Vector2(0.3, 0.3)
	var halo := Polygon2D.new()                                # мягкий ореол вокруг вспышки
	halo.polygon = Fx.pixel_disc(r * 1.6)
	halo.color = Color(color, color.a * 0.3)
	halo.show_behind_parent = true
	p.add_child(halo)
	Fx.host(parent).add_child(p)                # вспышка — в общий слой эффектов (см. Fx.host)
	var t := p.create_tween()
	t.set_parallel(true)
	t.tween_property(p, "scale", Vector2.ONE, 0.2)
	t.tween_property(p, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(p.queue_free)

# Взрыв: урон противникам в радиусе и выбивание клеток из объектов
# (в том числе фоновых — деревьев и задних стен). fire — поджигает горючие клетки.
static func explode(parent: Node, pos: Vector2, radius: float, player_dmg: int,
		cell_dmg: int, team: int, attacker, fire := false) -> void:
	radius *= Balance.blast_mult(attacker)         # в Дуэли взрывы легенд шире
	Audio.explosion(pos, radius)
	if radius >= 90.0:
		Fx.shake(parent, clampf(radius / 25.0, 3.0, 12.0))
	for n in parent.get_children():
		if n is Player:
			if n.team != team and n.is_alive() and n.global_position.distance_to(pos) <= radius:
				n.take_damage(player_dmg, attacker)
		elif n is Destructible and n.shield_team != team:
			n.hit(pos, Vector2.ZERO, cell_dmg, radius * 0.8, team,
					{"strict": true, "radial": true, "attacker": attacker, "fire": fire})
	flash(parent, pos, radius, Color(1.0, 0.6, 0.2))
	if radius >= 40.0:
		Fx.fireball(parent, pos, clampf(radius * 0.55, 24.0, 110.0))
		Fx.debris(parent, pos, clampi(int(radius / 14.0), 3, 12), Color(0.40, 0.36, 0.32), 300.0 + radius * 2.0, 5.0)

# На Арене снаряды пролетают сквозные платформы насквозь (стрелкам не мешают мостки)
static func arena_on(node: Node) -> bool:
	return node != null and node.is_inside_tree() and node.get_tree().get_first_node_in_group("arena_mode") != null

# Снаряд пролетает это тело: сквозная платформа на Арене
static func shot_passes(body, shot: Node) -> bool:
	return is_one_way(body) and arena_on(shot)

# Сквозная платформа (снизу пропрыгнуть, сверху стоять)
static func is_one_way(body) -> bool:
	if body is Destructible:
		return body.one_way
	if body is StaticBody2D:
		for c in body.get_children():
			if c is CollisionShape2D and c.one_way_collision:
				return true
	return false
