extends Resource
class_name NPCData
## Данные выжившего NPC (рекрутируемого члена группы).
##
## Умения НЕ взаимозаменяемы: каждое либо закрывает уникальную угрозу, либо
## даёт уникальный ресурс/эффект, либо открывает уникальный путь в дилеммах.
## Поэтому ability_id уникален в группе, а у умения есть категория роли.

## Роль умения — задаёт, ПОЧЕМУ оно незаменимо.
enum AbilityRole {
	THREAT_COUNTER,  ## Закрывает уникальную угрозу (разведчик видит орду заранее).
	RESOURCE_EFFECT, ## Даёт уникальный ресурс/эффект (фермер снижает голод).
	DILEMMA_PATH,    ## Открывает уникальный путь решения дилемм (медик спасает тяжелораненого).
}

@export var id: StringName = &""
@export var display_name: String = "Выживший"
@export_multiline var description: String = ""
@export var portrait: Texture2D

@export_group("Уникальное умение")
@export var ability_id: StringName = &""
@export var ability_role: AbilityRole = AbilityRole.RESOURCE_EFFECT
@export_multiline var ability_description: String = ""

@export_group("Стоимость / упрямство")
## Сколько еды потребляет в день (снайпер привередлив, ест много).
@export var food_upkeep: int = 1
## Требует ли особое условие (грядка для фермера, вышка для снайпера).
@export var requires_structure_id: StringName = &""

@export_group("Бой")
@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_range: float = 32.0

@export_group("Мораль")
## Стартовая лояльность при рекруте (0..1).
@export_range(0.0, 1.0, 0.01) var base_loyalty: float = 0.6
