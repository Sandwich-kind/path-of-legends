extends SceneTree
# Дуэль на картах земель Странника: «Мгновенная смерть» — острова рушатся / огненный вал (30 с)
var main
var f := 0
var ids := ["arena_sky", "arena_burning"]
var mi := 0
var t0 := 0
var out := "/tmp/claude-0/arena90/"
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_stages()
	var vis := []
	for m in Maps.visible_duel_maps(): vis.append(m["id"])
	print("visible has sky/burning: ", "arena_sky" in vis, " ", "arena_burning" in vis)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _report() -> void:
	var hp := []
	for p in main.duel_players: hp.append([p.hp, p.global_position.round()])
	var segs := 0
	var walls := []
	for n in main.world.get_children():
		if n is StaticBody2D and n.get_meta("color", Color.BLACK) == SkyIsles.ROCK: segs += 1
		if n is RiftDoom.FireWall: walls.append(int(n.x))
	print(ids[mi - 1], ": doom=", main.events.doom, " kills=", main.kills, " hp=", hp, " segs=", segs, " walls=", walls)
func _physics_process(_d: float) -> bool:
	f += 1
	if mi > 0:
		var k := f - t0
		if k == 30:
			for p in main.duel_players:
				print("  spawn ", p.global_position, " on_floor=", p.is_on_floor())
		if k in [60 * 8, 60 * 20]:
			var img := root.get_viewport().get_texture().get_image()
			if img:
				if img: img.save_png(out + "doom_%s_%d.png" % [ids[mi - 1], k / 60])
			_report()
	if f == 3 or (mi > 0 and f - t0 == 60 * 30):
		if mi > 0:
			_report()
		if mi >= ids.size():
			return true
		main._on_duel_ready(ids[mi], 9, 99, [0, 1], {"heal": true, "buffs": true, "mega": true, "sd": true, "sd_time": 3})
		mi += 1
		t0 = f
	return false
