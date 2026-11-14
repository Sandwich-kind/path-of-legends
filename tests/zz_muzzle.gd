extends SceneTree
# Точка выстрела героев относительно тела (стоя, после выстрела): для сверки «до/после суставов»
var main
var f := 0
var hi := -1
var hs := [0, 7, 10, 6, 14, 19, 20, 21, 5, 4]
var p: Player
func _initialize() -> void:
	Save.load_game(); Save.data["skin_sel"] = {}; Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate(); root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f % 60 == 3:
		hi += 1
		if hi >= hs.size(): return true
		main.sel = [hs[hi], 1]; main.map_id = "test_field"; main.start_duel()
		p = main.duel_players[0]
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
	if f % 60 == 6:
		p.frozen = false
	if f % 60 == 20: Input.action_press("p1_shoot")
	if f % 60 == 22: Input.action_release("p1_shoot")
	if f % 60 in [19, 23, 30, 50] and p and p.rig:
		var m: Vector2 = p.rig.muzzle() - p.global_position
		print("MUZ %s f%d %.1f %.1f" % [Characters.LIST[hs[hi]].get("kit", "?"), f % 60, m.x, m.y])
	return false
