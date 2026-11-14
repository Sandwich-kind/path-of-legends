extends SceneTree
# Можно ли без способностей и без МЕГА-«Ветра» добраться до алтарей (баффы и сердца)
# на картах Дуэли. Грубая геометрия: верхние грани платформ и блоков, обычный прыжок
# (~150 пикселей вверх), лианы и батуты. Для каждой карты печатает недоступные алтари.
# MAPS=id1,id2 — только эти карты.
const JUMP_H := 135.0
const SPEED := 420.0
const G := 1800.0
const V0 := 750.0

var ids: Array = []
var bad_total := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_stages()
	for m in Maps.DUEL_MAPS:
		ids.append(m["id"])
	if OS.get_environment("MAPS") != "":
		ids = Array(OS.get_environment("MAPS").split(","))

func _reach(h: float, boost := 0.0) -> float:
	# сколько можно пролететь вбок, прыгнув на высоту h
	var top := V0 * V0 / (2.0 * G) + boost
	var t_up := sqrt(2.0 * top / G)
	var t_down := sqrt(maxf(0.0, 2.0 * (top - h)) / G)
	return SPEED * (t_up + t_down) + 20.0

func _surfaces(world: Node) -> Array:
	var out: Array = []           # [x0, x1, y, one_way]
	for n in world.get_children():
		if n is StaticBody2D and (n.collision_layer & Layer.WORLD) != 0:
			for c in n.get_children():
				if c is CollisionShape2D and c.shape is RectangleShape2D and not c.disabled:
					var sz: Vector2 = c.shape.size
					var ctr: Vector2 = n.global_position + c.position
					out.append([ctr.x - sz.x / 2, ctr.x + sz.x / 2, ctr.y - sz.y / 2, c.one_way_collision])
		elif n is Destructible and not n.background:
			var d: Destructible = n
			var rows := {}
			for cc in d.cells:
				if d.cells[cc] <= 0:
					continue
				var up: Vector2i = cc + Vector2i(0, -1)
				if d.cells.has(up) and d.cells[up] > 0:
					continue
				if not rows.has(cc.y):
					rows[cc.y] = []
				rows[cc.y].append(cc.x)
			for ry in rows:
				var xs: Array = rows[ry]
				xs.sort()
				var start: int = xs[0]
				var prev: int = xs[0]
				for i in range(1, xs.size() + 1):
					if i < xs.size() and xs[i] == prev + 1:
						prev = xs[i]
						continue
					var a: Vector2 = d.global_position + d._cell_center(Vector2i(start, ry)) - Vector2(d.cell / 2, d.cell / 2)
					var b: Vector2 = d.global_position + d._cell_center(Vector2i(prev, ry)) + Vector2(d.cell / 2, -d.cell / 2)
					out.append([a.x, b.x, a.y, d.one_way])
					if i < xs.size():
						start = xs[i]
						prev = xs[i]
	return out

func _gap(a: Array, b: Array) -> float:
	if a[1] < b[0]:
		return b[0] - a[1]
	if b[1] < a[0]:
		return a[0] - b[1]
	return 0.0

func _check(id: String) -> void:
	var world := Node2D.new()
	root.add_child(world)
	Maps.preview_mode = false
	var info: Dictionary = Maps.build(world, id)
	await process_frame
	var surf := _surfaces(world)
	var vines: Array = []
	var pads: Array = []
	var spawners: Array = []
	for n in world.get_children():
		if n is ClimbVine:
			vines.append([n.global_position.x, n.global_position.y, n.global_position.y + n.length])
		elif n is BouncePad:
			pads.append([n.global_position.x - n.width / 2, n.global_position.x + n.width / 2, n.global_position.y, n.power])
		elif n is PickupSpawner:
			spawners.append(n)
	# старт — поверхности под точками появления
	var reach := {}
	var queue: Array = []
	for key in ["p1", "p2"]:
		if not info.has(key):
			continue
		var pt: Vector2 = info[key]
		var best := -1
		var bd := INF
		for i in surf.size():
			var s: Array = surf[i]
			if pt.x >= s[0] - 10 and pt.x <= s[1] + 10 and s[2] >= pt.y - 10 and s[2] - pt.y < bd:
				bd = s[2] - pt.y
				best = i
		if best >= 0 and not reach.has(best):
			reach[best] = true
			queue.append(best)
	var vine_done := {}
	while not queue.is_empty():
		var i: int = queue.pop_front()
		var a: Array = surf[i]
		var boost := 0.0
		for pd in pads:
			if pd[0] < a[1] and pd[1] > a[0] and absf(pd[2] - a[2]) < 40.0:
				boost = maxf(boost, pd[3] * pd[3] / (2.0 * G) - V0 * V0 / (2.0 * G))
		var targets: Array = []
		for j in surf.size():
			if reach.has(j):
				continue
			var b: Array = surf[j]
			var h: float = a[2] - b[2]           # >0 — выше
			if h > JUMP_H + boost:
				continue
			var gap := _gap(a, b)
			if h <= 0.0:
				if gap <= _reach(0.0, boost) + 60.0:
					targets.append(j)         # вниз — спрыгнуть
				continue
			if gap > _reach(h, boost):
				continue
			if gap == 0.0 and not b[3]:
				# сплошной блок прямо над головой: нужен край, откуда допрыгнуть сбоку
				if a[0] >= b[0] - 25.0 and a[1] <= b[1] + 25.0:
					continue
			targets.append(j)
		# лианы: допрыгнуть до низа, залезть наверх
		for vi in vines.size():
			if vine_done.has(vi):
				continue
			var v: Array = vines[vi]
			var gapv := 0.0 if v[0] >= a[0] and v[0] <= a[1] else minf(absf(v[0] - a[0]), absf(v[0] - a[1]))
			if v[2] >= a[2] - JUMP_H - 40.0 and v[1] <= a[2] and gapv <= _reach(0.0):
				vine_done[vi] = true
				for j in surf.size():
					var b2: Array = surf[j]
					if not reach.has(j) and b2[2] >= v[1] - JUMP_H and _gap([v[0], v[0]], b2) <= _reach(0.0):
						targets.append(j)
		for j in targets:
			if not reach.has(j):
				reach[j] = true
				queue.append(j)
	var bad: Array = []
	for sp in spawners:
		var pos: Vector2 = sp.global_position
		var ok := false
		for i in reach:
			var s: Array = surf[i]
			# стоять на той же поверхности или дотянуться прыжком (сфера ~40 + рост героя ~60)
			if pos.x >= s[0] - 30 and pos.x <= s[1] + 30 and pos.y <= s[2] + 5 and s[2] - pos.y <= JUMP_H + 80.0:
				ok = true
				break
		if not ok:
			bad.append("%s @(%d,%d)" % [sp.kind, int(pos.x), int(pos.y)])
	bad_total += bad.size()
	print("%-22s surfaces=%d reach=%d spawners=%d  %s" % [id, surf.size(), reach.size(), spawners.size(),
			"OK" if bad.is_empty() else "НЕДОСТУПНО: " + ", ".join(bad)])
	world.queue_free()
	await process_frame

func _initialize_done() -> void:
	pass

func _process(_d: float) -> bool:
	return false

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	for id in ids:
		await _check(id)
	print("RESULT unreachable=", bad_total)
	quit()
