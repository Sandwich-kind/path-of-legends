extends SceneTree
# Показ модели Рассвета: стоит, бежит, бьёт, ульта «Восход» (два кадра). OUT=путь к PNG, SKIN=облик (например fire_rassvet)
var main
var f := 0
var p1: Player
var k: RassvetKit
var cells: Array = []
const CELL := Vector2i(210, 170)
const ZOOM := 3

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.data["skin_sel"] = {}
	if OS.get_environment("SKIN") != "":
		Save.data["skins"] = [OS.get_environment("SKIN")]
		Save.data["skin_sel"] = {Characters.LIST[13]["name"]: OS.get_environment("SKIN")}
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _cell() -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	var c: Vector2 = root.get_final_transform() * p1.get_global_transform_with_canvas().origin
	var r := Rect2i(Vector2i(c) - Vector2i(CELL.x / 2, CELL.y * 3 / 5), CELL).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var cell := Image.create(CELL.x, CELL.y, false, img.get_format())
	cell.blit_rect(img, r, Vector2i.ZERO)
	cell.convert(Image.FORMAT_RGBA8)
	cells.append(cell)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		if OS.get_environment("SKIN") != "":
			Skins.give(OS.get_environment("SKIN"))
			Skins.select(13, OS.get_environment("SKIN"))
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
		for c in p1.get_children():                       # полоски здоровья не мешают смотреть модель
			if c is ColorRect or c is Label:
				c.visible = false
	if p1 == null:
		return false
	p1.hp = p1.max_hp
	if f == 150: _cell()
	if f == 151: Input.action_press("p1_right")
	if f == 172 or f == 179: _cell()
	if f == 185: Input.action_release("p1_right")
	if f == 200: Input.action_press("p1_shoot")
	if f == 204: Input.action_release("p1_shoot")
	if f == 207: _cell()
	if f == 240:
		p1.velocity = Vector2.ZERO
		k.ult()
	if f == 278 or f == 292:
		_cell()
	if f == 300:
		var big := CELL * ZOOM
		var sheet := Image.create(big.x * cells.size(), big.y, false, Image.FORMAT_RGBA8)
		for i in cells.size():
			var im: Image = cells[i]
			im.resize(big.x, big.y, Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(im, Rect2i(Vector2i.ZERO, big), Vector2i(i * big.x, 0))
		sheet.save_png(OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/claude-0/st/rassvet_show.png")
		return true
	return false
