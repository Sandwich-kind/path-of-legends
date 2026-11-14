extends SceneTree
# «Замки»: пушки целятся в чужака (синие — в красного), а выбитая из-под пушки
# площадка заставляет её рухнуть и замолчать.
var main
var f := 0
var t_doom := -1
var target_ok := true

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main._on_duel_ready("castles", 9, 99, [0, 1], {"heal": false, "buffs": false, "mega": false, "sd": true, "sd_time": 1})
		return false
	if f < 10 or not main.events.doom:
		return false
	if t_doom < 0:
		t_doom = f
	var cannons: Array = main.map_info["cannons"]
	var siege = main.events._special
	for c in cannons:
		var tgt: Player = siege._target_for(c)
		if tgt != null and tgt.team == c.team:
			target_ok = false
	if f - t_doom == 30:
		# выбиваем смотровую площадку под синей пушкой на башне
		var c0 = cannons[0]
		for n in main.world.get_children():
			if n is Destructible and not n.background:
				n.hit(c0.global_position + Vector2(0, 10), Vector2.ZERO, 9999, 70.0, 2, {"strict": true, "radial": true})
	if f - t_doom == 240:
		var c0 = cannons[0]
		print("blue tower cannon broken=", c0.broken, " y=", c0.global_position.y, " others broken=",
				cannons.slice(1).map(func(c): return c.broken))
		var ok: bool = c0.broken and target_ok and not cannons[2].broken
		print("RESULT ", "OK" if ok else "FAIL", " target_ok=", target_ok)
		return true
	return false
