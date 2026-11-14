#!/bin/bash
# Открытая версия проекта — для публикации на GitHub.
#   tools/public/make_github_archive.sh [куда.zip]        (по умолчанию ../PathOfLegends-github.zip)
#
# Что делает:
#   1. берёт последнюю зафиксированную версию проекта (git HEAD) — БЕЗ истории git:
#      в истории лежат фотографии реальных людей, поэтому её публиковать нельзя;
#   2. заменяет четыре файла с фотографиями (characters/*_face.gd) нарисованными масками
#      из tools/public/faces/*.gd.txt (их рисует tools/public/make_masks.py);
#   3. переписывает в README раздел «Исключение»: в открытой версии исключений из GPL нет;
#   4. проверяет, что в архив не попали ключи подписи, пароли и фотографии, и собирает zip.
#
# Публиковать так: распаковать архив в пустую папку, в ней `git init`, первый коммит, `git push`
# в НОВЫЙ репозиторий. Существующую историю этого проекта на GitHub не отправлять.
set -e
cd "$(dirname "$0")/../.."
OUT=${1:-../PathOfLegends-github.zip}
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
NAME=PathOfLegends
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [ -n "$(git status --porcelain)" ]; then
	echo "ВНИМАНИЕ: есть незафиксированные изменения — в архив они не попадут (берётся git HEAD)."
fi
git archive --format=tar --prefix="$NAME/" HEAD | tar -x -C "$TMP"
D="$TMP/$NAME"

# маски вместо фотографий
for f in pivo glav genius dj; do
	[ -f "$D/tools/public/faces/${f}_face.gd.txt" ] || { echo "нет маски $f — сначала python3 tools/public/make_masks.py и коммит"; exit 1; }
	cp "$D/tools/public/faces/${f}_face.gd.txt" "$D/characters/${f}_face.gd"
done

# README: раздел «Исключение» — для открытой версии
python3 - "$D/README.md" <<'EOF'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
new = """### Лица персонажей

В этой, открытой, версии лица персонажей «Пивозавр», «Главный», «Недопонятый гений» и
«DJ Клима» — нарисованные маски (`characters/*_face.gd`, их рисует
`tools/public/make_masks.py`). Маски распространяются по той же лицензии GPL, что и вся
игра. В авторской сборке на их месте — фотографии реальных людей; в открытую версию они
не входят.

"""
s2, n = re.subn(r"### Исключение\n.*?(?=Движок Godot распространяется)", new, s, flags=re.S)
if n != 1:
    sys.exit("README: раздел «Исключение» не найден")
open(p, "w", encoding="utf-8").write(s2)
EOF

# проверки
bad=$(cd "$TMP" && find . -iname "*keystore*" -o -iname "*password*" -o -iname "*.jks" -o -iname "export_credentials.cfg" -o -name ".git" | head -5)
[ -z "$bad" ] || { echo "в архив попало лишнее: $bad"; exit 1; }
for f in pivo glav genius dj; do
	cmp -s "$D/characters/${f}_face.gd" "$D/tools/public/faces/${f}_face.gd.txt" || { echo "лицо $f не заменено"; exit 1; }
	# маска — несколько сотен символов base64, фотография — тысячи
	n=$(grep -c '^	"' "$D/characters/${f}_face.gd")
	[ "$n" -le 12 ] || { echo "в $f слишком большая картинка ($n строк) — похоже на фотографию"; exit 1; }
done
grep -q "### Исключение" "$D/README.md" && { echo "README не переписан"; exit 1; }

rm -f "$OUT"
(cd "$TMP" && zip -q -r -9 "$OUT" "$NAME")
echo "готово: $OUT ($(du -h "$OUT" | cut -f1)), файлов: $(unzip -l "$OUT" | tail -1 | awk '{print $2}')"
