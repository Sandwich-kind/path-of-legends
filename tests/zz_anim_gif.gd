extends SceneTree
# Кадры для GIF: герой бежит, прыгает, бьёт, применяет способности. HERO=номер, DIR=папка для PNG
var main
var f := 0
var p: Player
var n := 0
var held := {}
const CELL := Vector2i(190, 170)

func _initialize() -> void:
	Save.load_game()
	Save.data["skin_sel"] = {}
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func press(a: String, k: int) -> void:
	Input.action_press(a)
	held[a] = f + k

func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	if f == 3:
		main.sel = [int(OS.get_environment("HERO")), 1]
		main.map_id = "test_field"
		main.start_duel()
	if f == 6:
		for c in main.world.get_children():
			if c is Destructible: c.queue_free()
			if c is Player and c.index == 0: p = c
			if c is Player and c.index == 1: c.position = Vector2(1100, 300)
			if c is CanvasLayer: c.visible = false
		p.frozen = false
		p.position = Vector2(140, 565)
	if p == null:
		return false
	p.hp = p.max_hp
	var g := f - 30
	if g == 0: press("p1_right", 70)
	if g == 40: press("p1_jump", 3)
	if g == 85: press("p1_shoot", 3)
	if g == 110: press("p1_shoot", 3)
	if g == 135: press("p1_a1", 3)
	if g == 185: press("p1_left", 45)
	if g == 205: press("p1_jump", 3)
	if g == 245: press("p1_a3", 3)
	if g >= 0 and g % 2 == 0 and g < 300:
		var img: Image = root.get_viewport().get_texture().get_image()
		var c: Vector2 = root.get_final_transform() * p.get_global_transform_with_canvas().origin
		var r := Rect2i(Vector2i(c) - Vector2i(CELL.x / 2, CELL.y * 3 / 5), CELL).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var cell := Image.create(CELL.x, CELL.y, false, img.get_format())
		cell.blit_rect(img, r, Vector2i.ZERO)
		cell.save_png("%s/%03d.png" % [OS.get_environment("DIR"), n])
		n += 1
	return g >= 300
