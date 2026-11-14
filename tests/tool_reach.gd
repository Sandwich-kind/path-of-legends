extends SceneTree
# Проверка карт: до каждой ли площадки можно допрыгнуть без баффов.
# Прыжок героя: jump_force 750, gravity 1800 → высота ~156 px (берём 148 с запасом).
const JUMP_H := 148.0
const GAP := 220.0
var ids: Array = []
var i := 0
var f := 0
var world: Node2D

func _initialize() -> void:
	Save.load_game()
	for m in Maps.DUEL_MAPS:
		if not String(m["id"]).begins_with("test"):
			ids.append(m["id"])
	for extra in ["@hall", "@abyss", "@palace1", "@palace2"]:
		ids.append(extra)
	if OS.get_environment("ONLY") != "":
		ids = Array(OS.get_environment("ONLY").split(","))

func _surfaces(w: Node) -> Array:
	var rects: Array = []
	var stack: Array = [w]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is CollisionObject2D and (n.collision_layer & Layer.WORLD) != 0:
			for c in n.get_children():
				if c is CollisionShape2D and c.shape is RectangleShape2D and not c.disabled:
					var sz: Vector2 = (c.shape as RectangleShape2D).size * c.global_scale.abs()
					var o: Vector2 = c.global_position
					rects.append(Rect2(o - sz / 2, sz))
	var res: Array = []
	for r in rects:
		if r.size.x < 30:
			continue
		var covered := false
		for q in rects:
			if q != r and q.position.y < r.position.y and q.end.y >= r.position.y - 6 and q.position.x <= r.position.x + 4 and q.end.x >= r.end.x - 4:
				covered = true
				break
		if not covered:
			res.append([r.position.x, r.end.x, r.position.y])
	return res

func _physics_process(_d: float) -> bool:
	f += 1
	if f % 3 != 1:
		return false
	if world:
		world.queue_free()
		world = null
	if i >= ids.size():
		print("DONE")
		return true
	var id: String = ids[i]
	i += 1
	world = Node2D.new()
	root.add_child(world)
	var info: Dictionary
	match id:
		"@hall": info = AbyssStages.hall(world)
		"@abyss": info = AbyssStages.abyss(world)
		"@palace1": info = AbyssStages.palace(world, 1)
		"@palace2": info = AbyssStages.palace(world, 2)
		_: info = Maps.build(world, id)
	var surf := _surfaces(world)
	var starts: Array = []
	for key in ["p1", "p2", "center"]:
		if info.has(key):
			starts.append(info[key])
	var reach := {}
	var queue: Array = []
	for s in starts:
		var best := -1
		for k in surf.size():
			var sf: Array = surf[k]
			if s.x >= sf[0] - 10 and s.x <= sf[1] + 10 and sf[2] >= s.y - 10 and (best < 0 or sf[2] < surf[best][2]):
				best = k
		if best >= 0 and not reach.has(best):
			reach[best] = true
			queue.append(best)
	if OS.get_environment("DBG") == "1":
		print("starts ", starts, " start surfs ", queue.map(func(q): return surf[q]))
	while not queue.is_empty():
		var a: Array = surf[queue.pop_front()]
		for k in surf.size():
			if reach.has(k):
				continue
			var b: Array = surf[k]
			var gap := maxf(0.0, maxf(b[0] - a[1], a[0] - b[1]))
			var up: float = a[2] - b[2]
			if (up <= JUMP_H and up >= 0.0 and gap <= GAP) or (up < 0.0 and gap <= GAP):
				reach[k] = true
				queue.append(k)
	var bad: Array = []
	for k in surf.size():
		if not reach.has(k):
			var b: Array = surf[k]
			var need := INF
			for kk in reach:
				var a: Array = surf[kk]
				var gap := maxf(0.0, maxf(b[0] - a[1], a[0] - b[1]))
				if gap <= GAP and a[2] > b[2]:
					need = minf(need, a[2] - b[2])
			bad.append("x%d-%d y%d (+%s)" % [int(b[0]), int(b[1]), int(b[2]), str(int(need)) if need < INF else "?"])
	print("%s: %d surfaces, unreachable %d %s" % [id, surf.size(), bad.size(), str(bad.slice(0, 8))])
	if OS.get_environment("ALL") == "2":
		print("  low: ", surf.filter(func(s): return s[2] >= 2300).map(func(s): return "x%d-%d y%d" % [int(s[0]), int(s[1]), int(s[2])]))
	if OS.get_environment("ALL") == "1":
		print("  all: ", surf.map(func(s): return "x%d-%d y%d" % [int(s[0]), int(s[1]), int(s[2])]))
	return false
