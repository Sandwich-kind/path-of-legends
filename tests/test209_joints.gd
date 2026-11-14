extends SceneTree
# Суставы моделей: у героя есть колени и локти; на бегу колени сгибаются, в прыжке ноги
# поджаты, на ударе локоть распрямляется; оружие держит предплечье; у Колосса суставов нет.
var main
var f := 0
var fails := 0
var p: Player
var r: BotRig
var max_knee := 0.0
var air_knee := 0.0
var min_elbow := 0.0
var end_elbow := -9.0

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

func _process(_d: float) -> bool:
	# модель двигается в _process: углы суставов читаем здесь же
	if r != null and is_instance_valid(r) and r._jointed:
		if f > 40 and f < 90:
			max_knee = maxf(max_knee, maxf(r._shin_f.rotation, r._shin_b.rotation))
		if f > 100 and f < 125 and not p.is_on_floor():
			air_knee = maxf(air_knee, maxf(r._shin_f.rotation, r._shin_b.rotation))
		if f > 150 and f < 175:
			min_elbow = minf(min_elbow, r._fore_f.rotation)
			end_elbow = maxf(end_elbow, r._fore_f.rotation)
	return false

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [22, 1]
		main.map_id = "test_field"
		main.start_duel()
	if f == 6:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
			if n is Player and n.index == 0: p = n
			if n is Player and n.index == 1: n.position = Vector2(1100, 300)
		p.frozen = false
		p.position = Vector2(150, 565)
		r = p.rig
		check(r._jointed and r._shin_f != null and r._shin_b != null and r._fore_f != null and r._fore_b != null, "hero model has knees and elbows")
		check(r._weapon == null or r._weapon.get_parent() == r._fore_f, "the weapon is held by the forearm")
	if p == null:
		return false
	p.hp = p.max_hp
	if f == 30: Input.action_press("p1_right")
	if f == 90:
		Input.action_release("p1_right")
		check(max_knee > 0.5, "running: the knee of the swinging leg bends (%.2f rad)" % max_knee)
	if f == 100: Input.action_press("p1_jump")
	if f == 103: Input.action_release("p1_jump")
	if f == 130:
		check(air_knee > 0.6, "jump: legs are tucked on the way up (%.2f rad)" % air_knee)
	if f == 150:
		r.play("punch")
	if f == 176:
		check(min_elbow < -1.0 and end_elbow > -0.45, "punch: the elbow is bent on the windup (%.2f) and straightens on the strike (%.2f)" % [min_elbow, end_elbow])
		check(r.muzzle().distance_to(p.global_position) < 120.0, "hand point stays near the body")
		var b := Bots.create("colossus", 1, Vector2(700, 500), p, Config.W)
		main.world.add_child(b)
		b.frozen = true
		check(b.rig != null and not b.rig._jointed, "Colossus keeps solid limbs (its own heavy motion)")
		print("RESULT fails=", fails)
		return true
	return false
