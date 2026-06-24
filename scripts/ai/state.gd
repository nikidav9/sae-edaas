extends Node
class_name State
## Базовое состояние для StateMachine.
##
## Состояния поведения NPC/зомби: Idle/Patrol/Attack/Flee/Negotiate.
## Наследники переопределяют нужные хуки. Переход — через transition_requested.

## Просьба к машине состояний переключиться на состояние с этим именем.
signal transition_requested(to_state_name: StringName)

## Узел, чьим поведением управляет состояние (агент). Задаётся машиной.
var agent: Node = null

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
