extends SceneTree
# Парашют: с неба герой сначала падает, у земли раскрывает купол и мягко садится.
var main
var f := 0
var p
var max_vy := 0.0
var canopy_vy := 0.0
var canopy_frames := 0
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
	if f == 200:
		for n in main.world.get_children():
			if n is Player and n.index == 0: p = n
		p.position = main.map_info["sky"][0]
		p.velocity = Vector2.ZERO
		p._para = 1
	if f > 200 and p._para == 1:
		max_vy = maxf(max_vy, p.velocity.y)
	if f > 200 and p._para == 2:
		canopy_frames += 1
		canopy_vy = p.velocity.y
	if f > 200 and (p._para == 0 or f > 600):
		check(p._para == 0 and f < 500, "landed %.1f s after the jump" % ((f - 200) / 60.0))
		check(max_vy > 900.0, "free fall is fast (%d)" % int(max_vy))
		check(canopy_frames > 30 and canopy_vy < 250.0, "under the canopy the fall is slow (%d) for %d frames" % [int(canopy_vy), canopy_frames])
		check(p.is_alive() and p.hp == p.max_hp, "no damage from the landing")
		print("RESULT fails=", fails)
		return true
	return false
