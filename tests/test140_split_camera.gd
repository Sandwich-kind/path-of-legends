extends SceneTree
# Разделённый экран: решается по кадру (помещаются ли оба при удобном приближении),
# с запасом, чтобы не мигал; переход плавный. Проверка на «Двух домах» и «Горе».
#   godot --path . -s res://tests/test140_split_camera.gd [-- shots]
var main
var f := 0
var t0 := 0
var step := 0
var map_i := 0
var shots := false
var log_lines: Array = []
var prev_split := true
const MAPS := ["two_houses", "mountain", "test_buffs", "arena_colosseum"]
# [кадров держать, x1, y1-сдвиг, x2, y2-сдвиг, "any" — снимок посреди перехода, имя снимка]
# (подписи "split"/"shared" — что ожидается на экране шириной 1440; сама проверка — по кадру)
var plan := {
	"two_houses": [
		[90, 200.0, 0.0, 3800.0, 0.0, "split", "houses_far"],
		[90, 1300.0, 0.0, 3000.0, 0.0, "shared", "houses_1700"],
		[90, 1200.0, 0.0, 3200.0, 0.0, "shared", "houses_2000_stays"],
		[14, 1000.0, 0.0, 3400.0, 0.0, "any", "houses_2400_mid"],
		[90, 1000.0, 0.0, 3400.0, 0.0, "split", "houses_2400"],
		[90, 1900.0, 0.0, 2300.0, 0.0, "shared", "houses_close"],
	],
	"mountain": [
		[90, 200.0, 0.0, 5800.0, 0.0, "split", "mount_far"],
		[90, 2500.0, 0.0, 3500.0, 0.0, "shared", "mount_1000"],
		[90, 2900.0, -1560.0, 2900.0, 0.0, "split", "mount_vertical"],
		[90, 2900.0, -600.0, 3100.0, 0.0, "shared", "mount_vert_close"],
	],
	"test_buffs": [
		[90, 150.0, 0.0, 4350.0, 0.0, "split", "buffs_far"],
	],
	"arena_colosseum": [
		[90, 200.0, 0.0, 2400.0, 0.0, "shared", "colosseum_far"],
	],
}
func _initialize() -> void:
	shots = "shots" in OS.get_cmdline_user_args()
	Save.load_game()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _sv() -> SplitView:
	for n in main.world.get_children():
		if n is SplitView:
			return n
	return null
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		_start_map()
		return false
	if f < 3 or t0 == 0:
		return false
	var id: String = MAPS[map_i]
	var steps: Array = plan[id]
	var s: Array = steps[step]
	var g: float = main.map_info["p1"].y
	var p1: Player = main.duel_players[0]
	var p2: Player = main.duel_players[1]
	for pp in [[p1, s[1], s[2]], [p2, s[3], s[4]]]:
		var p: Player = pp[0]
		p.frozen = true
		p.velocity = Vector2.ZERO
		p.global_position = Vector2(pp[1], g + pp[2])
	if f - t0 >= s[0]:
		var sv := _sv()
		var split := sv != null and sv.is_split()
		var bl: float = sv.blend() if sv else 0.0
		var cam: DuelCamera = null
		for n in main.world.get_children():
			if n is DuelCamera:
				cam = n
		# ожидание считаем по кадру (так тест не зависит от размера окна): нужно отдалить
		# дальше SPLIT_ZOOM — разделён, хватает MERGE_ZOOM — общий, между ними — как было
		var need: float = cam.fit_zoom() if cam else 1.0
		var want: bool = split
		if need < SplitView.SPLIT_ZOOM:
			want = true
		elif need > SplitView.MERGE_ZOOM:
			want = false
		else:
			want = prev_split
		if sv == null:
			want = false                  # на картах без разделения экран всегда общий
		var ok: bool = s[5] == "any" or (want == split and (bl == 1.0 if split else bl == 0.0))
		prev_split = split
		var line: String = "%s/%s: split=%s blend=%.2f need=%.2f camz=%.2f %s" % [id, s[6], split, bl,
				cam.fit_zoom() if cam else -1.0, cam.zoom.x if cam else -1.0, "OK" if ok else "FAIL"]
		print(line)
		log_lines.append(line)
		if shots:
			DirAccess.make_dir_recursive_absolute("/tmp/claude-0/duel")
			if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/duel/cam_%s.png" % s[6])
		step += 1
		t0 = f
		if step >= steps.size():
			step = 0
			map_i += 1
			if map_i >= MAPS.size():
				var fails := log_lines.filter(func(l): return l.ends_with("FAIL")).size()
				print("RESULT fails=", fails)
				return true
			_start_map()
	return false
func _start_map() -> void:
	main._on_duel_ready(MAPS[map_i], 9, 99, [0, 1], {"heal": false, "buffs": false, "mega": false, "sd": false})
	t0 = f
	prev_split = true
