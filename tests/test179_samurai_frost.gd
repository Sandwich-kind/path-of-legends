extends SceneTree
# МЕГА-ульта Самурая: иней копится — вмораживает только каждый третий удар подряд,
# потом 3,5 с только замедляет; сколько раз соперник вмёрз за 6 с ударов.
var main
var f := 0
var me: Player
var foe: Player
var freezes := 0
var was := false
var stunned_frames := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	Input.action_release("p1_shoot")
	Input.action_release("p1_ult")
	if f == 3:
		var si := -1
		for i in Characters.LIST.size():
			if Characters.LIST[i]["name"] == "САМУРАЙ":
				si = i
		main._on_duel_ready("test_buffs", 9, 99, [si, 2], {})
	if f == 30:
		me = main.duel_players[0]
		foe = main.duel_players[1]
		foe.max_hp = 9000
		foe.hp = 9000
	if f < 240:
		return false
	var g := f - 240
	me._protect = 5.0
	if g < 6:
		me.global_position.x = 1200
		foe.global_position = Vector2(1300, me.global_position.y)
		me.facing = 1
		me.mega_mode = true
		me.ult_charge = 9999
	if g == 6:
		Input.action_press("p1_ult")
	if g > 30 and g < 30 + 360:
		foe.global_position.x = me.global_position.x + 100
		if g % 8 < 2:
			Input.action_press("p1_shoot")
		var now := foe._freeze_t > 0.0 or foe._stun_t > 0.0
		if now:
			stunned_frames += 1
		if now and not was:
			freezes += 1
		was = now
	if g == 30 + 360:
		print("frost: freezes=%d stunned=%.1f s of 6 s" % [freezes, stunned_frames / 60.0])
		var ok := freezes >= 1 and freezes <= 3 and stunned_frames < 60 * 3
		print("RESULT fails=", 0 if ok else 1)
		return true
	return false
