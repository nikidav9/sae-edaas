extends Node
## Единая система сохранений с версионированием схемы.
##
## Payload сейва:
##   version, saved_at, state (GameState), buildings (BaseGrid),
##   day_progress (DayNightSystem), npc_ability_ids (ростер — берётся из state).
##
## При любом несовместимом изменении формата: поднять SAVE_VERSION и добавить
## ветку в _migrate(). Никогда не ломаем загрузку старых сейвов молча.

const SAVE_VERSION: int = 2
const SAVE_DIR:     String = "user://saves"
const SAVE_EXT:     String = ".save"
## Слот 0 — автосохранение (каждый новый день). Слоты 1-2 — ручные.
const AUTOSAVE_SLOT: int = 0
const SLOT_COUNT:    int = 3

func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)

# --- Пути ---

func _slot_path(slot: int) -> String:
	return "%s/slot_%d%s" % [SAVE_DIR, slot, SAVE_EXT]

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# --- Запись ---

func save_game(slot: int = 0) -> bool:
	_ensure_dir()
	var payload: Dictionary = {
		"version":      SAVE_VERSION,
		"saved_at":     Time.get_unix_time_from_system(),
		"state":        GameState.to_dict(),
		"buildings":    _collect_buildings(),
		"day_progress": _collect_day_progress(),
	}
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: не удалось открыть файл на запись: %s" % _slot_path(slot))
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	EventBus.save_completed.emit(slot)
	return true

func _collect_buildings() -> Dictionary:
	var grid := _find_node(BaseGrid) as BaseGrid
	return grid.to_dict() if grid else {}

func _collect_day_progress() -> float:
	var dns := _find_node(DayNightSystem) as DayNightSystem
	return dns.day_progress if dns else 0.0

# --- Чтение ---

func load_game(slot: int = 0) -> bool:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("SaveSystem: сейв не найден: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: не удалось открыть файл на чтение: %s" % path)
		return false
	var raw := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveSystem: повреждённый сейв: %s" % path)
		return false

	var payload: Dictionary = _migrate(parsed)

	# 1. Восстанавливаем центральное состояние.
	GameState.from_dict(payload.get("state", {}))

	# 2. Восстанавливаем здания.
	_restore_buildings(payload.get("buildings", {}))

	# 3. Восстанавливаем NPC по ростеру из GameState.
	_restore_npcs()

	# 4. Восстанавливаем прогресс дня.
	_restore_day_progress(float(payload.get("day_progress", 0.0)))

	EventBus.load_completed.emit(slot)
	return true

func _restore_buildings(data: Dictionary) -> void:
	var sys := _find_node(BuildingSystem) as BuildingSystem
	if sys:
		sys.restore(data)

func _restore_npcs() -> void:
	var mgr := _find_node(NPCManager) as NPCManager
	if mgr:
		mgr.restore_from_game_state()

func _restore_day_progress(progress: float) -> void:
	var dns := _find_node(DayNightSystem) as DayNightSystem
	if dns:
		dns.day_progress = clampf(progress, 0.0, 1.0)

# --- Мета-данные слота (для UI) ---

## Возвращает словарь с информацией о слоте или пустой словарь если нет сейва.
func slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var p: Dictionary = parsed
	var state: Dictionary = p.get("state", {})
	return {
		"slot":     slot,
		"day":      int(state.get("current_day", 1)),
		"saved_at": int(p.get("saved_at", 0)),
		"version":  int(p.get("version", 0)),
	}

func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func delete_save(slot: int = 0) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(_slot_path(slot))

# --- Автосохранение ---

func _on_day_passed(_day: int) -> void:
	save_game(AUTOSAVE_SLOT)

# --- Миграции ---

func _migrate(payload: Dictionary) -> Dictionary:
	var version: int = int(payload.get("version", 0))
	while version < SAVE_VERSION:
		match version:
			1:
				# v1→v2: добавлены поля buildings и day_progress.
				if not payload.has("buildings"):
					payload["buildings"] = {}
				if not payload.has("day_progress"):
					payload["day_progress"] = 0.0
			_:
				pass
		version += 1
		payload["version"] = version
	return payload

# --- Поиск узлов в дереве сцены ---

func _find_node(type: Script) -> Node:
	var root := get_tree().root
	for child in root.get_children():
		var found := child.find_child("*", true, false)
		# find_child по классу не поддерживается напрямую — перебираем вручную.
		var result := _deep_find_by_script(child, type)
		if result:
			return result
	return null

func _deep_find_by_script(node: Node, type: Script) -> Node:
	if node.get_script() == type:
		return node
	for child in node.get_children():
		var found := _deep_find_by_script(child, type)
		if found:
			return found
	return null
