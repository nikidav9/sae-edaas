extends CharacterBody2D
class_name RaiderController
## Рейдер: враждебный человек, атакующий базу во время набега.
## Инстанцируется RaidSystem, удаляется по смерти или отступлении.

var health: int = 50
var max_health: int = 50
## Ссылка на систему рейдов — задаётся при спавне.
var raid_system: RaidSystem = null

@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	max_health = GameState.balance.raider_max_health
	health = max_health

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		_die()

func _die() -> void:
	if raid_system:
		raid_system.on_raider_killed(self)
	queue_free()

func despawn() -> void:
	if raid_system:
		raid_system.on_raider_escaped(self)
	queue_free()
