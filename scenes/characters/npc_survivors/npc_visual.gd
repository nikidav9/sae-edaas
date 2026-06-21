extends Node2D
class_name NPCVisual
## Внешность выжившего NPC — рисуется через _draw().
## Чиби-пропорции: большая голова, широкое тело, короткие ноги.
## Анимация ходьбы: покачивание тела + маховые движения ног.

enum Role { SNIPER, MECHANIC, MEDIC, SCOUT, FARMER }

const SKIN      := Color(0.72, 0.55, 0.40)
const HAIR_DARK := Color(0.22, 0.16, 0.10)
const HAIR_LITE := Color(0.52, 0.38, 0.18)
const DARK_BOOT := Color(0.15, 0.11, 0.08)

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
	var b  := sin(_walk_phase * 2.0) * 1.0      # вертикальный боб тела
	var ll := sin(_walk_phase) * 3.5             # левая нога (X смещение)
	var rl := -sin(_walk_phase) * 3.5            # правая нога
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

# ─── Снайпер ──────────────────────────────────────────────────────────────────
# Большой тактический капюшон, широкий плащ, диагональная винтовка

func _sniper(b: float, ll: float, rl: float) -> void:
	var hood  := Color(0.204, 0.165, 0.118)
	var coat  := Color(0.267, 0.220, 0.149)
	var coat2 := Color(0.220, 0.180, 0.118)
	var scrf  := Color(0.373, 0.314, 0.235)
	var pan   := Color(0.180, 0.149, 0.110)
	var gun   := Color(0.157, 0.133, 0.094)

	# Винтовка (за спиной, рисуется первой — позади тела)
	draw_line(Vector2(-5.0, -11.0 + b), Vector2(11.0, 8.0 + b), gun, 2.0)
	draw_line(Vector2(-5.0, -11.0 + b), Vector2(-9.0, -6.0 + b), gun, 1.5)
	# Сапоги + ноги
	draw_rect(Rect2(-9.0 + ll, 10.0 + b, 8.0, 5.0), DARK_BOOT)
	draw_rect(Rect2(1.0 + rl, 10.0 + b, 8.0, 5.0), DARK_BOOT)
	draw_rect(Rect2(-7.0 + ll, 5.0 + b, 5.5, 6.0), pan)
	draw_rect(Rect2(1.5 + rl, 5.0 + b, 5.5, 6.0), pan)
	# Плащ (широкий, слоями)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.0, 0.0 + b), Vector2(-12.0, 10.0 + b),
		Vector2(12.0, 10.0 + b), Vector2(11.0, 0.0 + b)]), coat2)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.0, -5.0 + b), Vector2(-11.0, 10.0 + b),
		Vector2(11.0, 10.0 + b), Vector2(9.0, -5.0 + b)]), coat)
	# Шарф на шее
	draw_rect(Rect2(-8.0, -5.0 + b, 16.0, 5.0), scrf)
	draw_rect(Rect2(-5.0, -6.0 + b, 10.0, 3.0), scrf.darkened(0.15))
	# Голова (кожа)
	draw_circle(Vector2(0.0, -9.0 + b), 7.0, SKIN)
	# Большой тактический капюшон
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -5.0 + b), Vector2(-10.0, -13.0 + b),
		Vector2(-5.0, -21.0 + b), Vector2(5.0, -21.0 + b),
		Vector2(10.0, -13.0 + b), Vector2(8.0, -5.0 + b)]), hood)
	# Тень внутри капюшона
	draw_rect(Rect2(-6.0, -14.0 + b, 12.0, 9.0), Color(0.078, 0.059, 0.039))
	# Прорезь для глаз
	draw_rect(Rect2(-5.0, -10.0 + b, 10.0, 3.0), SKIN)
	draw_rect(Rect2(-4.0, -10.0 + b, 3.0, 2.5), Color(0.12, 0.16, 0.24))
	draw_rect(Rect2(1.0, -10.0 + b, 3.0, 2.5), Color(0.12, 0.16, 0.24))
	# Складка капюшона
	draw_line(Vector2(-5.0, -20.0 + b), Vector2(-10.0, -13.0 + b), hood.lightened(0.08), 1.0)

# ─── Механик ──────────────────────────────────────────────────────────────────
# Огромные очки-гоглы, рабочая куртка, гаечный ключ

func _mechanic(b: float, ll: float, rl: float) -> void:
	var coat  := Color(0.35, 0.26, 0.14)
	var belt  := Color(0.58, 0.46, 0.15)
	var pan   := Color(0.24, 0.20, 0.12)
	var metal := Color(0.44, 0.48, 0.54)
	var goggl := Color(0.18, 0.28, 0.42)
	var patch := Color(0.28, 0.22, 0.12)

	# Сапоги + ноги
	draw_rect(Rect2(-9.0 + ll, 10.0 + b, 8.0, 6.0), DARK_BOOT)
	draw_rect(Rect2(1.0 + rl, 10.0 + b, 8.0, 6.0), DARK_BOOT)
	draw_rect(Rect2(-8.0 + ll, 5.0 + b, 6.0, 6.0), pan)
	draw_rect(Rect2(2.0 + rl, 5.0 + b, 6.0, 6.0), pan)
	# Рабочая куртка (широкая)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.0, -5.0 + b), Vector2(-12.0, 11.0 + b),
		Vector2(12.0, 11.0 + b), Vector2(9.0, -5.0 + b)]), coat)
	# Рукава
	draw_rect(Rect2(-9.0, -4.0 + b, 5.0, 5.0), coat)
	draw_rect(Rect2(4.0, -4.0 + b, 5.0, 5.0), coat)
	# Нагрудный карман (заплатка)
	draw_rect(Rect2(-6.0, 0.0 + b, 5.0, 5.0), patch)
	draw_rect(Rect2(-5.0, 1.0 + b, 3.0, 3.0), patch.darkened(0.2))
	# Инструментальный пояс
	draw_rect(Rect2(-10.0, 4.0 + b, 20.0, 3.0), belt)
	draw_rect(Rect2(-2.0, 4.5 + b, 4.0, 2.0), belt.darkened(0.3))
	draw_line(Vector2(6.0, 5.0 + b), Vector2(6.0, 11.0 + b), metal, 1.5)
	# Гаечный ключ
	draw_line(Vector2(-12.0, -1.0 + b), Vector2(-14.0, 8.0 + b), Color(0.36, 0.34, 0.22), 2.0)
	draw_rect(Rect2(-16.0, 6.0 + b, 5.5, 3.0), metal)
	draw_rect(Rect2(-16.5, 6.5 + b, 7.0, 1.5), metal)
	# Шея + голова
	draw_rect(Rect2(-3.0, -5.0 + b, 6.0, 3.0), SKIN)
	draw_circle(Vector2(0.0, -10.0 + b), 7.5, SKIN)
	# Взлохмаченные волосы
	draw_rect(Rect2(-7.0, -17.0 + b, 14.0, 8.0), HAIR_LITE)
	draw_rect(Rect2(-8.0, -16.0 + b, 4.0, 3.0), HAIR_LITE.darkened(0.1))
	draw_rect(Rect2(4.0, -16.0 + b, 3.0, 4.0), HAIR_LITE.lightened(0.08))
	# Очки-гоглы (главная черта!)
	draw_rect(Rect2(-8.0, -13.0 + b, 7.0, 5.0), goggl)
	draw_rect(Rect2(1.0, -13.0 + b, 7.0, 5.0), goggl)
	draw_line(Vector2(-1.0, -11.0 + b), Vector2(1.0, -11.0 + b), metal, 2.0)
	draw_rect(Rect2(-7.0, -12.0 + b, 5.0, 3.0), goggl.lightened(0.18))
	draw_rect(Rect2(2.0, -12.0 + b, 5.0, 3.0), goggl.lightened(0.18))
	draw_rect(Rect2(-8.0, -13.0 + b, 16.0, 1.5), Color(0.25, 0.22, 0.18))
	draw_rect(Rect2(-8.0, -8.0 + b, 16.0, 1.0), Color(0.25, 0.22, 0.18))
	# Пятна масла
	draw_rect(Rect2(-2.0, -6.0 + b, 4.0, 2.0), Color(0.22, 0.18, 0.12))
	draw_line(Vector2(-2.0, -7.5 + b), Vector2(2.0, -7.5 + b), SKIN.darkened(0.25), 1.0)

# ─── Медик ────────────────────────────────────────────────────────────────────
# Белый халат с красным крестом, медицинская шапочка, очки, аптечка

func _medic(b: float, ll: float, rl: float) -> void:
	var coat  := Color(0.82, 0.84, 0.80)
	var cross := Color(0.76, 0.10, 0.10)
	var pan   := Color(0.22, 0.22, 0.26)
	var bag   := Color(0.70, 0.70, 0.65)
	var cap   := Color(0.78, 0.80, 0.76)

	# Аптечка на боку (рисуется первой — частично за халатом)
	draw_rect(Rect2(7.0, -2.0 + b, 8.0, 8.0), bag)
	draw_rect(Rect2(8.5, 0.0 + b, 2.0, 5.0), cross)
	draw_rect(Rect2(7.5, 2.0 + b, 5.0, 1.5), cross)
	draw_line(Vector2(7.0, -2.0 + b), Vector2(6.0, -5.0 + b), Color(0.50, 0.48, 0.42), 1.5)
	# Сапоги + ноги
	draw_rect(Rect2(-8.0 + ll, 10.0 + b, 7.0, 5.0), DARK_BOOT)
	draw_rect(Rect2(1.0 + rl, 10.0 + b, 7.0, 5.0), DARK_BOOT)
	draw_rect(Rect2(-7.0 + ll, 5.0 + b, 5.0, 6.0), pan)
	draw_rect(Rect2(2.0 + rl, 5.0 + b, 5.0, 6.0), pan)
	# Белый халат
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -5.0 + b), Vector2(-10.0, 11.0 + b),
		Vector2(10.0, 11.0 + b), Vector2(8.0, -5.0 + b)]), coat)
	# Красный крест на груди
	draw_rect(Rect2(-1.5, -3.0 + b, 3.0, 8.0), cross)
	draw_rect(Rect2(-4.5, 0.0 + b, 9.0, 2.5), cross)
	# Отвороты халата
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -5.0 + b), Vector2(-5.0, -5.0 + b),
		Vector2(-3.0, 2.0 + b), Vector2(-8.0, 4.0 + b)]), coat.darkened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(8.0, -5.0 + b), Vector2(5.0, -5.0 + b),
		Vector2(3.0, 2.0 + b), Vector2(8.0, 4.0 + b)]), coat.darkened(0.08))
	# Шея + голова
	draw_rect(Rect2(-3.0, -5.0 + b, 6.0, 2.0), SKIN)
	draw_circle(Vector2(0.0, -10.0 + b), 7.0, SKIN)
	# Тёмные волосы
	draw_rect(Rect2(-6.0, -17.0 + b, 12.0, 7.0), HAIR_DARK)
	draw_rect(Rect2(-6.0, -16.0 + b, 5.0, 4.0), HAIR_DARK.lightened(0.04))
	# Белая медицинская шапочка с красной полосой
	draw_rect(Rect2(-7.0, -17.0 + b, 14.0, 5.0), cap)
	draw_rect(Rect2(-7.0, -17.0 + b, 14.0, 1.5), cross)
	# Очки
	draw_rect(Rect2(-6.0, -12.0 + b, 5.0, 3.0), Color(0.28, 0.40, 0.58))
	draw_rect(Rect2(1.0, -12.0 + b, 5.0, 3.0), Color(0.28, 0.40, 0.58))
	draw_line(Vector2(-1.0, -10.5 + b), Vector2(1.0, -10.5 + b), Color(0.45, 0.42, 0.38), 1.0)
	# Добрая улыбка
	draw_line(Vector2(-2.0, -8.0 + b), Vector2(2.0, -8.0 + b), SKIN.darkened(0.22), 1.5)

# ─── Разведчик ────────────────────────────────────────────────────────────────
# Тёмный капюшон с глубокой тенью, лёгкая куртка, рюкзак, шарф

func _scout(b: float, ll: float, rl: float) -> void:
	var hood := Color(0.20, 0.24, 0.18)
	var jac  := Color(0.28, 0.32, 0.24)
	var pan  := Color(0.24, 0.21, 0.14)
	var pack := Color(0.40, 0.34, 0.20)
	var strp := Color(0.30, 0.24, 0.14)
	var scrf := Color(0.26, 0.30, 0.22)

	# Рюкзак (позади тела)
	draw_rect(Rect2(-13.0, -4.0 + b, 7.0, 12.0), pack)
	draw_rect(Rect2(-13.5, -2.0 + b, 2.0, 8.0), strp)
	draw_rect(Rect2(-11.0, 6.0 + b, 5.0, 2.0), strp)
	draw_rect(Rect2(-11.0, 0.0 + b, 5.0, 1.0), pack.darkened(0.2))
	draw_rect(Rect2(-12.0, -3.0 + b, 6.0, 1.5), pack.darkened(0.15))
	# Сапоги + ноги
	draw_rect(Rect2(-8.0 + ll, 10.0 + b, 7.0, 4.0), Color(0.18, 0.15, 0.10))
	draw_rect(Rect2(1.0 + rl, 10.0 + b, 7.0, 4.0), Color(0.18, 0.15, 0.10))
	draw_rect(Rect2(-7.0 + ll, 5.0 + b, 5.5, 6.0), pan)
	draw_rect(Rect2(1.5 + rl, 5.0 + b, 5.5, 6.0), pan)
	# Куртка
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.0, -5.0 + b), Vector2(-9.0, 10.0 + b),
		Vector2(9.0, 10.0 + b), Vector2(7.0, -5.0 + b)]), jac)
	# Капюшон (первый слой)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.0, -5.0 + b), Vector2(-8.0, -12.0 + b),
		Vector2(-3.0, -21.0 + b), Vector2(3.0, -21.0 + b),
		Vector2(8.0, -12.0 + b), Vector2(7.0, -5.0 + b)]), hood)
	# Лицо (кожа)
	draw_circle(Vector2(0.0, -9.5 + b), 6.5, SKIN)
	# Капюшон (второй слой поверх лица)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7.0, -5.0 + b), Vector2(-8.0, -12.0 + b),
		Vector2(-3.0, -21.0 + b), Vector2(3.0, -21.0 + b),
		Vector2(8.0, -12.0 + b), Vector2(7.0, -5.0 + b)]), hood)
	# Глубокая тень внутри капюшона
	draw_rect(Rect2(-5.0, -15.0 + b, 10.0, 8.0), Color(0.06, 0.08, 0.05))
	# Лицо в тени
	draw_rect(Rect2(-4.0, -11.0 + b, 8.0, 5.0), SKIN.darkened(0.20))
	# Зоркие глаза
	draw_rect(Rect2(-3.5, -10.0 + b, 3.0, 2.0), Color(0.14, 0.18, 0.28))
	draw_rect(Rect2(0.5, -10.0 + b, 3.0, 2.0), Color(0.14, 0.18, 0.28))
	# Шарф на нижней части лица
	draw_rect(Rect2(-5.0, -7.0 + b, 10.0, 3.5), scrf)
	# Складки капюшона
	draw_line(Vector2(-7.0, -5.0 + b), Vector2(-8.0, -12.0 + b), hood.lightened(0.07), 1.0)
	draw_line(Vector2(7.0, -5.0 + b), Vector2(8.0, -12.0 + b), hood.lightened(0.07), 1.0)

# ─── Фермер ───────────────────────────────────────────────────────────────────
# Широкая соломенная шляпа, комбинезон, румяные щёки, мотыга

func _farmer(b: float, ll: float, rl: float) -> void:
	var ovr  := Color(0.40, 0.32, 0.16)
	var shrt := Color(0.62, 0.52, 0.36)
	var hat  := Color(0.62, 0.50, 0.24)
	var hat_b:= Color(0.44, 0.34, 0.16)
	var hoe_h:= Color(0.44, 0.36, 0.22)
	var hoe_m:= Color(0.40, 0.44, 0.50)
	var fbot := Color(0.22, 0.16, 0.09)

	# Мотыга (за спиной, диагонально)
	draw_line(Vector2(8.0, -15.0 + b), Vector2(-4.0, 14.0 + b), hoe_h, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(5.0, -16.0 + b), Vector2(12.0, -17.0 + b),
		Vector2(14.0, -13.0 + b), Vector2(7.0, -12.0 + b)]), hoe_m)
	# Сапоги + ноги
	draw_rect(Rect2(-9.0 + ll, 10.0 + b, 8.0, 5.0), fbot)
	draw_rect(Rect2(1.0 + rl, 10.0 + b, 8.0, 5.0), fbot)
	draw_rect(Rect2(-8.0 + ll, 5.0 + b, 6.0, 6.0), ovr)
	draw_rect(Rect2(2.0 + rl, 5.0 + b, 6.0, 6.0), ovr)
	# Рубашка
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, -5.0 + b), Vector2(-11.0, 10.0 + b),
		Vector2(11.0, 10.0 + b), Vector2(8.0, -5.0 + b)]), shrt)
	# Комбинезон (нижняя часть)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8.0, 0.0 + b), Vector2(-10.0, 10.0 + b),
		Vector2(10.0, 10.0 + b), Vector2(8.0, 0.0 + b)]), ovr)
	# Нагрудник комбинезона
	draw_rect(Rect2(-5.0, -5.0 + b, 10.0, 6.0), ovr)
	# Лямки
	draw_line(Vector2(-4.0, -5.0 + b), Vector2(-5.5, 0.0 + b), ovr.darkened(0.2), 2.0)
	draw_line(Vector2(4.0, -5.0 + b), Vector2(5.5, 0.0 + b), ovr.darkened(0.2), 2.0)
	# Нагрудный карман
	draw_rect(Rect2(-3.0, -3.0 + b, 6.0, 4.0), ovr.darkened(0.12))
	# Шея + голова
	draw_rect(Rect2(-3.0, -5.0 + b, 6.0, 2.0), SKIN)
	draw_circle(Vector2(0.0, -10.5 + b), 7.5, SKIN)
	# Волосы
	draw_rect(Rect2(-7.0, -18.0 + b, 14.0, 8.0), HAIR_LITE)
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
	draw_rect(Rect2(-12.0, -19.0 + b, 24.0, 3.5), hat)
	draw_rect(Rect2(-6.0, -24.0 + b, 12.0, 7.0), hat_b)
	draw_line(Vector2(-12.0, -18.0 + b), Vector2(12.0, -18.0 + b), hat.darkened(0.2), 1.5)
