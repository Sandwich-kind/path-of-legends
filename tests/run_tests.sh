#!/bin/bash
# Запуск проверочных сценариев.
#   tests/run_tests.sh                    — все tests/test*.gd
#   tests/run_tests.sh test204 test15     — только названные (можно без хвоста имени)
#   JOBS=2 OUT=/tmp/pol_tests tests/run_tests.sh
#   NO_WINDOW=1 T_HEADLESS=90 tests/run_tests.sh   — быстрый обход только без окна
#
# Каждый тест сначала идёт без окна (--headless, это быстро). Если он так не прошёл
# (ему нужен снимок экрана, он завис или упал), тест повторяется в окне под xvfb.
# У каждого запуска своя пустая папка сохранений (XDG_DATA_HOME): тесты не мешают
# друг другу и не трогают ваши сохранения. Итог — в $OUT/summary.txt:
#   PASS — прошёл; FAIL — есть строки FAIL или ошибки скрипта; TIMEOUT — не уложился во время
#   (долгий тест задаёт своё время строкой «# TIMEOUT=секунд» в начале файла).
# Нужны: godot (4.5.1) в PATH; для второй попытки — xvfb-run.
cd "$(dirname "$0")/.." || exit 1
OUT=${OUT:-/tmp/pol_tests}
JOBS=${JOBS:-2}
T_HEADLESS=${T_HEADLESS:-240}
T_WINDOW=${T_WINDOW:-900}
LOG_MAX=${LOG_MAX:-2000000}       # тест, который сыплет ошибками каждый кадр, обрывается, а не висит до конца времени
mkdir -p "$OUT"
: > "$OUT/summary.txt"

if [ $# -gt 0 ]; then
	LIST=""
	for t in "$@"; do
		f=$(ls tests/${t}.gd tests/${t}_*.gd 2>/dev/null | head -1)
		[ -n "$f" ] && LIST="$LIST $f" || echo "нет теста: $t"
	done
else
	LIST=$(ls tests/test*.gd | sort -V)
fi

verdict() {          # $1 — лог, $2 — код выхода
	local log=$1 code=$2
	if [ "$code" = "124" ] || [ "$code" = "137" ]; then echo TIMEOUT; return; fi
	if [ "$code" = "141" ]; then echo FAIL; return; fi          # лог переполнился ошибками
	if grep -qE "SCRIPT ERROR|Parse Error" "$log"; then echo FAIL; return; fi
	if grep -vE "fails=0|errors=0" "$log" | grep -qE "(^|[^a-zA-Z])FAIL|fails=[1-9]|errors=[1-9]|НЕ ПРОШ"; then echo FAIL; return; fi
	if [ "$code" != "0" ]; then echo FAIL; return; fi
	echo PASS
}

run_one() {
	local f=$1 name xdg log v code how th tw own
	name=$(basename "$f" .gd)
	th=$T_HEADLESS; tw=$T_WINDOW
	own=$(head -5 "$f" | grep -m1 -oE "TIMEOUT=[0-9]+" | cut -d= -f2)      # долгий тест сам говорит, сколько ему нужно
	[ -n "$own" ] && th=$own && tw=$own
	xdg="$OUT/xdg_$name"
	log="$OUT/$name.log"
	rm -rf "$xdg"; mkdir -p "$xdg"
	how=headless
	XDG_DATA_HOME="$xdg" timeout "$th" godot --headless --fixed-fps 60 --path . -s "res://$f" 2>&1 | head -c "$LOG_MAX" > "$log"
	code=${PIPESTATUS[0]}
	v=$(verdict "$log" $code)
	if [ "$v" != "PASS" ] && [ -z "$NO_WINDOW" ] && command -v xvfb-run > /dev/null; then
		mv "$log" "$OUT/$name.headless.log"
		rm -rf "$xdg"; mkdir -p "$xdg"
		how=window
		XDG_DATA_HOME="$xdg" timeout "$tw" xvfb-run -a -s "-screen 0 1600x720x24" godot --fixed-fps 60 --path . \
			--rendering-driver opengl3 --resolution 1600x720 -s "res://$f" 2>&1 | head -c "$LOG_MAX" > "$log"
		code=${PIPESTATUS[0]}
		v=$(verdict "$log" $code)
	fi
	rm -rf "$xdg"
	echo "$v $name ($how, код $code)" >> "$OUT/summary.txt"
}

export -f run_one verdict
export OUT T_HEADLESS T_WINDOW LOG_MAX NO_WINDOW
echo $LIST | tr ' ' '\n' | xargs -P "$JOBS" -I{} bash -c 'run_one {}'
sort -k2 -V "$OUT/summary.txt" -o "$OUT/summary.txt"
echo "PASS: $(grep -c '^PASS' "$OUT/summary.txt")  FAIL: $(grep -c '^FAIL' "$OUT/summary.txt")  TIMEOUT: $(grep -c '^TIMEOUT' "$OUT/summary.txt")"
grep -v '^PASS' "$OUT/summary.txt"
exit 0
