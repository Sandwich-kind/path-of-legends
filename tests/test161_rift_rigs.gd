extends SceneTree
# Модели свиты Странника: все виды в покое и в движении (снимки в /tmp/claude-0/arena90/)
var f := 0
var rigs: Array = []
var world: Node2D
func _initialize() -> void:
	world = Node2D.new()
	root.add_child(world)
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.62, 0.72)
	bg.size = Vector2(1600, 720)
	world.add_child(bg)
	var floor_r := ColorRect.new()
	floor_r.color = Color(0.35, 0.30, 0.28)
	floor_r.position = Vector2(0, 520)
	floor_r.size = Vector2(1600, 200)
	world.add_child(floor_r)
	var x := 60.0
	for k in RiftRig.KINDS:
		var sz: Vector2 = Bots.TYPES[k]["size"] if Bots.TYPES.has(k) else Vector2(40, 64)
		var r := RiftRig.new()
		r.kind = k
		r.size = sz
		var sc := 1.6 if sz.y < 120 else 1.0
		var holder := Node2D.new()
		holder.scale = Vector2(sc, sc)
		holder.position = Vector2(x + sz.x * sc / 2, 520 - sz.y * sc / 2 - (150.0 if k in ["rift_eye", "voidwing"] else 0.0))
		world.add_child(holder)
		holder.add_child(r)
		rigs.append(r)
		x += maxf(sz.x * sc, 60.0) + 40.0
	var cam := Camera2D.new()
	cam.position = Vector2(800, 360)
	world.add_child(cam)
	cam.call_deferred("make_current")

func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/arena90/rigs_idle.png")
		for r in rigs:
			r.puppet_vx = 200.0
	if f == 32:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/arena90/rigs_walk.png")
		for r in rigs:
			r.puppet_vx = 0.0
			r.play("swing")
	if f == 40:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/arena90/rigs_swing.png")
		for r in rigs:
			r.play("roar")
	if f == 58:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/arena90/rigs_roar.png")
		for r in rigs:
			r.play("cast")
	if f == 76:
		if DisplayServer.get_name() != "headless": root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/arena90/rigs_cast.png")
		return true
	return false
