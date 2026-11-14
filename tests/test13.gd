extends SceneTree
# Физика карты Дуэли: обычное тело (RigidBody2D без наших скриптов) падает и ложится на пол,
# а не проваливается сквозь него; у героя включена форма столкновений.
var main
var f := 0
var p1
var rb
var y30 := 0.0
var fails := 0
func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.map_id = "test_field"
		main.start_duel()
	if f == 5:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
			if n is Player and n.index == 0: p1 = n
			if n is Player and n.index == 1: n.position = Vector2(1000, 565)
		p1.position = Vector2(500, 565)
		check(p1.collision_layer != 0 and not p1._col.disabled, "hero has a collision layer and an enabled shape")
		rb = RigidBody2D.new()
		rb.collision_layer = 1
		rb.collision_mask = 3
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = Vector2(40, 40)
		c.shape = s
		rb.add_child(c)
		rb.position = Vector2(300, 300)
		main.world.add_child(rb)
	if f == 30:
		y30 = rb.position.y
		check(y30 > 320.0, "plain body falls (y=%d)" % int(y30))
	if f == 150:
		check(rb.position.y > 520.0 and rb.position.y < Config.H, "plain body lands on the floor and stays inside the map (y=%d)" % int(rb.position.y))
		check(rb.linear_velocity.length() < 5.0, "plain body rests")
		print("RESULT fails=", fails)
		return true
	return false
