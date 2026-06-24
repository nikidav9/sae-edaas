extends Node
## Модуль push-уведомлений (изолирован от игровой логики).
##
## Намеренно НЕ завязан на game logic: общается только через
## EventBus.notification_requested. Если нативный плагин (FCM / APNs) придётся
## заменить — меняем только этот файл, остальной код не трогаем.
##
## Реальная отправка делается нативными плагинами:
##   Android — Firebase Cloud Messaging, iOS — APNs.
## Здесь — кросс-платформенная обёртка с безопасными заглушками для редактора.

var _plugin: Object = null
var _permission_granted: bool = false

func _ready() -> void:
	_init_plugin()
	EventBus.notification_requested.connect(_on_notification_requested)

func _init_plugin() -> void:
	# Имя плагина подставится при интеграции нативного модуля.
	var plugin_name := _platform_plugin_name()
	if not plugin_name.is_empty() and Engine.has_singleton(plugin_name):
		_plugin = Engine.get_singleton(plugin_name)
	else:
		# В редакторе / без плагина работаем в режиме заглушки.
		print("[NotificationManager] Плагин '%s' недоступен — режим заглушки." % plugin_name)

func _platform_plugin_name() -> String:
	match OS.get_name():
		"Android":
			return "HollowReachFCM"
		"iOS":
			return "HollowReachAPNs"
		_:
			return ""

func request_permission() -> void:
	if _plugin and _plugin.has_method("request_permission"):
		_plugin.call("request_permission")
	else:
		_permission_granted = true # десктоп/редактор: считаем разрешённым

func schedule_local(title: String, body: String, delay_seconds: int) -> void:
	if _plugin and _plugin.has_method("schedule_local_notification"):
		_plugin.call("schedule_local_notification", title, body, delay_seconds)
	else:
		print("[NotificationManager] (заглушка) +%dс: %s — %s" % [delay_seconds, title, body])

func cancel_all() -> void:
	if _plugin and _plugin.has_method("cancel_all"):
		_plugin.call("cancel_all")

func _on_notification_requested(title: String, body: String, delay_seconds: int) -> void:
	schedule_local(title, body, delay_seconds)
