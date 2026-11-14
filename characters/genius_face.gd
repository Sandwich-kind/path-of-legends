class_name GeniusFace
# ---------- Маска Недопонятого гения ----------
# Открытая версия игры: вместо фотографии — нарисованная маска (голова-монитор с зелёным терминалом вместо лица, фиолетовый «глитч».)
# Картинка 44×58, PNG в base64 прямо в коде. Нарисована скриптом tools/public/make_masks.py
# и распространяется по той же лицензии, что и вся игра (GPL-3.0-or-later).

const PNG := (
	"iVBORw0KGgoAAAANSUhEUgAAACwAAAA6CAYAAADLC7uHAAACGUlEQVR42u1ZQSgEURj+aCXZcqEoOdg9bbY4iYNYlIs4OGmR5Kg2J6aw" +
	"rayLJJxsKSUHNwcn7GEPNidlywlpoxzmSHugODy/esOY3VmzeW/ef/n3fztv3rfffvP1vzdlc7X+dwgUHgBoqo0LATarawwwAMSfZ/41" +
	"WM27BQAoh2ChACvAogP2WF3Q0dleUkDp8wuXMGxktr8v5CiQk9Mkt64Z0+IzbGT2KHnGZadjKNT7K9PyaJg0e5xOlQTIS+sYACDR5+M0" +
	"LY+GqRvCFUtvn3mteufHiRF98k+BVKZ3AQDbgyuS+jD1w/R0koYjy1FuQjAzyiYGK1Qv8Se9xFvulasv/XsAgLabCa5WDNtl2FP1s1Yz" +
	"wQOOaaoVw8VqmMJKw/S9VSzVjAMAhut6lYY5HybNmmk83xhpGijoPu7xYatwyp/d48N2w6z7+/pH11nuQZhlb9ilPkzRuM/88yGc354v" +
	"kmN99CwaCgJKR8Lya7g+0cXVT9MpjmnjuNn1h4kAV1NsLES5PR3tmjXXaNhMq/mOF6p5+XzYl7wGANx9ZuPTvFmlF7Ugadauv4vP8G0o" +
	"wNXfztRyzgIyO/GRh2HyPTqfGMEUAKA73lxSZuU9H/7GdIgYuHcEQHankfUKp78zK2+3ZvWLKazeNpnep4WNP8rqwwqwAiy9SxhjcXHe" +
	"1kJmb1JjsVXFcFGMKA3Th6/3dCIAzuqaMAx/ABfHr9Rp1/+aAAAAAElFTkSuQmCC"
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
