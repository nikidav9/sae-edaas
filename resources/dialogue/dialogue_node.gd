extends Resource
class_name DialogueNode
## Один узел дерева диалога: реплика + варианты ответа.

## Уникальный ID в пределах DialogueTree. По соглашению первый узел = "start".
@export var id: String = "start"
## Кто говорит. Пустая строка → движок подставит display_name визитёра.
@export var speaker: String = ""
## Текст реплики. Поддерживает BBCode (через RichTextLabel).
@export_multiline var text: String = ""

## Варианты ответа игрока. Если пусто — узел авто-продолжается (монолог NPC).
@export var options: Array[DialogueOption] = []
## Авто-переход без выбора игрока. Используется когда options пусты.
## Пустая строка = конец диалога после прочтения.
@export var auto_next_id: String = ""
## Задержка перед авто-переходом (сек). Даёт время прочитать текст.
@export var auto_next_delay: float = 2.0

## Реакция на ИСТЕЧЕНИЕ таймера из этого узла (выбор по умолчанию).
## Если пустая строка — берётся последняя опция в списке.
@export var timeout_option_index: int = -1  # -1 = последняя
