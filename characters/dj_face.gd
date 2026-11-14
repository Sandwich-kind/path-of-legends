class_name DjFace
# ---------- Маска DJ Климы ----------
# Открытая версия игры: вместо фотографии — нарисованная маска (чёрный капюшон, неоновые глаза и эквалайзер вместо рта, нота на лбу, цепочка.)
# Картинка 44×58, PNG в base64 прямо в коде. Нарисована скриптом tools/public/make_masks.py
# и распространяется по той же лицензии, что и вся игра (GPL-3.0-or-later).

const PNG := (
	"iVBORw0KGgoAAAANSUhEUgAAACwAAAA6CAYAAADLC7uHAAABq0lEQVR42u2avUoDQRSFT0Qs3CppFhY0TSofICnEQgsLsbVLGRtfwdqn" +
	"0NJHUEtFRUgCVkKqNCoEYmEEsylsYrEZYS6Z7N4ZXDI7c7oL83P4mL0zc3dK0/32FBZpFQB2zhtWmH087iSGAeBz62CpzVZ6NwCAFVgm" +
	"bziXj05L1aHZzK+hJ5yJ7GDwxuoeRZvyOEzSBSackeyofiXF5e7h3H66pAtIWHPNUrJUuqQLRJhJlq7drOKSLt4aVpGN44kUr93tsSYO" +
	"gvXFpJ3d6ShZXYlxKGl3dzpBpNGPAQCdWmA0MR0nK2l3zsMv3wmhFjkWU/KC5MUsrbYMj9HuEOaSMiXrDmFudjDNJv6a7w3/W11Cocuz" +
	"vhQ3T2uecK4SO59uFnGP8PtRW4rvfZbIeQ2fXH9I8bMnnKKf3VspHuZs2G/N3rA3vKxZIgwjAMBGr7m44QPPgBh3PP5ynDAlYFpj49bU" +
	"Ckh4VgGPqklI68S6hFT6qwu7848jhfToqT63eXm7K8Vp7bKSdeC0RkhTkiqiqnZcsg7dOFKyh4qoKVn7CYtXS1xVcjZcsu2h3S+t5ZPK" +
	"uQz79gAAAABJRU5ErkJggg=="
)

static var _tex: ImageTexture

static func image() -> Image:
	var im := Image.new()
	im.load_png_from_buffer(Marshalls.base64_to_raw(PNG))
	return im

static func texture() -> ImageTexture:
	if _tex == null:
		_tex = ImageTexture.create_from_image(image())
	return _tex
