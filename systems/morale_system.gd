extends Node
class_name MoraleSystem
## Лояльность/мораль группы.
##
## Мораль падает от предательств, манипуляторов, голода; растёт от спасений и
## выполненных обещаний. Низкая мораль → NPC могут уйти/взбунтоваться.
## Система реагирует на факты из EventBus и меняет GameState.

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.visitor_true_nature_revealed.connect(_on_true_nature_revealed)

func _on_day_passed(_day: int) -> void:
	# Естественный спад репутации рейдеров со временем (о тебе забывают).
	if GameState.raider_reputation > 0.0:
		GameState.change_raider_reputation(-GameState.balance.reputation_decay_per_day)
	# Голод бьёт по морали, если еды нет.
	if GameState.get_resource("food") <= 0:
		GameState.change_morale(-0.05)

func _on_true_nature_revealed(_visitor: VisitorData, trait_id: int) -> void:
	# Дополнительная реакция морали на раскрытие предателя сверх базовой.
	if trait_id == VisitorData.HiddenTrait.MANIPULATOR:
		GameState.change_morale(-GameState.balance.manipulator_daily_morale_drain)
