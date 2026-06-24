extends Resource
class_name DialogueTree
## Полное дерево диалога визитёра.
##
## Узлы хранятся в словаре id→DialogueNode. Движок (DialogueSystem) читает
## отсюда; редактировать контент можно в .tres без правки кода.

## Все узлы диалога. Ключ — DialogueNode.id, значение — DialogueNode.
@export var nodes: Array[DialogueNode] = []
## ID стартового узла. По соглашению "start".
@export var entry_node_id: String = "start"

var _index: Dictionary = {}  # строится один раз при первом обращении

func get_node_by_id(id: String) -> DialogueNode:
	if _index.is_empty():
		_build_index()
	return _index.get(id, null)

func _build_index() -> void:
	_index.clear()
	for node in nodes:
		_index[node.id] = node
