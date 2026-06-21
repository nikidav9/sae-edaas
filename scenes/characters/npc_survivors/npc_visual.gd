extends Node2D
class_name NPCVisual
## Внешность выжившего NPC — рисуется через _draw().
## Все 5 ролей имеют уникальный силуэт, одежду и снаряжение.
## Анимация ходьбы: покачивание тела + маховые движения ног.

enum Role { SNIPER, MECHANIC, MEDIC, SCOUT, FARMER }

const SKIN      := Color(0.74, 0.57, 0.43)
const HAIR_DARK := Color(0.18, 0.13, 0.09)
const HAIR_LITE := Color(0.50, 0.37, 0.18)
const DARK_BOOT := Color(0.14, 0.11, 0.08)

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
# Тёмный тактический костюм, красная бандана на лице, длинная винтовка

func _sniper(b: float, ll: float, rl: float) -> void:
	var jac  := Color(0.22, 0.25, 0.18)
	var pan  := Color(0.16, 0.15, 0.12)
	var bnd  := Color(0.52, 0.07, 0.07)  # бандана
	var gun  := Color(0.13, 0.11, 0.09)

	# Сапоги
	draw_rect(Rect2(-6.0 + ll, 9.5 + b, 5.5, 3.5), DARK_BOOT)
	draw_rect(Rect2(0.5  + rl, 9.5 + b, 5.5, 3.5), DARK_BOOT)
	# Тактические штаны
	draw_rect(Rect2(-5.0 + ll, 4.0 + b, 4.0, 7.0), pan)
	draw_rect(Rect2(1.0  + rl, 4.0 + b, 4.0, 7.0), pan)
	# Тактическая куртка (узкая, поджарый силуэт)
	draw_rect(Rect2(-5.0, -4.0 + b, 10.0, 9.0), jac)
	# Наплечник
	draw_rect(Rect2(-6.0, -4.0 + b, 3.0, 4.0), jac.darkened(0.2))
	# Шея
	draw_rect(Rect2(-2.0, -5.5 + b, 4.0, 2.5), SKIN)
	# Голова
	draw_circle(Vector2(0.0, -9.5 + b), 5.0, SKIN)
	# Бандана (нижняя половина лица)
	draw_rect(Rect2(-5.0, -8.5 + b, 10.0, 4.0), bnd)
	# Тактические очки / козырёк (полоса сверху)
	draw_rect(Rect2(-5.5, -15.0 + b, 11.0, 2.5), Color(0.20, 0.20, 0.18))
	draw_rect(Rect2(-2.0, -15.0 + b, 8.0,  1.5), Color(0.30, 0.32, 0.28))
	# Волосы под козырьком
	draw_rect(Rect2(-5.0, -14.5 + b, 10.0, 6.5), HAIR_DARK)
	# Взгляд (узкая щель между козырьком и бандой)
	draw_rect(Rect2(-4.0, -11.5 + b,  3.5, 1.5), Color(0.10, 0.14, 0.22))
	# Винтовка (от плеча вправо-вниз)
	draw_line(Vector2(5.0, -1.5 + b), Vector2(19.0,  6.0 + b), gun, 2.5)
	draw_line(Vector2(5.0, -1.5 + b), Vector2( 5.0,  3.5 + b), Color(0.28, 0.22, 0.14), 4.0)
	# Ствол (тонкий)
	draw_line(Vector2(9.0, 1.0 + b), Vector2(19.0, 6.0 + b), gun.lightened(0.1), 1.0)

# ─── Механик ──────────────────────────────────────────────────────────────────
# Рабочая куртка, жёлтый инструментальный пояс, гаечный ключ в руке

func _mechanic(b: float, ll: float, rl: float) -> void:
	var jac   := Color(0.38, 0.28, 0.15)
	var pan   := Color(0.26, 0.22, 0.14)
	var belt  := Color(0.58, 0.46, 0.16)
	var metal := Color(0.44, 0.48, 0.54)
	var grease:= Color(0.22, 0.18, 0.12)  # грязь/масло

	# Тяжёлые рабочие сапоги
	draw_rect(Rect2(-7.0 + ll, 9.0 + b, 6.5, 4.0), DARK_BOOT)
	draw_rect(Rect2(0.5  + rl, 9.0 + b, 6.5, 4.0), DARK_BOOT)
	# Штаны
	draw_rect(Rect2(-6.0 + ll, 4.0 + b, 5.0, 7.0), pan)
	draw_rect(Rect2(1.0  + rl, 4.0 + b, 5.0, 7.0), pan)
	# Куртка (широкая — коренастый)
	draw_rect(Rect2(-7.0, -4.5 + b, 14.0, 9.5), jac)
	# Нагрудный карман
	draw_rect(Rect2(-4.5, -3.5 + b, 5.0, 4.5), jac.darkened(0.12))
	# Инструментальный пояс
	draw_rect(Rect2(-7.0, 2.5 + b, 14.0, 3.0), belt)
	draw_rect(Rect2(-2.0, 2.8 + b,  4.0, 2.5), belt.darkened(0.3))  # пряжка
	# Шея
	draw_rect(Rect2(-2.0, -5.5 + b, 4.0, 2.0), SKIN)
	# Голова (округлая)
	draw_circle(Vector2(0.0, -9.0 + b), 5.5, SKIN)
	# Пятна масла на лице
	draw_rect(Rect2(1.5, -10.5 + b, 3.0, 1.5), grease)
	draw_rect(Rect2(-4.0, -8.5 + b, 2.0, 1.0), grease)
	# Взлохмаченные светлые волосы
	draw_rect(Rect2(-5.5, -14.5 + b, 11.0, 6.0), HAIR_LITE)
	draw_rect(Rect2(-5.5, -14.5 + b,  4.0, 2.5), HAIR_LITE.darkened(0.15))
	draw_rect(Rect2( 3.0, -14.5 + b,  2.5, 3.0), HAIR_LITE.lightened(0.1))
	# Глаза
	draw_rect(Rect2(-4.0, -11.0 + b, 3.0, 2.0), Color(0.32, 0.26, 0.14))
	draw_rect(Rect2( 1.0, -11.0 + b, 3.0, 2.0), Color(0.32, 0.26, 0.14))
	# Гаечный ключ
	draw_line(Vector2(-7.0, -2.0 + b), Vector2(-13.0,  5.5 + b), Color(0.36, 0.32, 0.22), 2.5)
	draw_rect(Rect2(-16.0, 3.5 + b, 5.5, 3.0), metal)   # головка
	draw_rect(Rect2(-16.5, 4.0 + b, 7.0, 1.5), metal)   # широкая часть

# ─── Медик ────────────────────────────────────────────────────────────────────
# Белый (грязный) халат, красный крест на груди, аптечка на боку

func _medic(b: float, ll: float, rl: float) -> void:
	var coat  := Color(0.80, 0.82, 0.78)
	var pan   := Color(0.22, 0.22, 0.26)
	var cross := Color(0.76, 0.10, 0.10)
	var bag   := Color(0.70, 0.70, 0.65)
	var glass := Color(0.28, 0.40, 0.58, 0.82)

	# Сапоги
	draw_rect(Rect2(-5.5 + ll, 9.5 + b, 5.0, 3.5), DARK_BOOT)
	draw_rect(Rect2(0.5  + rl, 9.5 + b, 5.0, 3.5), DARK_BOOT)
	# Брюки
	draw_rect(Rect2(-5.0 + ll, 4.0 + b, 4.0, 7.0), pan)
	draw_rect(Rect2(1.0  + rl, 4.0 + b, 4.0, 7.0), pan)
	# Аптечка на боку (рисуем до халата — будет частично за ним)
	draw_rect(Rect2(5.5, -1.5 + b, 7.5, 7.0), bag)
	draw_rect(Rect2(7.0,  0.0 + b, 2.0, 4.5), cross)
	draw_rect(Rect2(6.0,  1.8 + b, 5.5, 1.5), cross)
	draw_line(Vector2(5.5, -1.5 + b), Vector2(5.0, -3.5 + b), Color(0.50, 0.45, 0.35), 1.5)  # ремень
	# Халат
	draw_rect(Rect2(-6.0, -5.0 + b, 12.0, 10.0), coat)
	# Красный крест на груди
	draw_rect(Rect2(-1.5, -4.0 + b, 3.0,  7.5), cross)
	draw_rect(Rect2(-4.5, -1.0 + b, 9.0,  2.5), cross)
	# Воротник
	draw_rect(Rect2(-3.0, -5.0 + b, 6.0,  2.5), coat.darkened(0.1))
	# Шея
	draw_rect(Rect2(-2.0, -6.0 + b, 4.0,  2.0), SKIN)
	# Голова
	draw_circle(Vector2(0.0, -9.5 + b), 5.0, SKIN)
	# Тёмные волосы (собранные)
	draw_rect(Rect2(-5.0, -14.5 + b, 10.0, 5.5), HAIR_DARK)
	draw_rect(Rect2(-5.0, -13.5 + b,  5.0, 3.0), HAIR_DARK.lightened(0.05))
	# Очки
	draw_rect(Rect2(-5.0, -11.5 + b, 3.5, 2.5), glass)
	draw_rect(Rect2( 1.5, -11.5 + b, 3.5, 2.5), glass)
	draw_line(Vector2(-1.5, -10.5 + b), Vector2(1.5, -10.5 + b), Color(0.45, 0.42, 0.38), 1.0)

# ─── Разведчик ────────────────────────────────────────────────────────────────
# Тёмный капюшон, рюкзак за спиной, лёгкое снаряжение

func _scout(b: float, ll: float, rl: float) -> void:
	var jac  := Color(0.26, 0.30, 0.22)
	var hood := Color(0.18, 0.22, 0.16)
	var pan  := Color(0.25, 0.22, 0.15)
	var pack := Color(0.40, 0.34, 0.20)
	var strap:= Color(0.30, 0.24, 0.14)

	# Сапоги
	draw_rect(Rect2(-5.0 + ll, 9.5 + b, 4.5, 3.5), DARK_BOOT)
	draw_rect(Rect2(0.5  + rl, 9.5 + b, 4.5, 3.5), DARK_BOOT)
	# Штаны (лёгкие)
	draw_rect(Rect2(-4.5 + ll, 4.0 + b, 3.5, 7.0), pan)
	draw_rect(Rect2(1.0  + rl, 4.0 + b, 3.5, 7.0), pan)
	# Рюкзак за спиной (слева — видна при повороте)
	draw_rect(Rect2(-10.0, -4.5 + b, 6.0, 10.0), pack)
	draw_rect(Rect2(-10.5, -2.5 + b, 2.0,  6.0), strap)  # лямка
	draw_rect(Rect2( -9.0,  2.5 + b, 4.5,  2.0), strap)  # поясной ремень
	# Куртка с капюшоном
	draw_rect(Rect2(-5.0, -5.0 + b, 10.0, 10.0), jac)
	# Капюшон (трапециевидный)
	var hd := PackedVector2Array([
		Vector2(-6.5, -4.5 + b),
		Vector2(-5.0, -16.0 + b),
		Vector2( 5.0, -16.0 + b),
		Vector2( 6.5, -4.5 + b),
	])
	draw_colored_polygon(hd, hood)
	# Лицо в тени (кожа)
	draw_circle(Vector2(0.0, -9.5 + b), 4.5, SKIN)
	# Тень от капюшона на лице
	draw_rect(Rect2(-4.5, -14.0 + b, 9.0, 4.0), hood)
	draw_rect(Rect2(-4.5, -11.5 + b, 9.0, 2.0), Color(0.0, 0.0, 0.0, 0.30))
	# Глаза (почти скрыты в тени)
	draw_rect(Rect2(-3.5, -11.0 + b, 2.5, 1.5), Color(0.10, 0.14, 0.20, 0.85))

# ─── Фермер ───────────────────────────────────────────────────────────────────
# Комбинезон, соломенная шляпа, мотыга в руке

func _farmer(b: float, ll: float, rl: float) -> void:
	var ovr  := Color(0.38, 0.30, 0.15)
	var shirt:= Color(0.60, 0.50, 0.34)
	var hat  := Color(0.60, 0.48, 0.22)
	var hat_b:= Color(0.42, 0.32, 0.14)
	var hoe_h:= Color(0.42, 0.35, 0.22)
	var hoe_m:= Color(0.40, 0.44, 0.50)

	# Рабочие сапоги
	draw_rect(Rect2(-7.0 + ll, 9.0 + b, 6.0, 4.5), Color(0.20, 0.14, 0.09))
	draw_rect(Rect2(1.0  + rl, 9.0 + b, 6.0, 4.5), Color(0.20, 0.14, 0.09))
	# Комбинезон — штаны
	draw_rect(Rect2(-6.0 + ll, 4.0 + b, 5.0, 7.0), ovr)
	draw_rect(Rect2(1.0  + rl, 4.0 + b, 5.0, 7.0), ovr)
	# Рубашка
	draw_rect(Rect2(-7.0, -5.0 + b, 14.0, 10.0), shirt)
	# Комбинезон поверх (нагрудник + туловище)
	draw_rect(Rect2(-7.0,  0.5 + b, 14.0, 5.0), ovr)
	draw_rect(Rect2(-4.0, -5.0 + b,  8.0, 7.0), ovr)  # нагрудник
	# Лямки комбинезона
	draw_line(Vector2(-3.0, -5.0 + b), Vector2(-4.5, 0.5 + b), ovr.darkened(0.2), 2.0)
	draw_line(Vector2( 3.0, -5.0 + b), Vector2( 4.5, 0.5 + b), ovr.darkened(0.2), 2.0)
	# Шея
	draw_rect(Rect2(-2.0, -6.0 + b, 4.0, 2.0), SKIN)
	# Голова (округлая, добродушная)
	draw_circle(Vector2(0.0, -9.5 + b), 5.5, SKIN)
	# Светлые волосы
	draw_rect(Rect2(-5.5, -15.0 + b, 11.0, 5.5), HAIR_LITE)
	# Глаза
	draw_rect(Rect2(-4.0, -11.0 + b, 3.0, 2.0), Color(0.28, 0.22, 0.10))
	draw_rect(Rect2( 1.0, -11.0 + b, 3.0, 2.0), Color(0.28, 0.22, 0.10))
	# Улыбка
	draw_arc(Vector2(0.0, -8.5 + b), 2.5, 0.2, PI - 0.2, 8, Color(0.42, 0.25, 0.15), 1.5)
	# Соломенная шляпа (поля + тулья)
	draw_rect(Rect2(-10.0, -16.0 + b, 20.0, 3.0), hat)     # поля
	draw_rect(Rect2( -5.5, -20.5 + b, 11.0, 6.0), hat_b)   # тулья
	draw_line(Vector2(-10.0, -15.5 + b), Vector2(10.0, -15.5 + b), hat_b, 1.5)  # тень полей
	# Мотыга
	draw_line(Vector2(-9.0, -4.5 + b), Vector2(-9.0, 12.5 + b), hoe_h, 2.0)
	draw_rect(Rect2(-14.0, -7.5 + b, 8.0, 3.0), hoe_m)
	draw_rect(Rect2(-14.0, -7.5 + b, 2.0, 5.5), hoe_m)
