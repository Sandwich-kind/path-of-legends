extends SceneTree
# Недопонятый гений в Дуэли: «Перегазрука» лечит 10% (не 20%) и откатывается 22 с.
var main
var f := 0
var fails := 0
var p1: Player
var hp0 := 0

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [Characters.LIST.map(func(c): return c.get("kit", "")).find("genius"), 0]
		main.map_id = "test_field"
		main.start_duel()
	if f == 5:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
			if n is Player and n.index == 0: p1 = n
			if n is Player and n.index == 1: n.position = Vector2(1400, 565)
	if f < 8 or p1 == null:
		return false
	if f == 8:
		p1.frozen = false
		p1.position = Vector2(500, 565)
		check(is_equal_approx(float(p1.ability_cds[2]), 11.0), "duel: overclock cooldown 11 s (%.0f)" % p1.ability_cds[2])
		p1.hp = 40
		hp0 = p1.hp
		p1.kit.use("overclock")
	if f == 8 + 140:
		var got := p1.hp - hp0
		check(got >= int(p1.max_hp * 0.09) and got <= int(p1.max_hp * 0.11) + 1, "duel: overclock heals 10 pct (+%d of %d)" % [got, p1.max_hp])
		print("RESULT fails=", fails)
		return true
	return false
