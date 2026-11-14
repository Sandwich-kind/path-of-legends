extends SceneTree
# МЕГА «Вихрь клинков» Ассасина: кадры теней-рывков
# рубит крест-накрест) — склейка снимков /tmp/claude-0/storm/.
var main
var f := 0
var out := "/tmp/claude-0/storm/"
var me: Player
var foe: Player
var k := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	Input.action_release("p1_a1")
	if f == 3:
		var si := -1
		for i in Characters.LIST.size():
			if Characters.LIST[i]["name"] == "АССАСИН":
				si = i
		main._on_duel_ready("test_buffs", 9, 99, [si, 2], {})
	if f == 30:
		me = main.duel_players[0]
		foe = main.duel_players[1]
		foe.max_hp = 5000
		foe.hp = 5000
	if f < 240:
		return false
	var g := f - 240
	if g < 6:
		me.global_position.x = 1200
		foe.global_position = Vector2(1330, me.global_position.y)
		me.facing = 1
		me.mega_mode = true
		me._cd = [0.0, 0.0, 0.0]
		me._protect = 5.0
	if g == 6:
		Input.action_press("p1_a1")
	if g >= 8 and g <= 140 and (g - 8) % 4 == 0:
		var img := root.get_viewport().get_texture().get_image()
		if img:
			if img: img.save_png(out + "f%02d.png" % k)
			var sp := me.get_global_transform_with_canvas().origin
			var vr := root.get_viewport().get_visible_rect().size
			print("POS %d %d %d %d %d %d" % [k, int(sp.x), int(sp.y), int(vr.x), int(vr.y), img.get_width()])
		k += 1
	if g == 150:
		print("RESULT frames=", k, " foe hp=", foe.hp)
		return true
	return false
