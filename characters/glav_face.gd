class_name GlavFace
# ---------- Маска Главного ----------
# Открытая версия игры: вместо фотографии — нарисованная маска (гладкая золотая маска с тёмными очками «за 23914$», ухмылка, воротник пальто.)
# Картинка 44×58, PNG в base64 прямо в коде. Нарисована скриптом tools/public/make_masks.py
# и распространяется по той же лицензии, что и вся игра (GPL-3.0-or-later).

const PNG := (
	"iVBORw0KGgoAAAANSUhEUgAAACwAAAA6CAYAAADLC7uHAAAB/ElEQVR42mPcl/f/P8MQAiwMDAwMu86dHBKOdTMyhziYgYGBYcONukHt" +
	"2ACNJgYGBgYGJoYhBkYdTJdMRwr4/OceVR3Ay6I0GsI0CVl0c4kN6eEXwrhCNt/rHUUWT9wmRFZID/9S4smjFpLUf7u7AYU/tXsXSgyh" +
	"h/TILSUoTbMwkF3qRlFID78QRg9Z9DRJLHh87SYK389bHk3FQwYGBgaGebtGaikBS3ujrbVRBw+VNPzkxykGBgYGhqZNDFB6B52cBLFX" +
	"hsNsmIcwzIewkJ585j0DAwMDQ4I6tKfAK0iSRTD9uSb49X0+acXAwMDAoGn/Z4SVw7CQySWg7uVhDxS+uO0OokIWBmAhe/0gC9aQHi3W" +
	"qA2uH2SBh/bwTMN1fkzQcvgfSWkXXRyWlgnZM2/XSO1x4ApBYsGZmYp45TdtfYi1tICBAI3RUgICjmw9wXBk64nR1hrZ4xKEgI23Bf42" +
	"xfz7kJovUXE0hKkKKA3ZkRvCZaXE9UQoDdnhH8KwsTD08YmubuJqQPSRn9EQhoF5u0wYGBgYGJLczuANaUJAVksda4yh2zNy0zC1Qprc" +
	"kB055TCukCbXnJFbSkyL2kmWgeiLRdyMzLGqM4nCb07WMvdhHsKxi1TJMjBWZwlVzME1Izrapxt1MK40DFu1RG2Anqap4mBcRc9gBAAZ" +
	"faSEkYJg6wAAAABJRU5ErkJggg=="
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
