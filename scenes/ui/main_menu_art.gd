extends Node2D
class_name MainMenuArt
## Нарисованный вручную анимированный фон главного меню.
## Зомби идёт слева, выживший стреляет справа, дождь, туман, город.

const GROUND_Y := 440.0
const SHOOTER_X := 1070.0
const ZOMBIE_SPEED := 30.0

# Здания силуэта — [x, y_top, width] — центр (400-880) оставлен под заголовок
const BUILDINGS := [
	[0, 245, 88], [70, 195, 75], [130, 235, 68], [185, 205, 62],
	[228, 225, 82], [292, 178, 82], [356, 235, 68],
	[892, 225, 68], [942, 188, 88], [1012, 238, 72],
	[1068, 198, 78], [1128, 218, 82], [1192, 182, 88],
]

var _time: float = 0.0
var _zombie_x: float = -65.0
var _muzzle_flash: float = 0.0
var _fire_timer: float = 2.2
var _rain: PackedVector2Array
var _rng: RandomNumberGenerator

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 7331
	_rain.resize(130)
	for i in 130:
		_rain[i] = Vector2(_rng.randf() * 1280, _rng.randf() * 720)

func _process(delta: float) -> void:
	_time += delta
	_zombie_x += ZOMBIE_SPEED * delta
	if _zombie_x > 460:
		_zombie_x = -65.0
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_muzzle_flash = 0.28
		_fire_timer = _rng.randf_range(1.6, 4.2)
	_muzzle_flash = maxf(0.0, _muzzle_flash - delta)
	for i in _rain.size():
		_rain[i].y += 520.0 * delta
		_rain[i].x += 32.0 * delta
		if _rain[i].y > 720:
			_rain[i] = Vector2(_rng.randf() * 1280, _rng.randf() * -100)
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_moon()
	_draw_city()
	_draw_ground()
	_draw_campfire(195.0, GROUND_Y)
	_draw_blood_spots()
	_draw_rain()
	_draw_fog()
	_draw_zombie(_zombie_x, GROUND_Y)
	_draw_shooter(SHOOTER_X, GROUND_Y)
	if _muzzle_flash > 0.0:
		_draw_muzzle_flash(SHOOTER_X - 112.0, GROUND_Y - 72.0)

func _draw_sky() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.038, 0.038, 0.06))

func _draw_moon() -> void:
	var mx := 640.0; var my := 82.0
	draw_circle(Vector2(mx, my), 72, Color(0.7, 0.68, 0.58, 0.06))
	draw_circle(Vector2(mx, my), 52, Color(0.75, 0.72, 0.62, 0.12))
	draw_circle(Vector2(mx, my), 34, Color(0.84, 0.8, 0.7, 0.88))
	# Лёгкое свечение
	draw_circle(Vector2(mx, my), 90, Color(0.65, 0.62, 0.5, 0.035))

func _draw_city() -> void:
	var col := Color(0.05, 0.05, 0.065)
	var win := Color(0.82, 0.76, 0.32, 0.2)
	for b in BUILDINGS:
		var bx: int = b[0]; var by: int = b[1]; var bw: int = b[2]
		draw_rect(Rect2(bx, by, bw, GROUND_Y - by), col)
		var wy := by + 10
		while wy < GROUND_Y - 12:
			var wx := bx + 5
			while wx < bx + bw - 10:
				if (bx + wx + int(wy)) % 5 != 0:
					draw_rect(Rect2(wx, wy, 7, 9), win)
				wx += 13
			wy += 18

func _draw_ground() -> void:
	draw_rect(Rect2(0, GROUND_Y, 1280, 720 - GROUND_Y), Color(0.085, 0.065, 0.05))
	draw_line(Vector2(0, GROUND_Y), Vector2(1280, GROUND_Y), Color(0.16, 0.12, 0.09), 2.0)
	# Трещины асфальта
	draw_line(Vector2(310, GROUND_Y + 7), Vector2(355, GROUND_Y + 20), Color(0.12, 0.09, 0.07), 2)
	draw_line(Vector2(680, GROUND_Y + 5), Vector2(730, GROUND_Y + 15), Color(0.11, 0.08, 0.06), 2)
	draw_line(Vector2(800, GROUND_Y + 9), Vector2(825, GROUND_Y + 4), Color(0.11, 0.08, 0.06), 1)

func _draw_blood_spots() -> void:
	var c := Color(0.32, 0.035, 0.035, 0.55)
	draw_circle(Vector2(420, GROUND_Y + 9), 6, c)
	draw_circle(Vector2(437, GROUND_Y + 5), 3.5, c)
	draw_circle(Vector2(442, GROUND_Y + 12), 2.5, c)
	draw_circle(Vector2(590, GROUND_Y + 8), 7, c)
	draw_circle(Vector2(605, GROUND_Y + 5), 4, c)

func _draw_campfire(x: float, y: float) -> void:
	var fl := sin(_time * 11.0) * 0.28 + 0.72
	# Брёвна
	draw_line(Vector2(x - 14, y), Vector2(x + 9, y - 4), Color(0.28, 0.18, 0.09), 5)
	draw_line(Vector2(x + 14, y), Vector2(x - 9, y - 4), Color(0.28, 0.18, 0.09), 5)
	# Свечение
	draw_circle(Vector2(x, y - 6), 38 * fl, Color(0.92, 0.42, 0.06, 0.09))
	draw_circle(Vector2(x, y - 6), 20 * fl, Color(1.0, 0.62, 0.12, 0.18))
	# Пламя (полигон)
	var s1 := sin(_time * 14.0) * 2.5
	var s2 := cos(_time * 11.0) * 2.0
	var flame := PackedVector2Array([
		Vector2(x, y - 2), Vector2(x - 9, y),
		Vector2(x - 5 + s1, y - 16 * fl),
		Vector2(x + s2, y - 28 * fl),
		Vector2(x + 5 - s1, y - 16 * fl),
		Vector2(x + 9, y)
	])
	draw_colored_polygon(flame, Color(1.0, 0.55, 0.1, 0.88 * fl))
	var flame2 := PackedVector2Array([
		Vector2(x, y - 2), Vector2(x - 5, y),
		Vector2(x - 2 + s2, y - 14 * fl),
		Vector2(x, y - 20 * fl),
		Vector2(x + 2 - s2, y - 14 * fl),
		Vector2(x + 5, y)
	])
	draw_colored_polygon(flame2, Color(1.0, 0.9, 0.5, 0.65 * fl))

func _draw_rain() -> void:
	var col := Color(0.42, 0.52, 0.72, 0.18)
	for drop in _rain:
		draw_line(drop, drop + Vector2(4, 13), col, 1)

func _draw_fog() -> void:
	var off := fmod(_time * 20.0, 700.0)
	draw_rect(Rect2(-off, GROUND_Y - 28, 800, 48), Color(0.12, 0.12, 0.14, 0.065))
	draw_rect(Rect2(500.0 - off, GROUND_Y - 16, 1000, 36), Color(0.1, 0.1, 0.12, 0.055))
	draw_rect(Rect2(1000.0 - off, GROUND_Y - 6, 700, 24), Color(0.08, 0.08, 0.1, 0.07))

func _draw_zombie(x: float, gy: float) -> void:
	var walk := sin(_time * 3.2) * 7.0
	var sway := cos(_time * 1.6) * 4.0
	var col := Color(0.11, 0.17, 0.09)
	var eye := Color(0.42, 0.88, 0.08, 0.92)
	# Тень
	_draw_ellipse(Vector2(x, gy), 16.0, 4.5, Color(0, 0, 0, 0.32))
	# Ноги
	draw_line(Vector2(x - 5, gy - 38), Vector2(x - 13 + walk, gy), col, 7)
	draw_line(Vector2(x + 5, gy - 38), Vector2(x + 11 - walk, gy), col, 7)
	# Тело
	draw_rect(Rect2(x - 12, gy - 84, 24, 46), col)
	# Порванная куртка
	draw_line(Vector2(x - 12, gy - 82), Vector2(x - 12, gy - 52), Color(0.07, 0.1, 0.06), 2)
	# Руки вперёд (поза зомби)
	draw_line(Vector2(x - 12, gy - 72), Vector2(x - 40 + sway, gy - 62 + walk * 0.3), col, 7)
	draw_line(Vector2(x + 12, gy - 72), Vector2(x + 42 - sway, gy - 64 - walk * 0.3), col, 7)
	# Шея
	draw_rect(Rect2(x - 4, gy - 96, 8, 14), col)
	# Голова
	draw_circle(Vector2(x + sway * 0.35, gy - 112), 17, col)
	# Светящиеся глаза
	draw_circle(Vector2(x + sway * 0.3 - 6, gy - 114), 3.8, eye)
	draw_circle(Vector2(x + sway * 0.3 + 5, gy - 114), 3.8, eye)
	draw_circle(Vector2(x + sway * 0.3 - 6, gy - 114), 7, Color(0.4, 0.88, 0.1, 0.18))
	draw_circle(Vector2(x + sway * 0.3 + 5, gy - 114), 7, Color(0.4, 0.88, 0.1, 0.18))

func _draw_shooter(x: float, gy: float) -> void:
	var col := Color(0.26, 0.2, 0.16)
	var dark := Color(0.16, 0.12, 0.09)
	var skin := Color(0.7, 0.52, 0.38)
	# Тень
	_draw_ellipse(Vector2(x, gy), 20.0, 5.5, Color(0, 0, 0, 0.32))
	# Ноги
	draw_line(Vector2(x - 9, gy - 42), Vector2(x - 15, gy), col, 10)
	draw_line(Vector2(x + 7, gy - 42), Vector2(x + 12, gy), col, 10)
	# Тактический жилет
	draw_rect(Rect2(x - 16, gy - 96, 32, 54), col)
	draw_rect(Rect2(x - 16, gy - 96, 8, 54), dark)
	draw_rect(Rect2(x + 8, gy - 96, 8, 54), dark)
	# Пояс
	draw_rect(Rect2(x - 16, gy - 44, 32, 5), dark)
	# Руки держат оружие (целится влево)
	draw_line(Vector2(x - 16, gy - 80), Vector2(x - 54, gy - 72), col, 9)
	draw_line(Vector2(x - 16, gy - 70), Vector2(x - 50, gy - 65), col, 8)
	# Кисть
	draw_circle(Vector2(x - 54, gy - 72), 5.5, skin)
	# Пистолет-пулемёт (корпус)
	draw_rect(Rect2(x - 72, gy - 80, 24, 14), Color(0.18, 0.18, 0.2))
	# Ствол
	draw_line(Vector2(x - 72, gy - 73), Vector2(x - 118, gy - 73), Color(0.2, 0.2, 0.22), 5)
	# Магазин
	draw_line(Vector2(x - 62, gy - 66), Vector2(x - 58, gy - 52), Color(0.15, 0.15, 0.18), 7)
	# Прицел
	draw_rect(Rect2(x - 68, gy - 84, 10, 5), Color(0.22, 0.22, 0.25))
	# Шея
	draw_rect(Rect2(x - 5, gy - 108, 10, 13), skin)
	# Голова
	draw_circle(Vector2(x, gy - 124), 19, skin)
	# Балаклава/шлем (верхняя часть)
	_draw_ellipse(Vector2(x, gy - 128), 19.0, 14.0, dark)
	# Козырёк
	draw_rect(Rect2(x - 24, gy - 140, 48, 6), dark)
	draw_rect(Rect2(x - 12, gy - 158, 24, 20), dark)
	# Глаз (прищурен, целится)
	draw_circle(Vector2(x - 11, gy - 123), 3.5, Color(0.65, 0.5, 0.28))
	draw_circle(Vector2(x - 11, gy - 123), 1.5, Color(0.05, 0.05, 0.05))

func _draw_muzzle_flash(x: float, y: float) -> void:
	var a := _muzzle_flash / 0.28
	# Конус света
	var cone := PackedVector2Array([
		Vector2(x, y), Vector2(x - 70, y - 22), Vector2(x - 70, y + 22)
	])
	draw_colored_polygon(cone, Color(1.0, 0.88, 0.38, a * 0.38))
	# Лучи вспышки
	for i in 8:
		var angle := (float(i) / 8.0) * TAU + _time * 0.2
		var length := 18.0 + sin(_time * 30.0 + i) * 6.0
		draw_line(
			Vector2(x, y),
			Vector2(x + cos(angle) * length, y + sin(angle) * length),
			Color(1.0, 0.92, 0.45, a * 0.8), 2.0
		)
	# Ядро
	draw_circle(Vector2(x, y), 11.0 * a, Color(1.0, 0.96, 0.65, a))
	draw_circle(Vector2(x, y), 5.0 * a, Color(1.0, 1.0, 1.0, a * 0.92))
	# Лёгкий засвет экрана
	draw_rect(Rect2(0, 0, 1280, 720), Color(1.0, 0.88, 0.32, a * 0.045))

func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	const STEPS := 14
	var pts := PackedVector2Array()
	pts.resize(STEPS)
	for i in STEPS:
		var a := (float(i) / STEPS) * TAU
		pts[i] = center + Vector2(cos(a) * rx, sin(a) * ry)
	draw_colored_polygon(pts, color)
