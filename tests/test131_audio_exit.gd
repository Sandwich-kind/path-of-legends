extends SceneTree
# Выход без утечек: узел звука освобождается вместе с главной сценой.
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 10:
		Audio.sfx("click")
		Audio.stinger("unlock")
		main.queue_free()
	if f == 20:
		print("audio inst after free: ", Audio.inst)
		return true
	return false
