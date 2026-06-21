extends Node
class_name AudioSystem
## Управляет аудио-шинами, атмосферным звуком и SFX.
##
## Структура шин: Master → Ambience, SFX, Music.
## Пока нет реальных аудио-файлов — система создаёт шины и устанавливает громкость.
## Когда появятся ассеты: добавить StreamPlayer-ы и вызвать play_sfx()/set_ambience().

const BUS_AMBIENCE := "Ambience"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"

var _ambience_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = BUS_AMBIENCE
	add_child(_ambience_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = BUS_SFX
	add_child(_sfx_player)

	_ensure_buses()
	EventBus.day_phase_changed.connect(_on_phase_changed)
	EventBus.noise_emitted.connect(_on_noise_emitted)
	EventBus.base_attacked.connect(_on_base_attacked)
	EventBus.raid_started.connect(_on_raid_started)
	EventBus.raid_ended.connect(_on_raid_ended)

func _ensure_buses() -> void:
	for bus_name in [BUS_AMBIENCE, BUS_SFX, BUS_MUSIC]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func set_ambience_volume(db: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_AMBIENCE)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)

func set_sfx_volume(db: float) -> void:
	var idx := AudioServer.get_bus_index(BUS_SFX)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)

func play_sfx(stream: AudioStream) -> void:
	if stream == null or not is_instance_valid(_sfx_player):
		return
	_sfx_player.stream = stream
	_sfx_player.play()

func set_ambience(stream: AudioStream) -> void:
	if stream == null or not is_instance_valid(_ambience_player):
		return
	if _ambience_player.stream == stream:
		return
	# Плавный кроссфейд.
	var tween := create_tween()
	tween.tween_property(_ambience_player, "volume_db", -40.0, 0.8)
	tween.tween_callback(func() -> void:
		_ambience_player.stream = stream
		_ambience_player.play()
	)
	tween.tween_property(_ambience_player, "volume_db", 0.0, 0.8)

# --- Реакции на события ---

func _on_phase_changed(phase: int, _progress: float) -> void:
	# phase: 0=dawn 1=day 2=dusk 3=night
	# Здесь подключить ambience-потоки когда появятся ассеты.
	match phase:
		0: set_ambience_volume(-6.0)   # рассвет — тихо
		1: set_ambience_volume(0.0)    # день
		2: set_ambience_volume(-3.0)   # закат
		3: set_ambience_volume(-2.0)   # ночь — чуть тише чем день

func _on_noise_emitted(_position: Vector2, loudness: float) -> void:
	if loudness > 0.7:
		pass  # play_sfx(loud_sound_stream)

func _on_base_attacked(_count: int) -> void:
	pass  # play_sfx(hit_sound_stream)

func _on_raid_started(_count: int) -> void:
	pass  # play_sfx(raid_alarm_stream) или music смена на tension track

func _on_raid_ended(repelled: bool) -> void:
	if repelled:
		pass  # play_sfx(victory_sting_stream)
