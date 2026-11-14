class_name SplitView
extends CanvasLayer
# Разделённый экран для больших карт (Гора, Два дома, Замки, Поезд, TEST_BUFFS).
# Делить ли экран, решает не расстояние, а кадр: если, чтобы показать обоих,
# общей камере пришлось бы отдалиться дальше SPLIT_ZOOM — экран делится пополам
# (слева тот, кто левее), у каждого своя камера крупным планом. Как только оба
# снова помещаются в общий кадр с приближением MERGE_ZOOM — экран опять общий.
# Переход плавный: в миг деления половинки показывают ровно ту же картинку,
# что и общий кадр, и за полсекунды «разъезжаются» к своим героям; при слиянии —
# наоборот, съезжаются в общий кадр и только тогда исчезают.
# По краю каждой половины стрелка показывает, где соперник, и сколько до него блоков.

const SPLIT_ZOOM := 0.55       # общий кадр дальше этого не отдаляется — делим экран
const MERGE_ZOOM := 0.62       # оба помещаются при таком приближении — снова общий экран
const ZOOM := 0.8              # приближение каждой половины
const BLEND_TIME := 0.45       # сколько длится переход
const BLOCK := 40.0            # сколько пикселей в одном «блоке» для подписи расстояния

var players: Array = []
var bounds := Rect2()
var open_top := true
var shared: DuelCamera         # общая камера: по ней видно, помещаются ли оба в кадр

var _halves: Array = []        # {box, cam, arrow, dist}
var _on := false
var _blend := 0.0              # 0 — общий экран, 1 — разделён
var _order := [0, 1]           # кто в левой половине, кто в правой
var _first := true
var _divider: ColorRect

# Нужен ли карте разделённый экран: явно ("split") или если иначе общей камере
# пришлось бы отдаляться слишком далеко (карта намного шире экрана)
static func wanted(info: Dictionary, play: Vector2) -> bool:
	if info.has("split"):
		return bool(info["split"])
	if not info.get("follow", false):
		return false
	var b: Rect2 = info.get("cam_rect", Rect2(Vector2.ZERO, info["size"]))
	var z := play.x / b.size.x
	if not info.get("open_top", false):
		z = maxf(z, play.y / b.size.y)
	return z < SPLIT_ZOOM

func _ready() -> void:
	layer = 1
	var vs := Config.screen(self)
	var h := vs.y - Config.panel()
	for i in 2:
		var box := SubViewportContainer.new()
		box.stretch = true
		box.position = Vector2(i * vs.x / 2.0, 0)
		box.size = Vector2(vs.x / 2.0, h)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)
		var sv := SubViewport.new()
		sv.world_2d = get_viewport().world_2d     # тот же мир, что и на главном экране
		sv.handle_input_locally = false
		sv.gui_disable_input = true
		box.add_child(sv)
		var cam := Camera2D.new()
		cam.zoom = Vector2(ZOOM, ZOOM)
		sv.add_child(cam)
		cam.enabled = true
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(26, 0), Vector2(-14, -18), Vector2(-6, 0), Vector2(-14, 18)])
		box.add_child(arrow)
		var dist := Label.new()
		dist.size = Vector2(120, 30)
		dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dist.add_theme_font_size_override("font_size", 18)
		box.add_child(dist)
		_halves.append({"box": box, "cam": cam, "arrow": arrow, "dist": dist, "sv": sv})
	_divider = ColorRect.new()
	_divider.color = Color(0.08, 0.07, 0.1)
	_divider.position = Vector2(vs.x / 2.0 - 3, 0)
	_divider.size = Vector2(6, h)
	_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_divider)
	_show(false)

func is_split() -> bool:
	return _on

# Насколько экран сейчас разделён (0..1, для проверок)
func blend() -> float:
	return _blend

func _show(v: bool) -> void:
	visible = v
	for hf in _halves:
		hf["sv"].render_target_update_mode = SubViewport.UPDATE_ALWAYS if v else SubViewport.UPDATE_DISABLED

# Делим экран (слева — тот, кто левее) или собираем обратно
func _switch(on: bool) -> void:
	_on = on
	if not on:
		return
	var a: Player = players[0]
	var b: Player = players[1]
	_order = [0, 1] if a.global_position.x <= b.global_position.x else [1, 0]
	for i in 2:
		var foe: Player = players[_order[1 - i]]
		var col: Color = Config.OUTLINE_P1 if foe.team == 0 else Config.OUTLINE_P2   # цвет соперника
		_halves[i]["arrow"].color = col
		_halves[i]["dist"].add_theme_color_override("font_color", col.lightened(0.3))

func _process(delta: float) -> void:
	if players.size() < 2:
		return
	var a: Player = players[0]
	var b: Player = players[1]
	if not (is_instance_valid(a) and is_instance_valid(b)):
		return
	# пока кто-то возрождается — ничего не меняем
	if a.is_alive() and b.is_alive():
		var need := _need_zoom()
		if not _on and need < SPLIT_ZOOM:
			_switch(true)
		elif _on and need > MERGE_ZOOM:
			_switch(false)
	if _first:
		_first = false
		_blend = 1.0 if _on else 0.0          # в начале раунда — сразу, без перехода
	else:
		_blend = move_toward(_blend, 1.0 if _on else 0.0, delta / BLEND_TIME)
	var on_screen := _blend > 0.0
	if on_screen != visible:
		_show(on_screen)
	if not on_screen:
		return
	var k := smoothstep(0.0, 1.0, _blend)
	_divider.modulate.a = k
	var zs := ZOOM
	var vc := Vector2.ZERO
	if shared and is_instance_valid(shared):
		zs = shared.zoom.x
		vc = shared.view_center()
	for i in 2:
		var me: Player = players[_order[i]]
		var foe: Player = players[_order[1 - i]]
		var hf: Dictionary = _halves[i]
		var box: SubViewportContainer = hf["box"]
		var cam: Camera2D = hf["cam"]
		# своя камера крупным планом на своём герое
		var half := box.size / ZOOM / 2.0
		var c := me.global_position + Vector2(0, -60)
		c.x = _clamp_axis(c.x, half.x, bounds.position.x, bounds.end.x)
		c.y = minf(c.y, bounds.end.y - half.y)
		if not open_top:
			c.y = maxf(c.y, bounds.position.y + half.y)
		# та же половина общего кадра (с неё переход начинается и ею заканчивается)
		var cm := vc + Vector2((i * 2 - 1) * box.size.x / 2.0 / zs, 0)
		if shared == null:
			cm = c
		cam.position = cm.lerp(c, k)
		var z := 1.0 / lerpf(1.0 / zs, 1.0 / ZOOM, k)
		cam.zoom = Vector2(z, z)
		# стрелка на краю половины экрана — в сторону соперника
		var dir := (foe.global_position - cam.position).normalized()
		var center := box.size / 2.0
		var edge := box.size / 2.0 - Vector2(40, 40)
		var t := minf(edge.x / maxf(absf(dir.x), 0.001), edge.y / maxf(absf(dir.y), 0.001))
		var arrow: Polygon2D = hf["arrow"]
		arrow.position = center + dir * t
		arrow.rotation = dir.angle()
		arrow.modulate.a = k
		var lbl: Label = hf["dist"]
		lbl.text = "%d бл." % int(me.global_position.distance_to(foe.global_position) / BLOCK)
		lbl.position = arrow.position - dir * 46.0 - lbl.size / 2.0
		lbl.modulate.a = k

# Какое приближение нужно общей камере, чтобы оба были в кадре
func _need_zoom() -> float:
	if shared and is_instance_valid(shared):
		return shared.fit_zoom()
	# без общей камеры — по расстоянию на экране
	var vs := Config.screen(self)
	var d: Vector2 = (players[0].global_position - players[1].global_position).abs() + Vector2(520, 360)
	return minf(vs.x / d.x, (vs.y - Config.panel()) / d.y)

func _clamp_axis(v: float, half: float, lo: float, hi: float) -> float:
	if hi - lo <= half * 2.0:
		return (lo + hi) / 2.0
	return clampf(v, lo + half, hi - half)
