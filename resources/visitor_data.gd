extends Resource
class_name VisitorData
## Данные одного визитёра лагеря.
##
## Истинная природа враждебных/предателей скрыта от игрока до раскрытия
## (reveal_*). Новых визитёров добавляем как .tres, без правки кода.

enum Type {
	FRIENDLY,  ## Рекрутируемый: даёт уникальное умение (ability_id).
	NEUTRAL,   ## Торговец: обмен ресурсов/информации.
	HOSTILE,   ## Внешне обычный, но со скрытой враждебной природой.
	DILEMMA,   ## Моральный выбор без явно "правильного" ответа.
}

## Скрытая черта — раскрывается со временем/событиями, не видна игроку сразу.
enum HiddenTrait {
	NONE,
	RAIDER_SCOUT,  ## Собирает данные о слабых местах, позже наводит банду.
	INFECTED,      ## Скрывает укус; обращается через reveal_delay_days внутри периметра.
	MANIPULATOR,   ## Снижает мораль группы изнутри.
	BETRAYER,      ## "Второй шанс": может предать (для DILEMMA / бывшего врага).
	LOYAL,         ## Скрытая положительная черта (например, окажется верным союзником).
}

@export var id: StringName = &""
@export var display_name: String = "Незнакомец"
@export var type: Type = Type.FRIENDLY

## Дерево диалога. Формат описывается отдельно в DialogueSystem;
## храним как Dictionary, чтобы редактировать данными, а не кодом.
@export var dialogue_tree: Dictionary = {}

@export_group("Reveal (скрытая природа)")
## Вероятность раскрытия истинной природы за один день/диалог (0..1).
@export_range(0.0, 1.0, 0.01) var reveal_chance: float = 0.0
## Через сколько дней внутри периметра срабатывает скрытая черта (напр. обращение заражённого).
@export var reveal_delay_days: int = 0
@export var hidden_trait: HiddenTrait = HiddenTrait.NONE

@export_group("Рекрут (для FRIENDLY)")
## Уникальное умение, которое даёт NPC при рекруте. Должно быть уникальным
## во всей группе (см. систему уникальных умений).
@export var ability_id: StringName = &""
## Ссылка на полные данные NPC, если визитёра можно принять в группу.
@export var npc_data: NPCData

@export_group("Генерация")
## Базовый вес в weighted random пуле генератора.
@export var spawn_weight: float = 1.0
## Минимальный день, начиная с которого визитёр может появиться.
@export var min_day: int = 1

func is_recruitable() -> bool:
	return type == Type.FRIENDLY and ability_id != &""

func has_hidden_nature() -> bool:
	return hidden_trait != HiddenTrait.NONE
