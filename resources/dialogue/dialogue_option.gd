extends Resource
class_name DialogueOption
## Один вариант ответа игрока в диалоге.

## Текст на кнопке.
@export var label: String = ""
## ID следующего DialogueNode. Пустая строка = конец диалога.
@export var next_node_id: String = ""
## Итоговое действие при выборе этого варианта.
## Обрабатывается в DialogueSystem._apply_action().
## Допустимые значения: "recruit" | "admit" | "dismiss" | "rob" | "trade" | "reject" | ""
@export var action: String = ""

## Опция видна только если игрок имеет это умение (StringName, &"" = всегда видна).
## Пример: только медик может предложить лечение тяжелораненому.
@export var requires_ability: StringName = &""

## Дельты состояния при выборе (применяются СРАЗУ, до перехода к next_node).
@export var morale_delta: float = 0.0
@export var raider_reputation_delta: float = 0.0
## Ресурс, который тратится при выборе. Формат: {"food": 2, "medicine": 1}
@export var resource_cost: Dictionary = {}
