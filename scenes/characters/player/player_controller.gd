extends CharacterBody2D
class_name PlayerController
## Персонаж игрока. Движение (джойстик / WASD), ближний бой.
##
## Атака: swing() создаёт краткосрочную Area2D в направлении взгляда
## и наносит урон всем ZombieController/RaiderController внутри.

var health: int = 100
var _max_health: int = 100
var _attack_cooldown: float = 0.0
var _facing: Vector2 = Vector2.DOWN

## Ссылка устанавливается Main при старте.
var joystick: VirtualJoystick = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea

signal health_changed(new_hp: int, max_hp: int)

func _ready() -> void:
	_max_health = GameState.balance.player_max_health
	health = _max_health

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_move(delta)

func _move(_delta: float) -> void:
	var dir := Vector2.ZERO
	if joystick != null:
		dir = joystick.get_direction()
	if dir.length() > 0.1:
		_facing = dir.normalized()
		velocity = _facing * GameState.balance.player_move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, GameState.balance.player_move_speed)
	move_and_slide()

## Вызывается кнопкой атаки (AttackButton в UI).
func swing() -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = GameState.balance.player_attack_cooldown
	# Позиционируем зону атаки в направлении взгляда.
	attack_area.position = _facing * GameState.balance.player_attack_range
	# Наносим урон всем телам в зоне.
	for body in attack_area.get_overlapping_bodies():
		if body is ZombieController:
			(body as ZombieController).take_damage(GameState.balance.player_attack_damage)
		elif body is RaiderController:
			(body as RaiderController).take_damage(GameState.balance.player_attack_damage)
	# Шум от атаки (привлекает зомби).
	EventBus.noise_emitted.emit(global_position, 0.6)

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	EventBus.player_damaged.emit(amount, health)
	health_changed.emit(health, _max_health)
	if health <= 0:
		EventBus.player_died.emit()
