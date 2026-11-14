extends SceneTree
# Лист с видами крыльев ульты Рассвета (на настоящей модели в игре). OUT=путь к PNG, SKIN=облик (необязательно)
var main
var f := 0
var p1: Player
var k: RassvetKit
var cells: Array = []
var si := -1
var t0 := 0
const CELL := Vector2i(230, 190)

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.data["skin_sel"] = {}
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _cell() -> Image:
	var img: Image = root.get_viewport().get_texture().get_image()
	var c: Vector2 = root.get_final_transform() * p1.get_global_transform_with_canvas().origin
	var r := Rect2i(Vector2i(c) - Vector2i(CELL.x / 2, CELL.y * 3 / 5), CELL).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var cell := Image.create(CELL.x, CELL.y, false, img.get_format())
	cell.blit_rect(img, r, Vector2i.ZERO)
	cell.convert(Image.FORMAT_RGBA8)
	return cell

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.sel = [13, 0]
		main.start_arena(false, 1)
	if f == 120:
		for n in main.world.get_children():
			if n is ArenaMode:
				n._queue.clear()
				for b in n._alive:
					if is_instance_valid(b): b.queue_free()
				n._alive.clear()
				p1 = n.players[0]
			if n is CanvasLayer:
				n.visible = false
		k = p1.kit
		p1.frozen = false
	if p1 == null:
		return false
	p1.hp = p1.max_hp
	if f >= 150 and (f - 150) % 70 == 0:
		si += 1
		if si >= RassvetKit.WING_STYLES.size():
			var big := CELL * 2
			var sheet := Image.create(big.x * cells.size() / 2, big.y * 2, false, Image.FORMAT_RGBA8)
			for i in cells.size():
				var im: Image = cells[i]
				im.resize(big.x, big.y, Image.INTERPOLATE_NEAREST)
				sheet.blit_rect(im, Rect2i(Vector2i.ZERO, big), Vector2i((i / 2) * big.x, (i % 2) * big.y))
			sheet.save_png(OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/claude-0/st/rassvet_wings.png")
			RassvetKit.wing_style = "feathers"
			return true
		if is_instance_valid(k._wings):
			k._wings.free()
		k._wings = null
		k._dawn_t = 0.0
		p1.global_position = Vector2(1300, 700)
		p1.velocity = Vector2.ZERO
		RassvetKit.wing_style = RassvetKit.WING_STYLES[si]
		k.ult()
		t0 = f
	if si >= 0 and (f == t0 + 40 or f == t0 + 52):
		p1.velocity = Vector2.ZERO
		cells.append(_cell())
	return false
