class_name PivoFace
# ---------- Маска Пивозавра ----------
# Открытая версия игры: вместо фотографии — нарисованная маска (маска динозавра — гребень, жёлтые глаза, зубастая пасть, пивная пена на носу.)
# Картинка 44×58, PNG в base64 прямо в коде. Нарисована скриптом tools/public/make_masks.py
# и распространяется по той же лицензии, что и вся игра (GPL-3.0-or-later).

const PNG := (
	"iVBORw0KGgoAAAANSUhEUgAAACwAAAA6CAYAAADLC7uHAAABxUlEQVR42mNkYGBg+N8j8p9hCADGkjeMjEPFsTDAAmPkrOMa1A6dEvSN" +
	"gYGBgYGJYYiBUQcPuIMPO4swHHYWGTD5kZMkBktIj2a6UQfjqumIBRtU0Pz48B1F8sIjPoQt7Czo66K9W0Yz3aiDqZKG4bl58TaiDDIM" +
	"NMArf379BeJcBLU34M6/EVJKwEJus3sCAwMDA4O0ShaK/NNjEHnf8/jNeTJjAgH9bETFxDCu6V7NoswmSvWPFmujDh518CAvJWDlpNFU" +
	"MzRx+ugfOT0OGLBXlaLI4oO3n42mYaJCdkIXpDVXUOaFVx+6Opg5pIb08A1h9JAtUSmH0LPKidKPrq7nTidZIT380zAsZCkFMHNgIT2a" +
	"htHTHrVCbLQcxghJ7akMDAwMDDYKggwMDAwMRx68p4gfsDVqNIRRALVCFsZn+PkImgegFnii2pfjZDu0Qxg+dYs+E4o+jgsbn6C0lUZq" +
	"uQ4L4SE7E4ozDcPGtmAhDR+RCaRue3iDtz4kTU/5gJpXcgSwOnX4lRKEQppcADNHYbSmIxTSNAYG0nxQ1rdhHsLoIU0tcAFnqTDSxyWo" +
	"n0aHaSkx5JaBMTGWvGEcMqFb8oYRAHRKsf8A2sr+AAAAAElFTkSuQmCC"
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
