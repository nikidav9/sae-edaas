extends Node2D
class_name NPCVisual
## Внешность выжившего NPC — рисуется через _draw().
## Чиби-пропорции: большая голова, широкое тело с плечами, короткие ноги.
## Каждый элемент имеет тёмный контур (2px) — как в pixel-art.

enum Role { SNIPER, MECHANIC, MEDIC, SCOUT, FARMER }

const SKIN      := Color(0.74, 0.57, 0.43)
const HAIR_DARK := Color(0.22, 0.16, 0.10)
const HAIR_LITE := Color(0.52, 0.38, 0.18)
const DARK_BOOT := Color(0.15, 0.11, 0.08)
const OUTLINE   := Color(0.06, 0.05, 0.04)

const _O := 1.2   # outline expansion in game units

var _role: Role = Role.SCOUT
var _walk_phase: float = 0.0
var _is_moving: bool = false

func setup(data: NPCData) -> void:
	_role = _ability_to_role(data.ability_id)
	queue_redraw()

func set_moving(moving: bool) -> void:
	_is_moving = moving

func set_facing(dir: int) -> void:
	scale.x = 1.0 if dir >= 0 else -1.0

func _process(delta: float) -> void:
	var prev := _walk_phase
	if _is_moving:
		_walk_phase += delta * 7.0
	else:
		_walk_phase = move_toward(_walk_phase, 0.0, delta * 14.0)
	if _walk_phase != prev:
		queue_redraw()

func _draw() -> void:
	var b  := sin(_walk_phase * 2.0) * 1.0
	var ll := sin(_walk_phase) * 3.5
	var rl := -sin(_walk_phase) * 3.5
	match _role:
		Role.SNIPER:   _sniper(b, ll, rl)
		Role.MECHANIC: _mechanic(b, ll, rl)
		Role.MEDIC:    _medic(b, ll, rl)
		Role.SCOUT:    _scout(b, ll, rl)
		Role.FARMER:   _farmer(b, ll, rl)

func _ability_to_role(id: StringName) -> Role:
	match id:
		&"tower_sniper":   return Role.SNIPER
		&"mechanic_traps": return Role.MECHANIC
		&"medic_heal":     return Role.MEDIC
		&"scout_recon":    return Role.SCOUT
		&"farmer_food":    return Role.FARMER
	return Role.SCOUT

# Расширяет полигон от центроида на _O единиц (для рисовки контура)
func _ep(pts: PackedVector2Array) -> PackedVector2Array:
	var cx := 0.0; var cy := 0.0
	for p in pts: cx += p.x; cy += p.y
	cx /= pts.size(); cy /= pts.size()
	var ep := PackedVector2Array()
	for p in pts:
		var dx := p.x - cx; var dy := p.y - cy
		var d := maxf(sqrt(dx * dx + dy * dy), 0.01)
		ep.append(Vector2(p.x + dx / d * _O, p.y + dy / d * _O))
	return ep

# Прямоугольник с контуром
func _r(x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(x - _O, y - _O, w + _O * 2.0, h + _O * 2.0), OUTLINE)
	draw_rect(Rect2(x, y, w, h), col)

# Круг с контуром
func _c(cx: float, cy: float, r: float, col: Color) -> void:
	draw_circle(Vector2(cx, cy), r + _O, OUTLINE)
	draw_circle(Vector2(cx, cy), r, col)

# Полигон с контуром
func _p(pts: PackedVector2Array, col: Color) -> void:
	draw_colored_polygon(_ep(pts), OUTLINE)
	draw_colored_polygon(pts, col)

# Линия с контуром
func _l(x0: float, y0: float, x1: float, y1: float, col: Color, w: float) -> void:
	draw_line(Vector2(x0, y0), Vector2(x1, y1), OUTLINE, w + 2.5)
	draw_line(Vector2(x0, y0), Vector2(x1, y1), col, w)

# ─── Снайпер ──────────────────────────────────────────────────────────────────
func _sniper(b: float, ll: float, rl: float) -> void:
	var cloak  := Color(0.38, 0.38, 0.15)   # основной оливковый
	var cloak2 := Color(0.28, 0.28, 0.10)   # тень плаща
	var cloak3 := Color(0.48, 0.48, 0.20)   # свет плаща
	var hood   := Color(0.36, 0.36, 0.13)   # капюшон чуть темнее
	var bala   := Color(0.10, 0.09, 0.07)   # балаклава
	var eyes   := Color(0.85, 0.50, 0.05)   # оранжевые глаза-прицел
	var gun    := Color(0.22, 0.20, 0.15)   # металл винтовки
	var gun2   := Color(0.35, 0.32, 0.24)   # ложе (дерево)
	var pan    := Color(0.22, 0.22, 0.09)   # тёмные штаны (почти не видны)

	# Длинная снайперская винтовка наискосок
	_l(-12.0, 10.0 + b, 10.0, -12.0 + b, gun2, 3.5)   # ложе
	_l(-12.0, 10.0 + b, 10.0, -12.0 + b, gun, 1.5)     # металл поверх
	draw_rect(Rect2(7.0, -14.0 + b, 4.0, 3.5), gun)    # казённик
	draw_rect(Rect2(-14.0, 10.0 + b, 4.0, 2.5), gun)   # дульный тормоз

	# Ноги и сапоги (едва видны из-под плаща)
	draw_rect(Rect2(-5.0 + ll, 11.0 + b, 4.0, 4.0), pan)
	draw_rect(Rect2(1.0 + rl, 11.0 + b, 4.0, 4.0), pan)
	_r(-6.0 + ll, 14.0 + b, 5.5, 4.0, DARK_BOOT)
	_r(0.5 + rl, 14.0 + b, 5.5, 4.0, DARK_BOOT)

	# Массивный плащ-колокол (основная форма)
	_p(PackedVector2Array([
		Vector2(-5.0, -8.0 + b),  Vector2(-16.0, 0.0 + b),
		Vector2(-15.0, 12.0 + b), Vector2(15.0, 12.0 + b),
		Vector2(16.0, 0.0 + b),   Vector2(5.0, -8.0 + b)]), cloak)

	# Тени на плаще (левая и нижняя)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5.0, -8.0 + b), Vector2(-16.0, 0.0 + b),
		Vector2(-15.0, 12.0 + b), Vector2(-5.0, 12.0 + b),
		Vector2(-4.0, 0.0 + b)]), cloak2)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15.0, 9.0 + b), Vector2(-15.0, 12.0 + b),
		Vector2(15.0, 12.0 + b), Vector2(15.0, 9.0 + b)]), cloak2)

	# Блик на плаще (правая верхняя часть)
	draw_colored_polygon(PackedVector2Array([
		Vector2(3.0, -8.0 + b), Vector2(16.0, 0.0 + b),
		Vector2(14.0, 5.0 + b), Vector2(5.0, 0.0 + b)]), cloak3)

	# Складки плаща
	draw_line(Vector2(-4.0, -6.0 + b), Vector2(-10.0, 8.0 + b), cloak2, 1.0)
	draw_line(Vector2(2.0, -6.0 + b),  Vector2(5.0, 10.0 + b),  cloak2, 1.0)

	# Голова (небольшой круг под капюшоном — основа для балаклавы)
	draw_circle(Vector2(0.0, -13.0 + b), 6.5, bala)

	# Капюшон (большой, закрывает большую часть головы)
	_p(PackedVector2Array([
		Vector2(-5.0, -8.0 + b),  Vector2(-8.0, -14.0 + b),
		Vector2(-5.0, -22.0 + b), Vector2(5.0, -22.0 + b),
		Vector2(8.0, -14.0 + b),  Vector2(5.0, -8.0 + b)]), hood)

	# Тень внутри капюшона
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5.0, -9.0 + b),  Vector2(-5.0, -20.0 + b),
		Vector2(-2.0, -20.0 + b), Vector2(-1.0, -9.0 + b)]), hood.darkened(0.3))

	# Балаклава — тёмная зона лица
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5.0, -9.0 + b), Vector2(-6.0, -16.0 + b),
		Vector2(6.0, -16.0 + b), Vector2(5.0, -9.0 + b)]), bala)

	# Оранжевые светящиеся глаза-прицелы
	draw_rect(Rect2(-5.0, -14.0 + b, 4.0, 2.5), eyes)
	draw_rect(Rect2(1.0,  -14.0 + b, 4.0, 2.5), eyes)
	# Яркий блик на глазах
	draw_rect(Rect2(-4.5, -14.0 + b, 1.5, 1.0), Color(1.0, 0.85, 0.50))
	draw_rect(Rect2(1.5,  -14.0 + b, 1.5, 1.0), Color(1.0, 0.85, 0.50))

	# Складка капюшона
	draw_line(Vector2(-8.0, -14.0 + b), Vector2(-5.0, -22.0 + b), hood.lightened(0.10), 1.0)

# ─── Механик ──────────────────────────────────────────────────────────────────
func _mechanic(b: float, ll: float, rl: float) -> void:
	var coat  := Color(0.35, 0.26, 0.14)
	var belt  := Color(0.58, 0.46, 0.15)
	var pan   := Color(0.24, 0.20, 0.12)
	var metal := Color(0.44, 0.48, 0.54)
	var goggl := Color(0.18, 0.28, 0.42)
	var patch := Color(0.28, 0.22, 0.12)

	# Сапоги + ноги
	_r(-9.0 + ll, 10.0 + b, 8.0, 6.0, DARK_BOOT)
	_r(1.0 + rl, 10.0 + b, 8.0, 6.0, DARK_BOOT)
	_r(-8.0 + ll, 5.0 + b, 6.0, 6.0, pan)
	_r(2.0 + rl, 5.0 + b, 6.0, 6.0, pan)
	# Гаечный ключ
	_l(-13.0, 2.0 + b, -15.0, 9.0 + b, Color(0.36, 0.34, 0.22), 2.0)
	_r(-17.0, 7.0 + b, 5.5, 3.0, metal)
	# Куртка с плечами
	_p(PackedVector2Array([
		Vector2(-9.0, -5.0 + b), Vector2(-14.0, 0.0 + b),
		Vector2(-12.0, 11.0 + b), Vector2(12.0, 11.0 + b),
		Vector2(14.0, 0.0 + b), Vector2(9.0, -5.0 + b)]), coat)
	# Нагрудная заплатка
	_r(-6.0, 0.0 + b, 5.0, 5.0, patch)
	draw_rect(Rect2(-5.0, 1.0 + b, 3.0, 3.0), patch.darkened(0.2))
	# Пояс
	_r(-10.0, 4.0 + b, 20.0, 3.0, belt)
	draw_rect(Rect2(-2.0, 4.0 + b, 4.0, 3.0), belt.darkened(0.3))
	# Шея + голова
	_r(-3.0, -5.0 + b, 6.0, 3.0, SKIN)
	_c(0.0, -10.0 + b, 7.5, SKIN)
	# Взлохмаченные волосы
	_r(-7.0, -17.0 + b, 14.0, 8.0, HAIR_LITE)
	draw_rect(Rect2(-8.0, -16.0 + b, 4.0, 3.0), HAIR_LITE.darkened(0.1))
	draw_rect(Rect2(4.0, -16.0 + b, 3.0, 4.0), HAIR_LITE.lightened(0.08))
	# Большие очки-гоглы!
	_r(-8.0, -13.0 + b, 7.0, 5.0, goggl)
	_r(1.0, -13.0 + b, 7.0, 5.0, goggl)
	draw_line(Vector2(-1.0, -11.0 + b), Vector2(1.0, -11.0 + b), metal, 2.0)
	draw_rect(Rect2(-7.0, -12.0 + b, 5.0, 3.0), goggl.lightened(0.18))
	draw_rect(Rect2(2.0, -12.0 + b, 5.0, 3.0), goggl.lightened(0.18))
	draw_rect(Rect2(-8.0, -13.0 + b, 16.0, 1.5), Color(0.25, 0.22, 0.18))
	draw_rect(Rect2(-8.0, -8.0 + b, 16.0, 1.0), Color(0.25, 0.22, 0.18))
	# Пятна масла
	draw_rect(Rect2(-2.0, -6.0 + b, 4.0, 2.0), Color(0.22, 0.18, 0.12))

# ─── Медик ────────────────────────────────────────────────────────────────────
func _medic(b: float, ll: float, rl: float) -> void:
	var coat  := Color(0.82, 0.84, 0.80)
	var cross := Color(0.76, 0.10, 0.10)
	var pan   := Color(0.22, 0.22, 0.26)
	var bag   := Color(0.70, 0.70, 0.65)
	var cap   := Color(0.78, 0.80, 0.76)

	# Аптечка
	_r(7.0, -2.0 + b, 8.0, 8.0, bag)
	draw_rect(Rect2(8.5, 0.0 + b, 2.0, 5.0), cross)
	draw_rect(Rect2(7.5, 2.0 + b, 5.0, 1.5), cross)
	draw_line(Vector2(7.0, -2.0 + b), Vector2(6.0, -5.0 + b), Color(0.50, 0.48, 0.42), 1.5)
	# Сапоги + ноги
	_r(-8.0 + ll, 10.0 + b, 7.0, 5.0, DARK_BOOT)
	_r(1.0 + rl, 10.0 + b, 7.0, 5.0, DARK_BOOT)
	_r(-7.0 + ll, 5.0 + b, 5.0, 6.0, pan)
	_r(2.0 + rl, 5.0 + b, 5.0, 6.0, pan)
	# Белый халат с плечами
	_p(PackedVector2Array([
		Vector2(-8.0, -5.0 + b), Vector2(-13.0, 0.0 + b),
		Vector2(-10.0, 11.0 + b), Vector2(10.0, 11.0 + b),
		Vector2(13.0, 0.0 + b), Vector2(8.0, -5.0 + b)]), coat)
	# Красный крест
	draw_rect(Rect2(-1.5, -3.0 + b, 3.0, 8.0), cross)
	draw_rect(Rect2(-4.5, 0.0 + b, 9.0, 2.5), cross)
	# Отвороты
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -5.0 + b), Vector2(-5.0, -5.0 + b),
		Vector2(-3.0, 2.0 + b), Vector2(-8.0, 4.0 + b)]), coat.darkened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(8.0, -5.0 + b), Vector2(5.0, -5.0 + b),
		Vector2(3.0, 2.0 + b), Vector2(8.0, 4.0 + b)]), coat.darkened(0.08))
	# Шея + голова
	_r(-3.0, -5.0 + b, 6.0, 2.0, SKIN)
	_c(0.0, -10.0 + b, 7.0, SKIN)
	# Волосы
	_r(-6.0, -17.0 + b, 12.0, 7.0, HAIR_DARK)
	draw_rect(Rect2(-6.0, -16.0 + b, 5.0, 4.0), HAIR_DARK.lightened(0.04))
	# Медицинская шапочка
	_r(-7.0, -17.0 + b, 14.0, 5.0, cap)
	draw_rect(Rect2(-7.0, -17.0 + b, 14.0, 1.5), cross)
	# Очки
	draw_rect(Rect2(-6.0, -12.0 + b, 5.0, 3.0), Color(0.28, 0.40, 0.58))
	draw_rect(Rect2(1.0, -12.0 + b, 5.0, 3.0), Color(0.28, 0.40, 0.58))
	draw_line(Vector2(-1.0, -10.5 + b), Vector2(1.0, -10.5 + b), Color(0.45, 0.42, 0.38), 1.0)
	# Улыбка
	draw_line(Vector2(-2.0, -8.0 + b), Vector2(2.0, -8.0 + b), SKIN.darkened(0.22), 1.5)

# ─── Разведчик ────────────────────────────────────────────────────────────────
func _scout(b: float, ll: float, rl: float) -> void:
	var hood := Color(0.20, 0.24, 0.18)
	var jac  := Color(0.28, 0.32, 0.24)
	var pan  := Color(0.24, 0.21, 0.14)
	var pack := Color(0.40, 0.34, 0.20)
	var strp := Color(0.30, 0.24, 0.14)
	var scrf := Color(0.26, 0.30, 0.22)

	# Рюкзак
	_r(-13.0, -4.0 + b, 7.0, 12.0, pack)
	_r(-13.5, -2.0 + b, 2.0, 8.0, strp)
	_r(-11.0, 6.0 + b, 5.0, 2.0, strp)
	draw_rect(Rect2(-11.0, 0.0 + b, 5.0, 1.0), pack.darkened(0.2))
	# Сапоги + ноги
	_r(-8.0 + ll, 10.0 + b, 7.0, 4.0, Color(0.18, 0.15, 0.10))
	_r(1.0 + rl, 10.0 + b, 7.0, 4.0, Color(0.18, 0.15, 0.10))
	_r(-7.0 + ll, 5.0 + b, 5.5, 6.0, pan)
	_r(1.5 + rl, 5.0 + b, 5.5, 6.0, pan)
	# Куртка с плечами
	_p(PackedVector2Array([
		Vector2(-7.0, -5.0 + b), Vector2(-12.0, 0.0 + b),
		Vector2(-9.0, 10.0 + b), Vector2(9.0, 10.0 + b),
		Vector2(12.0, 0.0 + b), Vector2(7.0, -5.0 + b)]), jac)
	# Капюшон (первый слой)
	_p(PackedVector2Array([
		Vector2(-7.0, -5.0 + b), Vector2(-8.0, -12.0 + b),
		Vector2(-3.0, -21.0 + b), Vector2(3.0, -21.0 + b),
		Vector2(8.0, -12.0 + b), Vector2(7.0, -5.0 + b)]), hood)
	# Лицо
	draw_circle(Vector2(0.0, -9.5 + b), 6.5, SKIN)
	# Капюшон (второй слой поверх лица)
	_p(PackedVector2Array([
		Vector2(-7.0, -5.0 + b), Vector2(-8.0, -12.0 + b),
		Vector2(-3.0, -21.0 + b), Vector2(3.0, -21.0 + b),
		Vector2(8.0, -12.0 + b), Vector2(7.0, -5.0 + b)]), hood)
	# Тень
	draw_rect(Rect2(-5.0, -15.0 + b, 10.0, 8.0), Color(0.06, 0.08, 0.05))
	draw_rect(Rect2(-4.0, -11.0 + b, 8.0, 5.0), SKIN.darkened(0.20))
	# Глаза
	draw_rect(Rect2(-3.5, -10.0 + b, 3.0, 2.0), Color(0.14, 0.18, 0.28))
	draw_rect(Rect2(0.5, -10.0 + b, 3.0, 2.0), Color(0.14, 0.18, 0.28))
	# Шарф
	_r(-5.0, -7.0 + b, 10.0, 3.5, scrf)
	# Складки капюшона
	draw_line(Vector2(-7.0, -5.0 + b), Vector2(-8.0, -12.0 + b), hood.lightened(0.07), 1.0)
	draw_line(Vector2(7.0, -5.0 + b), Vector2(8.0, -12.0 + b), hood.lightened(0.07), 1.0)

# ─── Фермер ───────────────────────────────────────────────────────────────────
func _farmer(b: float, ll: float, rl: float) -> void:
	var ovr  := Color(0.40, 0.32, 0.16)
	var shrt := Color(0.62, 0.52, 0.36)
	var hat  := Color(0.62, 0.50, 0.24)
	var hat_b:= Color(0.44, 0.34, 0.16)
	var hoe_h:= Color(0.44, 0.36, 0.22)
	var hoe_m:= Color(0.40, 0.44, 0.50)
	var fbot := Color(0.22, 0.16, 0.09)

	# Мотыга
	_l(8.0, -15.0 + b, -4.0, 14.0 + b, hoe_h, 2.0)
	_p(PackedVector2Array([
		Vector2(5.0, -16.0 + b), Vector2(12.0, -17.0 + b),
		Vector2(14.0, -13.0 + b), Vector2(7.0, -12.0 + b)]), hoe_m)
	# Сапоги + ноги
	_r(-9.0 + ll, 10.0 + b, 8.0, 5.0, fbot)
	_r(1.0 + rl, 10.0 + b, 8.0, 5.0, fbot)
	_r(-8.0 + ll, 5.0 + b, 6.0, 6.0, ovr)
	_r(2.0 + rl, 5.0 + b, 6.0, 6.0, ovr)
	# Рубашка с широкими плечами
	_p(PackedVector2Array([
		Vector2(-8.0, -5.0 + b), Vector2(-14.0, 0.0 + b),
		Vector2(-11.0, 10.0 + b), Vector2(11.0, 10.0 + b),
		Vector2(14.0, 0.0 + b), Vector2(8.0, -5.0 + b)]), shrt)
	# Комбинезон
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, 0.0 + b), Vector2(-10.0, 10.0 + b),
		Vector2(10.0, 10.0 + b), Vector2(8.0, 0.0 + b)]), ovr)
	# Нагрудник
	_r(-5.0, -5.0 + b, 10.0, 6.0, ovr)
	draw_line(Vector2(-4.0, -5.0 + b), Vector2(-5.5, 0.0 + b), ovr.darkened(0.2), 2.0)
	draw_line(Vector2(4.0, -5.0 + b), Vector2(5.5, 0.0 + b), ovr.darkened(0.2), 2.0)
	draw_rect(Rect2(-3.0, -3.0 + b, 6.0, 4.0), ovr.darkened(0.12))
	# Шея + голова
	_r(-3.0, -5.0 + b, 6.0, 2.0, SKIN)
	_c(0.0, -10.5 + b, 7.5, SKIN)
	# Волосы
	_r(-7.0, -18.0 + b, 14.0, 8.0, HAIR_LITE)
	draw_rect(Rect2(-7.0, -17.0 + b, 5.0, 3.0), HAIR_LITE.darkened(0.1))
	# Румяные щёки
	draw_circle(Vector2(-4.0, -9.5 + b), 2.0, Color(0.82, 0.52, 0.42))
	draw_circle(Vector2(4.0, -9.5 + b), 2.0, Color(0.82, 0.52, 0.42))
	# Глаза с блеском
	draw_circle(Vector2(-2.5, -11.5 + b), 1.5, HAIR_DARK)
	draw_circle(Vector2(2.5, -11.5 + b), 1.5, HAIR_DARK)
	draw_circle(Vector2(-2.5, -11.5 + b), 0.8, Color(0.86, 0.86, 0.86))
	draw_circle(Vector2(2.5, -11.5 + b), 0.8, Color(0.86, 0.86, 0.86))
	# Улыбка
	draw_arc(Vector2(0.0, -8.5 + b), 3.0, 0.2, PI - 0.2, 8, SKIN.darkened(0.32), 1.5)
	# Широкая соломенная шляпа
	_r(-12.0, -19.0 + b, 24.0, 3.5, hat)
	_r(-6.0, -24.0 + b, 12.0, 7.0, hat_b)
	draw_line(Vector2(-12.0, -18.0 + b), Vector2(12.0, -18.0 + b), hat.darkened(0.2), 1.5)
