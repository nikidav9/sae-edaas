extends StaticBody2D
class_name Building
## Размещённое здание в лагере.
##
## Строится за N дней. После постройки — ежедневные эффекты (еда, мораль).
## Зомби накапливаются у стен — при достижении порога стена начинает разрушаться.

signal construction_completed(building: Building)
signal destroyed(building: Building)

@export var building_data: BuildingData

@onready var health_bar: ProgressBar = $HealthBar
@onready var progress_label: Label = $ProgressLabel
@onready var work_point_node: WorkPoint = $WorkPoint
@onready var _visual: Polygon2D = $Visual

var current_health: int = 0
var construction_days_left: int = 0
var is_built: bool = false

var _scaffold_instance: Node2D = null
var _building_instance: Node2D = null
var _zombie_check_timer: float = 0.0

const ZOMBIE_CHECK_INTERVAL := 2.0
const ZOMBIE_DETECT_RADIUS := 56.0

func _ready() -> void:
	if building_data == null:
		return
	current_health = building_data.max_health
	health_bar.max_value = building_data.max_health
	health_bar.value = current_health

	# Тёмный цвет во время строительства.
	_visual.color = _get_base_color().darkened(0.45)

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

func _process(delta: float) -> void:
	if not is_built or not _is_wall_type():
		return
	_zombie_check_timer -= delta
	if _zombie_check_timer > 0.0:
		return
	_zombie_check_timer = ZOMBIE_CHECK_INTERVAL
	var nearby := _count_nearby_zombies(ZOMBIE_DETECT_RADIUS)
	var threshold := _get_damage_threshold()
	if nearby >= threshold:
		var excess := nearby - threshold + 1
		take_damage(excess * 5)
		_shake()

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

	if building_data.daily_food > 0:
		GameState.change_resource("food", building_data.daily_food)
	if building_data.daily_morale > 0.0:
		GameState.change_morale(building_data.daily_morale)
	if building_data.id == &"campfire":
		GameState.change_morale(0.01)

func _finish_construction() -> void:
	is_built = true
	if _scaffold_instance:
		_scaffold_instance.queue_free()
	progress_label.hide()
	_visual.color = _get_base_color()
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
	_update_visual()
	if current_health <= 0:
		_destroy()

func _on_base_attacked(attacker_count: int) -> void:
	if not is_built or building_data == null:
		return
	match building_data.id:
		&"barricade", &"wall_wood", &"wall_stone", &"wall_metal", &"gate":
			var threshold := _get_damage_threshold()
			if attacker_count >= threshold:
				take_damage((attacker_count - threshold + 1) * 8)
				_shake()
		&"farm_plot":
			if building_data.daily_food > 0:
				GameState.change_resource("food", -building_data.daily_food)

func _destroy() -> void:
	destroyed.emit(self)
	EventBus.building_destroyed.emit(building_data.id if building_data else &"", Vector2i.ZERO)
	queue_free()

# --- Визуальная деградация ---

func _update_visual() -> void:
	if _visual == null or building_data == null or not is_built:
		return
	var ratio := float(current_health) / float(building_data.max_health)
	var base := _get_base_color()
	if ratio > 0.75:
		_visual.color = base
	elif ratio > 0.5:
		_visual.color = base.darkened(0.25)
	elif ratio > 0.25:
		_visual.color = base.darkened(0.4).lerp(Color(0.7, 0.2, 0.1), 0.25)
	else:
		_visual.color = base.darkened(0.5).lerp(Color(0.8, 0.08, 0.05), 0.45)

func _shake() -> void:
	if _visual == null:
		return
	var tween := create_tween()
	tween.tween_property(_visual, "position", Vector2(4, 0), 0.05)
	tween.tween_property(_visual, "position", Vector2(-4, 0), 0.05)
	tween.tween_property(_visual, "position", Vector2(2, 2), 0.04)
	tween.tween_property(_visual, "position", Vector2(0, 0), 0.04)

func _get_base_color() -> Color:
	if building_data == null:
		return Color(0.55, 0.5, 0.4)
	match building_data.id:
		&"campfire":     return Color(0.92, 0.5, 0.1)
		&"barricade":   return Color(0.5, 0.35, 0.15)
		&"wall_wood":   return Color(0.65, 0.42, 0.22)
		&"wall_stone":  return Color(0.52, 0.52, 0.52)
		&"wall_metal":  return Color(0.42, 0.47, 0.55)
		&"gate":        return Color(0.48, 0.33, 0.18)
		&"forge":       return Color(0.5, 0.35, 0.25)
		&"house":       return Color(0.65, 0.52, 0.38)
		&"farm_plot":   return Color(0.32, 0.58, 0.22)
		&"workshop":    return Color(0.48, 0.42, 0.32)
		&"medical_tent": return Color(0.82, 0.82, 0.9)
		&"watchtower":  return Color(0.55, 0.48, 0.35)
		_:              return Color(0.55, 0.5, 0.4)

func _get_damage_threshold() -> int:
	if building_data == null:
		return 999
	match building_data.id:
		&"barricade":   return 3
		&"gate":        return 5
		&"wall_wood":   return 5
		&"wall_stone":  return 10
		&"wall_metal":  return 20
		_:              return 999

func _is_wall_type() -> bool:
	if building_data == null:
		return false
	return building_data.id in [&"barricade", &"wall_wood", &"wall_stone", &"wall_metal", &"gate"]

func _count_nearby_zombies(radius: float) -> int:
	var count := 0
	for z in get_tree().get_nodes_in_group("zombie"):
		if z is Node2D and (z as Node2D).global_position.distance_to(global_position) <= radius:
			count += 1
	return count
