extends SceneTree
# Почти легенда в Дуэли: кулаки, Рельмотрон, лёд, метеорит работают без Арены; Титан бьёт
# соперника по всей карте и уходит; ничего не ломается.
var main
var f := 0
var fails := 0
var p1: Player
var p2: Player
var k: AlmostKit
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
		var kits := Characters.LIST.map(func(c): return c.get("kit", ""))
		main.sel = [kits.find("almost"), kits.find("genius")]
		main.map_id = "test_field"
		main.start_duel()
	if f == 5:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
			if n is Player and n.index == 0: p1 = n
			if n is Player and n.index == 1: p2 = n
		k = p1.kit
	if f < 8 or p1 == null:
		return false
	if f == 8:
		p1.frozen = false
		p2.frozen = false
		p1.position = Vector2(600, 565)
		p2.position = Vector2(900, 565)
		p1.facing = 1
	if f > 8:
		p1.hp = p1.max_hp
	if f > 8 and f < 390 and p2.is_alive():
		p2.hp = maxi(p2.hp, 80)
	if f == 30:
		hp0 = p2.hp
		k.use("railmotron")
	if f == 60:
		check(p2.hp < hp0, "duel: railmotron hits the other player (-%d)" % (hp0 - p2.hp))
	if f == 100:
		p2.position = Vector2(700, 565)
		k.use("ice_farewell")
	if f == 160:
		check(p2._slow_t > 0.0, "duel: ice zone slows the other player")
	if f == 400:
		p2.hp = p2.max_hp
		hp0 = p2.hp
		k.use("meteor_strike")
	if f == 470:
		check(p2.hp < hp0 or k._enemies().is_empty(), "duel: meteor lands on the other player (-%d)" % (hp0 - p2.hp))
	if f == 700:
		p2.hp = p2.max_hp
		hp0 = p2.hp
		k.ult()
		check(k.ulting(), "duel: Titan rises")
	if f == 700 + 60 * 16:
		check(not k.ulting(), "duel: Titan leaves")
		check(p2.hp < hp0 or main.kills[0] > 0, "duel: Titan hurt the other player")
		print("RESULT fails=", fails)
		return true
	return false
