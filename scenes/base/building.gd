extends StaticBody2D
class_name Building
## Размещённое здание в лагере.
##
## Строится за N дней. После постройки — ежедневные эффекты (еда, мораль).
## Зомби могут атаковать и уничтожить здание.

signal construction_completed(building: Building)
signal destroyed(building: Building)

@export var building_data: BuildingData

@onready var health_bar: ProgressBar = $HealthBar
@onready var progress_label: Label = $ProgressLabel
@onready var work_point_node: WorkPoint = $WorkPoint

var current_health: int = 0
var construction_days_left: int = 0
var is_built: bool = false

var _scaffold_instance: Node2D = null
var _building_instance: Node2D = null

func _ready() -> void:
	if building_data == null:
		return
	current_health = building_data.max_health
	health_bar.max_value = building_data.max_health
	health_bar.value = current_health

	var build_days := building_data.build_time_days
	if GameState.has_ability("mechanic_traps"):
		build_days = ceili(build_days / 2.0)

	if build_days <= 0:
		_finish_construction()
	else:
		construction_days_left = build_days
		_start_construction()
		EventBus.day_passed.connect(_on_day_passed)

	if work_point_node and not building_data.provides_work_for_ability.is_empty():
		work_point_node.required_ability_id = building_data.provides_work_for_ability
		work_point_node.add_to_group("work_points")
	elif work_point_node:
		work_point_node.queue_free()

	EventBus.base_attacked.connect(_on_base_attacked)

# --- Строительство ---

func _start_construction() -> void:
	progress_label.show()
	_update_progress_label()
	if not building_data.scaffold_scene.is_empty() and ResourceLoader.exists(building_data.scaffold_scene):
		_scaffold_instance = load(building_data.scaffold_scene).instantiate()
		add_child(_scaffold_instance)

func _on_day_passed(_day: int) -> void:
	if not is_built:
		construction_days_left -= 1
		_update_progress_label()
		if construction_days_left <= 0:
			EventBus.day_passed.disconnect(_on_day_passed)
			_finish_construction()
			EventBus.day_passed.connect(_on_day_passed)
		return

	# Ежедневные эффекты готового здания.
	if building_data.daily_food > 0:
		GameState.change_resource("food", building_data.daily_food)
	if building_data.daily_morale > 0.0:
		GameState.change_morale(building_data.daily_morale)
	# Костёр без daily_morale поля — оставляем старую логику.
	if building_data.id == &"campfire":
		GameState.change_morale(0.01)

func _finish_construction() -> void:
	is_built = true
	if _scaffold_instance:
		_scaffold_instance.queue_free()
	progress_label.hide()
	if not building_data.building_scene.is_empty() and ResourceLoader.exists(building_data.building_scene):
		_building_instance = load(building_data.building_scene).instantiate()
		add_child(_building_instance)
	construction_completed.emit(self)
	EventBus.building_construction_completed.emit(building_data.id, Vector2i.ZERO)
	if building_data.id == &"campfire":
		GameState.change_morale(0.05)

func _update_progress_label() -> void:
	progress_label.text = "🔨 %d д." % construction_days_left

# --- Здоровье / урон ---

func take_damage(amount: int) -> void:
	current_health = maxi(0, current_health - amount)
	health_bar.value = current_health
	if current_health <= 0:
		_destroy()

func _on_base_attacked(attacker_count: int) -> void:
	if not is_built:
		return
	if building_data == null:
		return
	match building_data.id:
		&"barricade", &"wall_wood", &"wall_stone":
			take_damage(attacker_count * 10)
		&"farm_plot":
			# Зомби вытаптывают огород — теряем накопленную еду.
			if building_data.daily_food > 0:
				GameState.change_resource("food", -building_data.daily_food)

func _destroy() -> void:
	destroyed.emit(self)
	EventBus.building_destroyed.emit(building_data.id if building_data else &"", Vector2i.ZERO)
	queue_free()
