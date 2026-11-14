extends SceneTree
# Места возрождения на карте «Два дома»: на вертикали находятся опоры (пол, этажи, крыша),
# и хотя бы одна из них свободна.
var main
var f := 0
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
		main._on_duel_ready("two_houses", 2, 2, [0, 1])
	if f == 10:
		var space = main.world.get_world_2d().direct_space_state
		for x in [2500.0, 3000.0, 3700.0]:
			var spots: Array = Spawner._spots_on_line(space, x, -100.0, 1300.0)
			var free := 0
			for s in spots:
				if Spawner._is_free(space, s):
					free += 1
			check(spots.size() >= 1 and free >= 1, "x=%d: %d spots to stand on, %d free" % [int(x), spots.size(), free])
		var house: Array = Spawner._spots_on_line(space, 3700.0, -100.0, 1300.0)
		check(house.size() >= 3, "inside the house: floor, upper floor and roof (%d)" % house.size())
		print("RESULT fails=", fails)
		return true
	return false
