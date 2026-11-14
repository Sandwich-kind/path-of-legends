class_name Fx
# Эффекты для ульт и способностей: кольца, искры, руны, листья, вспышки.
# Всё рисуется простыми полигонами и плавно исчезает само.

# «Эффекты: упрощённые» (Настройки → Игра и звук): без пыли, дыма, обломков и конфетти,
# искр меньше. Механика та же — убираются только украшения, чтобы слабый телефон не тормозил.
static var lite := false

static func load_setting() -> void:
	lite = StorySettings.get_value("fx_lite") == true

# Одноразовые эффекты (искры, пыль, кольца, вспышки) живут не прямо в мире боя, а в одном общем
# узле-слое. Иначе сотни частиц попадают в список детей мира, а его каждый кадр перебирают
# способности, боты и снаряды в поисках врагов. Слой держится последним среди детей мира:
# частицы, как и раньше, рисуются поверх ровесников по z_index.
static var _moved_frame := -1

static func host(parent: Node) -> Node:
	if parent == null or not parent.has_meta("fx_world"):
		return parent                                       # не мир боя (эффект внутри героя и т. п.) — как есть
	var l = parent.get_meta("fx_layer") if parent.has_meta("fx_layer") else null
	if l == null or not is_instance_valid(l) or l.is_queued_for_deletion() or l.get_parent() != parent:
		l = Node2D.new()
		l.name = "FxLayer"
		parent.add_child(l)
		parent.set_meta("fx_layer", l)
	elif l.get_index() != parent.get_child_count() - 1 and Engine.get_process_frames() != _moved_frame:
		_moved_frame = Engine.get_process_frames()
		parent.move_child(l, -1)
	return l

# ---------- Пиксельный стиль ----------
# Общие эффекты нарисованы «по клеточкам», как модели и Титан: круги — со ступенчатым краем,
# искры и обломки — квадратики, кольца — ступеньками. Гладких окружностей и ромбов нет.
const PIX := 4.0                 # наименьшая клеточка эффектов

# Закрашенный круг из клеточек (ступенчатый контур). cell — размер клеточки; 0 — по размеру круга
static func pixel_disc(r: float, cell := 0.0) -> PackedVector2Array:
	var g := cell if cell > 0.0 else clampf(r / 4.5, PIX, 16.0)
	var rows := maxi(1, int(round(r / g)))
	var rr := rows * g                  # радиус, кратный клеточке: без «шипов» в один пиксель сверху и с боков
	var right := PackedVector2Array()
	var left := PackedVector2Array()
	for i in range(-rows, rows):
		var yc := (i + 0.5) * g
		var w := maxf(g, round(sqrt(maxf(0.0, rr * rr - yc * yc)) / g) * g)
		right.append(Vector2(w, i * g))
		right.append(Vector2(w, (i + 1) * g))
		left.append(Vector2(-w, i * g))
		left.append(Vector2(-w, (i + 1) * g))
	left.reverse()
	right.append_array(left)
	return right

# Окружность единичного радиуса «лесенкой»: только горизонтальные и вертикальные отрезки.
# radius — каким кольцо станет на экране (от него зависит размер ступеньки)
static func pixel_loop(radius: float, flat := 1.0) -> PackedVector2Array:
	var n := clampi(int(round(radius * PI / 2.0 / clampf(radius / 6.0, 6.0, 18.0))), 2, 12)
	var pts := PackedVector2Array()
	for k in n * 4:
		var a := Vector2.from_angle(PI / 2.0 * k / n)
		var b := Vector2.from_angle(PI / 2.0 * (k + 1) / n)
		pts.append(Vector2(a.x, a.y * flat))
		# угол ступеньки — снаружи окружности
		pts.append(Vector2(a.x if absf(a.x) > absf(b.x) else b.x, (a.y if absf(a.y) > absf(b.y) else b.y) * flat))
	pts.append(pts[0])
	return pts

static func _square(h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])

# Расходящееся кольцо (ударная волна)
static func ring(parent: Node, pos: Vector2, radius: float, color: Color, time := 0.45, width := 6.0,
		flat := 1.0) -> void:
	var l := Line2D.new()
	var pts := pixel_loop(radius, flat)
	l.points = pts
	l.joint_mode = Line2D.LINE_JOINT_SHARP
	l.width = width / maxf(radius, 1.0)
	l.default_color = color
	l.position = pos
	l.scale = Vector2(radius * 0.2, radius * 0.2)
	l.z_index = 8
	var halo := Line2D.new()                                   # мягкое свечение вокруг волны
	halo.points = pts
	halo.width = l.width * 2.6
	halo.default_color = Color(color, color.a * 0.28)
	l.add_child(halo)
	host(parent).add_child(l)
	var t := l.create_tween()
	t.set_parallel(true)
	t.tween_property(l, "scale", Vector2(radius, radius), time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, time)
	t.chain().tween_callback(l.queue_free)

# Искры, разлетающиеся во все стороны
static func sparks(parent: Node, pos: Vector2, color: Color, n := 12, speed := 260.0, size := 5.0,
		up := false) -> void:
	if lite:
		n = maxi(1, int(ceil(n * 0.4)))                     # упрощённые эффекты: искр меньше
	for i in n:
		var s := Polygon2D.new()
		s.polygon = _square(maxf(1.5, size * (0.55 if i % 3 == 0 else 0.4)))      # квадратные «пиксели» двух размеров
		s.color = color.lightened(randf_range(0.0, 0.3))
		s.position = pos
		s.z_index = 9
		host(parent).add_child(s)
		var a := randf() * TAU
		if up:
			a = -PI / 2 + randf_range(-0.9, 0.9)
		var d := Vector2.from_angle(a) * speed * randf_range(0.4, 1.0)
		var t := s.create_tween()
		t.set_parallel(true)
		t.tween_property(s, "position", pos + d * 0.5, randf_range(0.3, 0.6)).set_ease(Tween.EASE_OUT)
		t.tween_property(s, "modulate:a", 0.0, 0.6)
		t.chain().tween_callback(s.queue_free)

# Вращающийся круг с рунами (на земле — сплющенный)
static func rune_circle(parent: Node, pos: Vector2, radius: float, color: Color, time: float, flat := 0.3) -> Node2D:
	var root := Node2D.new()
	root.position = pos
	root.z_index = 2
	parent.add_child(root)
	var spin := Node2D.new()
	root.add_child(spin)
	for r in [radius, radius * 0.72]:
		var l := Line2D.new()
		var pts := Util.circle(r, 40)
		pts.append(pts[0])
		l.points = pts
		l.width = 3.0
		l.default_color = color
		spin.add_child(l)
	for i in 8:                              # руны по кругу
		var a := TAU * i / 8.0
		var g := Polygon2D.new()
		var c := Vector2.from_angle(a) * radius * 0.86
		g.polygon = PackedVector2Array([c + Vector2(0, -7), c + Vector2(5, 0), c + Vector2(0, 7), c + Vector2(-5, 0)])
		g.color = color.lightened(0.3)
		spin.add_child(g)
	root.scale = Vector2(0.1, 0.1 * flat)
	var t := root.create_tween()
	t.tween_property(root, "scale", Vector2(1.0, flat), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(maxf(0.0, time - 0.55))
	t.tween_property(root, "modulate:a", 0.0, 0.3)
	t.tween_callback(root.queue_free)
	var st := spin.create_tween().set_loops(int(ceil(time / 1.2)) + 1)
	st.tween_property(spin, "rotation", TAU, 1.2).from(0.0)
	return root

# Мягкое свечение (круг, который пульсирует и тает)
static func glow(parent: Node, pos: Vector2, radius: float, color: Color, time: float) -> Polygon2D:
	var g := Polygon2D.new()
	g.polygon = pixel_disc(radius)
	g.color = color
	g.position = pos
	g.z_index = 7
	parent.add_child(g)
	g.scale = Vector2(0.2, 0.2)
	var t := g.create_tween()
	t.tween_property(g, "scale", Vector2.ONE, time * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(time * 0.4)
	t.tween_property(g, "modulate:a", 0.0, time * 0.2)
	t.tween_callback(g.queue_free)
	return g

# Звезда-вспышка (на острие копья, в руке)
static func star(parent: Node, pos: Vector2, radius: float, color: Color, time: float) -> Polygon2D:
	var s := Polygon2D.new()
	# пиксельная «искорка»: крест из клеточек с квадратной сердцевиной
	var h := maxf(2.0, round(radius * 0.22))
	var m := h * 2.0
	s.polygon = PackedVector2Array([Vector2(-h, -radius), Vector2(h, -radius), Vector2(h, -m), Vector2(m, -m), Vector2(m, -h),
			Vector2(radius, -h), Vector2(radius, h), Vector2(m, h), Vector2(m, m), Vector2(h, m), Vector2(h, radius),
			Vector2(-h, radius), Vector2(-h, m), Vector2(-m, m), Vector2(-m, h), Vector2(-radius, h), Vector2(-radius, -h),
			Vector2(-m, -h), Vector2(-m, -m), Vector2(-h, -m)])
	s.color = color
	s.position = pos
	s.z_index = 9
	parent.add_child(s)
	s.scale = Vector2.ZERO
	var t := s.create_tween()
	t.set_parallel(true)
	t.tween_property(s, "scale", Vector2.ONE, time * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(s, "modulate:a", 0.0, time * 0.4)
	t.chain().tween_callback(s.queue_free)
	return s

# Вихрь листьев вокруг героя (превращение Терновника)
static func leaf_swirl(parent: Node, center: Node2D, radius: float, time: float, n := 18) -> void:
	var sw := LeafSwirl.new()
	sw.center = center
	sw.radius = radius
	sw.time = time
	sw.count = n
	host(parent).add_child(sw)

# Листья, разлетающиеся при превращении
static func leaf_burst(parent: Node, pos: Vector2, n := 24) -> void:
	for i in n:
		var leaf := Polygon2D.new()
		leaf.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(0, -4), Vector2(7, 0), Vector2(0, 4)])
		leaf.color = Color(0.3, 0.7, 0.25).lightened(randf_range(0.0, 0.3))
		leaf.position = pos
		leaf.z_index = 9
		host(parent).add_child(leaf)
		var d := Vector2.from_angle(randf() * TAU) * randf_range(80, 220)
		var t := leaf.create_tween()
		t.set_parallel(true)
		t.tween_property(leaf, "position", pos + d + Vector2(0, 60), 0.9).set_ease(Tween.EASE_OUT)
		t.tween_property(leaf, "rotation", randf_range(-6, 6), 0.9)
		t.tween_property(leaf, "modulate:a", 0.0, 0.9).set_delay(0.3)
		t.chain().tween_callback(leaf.queue_free)

# Трещины в земле после удара
static func cracks(parent: Node, pos: Vector2, color: Color, length := 90.0) -> void:
	Audio.sfx("slam", pos)                 # удар оземь
	for i in 6:
		var l := Line2D.new()
		var a := PI + PI * (i + 0.5) / 6.0 + randf_range(-0.15, 0.15)
		var pts := PackedVector2Array([Vector2.ZERO])
		var p := Vector2.ZERO
		for k in 4:
			p += Vector2.from_angle(a + randf_range(-0.4, 0.4)) * length / 4.0 * Vector2(1.0, 0.25)
			pts.append(p)
		l.points = pts
		l.width = 3.0
		l.default_color = color
		l.position = pos
		l.z_index = 3
		host(parent).add_child(l)
		var t := l.create_tween()
		t.tween_interval(0.8)
		t.tween_property(l, "modulate:a", 0.0, 0.6)
		t.tween_callback(l.queue_free)

# След удара оружием: светлый полумесяц от угла a0 до a1 (вокруг центра)
static func arc(parent: Node, pos: Vector2, radius: float, a0: float, a1: float, color: Color,
		time := 0.22, thick := 26.0) -> void:
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(Vector2.from_angle(a) * radius)
	for i in range(n, -1, -1):
		var a := lerpf(a0, a1, float(i) / n)
		var k := sin(PI * float(i) / n)            # к краям полумесяц тоньше
		pts.append(Vector2.from_angle(a) * (radius - thick * k))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = color
	poly.position = pos
	poly.z_index = 8
	host(parent).add_child(poly)
	var t := poly.create_tween()
	t.set_parallel(true)
	t.tween_property(poly, "modulate:a", 0.0, time)
	t.tween_property(poly, "scale", Vector2(1.12, 1.12), time)
	t.chain().tween_callback(poly.queue_free)

# Огненное кольцо вокруг героя (МЕГА-ульта Кузнеца) — следует за ним
static func flame_ring(target: Node2D, radius: float, time: float) -> Node2D:
	var root := Node2D.new()
	root.z_index = 3
	target.add_child(root)
	for i in 16:
		var f := Polygon2D.new()
		f.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(0, -22), Vector2(7, 0), Vector2(0, 5)])
		f.color = Color(1.0, 0.45 + 0.3 * (i % 2), 0.1, 0.8)
		f.position = Vector2.from_angle(TAU * i / 16.0) * Vector2(radius, radius * 0.2)
		root.add_child(f)
	var ring := Line2D.new()
	var pts := Util.circle(radius, 40)
	pts.append(pts[0])
	for i in pts.size():
		pts[i].y *= 0.2
	ring.points = pts
	ring.width = 5.0
	ring.default_color = Color(1.0, 0.55, 0.15, 0.7)
	root.add_child(ring)
	root.position = Vector2(0, 22)
	root.scale = Vector2(0.2, 0.2)
	var t := root.create_tween()
	t.tween_property(root, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(maxf(0.0, time - 0.6))
	t.tween_property(root, "modulate:a", 0.0, 0.3)
	t.tween_callback(root.queue_free)
	return root

# Электрический разряд вокруг точки (ломаные искры)
static func zap(parent: Node, pos: Vector2, color: Color, r := 26.0) -> void:
	Audio.sfx("zap", pos, -6.0)
	for i in 5:
		var l := Line2D.new()
		var a := randf() * TAU
		var pts := PackedVector2Array([Vector2.ZERO])
		var q := Vector2.ZERO
		for k in 4:
			q += Vector2.from_angle(a + randf_range(-0.8, 0.8)) * r / 4.0
			pts.append(q)
		l.points = pts
		l.width = 2.0
		l.default_color = color
		l.position = pos
		l.z_index = 9
		host(parent).add_child(l)
		var t := l.create_tween()
		t.tween_property(l, "modulate:a", 0.0, 0.25)
		t.tween_callback(l.queue_free)

# Молния от точки к точке
static func bolt(parent: Node, a: Vector2, b: Vector2, color: Color) -> void:
	Audio.sfx("zap", (a + b) / 2.0)
	var l := Line2D.new()
	var pts := PackedVector2Array([a])
	var n := 7
	for i in range(1, n):
		var q := a.lerp(b, float(i) / n)
		pts.append(q + (b - a).orthogonal().normalized() * randf_range(-14.0, 14.0))
	pts.append(b)
	l.points = pts
	l.width = 3.0
	l.default_color = color
	l.z_index = 9
	host(parent).add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "modulate:a", 0.0, 0.3)
	t.tween_callback(l.queue_free)

# Ледяная корка на замороженном враге (тает сама)
static func ice(target: Node2D, size: Vector2, time: float) -> void:
	var root := Node2D.new()
	root.z_index = 6
	target.add_child(root)
	var block := Polygon2D.new()
	var hw := size.x * 0.65
	var hh := size.y * 0.6
	block.polygon = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw * 0.6, -hh * 1.1), Vector2(hw, -hh * 0.2),
			Vector2(hw * 0.9, hh), Vector2(-hw * 0.8, hh), Vector2(-hw * 1.05, 0)])
	block.color = Color(0.6, 0.85, 1.0, 0.45)
	root.add_child(block)
	for k in 3:
		var sh := Line2D.new()
		sh.points = PackedVector2Array([Vector2(-hw * 0.5 + k * hw * 0.4, -hh * 0.7), Vector2(-hw * 0.3 + k * hw * 0.4, -hh * 0.2)])
		sh.width = 2.0
		sh.default_color = Color(1, 1, 1, 0.7)
		root.add_child(sh)
	var t := root.create_tween()
	t.tween_interval(maxf(0.0, time - 0.25))
	t.tween_property(root, "modulate:a", 0.0, 0.25)
	t.tween_callback(root.queue_free)

# Тряска экрана (если не выключена в настройках): камера дрожит и успокаивается
static var _shake_until := 0
static func shake(node: Node, strength: float) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	if not bool(StorySettings.get_value("screen_shake")):
		return
	var now := Time.get_ticks_msec()
	if now < _shake_until - 120:
		return                          # уже трясётся — не наслаиваем
	var cam := node.get_viewport().get_camera_2d()
	if cam == null:
		return
	_shake_until = now + 260
	var t := cam.create_tween()
	for i in 6:
		var k := 1.0 - i / 6.0
		t.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, 0.04)
	t.tween_property(cam, "offset", Vector2.ZERO, 0.04)

# ---------- Эпичные эффекты: пыль, обломки, дым, огненный шар, ударная волна ----------
# Клубы пыли у земли: мягкие круги расползаются в стороны и тают
static func dust(parent: Node, pos: Vector2, n := 8, color := Color(0.62, 0.58, 0.52), spread := 90.0, size := 18.0) -> void:
	if lite or not is_instance_valid(parent):
		return
	for i in n:
		var d := Polygon2D.new()
		d.polygon = pixel_disc(size * randf_range(0.6, 1.2))
		d.color = Color(color, randf_range(0.45, 0.7))
		d.position = pos + Vector2(randf_range(-12, 12), randf_range(-6, 2))
		d.z_index = 7
		d.scale = Vector2(0.4, 0.4)
		host(parent).add_child(d)
		var side := -1.0 if i % 2 == 0 else 1.0
		var to := d.position + Vector2(side * randf_range(0.3, 1.0) * spread, -randf_range(8.0, 40.0))
		var t := d.create_tween().set_parallel(true)
		t.tween_property(d, "position", to, randf_range(0.5, 0.9)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property(d, "scale", Vector2.ONE * randf_range(1.2, 1.8), 0.8)
		t.tween_property(d, "modulate:a", 0.0, 0.9).set_delay(0.15)
		t.chain().tween_callback(d.queue_free)

# Обломки: камешки/куски разлетаются по дуге и падают
static func debris(parent: Node, pos: Vector2, n := 8, color := Color(0.42, 0.38, 0.34), power := 420.0, size := 6.0) -> void:
	if lite or not is_instance_valid(parent):
		return
	for i in n:
		var c := Polygon2D.new()
		var s := size * randf_range(0.6, 1.3)
		c.polygon = PackedVector2Array([Vector2(-s, -s * 0.6), Vector2(s, -s * 0.6), Vector2(s, s * 0.6), Vector2(-s, s * 0.6)])   # кусок-«кирпичик»
		c.color = color.lightened(randf_range(-0.1, 0.2))
		c.position = pos
		c.z_index = 8
		host(parent).add_child(c)
		var v := Vector2(randf_range(-0.8, 0.8), -randf_range(0.5, 1.0)) * power
		var life := randf_range(0.55, 0.9)
		var spin := randf_range(-12.0, 12.0)
		var t := c.create_tween()
		t.tween_method(func(q: float):
			if is_instance_valid(c):
				var tt := q * life
				c.position = pos + v * tt + Vector2(0, 1400.0 * tt * tt * 0.5)
				c.rotation = snappedf(spin * tt, PI / 2.0)                # кувыркается рывками по четверть оборота
				c.modulate.a = 1.0 - maxf(0.0, q - 0.7) / 0.3, 0.0, 1.0, life)
		t.tween_callback(c.queue_free)

# Клуб дыма: поднимается и расплывается
static func smoke(parent: Node, pos: Vector2, size := 20.0, color := Color(0.30, 0.30, 0.33), rise := 60.0) -> void:
	if lite or not is_instance_valid(parent):
		return
	var s := Polygon2D.new()
	s.polygon = pixel_disc(size)
	s.color = Color(color, 0.6)
	s.position = pos
	s.z_index = 7
	s.scale = Vector2(0.5, 0.5)
	host(parent).add_child(s)
	var t := s.create_tween().set_parallel(true)
	t.tween_property(s, "position", pos + Vector2(randf_range(-20, 20), -rise), 1.0).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "scale", Vector2.ONE * 1.8, 1.0)
	t.tween_property(s, "modulate:a", 0.0, 1.0)
	t.chain().tween_callback(s.queue_free)

# Огненный шар взрыва: белое ядро, оранжевое пламя, тёмный дым следом
static func fireball(parent: Node, pos: Vector2, radius := 60.0, hot := Color(1.0, 0.75, 0.30), dark := Color(0.85, 0.30, 0.08)) -> void:
	if not is_instance_valid(parent):
		return
	for k in 3:
		var b := Polygon2D.new()
		b.polygon = pixel_disc(radius * [1.0, 0.7, 0.4][k], clampf(radius / 6.0, PIX, 12.0))
		b.color = [Color(dark, 0.85), Color(hot, 0.95), Color(1.0, 0.97, 0.85)][k]
		b.position = pos
		b.z_index = 8 + k
		b.scale = Vector2(0.2, 0.2)
		host(parent).add_child(b)
		var t := b.create_tween()
		t.tween_property(b, "scale", Vector2.ONE, 0.12 + k * 0.02).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(b, "modulate:a", 0.0, 0.25 + (2 - k) * 0.1)
		t.tween_callback(b.queue_free)
	for k in 4:
		smoke(parent, pos + Vector2(randf_range(-radius, radius) * 0.5, randf_range(-radius, 0) * 0.4), radius * 0.45)
	sparks(parent, pos, hot, 10, radius * 5.0, 4.0)

# Ударная волна: светлое кольцо, сразу за ним — дрожащее «марево» и вспышка в центре
static func shockwave(parent: Node, pos: Vector2, radius: float, color: Color, flat := 0.35) -> void:
	ring(parent, pos, radius, color, 0.45, 10.0, flat)
	ring(parent, pos, radius * 0.75, Color(1, 1, 1, 0.7), 0.3, 5.0, flat)
	ring(parent, pos, radius * 1.15, Color(color, 0.35), 0.6, 16.0, flat)
	Util.flash(parent, pos, radius * 0.35, Color(1.0, 0.97, 0.9, 0.85))

# ---------- Для всех легенд: приём и ульта выглядят весомее ----------
# Приём: под ногами вспыхивает кольцо цвета легенды, вверх — искры
static func cast_flourish(p: Node2D, c: Color) -> void:
	var world := p.get_parent()
	if not is_instance_valid(world):
		return
	var feet: Vector2 = p.global_position + Vector2(0, p.body_size.y / 2)
	ring(world, feet, 46.0, Color(c, 0.85), 0.3, 4.0, 0.3)
	sparks(world, feet + Vector2(0, -6), c.lightened(0.35), 5, 160.0, 3.0, true)

# Ульта: лучи света из героя, ударная волна и полоса с названием ульты через весь кадр
static func ult_cutin(p: Node2D, c: Color, title: String) -> void:
	var world := p.get_parent()
	if not is_instance_valid(world):
		return
	var at: Vector2 = p.global_position
	var rays := Node2D.new()                                  # лучи
	rays.position = at
	rays.z_index = 6
	world.add_child(rays)
	for k in 12:
		var r := Polygon2D.new()
		var a := TAU * k / 12.0
		r.polygon = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a - 0.06) * 260.0, Vector2.from_angle(a + 0.06) * 260.0])
		r.color = Color(c.lightened(0.4), 0.35 if k % 2 == 0 else 0.2)
		rays.add_child(r)
	rays.scale = Vector2(0.2, 0.2)
	var rt := rays.create_tween().set_parallel(true)
	rt.tween_property(rays, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rt.tween_property(rays, "rotation", 0.8, 0.9)
	rt.tween_property(rays, "modulate:a", 0.0, 0.5).set_delay(0.4)
	rt.chain().tween_callback(rays.queue_free)
	shockwave(world, at + Vector2(0, p.body_size.y / 2), 150.0, c, 0.35)
	glow(world, at, 70.0, Color(c.lightened(0.5), 0.45), 0.5)
	if title == "":
		return
	var band := Node2D.new()                                  # полоса с названием
	band.position = at + Vector2(0, -150)
	band.z_index = 11
	world.add_child(band)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2(-460, -26), Vector2(480, -34), Vector2(460, 26), Vector2(-480, 34)])
	bg.color = Color(c.darkened(0.55), 0.82)
	band.add_child(bg)
	for k in 2:
		var edge := Polygon2D.new()
		var y := -34.0 if k == 0 else 30.0
		edge.polygon = PackedVector2Array([Vector2(-480, y), Vector2(480, y - 8.0), Vector2(480, y - 4.0), Vector2(-480, y + 4.0)])
		edge.color = c.lightened(0.3)
		band.add_child(edge)
	var l := Label.new()
	l.text = title.to_upper()
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", c.darkened(0.7))
	l.position = Vector2(-l.get_minimum_size().x / 2, -26)
	band.add_child(l)
	band.position.x -= 900.0
	band.modulate.a = 0.0
	var bt := band.create_tween()
	bt.tween_property(band, "position:x", at.x, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bt.parallel().tween_property(band, "modulate:a", 1.0, 0.12)
	bt.tween_property(band, "position:x", at.x + 40.0, 0.6)
	bt.tween_property(band, "position:x", at.x + 900.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	bt.parallel().tween_property(band, "modulate:a", 0.0, 0.18)
	bt.tween_callback(band.queue_free)

# Конфетти: разноцветные бумажки вылетают вверх, кружатся и падают
static func confetti(parent: Node, pos: Vector2, n := 20, colors: Array = [], power := 520.0) -> void:
	if lite or not is_instance_valid(parent):
		return
	var cols: Array = colors if not colors.is_empty() else [Color(1.0, 0.36, 0.80), Color(0.30, 0.90, 1.0), Color(1.0, 0.92, 0.25), Color(0.45, 1.0, 0.45)]
	for i in n:
		var c := Polygon2D.new()
		c.polygon = PackedVector2Array([Vector2(-3, -1.5), Vector2(3, -1.5), Vector2(3, 1.5), Vector2(-3, 1.5)])
		c.color = cols[i % cols.size()]
		c.position = pos
		c.z_index = 9
		host(parent).add_child(c)
		var v := Vector2(randf_range(-0.7, 0.7), -randf_range(0.6, 1.0)) * power
		var life := randf_range(1.0, 1.6)
		var spin := randf_range(-14.0, 14.0)
		var wob := randf_range(6.0, 12.0)
		var t := c.create_tween()
		t.tween_method(func(q: float):
			if is_instance_valid(c):
				var tt := q * life
				c.position = pos + Vector2(v.x * tt * 0.6 + sin(tt * wob) * 14.0, v.y * tt + 450.0 * tt * tt)
				c.rotation = spin * tt
				c.scale.y = absf(sin(tt * wob * 1.5))
				c.modulate.a = 1.0 - maxf(0.0, q - 0.75) / 0.25, 0.0, 1.0, life)
		t.tween_callback(c.queue_free)
