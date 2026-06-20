extends Node
## Единая система сохранений с версионированием схемы.
##
## Контента будет много обновлений → схема сейва будет меняться. Каждый сейв
## хранит "version"; при загрузке старого сейва прогоняем миграции по цепочке
## до текущей версии. Никогда не ломаем загрузку старых сейвов молча.

## Текущая версия схемы сохранения. Поднимай при любом несовместимом изменении
## формата и добавляй соответствующую миграцию в _migrate().
const SAVE_VERSION: int = 1
const SAVE_DIR: String = "user://saves"
const SAVE_EXT: String = ".save"

func _slot_path(slot: int) -> String:
	return "%s/slot_%d%s" % [SAVE_DIR, slot, SAVE_EXT]

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int = 0) -> bool:
	_ensure_dir()
	var payload: Dictionary = {
		"version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"state": GameState.to_dict(),
	}
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Не удалось открыть сейв на запись: %s" % _slot_path(slot))
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	EventBus.save_completed.emit(slot)
	return true

func load_game(slot: int = 0) -> bool:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("Сейв не найден: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть сейв на чтение: %s" % path)
		return false
	var raw := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Повреждённый сейв (не JSON-объект): %s" % path)
		return false

	var payload: Dictionary = parsed
	payload = _migrate(payload)
	GameState.from_dict(payload.get("state", {}))
	EventBus.load_completed.emit(slot)
	return true

func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func delete_save(slot: int = 0) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(_slot_path(slot))

## Прогоняет payload через цепочку миграций до SAVE_VERSION.
func _migrate(payload: Dictionary) -> Dictionary:
	var version: int = int(payload.get("version", 0))
	while version < SAVE_VERSION:
		match version:
			# Пример будущей миграции:
			# 1:
			#     payload["state"]["new_field"] = default_value
			_:
				pass
		version += 1
		payload["version"] = version
	return payload
