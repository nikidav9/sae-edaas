extends CanvasLayer
class_name CraftingPanel
## Панель крафта: создание предметов из ресурсов по рецептам.

const RECIPE_DIR := "res://resources/crafting/"

@onready var items_container: VBoxContainer = %ItemsContainer
@onready var close_button: Button = %CloseButton

var _recipes: Array[CraftingRecipe] = []
var _building_system: BuildingSystem = null

func _ready() -> void:
	add_to_group("crafting_panel")
	close_button.pressed.connect(hide)
	_load_recipes()
	hide()

func setup(bsys: BuildingSystem) -> void:
	_building_system = bsys

func toggle() -> void:
	if visible:
		hide()
	else:
		_rebuild()
		show()

func _load_recipes() -> void:
	_recipes.clear()
	var dir := DirAccess.open(RECIPE_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res := ResourceLoader.load(RECIPE_DIR + fname) as CraftingRecipe
			if res:
				_recipes.append(res)
		fname = dir.get_next()
	dir.list_dir_end()

func _rebuild() -> void:
	for child in items_container.get_children():
		child.queue_free()
	for recipe in _recipes:
		if recipe.requires_building != &"" and _building_system != null:
			if not _building_system.has_building(recipe.requires_building):
				continue
		_add_card(recipe)

func _add_card(recipe: CraftingRecipe) -> void:
	var card := PanelContainer.new()
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = recipe.display_name
	name_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_lbl)

	if recipe.description != "":
		var desc_lbl := Label.new()
		desc_lbl.text = recipe.description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		vbox.add_child(desc_lbl)

	var cost_parts: PackedStringArray = []
	for k: String in recipe.input_resources:
		cost_parts.append("%s ×%d" % [k, recipe.input_resources[k]])
	var cost_lbl := Label.new()
	cost_lbl.text = "Нужно: " + ", ".join(cost_parts)
	vbox.add_child(cost_lbl)

	var out_lbl := Label.new()
	out_lbl.text = "→ %s ×%d" % [recipe.output_resource, recipe.output_amount]
	out_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	vbox.add_child(out_lbl)

	var can_afford := _can_afford(recipe)
	var btn := Button.new()
	btn.text = "Скрафтить"
	btn.disabled = not can_afford
	btn.pressed.connect(_craft.bind(recipe))
	vbox.add_child(btn)

	items_container.add_child(card)

func _can_afford(recipe: CraftingRecipe) -> bool:
	for k: String in recipe.input_resources:
		if GameState.get_resource(k) < int(recipe.input_resources[k]):
			return false
	return true

func _craft(recipe: CraftingRecipe) -> void:
	if not _can_afford(recipe):
		return
	for k: String in recipe.input_resources:
		GameState.change_resource(k, -int(recipe.input_resources[k]))
	GameState.change_resource(recipe.output_resource, recipe.output_amount)
	_rebuild()
