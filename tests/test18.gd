extends SceneTree
# Горение дерева и ракеты сквозь дерево
var main
var f := 0
var tr
var p2
var cells0 := 0
var t2cells := 0
var fails := 0
func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func trees() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Destructible and n.flammable:
			r.append(n)
	return r
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main._on_duel_ready("two_houses", 2, 5, [0, 1])
	if f == 10:
		tr = trees()[0]
		var fz := FireZone.new()
		fz.team = 0
		fz.position = tr.global_position + Vector2(0, 60)   # середина ствола
		main.world.add_child(fz)
		cells0 = tr.cells.size()
		check(cells0 > 20, "tree is there (%d cells)" % cells0)
	if f in [60, 120, 240, 400]:
		var ts := trees()
		var fallen := 0
		var total := 0
		for t in ts:
			total += t.cells.size()
			if not t.background:
				fallen += 1
		var left: int = tr.cells.size() if is_instance_valid(tr) else 0
		if f == 60:
			check(is_instance_valid(tr) and tr._burning.size() > 0, "fire zone sets the trunk on fire (%d cells burning)" % tr._burning.size())
		if f == 240:
			check(left < cells0 / 2 and fallen >= 1, "the trunk burns through and the top falls (%d of %d cells left, fallen pieces %d)" % [left, cells0, fallen])
	if f == 410:
		# залп по второму дереву: ракеты не должны взрываться о дерево
		for n in main.world.get_children():
			if n is Player and n.index == 1: p2 = n
			if n is Player and n.index == 0: n.position = Vector2(300, 1215)
		p2.position = Vector2(3700, 1215)
		p2.facing = -1
		for t in trees():
			if t.global_position.x > 3000 and t.background:
				t2cells = t.cells.size()
		p2._barrage()
	if f == 600:
		var t2 = null
		for t in trees():
			if t.global_position.x > 3000:
				t2 = t
		# ракеты залпа пролетают сквозь дерево (оно на заднем плане) и рвутся на земле за ним:
		# дерево задевает только взрывами, целиком оно не сносится
		check(t2 != null and t2.cells.size() > 0 and t2.cells.size() <= t2cells, "barrage flies through the tree: %d of %d cells left" % [t2.cells.size() if t2 else -1, t2cells])
		print("RESULT fails=", fails)
		return true
	return false
