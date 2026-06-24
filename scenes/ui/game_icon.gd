extends Control
class_name GameIcon
## Каменный иконочный виджет. Рисует все игровые иконки через _draw().
## Стиль: выветренный камень с трещинами и мхом.

enum IconType {
	FOOD,        # 0  пшеничный колос
	MATERIALS,   # 1  брёвна
	MEDICINE,    # 2  крест
	STONE,       # 3  горный силуэт
	METAL,       # 4  шестерня
	HEALTH,      # 5  сердце
	PHASE_DAWN,  # 6  рассвет
	PHASE_DAY,   # 7  солнце
	PHASE_DUSK,  # 8  закат
	PHASE_NIGHT, # 9  луна
	SAVE,        # 10 каменная плита
	BUILD,       # 11 молоток
	JOURNAL,     # 12 книга
	EXPEDITION,  # 13 компас
	CRAFT,       # 14 ступка
	DEMOLISH,    # 15 кувалда
	MORALE,      # 16 костёр
	SHIELD,      # 17 щит
}

@export var icon_type: IconType = IconType.FOOD
@export var draw_background: bool = true

const C_STONE_DARK  := Color(0.16, 0.13, 0.11)
const C_STONE_MID   := Color(0.30, 0.25, 0.19)
const C_STONE_LIGHT := Color(0.42, 0.36, 0.28)
const C_ICON        := Color(0.82, 0.75, 0.62)
const C_ACCENT      := Color(0.62, 0.44, 0.22)
const C_MOSS        := Color(0.22, 0.46, 0.12)
const C_SUN         := Color(0.92, 0.76, 0.22)
const C_METAL_ICON  := Color(0.46, 0.52, 0.60)
const C_BLOOD       := Color(0.54, 0.07, 0.07)
const C_SNOW        := Color(0.90, 0.90, 0.93)

func _draw() -> void:
	var s := minf(size.x, size.y)
	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var r := s * 0.5

	if draw_background:
		_bg(cx, cy, r)

	var ir := r * 0.60
	match icon_type:
		IconType.FOOD:        _food(cx, cy, ir)
		IconType.MATERIALS:   _materials(cx, cy, ir)
		IconType.MEDICINE:    _medicine(cx, cy, ir)
		IconType.STONE:       _stone_icon(cx, cy, ir)
		IconType.METAL:       _metal(cx, cy, ir)
		IconType.HEALTH:      _health(cx, cy, ir)
		IconType.PHASE_DAWN:  _dawn(cx, cy, ir)
		IconType.PHASE_DAY:   _day(cx, cy, ir)
		IconType.PHASE_DUSK:  _dusk(cx, cy, ir)
		IconType.PHASE_NIGHT: _night(cx, cy, ir)
		IconType.SAVE:        _save(cx, cy, ir)
		IconType.BUILD:       _build(cx, cy, ir)
		IconType.JOURNAL:     _journal(cx, cy, ir)
		IconType.EXPEDITION:  _expedition(cx, cy, ir)
		IconType.CRAFT:       _craft(cx, cy, ir)
		IconType.DEMOLISH:    _demolish(cx, cy, ir)
		IconType.MORALE:      _morale(cx, cy, ir)
		IconType.SHIELD:      _shield(cx, cy, ir)

# ─── Фон ───────────────────────────────────────────────────────────────────────

func _bg(cx: float, cy: float, r: float) -> void:
	var rr := r * 0.88
	# Базовая плита
	draw_rect(Rect2(cx - rr, cy - rr, rr * 2.0, rr * 2.0), C_STONE_DARK)
	# Левый и верхний блик (имитация объёма)
	draw_line(Vector2(cx - rr + 2, cy - rr + 1), Vector2(cx + rr - 2, cy - rr + 1), C_STONE_MID, 1.5)
	draw_line(Vector2(cx - rr + 1, cy - rr + 2), Vector2(cx - rr + 1, cy + rr - 2), C_STONE_MID, 1.5)
	# Правый и нижний тёмный край
	draw_line(Vector2(cx + rr - 1, cy - rr + 2), Vector2(cx + rr - 1, cy + rr - 1), C_STONE_DARK.darkened(0.3), 1.0)
	draw_line(Vector2(cx - rr + 2, cy + rr - 1), Vector2(cx + rr - 1, cy + rr - 1), C_STONE_DARK.darkened(0.3), 1.0)
	# Диагональная трещина
	draw_line(Vector2(cx + rr * 0.25, cy - rr * 0.65), Vector2(cx + rr * 0.55, cy + rr * 0.20), C_STONE_LIGHT, 1.0)
	draw_line(Vector2(cx + rr * 0.55, cy + rr * 0.20), Vector2(cx + rr * 0.35, cy + rr * 0.62), C_STONE_LIGHT, 1.0)
	# Мох по верхнему краю
	for i in 5:
		var mx := cx - rr * 0.5 + float(i) * rr * 0.25
		draw_circle(Vector2(mx, cy - rr + 2.0), 2.0, C_MOSS)

# ─── Иконки ────────────────────────────────────────────────────────────────────

func _food(cx: float, cy: float, r: float) -> void:
	# Пшеничный колос: стебель + зёрна
	draw_line(Vector2(cx, cy + r), Vector2(cx, cy - r * 0.2), C_SUN, 2.0)
	draw_line(Vector2(cx, cy + r * 0.35), Vector2(cx - r * 0.48, cy + r * 0.05), C_SUN, 1.5)
	draw_line(Vector2(cx, cy + r * 0.05), Vector2(cx + r * 0.48, cy - r * 0.22), C_SUN, 1.5)
	for i in 5:
		var a := (float(i) / 4.0 - 0.5) * PI * 0.75
		var gx := cx + sin(a) * r * 0.32
		var gy := cy - r * 0.22 - cos(a) * r * 0.46
		draw_circle(Vector2(gx, gy), 2.8, C_SUN)

func _materials(cx: float, cy: float, r: float) -> void:
	# Три спила бревна
	for i in 3:
		var oy := cy + r * 0.55 - float(i) * r * 0.50
		_ellipse(cx, oy, r * 0.78, r * 0.24, C_ACCENT)
		_ellipse(cx, oy, r * 0.52, r * 0.14, C_STONE_MID)
		draw_circle(Vector2(cx, oy), r * 0.12, C_STONE_DARK)

func _medicine(cx: float, cy: float, r: float) -> void:
	var med_col := Color(0.78, 0.84, 0.90)
	var t := r * 0.30
	draw_rect(Rect2(cx - t, cy - r, t * 2.0, r * 2.0), med_col)
	draw_rect(Rect2(cx - r, cy - t, r * 2.0, t * 2.0), med_col)
	# Выбоины на кресте
	draw_line(Vector2(cx - t * 0.4, cy - r * 0.6), Vector2(cx + t * 0.2, cy - r * 0.4), C_STONE_MID, 1.0)

func _stone_icon(cx: float, cy: float, r: float) -> void:
	# Горный силуэт с двумя пиками
	var pts := PackedVector2Array([
		Vector2(cx - r,       cy + r * 0.55),
		Vector2(cx - r * 0.5, cy - r * 0.25),
		Vector2(cx - r * 0.1, cy - r),
		Vector2(cx + r * 0.28, cy - r * 0.52),
		Vector2(cx + r,       cy + r * 0.55),
	])
	draw_colored_polygon(pts, C_ICON)
	# Снег на вершине
	draw_circle(Vector2(cx - r * 0.1, cy - r * 0.88), r * 0.22, C_SNOW)
	draw_circle(Vector2(cx + r * 0.28, cy - r * 0.45), r * 0.14, C_SNOW)

func _metal(cx: float, cy: float, r: float) -> void:
	# Шестерня 8 зубьев
	var teeth := 8
	var ri := r * 0.44
	var ro := r * 0.72
	var pts := PackedVector2Array()
	for i in teeth:
		var a0 := TAU * float(i) / teeth - TAU / (teeth * 4.2)
		var a1 := TAU * float(i) / teeth + TAU / (teeth * 4.2)
		var a2 := TAU * (float(i) + 0.5) / teeth - TAU / (teeth * 4.2)
		var a3 := TAU * (float(i) + 0.5) / teeth + TAU / (teeth * 4.2)
		pts.append(Vector2(cx + cos(a0) * ro, cy + sin(a0) * ro))
		pts.append(Vector2(cx + cos(a1) * ro, cy + sin(a1) * ro))
		pts.append(Vector2(cx + cos(a2) * ri, cy + sin(a2) * ri))
		pts.append(Vector2(cx + cos(a3) * ri, cy + sin(a3) * ri))
	draw_colored_polygon(pts, C_METAL_ICON)
	draw_circle(Vector2(cx, cy), r * 0.24, C_STONE_DARK)
	draw_circle(Vector2(cx, cy), r * 0.12, C_METAL_ICON)

func _health(cx: float, cy: float, r: float) -> void:
	# Параметрическое сердце
	var pts := PackedVector2Array()
	for i in 36:
		var t := TAU * float(i) / 36.0
		var hx := 16.0 * pow(sin(t), 3)
		var hy := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(Vector2(cx + hx * r / 17.5, cy + hy * r / 17.5))
	draw_colored_polygon(pts, C_BLOOD)
	# Блик
	draw_circle(Vector2(cx - r * 0.22, cy - r * 0.28), r * 0.14, C_BLOOD.lightened(0.35))

func _dawn(cx: float, cy: float, r: float) -> void:
	# Полукруг над горизонтом
	var hy := cy + r * 0.15
	draw_line(Vector2(cx - r, hy), Vector2(cx + r, hy), C_ICON, 1.5)
	var pts := PackedVector2Array()
	pts.append(Vector2(cx - r * 0.72, hy))
	for i in 18:
		var a := PI + PI * float(i) / 17.0
		pts.append(Vector2(cx + cos(a) * r * 0.72, hy + sin(a) * r * 0.72))
	pts.append(Vector2(cx + r * 0.72, hy))
	draw_colored_polygon(pts, C_SUN)
	# Лучи вверх
	for i in 5:
		var a := PI + PI * float(i) / 4.0
		if sin(a) > 0.0:
			continue
		draw_line(
			Vector2(cx, hy) + Vector2(cos(a), sin(a)) * r * 0.78,
			Vector2(cx, hy) + Vector2(cos(a), sin(a)) * r * 0.98,
			C_SUN, 1.5
		)

func _day(cx: float, cy: float, r: float) -> void:
	# Полное солнце с лучами
	draw_circle(Vector2(cx, cy), r * 0.48, C_SUN)
	for i in 8:
		var a := TAU * float(i) / 8.0
		draw_line(
			Vector2(cx, cy) + Vector2(cos(a), sin(a)) * r * 0.56,
			Vector2(cx, cy) + Vector2(cos(a), sin(a)) * r * 0.88,
			C_SUN, 2.0
		)

func _dusk(cx: float, cy: float, r: float) -> void:
	# Закат — зеркальный рассвет с красноватым оттенком
	var hy := cy + r * 0.15
	draw_line(Vector2(cx - r, hy), Vector2(cx + r, hy), C_ICON, 1.5)
	var dusk_col := C_SUN.lerp(Color(0.95, 0.45, 0.12), 0.5)
	var pts := PackedVector2Array()
	pts.append(Vector2(cx - r * 0.72, hy))
	for i in 18:
		var a := PI + PI * float(i) / 17.0
		pts.append(Vector2(cx + cos(a) * r * 0.72, hy + sin(a) * r * 0.72))
	pts.append(Vector2(cx + r * 0.72, hy))
	draw_colored_polygon(pts, dusk_col)
	for i in 3:
		var a := PI + PI * float(i + 1) / 4.0
		if sin(a) > 0.0:
			continue
		draw_line(
			Vector2(cx, hy) + Vector2(cos(a), sin(a)) * r * 0.78,
			Vector2(cx, hy) + Vector2(cos(a), sin(a)) * r * 0.98,
			dusk_col, 1.5
		)

func _night(cx: float, cy: float, r: float) -> void:
	# Серп луны: светлый диск минус смещённый тёмный
	var moon_col := Color(0.84, 0.84, 0.76)
	draw_circle(Vector2(cx, cy), r * 0.64, moon_col)
	var bg := C_STONE_DARK if draw_background else Color(0, 0, 0, 0)
	draw_circle(Vector2(cx + r * 0.30, cy - r * 0.12), r * 0.50, bg)
	# Звёздочки
	for star in [Vector2(0.55, -0.6), Vector2(0.75, 0.1), Vector2(0.3, 0.7)]:
		draw_circle(Vector2(cx + star.x * r, cy + star.y * r), 1.5, moon_col)

func _save(cx: float, cy: float, r: float) -> void:
	# Каменная плита с насечками-строками
	draw_rect(Rect2(cx - r * 0.72, cy - r * 0.85, r * 1.44, r * 1.7), C_ICON)
	draw_rect(Rect2(cx - r * 0.72, cy - r * 0.85, r * 1.44, r * 1.7), C_STONE_MID, false, 1.5)
	# Строки текста (насечки)
	for i in 4:
		var ly := cy - r * 0.48 + float(i) * r * 0.35
		draw_line(Vector2(cx - r * 0.48, ly), Vector2(cx + r * 0.48, ly), C_STONE_MID, 1.5)
	# Зарубка сверху
	draw_line(Vector2(cx - r * 0.18, cy - r * 0.85), Vector2(cx - r * 0.05, cy - r * 0.62), C_STONE_DARK, 2.0)

func _build(cx: float, cy: float, r: float) -> void:
	# Молоток
	draw_line(Vector2(cx - r * 0.08, cy + r * 0.88), Vector2(cx + r * 0.52, cy - r * 0.28), C_ACCENT, 3.0)
	var pts := PackedVector2Array([
		Vector2(cx - r * 0.48, cy - r * 0.52),
		Vector2(cx + r * 0.12, cy - r * 0.92),
		Vector2(cx + r * 0.58, cy - r * 0.52),
		Vector2(cx - r * 0.02, cy - r * 0.12),
	])
	draw_colored_polygon(pts, C_ICON)
	# Зарубина от ударов
	draw_line(Vector2(cx + r * 0.08, cy - r * 0.78), Vector2(cx + r * 0.28, cy - r * 0.58), C_STONE_MID, 1.5)

func _journal(cx: float, cy: float, r: float) -> void:
	# Книга / свиток
	draw_rect(Rect2(cx - r * 0.68, cy - r * 0.88, r * 1.36, r * 1.76), C_ICON)
	draw_rect(Rect2(cx - r * 0.68, cy - r * 0.88, r * 1.36, r * 1.76), C_STONE_DARK, false, 1.5)
	draw_line(Vector2(cx - r * 0.68, cy - r * 0.88), Vector2(cx - r * 0.68, cy + r * 0.88), C_ACCENT, 4.0)
	for i in 5:
		var ly := cy - r * 0.58 + float(i) * r * 0.36
		var x0 := cx - r * 0.38 if i % 2 == 0 else cx - r * 0.28
		draw_line(Vector2(x0, ly), Vector2(cx + r * 0.52, ly), C_STONE_MID, 1.5)

func _expedition(cx: float, cy: float, r: float) -> void:
	# Компас
	_ellipse(cx, cy, r * 0.78, r * 0.78, C_STONE_MID)
	_ellipse(cx, cy, r * 0.62, r * 0.62, C_STONE_DARK)
	draw_circle(Vector2(cx, cy), r * 0.78, C_ICON, false, 1.5)
	# Северная стрелка (красная)
	var pn := PackedVector2Array([
		Vector2(cx, cy - r * 0.52),
		Vector2(cx - r * 0.16, cy + r * 0.08),
		Vector2(cx + r * 0.16, cy + r * 0.08),
	])
	draw_colored_polygon(pn, C_BLOOD)
	# Южная стрелка (белая)
	var ps := PackedVector2Array([
		Vector2(cx, cy + r * 0.52),
		Vector2(cx - r * 0.16, cy - r * 0.08),
		Vector2(cx + r * 0.16, cy - r * 0.08),
	])
	draw_colored_polygon(ps, C_ICON)
	draw_circle(Vector2(cx, cy), r * 0.1, C_STONE_MID)

func _craft(cx: float, cy: float, r: float) -> void:
	# Ступка и пестик
	var pts := PackedVector2Array([
		Vector2(cx - r * 0.72, cy + r * 0.72),
		Vector2(cx - r * 0.52, cy + r * 0.02),
		Vector2(cx + r * 0.52, cy + r * 0.02),
		Vector2(cx + r * 0.72, cy + r * 0.72),
	])
	draw_colored_polygon(pts, C_ICON)
	draw_line(Vector2(cx - r * 0.72, cy + r * 0.72), Vector2(cx + r * 0.72, cy + r * 0.72), C_ICON, 3.0)
	# Пестик
	draw_line(Vector2(cx + r * 0.18, cy + r * 0.02), Vector2(cx + r * 0.62, cy - r * 0.82), C_ICON, 4.0)
	draw_circle(Vector2(cx + r * 0.65, cy - r * 0.86), r * 0.15, C_ICON)

func _demolish(cx: float, cy: float, r: float) -> void:
	# Кувалда (как молоток, но с выбоиной — символ сноса)
	draw_line(Vector2(cx - r * 0.08, cy + r * 0.88), Vector2(cx + r * 0.52, cy - r * 0.28), C_ACCENT, 3.0)
	var pts := PackedVector2Array([
		Vector2(cx - r * 0.52, cy - r * 0.48),
		Vector2(cx + r * 0.08, cy - r * 0.92),
		Vector2(cx + r * 0.62, cy - r * 0.48),
		Vector2(cx + r * 0.02, cy - r * 0.04),
	])
	draw_colored_polygon(pts, C_ICON)
	# Крест — знак удаления
	draw_line(Vector2(cx - r * 0.22, cy - r * 0.78), Vector2(cx + r * 0.12, cy - r * 0.42), C_BLOOD, 2.0)
	draw_line(Vector2(cx - r * 0.22, cy - r * 0.42), Vector2(cx + r * 0.12, cy - r * 0.78), C_BLOOD, 2.0)

func _morale(cx: float, cy: float, r: float) -> void:
	# Костёр — поленья крест-накрест + языки пламени
	draw_line(Vector2(cx - r * 0.62, cy + r * 0.72), Vector2(cx + r * 0.62, cy + r * 0.12), C_ACCENT, 3.0)
	draw_line(Vector2(cx + r * 0.62, cy + r * 0.72), Vector2(cx - r * 0.62, cy + r * 0.12), C_ACCENT, 3.0)
	var flame := PackedVector2Array([
		Vector2(cx - r * 0.46, cy + r * 0.14),
		Vector2(cx - r * 0.56, cy - r * 0.22),
		Vector2(cx - r * 0.22, cy - r * 0.56),
		Vector2(cx,            cy - r * 0.88),
		Vector2(cx + r * 0.22, cy - r * 0.56),
		Vector2(cx + r * 0.56, cy - r * 0.22),
		Vector2(cx + r * 0.46, cy + r * 0.14),
	])
	draw_colored_polygon(flame, Color(0.95, 0.52, 0.08))
	var inner := PackedVector2Array([
		Vector2(cx - r * 0.24, cy + r * 0.10),
		Vector2(cx - r * 0.14, cy - r * 0.42),
		Vector2(cx,            cy - r * 0.66),
		Vector2(cx + r * 0.14, cy - r * 0.42),
		Vector2(cx + r * 0.24, cy + r * 0.10),
	])
	draw_colored_polygon(inner, Color(0.98, 0.86, 0.28))

func _shield(cx: float, cy: float, r: float) -> void:
	# Щит — пятиугольник с крестом
	var pts := PackedVector2Array([
		Vector2(cx - r * 0.70, cy - r * 0.74),
		Vector2(cx + r * 0.70, cy - r * 0.74),
		Vector2(cx + r * 0.70, cy + r * 0.08),
		Vector2(cx,            cy + r * 0.84),
		Vector2(cx - r * 0.70, cy + r * 0.08),
	])
	draw_colored_polygon(pts, C_ICON)
	draw_line(Vector2(cx, cy - r * 0.62), Vector2(cx, cy + r * 0.56), C_STONE_MID, 1.5)
	draw_line(Vector2(cx - r * 0.54, cy - r * 0.18), Vector2(cx + r * 0.54, cy - r * 0.18), C_STONE_MID, 1.5)

# ─── Вспомогательный эллипс ────────────────────────────────────────────────────

func _ellipse(px: float, py: float, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(Vector2(px + cos(a) * rx, py + sin(a) * ry))
	draw_colored_polygon(pts, color)
