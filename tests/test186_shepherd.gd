extends SceneTree
# Пастух Разлома (95): выходит после сцены, стадо бьёт стоящего героя, через прыгнувшего —
# нет, крюк тянет, порча жжёт, колокол замедляет; ярость с половины здоровья.
var main
var f := 0
var arena: ArenaMode
var p1: Player
var b
var t0 := 0
var fails := 0
var hp0 := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])
func shot(n: String) -> void:
	if OS.get_environment("SHOTS") == "1":
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/sh_%s.png" % n)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [0, 0]
		main.start_arena(false, 95)
	if f == 100:
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
		p1 = arena.players[0]
	if arena == null:
		return false
	if b == null and arena._boss != null and not arena._boss.cutscene_shield and f > 200:
		b = arena._boss
		t0 = f
		check(b.get_meta("kind") == "void_shepherd", "wave 95 brings the Shepherd")
		b.frozen = true
	if b == null:
		if f == 300:
			shot("intro")
		return f > 3000
	var g := f - t0
	if g == 10:
		p1.hp = p1.max_hp
		hp0 = p1.hp
		p1.global_position.x = b.global_position.x + (500.0 if b.global_position.x < 1300 else -500.0)
		ShepherdAbilities.stampede(b, false, 4)
	if g == 130:
		shot("stampede")
	if g == 240:
		check(p1.hp < hp0, "stampede hits a standing hero (%d -> %d)" % [hp0, p1.hp])
		p1.hp = p1.max_hp
		hp0 = p1.hp
		p1.velocity = Vector2.ZERO
		p1.global_position.x = b.global_position.x + (500.0 if b.global_position.x < 1300 else -500.0)
		ShepherdAbilities.blight_sow(b)
	if g == 300:
		shot("blight")
	if g == 400:
		check(p1.hp < hp0, "blight burns (%d -> %d)" % [hp0, p1.hp])
		p1.hp = p1.max_hp
		ShepherdAbilities.bell_toll(b)
	if g == 410:
		check(p1._slow_t > 0.0 or p1.global_position.distance_to(b.global_position) > 380.0, "bell slows nearby heroes")
	if g == 480:
		b.frozen = false
		b.hp = int(b.max_hp * 0.45)
		b.heal(0)
	if g == 540:
		check(AbyssAbilities.br_rage(b), "Shepherd enrages at half health")
		shot("rage")
	if g == 640:
		print("RESULT fails=", fails)
		return true
	return false
