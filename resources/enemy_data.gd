extends Resource
class_name EnemyData
## Данные типа врага (зомби / мутации).
##
## Новые типы добавляем как .tres. Параметры баланса — здесь, не в логике AI.

enum Family {
	WALKER,   ## Базовый медленный зомби.
	RUNNER,   ## Быстрый.
	BRUTE,    ## Толстый/сильный.
	MUTANT,   ## Особый, со способностью.
}

@export var id: StringName = &""
@export var display_name: String = "Зомби"
@export var family: Family = Family.WALKER
@export var sprite_frames: SpriteFrames

@export_group("Характеристики")
@export var max_health: int = 30
@export var move_speed: float = 40.0
@export var attack_damage: int = 8
@export var attack_cooldown: float = 1.0

@export_group("Сенсорика / шум")
## Радиус, в котором враг реагирует на источник шума.
@export var hearing_radius: float = 256.0
## Насколько сильно враг тянется на шум (множитель приоритета).
@export var noise_attraction: float = 1.0

@export_group("Оптимизация (mobile)")
## Можно ли рендерить через MultiMeshInstance2D в составе орды
## (для массовых однотипных юнитов при просадке FPS).
@export var supports_multimesh: bool = true
