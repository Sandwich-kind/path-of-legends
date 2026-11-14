extends SceneTree
# Раскадровка движений героя для сравнения «до/после»: бег, прыжок с приземлением,
# выстрел, бросок, удар. Нужен экран (xvfb). HERO=номер легенды, OUT=путь к PNG.
var main
var f := 0
var p: Player
var hero := 7
var out := "/tmp/claude-0/st/anim.png"
var rows: Array = [[], [], [], [], [], []]
var _land := -1                 # кадр приземления после прыжка
const CELL := Vector2i(104, 112)        # вырезка вокруг героя; на листе увеличена вдвое
const ZOOM := 2
var held := {}

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	if OS.get_environment("HERO") != "":
		hero = int(OS.get_environment("HERO"))
	if OS.get_environment("OUT") != "":
		out = OS.get_environment("OUT")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n

func grab(row: int) -> void:
	rows[row].append(_cell())

func _cell() -> Image:
	var img: Image = root.get_viewport().get_texture().get_image()
	var c: Vector2 = root.get_final_transform() * p.get_global_transform_with_canvas().origin   # в пикселях окна
	var r := Rect2i(Vector2i(c) - Vector2i(CELL.x / 2, CELL.y * 3 / 5), CELL)
	r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var cell := Image.create(CELL.x, CELL.y, false, img.get_format())
	cell.blit_rect(img, r, Vector2i.ZERO)
	return cell

func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	if f == 3:
		main.sel = [hero, 1]
		main.map_id = "test_field"
		main.start_duel()
	if f == 6:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()
			if n is Player and n.index == 0: p = n
			if n is Player and n.index == 1: n.position = Vector2(1100, 300)
			if n is CanvasLayer: n.visible = false
		p.frozen = false
		p.position = Vector2(150, 565)
	if p == null:
		return false
	p.hp = p.max_hp
	var g := f - 30
	if g == 0: press("p1_right", 52)
	if g >= 22 and g < 46 and (g - 22) % 3 == 0: grab(0)
	if g == 70: press("p1_jump", 3)
	if g >= 70 and g < 118 and (g - 70) % 6 == 0: grab(1)
	# приземление — подряд, кадр за кадром (сжатие длится доли секунды)
	if g > 80 and g < 135 and _land < 0 and p.is_on_floor():
		_land = g
	if _land >= 0 and g >= _land and g < _land + 8: grab(5)
	if g == 140: press("p1_shoot", 2)
	if g >= 140 and g < 156 and (g - 140) % 2 == 0: grab(2)
	if g == 180 and p.rig: p.rig.play("throw")
	if g >= 180 and g < 204 and (g - 180) % 3 == 0: grab(3)
	if g == 230 and p.rig: p.rig.play("punch")
	if g >= 230 and g < 246 and (g - 230) % 2 == 0: grab(4)
	if g == 260:
		var cols := 0
		for r in rows:
			cols = maxi(cols, r.size())
		var big := CELL * ZOOM
		var sheet := Image.create(cols * big.x, rows.size() * big.y, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.1, 0.1, 0.12))
		for y in rows.size():
			for x in rows[y].size():
				var im: Image = rows[y][x]
				im.convert(Image.FORMAT_RGBA8)
				im.resize(big.x, big.y, Image.INTERPOLATE_NEAREST)
				sheet.blit_rect(im, Rect2i(Vector2i.ZERO, big), Vector2i(x * big.x, y * big.y))
		sheet.save_png(out)
		print("saved ", out, " ", sheet.get_size())
		return true
	return false
