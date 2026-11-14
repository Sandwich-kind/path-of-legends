extends SceneTree
# «Экспресс», «Мгновенная смерть»: тоннель сносит того, кто на крыше, и не трогает
# того, кто внутри вагона; после тоннеля возрождение не на крыше; пожар в вагоне.
#   godot --path . -s res://tests/test142_train_tunnel.gd [-- shots]
var main
var f := 0
var shots := false
var tun: Node
var hp_roof := []
var hp_in := []
var phases := {}
var shot_done := {}
var fires := 0

func _initialize() -> void:
	shots = "shots" in OS.get_cmdline_user_args()
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main._on_duel_ready("train", 9, 99, [0, 1], {"heal": false, "buffs": false, "mega": false, "sd": true, "sd_time": 1})
		return false
	if f < 10:
		return false
	var p1: Player = main.duel_players[0]
	var p2: Player = main.duel_players[1]
	if not main.events.doom:
		return false
	tun = main.events._special
	var ph: String = tun.get("_phase")
	phases[ph] = phases.get(ph, 0) + 1
	# Игрок 1 стоит на крыше пассажирского вагона, Игрок 2 сидит в своём вагоне
	if ph in ["wait", "warn"] and phases.get("exit", 0) == 0:
		for pp in [[p1, Vector2(1100, Train.RT - 32)], [p2, Vector2(4000, Train.TF - 32)]]:
			var p: Player = pp[0]
			if p.is_alive():
				p.global_position = pp[1]
				p.velocity = Vector2.ZERO
				p.heal(500)
		hp_roof = [p1.hp]
		hp_in = [p2.hp]
	if ph == "enter":
		hp_roof.append(p1.hp)
		hp_in.append(p2.hp)
	for n in main.world.get_children():
		if n is FireZone:
			fires += 1
	if shots and not shot_done.has(ph) and ph in ["warn", "enter", "inside"] and phases[ph] == (8 if ph != "inside" else 60):
		shot_done[ph] = true
		DirAccess.make_dir_recursive_absolute("/tmp/claude-0/duel")
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/duel/train_tunnel_%s.png" % ph)
	if phases.get("exit", 0) > 0 and ph == "wait":
		var roof_hit: int = hp_roof[0] - hp_roof.min() if not hp_roof.is_empty() else 0
		var in_hit: int = hp_in[0] - hp_in.min() if not hp_in.is_empty() else 0
		print("phases=", phases, " roof_hit=", roof_hit, " inside_hit=", in_hit, " fire_frames=", fires)
		var r: Dictionary = tun.safe_spawn({"pos": Vector2(1100, Train.RT - 32), "parachute": false}, p1)
		print("spawn on roof (no tunnel now) -> ", r)
		tun.set("_phase", "inside")
		var r2: Dictionary = tun.safe_spawn({"pos": Vector2(1100, Train.RT - 32), "parachute": true}, p1)
		print("spawn during tunnel -> ", r2)
		var ok: bool = roof_hit >= 25 and in_hit < 25 and r2["pos"].y > Train.CLEAR_Y and not r2["parachute"]
		print("RESULT ", "OK" if ok else "FAIL")
		return true
	if f > 60 * 60:
		print("RESULT FAIL timeout phases=", phases)
		return true
	return false
