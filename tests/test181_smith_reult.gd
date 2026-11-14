extends SceneTree
# Кузнец: нажатие ульты во время финала старой «Кузни» не ломает новую —
# ульта не включается, пока идёт старая; после финала новая — с ростом и огнём.
var main
var f := 0
var me: Player
var fails := 0
var fin_at := -1

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("%s %s" % ["ok  " if ok else "FAIL", what])

func _physics_process(_d: float) -> bool:
	f += 1
	Input.action_release("p1_ult")
	if f == 3:
		main._on_duel_ready("test_buffs", 9, 99, [1, 2], {})
	if f == 30:
		me = main.duel_players[0]
	if f < 240:
		return false
	var g := f - 240
	me._protect = 5.0
	if g == 2:
		me.mega_mode = true
		me.ult_charge = 9999
		Input.action_press("p1_ult")
	if g > 10 and fin_at < 0 and me.kit._finale:
		fin_at = g
		me.ult_charge = 9999              # «успел набить вторую»
		Input.action_press("p1_ult")      # жмёт во время финальных ударов
	if fin_at > 0 and g == fin_at + 5:
		check(me.kit.forge_t <= 0.0 and not me.kit._forging, "no new forge during the finale")
	if fin_at > 0 and g == fin_at + 150:
		check(not me.kit._finale and me._rig_root.scale.x < 1.05, "finale ended, back to normal size")
		me.ult_charge = 9999
		Input.action_press("p1_ult")
	if fin_at > 0 and g == fin_at + 200:
		check(me.kit.forge_t > 0.0 and me._rig_root.scale.x > 1.25 and is_instance_valid(me.kit._aura), "new forge: grown, flame ring (scale %.2f)" % me._rig_root.scale.x)
		print("RESULT fails=", fails)
		return true
	if g > 60 * 20:
		print("FAIL timeout")
		return true
	return false
